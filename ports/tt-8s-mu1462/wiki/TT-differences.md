# How the TT differs from the MU1438 cars

[Home](Home.md)

| Item | MU1438 (upstream project) | TT MU1462 |
|---|---|---|
| Displays | Centre screen and cluster | One: display 0, terminal `main`, 1440x540 (1440x542 in places) |
| Stock map context | 72-77 on terminal 1 | 10 on terminal 0 (both view sizes) |
| CarPlay full screen | Separate screen | Context 78 |
| Cluster type | Not checked | Contexts up to 157, so type 4 (`+79` KDK remap) |
| NvSS video output | 1 | 0 (`NVSS_VIDEO_OUTPUT_DEVICE=0`) |
| TCP 6031 on `carplay0` | Open | Blocked by the stock firewall |

## One display

The TT has no centre screen. The cockpit is the head unit's own picture, but the
cluster shows that picture only through fixed windows: the map area, and the
guidance banner spot. See [Cockpit drawing](Cockpit-drawing.md#what-the-cockpit-lets-through).

## MMI-Kombi variant

`Util.isClusterMMI()` is true (`getScreenRes() == 4`), and much of the navigation
code takes MMI-Kombi branches:

- `FunctionListNaviEvo.initVariantMMIKombi` switches off BAP NavSD functions 23
  (ManeuverDescriptor), 24 (LaneGuidance), 39 (ActiveRGType) and 49 (ExitView).
  The cockpit cannot get a turn arrow or lanes over BAP the way MHI2Q cluster
  cars do.
- `ClusterViewMode.refreshViewMode` returns early; map-tab switching is decided
  in the HMI screens.

## Offline checks on the hook

All 47 symbols the hook resolves exist in the MU1462 `libairplay.so`, and all 5
hooked function prologues match what it expects.
