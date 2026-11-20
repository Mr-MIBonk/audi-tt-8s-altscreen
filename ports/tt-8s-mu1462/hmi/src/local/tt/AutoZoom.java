package local.tt;

import java.io.File;
import java.io.FileInputStream;

/**
 * v47: zooms the cockpit CarPlay map in while approaching a turn and back out after it, through
 * the same path as the steering-wheel zoom (ZoomGate.send: "MZ01" to the hook, which asks the
 * iPhone for changeMapZoomLevel). The phone apps have no auto-zoom switch for the cluster map.
 *
 * In: a turn-like maneuver (RgdBus.nearTurn codes) within 250 m, motorway exits and forks 600 m,
 * once per maneuver. Out: 3 s after that maneuver is passed (the iPhone moves on to the next one),
 * the route ends, or the distance jumps back up (reroute). Steps: /tmp/tt-autozoom-steps (1-6,
 * default 2); /tmp/tt-autozoom-off turns it off. Every action is logged to /tmp/tt-zoom.log.
 */
public final class AutoZoom {
    private static final File OFF = new File("/tmp/tt-autozoom-off");
    private static final File STEPS = new File("/tmp/tt-autozoom-steps");
    private static final Object LOCK = new Object();
    /** Steps currently zoomed in (0 = normal). */
    private static int zoomed;
    /** The maneuver id we zoomed in for. */
    private static String zoomedFor;
    /** When to zoom back out (0 = not scheduled). */
    private static long outAt;

    private AutoZoom() {
    }

    /** RgdBus, every iPhone update. man = current maneuver id ("" when none). */
    static void route(boolean on, int main, int turn, String man) {
        long now = System.currentTimeMillis();
        synchronized (LOCK) {
            if (zoomed > 0) {
                boolean passed = man == null || !man.equals(zoomedFor);
                if (!on) {
                    zoomOut("route ended");
                } else if (passed) {
                    if (turnLike(main) && turn > 0 && turn <= (motorway(main) ? 600 : 250)) {
                        // the next turn is close too: stay zoomed in for it
                        zoomedFor = man;
                        outAt = 0L;
                    } else if (outAt == 0L) {
                        outAt = now + 3000L;
                    }
                } else if (turn > (motorway(main) ? 900 : 450)) {
                    zoomOut("turn far again");
                }
                return;
            }
            if (!on) {
                zoomedFor = null;
            }
            // v52 (run45): never at 0 m - route start (42) and maneuver changes report 0 for a moment.
            if (!on || OFF.exists() || man == null || man.length() == 0 || turn <= 0 || !turnLike(main)) {
                return;
            }
            if (man.equals(zoomedFor)) {
                return;
            }
            if (turn <= (motorway(main) ? 600 : 250)) {
                int n = steps();
                String why = new StringBuffer("auto zoom in (turn ").append(turn).append(" m)").toString();
                if (ZoomGate.autoZoom(why, -n)) {
                    zoomed = n;
                }
                zoomedFor = man;
                outAt = 0L;
            }
        }
    }

    /** Layers loop, every second: runs the scheduled zoom-out. */
    static void tick() {
        synchronized (LOCK) {
            if (zoomed > 0 && outAt > 0L && System.currentTimeMillis() >= outAt) {
                zoomOut("turn passed");
            }
        }
    }

    private static void zoomOut(String why) {
        ZoomGate.autoZoom(new StringBuffer("auto zoom out (").append(why).append(')').toString(), zoomed);
        zoomed = 0;
        outAt = 0L;
    }

    /**
     * v52 (run45 zoomed in on "start of route", code 42, at 0 m): only real turns - turns, exits,
     * forks and roundabouts (13-27) and end of road (41). Not follow road, arrival, merge, start,
     * lane change or ferry.
     */
    private static boolean turnLike(int main) {
        return main >= 13 && main <= 27 || main == 41;
    }

    private static boolean motorway(int main) {
        return main >= 14 && main <= 20 || main == 40 || main == 43;
    }

    private static int steps() {
        FileInputStream in = null;
        try {
            if (!STEPS.exists()) {
                return 2;
            }
            in = new FileInputStream(STEPS);
            byte[] b = new byte[8];
            int n = in.read(b);
            int v = Integer.parseInt(new String(b, 0, Math.max(0, n)).trim());
            return v < 1 ? 1 : (v > 6 ? 6 : v);
        } catch (Throwable t) {
            return 2;
        } finally {
            try {
                if (in != null) {
                    in.close();
                }
            } catch (Throwable ignored) {
            }
        }
    }
}
