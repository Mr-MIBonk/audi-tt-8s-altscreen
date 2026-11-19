# Components

[Home](Home.md)

| Piece | Where on the car | Role |
|---|---|---|
| `libaltscreen111.so` | `/mnt/app/root/lib-target/`, first `NEEDED` of `dio_manager` | CarPlay alternate-screen session, safe area, zoom datagrams |
| `cluster_runtime` | `/mnt/app/root/mu1438-cluster/` | Draws the CarPlay stream with NvSS on output 0; small-view crop shift |
| `cluster_supervisor.sh` | `/mnt/app/root/mu1438-cluster/` | Declares context 901 (layers 16 and 60) so the MMI layer stays above the map |
| `tt-zoom.jar` | `/mnt/app/eso/hmi/lsd/jars/` | Our Java: zoom, view marker, turn-by-turn feed, turn panel, logging |
| `librgd_hook.so` | LD_PRELOAD into `mm-ipod` | chefranov's hook that asks the iPhone for route guidance (not distributed) |
| Firewall rule | `/mnt/system/etc/pf*.conf` | `pass` for TCP 6031, inserted before the `carplay0` block rule |

## Stage 1: native hook only (no HMI change)

- `dio_manager`: hook added as the first `NEEDED`, stock library order kept.
- `cluster_runtime`: output device changed from 1 to 0.
- `cluster_supervisor.sh`: generated from the stock script (final version 4776 bytes).
- Firewall rule as above.

## Installers (`package/`)

| Script | Does |
|---|---|
| `altscreen-mu1462-install.sh` | `--check` / `--install` / `--restore`, pinned to MU1462 hashes; backup under `/mnt/app/root/altscreen-backups/` |
| `tt-zoom.sh` | Adds or removes `tt-zoom.jar` |
| `status.sh` | Shows what is on flash, changes nothing |
| `safe-preset.sh` | Switches the hook's safe-area preset |
| `sup-update.sh` | Installs the supervisor alone |
| `rgd-test.sh` | Sets up chefranov's hook for testing |

`package/` still holds the early jar; refreshing it is an open item. Day-to-day
testing uses the `kit/` toolkit instead ([Build and test](Build-and-test.md)).
