package local.tt;

/**
 * Software drawing of the cockpit turn panel into an RGBA byte array
 * (no AWT on the head unit). Pure Java 1.4, so it can be previewed on a PC.
 *
 * Coordinates are pixels, origin top-left. Shapes are antialiased by
 * computing per-pixel coverage against thick line segments (distance to the
 * segment) and filled triangles (4x4 supersampling).
 *
 * Maneuvers use the BAP/RGI codes the rest of tt-zoom uses: main element
 * (11 follow, 12 prepare, 13/14 turn, 15/16 exit right/left, 19/20 fork,
 * 21-24 roundabout, 25 U-turn, 3/4 arrived/near destination) and direction
 * 0-255 counter-clockwise from straight ahead (64 left, 128 back, 192 right).
 * Side streets are drawn as grey arms, like the stock junction icon.
 */
public final class PanelArt {
    public static final int BG = 0xE0101418;
    public static final int ROUTE = 0xFFFFFFFF;
    public static final int ARM = 0xFF6E757D;
    public static final int BAR_ON = 0xFFFFFFFF;
    public static final int BAR_OFF = 0xFF3A4048;

    private final int w;
    private final int h;
    /** Premultiplied-free ARGB working buffer. */
    private final int[] px;

    public PanelArt(int w, int h) {
        this.w = w;
        this.h = h;
        this.px = new int[w * h];
    }

    public int width() {
        return w;
    }

    public int height() {
        return h;
    }

    public int[] pixels() {
        return px;
    }

    /** RGBA bytes (texture format 6). */
    public byte[] rgba() {
        byte[] out = new byte[w * h * 4];
        for (int i = 0, j = 0; i < px.length; i++) {
            int c = px[i];
            out[j++] = (byte) (c >> 16);
            out[j++] = (byte) (c >> 8);
            out[j++] = (byte) c;
            out[j++] = (byte) (c >>> 24);
        }
        return out;
    }

    /**
     * The whole panel: rounded background, maneuver picture in the box
     * (ax, ay, as) and, when bar >= 0, a vertical progress bar (255 = far, 0 = at the turn).
     */
    public void panel(int main, int dir, int[] arms, int bar) {
        panel(main, dir, arms, bar, null, null);
    }

    /**
     * With lanes: laneAngles[i] = the arrow angles of lane i in degrees (0 straight,
     * negative left, positive right), laneStatus[i] = 0 not recommended, 1 good, 2 preferred.
     */
    public void panel(int main, int dir, int[] arms, int bar, int[][] laneAngles, int[] laneStatus) {
        java.util.Arrays.fill(px, 0);
        roundRect(0, 0, w, h, 18, BG);
        boolean lanes = laneAngles != null && laneAngles.length > 0;
        int as = Math.min(w - 40, h - (lanes ? 178 : 120));
        int ax = (w - as) / 2 + 10;
        int ay = 14;
        maneuver(main, dir, arms, ax, ay, as);
        if (lanes) {
            lanes(laneAngles, laneStatus, 30, ay + as + 2, w - 44, 58);
        }
        if (bar >= 0) {
            int bx = 14;
            int by = ay + 8;
            int bh = as - 16;
            int filled = (int) ((long) bh * Math.min(255, bar) / 255);
            roundRect(bx, by, 10, bh, 5, BAR_OFF);
            if (filled > 0) {
                roundRect(bx, by + bh - filled, 10, filled, 5, BAR_ON);
            }
        }
    }

    /**
     * Compact panel for the large view (v22): maneuver picture on the left, text area on the
     * right (drawn by HMI text nodes), lane row under the text, thin progress bar on the right edge.
     * Returns nothing; TtPanel places the texts at TEXT_X.
     */
    public void compact(int main, int dir, int[] arms, int bar, int[][] laneAngles, int[] laneStatus) {
        java.util.Arrays.fill(px, 0);
        roundRect(0, 0, w, h, 16, BG);
        int s = h - 16;
        maneuver(main, dir, arms, 6, 8, s);
        if (laneAngles != null && laneAngles.length > 0) {
            lanes(laneAngles, laneStatus, s + 10, h - 50, w - s - 32, 44);
        }
        if (bar >= 0) {
            int bh = h - 24;
            int filled = (int) ((long) bh * Math.min(255, bar) / 255);
            roundRect(w - 14, 12, 7, bh, 3, BAR_OFF);
            if (filled > 0) {
                roundRect(w - 14, 12 + bh - filled, 7, filled, 3, BAR_ON);
            }
        }
    }

    // ---- v23 layouts -------------------------------------------------------------------
    /** Large view, left banner: picture square on the left, text area right, lanes under, bar at the edge. */
    public void banner(int main, int dir, int[] arms, int bar, int[][] laneAngles, int[] laneStatus) {
        java.util.Arrays.fill(px, 0);
        roundRect(0, 0, w, h, 14, BG);
        boolean lanes = laneAngles != null && laneAngles.length > 0;
        int s = lanes ? h - 62 : h - 14;
        maneuver(main, dir, arms, 6, 7, s);
        if (lanes) {
            lanes(laneAngles, laneStatus, 12, h - 54, w - 36, 48);
        }
        if (bar >= 0) {
            int bh = h - 20;
            int filled = (int) ((long) bh * Math.min(255, bar) / 255);
            roundRect(w - 13, 10, 6, bh, 3, BAR_OFF);
            if (filled > 0) {
                roundRect(w - 13, 10 + bh - filled, 6, filled, 3, BAR_ON);
            }
        }
    }

