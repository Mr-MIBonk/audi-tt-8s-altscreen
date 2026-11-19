# Cockpit drawing (EAL)

[Home](Home.md)

The cockpit is the HMI's main terminal; its scene graph is built through
`EALManager` (e.solutions engine layer), and we can add our own nodes to it.

## API that works on MU1462

| Need | Call |
|---|---|
| Group node | `createNode3D(parent, name, w, h)`, then `setPosition(x, y, 0)` |
| Texture | `createTextureDescription(buffer, 6 /*RGBA8888*/, w, h)` with `ByteBuffer.allocateDirect(w*h*4)` |
| Image | `createImage3D(parent, name, desc, 0, true, owner)`; size it with `setScale(targetW/unscaledW, targetH/unscaledH, 1)` |
| Font | `HMITerminalImpl.fontLoader.getFont(style, size)` (style 1 plain, 2 bold) |
| Text | `createText3D(parent, name, text, font)`; `setColor(0xRRGGBBAA)` |
| Text width | `EALManager.getTextWidth(String, IWrappedFont)` |
| Own layer | `createViewport` / `createLayer` at index 225, then `setForceInvisible(false)` + `setVisible(true)` |
| Repaint | `fireRenderEvent()` |
| Thread | All EAL work on the HMI thread: `getHMIService().getEventDispatcher().postEvent(new RunnableEvent(job))` |
| Getting the manager | Captured in the patched `AnimationMIB2HighSport.setViewSize` (fallback: `CombiMapController.hmiService`) |

## Traps (each cost a test round)

| Symptom | Cause |
|---|---|
| Panel drawn as a thin white strip (v19) | Argument order is `(buffer, format, w, h)`; ours meant format 400, 200x6 |
| No text (v20) | `getFont` takes `(style, size)`; we asked for size 0 |
| Nothing drawn in our viewport (v25) | `WrappedViewport` hides its 2D link in the constructor; only `setVisible(true)` shows it |
| Text too high (v26) | Text nodes are placed by their baseline: use `top + 0.82 * size` |
| Grey text pink, shadows invisible (v30) | Text colours are `0xRRGGBBAA`, not ARGB (green labels showed faint magenta) |
| `WrappedNode3D.setSize` does nothing visible | It only stores the size; scale images instead |
| 300-870 ms stalls (v24) | Drawing on the HMI thread; pictures are now pre-rendered off it, upload only |

## What the cockpit lets through

The cluster draws its own gauges and pages and shows the head unit's picture only
in fixed windows. Grid photos (`panel grid on`) measured them:

| View | Window | Notes |
|---|---|---|
| Small (tach-centred) | 328x180 at 991,152 | Fixed by the cluster: moving the stock banner does not move it (v30 window test). The UI trim line runs along its top edge |
| Large, car tab / map tab | Stock frame inner box about 210x153 at 1105,110 | The stock frame and the large-view speedometer are drawn above our layer |
| Large, map tab | The CarPlay map area | |

The banner spot shows only while the stock banner (KDK displayable 20) is on.

## Stock banner handling

- Layout class `LayoutMIB2MMICombiTTSport`. Banner position constants 58/59 =
  991,152 (small view) and 60/61 = 1105,110 (large view); crop sizes 120/121 =
  210x153, 124/125 = 328x180.
- Displayable 20 obeys `getDisplayManager().setOpacity(20, 0, alpha)`.
- On every show, `CombiMapController.handleKdkSingleTerminal` sets opacity, position
  and visibility, then `AnimationControllerMIB2High.startKDKAnimation` fades the
  banner in over about 1 s. This overrides our opacity: the stock straight-line
  flash.
- Fix: the `KdkGuard` thread re-applies opacity 0 every 100 ms while our panel is
  up, every 30 ms for 2 s after a show or view change. On the car it stepped in
  8 times at route start, then never again.
- Under the banner sits the EAL `G24_KDK_BACKGROUND` viewport (220, `show/hideKDKBackground`),
  above the main viewport (210). Our viewport 225 is above both.
- Display context: the map is context 10 (both views). While the stock banner is
  up the cluster adds 79 (cluster type 4 "KDK remap"): the map becomes 89, the
  car page 79. In context 89 the stock map covers the CarPlay map, which is why a
  route with the banner on lost the CarPlay map (v32 drive test). v33 watches the
  context and keeps the banner off while the map shows (`/tmp/tt-rgi-kdk-map`
  brings the old behaviour back).
- `IDisplayManagerKombiControl.createImageDisplayable(ResourceLocator, id)` exists;
  an untried way to add an image layer.
