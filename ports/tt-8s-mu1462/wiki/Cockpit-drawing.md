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
| Large, map tab | The whole screen (v33 full grid) | |
| Small, map showing | The map left of the tach: x 0 to about 520, top edge a diagonal from (0,110) to (200,50), bottom about 440 | Only with the stock banner off |

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
- Stock `DisplayManagerMIB2High.defineContextsForG24`: every context N below 79 gets a
  twin N + 79 with exactly the same displayables plus the banner (20) on top. So
  context 89 is not a different layout; what paints the stock map over CarPlay must
  be something the banner request triggers (likely the nav engine's guidance view).
  v36 experiment `/tmp/tt-kdk-direct` opens the window with `setKDKVisible(20, 0)`
  and never asks for the guidance view. Result: still context 89, no guidance-view
  events in `tt-nav.log`, and the CarPlay map was still lost; map and panel showed
  together only for a moment while the window closed (89 -> 10). That rules out the
  nav engine's view.
- Context layer lists (Java `defineContexts`): 10 = {16, 19}, 89 = {20, 16, 19},
  79 = {20, 16}, 78 = {16, 59}. Native names from MU0678 `dmdt`: 16 HMI, 19 MAPVIEWER,
  20 MAP_ROUTE_GUIDANCE (328x180, the banner window), 59 EXTERNAL_SMARTPHONE; the
  CarPlay picture is layer 60 (`cluster_runtime`, context 901 = {16, 60}).
  Candidate cause: with the banner, layer 19 (stock map) is composed above layer 60.
  On MU0678 `dmdt dc` redeclared an existing context in memory, so `sh tt.sh layers`
  tries other lists for 89 without touching flash.
- Layer test result (v36b, `dmdt dc` works on the TT; changes apply at the next switch
  into the context): the CarPlay map shows with the banner only when layer 60 is in the
  list. {20 16} and {16 19 20}: map area empty, panel in the window. {20 16 60},
  {16 60 20}, {20 60 16}: CarPlay map plus the banner window, both views, same look. After
  60 had been in a list, the plain map {16 19} showed the stock map again, so v37 sets both:
  10 = {16 60}, 89 = {20 16 60} while CarPlay draws, the stock lists otherwise
  (`local.tt.Layers`). The display manager keeps its lists across an HMI-only restart.
  The HMI skips a switch to the context it is already in, so a new list cannot be forced
  from Java without a real switch.
- Contexts logged by v33 (both views): map 10; map with banner 89; car page with
  banner 79. Every tab switch passes through 78 and 157 (78 + 79) for under a
  second: map to car is 10, 78, 157, 79; car to map is 79, 157, 89, 10.
- `IDisplayManagerKombiControl.createImageDisplayable(ResourceLocator, id)` exists;
  an untried way to add an image layer.