    // ---- v27: one panel inside the stock banner window ---------------------------------
    /** Opaque fill inside the stock banner frame (the frame itself is the HMI's). */
    public static final int KDK_BG = 0xFF0C0F12;
    /** Side of the maneuver square in the kdk layout (smaller when lanes take the bottom row). */
    public static int kdkSquare(int h, boolean lanes) {
        return lanes ? h - 66 : h - 52;
    }

    /** Left edge of the text column right of the square (texts run to w - 6). */
    public static int kdkCol(int h, boolean lanes) {
        return 20 + kdkSquare(h, lanes) + (lanes ? 6 : 4);
    }

    /**
     * v27 (v26 photos): the stock banner frame is drawn above our layer and shows our panel only
     * through its window, so everything lives in one small picture the size of that window:
     * bar on the left edge, maneuver square, texts as HMI nodes (distance under the square, arrival
     * time and exit/street in the right column); with lanes a smaller square and the lanes across the bottom.
     */
    public void kdk(int main, int dir, int[] arms, int bar, int[][] laneAngles, int[] laneStatus) {
        java.util.Arrays.fill(px, KDK_BG);
        if (laneAngles != null && laneAngles.length > 0) {
            // With lanes: smaller square, texts right of it, lanes across the bottom.
            maneuver(main, dir, arms, 20, 4, kdkSquare(h, true));
            lanes(laneAngles, laneStatus, 20, h - 60, w - 26, 56);
        } else {
            maneuver(main, dir, arms, 20, 4, kdkSquare(h, false));
        }
        if (bar >= 0) {
            int bh = h - 16;
            int filled = (int) ((long) bh * Math.min(255, bar) / 255);
            roundRect(7, 8, 7, bh, 3, BAR_OFF);
            if (filled > 0) {
                roundRect(7, 8 + bh - filled, 7, filled, 3, BAR_ON);
            }
        }
    }

    // ---- v29: TT style (user-approved mockups 1-5) ----------------------------------------
    public static final int TT_RED = 0xFFE0001E;
    public static final int EXIT_GREEN = 0xFF0E7B3E;
    /** Optional background picture (alpha mask) on the car: "TTBG", u16 width, u16 height, alpha bytes. */
    public static final String BG_FILE = "/mnt/app/root/tt/panel-bg.a8";
    private static final float BG_ALPHA = 0.22f;
    /** Where loadBg() looks (BG_FILE on the car; the PC preview points it elsewhere). */
    static String bgPath = BG_FILE;
    private static float[] bgMask;
    private static int bgW;
    private static int bgH;
    private static boolean bgTried;
    /** Everything except the bar, per layout (the bar changes every few seconds near a turn). */
    private static final java.util.Hashtable BASE = new java.util.Hashtable();

    /**
     * v29 TT-style panel: dark gradient, the user's background picture centred and faint,
     * perspective 3D arrows (lit top face, side walls, soft shadow), raised lane arrows, a
     * cylinder bar and a green exit badge. framed = our own chamfered frame with a red accent
     * (tach-centred view); otherwise only the gradient (large view, inside the stock frame).
     * Texts are HMI nodes placed by KdkLayout.
     */
    public void kdkStyled(int main, int dir, int[] arms, int bar, int[][] laneAngles, int[] laneStatus,
                          String exit, boolean hasStreet, boolean framed) {
        boolean hasLanes = laneAngles != null && laneAngles.length > 0;
        String label = KdkLayout.badgeLabel(exit);
        KdkLayout l = new KdkLayout(w, h, hasLanes, label.length() > 0, hasStreet);
        StringBuffer k = new StringBuffer().append(w).append('x').append(h).append(',').append(main).append(',')
            .append(dir).append(',').append(label).append(',').append(hasStreet).append(',').append(framed);
        for (int i = 0; arms != null && i < arms.length; i++) {
            k.append(',').append(arms[i]);
        }
        for (int i = 0; hasLanes && i < laneAngles.length; i++) {
            k.append('/').append(laneStatus == null || i >= laneStatus.length ? 0 : laneStatus[i]);
            for (int j = 0; laneAngles[i] != null && j < laneAngles[i].length; j++) {
                k.append(':').append(laneAngles[i][j]);
            }
        }
        String key = k.toString();
        int[] base;
        synchronized (BASE) {
            base = (int[]) BASE.get(key);
        }
        if (base == null) {
            base = new int[w * h];
            drawBase(base, l, main, dir, arms, laneAngles, laneStatus, label, framed);
            synchronized (BASE) {
                if (BASE.size() > 8) {
                    BASE.clear();
                }
                BASE.put(key, base);
            }
        }
        System.arraycopy(base, 0, px, 0, px.length);
        // Cylinder bar: lit in the middle, darker at the sides.
        int barTop = 12;
        int barH = h - 24;
        int filled = bar < 0 ? 0 : (int) ((long) barH * Math.min(255, bar) / 255);
        for (int y = 0; y < barH; y++) {
            boolean on = y >= barH - filled;
            for (int x = 0; x < 7; x++) {
                float cx = (x - 3f) / 3.5f;
                float shade = 1f - 0.55f * cx * cx;
                int c = on ? lerpRgb(0x000000, 0xF4F6F8, shade) : lerpRgb(0x000000, 0x2C3238, 0.7f + 0.3f * shade);
                blend(8 + x, barTop + y, 0xFF000000 | c, 1f);
            }
        }
    }

