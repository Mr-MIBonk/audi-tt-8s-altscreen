#!/usr/bin/env python3
"""Make supervisor v5 from the installed 4776-byte cluster_supervisor.sh v2 (sha 9175a6de...).

usage: python3 -I mksup.py altscreen-cluster_supervisor.sh out/cluster_supervisor-v5.sh

Car tests (runs 33-37): opening the CarPlay tab could leave it black until CarPlay gave up and
dropped the session; with the renderer switched off it never happened (55 openings).
v3 (dropped): without v2's "dmdt sc 0 901" the map views lost the CarPlay map and the banner,
and it still crashed. v4 (run38/39): starting the renderer only after 4 s of car screen made
the crash rare (it came 12 ms after a renderer had just started) but the map took ~7 s to
come back after the CarPlay tab.

v5: v2, but the renderer starts only while a map view shows. tt-zoom.jar v41+ writes
/tmp/tt-map-view ("1" on the map views, "0" elsewhere); flips between the car tab and the
CarPlay tab therefore never start it, and on the map it starts 1 s after the car has the screen
(/tmp/mu1462-start-delay: other whole seconds). Without that file it behaves like v2. It still
stops the renderer whenever the CarPlay tab takes the screen, keeps the switch to 901, checks
that "sleep 0.2" really sleeps and logs its version.
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


rep("# (mode_screen=2), and show it in place of the stock map (context 10).\n",
    "# (mode_screen=2), and show it in place of the stock map (context 10). tt v5: start it only\n"
    "# while a map view shows (/tmp/tt-map-view from tt-zoom.jar), so flips between the car tab\n"
    "# and the CarPlay tab never start it (run38: the crash came while one was starting up).\n")
rep("screen=\nlast_screen=x",
    "# \"sleep 0.2\" must really sleep; otherwise poll once a second.\n"
    "s0=$SECONDS\n"
    "sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null\n"
    "if test $((SECONDS - s0)) -ge 1; then NAP=0.2; PER_SEC=5; else NAP=1; PER_SEC=1; fi\n"
    "START_SECS=1\n"
    "if test -r /tmp/mu1462-start-delay; then\n"
    "    read -r d < /tmp/mu1462-start-delay\n"
    "    case \"$d\" in ''|*[!0-9]*) ;; *) START_SECS=$d;; esac\n"
    "fi\n"
    "START_POLLS=$((START_SECS * PER_SEC))\n"
    "MAPVIEW=/tmp/tt-map-view\n"
    "# No file (tt-zoom.jar not running): behave like v2.\n"
    "map_view() {\n"
    "    test -r \"$MAPVIEW\" || return 0\n"
    "    mv=\n"
    "    read -r mv < \"$MAPVIEW\"\n"
    "    test \"$mv\" != 0\n"
    "}\n"
    "\n"
    "screen=\nlast_screen=x")
rep('log "supervisor $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N])"',
    'log "supervisor v5 $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N], nap $NAP, start ${START_SECS}s on the map view)"')
rep('    if test -z "$child_pid" && test "$car_polls" -ge 5; then',
    '    if test -z "$child_pid" && test "$car_polls" -ge "$START_POLLS" && map_view; then')
rep("    sleep 0.2\ndone\n", "    sleep \"$NAP\"\ndone\n")
open(dst, "wb").write(s.encode("ascii"))
print(dst, len(s), hashlib.sha256(s.encode("ascii")).hexdigest())
