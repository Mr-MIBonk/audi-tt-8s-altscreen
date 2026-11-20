# CarPlay map

[Home](Home.md)

## Map window

iOS lays the map out inside the safe area the hook reports. Several presets were
compared on the car (`package/safe-preset.sh`); `h320` fits the TT window best.

## Small-view layout

"Classic/Sport" on this car is the cockpit's large/Sport view size; the skin
stays 1 (Sport) throughout.

**How it works:** `tt-zoom.jar` creates `/tmp/mu1438-cluster-sport` in the small
view and deletes it in the Classic view. The patched renderer (`scripts/mkrt.py`)
re-reads the decoder attributes every 8 frames and, while the file exists, crops
the source at x = 453: crop (453,0,987,540) drawn at (0,0,987,540).

NvSSVideoSetAttribs layout used: byte 8 = 1; bytes 12-24 source crop x,y,w,h;
bytes 28-40 screen rectangle; byte 60 = 1, byte 61 = 0.

| Tried | Result |
|---|---|
| Hook preset `auto`: switch only the safe area on a view change | Failed: iOS accepted `updateViewArea` (status 0), but Apple and Google Maps did not re-layout |
| Hook preset `auto2`: switch to view 2 with a 720-wide area | Failed, same reason |
| Detect the change in `DisplayManagerEvo.setupKDKBackground` / `setSkin` | Runs only once at start-up |
| Detect it in `DSICarTimeUnitsLanguageManager.updateSkin` | Also only once (the skin never changes) |
| **Shift the picture in `cluster_runtime`** (as yuedizhibo's MHI2Q AltScreen does for B9 Sport) | **Works** |
| **Detect the size change in static `AnimationMIB2HighSport.setViewSize(eal, layout, small)`** | **Works** |

## Steering-wheel zoom

The wheel's map zoom arrives as `AbstractGUI.increment/decrement` (gesture scale
id 400898) and `CombiBAPListener.setMapScale`. `ZoomGate` checks whether the
CarPlay renderer is drawing (heartbeat file `/tmp/mu1438-cluster-active` is
fresh). If so, the step goes to the hook as an `MZ01` UDP datagram and the stock
map is left alone; otherwise the stock code runs.

- CarPlay's zoom direction is the reverse of the stock one; `/tmp/tt-zoom-invert` flips it.
- Every decision is logged to `/tmp/tt-zoom.log`.

### Auto zoom at turns (v47)

`local.tt.AutoZoom` uses the same path: when a turn is within 250 m (motorway exits and forks
600 m) it sends 2 zoom-in steps (`/tmp/tt-autozoom-steps`, 1-6), once per maneuver, and the same
steps out 3 s after the turn (or when the route ends or the turn moves far away again). Back-to-back
turns stay zoomed in. Kit: `sh tt.sh autozoom on|off|steps N`. Whether the apps keep a zoom level
set this way during guidance is still to be checked on the car.

### Map tilt

There is no known cluster URL option or command for pitch. Google Maps already draws its cluster
map in 3D; Apple Maps draws it top-down. That is the app's choice and cannot be changed from the car.

## The iPhone's own maneuver card

The hook asks the iPhone for `maps:/car/instrumentcluster` (map with the app's card) or
`.../map` (map only), plus `?showSpeedLimit&showCompass&showETA&maneuverLayout=`
(`leftAligned`, `rightAligned`, `topAligned`). The surface comes from
`/tmp/mibr-alt111-url-mode` (or `/mnt/app/root/mibr-carplay111-nav.surface`), the layout from
`/mnt/app/root/mibr-carplay111-nav.maneuverLayout`. They are read when CarPlay connects and
whenever the hook sends `showUI`; touching `/tmp/mibr-alt111-show-only` makes it send `showUI`
again while connected. There is no option for map tilt or auto zoom (only zoom steps,
`changeMapZoomLevel`). tt-zoom v44 switches the surface per view: Classic with card, Sport map
only (`sh tt.sh card`).
v46 switches it by distance instead: the card shows only near a turn (1 km, motorway exits
and forks 2 km, plus 10 s at route start and 5 s after a turn), map only otherwise, in both views.
The card cannot be made see-through: the iPhone draws it into the video.

Defaults (user, 2026-11-20): card at the top (`sh tt.sh card top`), the app's own ETA bar off
(`sh tt.sh eta off` writes `no` to `/mnt/app/root/mibr-carplay111-nav.showETA`; the car's bottom
strip already shows ETA/distance), standard safe window. The map options are sent only while
`/mnt/app/root/mibr-carplay111-nav-query.enabled` exists; the SD installer creates it.
Tried: `look low1` (safe window 520,110 400x360) puts the car lower during guidance but the app's ETA
bar then sits behind the car's bottom strip.

## The bottom strip

The cockpit map's bottom strip (NaviScreenBag6 map view, `MapStatuslineLabelContainer`) is a
turn-point icon (choice model 69) and two labels: model 62, the current street
(`ClusterService.updateCurrentStreet`), and model 71, the street after the next turn
(`updateTurnToStreet`). `ClusterService.refreshStreetMode` shows the icon and the turn-to street
while the bargraph is on (the approach, about the last 430 m, motorway 1750 m) and the current
street otherwise. Altitude and scale sit beside it. TtRgi feeds both streets from the iPhone
(stock nav overwrites the current street with its map-matched one now and then; TtRgi resends
within 2 s). v54 words them: "Left to Alpha St" (`sh tt.sh strip turn|always|plain`).

## How far ahead the map shows

The iPhone is told the stream is 1440 x 540 px on a 320 x 120 mm screen, with a 400 x 320 safe
window at (520,110) (car logs: `physical=320x120`, `safe=400x320@520,110`). The real 12.3" panel
is about 292 x 110 mm. With the card on the side (`card left|right`) the card takes about half of
the 400 px safe window, and the map and the app's ETA bar move over (car photos, v44).

Hook TT build 2 (`sh tt.sh hookfix`, sha 347a9114…) reads two RAM-only test files when the
iPhone connects, so sizes can be tried with a replug and no flash write:

| File | Content | Kit command |
|---|---|---|
| `/tmp/tt-hook-mm` | `W H`, screen size in mm told to the iPhone | `sh tt.sh look 1..4` (320x120, 430x160, 580x215, 780x290), `look mm W H` |
| `/tmp/tt-hook-safe` | `X Y W H`, safe window for all three views | `sh tt.sh look safe X Y W H` |

The idea under test: a bigger reported screen means a lower pixel density, so iOS should draw
the cluster map and its labels smaller and show more road. Not yet confirmed on the car.
