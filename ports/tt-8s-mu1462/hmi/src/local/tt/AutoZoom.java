package local.tt;

import java.io.File;
import java.io.FileInputStream;

/**
 * v47: zooms the cockpit CarPlay map in while approaching a turn and back out after it, through
 * the same path as the steering-wheel zoom (ZoomGate.send: "MZ01" to the hook, which asks the
 * iPhone for changeMapZoomLevel). The phone apps have no auto-zoom switch for the cluster map.
 *
 * In: a turn-like maneuver within 330 m (the iPhone's "0.2 mi" step), motorway exits and forks
 * 800 m, once per maneuver. Out: 3 s after that maneuver is passed, the route ends, or the
 * distance jumps back up (reroute). (v55 tied the iPhone's card to this stretch; v56 undid that.) Steps: /tmp/tt-autozoom-steps (1-6,
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
    /** v53: the current maneuver id and since when (its distance is stale for a moment). */
    private static String curMan = "";
    private static long curSince;

    /** v55: zoom (and card) distances, city and motorway. */
    private static final int IN_CITY = 330;
    private static final int IN_MOTORWAY = 800;

    private AutoZoom() {
    }


    /** RgdBus, every iPhone update. man = current maneuver id ("" when none). */
    static void route(boolean on, int main, int turn, String man) {
        long now = System.currentTimeMillis();
        synchronized (LOCK) {
            String m = man == null ? "" : man;
            if (!m.equals(curMan)) {
                curMan = m;
                curSince = now;
            }
            if (zoomed > 0) {
                boolean passed = man == null || !man.equals(zoomedFor);
                if (!on) {
                    zoomOut("route ended");
                } else if (passed) {
                    // v55 (run47: the Barker Cypress turn never zoomed): right after a turn the
                    // phone sends the old "15 m" with the next maneuver for a moment. Only a
                    // distance 3 s after the change counts as "the next turn is close too".
                    if (turnLike(main) && now - curSince >= 3000L && turn >= 40
                        && turn <= (motorway(main) ? IN_MOTORWAY : IN_CITY)) {
                        zoomedFor = man;
                        outAt = 0L;
                    } else if (outAt == 0L) {
                        outAt = now + 3000L;
                    }
                } else if (turn > (motorway(main) ? IN_MOTORWAY + 500 : IN_CITY + 250)) {
                    zoomOut("turn far again");
                    // may zoom in again for the same maneuver when it gets close
                    zoomedFor = null;
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
            // v53 (run46 zoomed in at "15 m" and out again at once): right after the maneuver
            // changes the phone still sends the old distance. Wait 3 s, and never under 40 m.
            if (now - curSince < 3000L || turn < 40) {
                return;
            }
            if (turn <= (motorway(main) ? IN_MOTORWAY : IN_CITY)) {
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
