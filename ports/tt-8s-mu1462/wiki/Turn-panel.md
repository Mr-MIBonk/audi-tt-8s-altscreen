# Turn panel

[Home](Home.md)

Our own guidance panel, drawn in the stock banner window on every view (map tab
included), fed live from the iPhone ([Turn-by-turn data](Turn-by-turn-data.md)).

![v32 pictures](../docs/panel-preview-v32.png)

## Layout

| View | Panel | Frame |
|---|---|---|
| Small (tach-centred), car page | 328x170 at 991,160, just under the trim line | Our own: chamfered top-right corner, light border, red accent |
| Small, map showing (v35) | 328x170 at 130,76, over the map left of the tach (the banner window is gone with the banner off) | Our own |
| Large, car tab | 210x150 at 1105,110 | The stock frame |
| Large, map tab (v33) | 210x150 at 1105,110, over the CarPlay map | Our own (stock banner off, it hides the map) |

- Left: thin cylinder-shaded progress bar, then the maneuver picture, centred in its area.
- Right column, rows spread evenly and each centred: top line (small view:
  distance to destination and arrival time; large view: arrival time), big
  distance with a small unit, green "EXIT 12A" badge, street.
- Without an exit number the street becomes the main line; without lanes it
  moves to the bottom.
- Lanes run across the bottom during the approach: preferred white, good light
  grey, others dark. A lane with two directions shares one stem.
- Geometry lives in `KdkLayout`, shared by the picture and the text nodes.
- Text: HMI fonts with a dark shadow node. The distance shrinks instead of being
  cut; the top line tightens, shrinks, then drops AM/PM before using "...".

## Rendering

All in plain Java (no AWT on the car), in `PanelArt.kdkStyled`, off the HMI thread:

1. Gradient background, then the user's picture (optional, see below).
2. Frame (small view only).
3. Maneuver drawn flat at 2x, split into route (white) and side streets (grey),
   laid on the road in perspective, then extruded with side walls, a lit top
   face, an edge highlight and a blurred shadow.
4. Lanes: flat dashes, raised arrows. Exit badge.
5. The static part is cached per maneuver; a bar update only copies it and
   redraws the bar. A full draw takes 10-15 ms on the car.

**Background picture:** `/mnt/app/root/tt/panel-bg.a8`, a centred, faint alpha
mask with its proportions kept, made with `scripts/mkbg.py`. Pictures stay out of
git; without the file there is no background.

## Pictures

| Picture | Code | iAP2 types |
|---|---|---|
| Turn (slight / normal / sharp) with side streets | 13 | 1, 2, 3, 6, 16, 47-51 |
| Highway exit | 15 / 16 | 8, 22, 23 |
| Fork / keep left or right | 19 | 13, 14 |
| Roundabout with the exit taken | 21 / 22 | 28-46 |
| U-turn | 25 | 4, 18, 26 |
| U-turn at a roundabout | 21 / 22, dir 128 | 19 |
| Follow road | 11 | 0, 5 |
| Arrival flag | 3 | 10, 12, 27 |
| Arrive, destination left / right | 3, dir 64 / 192 | 24, 25 |
| Leave the roundabout | 26 / 27 | 7 |
| On-ramp merge | 40 | 9 |
| End of road (T) | 41 | 20, 21 |
| Start of route | 42 | 11 |
| Change lanes left / right | 43 | 52, 53 |
| Ferry | 44 | 15, 17 |

Codes 40-44 are TT-local: `RgdBus.stockSafe` never passes them to the stock
cluster. Code 12 stays stock's "prepare" icon, so lane change got its own code.

## Stock banner behaviour

- The stock banner is on for a CarPlay route in every view; `/tmp/tt-rgi-nokdk`
  turns it off.
- Its picture is kept at opacity 0 while our panel is up ([Cockpit drawing](Cockpit-drawing.md#stock-banner-handling)).
- After our panel goes, the banner stays transparent (no black box); stock
  navigation fades its own banner back in.

## History

| Version | Change | Result |
|---|---|---|
| v19-v20 | First EAL nodes | Drew, after fixing texture and font argument order |
| v21 | Real panel (300x340) at the banner spot | Too big in the large view; hidden in the small view |
| v22-v23 | Compact panel; then left/right banners on the map | Banners drew but were clipped by the screen's corners; the stock frame covered the small view |
| v24-v26 | Banner opacity, own viewport 225, pre-rendering | v26: first drawing visible on the cockpit |
| v27 | One 210x150 panel in the stock frame everywhere ("original style"), opacity watcher, calibration grid | Flash gone; window sizes measured |
| v28 | Wide 328x170 panel under the trim line in the small view | Fit; looked like a pasted-on slab, "1..." cut-offs |
| v29-v30 | TT-styled frame, 3D arrows, exit badge, background picture, centred layout (five PC mockups first) | Looked right; pink text, cut top line |
| v31 | RGBA text colours, top-line fitting | |
| v32 | Nine new pictures, fixed roundabout U-turn, research log | Pictures as previewed; live route: the stock banner hid the CarPlay map |
| v33 | Banner off while the map shows (context 10/89), own frame on the map, full-screen grid | Map kept on live Google and Apple routes in every view; banner back on the car page. At a playback start the banner stayed up about 11 s |
| v34 | Map check reads the live context; the watcher runs for as long as a route is declared | Photos: CarPlay map + framed panel on the large map, panel in the stock frame on the car pages. Small view with the map: map kept, panel not visible (its window is gone) |
| v35 | Small view with the map: panel over the map at 130,76; U-turn lanes drawn as a hook; street names shrink before "..." | Test pending |

Previews: [v27](../docs/panel-preview-v27.png), [v28](../docs/panel-preview-v28.png),
[v29](../docs/panel-preview-v29.png), [v30](../docs/panel-preview-v30.png),
[v32](../docs/panel-preview-v32.png).

## Ideas waiting for data

Real junction shapes and roundabout exit stubs (from the junction angles), the
highway exit label instead of text parsing, and a small "then" arrow when two
maneuvers come close together.
