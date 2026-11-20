package local.tt;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

/**
 * v44: the iPhone's own maneuver card on the cockpit CarPlay map, per view.
 *
 * Classic (large view): map with the card ("base" surface; its position comes from the hook's
 * maneuverLayout setting, e.g. sh tt.sh card left). Sport (small view): map only ("map"
 * surface), the card would cover the small map window.
 *
 * The hook reads /tmp/mibr-alt111-url-mode when CarPlay connects and on every showUI it sends;
 * touching /tmp/mibr-alt111-show-only makes it send showUI again with the current address, so the
 * iPhone switches while connected. Only done when the view really changes and a CarPlay session
 * is up. /tmp/tt-card-fixed (set by the kit's manual card commands) turns this off.
 */
public final class Card {
    private static final File MODE = new File("/tmp/mibr-alt111-url-mode");
    private static final File SHOW = new File("/tmp/mibr-alt111-show-only");
    private static final File FIXED = new File("/tmp/tt-card-fixed");
    private static final File STATUS = new File("/tmp/mibr-alt111-gen2.status");
    private static int last = -1;

    private Card() {
    }

    /** ZoomGate.stage: the cockpit view size changed (also once at MMI start). */
    static void view(boolean small) {
        try {
            if (FIXED.exists()) {
                return;
            }
            int want = small ? 1 : 0;
            if (want == last) {
                return;
            }
            last = want;
            write(MODE, small ? "map\n" : "base\n");
            boolean live = sessionReady();
            if (live) {
                write(SHOW, "1\n");
            }
            RgdBus.note(new StringBuffer("card: ").append(small ? "Sport, map only" : "Classic, with card")
                .append(live ? " (sent to the iPhone)" : " (from the next connect)").toString());
        } catch (Throwable t) {
            RgdBus.note(new StringBuffer("card: ").append(String.valueOf(t)).toString());
        }
    }

    private static boolean sessionReady() {
        FileInputStream in = null;
        try {
            if (!STATUS.exists()) {
                return false;
            }
            in = new FileInputStream(STATUS);
            byte[] b = new byte[2048];
            int n = in.read(b);
            String s = n > 0 ? new String(b, 0, n) : "";
            return s.indexOf("control_session=1") >= 0 && s.indexOf("command_ready=1") >= 0;
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

    private static void write(File f, String s) throws java.io.IOException {
        FileOutputStream out = new FileOutputStream(f);
        try {
            out.write(s.getBytes());
        } finally {
            out.close();
        }
    }
}
