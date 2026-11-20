package local.tt;

import java.io.File;
import java.io.FileInputStream;

/**
 * v54: the text of the cockpit map's bottom strip during a CarPlay route.
 *
 * The strip (NaviScreenBag6 map view, MapStatuslineLabelContainer) is a turn-point icon (choice
 * model 69) and two labels: model 62, the current street (ClusterService.updateCurrentStreet), and
 * model 71, the street after the next turn (updateTurnToStreet). ClusterService.refreshStreetMode
 * shows the icon and the turn-to street while the bargraph is on (the approach) and the current
 * street otherwise. TtRgi already feeds both from the iPhone; this only words them.
 *
 * /tmp/tt-strip:
 *   turn    (default) approach: "Left to Alpha St"; otherwise the current street
 *   always  the next turn ("Left to Alpha St") in place of the current street the whole route
 *   plain   the street names only (v53 and older)
 */
final class StripText {
    private static final File MODE = new File("/tmp/tt-strip");

    private StripText() {
    }

    /** 0 turn, 1 always, 2 plain. */
    static int mode() {
        FileInputStream in = null;
        try {
            if (!MODE.exists()) {
                return 0;
            }
            in = new FileInputStream(MODE);
            byte[] b = new byte[16];
            int n = in.read(b);
            String s = n > 0 ? new String(b, 0, n).trim() : "";
            return s.equals("always") ? 1 : (s.equals("plain") ? 2 : 0);
        } catch (Throwable t) {
            return 0;
        } finally {
            try {
                if (in != null) {
                    in.close();
                }
            } catch (Throwable ignored) {
            }
        }
    }

    /**
     * "Left to Alpha St" from the stock-style maneuver code and direction (0-255, 64 left,
     * 192 right), the street after the turn and the exit number. The street alone when the
     * maneuver is unknown; "" when there is nothing to say.
     */
    static String turn(int main, int dir, String street, String exit) {
        String s = street == null ? "" : street.trim();
        String w = word(main, dir & 0xff, exit == null ? "" : exit);
        if (w == null) {
            return s;
        }
        if (s.length() == 0) {
            return w;
        }
        StringBuffer b = new StringBuffer(w);
        b.append(main == 3 ? " " : (main == 11 ? " on " : " to ")).append(s);
        return b.toString();
    }

    private static String word(int main, int d, String exit) {
        boolean left = d > 0 && d < 128;
        boolean right = d > 128;
        switch (main) {
            case 3:
                return "Arrive at";
            case 11:
                return "Continue";
            case 13:
            case 14:
            case 41:
                if (left) {
                    return d < 48 ? "Slight left" : (d > 88 ? "Sharp left" : "Left");
                }
                if (right) {
                    return d > 208 ? "Slight right" : (d < 168 ? "Sharp right" : "Right");
                }
                return main == 41 ? "End of road" : "Straight";
            case 15:
            case 16:
            case 17:
            case 18: {
                StringBuffer b = new StringBuffer("Exit");
                if (exit.length() > 0) {
                    b.append(' ').append(exit);
                } else if (left) {
                    b.append(" left");
                } else if (right) {
                    b.append(" right");
                }
                return b.toString();
            }
            case 19:
            case 20:
                return left ? "Keep left" : (right ? "Keep right" : "Keep straight");
            case 21:
            case 22:
            case 23:
            case 24:
                return "Roundabout";
            case 25:
                return "U-turn";
            case 26:
            case 27:
                return "Leave roundabout";
            case 40:
                return "Merge";
            case 44:
                return "Ferry";
            default:
                return null;
        }
    }
}