    private void drawBase(int[] dst, KdkLayout l, int main, int dir, int[] arms, int[][] laneAngles,
                          int[] laneStatus, String label, boolean framed) {
        int n = w * h;
        int cut = framed ? 18 : 0;
        for (int y = 0; y < h; y++) {
            int c = lerpRgb(0x262C33, 0x0A0D11, h <= 1 ? 0f : (float) y / (h - 1));
            for (int x = 0; x < w; x++) {
                float cov = 1f;
                if (cut > 0) {
                    cov = clamp(((w - cut + y) - (x + 0.5f)) * 0.7071f + 0.5f);
                }
                dst[y * w + x] = cov <= 0f ? 0 : ((int) (0xF2 * cov) << 24) | c;
            }
        }
        // The user's picture, centred, proportions kept.
        loadBg();
        if (bgMask != null) {
            float kk = Math.min(w * 0.80f / bgW, h * 0.62f / bgH);
            int bw = Math.max(1, (int) (bgW * kk));
            int bh = Math.max(1, (int) (bgH * kk));
            float[] a = new float[bw * bh];
            for (int y = 0; y < bh; y++) {
                for (int x = 0; x < bw; x++) {
                    a[y * bw + x] = BG_ALPHA * samp(bgMask, bgW, bgH, x * (bgW - 1f) / Math.max(1, bw - 1),
                        y * (bgH - 1f) / Math.max(1, bh - 1));
                }
            }
            overSolid(dst, (w - bw) / 2, (h - bh) / 2, bw, bh, a, 0xC8D2DC);
        }
        // Frame (tach-centred view) or a thin top highlight (large view).
        PanelArt fr = new PanelArt(w, h);
        if (framed) {
            int e = 0xA0B4BEC8;
            fr.thick(0.75f, 0.75f, w - cut - 0.75f, 0.75f, 1.5f, e);
            fr.thick(w - cut - 0.75f, 0.75f, w - 0.75f, cut + 0.75f, 1.5f, e);
            fr.thick(w - 0.75f, cut + 0.75f, w - 0.75f, h - 0.75f, 1.5f, e);
            fr.thick(0.75f, h - 0.75f, w - 0.75f, h - 0.75f, 1.5f, 0x60B4BEC8);
            fr.thick(0.75f, 0.75f, 0.75f, h - 0.75f, 1.5f, e);
            fr.thick(1.5f, 1.5f, w * 0.38f, 1.5f, 3f, TT_RED);
        } else {
            fr.thick(0f, 0.5f, w, 0.5f, 1f, 0x40FFFFFF);
        }
        overLayer(dst, fr.px);
        // 3D maneuver: drawn flat at 2x, split into route (white) and side streets (grey),
        // laid on the road in perspective, then extruded.
        int s = l.square;
        int big = s * 2;
        PanelArt flat = new PanelArt(big, big);
        flat.maneuver(main, dir, arms, 0, 0, big);
        float[] route = warp(dilate(split(flat.px, true), big, big, (int) (big * 0.012f)), big, s);
        float[] arm = warp(split(flat.px, false), big, s);
        solid(dst, l.squareX, l.squareY, s, s, arm, 2, 0x9AA3AC, 0x6E777F, 0x454B52);
        solid(dst, l.squareX, l.squareY, s, s, route, 4, 0xFFFFFF, 0xC8D0D8, 0x8A939C);
        // Lanes: flat dashes, raised arrows.
        if (laneAngles != null && laneAngles.length > 0) {
            PanelArt sep = new PanelArt(w, h);
            sep.laneSeparators(laneAngles.length, 20, l.lanesY, w - 28, l.lanesH);
            overLayer(dst, sep.px);
            PanelArt lp = new PanelArt(w, h);
            lp.laneArrows(laneAngles, laneStatus, 20, l.lanesY - 2, w - 28, l.lanesH);
            float[] white = new float[n];
            float[] grey = new float[n];
            for (int i = 0; i < n; i++) {
                float a = (lp.px[i] >>> 24) / 255f;
                if (((lp.px[i] >> 16) & 0xff) > 0xF0) {
                    white[i] = a;
                } else {
                    grey[i] = a;
                }
            }
            solid(dst, 0, 0, w, h, grey, 2, 0x7C858E, 0x5A6068, 0x30353A);
            solid(dst, 0, 0, w, h, white, 3, 0xFFFFFF, 0xD8DEE4, 0x8A939C);
        }
        // Exit badge (centred in the text column).
        if (label.length() > 0 && l.badgeTop >= 0) {
            PanelArt bd = new PanelArt(w, h);
            int bw = l.badgeW(label);
            int bx = l.badgeX(label);
            bd.roundRect(bx, l.badgeTop, bw, l.badgeH, 5, 0xFFFFFFFF);
            bd.roundRect(bx + 2, l.badgeTop + 2, bw - 4, l.badgeH - 4, 4, EXIT_GREEN);
            overLayer(dst, bd.px);
        }
    }

    /** Reads BG_FILE once (missing file = no background). */
    private static void loadBg() {
        if (bgTried) {
            return;
        }
        bgTried = true;
        try {
            java.io.File f = new java.io.File(bgPath);
            if (!f.exists() || f.length() < 8 || f.length() > 2000000L) {
                return;
            }
            byte[] b = new byte[(int) f.length()];
            java.io.FileInputStream in = new java.io.FileInputStream(f);
            try {
                int off = 0;
                while (off < b.length) {
                    int r = in.read(b, off, b.length - off);
                    if (r < 0) {
                        break;
                    }
                    off += r;
                }
            } finally {
                in.close();
            }
            if (b[0] != 'T' || b[1] != 'T' || b[2] != 'B' || b[3] != 'G') {
                return;
            }
            int bw = ((b[4] & 0xff) << 8) | (b[5] & 0xff);
            int bh = ((b[6] & 0xff) << 8) | (b[7] & 0xff);
            if (bw < 2 || bh < 2 || 8 + bw * bh > b.length) {
                return;
            }
            float[] m = new float[bw * bh];
            for (int i = 0; i < m.length; i++) {
                m[i] = (b[8 + i] & 0xff) / 255f;
            }
            bgW = bw;
            bgH = bh;
            bgMask = m;
        } catch (Throwable ignored) {
            bgMask = null;
        }
    }

