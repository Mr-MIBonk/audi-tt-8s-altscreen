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

## Hook fix1: a busy port no longer blocks CarPlay

Car log (run32): after the iPhone dropped, each reconnect loaded the hook again, but the
renderer tee port 127.0.0.1:19820 was still held by the old session. The hook logged
`cannot start local H264 tee; AltScreen disabled fail-closed` and returned before it looked
up the stock `AirPlayReceiverSession*` functions; its exported replacements still took the
calls and found no stock delegate (`FATAL no stock SessionSetup delegate`), so every setup
failed and the CarPlay icon only flickered (about 30 attempts, 11 frames each).

`scripts/patch_hook.py` changes one instruction in the shipped `libaltscreen111.so`
(`mov r3, r6` -> `mov r3, #1` before the tee's `bind_listener_ipv4`): with 19820 busy the tee
takes a free port, the hook finishes its start-up and CarPlay connects. The cockpit renderer
still connects to 19820, so the cockpit map waits for the old holder to go. Install with
`sh tt.sh hookfix` (keeps the original, `sh tt.sh hookfix undo`), then restart the MMI.
Open: which process keeps 19820 (`sh tt.sh diag` records it). Likely related: the hook
spawns `cluster_supervisor.sh` without close-on-exec on its listening sockets.

The TT runs the h320 safe-area preset of the hook (`36aedadb...`, 13 bytes in the safe-area
table differ from the shipped build); `patch_hook.py` and `sh tt.sh hookfix` handle both.

## CarPlay-tab crash

Run33: each new session first works (main screen stream 110 set up, cockpit renderer attached),
then the whole session drops with no request (`GEN2 TEARDOWN entry request=NULL reason=0`,
then `reason=-6753`). The 378 s drop came 8 s after the CarPlay tab was opened (110 set up at
365 s, left at 370 s), matching "CarPlay tab black, then crash". Suspect: the cockpit renderer
keeps an NvSS decoder open on display 0, the same display the stock CarPlay main screen uses.
`sh tt.sh crash` flips to the CarPlay tab with the renderer on, then off
(`/tmp/mu1438-cluster-disable`); `save` now keeps `sloginfo` (stock decoder messages).

Runs 35-37 (renderer off from the start): 55 CarPlay-tab openings, no session drop. The
installed supervisor (4776 bytes, `9175a6de...`) already ran the renderer only while
`mode_screen=2` (in all logs `mode_screen=1` comes about 10 ms before the CarPlay tab's stream
110 is set up, `2` just before it is torn down). But while the renderer drew it also switched
the display to its own context 901 with `dmdt sc 0 901` whenever it saw the stock map context
10, behind the HMI; a tab flip between its `gs` and its `sc` leaves the display on 901 while the
HMI shows the CarPlay tab. Fix: supervisor v3 (`scripts/mksup.py`, generated from the installed
one, not committed) without that switch, since tt-zoom v37+ puts layer 60 into context 10
itself; it also checks that `sleep 0.2` really sleeps and logs its version. Install with
`sh tt.sh sup` (keeps v2, `sh tt.sh sup undo`), then replug. The supervisor's own log is
`/tmp/mu1462-supervisor.log` (kept by `save` since v40).

Run38 (v3 installed): still dropped on the first flip test. The drop came 12 ms after a
renderer had just started (v2/v3 start it 1 s after the car gets the screen back): the CarPlay
tab opened while the renderer was still setting up its video output on the same display. A
flip at 101.9 s, with the renderer running for 2 s and stopped cleanly, did not drop.
With v3 the Classic and Sport map views also lost the CarPlay map and the banner: the jar's
layer lists alone do not bring CarPlay onto the plain map, v2's switch to 901 does (and it
was not the crash cause). Supervisor v4 is therefore v2 plus: it starts the renderer only after the car has held the screen 4 s
(`/tmp/mu1462-start-delay`), so quick flips never start it; test switch
`/tmp/mu1462-keep-renderer` keeps it running on the CarPlay tab (do both fit on one display?).
`sh tt.sh crash` now tests quick flips, long stays and the keep switch; each `c` also stores a
slice of `sloginfo` (stock dio_manager/AirPlay messages) in `/tmp/tt-slog-marks.txt`.

Run39 (v4): one crash all session, but the map took about 7 s to come back after the CarPlay
tab (4 s wait + renderer start + switch). Supervisor v5 (`scripts/mksup.py`) is v2 with one
condition: the renderer starts only while a map view shows. tt-zoom v41 writes
`/tmp/tt-map-view` (1 on contexts 10/89, else 0, polled every 200 ms); flips between the car
tab and the CarPlay tab never start it, on the map it starts 1 s after the car has the screen,
and it keeps running on the car tab so map <-> car stays instant. Without the file it behaves
like v2. v41 also switches the jar's layer lists back at once when the iPhone's link ends, and
retries the real context switch for up to 20 s while the banner is still up (unplugged during
a route: the map stayed black). Remaining: rare crash (map view -> CarPlay tab right after the
renderer started), and the replug flicker (busy tee port; needs a native fix).

