# TT 8S port wiki

How the CarPlay AltScreen was brought to the Audi TT 8S Virtual Cockpit
(MHI2_US_AU43x_P5180, MU1462, G24), and what was learned on the way. Dead ends
are kept, with the evidence, so nobody has to repeat them.

Everything marked "works" was checked on one car (US TT, MU1462), November 2026.

## Status

| Feature | State | Page |
|---|---|---|
| CarPlay map (Apple/Google Maps) on the cockpit map tab | Works | [CarPlay map](CarPlay-map.md) |
| Large/small view (tach-centred) layout | Works | [CarPlay map](CarPlay-map.md#small-view-layout) |
| Steering-wheel scroll zoom | Works | [CarPlay map](CarPlay-map.md#steering-wheel-zoom) |
| iPhone turn-by-turn data on the head unit | Works | [Turn-by-turn data](Turn-by-turn-data.md) |
| Turn panel on the cockpit (arrows, lanes, exit badge) | Works parked; live drive pending | [Turn panel](Turn-panel.md) |
| Stock guidance display fed with iPhone turns | Not possible | [Stock guidance dead ends](Stock-guidance-dead-ends.md) |

## Pages

**The car**
- [How the TT differs](TT-differences.md): one display, MMI-Kombi, contexts, firewall
- [Components](Components.md): what is installed where

**Features**
- [CarPlay map](CarPlay-map.md): safe area, small-view shift, wheel zoom
- [Turn-by-turn data](Turn-by-turn-data.md): getting route guidance from the iPhone
- [Turn panel](Turn-panel.md): our guidance panel, its pictures and its history

**Internals**
- [HMI patching](HMI-patching.md): how `tt-zoom.jar` overrides stock classes, and the rules
- [Cockpit drawing](Cockpit-drawing.md): drawing our own nodes with the EAL, and its traps
- [Stock guidance dead ends](Stock-guidance-dead-ends.md): why the stock banner cannot show iPhone turns

**Working on it**
- [Build and test](Build-and-test.md): build, `tt.sh` toolkit, parked tests, logs
- [Credits and exclusions](Credits.md): third-party code, what is never committed
- [Working with Claude](Working-with-Claude.md): how this was built with Claude Code, prompts and tips

## Next

- v31/v32 parked check: grey text, top line, the new pictures (`play new`).
- Parked routes in both apps, then `sh tt.sh seen` / `save`: does iOS send the
  whole route up front? Which fields does the hook pass on?
- Then: real junction shapes, roundabout exit stubs, exit label field, "then" preview.
- Live drive with Google and Apple Maps.
- Try the iPhone's own maneuver card (hook switches `/mnt/app/root/mibr-carplay111-nav*`).
- Refresh the installer `package/` with the final jar; SD-card (M.I.B.) installer.