    /** Route (white) or side-street (grey) coverage of a flat maneuver picture. */
    private static float[] split(int[] p, boolean route) {
        float[] m = new float[p.length];
        for (int i = 0; i < p.length; i++) {
            float a = (p[i] >>> 24) / 255f;
            int r = (p[i] >> 16) & 0xff;
            float wv = Math.max(0f, Math.min(1f, (r - 0x6E) / (float) (0xFF - 0x6E)));
            m[i] = route ? a * wv : a * (1f - wv);
        }
        return m;
    }

    private static float samp(float[] m, int w, int h, float x, float y) {
        if (x < 0 || y < 0 || x >= w - 1 || y >= h - 1) {
            return 0f;
        }
        int x0 = (int) x;
        int y0 = (int) y;
        float fx = x - x0;
        float fy = y - y0;
        float a = m[y0 * w + x0];
        float b = m[y0 * w + x0 + 1];
        float c = m[(y0 + 1) * w + x0];
        float d = m[(y0 + 1) * w + x0 + 1];
        return (a * (1 - fx) + b * fx) * (1 - fy) + (c * (1 - fx) + d * fx) * fy;
    }

    /** Perspective: the flat square lies on the road, the far end narrower and compressed. */
    private static float[] warp(float[] m, int src, int out) {
        float[] o = new float[out * out];
        for (int y = 0; y < out; y++) {
            float v = y / (float) (out - 1);
            float sy = (float) Math.pow(v, 1.18) * (src - 1);
            float sc = 0.72f + 0.28f * v;
            for (int x = 0; x < out; x++) {
                float u = x / (float) (out - 1);
                o[y * out + x] = samp(m, src, src, (0.5f + (u - 0.5f) / sc) * (src - 1), sy);
            }
        }
        return o;
    }

