"""Hand-laid system architecture diagram (SVG) for wiki/Architecture.md."""
import html
import sys

W, H = 1110, 790
F = "font-family='-apple-system,Segoe UI,Helvetica,Arial,sans-serif'"
C = {
    "apple": ("#ddf4ff", "#0969da"), "stock": ("#f6f8fa", "#8c959f"),
    "ours": ("#dafbe1", "#1a7f37"), "hw": ("#fff8c5", "#bf8700"), "box": ("#ffffff", "#d0d7de"),
}
s = []


def box(x1, y1, x2, y2, kind, title, lines=(), title_size=13, dash=False, rx=8):
    fill, stroke = C[kind]
    d = " stroke-dasharray='5 4'" if dash else ""
    s.append("<rect x='%d' y='%d' width='%d' height='%d' rx='%d' fill='%s' stroke='%s' stroke-width='1.5'%s/>"
             % (x1, y1, x2 - x1, y2 - y1, rx, fill, stroke, d))
    s.append("<text x='%d' y='%d' %s font-size='%d' font-weight='700' fill='#1f2328'>%s</text>"
             % (x1 + 8, y1 + 18, F, title_size, html.escape(title)))
    for i, ln in enumerate(lines):
        s.append("<text x='%d' y='%d' %s font-size='11' fill='#3d444d'>%s</text>"
                 % (x1 + 8, y1 + 34 + 13 * i, F, html.escape(ln)))


def path(pts, label=None, lx=None, ly=None, both=False, dash=False, color="#57606a"):
    d = "M" + " L".join("%d %d" % p for p in pts)
    extra = " stroke-dasharray='5 4'" if dash else ""
    start = " marker-start='url(#a0)'" if both else ""
    s.append("<path d='%s' fill='none' stroke='%s' stroke-width='1.6'%s marker-end='url(#a1)'%s/>"
             % (d, color, extra, start))
    if label:
        tw = 6.1 * len(label) + 8
        s.append("<rect x='%d' y='%d' width='%d' height='15' rx='3' fill='#ffffff' opacity='0.92'/>"
                 % (lx - 4, ly - 11, tw))
        s.append("<text x='%d' y='%d' %s font-size='11' fill='#1f2328'>%s</text>" % (lx, ly, F, html.escape(label)))


s.append("<svg xmlns='http://www.w3.org/2000/svg' width='%d' height='%d' viewBox='0 0 %d %d'>" % (W, H, W, H))
s.append("<defs><marker id='a1' markerWidth='9' markerHeight='9' refX='8' refY='4.5' orient='auto'>"
         "<path d='M0,0 L9,4.5 L0,9 z' fill='#57606a'/></marker>"
         "<marker id='a0' markerWidth='9' markerHeight='9' refX='1' refY='4.5' orient='auto'>"
         "<path d='M9,0 L0,4.5 L9,9 z' fill='#57606a'/></marker></defs>")
