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
