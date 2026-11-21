#!/usr/bin/env python3
"""Make a parked replay of recorded iPhone route-guidance messages (tt-zoom v58+).

    python3 mkrgdreplay.py tt-rgd.log T0 T1 out.txt [--road "Ramp"] [--dest "Test Destination"] [--loop]

T0/T1 are seconds in the log's own clock (first column / 1000). The script:
  1. replays every logged update before T0 silently into one "seed" state (the route, its
     maneuvers and lanes as far as the log has them),
  2. then sends each update between T0 and T1 at its recorded time (rgd lines, to the ms),
  3. and repeats from the seed when --loop is given.
The car plays it with:  cp out.txt /tmp/tt-rgi-play.txt   (stop: sh tt.sh stop)

The log keeps the first 700 bytes of each update and writes non-ASCII bytes as '?', so the
last, cut field of a long update is dropped and runs of '?' in current_road / destination are
replaced (--road / --dest). Everything else is sent exactly as recorded.
"""
import argparse
import io
import re

ap = argparse.ArgumentParser()
ap.add_argument("log")
ap.add_argument("t0", type=float)
ap.add_argument("t1", type=float)
ap.add_argument("out")
ap.add_argument("--road", default="Ramp")
ap.add_argument("--dest", default="Test Destination")
ap.add_argument("--loop", action="store_true")
o = ap.parse_args()

LINE = re.compile(r"^(\d+) rgd #\d+ @routeguidance \| (.*)$")


def fields(body):
    cut = body.endswith(" ...")
    if cut:
        body = body[:-4]
    parts = body.split(" | ")
    if cut:
        parts = parts[:-1]          # the last field was cut at 700 bytes
    out = []
    for p in parts:
        k = p.split(":", 2)
        if len(k) != 3 or not k[0]:
            continue
        key, typ, val = k
        if "?" in val and set(val) <= {"?"}:
            if key == "current_road":
                val = o.road
            elif key == "destination":
                val = o.dest
        out.append((key, typ, val.replace("|", "/")))
    return out


seed = {}
events = []
for line in io.open(o.log, encoding="utf-8", errors="replace"):
    m = LINE.match(line.rstrip("\n"))
    if not m:
        continue
    t = int(m.group(1)) / 1000.0
    f = fields(m.group(2))
    if t < o.t0:
        for key, typ, val in f:
            seed[key] = (typ, val)
    elif t <= o.t1:
        events.append((t, f))

if not events:
    raise SystemExit("no updates between T0 and T1")


def rgd(f):
    return "rgd " + "|".join("%s:%s:%s" % (k, t, v) for k, t, v in f)


out = ["# Replay of recorded iPhone route guidance, %.1f-%.1f s of %s (%d updates)" % (o.t0, o.t1, o.log, len(events)),
       "# Plays through the live path (tt-zoom v58+). Stop: sh tt.sh stop",
       "say replay start",
       "rgdclear",
       rgd([(k, t, v) for k, (t, v) in sorted(seed.items())]),
       "wait 3000"]
last = events[0][0]
for t, f in events:
    gap = int(round((t - last) * 1000))
    if gap > 0:
        out.append("wait %d" % gap)
    last = t
    out.append(rgd(f))
out.append("say replay end")
if o.loop:
    out.append("wait 5000")
    out.append("loop")
data = "\n".join(out) + "\n"
io.open(o.out, "w", encoding="utf-8", newline="\n").write(data)
print("%s: %d updates, %.0f s, %d bytes" % (o.out, len(events), events[-1][0] - events[0][0], len(data.encode("utf-8"))))
