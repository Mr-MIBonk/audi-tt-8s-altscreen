#!/usr/bin/env python3
"""Make supervisor v3 from the installed 4776-byte cluster_supervisor.sh (sha 9175a6de...).

usage: python3 -I mksup.py altscreen-cluster_supervisor.sh out/cluster_supervisor-v3.sh

Car tests (runs 33-37): opening the CarPlay tab could leave it black until CarPlay gave up and
dropped the session; with the renderer switched off it never happened (55 openings). v2 switched
the display to its own context 901 {16 60} with "dmdt sc 0 901" whenever it saw the stock map
context 10, behind the HMI's back; a tab flip between its "gs" and its "sc" leaves the display
on 901 while the HMI shows the CarPlay tab. Since tt-zoom v37 (Layers) context 10 itself holds
the CarPlay layer while CarPlay draws, so v3 never switches. Kept: the renderer runs only while
the car owns the screen (mode_screen=2) and stops as soon as the CarPlay tab takes it.
v3 also checks that "sleep 0.2" really sleeps (else polls once a second) and logs its version.
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


rep("""# (mode_screen=2), and show it in place of the stock map (context 10).
""", """# (mode_screen=2). tt v3: never switches the display itself (no "dmdt sc 0 901": it raced
# tab flips and left the CarPlay tab black); tt-zoom.jar puts the CarPlay layer into the
# stock contexts instead.
""")
# the poll interval: QNX sleep may not take fractions
rep("""screen=
last_screen=x""", """# "sleep 0.2" must really sleep; otherwise poll once a second.
s0=$SECONDS
sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null
if test $((SECONDS - s0)) -ge 1; then NAP=0.2; START_POLLS=5; else NAP=1; START_POLLS=1; fi

screen=
last_screen=x""")
rep("""log "supervisor $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N])\"""",
    """log "supervisor v3 $$ started for parent $parent_pid (dc attempts $i, pty [$PTY_N], nap $NAP)\"""")
rep("""    if test -z "$child_pid" && test "$car_polls" -ge 5; then""",
    """    if test -z "$child_pid" && test "$car_polls" -ge "$START_POLLS"; then""")
# drop the context switching
i = s.index("    # Only replace the stock map, and only once frames are being drawn.\n")
j = s.index("    sleep 0.2\ndone\n")
s = s[:i] + "    sleep \"$NAP\"\ndone\n" + s[j + len("    sleep 0.2\ndone\n"):]
open(dst, "wb").write(s.encode("ascii"))
print(dst, len(s), hashlib.sha256(s.encode("ascii")).hexdigest())
