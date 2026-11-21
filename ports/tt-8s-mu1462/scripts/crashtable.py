"""Every CarPlay-tab opening across the saved runs, with what the cockpit renderer was doing.

Hook log (altscreen111.log, seconds of uptime):
  MODES_CHANGED ... screen=1        CarPlay tab owns the screen, screen=2 car (cockpit map etc.)
  SETUP entry streams=1 types=110   head unit sets up the main CarPlay video (the tab)
  TEARDOWN ... main110=1            main video torn down normally (left the tab)
  TEARDOWN whole-session            the session ended (crash, or unplug)
  MU1438 runtime spawn=PID          supervisor PID spawned (its log clock starts about here)
Supervisor log (seconds since its start): runtime started / stopped / exited.
"""
import os
import re
import sys

A = sys.argv[1]
detail = len(sys.argv) > 2


def num(s):
    return float(s)


rows = []
for run in sorted(os.listdir(A), key=lambda s: int(s[3:])):
    hook = os.path.join(A, run, "altscreen111.log")
    if not os.path.exists(hook):
        continue
    ev = []  # (t, kind, info)
    spawns = []
    for line in open(hook, encoding="utf-8", errors="replace"):
        m = re.match(r"(\d+\.\d+) \[altscreen111\] (.*)", line)
        if not m:
            continue
        t, msg = num(m.group(1)), m.group(2)
        if "MODES_CHANGED parsed" in msg:
            sc = re.search(r" screen=(\d+)", msg)
            ev.append((t, "screen", int(sc.group(1))))
        elif msg.startswith("SETUP entry streams=1 types=110"):
            ev.append((t, "setup110", None))
        elif "TEARDOWN entry" in msg and "main110=1" in msg:
            ev.append((t, "down110", None))
        elif "TEARDOWN whole-session" in msg:
            ev.append((t, "session_end", None))
        elif msg.startswith("MU1438 runtime spawn="):
            pid = re.search(r"spawn=(\d+)", msg).group(1)
            spawns.append((t, pid))
            ev.append((t, "spawn", pid))
        elif "renderer tee listening" in msg:
            ev.append((t, "hook_start", None))
    # supervisor events mapped to hook time through its spawn
    sup = os.path.join(A, run, "mu1462-supervisor.log")
    rend = []  # (t, 'start'|'stop'|'exit')
    supver = "-"
    if os.path.exists(sup):
        cur_base = None
        for line in open(sup, encoding="utf-8", errors="replace"):
            m = re.match(r"(\d+)s (.*)", line)
            if not m:
                continue
            s, msg = int(m.group(1)), m.group(2)
            sm = re.match(r"supervisor (v\d+) (\d+) started", msg)
            if sm:
                supver = sm.group(1)
                pid = sm.group(2)
                cur_base = None
                for t, p in spawns:
                    if p == pid:
                        cur_base = t
                continue
            if cur_base is None:
                continue
            t = cur_base + s
            if re.match(r"runtime \d+ started", msg):
                rend.append((t, "start"))
            elif re.match(r"runtime \d+ stopped", msg):
                rend.append((t, "stop"))
            elif "exited by itself" in msg:
                rend.append((t, "exit"))
    ev.sort()
    screen = None
    last_screen_change = None
    prev_screen_dwell = None
    open_tab = None  # (t_screen1, t_setup)
    for i, (t, kind, info) in enumerate(ev):
        if kind == "screen":
            if info != screen:
                if last_screen_change is not None:
                    prev_screen_dwell = t - last_screen_change
                last_screen_change = t
            screen = info
        elif kind == "setup110":
            # renderer state at this moment
            before = [r for r in rend if r[0] <= t + 0.5]
            state = before[-1][1] if before else ("?" if not rend else "none")
            since = (t - before[-1][0]) if before else None
            after = [r for r in rend if t + 0.5 < r[0] <= t + 6]
            # outcome
            outcome = "?"
            t_end = None
            for t2, k2, _ in ev[i + 1:]:
                if k2 == "down110":
                    outcome = "ok"
                    t_end = t2
                    break
                if k2 == "session_end":
                    outcome = "CRASH" if t2 - t < 20 else "end"
                    t_end = t2
                    break
            rows.append({
                "run": run, "sup": supver, "t": t, "state": state, "since": since,
                "after": after, "outcome": outcome, "dt": (t_end - t) if t_end else None,
                "dwell": prev_screen_dwell,
            })

def f(x):
    return "-" if x is None else "%.1f" % x

if detail:
    for r in rows:
        if r["outcome"] != "ok" or detail == 2:
            print("%-6s %-4s t=%7.1f renderer=%-5s since=%5s after=%-22s dwell_before=%5s -> %s in %s" % (
                r["run"], r["sup"], r["t"], r["state"], f(r["since"]),
                ",".join("%s@+%.1f" % (k, tt - r["t"]) for tt, k in r["after"]) or "-",
                f(r["dwell"]), r["outcome"], f(r["dt"])))
    print()

from collections import defaultdict
agg = defaultdict(lambda: [0, 0, 0])
for r in rows:
    a = agg[r["run"]]
    a[0] += 1
    if r["outcome"] == "CRASH":
        a[1] += 1
    if r["outcome"] in ("?", "end"):
        a[2] += 1
sups = {}
for r in rows:
    sups[r["run"]] = r["sup"]
print("run    sup  openings crashes other")
for run in sorted(agg, key=lambda s: int(s[3:])):
    a = agg[run]
    print("%-6s %-4s %8d %7d %5d" % (run, sups[run], a[0], a[1], a[2]))
