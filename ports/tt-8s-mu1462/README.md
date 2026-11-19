# Audi TT 8S port (MHI2_US_AU43x_P5180 / MU1462)

CarPlay on the Audi TT 8S Virtual Cockpit, ported from this repository's MU1438
AltScreen (GPL-3.0), November 2026.

> **Works on one car (US TT, MU1462).** It modifies system files on the head
> unit and can stop CarPlay working. Do not install it on any other firmware.

**Documentation: [wiki](wiki/Home.md)**: status, how it works, dead ends.

## Folders

| Folder | Contents |
|---|---|
| `package/` | Installers: `altscreen-mu1462-install.sh`, `tt-zoom.sh`, status and preset helpers ([Components](wiki/Components.md)) |
| `hmi/` | Source of `tt-zoom.jar` and its build tools ([HMI patching](wiki/HMI-patching.md)) |
| `kit/` | `tt.sh` toolkit and parked-test scripts ([Build and test](wiki/Build-and-test.md)) |
| `scripts/` | Firmware analysis and patch tools, run against your own firmware copy |
| `docs/` | Panel previews |
| `wiki/` | Documentation |

No firmware is included. See [Credits and exclusions](wiki/Credits.md).

## Rebuilding from your own firmware

| Script | Purpose |
|---|---|
| `unlzo1z.py` | Decompress `mifs-stage2.img` (LZO1Z) |
| `ifsx.py` | Extract `lsd.jxe` from the IFS |
| `qnx6x.py` | Extract files from `app.img` (QNX6) |
| `elfinfo.py`, `hookcheck.py`, `armcalls.py`, `pltname.py` | Inspect ELF imports, hook targets and call sites |
| `contexts.py` | Turn `javap` output of `defineContexts` into a context table |
| `patch_dio_mu1462.py` | Create the hook-first `dio_manager` |
| `assemble.py` | Assemble the stage 1 payload (expects the development scratch layout; adjust paths) |
| `mkrt.py` | Build the small-view `cluster_runtime` (needs capstone) |
| `jarcheck.py` | List stock classes a jar replaces and references it cannot resolve |
| `sumnav.py`, `mkreplay.py` | Summarise a NavSpy log; turn one into a parked replay script |
| `mkbg.py` | Convert a picture into the panel background (`panel-bg.a8`, needs Pillow) |
