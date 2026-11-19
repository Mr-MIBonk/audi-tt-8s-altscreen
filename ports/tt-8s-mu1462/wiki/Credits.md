# Credits and exclusions

[Home](Home.md)

## Third-party code

| Code | From | Licence | Use |
|---|---|---|---|
| Upstream AltScreen (hook, renderer, supervisor, installers) | aberbic/Audi-MHI2-Virtual-Cockpit-Altscreen-CarPlay-AndroidAuto | GPL-3.0 | Base of this port |
| `hmi/src/local/tt/ManeuverMapper.java` | luka-dev/mib2q-carplay-rgi | GPL-3.0 | Unchanged apart from the package |
| CPHB bus protocol | yuedizhibo/MHI2Q-CarPlay-AltScreen | GPL-3.0 | `RgdBus` is our own implementation |
| Small-view crop idea | yuedizhibo/MHI2Q-CarPlay-AltScreen (B9 Sport) | GPL-3.0 | Approach only |
| `librgd_hook.so` | chefranov | No redistribution | Used unmodified on the car, **not** included |

## Never committed

- Firmware and any stock Audi/Harman file.
- Converted HMI jars, and `tt-zoom.jar` (it contains patched stock classes).
- The patched `cluster_runtime` and `dio_manager`, and the generated `cluster_supervisor.sh`.
- Panel background pictures (third-party art and trademarks).

The scripts in `scripts/` rebuild the patched files from your own firmware copy.
