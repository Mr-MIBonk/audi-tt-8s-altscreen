package local.tt;

/** v45: the thread that fades the turn panel in and out (a plain class: no synthetic accessors). */
final class PanelFade implements Runnable {
    public void run() {
        TtPanel.fadeLoop();
    }
}
