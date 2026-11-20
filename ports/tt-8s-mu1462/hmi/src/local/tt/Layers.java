package local.tt;

import java.io.File;
import java.io.InputStream;

/**
 * v37: cockpit layer lists while the CarPlay map is drawn.
 *
 * The stock lists (DisplayManagerMIB2High.defineContextsForG24) are map 10 = {16 HMI, 19 stock
 * map} and map + banner 89 = {20 banner, 16, 19}. The v36b layer test (sh tt.sh layers) showed
 * that the CarPlay picture (layer 60) only shows with the banner when 60 is in the list:
 * {20 16} and {16 19 20} gave an empty map area, {20 16 60}, {16 60 20} and {20 60 16} gave the
 * CarPlay map with the banner window, in both views. After 60 had been in a list, the plain map
 * {16 19} showed the stock map again, so 10 gets 60 too.
 *
 * While the renderer's heartbeat (/tmp/mu1438-cluster-active) is fresh: 10 = {16 60},
 * 89 = {20 16 60}, and the stock banner may come up on the map (TtRgi.kdkWanted). When it has
 * been stale for 10 s (iPhone gone), the stock lists come back, so the stock map works without
 * a phone. The lists live in the display manager's memory only (dmdt dc); nothing is written to
 * flash. touch /tmp/tt-layer-off restores the stock lists and the v36 behaviour.
 *
 * Java 1.4 class library: no StringBuilder, no anonymous classes needed.
 */
public final class Layers implements Runnable {
    private static final File ACTIVE = new File("/tmp/mu1438-cluster-active");
    private static final File OFF = new File("/tmp/tt-layer-off");
    private static final File STATUS = new File("/tmp/mibr-alt111-gen2.status");
    /** v41: "1" while a map view shows (context 10/89), else "0"; supervisor v5 starts the
     *  renderer only then, so car tab <-> CarPlay tab flips never start it. */
    private static final File MAP_VIEW = new File("/tmp/tt-map-view");
    private static int mapFlag = -1;
    /** v41: the iPhone's route-guidance link went (unplugged): stock lists at once. */
    private static volatile long goneAt;
    /** v41: since when the CarPlay tab holds the CarPlay lists (at most 30 s). */
    private static long tabSince;
    private static final String DMDT = "/eso/bin/apps/dmdt";
    private static final String[] ENV = {
        "LD_LIBRARY_PATH=/eso/lib:/mnt/app/root/lib-target:/mnt/app/usr/lib:/mnt/app/armle/lib:/mnt/app/armle/lib/dll:/mnt/app/armle/usr/lib",
        "IPL_CONFIG_DIR=/etc/eso/production",
    };
    private static final Object LOCK = new Object();
    private static boolean started;
    /** CarPlay lists in place. */
    private static volatile boolean on;
    /** False until the first apply: the lists may be left over from an earlier HMI run. */
    private static boolean known;
    private static long lastFresh;
    private static long retryAt;
    private static int fails;

    private Layers() {
    }

    /** RgdBus: the iPhone's link ended. */
    static void phoneGone() {
        goneAt = System.currentTimeMillis();
    }

    /** True while the CarPlay lists are in place (banner allowed on the map). */
    public static boolean on() {
        return on;
    }

    /** ZoomGate.skin (MMI start): starts the 2 s check thread once. */
    public static void start() {
        synchronized (LOCK) {
            if (started) {
                return;
            }
            started = true;
        }
        try {
            Thread t = new Thread(new Layers(), "ttLayers");
            t.setDaemon(true);
            t.start();
        } catch (Throwable t) {
            RgdBus.note(new StringBuffer("layers: thread failed ").append(String.valueOf(t)).toString());
        }
    }

    public void run() {
        try {
            Thread.sleep(5000L);
        } catch (Throwable ignored) {
        }
        int n = 0;
        while (true) {
            try {
                mapView();
                if (n % 5 == 0) {
                    Card.tick();
                    AutoZoom.tick();
                }
                // every 2 s, or at once after the iPhone went
                if (n++ % 10 == 0 || (goneAt > 0 && on && System.currentTimeMillis() - goneAt < 1000L)) {
                    tick();
                }
            } catch (Throwable t) {
                RgdBus.note(new StringBuffer("layers: ").append(String.valueOf(t)).toString());
            }
            try {
                Thread.sleep(200L);
            } catch (Throwable ignored) {
            }
        }
    }