s.append("<rect width='100%' height='100%' fill='#ffffff'/>")
s.append("<text x='20' y='32' %s font-size='20' font-weight='700' fill='#1f2328'>TT 8S CarPlay cockpit map: system structure</text>" % F)
# legend
lx = 760
for i, (k, name) in enumerate((("apple", "Apple / Google"), ("stock", "stock Audi / Harman"), ("ours", "ours (this repo)"), ("hw", "hardware"))):
    fill, stroke = C[k]
    x = lx + (i % 2) * 170
    y = 18 + (i // 2) * 20
    s.append("<rect x='%d' y='%d' width='14' height='12' rx='3' fill='%s' stroke='%s'/>" % (x, y, fill, stroke))
    s.append("<text x='%d' y='%d' %s font-size='12' fill='#1f2328'>%s</text>" % (x + 20, y + 11, F, name))

# iPhone + kit
box(380, 52, 720, 140, "box", "iPhone")
box(395, 80, 535, 128, "apple", "Maps app", ["Google / Apple"])
box(555, 80, 705, 128, "apple", "CarPlay (iOS)", ["video + iAP2 over USB"])
box(20, 52, 220, 128, "ours", "tt.sh kit + recorder", ["install, undo, tests, logs", "(you, over SSH)"], dash=True)

# head unit container
box(20, 175, 1090, 640, "box", "Head unit MU1462  ·  QNX 6.5  ·  NVIDIA Tegra", title_size=14)
box(40, 200, 400, 375, "stock", "dio_manager (stock CarPlay process)")
box(55, 228, 225, 278, "stock", "AirPlay receiver", ["session, touch, audio"])
box(55, 310, 225, 360, "stock", "CarPlay-tab video", ["NvSS decoder, layer 59"])
box(245, 228, 385, 360, "ours", "our hook", ["libaltscreen111.so", "loaded first", "2nd stream on TCP 6031", "tee -> 127.0.0.1:19820", "zoom in: UDP 19822", "writes mode_screen", "spawns the supervisor"])
box(420, 200, 580, 300, "stock", "mm-ipod (iAP2)")
box(435, 228, 565, 285, "ours", "rgd hook", ["chefranov, preloaded", "(you supply it)"])
box(600, 200, 1060, 375, "stock", "HMI  ·  Java on J9 (lsd.jxe)")
box(615, 228, 825, 360, "ours", "tt-zoom.jar", ["ZoomGate: wheel zoom, views", "Layers: layer 60 in map lists", "RgdBus: route guidance in", "TtRgi + StripText: strip text", "TtPanel: our turn panel", "Card, AutoZoom"])
box(845, 228, 1045, 360, "stock", "stock HMI", ["contexts (map, CarPlay tab...)", "ClusterService, bottom strip", "KDK banner window", "nav map (stock)"])
box(100, 405, 220, 470, "ours", "supervisor v9", ["starts once,", "restarts if it dies"])
box(240, 405, 440, 470, "ours", "renderer (build 6)", ["cluster_runtime: NvSS, layer 60", "output opened once per session", "picture on/off in ~40 ms"])
box(600, 405, 740, 470, "box", "/tmp state", ["mode_screen, tt-map-view,", "sport marker, heartbeat"], rx=4)
box(40, 525, 560, 615, "stock", "nvdisp: display driver", ["hands out the display controller's few hardware windows (overlays)", "a second video player asking for a taken window gets \"Window is in use\""])
box(620, 525, 1060, 615, "stock", "Display manager", ["composes each context from a layer list (set with dmdt)", "map 10 = {16 HMI, 60 CarPlay map}", "map + banner 89 = {20 banner, 16, 60}"])

# hardware
box(120, 670, 360, 730, "hw", "display windows", ["few hardware overlays"])
box(420, 670, 680, 730, "hw", "12.3\" cockpit LCD", ["one display for everything"])
box(880, 670, 1060, 730, "hw", "steering-wheel scroll", ["map scale up / down"])

# edges
path([(590, 128), (590, 150), (140, 150), (140, 228)], "USB: main stream (CarPlay tab)", 150, 146)
path([(630, 128), (630, 162), (315, 162), (315, 228)], "cluster map stream  ⇅  zoom, showUI", 330, 172, both=True)
path([(670, 128), (670, 186), (548, 186), (548, 228)], "iAP2 route guidance", 556, 198)
path([(140, 278), (140, 310)])
path([(340, 360), (340, 405)], "tee", 346, 390)
path([(270, 360), (270, 385), (160, 385), (160, 405)], "spawns", 170, 383)
path([(220, 438), (240, 438)])
path([(565, 256), (615, 256)], "19810", 572, 250)
path([(615, 340), (385, 340)], "zoom UDP 19822", 450, 336)
path([(825, 294), (845, 294)], both=True)
path([(1060, 700), (1078, 700), (1078, 300), (1045, 300)], "scale", 1040, 690)
path([(680, 360), (680, 405)], "map view", 686, 392)
path([(380, 360), (380, 392), (620, 392), (620, 405)], "mode_screen", 470, 390)
path([(600, 438), (440, 438)], "read every 25 ms", 465, 434)
path([(340, 470), (340, 525)], "layer 60", 346, 505)
path([(70, 360), (70, 525)], "layer 59", 76, 505)
path([(790, 360), (790, 525)], "layer lists", 796, 505)
path([(950, 360), (950, 525)], "context switches", 956, 505)
path([(620, 570), (560, 570)])
path([(240, 615), (240, 670)])
path([(360, 700), (420, 700)])
s.append("<text x='20' y='770' %s font-size='12' fill='#59636e'>Main paths: cockpit map = CarPlay -> hook -> renderer -> layer 60;  CarPlay tab = AirPlay receiver -> layer 59.  Both need a display window: see Display-window handover.</text>" % F)
s.append("</svg>")
open(sys.argv[1], "w", encoding="utf-8").write("\n".join(s))
print("ok")
