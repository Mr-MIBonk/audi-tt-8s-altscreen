#!/usr/bin/env python3
"""Make supervisor v4 from the installed 4776-byte cluster_supervisor.sh v2 (sha 9175a6de...).

usage: python3 -I mksup.py altscreen-cluster_supervisor.sh out/cluster_supervisor-v4.sh

Car tests (runs 33-37): opening the CarPlay tab could leave it black until CarPlay gave up and
dropped the session; with the renderer switched off it never happened (55 openings).

v3 (dropped): removed v2's "dmdt sc 0 901" (switch to context 901 {16 60} while the renderer
draws on the stock map context 10). Run38: still crashed, and the Classic and Sport map views
then showed the stock map and no banner, so that switch is what brings CarPlay onto the plain
map. v4 is built on v2 again and keeps it.

v4 (run38): the drop came 12 ms after a renderer had just started (v2 starts it 1 s after the
car gets the screen back), so the CarPlay tab opened while it was still setting up its video
output on the same display. v4 starts the renderer only after the car has held the screen for
4 s (/tmp/mu1462-start-delay holds other whole seconds), so quick tab flips never start it.
Test switch /tmp/mu1462-keep-renderer: never stop the renderer for the CarPlay tab.
Also checks that "sleep 0.2" really sleeps (else polls once a second) and logs its version.
Kept from v2: the renderer runs only while the car owns the screen (mode_screen=2).
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
    "# (mode_screen=2), and show it in place of the stock map (context 10). tt v4: starts the\n"
    "# renderer only after the car has held the screen START_SECS (4 s), so quick tab flips\n"
    "# never start it (run38: a renderer still starting up when the CarPlay tab opened).\n")
rep("screen=\nlast_screen=x",
    "# \"sleep 0.2\" must really sleep; otherwise poll once a second.\n"
    "s0=$SECONDS\n"
    "sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null\n"
    "if test $((SECONDS - s0)) -ge 1; then NAP=0.2; PER_SEC=5; else NAP=1; PER_SEC=1; fi\n"
    "START_SECS=4\n"
    "if test -r /tmp/mu1462-start-delay; then\n"
    "    read -r d < /tmp/mu1462-start-delay\n"
    "    case \"$d\" in ''|*[!0-9]*) ;; *) START_SECS=$d;; esac\n"
    "fi\n"
    "START_POLLS=$((START_SECS * PER_SEC))\n"
    "KEEP=/tmp/mu1462-keep-renderer\n"
    "if test -e \"$KEEP\"; then keep=yes; else keep=no; fi\n"
    "\n"
    "screen=\nlast_screen=x")
rep('log "supervisor $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N])"',
    'log "supervisor v4 $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N], nap $NAP, start ${START_SECS}s, keep $keep)"')
rep("    elif test -n \"$screen\"; then\n        car_polls=0\n        stop_child\n",
    "    elif test -n \"$screen\"; then\n        car_polls=0\n        test -e \"$KEEP\" || stop_child\n")
rep('    if test -z "$child_pid" && test "$car_polls" -ge 5; then',
    '    if test -z "$child_pid" && test "$car_polls" -ge "$START_POLLS"; then')
rep("    sleep 0.2\ndone\n", "    sleep \"$NAP\"\ndone\n")
open(dst, "wb").write(s.encode("ascii"))
print(dst, len(s), hashlib.sha256(s.encode("ascii")).hexdigest())