    private static float[] dilate(float[] a, int w, int h, int r) {
        if (r < 1) {
            return a;
        }
        float[] t = new float[w * h];
        float[] o = new float[w * h];
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                float m = 0f;
                for (int k = -r; k <= r; k++) {
                    int xx = x + k;
                    if (xx >= 0 && xx < w && a[y * w + xx] > m) {
                        m = a[y * w + xx];
                    }
                }
                t[y * w + x] = m;
            }
        }
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                float m = 0f;
                for (int k = -r; k <= r; k++) {
                    int yy = y + k;
                    if (yy >= 0 && yy < h && t[yy * w + x] > m) {
                        m = t[yy * w + x];
                    }
                }
                o[y * w + x] = m;
            }
        }
        return o;
    }

    /** Extruded solid: soft shadow, side walls t px deep, lit top face with a bright front edge. */
    private void solid(int[] dst, int x0, int y0, int sw, int sh, float[] a, int t, int topNear, int topFar,
                       int side) {
        float[] sd = blur(blur(a, sw, sh, 3), sw, sh, 3);
        for (int i = 0; i < sd.length; i++) {
            sd[i] *= 0.8f;
        }
        overSolid(dst, x0 + 3, y0 + t + 4, sw, sh, sd, 0x000000);
        for (int k = t; k >= 1; k--) {
            overSolid(dst, x0, y0 + k, sw, sh, a, lerpRgb(side, 0x1A1E22, 0.5f * k / t));
        }
        int[] top = new int[sw * sh];
        for (int y = 0; y < sh; y++) {
            int c0 = lerpRgb(topFar, topNear, y / (float) sh);
            for (int x = 0; x < sw; x++) {
                int i = y * sw + x;
                float up = y > 0 ? a[i - sw] : 0f;
                float lf = x > 0 ? a[i - 1] : 0f;
                float hl = Math.max(0f, a[i] - up) * 0.9f + Math.max(0f, a[i] - lf) * 0.35f;
                top[i] = lerpRgb(c0, 0xFFFFFF, Math.min(1f, hl));
            }
        }
        overRgb(dst, x0, y0, sw, sh, a, top);
    }

    private void overSolid(int[] dst, int x0, int y0, int sw, int sh, float[] a, int rgb) {
        for (int y = 0; y < sh; y++) {
            int dy = y0 + y;
            if (dy < 0 || dy >= h) {
                continue;
            }
            for (int x = 0; x < sw; x++) {
                int dx = x0 + x;
                float sa = a[y * sw + x];
                if (dx >= 0 && dx < w && sa > 0.003f) {
                    dst[dy * w + dx] = over(dst[dy * w + dx], rgb, sa);
                }
            }
        }
    }

    private void overRgb(int[] dst, int x0, int y0, int sw, int sh, float[] a, int[] rgb) {
        for (int y = 0; y < sh; y++) {
            int dy = y0 + y;
            if (dy < 0 || dy >= h) {
                continue;
            }
            for (int x = 0; x < sw; x++) {
                int dx = x0 + x;
                int i = y * sw + x;
                if (dx >= 0 && dx < w && a[i] > 0.003f) {
                    dst[dy * w + dx] = over(dst[dy * w + dx], rgb[i], a[i]);
                }
            }
        }
    }

    /** A full-size ARGB layer over dst. */
    private void overLayer(int[] dst, int[] layer) {
        for (int i = 0; i < layer.length; i++) {
            int c = layer[i];
            float a = (c >>> 24) / 255f;
            if (a > 0.003f) {
                dst[i] = over(dst[i], c & 0xffffff, a);
            }
        }
    }

    private static int over(int d, int rgb, float sa) {
        float da = (d >>> 24) / 255f;
        float oa = sa + da * (1f - sa);
        if (oa <= 0f) {
            return 0;
        }
        int r = mix((rgb >> 16) & 0xff, (d >> 16) & 0xff, sa, da, oa);
        int g = mix((rgb >> 8) & 0xff, (d >> 8) & 0xff, sa, da, oa);
        int b = mix(rgb & 0xff, d & 0xff, sa, da, oa);
        return ((int) (oa * 255f + 0.5f) << 24) | (r << 16) | (g << 8) | b;
    }

    private static int lerpRgb(int a, int b, float t) {
        int r = (int) (((a >> 16) & 0xff) * (1 - t) + ((b >> 16) & 0xff) * t);
        int g = (int) (((a >> 8) & 0xff) * (1 - t) + ((b >> 8) & 0xff) * t);
        int bb = (int) ((a & 0xff) * (1 - t) + (b & 0xff) * t);
        return (r << 16) | (g << 8) | bb;
    }

    /** Separable box blur of an alpha map. */
    private static float[] blur(float[] src, int w, int h, int r) {
        float[] tmp = new float[w * h];
        float[] out = new float[w * h];
        float norm = 1f / (2 * r + 1);
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                float sum = 0f;
                for (int k = -r; k <= r; k++) {
                    int xx = x + k;
                    if (xx >= 0 && xx < w) {
                        sum += src[y * w + xx];
                    }
                }
                tmp[y * w + x] = sum * norm;
            }
        }
        for (int y = 0; y < h; y++) {
            for (int x = 0; x < w; x++) {
                float sum = 0f;
                for (int k = -r; k <= r; k++) {
                    int yy = y + k;
                    if (yy >= 0 && yy < h) {
                        sum += tmp[yy * w + x];
                    }
                }
                out[y * w + x] = sum * norm;
            }
        }
        return out;
    }

    private static int lerp(int c0, int c1, float t) {
        int a = (int) (((c0 >>> 24) & 0xff) * (1f - t) + ((c1 >>> 24) & 0xff) * t);
        int r = (int) (((c0 >> 16) & 0xff) * (1f - t) + ((c1 >> 16) & 0xff) * t);
        int g = (int) (((c0 >> 8) & 0xff) * (1f - t) + ((c1 >> 8) & 0xff) * t);
        int b = (int) ((c0 & 0xff) * (1f - t) + (c1 & 0xff) * t);
        return (a << 24) | (r << 16) | (g << 8) | b;
    }

    /** v29: solid, opaque dashes (v28's thin translucent ones showed colour fringes on the car). */
    private void laneSeparators(int n, int x, int y, int rw, int rh) {
        int cell = Math.min(54, rw / n);
        int start = x + (rw - n * cell) / 2;
        for (int i = 1; i < n; i++) {
            float sx = start + cell * i;
            for (float yy = y + 6; yy < y + rh - 4; yy += 11f) {
                thick(sx, yy, sx, Math.min(yy + 6f, y + rh - 4), 2.5f, 0xFF7C858E);
            }
        }
    }

    /**
     * v29 lane arrows: like lanes() without separators; a lane with several directions shares one
     * stem and branches lower, so the heads no longer overlap.
     */
    void laneArrows(int[][] angles, int[] status, int x, int y, int rw, int rh) {
        int n = angles.length;
        int cell = Math.min(54, rw / n);
        int start = x + (rw - n * cell) / 2;
        float base = y + rh - 3;
        for (int i = 0; i < n; i++) {
            int st = status == null || i >= status.length ? 0 : status[i];
            int c = st >= 2 ? LANE_PREFERRED : (st == 1 ? LANE_GOOD : LANE_OTHER);
            float cx = start + cell * i + cell / 2f;
            float t = Math.max(3.5f, cell * 0.15f);
            int[] a = angles[i];
            if (a == null || a.length == 0) {
                a = new int[] { 0 };
            }
            boolean multi = a.length > 1;
            float mid = y + rh * (multi ? 0.62f : 0.55f);
            thick(cx, base, cx, mid, t, c);
            for (int k = 0; k < a.length; k++) {
                int d = laneDir(a[k]);
                boolean straight = d == 0;
                float from = multi && !straight ? mid + rh * 0.08f : mid;
                float len = rh * (multi ? (straight ? 0.30f : 0.20f) : 0.22f);
                float[] e = endpoint(cx, from, d, len);
                thick(cx, from, e[0], e[1], t, c);
                laneHead(e[0], e[1], d, rh * (multi ? 0.22f : 0.26f), c);
            }
        }
    }

    /**
     * Calibration grid whose top-left pixel sits at screen (ox, oy): lines on every absolute
     * multiple of 10 px (faint), 50 px (yellow) and 100 px (red), transparent elsewhere.
     */
    public void grid(int ox, int oy) {
        java.util.Arrays.fill(px, 0);
        for (int y = 0; y < h; y++) {
            int ay = oy + y;
            for (int x = 0; x < w; x++) {
                int ax = ox + x;
                int c = 0;
                if (ax % 100 == 0 || ax % 100 == 1 || ay % 100 == 0 || ay % 100 == 1) {
                    c = 0xFFFF3030;
                } else if (ax % 50 == 0 || ay % 50 == 0) {
                    c = 0xE0FFE000;
                } else if (ax % 10 == 0 || ay % 10 == 0) {
                    c = 0x70FFFFFF;
                }
                if (c != 0) {
                    px[y * w + x] = c;
                }
            }
        }
    }

    /** Large view, right banner: destination flag on the left (texts are HMI nodes). */
    public void destination() {
        java.util.Arrays.fill(px, 0);
        roundRect(0, 0, w, h, 14, BG);
        flag(h * 0.5f, h * 0.5f, h * 0.9f);
    }

    /**
     * Small view, the full panel: picture, side bar, lanes, then three text rows drawn by HMI
     * nodes (distance, exit/street, destination) with a separator and a small flag on the last row.
     */
    public void full(int main, int dir, int[] arms, int bar, int[][] laneAngles, int[] laneStatus) {
        java.util.Arrays.fill(px, 0);
        roundRect(0, 0, w, h, 18, BG);
        boolean lanes = laneAngles != null && laneAngles.length > 0;
        int as = Math.min(w - 40, h - 174 - (lanes ? 58 : 0));
        int ax = (w - as) / 2 + 10;
        int ay = 12;
        maneuver(main, dir, arms, ax, ay, as);
        if (lanes) {
            lanes(laneAngles, laneStatus, 30, ay + as + 2, w - 44, 56);
        }
        if (bar >= 0) {
            int by = ay + 8;
            int bh = as - 16;
            int filled = (int) ((long) bh * Math.min(255, bar) / 255);
            roundRect(14, by, 9, bh, 4, BAR_OFF);
            if (filled > 0) {
                roundRect(14, by + bh - filled, 9, filled, 4, BAR_ON);
            }
        }
        thick(16f, h - 56f, w - 16f, h - 56f, 1.5f, 0x60FFFFFF);
        flag(32f, h - 28f, 38f);
    }

    /** Maneuver picture inside the square (x, y, s). */
    public void maneuver(int main, int dir, int[] arms, int x, int y, int s) {
        float cx = x + s / 2f;
        float jy = y + s * 0.52f;
        float bottom = y + s * 0.97f;
        float len = s * 0.38f;
        float route = s * 0.11f;
        float arm = s * 0.07f;
        if (main == 3 || main == 4 || main == 5 || main == 38) {
            flag(cx, y + s * 0.5f, s);
            return;
        }
        if (main >= 21 && main <= 24) {
            roundabout(cx, jy, s, dir, main == 22 || main == 24);
            return;
        }
        if (main == 25) {
            uturn(cx, bottom, s, (dir & 0xff) < 128 || (dir & 0xff) == 128);
            return;
        }
        // Side streets first, so the route is drawn on top of them.
        if (arms != null) {
            for (int i = 0; i < arms.length; i++) {
                int a = arms[i] & 0xff;
                if (a == 255) {
                    continue;
                }
                float[] e = endpoint(cx, jy, a, len);
                thick(cx, jy, e[0], e[1], arm, ARM);
            }
        }
        int d = dir & 0xff;
        if (main == 11 || main == 6 || main == 9 || main == 10 || d == 255) {
            d = 0;
        }
        if (main == 19 || main == 20) {
            // Fork: a Y; the route takes one branch, the other is grey.
            boolean left = d > 0 && d < 128;
            d = left ? 26 : 230;
            float[] o = endpoint(cx, jy, left ? 230 : 26, len);
            thick(cx, jy, o[0], o[1], route * 0.9f, ARM);
        }
        if (main == 15 || main == 16) {
            // Motorway exit: the main road continues straight in grey, the route peels off.
            boolean left = main == 16 || (d > 0 && d < 128);
            d = left ? 30 : 226;
            thick(cx, jy, cx, y + s * 0.04f, route * 0.9f, ARM);
        }
        thick(cx, bottom, cx, jy, route, ROUTE);
        float[] e = endpoint(cx, jy, d, len * 0.78f);
        thick(cx, jy, e[0], e[1], route, ROUTE);
        head(e[0], e[1], d, s * 0.20f);
        disc(cx, jy, route / 2f, ROUTE);
    }

    public static final int LANE_PREFERRED = 0xFFFFFFFF;
    public static final int LANE_GOOD = 0xFFC8CDD2;
    public static final int LANE_OTHER = 0xFF5A6068;

    /** A row of lane arrows in (x, y, rw, rh), with dashed separators. */
    public void lanes(int[][] angles, int[] status, int x, int y, int rw, int rh) {
        int n = angles.length;
        int cell = Math.min(54, rw / n);
        int start = x + (rw - n * cell) / 2;
        float base = y + rh - 3;
        float mid = y + rh * 0.55f;
        for (int i = 1; i < n; i++) {
            float sx = start + cell * i;
            for (float yy = y + 4; yy < y + rh - 4; yy += 10f) {
                thick(sx, yy, sx, Math.min(yy + 5f, y + rh - 4), 2f, 0x90FFFFFF);
            }
        }
        for (int i = 0; i < n; i++) {
            int st = status == null || i >= status.length ? 0 : status[i];
            int c = st >= 2 ? LANE_PREFERRED : (st == 1 ? LANE_GOOD : LANE_OTHER);
            float cx = start + cell * i + cell / 2f;
            float t = Math.max(3f, cell * 0.13f);
            int[] a = angles[i];
            if (a == null || a.length == 0) {
                a = new int[] { 0 };
            }
            thick(cx, base, cx, mid, t, c);
            for (int k = 0; k < a.length; k++) {
                int d = laneDir(a[k]);
                float[] e = endpoint(cx, mid, d, rh * 0.22f);
                thick(cx, mid, e[0], e[1], t, c);
                laneHead(e[0], e[1], d, rh * 0.26f, c);
            }
        }
    }

    /** Lane angle in degrees (positive = right) to the BAP direction (0-255, 64 left, 192 right). */
    static int laneDir(int degrees) {
        int d = (int) Math.floor(-degrees * 256.0 / 360.0 + 0.5);
        return ((d % 256) + 256) % 256;
    }

    private void laneHead(float x, float y, int dir, float size, int c) {
        double a = dir * Math.PI * 2.0 / 256.0;
        float fx = (float) -Math.sin(a);
        float fy = (float) -Math.cos(a);
        float px1 = -fy;
        float py1 = fx;
        triangle(x + fx * size * 0.8f, y + fy * size * 0.8f,
            x - fx * size * 0.1f + px1 * size * 0.6f, y - fy * size * 0.1f + py1 * size * 0.6f,
            x - fx * size * 0.1f - px1 * size * 0.6f, y - fy * size * 0.1f - py1 * size * 0.6f, c);
    }

    private static float[] endpoint(float cx, float cy, int dir, float len) {
        double a = dir * Math.PI * 2.0 / 256.0;
        return new float[] { (float) (cx - Math.sin(a) * len), (float) (cy - Math.cos(a) * len) };
    }

    /** Arrow head with its tip a little beyond (x, y), pointing along dir. */
    private void head(float x, float y, int dir, float size) {
        double a = dir * Math.PI * 2.0 / 256.0;
        float fx = (float) -Math.sin(a);
        float fy = (float) -Math.cos(a);
        float tipx = x + fx * size * 0.9f;
        float tipy = y + fy * size * 0.9f;
        float bx = x - fx * size * 0.15f;
        float by = y - fy * size * 0.15f;
        float px1 = -fy;
        float py1 = fx;
        triangle(tipx, tipy, bx + px1 * size * 0.75f, by + py1 * size * 0.75f,
            bx - px1 * size * 0.75f, by - py1 * size * 0.75f, ROUTE);
    }

    private void uturn(float cx, float bottom, float s, boolean left) {
        float r = s * 0.17f;
        float route = s * 0.11f;
        float sign = left ? -1f : 1f;
        float x1 = cx - sign * r;
        float x2 = cx + sign * r;
        float top = bottom - s * 0.62f;
        thick(x1, bottom, x1, top, route, ROUTE);
        int steps = 16;
        float lx = x1;
        float ly = top;
        for (int i = 1; i <= steps; i++) {
            double t = Math.PI * i / steps;
            float nx = (float) (cx - sign * r * Math.cos(t));
            float ny = (float) (top - r * Math.sin(t));
            thick(lx, ly, nx, ny, route, ROUTE);
            lx = nx;
            ly = ny;
        }
        float endy = top + s * 0.18f;
        thick(x2, top, x2, endy, route, ROUTE);
        head(x2, endy, 128, s * 0.20f);
    }

    private void roundabout(float cx, float cy, float s, int dir, boolean clockwise) {
        float r = s * 0.21f;
        float route = s * 0.10f;
        float bottom = y0(cy, s);
        ring(cx, cy, r, s * 0.07f, ARM);
        thick(cx, bottom, cx, cy + r, route, ROUTE);
        int d = dir & 0xff;
        // Right-hand traffic goes round anti-clockwise on screen (bottom -> right -> top);
        // the ring position at angle a matches endpoint(), so travel from pi to the exit angle.
        double a = d * Math.PI * 2.0 / 256.0;
        double start = Math.PI;
        double end;
        if (!clockwise) {
            end = a <= start + 0.01 ? a + Math.PI * 2.0 : a;
        } else {
            end = a >= start - 0.01 ? a - Math.PI * 2.0 : a;
        }
        int steps = 32;
        float lx = cx;
        float ly = cy + r;
        for (int i = 1; i <= steps; i++) {
            double t = start + (end - start) * i / steps;
            float nx = (float) (cx - Math.sin(t) * r);
            float ny = (float) (cy - Math.cos(t) * r);
            thick(lx, ly, nx, ny, route, ROUTE);
            lx = nx;
            ly = ny;
        }
        float[] e = endpoint(lx, ly, d, s * 0.12f);
        thick(lx, ly, e[0], e[1], route, ROUTE);
        head(e[0], e[1], d, s * 0.18f);
    }

    private static float y0(float cy, float s) {
        return cy + s * 0.45f;
    }

    private void flag(float cx, float cy, float s) {
        float pole = s * 0.05f;
        thick(cx - s * 0.12f, cy + s * 0.32f, cx - s * 0.12f, cy - s * 0.30f, pole, ROUTE);
        triangle(cx - s * 0.12f, cy - s * 0.30f, cx + s * 0.25f, cy - s * 0.18f, cx - s * 0.12f, cy - s * 0.04f, ROUTE);
    }

    private void ring(float cx, float cy, float r, float t, int c) {
        int x0 = (int) (cx - r - t);
        int x1 = (int) (cx + r + t) + 1;
        int y0 = (int) (cy - r - t);
        int y1 = (int) (cy + r + t) + 1;
        for (int y = Math.max(0, y0); y < Math.min(h, y1); y++) {
            for (int x = Math.max(0, x0); x < Math.min(w, x1); x++) {
                float dx = x + 0.5f - cx;
                float dy = y + 0.5f - cy;
                float d = (float) Math.abs(Math.sqrt(dx * dx + dy * dy) - r);
                blend(x, y, c, clamp(t / 2f - d + 0.5f));
            }
        }
    }

    /** Round-capped thick line. */
    public void thick(float x0, float y0, float x1, float y1, float width, int c) {
        float r = width / 2f;
        int minx = (int) Math.floor(Math.min(x0, x1) - r - 1);
        int maxx = (int) Math.ceil(Math.max(x0, x1) + r + 1);
        int miny = (int) Math.floor(Math.min(y0, y1) - r - 1);
        int maxy = (int) Math.ceil(Math.max(y0, y1) + r + 1);
        float dx = x1 - x0;
        float dy = y1 - y0;
        float l2 = dx * dx + dy * dy;
        for (int y = Math.max(0, miny); y < Math.min(h, maxy); y++) {
            for (int x = Math.max(0, minx); x < Math.min(w, maxx); x++) {
                float qx = x + 0.5f - x0;
                float qy = y + 0.5f - y0;
                float t = l2 == 0f ? 0f : (qx * dx + qy * dy) / l2;
                if (t < 0f) {
                    t = 0f;
                } else if (t > 1f) {
                    t = 1f;
                }
                float ex = qx - t * dx;
                float ey = qy - t * dy;
                float d = (float) Math.sqrt(ex * ex + ey * ey);
                blend(x, y, c, clamp(r - d + 0.5f));
            }
        }
    }

    public void disc(float cx, float cy, float r, int c) {
        thick(cx, cy, cx, cy, r * 2f, c);
    }

    public void triangle(float ax, float ay, float bx, float by, float cx, float cy, int c) {
        int minx = (int) Math.floor(Math.min(ax, Math.min(bx, cx)));
        int maxx = (int) Math.ceil(Math.max(ax, Math.max(bx, cx)));
        int miny = (int) Math.floor(Math.min(ay, Math.min(by, cy)));
        int maxy = (int) Math.ceil(Math.max(ay, Math.max(by, cy)));
        for (int y = Math.max(0, miny); y <= Math.min(h - 1, maxy); y++) {
            for (int x = Math.max(0, minx); x <= Math.min(w - 1, maxx); x++) {
                int hit = 0;
                for (int sy = 0; sy < 4; sy++) {
                    for (int sx = 0; sx < 4; sx++) {
                        float px0 = x + (sx + 0.5f) / 4f;
                        float py0 = y + (sy + 0.5f) / 4f;
                        float d1 = (px0 - bx) * (ay - by) - (ax - bx) * (py0 - by);
                        float d2 = (px0 - cx) * (by - cy) - (bx - cx) * (py0 - cy);
                        float d3 = (px0 - ax) * (cy - ay) - (cx - ax) * (py0 - ay);
                        boolean neg = d1 < 0 || d2 < 0 || d3 < 0;
                        boolean pos = d1 > 0 || d2 > 0 || d3 > 0;
                        if (!(neg && pos)) {
                            hit++;
                        }
                    }
                }
                if (hit > 0) {
                    blend(x, y, c, hit / 16f);
                }
            }
        }
    }

    public void roundRect(int x, int y, int rw, int rh, int rad, int c) {
        for (int yy = Math.max(0, y); yy < Math.min(h, y + rh); yy++) {
            for (int xx = Math.max(0, x); xx < Math.min(w, x + rw); xx++) {
                float dx = 0f;
                float dy = 0f;
                if (xx < x + rad) {
                    dx = x + rad - (xx + 0.5f);
                } else if (xx >= x + rw - rad) {
                    dx = xx + 0.5f - (x + rw - rad);
                }
                if (yy < y + rad) {
                    dy = y + rad - (yy + 0.5f);
                } else if (yy >= y + rh - rad) {
                    dy = yy + 0.5f - (y + rh - rad);
                }
                float cov = 1f;
                if (dx > 0f && dy > 0f) {
                    cov = clamp(rad - (float) Math.sqrt(dx * dx + dy * dy) + 0.5f);
                }
                blend(xx, yy, c, cov);
            }
        }
    }

    private static float clamp(float v) {
        return v < 0f ? 0f : (v > 1f ? 1f : v);
    }

    /** Source-over blend of colour c (ARGB) with extra coverage a. */
    private void blend(int x, int y, int c, float a) {
        if (a <= 0f) {
            return;
        }
        int i = y * w + x;
        float sa = ((c >>> 24) / 255f) * a;
        int d = px[i];
        float da = (d >>> 24) / 255f;
        float oa = sa + da * (1f - sa);
        if (oa <= 0f) {
            px[i] = 0;
            return;
        }
        int r = mix((c >> 16) & 0xff, (d >> 16) & 0xff, sa, da, oa);
        int g = mix((c >> 8) & 0xff, (d >> 8) & 0xff, sa, da, oa);
        int b = mix(c & 0xff, d & 0xff, sa, da, oa);
        px[i] = ((int) (oa * 255f + 0.5f) << 24) | (r << 16) | (g << 8) | b;
    }

    private static int mix(int s, int d, float sa, float da, float oa) {
        int v = (int) ((s * sa + d * da * (1f - sa)) / oa + 0.5f);
        return v < 0 ? 0 : (v > 255 ? 255 : v);
    }
}
