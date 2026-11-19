# Turn-by-turn data

[Home](Home.md)

## Path

1. chefranov's `librgd_hook.so` (unmodified, not redistributable) is LD_PRELOADed
   into `mm-ipod` (`package/rgd-test.sh`). `mm-ipod` restarts on every iPhone
   plug-in, so the hook reloads each time.
2. The hook patches iAP2 Identify (adds RouteGuidance 0x001E, component 0x0010).
   It only sends StartRouteGuidanceUpdates (0x5200) while a Java listener is
   connected on 127.0.0.1:19810.
3. Our listener `RgdBus` speaks luka's CPHB protocol: a 16-byte big-endian header
   (magic `CPHB`, seq, u16 type, u8 flags, u8 reserved, u32 length), then
   `key:type:value` text lines for `EVT_RGD_UPDATE` (0x0020). Updates are deltas;
   `RgdBus` keeps the merged state.
4. `RgdBus` turns the state into a stock-shaped icon, a phase and a bar, and
   feeds the [turn panel](Turn-panel.md) (`TtPanel.live`).

## Fields

- Route state, distance to destination and maneuver, ETA, destination name.
- Maneuver list: `mN_type`, `exit_angle` / `turn_angle`, `junction_type`,
  `driving_side`, `name`, `after_road`.
- Lanes (seen from Google Maps): `lgN_index`, `lane_directions`, `lane_angles`, `lane_status`.
- iOS sends a short `route_state 0` about every 30 s, so "route off" is only
  accepted after 6 s.
- No separate exit-number field has been seen yet. `RgdBus.exitNumber` takes the
  token after "exit" in the maneuver text ("Take exit 12A toward ..." gives 12A).

## What the apps actually send (parked, v32 log)

| Item | Google Maps | Apple Maps |
|---|---|---|
| Maneuvers sent | Current and next only (list "0,1" of 12-19) | Current only (list "0" of 22) |
| Lane sets | Up to 6 upcoming | Up to 6 upcoming |
| Junction angles (`exit_angle`, `turn_angle`) | Not sent (1000) | Not sent (1000) |
| Distance to the next turn | Not sent while parked | `dist_maneuver_m` and `mN_distance` sent |
| Text language | Chinese on this phone ("W Copper Lakes Ct方面") | English ("Start on W Copper Lakes Dr") |

So routes planned while parked capture only the first maneuvers; the research
log fills from normal drives. Real junction shapes are not possible from this
data. Exit numbers from non-English instructions need their own patterns.

## Maneuver types

Both apps reach the car through Apple's 54 maneuver types (public as
`CPManeuverType`; the iAP2 list `ManeuverMapper` decodes). Google's own 66 types
(merges, ramp variants, ferry train) are folded into those 54 before CarPlay.

Per maneuver, iOS can also send the junction's exit angle, the other roads'
angles, the traffic side, lanes and a highway exit label (`CPManeuver`). Whether
the hook passes all of them on is still to be checked.

Mapping: luka's `ManeuverMapper` (GPL-3.0, unchanged) plus TT overrides in
`RgdBus.stockCode`; the full table is on the [Turn panel](Turn-panel.md#pictures) page.

## Phases (from stock nav)

| Phase | City | Motorway | Panel shows |
|---|---|---|---|
| 1 follow | > 1250 m | > 3200 m | Straight arrow `{11,255}` |
| 2 prepare | to 1250 m | to 3200 m | `{12,dir}` for turns, else straight |
| 3 approach | to 430 m | to 1750 m | Full picture, bar and lanes |
| 4 at the turn | to 100 m | to 150 m | Same |

Bar: 255 x distance / approach-start distance, counting down. On-ramp and lane
change use the motorway distances.

## Research log (v32)

So maneuvers need not be driven to be seen:

- `/tmp/tt-rgd-cat.txt`: every distinct maneuver (`mN_*`) and lane set (`lgN_*`),
  once each, all keys (distances and times left out of the comparison).
- `/tmp/tt-route.txt`: the whole merged route, rewritten when the maneuver list changes.
- `sh tt.sh seen` counts them by type; `sh tt.sh save` keeps them (they are in RAM).

Open question: does iOS send the whole route's maneuvers when guidance starts?
If so, routes planned while parked capture everything.
