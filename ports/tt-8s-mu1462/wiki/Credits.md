# Credits and exclusions

[Home](Home.md)

## Third-party code and work this port builds on

| Code | From | Licence | Use |
|---|---|---|---|
| Upstream AltScreen (hook, renderer, supervisor, installers) | [aberbic/Audi-MHI2-Virtual-Cockpit-Altscreen-CarPlay-AndroidAuto](https://github.com/aberbic/Audi-MHI2-Virtual-Cockpit-Altscreen-CarPlay-AndroidAuto) | GPL-3.0 | Base of this port; its full history is kept in this repository |
| `hmi/src/local/tt/ManeuverMapper.java` | [luka-dev/mib2q-carplay-rgi](https://github.com/luka-dev/mib2q-carplay-rgi) | GPL-3.0 | Unchanged apart from the package |
| CPHB bus protocol, small-view crop idea | [yuedizhibo/MHI2Q-CarPlay-AltScreen](https://github.com/yuedizhibo/MHI2Q-CarPlay-AltScreen) | GPL-3.0 | `RgdBus` is our own implementation; the crop is the same approach |
| `librgd_hook.so` (route guidance from the iPhone) | [chefranov](https://github.com/chefranov) / [tehfalcon-vw/mhi2-nar-carplay-maps](https://github.com/tehfalcon-vw/mhi2-nar-carplay-maps) | No redistribution | Used unmodified on the car, **not** included |
| Converting `lsd.jxe` to a jar | [luka-dev/jxe2jar](https://github.com/luka-dev/jxe2jar) | See its repository | Build input for the HMI patches |
| QNX 6.5 ARM toolchain | [luka-dev/qnx65-armv7-toolchain](https://github.com/luka-dev/qnx65-armv7-toolchain) | See its repository | Upstream native builds |
| SD-card toolbox | [M.I.B. More Incredible Bash](https://github.com/Mr-MIBonk/M.I.B._More-Incredible-Bash) | See its repository | Root access and the planned SD-card installer |

The upstream project in turn credits [harman-f](https://github.com/harman-f),
[luka-dev](https://github.com/luka-dev), [f-io/LIVI](https://github.com/f-io/LIVI) and
[binarybase](https://github.com/binarybase) (see `NOTICE`).

Public references used for the maneuver research: Apple's
[CPManeuverType](https://developer.apple.com/documentation/carplay/cpmaneuvertype) and
[CPManeuver](https://developer.apple.com/documentation/carplay/cpmaneuver), and Google's
[Navigation SDK maneuvers](https://developers.google.com/maps/documentation/navigation/ios-sdk/reference/objc/Enums/GMSNavigationManeuver).

## Never committed

- Firmware and any stock Audi/Harman file.
- Converted HMI jars, and `tt-zoom.jar` (it contains patched stock classes).
- The patched `cluster_runtime` and `dio_manager`, and the generated `cluster_supervisor.sh`.
- Panel background pictures (third-party art and trademarks).
- Car photos with real map areas or locations; the photos in `docs/photos/` are
  cropped, show demo street names only and have no metadata.

The scripts in `scripts/` rebuild the patched files from your own firmware copy.
