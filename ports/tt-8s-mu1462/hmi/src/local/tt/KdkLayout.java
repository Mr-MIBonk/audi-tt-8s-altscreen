package local.tt;

/**
 * v29: geometry of the TT-style turn panel, shared by the picture (PanelArt.kdkStyled) and the
 * HMI text nodes (TtPanel), so both always agree. Plain class, Java 1.4.
 *
 *   +--+---------+-------------------------+
 *   |b |         |    2.7 mi   6:09 PM     |   rows spread evenly over the height,
 *   |a |  arrow  |        0.2 mi           |   every row centred in the text column,
 *   |r | (centred|      [EXIT 12A]         |   arrow centred in its area
 *   |  |   area) |    Spring Cypress Rd    |
 *   |  +---------+-------------------------+
 *   |  |   lanes across the bottom (if any)|   with lanes: rows spread above the lanes
 *   +--+-----------------------------------+
 */
final class KdkLayout {
    final int w;
    final int h;
    final boolean lanes;
    final boolean wide;
    final int square;
    final int squareX;
    final int squareY;
    /** Lane row (only with lanes): top and height; kept clear of the bottom edge. */
    final int lanesY;
    final int lanesH;
    final int col;
    final int cw;
    final int topY;
    final int topSize;
    final int numTop;
    final int numSize;
    final int unitSize;
    /** -1 when there is no exit number. */
    final int badgeTop;
    final int badgeH;
    final int badgeText;
    /** -1 when the street is not shown (lanes, or no street). */
    final int streetTop;
    final int streetSize;

    KdkLayout(int w, int h, boolean lanes, boolean hasExit, boolean hasStreet) {
        this.w = w;
        this.h = h;
        this.lanes = lanes;
        this.wide = w > 260;
        topSize = wide ? 20 : 17;
        numSize = wide ? 42 : 34;
        unitSize = wide ? 22 : 18;
        badgeH = wide ? 26 : 22;
        badgeText = wide ? 18 : 15;
        // Without an exit badge the street is the main line under the distance: a bit larger.
        streetSize = (wide ? 18 : 15) + (hasExit ? 0 : 2);
        lanesH = wide ? 50 : 48;
        lanesY = h - lanesH - (wide ? 12 : 8);
        square = lanes ? lanesY - 8 : (wide ? h - 44 : h - 52);
        col = 20 + square + 8;
        cw = w - col - 8;
        // Area above the lanes (or the whole height), with the arrow centred in it.
        int areaTop = lanes ? 4 : 6;
        int areaBottom = lanes ? lanesY - 2 : h - 6;
        squareX = 20;
        squareY = areaTop + (areaBottom - areaTop - square) / 2;
        // Text rows spread evenly: equal gaps above, between and below.
        boolean street = hasStreet && (!lanes || !hasExit);
        int n = 2 + (hasExit ? 1 : 0) + (street ? 1 : 0);
        int sum = topSize + numSize + (hasExit ? badgeH : 0) + (street ? streetSize : 0);
        int gap = Math.max(2, (areaBottom - areaTop - sum) / (n + 1));
        int y = areaTop + gap;
        topY = y;
        y += topSize + gap;
        numTop = y;
        y += numSize + gap;
        if (hasExit) {
            badgeTop = y;
            y += badgeH + gap;
        } else {
            badgeTop = -1;
        }
        streetTop = street ? y : -1;
    }

    /** Width of the green exit badge for its label (estimated from the HMI font's average width). */
    int badgeW(String label) {
        int est = (int) (label.length() * badgeText * 0.62f) + 18;
        return Math.min(cw, est);
    }

    /** Badge left edge, centred in the text column. */
    int badgeX(String label) {
        return col + (cw - badgeW(label)) / 2;
    }

    /** Left edge for a text of width tw, centred in the text column. */
    int centre(int tw) {
        return col + Math.max(0, (cw - tw) / 2);
    }

    static String badgeLabel(String exit) {
        return exit == null || exit.length() == 0 ? "" : new StringBuffer("EXIT ").append(exit).toString();
    }
}
