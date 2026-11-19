# Stock guidance dead ends

[Home](Home.md)

**Conclusion:** the TT's stock guidance banner cannot show iPhone turns. The
arrow and junction picture come from the nav engine's own route and map data,
and it ignores anything we feed it. That is why we draw our own
[turn panel](Turn-panel.md).

## Attempts

| Version | Tried | Result on the car | Lesson |
|---|---|---|---|
| v10 | Stock BAP NavSD path (CombiBAPListener setters) | BAP got everything; cockpit showed nothing | The TT cockpit does not draw BAP navigation |
| chefranov / tehfalcon stack | His full stack (`mhi2-nar-carplay-maps`) | Ran, showed nothing; its installer gate also fails on pdksh (`"$@"` under `set -u`) | It draws into cluster context 80 / displayable 98, which G24 lacks |
| v12 | ClusterService COMBI_NAV_* models (icon, distance, ETA, streets), "route active" | A banner on every tab with a straight arrow and the right distance; the map tab lost the CarPlay map | The banner is the nav engine's view; distance from HMI data, arrow from its empty route |
| v13/v14 | Live modes, stock-shaped icons, NavSpy logging, parked playback | Nothing new | The logging made the next steps possible |
| v15 | Exact stock sequence (states 1-4, bar, junction arms) | A parked replay of a recorded stock drive showed nothing | The COMBI_NAV_* models are not drawn on the TT at all |
| v16 | RouteInfoElements into KOMOService four ways | Nothing | The engine reports its view not visible without its own route |
| v17 | Forced the KOMO view visible during a CarPlay route | Blank banner | Visibility can be forced; content cannot |
| v18 | Cycled RG modes (RGI, KDK, compass, map) and view styles | Still blank; `setRgSelect` never answered | The engine draws only from its own route |

## How the stock banner works

- It is the nav engine's KOMO/KDK view, a separate displayable (20). The HMI shows
  it when `ClusterKDKHandler` sees `komoViewEnabled && komoViewVisible && rgActive`.
- View style on MMI-Kombi: `KOMOCaller.getKomoViewStyle()` = 3. Layout files on
  `app.img`: `guidanceview_*_293x323.xml`, `KDKConfig_293x323.kdx`.
- On the map tab this view replaces the CarPlay map (the v12 effect).
- The HMI feeds it "nav info" (`DSIKOMONavInfo`: distances, ETA, streets).
  `ClusterService.refreshDistanceToNextManeuverMOST` marks the distance invalid
  while the bar is on, which is why v17/v18 showed none.
- MHI2Q cluster cars are different: their cluster is a separate computer that
  draws turns from BAP data, which is why luka's approach works there.

## Recorded stock behaviour (NavSpy, presentation mode and a real drive)

- Icon stream: `{mainElement, direction 0-255, side streets as signed bytes}`.
  Left turn `{13,64,-1,0,-64}`, right turn `{13,192,-1,64,0}`, motorway exit
  `{15,192,-1}`, fork `{19,64}`, follow road `{11,255}`, prepare `{12,dir}`,
  calculating `{9,x}`, off-road `{6,dir}`, recalculating `{10,dir}`.
- `updateTurnToStreet` ignores its boolean; the label shows only when the street
  is non-empty and the bar is on.
- Stock nav without a route still calls `updateRgActive(false)` /
  `updateRGIString(null)` now and then, so anything fed must be re-sent.