    private static void tick() {
        long now = System.currentTimeMillis();
        long stamp = ACTIVE.lastModified();
        boolean fresh = stamp > 0 && now >= stamp && now - stamp < 3000L;
        if (fresh) {
            lastFresh = now;
        }
        boolean want;
        boolean tab = !fresh && on && carplayTab();
        if (!tab) {
            tabSince = 0;
        } else if (tabSince == 0) {
            tabSince = now;
        }
        if (OFF.exists()) {
            want = false;
        } else if (fresh) {
            want = true;
        } else if (goneAt > 0 && now - goneAt < 15000L) {
            // v41 (car test): unplugged on the map tab, the map stayed black.
            want = false;
        } else if (tab && now - tabSince < 30000L) {
            // v40: the supervisor pauses the renderer while the CarPlay tab has the screen; keep
            // the CarPlay lists so the map is back as soon as the renderer is (v41: at most 30 s).
            want = true;
            lastFresh = now;
        } else if (stamp <= 0) {
            // v39 (car test): the renderer deletes its heartbeat when the iPhone has really gone
            // ("renderer heartbeat withdrawn"); waiting 10 s more only kept the map black.
            want = false;
        } else {
            // Short gaps (view change, renderer restart) keep the CarPlay lists.
            want = on && lastFresh > 0 && now - lastFresh < 10000L;
        }
        if (known && want == on) {
            return;
        }
        if (now < retryAt) {
            return;
        }
        boolean ok = want
            ? dc("10", "16 60") && dc("89", "20 16 60")
            : dc("10", "16 19") && dc("89", "20 16 19");
        if (!ok) {
            fails++;
            retryAt = now + (fails < 5 ? 10000L : 60000L);
            RgdBus.note(new StringBuffer("layers: dmdt failed (").append(fails).append(")").toString());
            return;
        }
        fails = 0;
        known = true;
        on = want;
        RgdBus.note(want ? "layers: carplay lists (10 = 16 60, 89 = 20 16 60)"
            : "layers: stock lists (10 = 16 19, 89 = 20 16 19)");
        // The display manager uses a new list at the next switch into that context. The banner
        // stays off the map until the lists are in place, and turning it on (re-declaring the
        // route, TtRgi.kdkWanted) is a real switch 10 -> 89, so the new list applies.
        TtPanel.layersChanged();
        try {
            de.audi.tghu.navi.app.cluster.TtRgi.viewChanged();
        } catch (Throwable ignored) {
        }
    }

    /** v41: tell supervisor v5 whether a map view shows. */
    private static void mapView() {
        int m = TtPanel.mapShowing() ? 1 : 0;
        if (m == mapFlag) {
            return;
        }
        java.io.FileOutputStream out = null;
        try {
            out = new java.io.FileOutputStream(MAP_VIEW);
            out.write(m == 1 ? "1\n".getBytes() : "0\n".getBytes());
            mapFlag = m;
        } catch (Throwable ignored) {
        } finally {
            try {
                if (out != null) {
                    out.close();
                }
            } catch (Throwable ignored) {
            }
        }
    }

    /** The hook's status file: session up and the iPhone's main screen shown (CarPlay tab). */
    private static boolean carplayTab() {
        java.io.FileInputStream in = null;
        try {
            if (!STATUS.exists()) {
                return false;
            }
            in = new java.io.FileInputStream(STATUS);
            byte[] b = new byte[2048];
            int n = in.read(b);
            String s = n > 0 ? new String(b, 0, n) : "";
            return s.indexOf("control_session=1") >= 0 && s.indexOf("mode_screen=1") >= 0;
        } catch (Throwable t) {
            return false;
        } finally {
            try {
                if (in != null) {
                    in.close();
                }
            } catch (Throwable ignored) {
            }
        }
    }

    /** dmdt dc ID LIST; true when it ran and exited 0. */
    private static boolean dc(String id, String list) {
        try {
            String[] cmd = new String[] {DMDT, "dc", id, "", "", ""};
            int n = 3;
            int i = 0;
            while (i < list.length() && n < cmd.length) {
                int j = list.indexOf(' ', i);
                if (j < 0) {
                    j = list.length();
                }
                cmd[n++] = list.substring(i, j);
                i = j + 1;
            }
            String[] args = new String[n];
            System.arraycopy(cmd, 0, args, 0, n);
            Process p = Runtime.getRuntime().exec(args, ENV);
            drain(p.getInputStream());
            drain(p.getErrorStream());
            int r = p.waitFor();
            return r == 0;
        } catch (Throwable t) {
            RgdBus.note(new StringBuffer("layers: dc ").append(id).append(' ').append(String.valueOf(t)).toString());
            return false;
        }
    }

    private static void drain(InputStream in) {
        try {
            byte[] b = new byte[256];
            while (in.read(b) > 0) {
                // discard
            }
            in.close();
        } catch (Throwable ignored) {
        }
    }
}
