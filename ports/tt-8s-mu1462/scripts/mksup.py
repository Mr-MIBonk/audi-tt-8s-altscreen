#!/usr/bin/env python3
"""Make supervisor v7 from the installed 4776-byte cluster_supervisor.sh v2 (sha 9175a6de...).

usage: python3 -I mksup.py altscreen-cluster_supervisor.sh out/cluster_supervisor-v7.sh

History (TT car tests):
- runs 33-37: opening the CarPlay tab could leave it black until CarPlay dropped the session;
  with the renderer switched off it never happened (55 openings).
- v3 dropped v2's "dmdt sc 0 901": map views lost the CarPlay map (the jar's layer lists then
  flipped back to stock every time the renderer was stopped) and it still crashed.
- v4/v5/v6: fewer renderer starts made the crash rarer. Every drop came 0.5-1 s after a
  renderer start, while the CarPlay tab's own video was starting.
- run43 (v6 keep switch): renderer kept running through the CarPlay tab: 49 CarPlay-tab
  openings, no drop. Both share the video hardware; only starting/stopping collided. But
  v2's "dmdt sc 0 901" (switch to its own context whenever it saw the plain map) raced fast
  tab flips and left the CarPlay tab showing the map.

v7: the renderer runs for the whole CarPlay session. It starts once the car has held the screen
for 3 s (/tmp/mu1462-start-delay: other whole seconds; avoids the screen flips while CarPlay
connects), is never stopped for the CarPlay tab, and is restarted the same way only if it exits
by itself. No display switching: tt-zoom.jar (v37+) puts the CarPlay layer into the stock map
contexts while the renderer draws. Also checks that "sleep 0.2" really sleeps and logs its
version.
"""
import hashlib
import sys

SRC_SHA = "9175a6deaff6acf2c4f35b61b245476ba8827e7f4b74977b48cdafc2c7c6f57c"
src, dst = sys.argv[1], sys.argv[2]
s = open(src, "rb").read()
assert hashlib.sha256(s).hexdigest() == SRC_SHA, "not the 4776-byte supervisor"
s = s.decode("ascii")
assert "\r" not in s


def rep(a, b):
    global s
    assert s.count(a) == 1, (a[:60], s.count(a))
    s = s.replace(a, b)


rep("# TT MU1462: one display, so the map renderer and main CarPlay cannot both hold\n"
    "# the video hardware. Run the renderer only while the car owns the screen\n"
    "# (mode_screen=2), and show it in place of the stock map (context 10).\n",
    "# TT MU1462, tt v7: the map renderer and main CarPlay CAN share the video hardware (run43:\n"
    "# 49 CarPlay-tab openings with the renderer running, no drop); only starting or stopping it\n"
    "# while the CarPlay tab started its video dropped the session. So the renderer runs for the\n"
    "# whole session: started once the car has held the screen START_SECS (3 s), never stopped\n"
    "# for the CarPlay tab. No display switching (\"dmdt sc 0 901\" raced fast tab flips and left\n"
    "# the CarPlay tab on the map); tt-zoom.jar puts the CarPlay layer into the stock contexts.\n")
rep("screen=\nlast_screen=x",
    "# \"sleep 0.2\" must really sleep; otherwise poll once a second.\n"
    "s0=$SECONDS\n"
    "sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null\n"
    "if test $((SECONDS - s0)) -ge 1; then NAP=0.2; PER_SEC=5; else NAP=1; PER_SEC=1; fi\n"
    "START_SECS=3\n"
    "if test -r /tmp/mu1462-start-delay; then\n"
    "    read -r d < /tmp/mu1462-start-delay\n"
    "    case \"$d\" in ''|*[!0-9]*) ;; *) START_SECS=$d;; esac\n"
    "fi\n"
    "START_POLLS=$((START_SECS * PER_SEC))\n"
    "\n"
    "screen=\nlast_screen=x")
rep('log "supervisor $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N])"',
    'log "supervisor v7 $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N], nap $NAP, start after ${START_SECS}s of car screen, keep running)"')
# never stop for the CarPlay tab; car_polls still only counts uninterrupted car-screen time
rep("    elif test -n \"$screen\"; then\n        car_polls=0\n        stop_child\n",
    "    elif test -n \"$screen\"; then\n        car_polls=0\n")
rep('    if test -z "$child_pid" && test "$car_polls" -ge 5; then',
    '    if test -z "$child_pid" && test "$car_polls" -ge "$START_POLLS"; then')
# no display switching
i = s.index("    # Only replace the stock map, and only once frames are being drawn.\n")
j = s.index("    sleep 0.2\ndone\n")
s = s[:i] + "    sleep \"$NAP\"\ndone\n" + s[j + len("    sleep 0.2\ndone\n"):]
open(dst, "wb").write(s.encode("ascii"))
print(dst, len(s), hashlib.sha256(s.encode("ascii")).hexdigest())
