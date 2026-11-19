package local.tt;

/**
 * v29: geometry of the TT-style turn panel, shared by the picture (PanelArt.kdkStyled) and the
 * HMI text nodes (TtPanel), so both always agree. Plain class, Java 1.4.
 *
 *   +--+---------+-------------------------+
 *   |b | arrow   | 2.7 mi   6:09 PM  (top) |
 *   |a | square  | 0.2 mi           (num)  |
 *   |r |         | [EXIT 12A]       (badge)|
 *   |  |         | Spring Cypress  (street)|
 *   |  +---------+-------------------------+   without lanes
 *   |  | lanes across the bottom           |   with lanes (no street row)
 *   +--+-----------------------------------+
 */
final class KdkLayout {
    final int w;
    final int h;
    final boolean lanes;
    final boolean wide;
    final int square;
    final int col;
    final int cw;
    final int topY;
    final int topSize;
    final int numTop;
    final int numSize;
    final int unitSize;
    final int badgeTop;
    final int badgeH;
    final int badgeText;
    final int streetTop;
    final int streetSize;

    KdkLayout(int w, int h, boolean lanes) {
        this.w = w;
        this.h = h;
        this.lanes = lanes;
        this.wide = w > 260;
        topSize = wide ? 20 : 17;
        numSize = wide ? 42 : 34;
        unitSize = wide ? 22 : 18;
        badgeH = wide ? 26 : 22;
        badgeText = wide ? 18 : 15;
        streetSize = wide ? 18 : 15;
        if (lanes) {
            square = h - 66;
            col = 20 + square + 8;
            topY = 6;
            numTop = topY + topSize + 1;
            badgeTop = numTop + numSize + 4;
            streetTop = -1;
        } else {
            square = h - 52;
            col = 20 + square + 6;
            topY = 8;
            numTop = topY + topSize + 3;
            badgeTop = numTop + numSize + 7;
            streetTop = badgeTop + badgeH + 6;
        }
        cw = w - col - 8;
    }

    /** Width of the green exit badge for its label (estimated from the HMI font's average width). */
    int badgeW(String label) {
        int est = (int) (label.length() * badgeText * 0.62f) + 18;
        return Math.min(cw, est);
    }

    static String badgeLabel(String exit) {
        return exit == null || exit.length() == 0 ? "" : new StringBuffer("EXIT ").append(exit).toString();
    }
}
