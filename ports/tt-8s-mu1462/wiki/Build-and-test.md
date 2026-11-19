# Build and test

[Home](Home.md)

## Build

```bash
STOCK_JAR=... ASM_DIR=... JAVA_LIB=... JDK_BIN=... bash hmi/tools/build.sh <tag> <outdir>
```

javac (`--release 8`), PatchZoom, VerifyZoom (ASM verifier), `checklib.py` (every
`java.*` call checked against the car's class library), deterministic jar
(`mkjar.py`). The inputs are your own converted stock jar, ASM 9.7 and the car's
Java library. The jar contains patched stock classes, so it is never committed.

## Toolkit (`kit/tt.sh`)

Copy the kit to `/tmp`, run `sh /tmp/tt.sh setup` once; afterwards, from the SSH
login folder:

| Command | Does |
|---|---|
| `sh tt.sh report` | What is installed and running |
| `sh tt.sh use vNN` | Install a stored jar (sha-checked); then restart the MMI |
| `sh tt.sh play new\|fit\|win\|kdk\|panel\|komo\|stock\|arrows` | Parked test scripts |
| `sh tt.sh stop` | End playback |
| `sh tt.sh seen` | What the iPhone has sent so far (maneuver types, lanes) |
| `sh tt.sh save` | Keep the logs in `/mnt/app/root/tt/logs/runN` |
| `sh tt.sh panel kdk-small\|kdk-large X Y [S]` | Move the panel live |
| `sh tt.sh mode ...` / `remove` | Feed modes / uninstall |

## Parked tests instead of drives

- `RgiPlayer` plays `/tmp/tt-rgi-play.txt` (`wait`, `loop`, `say`, feed commands,
  `panel ...`) and pauses the iPhone feed while it runs.
- `kit/stock-replay.txt` was generated from a recorded stock drive
  (`scripts/mkreplay.py`; `scripts/sumnav.py` summarises a NavSpy log).
- Stock nav's presentation mode simulates a route while parked.
- Routes planned on the iPhone while parked fill the research log
  ([Turn-by-turn data](Turn-by-turn-data.md#research-log-v32)).
- Panel designs are previewed on the PC first, drawn by the car code
  (`PanelArt` + `KdkLayout` with AWT text standing in for the HMI font).

## Logs

| File | Contents |
|---|---|
| `/tmp/tt-rgd.log` | Bus, feed, playback, panel (256 KB + one old file) |
| `/tmp/tt-nav.log` | NavSpy: every ClusterService/KOMOService input and the nav engine's answers |
| `/tmp/tt-zoom.log` | Wheel zoom and view decisions |
| `/tmp/tt-rgd.txt` | Last update as received |
| `/tmp/tt-rgd-cat.txt`, `/tmp/tt-route.txt` | Research log |

`/tmp` on the car is flat and wiped at power-off: run `sh tt.sh save`.

## SSH

```bash
ssh root@<car> -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa
```

scp also needs `-O`.
