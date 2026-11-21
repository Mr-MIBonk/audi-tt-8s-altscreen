"""Two SVG charts for the wiki page Display-window-handover.md (measured values from car runs)."""
import html
import os
import sys

out = sys.argv[1]
os.makedirs(out, exist_ok=True)
FONT = "font-family='-apple-system,Segoe UI,Helvetica,Arial,sans-serif'"


def hbar(path, title, subtitle, rows, unit, vmax, note):
    # rows: (label, value, colour, value_text)
    w, left, bar_w, row_h, top = 800, 250, 400, 34, 78
    h = top + row_h * len(rows) + 52
    s = ["<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='%d' viewBox='0 0 %d %d'>" % (w, h, w, h),
         "<rect width='100%' height='100%' rx='10' fill='#ffffff' stroke='#d0d7de'/>",
         "<text x='24' y='34' %s font-size='19' font-weight='700' fill='#1f2328'>%s</text>" % (FONT, html.escape(title)),
         "<text x='24' y='56' %s font-size='13' fill='#59636e'>%s</text>" % (FONT, html.escape(subtitle))]
    for i, (label, v, col, txt) in enumerate(rows):
        y = top + i * row_h
        bw = max(2, int(bar_w * min(v, vmax) / vmax))
        s.append("<text x='%d' y='%d' %s font-size='13' fill='#1f2328' text-anchor='end'>%s</text>" % (left - 12, y + 19, FONT, html.escape(label)))
        s.append("<rect x='%d' y='%d' width='%d' height='22' rx='4' fill='%s'/>" % (left, y + 4, bw, col))
        s.append("<text x='%d' y='%d' %s font-size='13' font-weight='600' fill='#1f2328'>%s</text>" % (left + bw + 8, y + 19, FONT, html.escape(txt)))
    s.append("<text x='24' y='%d' %s font-size='12' fill='#59636e'>%s</text>" % (h - 18, FONT, html.escape(note)))
    s.append("</svg>")
    open(os.path.join(out, path), "w", encoding="utf-8").write("\n".join(s))


GREY, RED, AMBER, GREEN, BLUE = "#8c959f", "#cf222e", "#bf8700", "#1a7f37", "#0969da"
hbar("map-return-latency.svg",
     "How long until the CarPlay map is back",
     "Median, from the head unit's \"screen back on the car\" to our map output on (car logs)",
     [("v6: kill + restart renderer", 1129, GREY, "~1.1 s (run56 r1)"),
      ("stage 1b keepkd", 1264, GREY, "1.26 s (r2)"),
      ("stage 1b no map-flag wait", 906, GREY, "0.91 s (r3)"),
      ("hide, build 2", 247, AMBER, "247 ms (r5)"),
      ("toggle-aware, build 5", 338, AMBER, "338 ms (run59)"),
      ("build 6 (no jar wait)", 40, GREEN, "~25-50 ms (expected)")],
     "ms", 1300,
     "Close mode re-opens the video output and waits for a key frame; hide/toggle keeps it open. Build 6 not yet measured.")
hbar("crash-evidence.svg",
     "Which CarPlay-tab openings crashed",
     "Black CarPlay tab, then the iPhone drops the session (car logs, runs 33-59)",
     [("renderer started/stopped < 1.2 s", 12.1, RED, "4 of 33 openings"),
      ("v6, supervisor hung (no stop)", 1.5, RED, "1 of 67 (run50)"),
      ("other openings, v3-v6", 0.65, AMBER, "1 of 154"),
      ("renderer off, light-speed flips", 0, GREEN, "0 of 53"),
      ("output kept open (hide builds)", 0, GREEN, "0 of ~60 normal"),
      ("output kept open, light-speed", 0, AMBER, "most 5-15 s bursts crash (accepted)")],
     "%", 16,
     "Bars: share of openings that crashed. Light-speed = switching every 0.3-0.6 s; accepted as out of scope.")
print("ok")