Run40 (v41 + v5): no crash in 20+ car tab <-> CarPlay tab flips (renderer never started). Map
view <-> CarPlay tab still dropped once: the CarPlay tab opened 0.76 s after a renderer had
attached; flips 2 s after an attach were fine. Each renderer start creates a video output on
display 0 ("Created output ... displayId:0"); a start overlapping the CarPlay tab's own video
start is the trigger. After the drop every reconnect hit the busy tee port until an MMI
restart. Kit: `sh tt.sh unstick` records `diag`, then stops leftover supervisor/renderer
processes whose session (dio_manager PID, last argument) is gone; `sh tt.sh delay N` sets the
renderer start delay on the map view (read at the next connect). dio_manager gets a new PID
for every CarPlay session (so the hook's constructor runs once per session). A real fix needs
the native renderer (keep its video output across the CarPlay tab instead of closing and
reopening it) and the hook (close-on-exec on its listening sockets).

Native build (2026-11-19, WSL + qnx65-armv7-toolchain GCC 4.9.4): upstream
`carplay/src/native` rebuilt unchanged gives the shipped `libaltscreen111.so` and
`cluster_runtime` byte for byte in every loaded section (only debug info differs).
Hook TT build 1 (`sh tt.sh hookfix`, sha `028b4a73...`): `-DMU1462_TT_SAFE_H320` (all three
views 400x320 at 520,110, same as the h320 preset), listening sockets `FD_CLOEXEC`, and the
stock `AirPlayReceiverSession*` functions looked up first so a fail-closed start still leaves
plain CarPlay. Compared with the h320 build: same imports/exports, same strings and data
(strings reordered), 136 bytes more code. Supervisor v6 = v5 plus the test switch
`/tmp/mu1462-keep-renderer` (keep the renderer on the CarPlay tab).

**CarPlay-tab crash: cause and fix (run41/43).** Run41 (v6 without the switch): the drop came
again 0.5 s after a renderer start; the hook fix worked (no busy port on any reconnect). Run43
(keep switch on): 49 CarPlay-tab openings with the renderer running, no drop; one renderer
process for the whole session, decoder never closed. While the CarPlay tab holds the screen
the renderer cannot bind its output ("NvMediaVideoMixerBindOutput: Unable to Create YUV
Display", retried) and binds again afterwards ("Created output"): the hardware is shared
without trouble; only opening/closing the renderer while the CarPlay tab started its video
dropped the session. Remaining: fast flips sometimes left the CarPlay tab showing the map -
v2's `dmdt sc 0 901` (12 switches in run43) racing the HMI's switch to the CarPlay tab.
Supervisor v7: renderer started once after 3 s of car screen, never stopped for the CarPlay
tab, no display switching. tt-zoom v42: the layer re-apply also works with the banner up
(context 0 -> 79 and back to 89). Failed reconnects in run41 ended before any CarPlay session
setup (USB/iAP2 level, not the hook): try another cable/port.

## Window handover stage 1 (runs 50-51)

Crash mechanism, caught with `sh tt.sh rec on`: the head unit's own CarPlay video and our
renderer cannot hold a display window at the same time. When the CarPlay tab opens while the
renderer still has one, nvdisp logs `Window is in use`, the head unit's decoder times out
(`NVSS_STATUS_TIMED_OUT`) and the iPhone ends the session about 4.5 s later. Supervisor v6 made
this likely two ways: it killed the renderer only after polling (0.2 s, sometimes too late), and
its `dmdt gs` call hung forever whenever the display manager stopped answering (process watch:
dmdt blocked on the display manager), after which nothing stopped or started the renderer.

Stage 1:
- `cluster_runtime` built with `-DMU1462_TT` (carplay/src/native/cluster_runtime.c): output 0,
  the Sport crop shift in C (was scripts/mkrt.py), and pause/resume. SIGUSR1 closes the video
  output and drops the stream connection, SIGUSR2 opens it again; the log gives both times.
- `cluster_supervisor-v8.sh` (ports/tt-8s-mu1462/carplay): starts the renderer once, pauses it
  on every non-map screen, resumes it on the map view, restarts it only if it exits. No dmdt.
- Kit: `sh tt.sh handover` / `handover undo` (flash, two files), `sh tt.sh manual on|off` and
  `sh tt.sh pause|resume` for timing tests by hand.

Stage 2 (after stage 1 numbers): the hook pauses the renderer when the tab opens and holds the
head unit's video setup until the window is free.
