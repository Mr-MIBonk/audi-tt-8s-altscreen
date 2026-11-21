package local.tt;

import java.io.File;
import java.io.FileInputStream;
import java.io.FileOutputStream;

/**
 * v59: automatic route recorder. Every route gets one file with every iPhone route-guidance
 * update in full (no 700-byte cut, UTF-8 kept), every tt-rgd.log note (panel state reports,
 * context and view changes, layers, card), every tt-zoom.log line and every "sh tt.sh mark".
 *
 * The file is a playback script: "rgd" lines with "wait" gaps at the recorded timing, notes as
 * "# time text" comments. cp route-0007.txt /tmp/tt-rgi-play.txt replays the drive parked
 * (sh tt.sh play route 7).
 *
 * Starts when a route starts; a route off or a phone disconnect shorter than 2 minutes stays in
 * the same file; ends 2 minutes after the route stopped. Saved to the SD card (/fs/sda0 or
 * /fs/sdb0, folder tt-routes, last 20 routes) or, without a card, to /tmp/tt-routes (last 3,
 * lost at an MMI restart). Off: /tmp/tt-rec-off. Java 1.4 class library: StringBuffer only.
 */
final class RouteRec implements Runnable {
    private static final String[] CARDS = {"/fs/sda0", "/fs/sdb0"};
    private static final File RAM = new File("/tmp/tt-routes");
    private static final File OFF = new File("/tmp/tt-rec-off");
    private static final File MARK = new File("/tmp/tt-mark");
    private static final long END_AFTER = 120000L;
    private static final long MAX_BYTES = 20L * 1024L * 1024L;
    private static final Object LOCK = new Object();

    private static StringBuffer pending = new StringBuffer();
    private static File file;
    private static boolean recording;
    private static boolean onRam;
    private static long offSince = -1L;
    private static long lastMsgAt;
    private static long written;
    private static boolean full;
    private static boolean started;

    private RouteRec() {
    }

    static synchronized void start() {
        if (started) {
            return;
        }
        started = true;
        try {
            Thread t = new Thread(new RouteRec(), "tt-route-rec");
            t.setDaemon(true);
            t.setPriority(Thread.MIN_PRIORITY);
            t.start();
        } catch (Throwable ignored) {
        }
    }

    /** RgdBus.feed: whether the phone's route is on (not called for replays). */
    static void route(boolean on) {
        if (RgdBus.replaying) {
            return;
        }
        long now = System.currentTimeMillis();
        synchronized (LOCK) {
            if (on) {
                offSince = -1L;
                if (!recording && !OFF.exists()) {
                    begin(now);
                }
            } else if (recording && offSince < 0L) {
                offSince = now;
            }
        }
    }

    /** RgdBus reader: one changed update from the phone, in full. */
    static void message(byte[] payload) {
        if (RgdBus.replaying) {
            return;
        }
        String text;
        try {
            text = new String(payload, "UTF-8");
        } catch (Throwable t) {
            text = new String(payload);
        }
        long now = System.currentTimeMillis();
        synchronized (LOCK) {
            if (!recording) {
                return;
            }
            long gap = now - lastMsgAt;
            lastMsgAt = now;
            if (gap > 0L) {
                pending.append("wait ").append(gap).append('\n');
            }
            pending.append("rgd ").append(flat(text)).append('\n');
        }
    }

    /** tt-rgd.log and tt-zoom.log lines, as comments. */
    static void note(String line) {
        long now = System.currentTimeMillis();
        synchronized (LOCK) {
            if (!recording || line == null) {
                return;
            }
            pending.append("# ").append(now % 100000000L).append(' ').append(line.replace('\n', ' ')).append('\n');
        }
    }

    /** "key:type:value" lines to one "|"-separated line (a '|' inside a value becomes '/'). */
    private static String flat(String text) {
        StringBuffer b = new StringBuffer(text.length());
        int n = text.length();
        boolean lineStart = true;
        for (int i = 0; i < n; i++) {
            char c = text.charAt(i);
            if (c == '\n') {
                if (!lineStart) {
                    b.append('|');
                }
                lineStart = true;
            } else if (c == '\r') {
                continue;
            } else {
                b.append(c == '|' ? '/' : c);
                lineStart = false;
            }
        }
        int len = b.length();
        if (len > 0 && b.charAt(len - 1) == '|') {
            b.setLength(len - 1);
        }
        return b.toString();
    }

    /** LOCK held: open a new file and write the header and the current state as a seed. */
    private static void begin(long now) {
        File dir = null;
        for (int i = 0; i < CARDS.length && dir == null; i++) {
            File card = new File(CARDS[i]);
            if (card.isDirectory()) {
                File d = new File(card, "tt-routes");
                if (d.isDirectory() || d.mkdirs()) {
                    if (writable(d)) {
                        dir = d;
                    }
                }
            }
        }
        onRam = dir == null;
        if (onRam) {
            RAM.mkdirs();
            dir = RAM;
        }
        prune(dir, onRam ? 2 : 19);
        file = new File(dir, nextName(dir));
        recording = true;
        full = false;
        written = 0L;
        lastMsgAt = now;
        pending = new StringBuffer();
        pending.append("# TT cockpit CarPlay route recording (tt-zoom v59), file ").append(file.getPath()).append('\n')
            .append("# started ").append(now % 100000000L).append(" (head-unit clock, same as tt-rgd.log)")
            .append(onRam ? ", RAM: no SD card found" : "").append('\n')
            .append("# replay parked: cp this file /tmp/tt-rgi-play.txt   (or sh tt.sh play route N)\n")
            .append("say recording replay start\n")
            .append("rgdclear\n")
            .append("rgd ").append(RgdBus.stateDump()).append('\n');
    }

    /** LOCK held. */
    private static void end(String why) {
        pending.append("# ").append(System.currentTimeMillis() % 100000000L).append(" recording ended: ").append(why).append('\n')
            .append("say recording replay end\n");
        flushLocked();
        recording = false;
        offSince = -1L;
        file = null;
    }

    public void run() {
        while (true) {
            try {
                Thread.sleep(2000L);
                long now = System.currentTimeMillis();
                String mark = readMark();
                synchronized (LOCK) {
                    if (mark != null && recording) {
                        pending.append("# ").append(now % 100000000L).append(" ===== MARK ").append(mark).append(" =====\n");
                    }
                    if (recording && OFF.exists()) {
                        end("switched off (/tmp/tt-rec-off)");
                    } else if (recording && offSince > 0L && now - offSince > END_AFTER) {
                        end("route off for 2 minutes");
                    } else if (recording) {
                        flushLocked();
                    }
                }
            } catch (Throwable ignored) {
            }
        }
    }

    /** LOCK held: append the pending text to the file. */
    private static void flushLocked() {
        if (file == null || pending.length() == 0) {
            return;
        }
        if (full) {
            pending.setLength(0);
            return;
        }
        byte[] data;
        try {
            data = pending.toString().getBytes("UTF-8");
        } catch (Throwable t) {
            data = pending.toString().getBytes();
        }
        pending.setLength(0);
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(file.getPath(), true);
            out.write(data);
            written += data.length;
            if (written > MAX_BYTES) {
                full = true;
                out.write("# recording stopped: 20 MB reached\n".getBytes());
            }
        } catch (Throwable t) {
            // the card went away or is full: carry on in RAM
            if (!onRam) {
                onRam = true;
                RAM.mkdirs();
                prune(RAM, 2);
                file = new File(RAM, nextName(RAM));
                pending.append("# card write failed (").append(String.valueOf(t)).append("), continuing in RAM\n");
            } else {
                full = true;
            }
        } finally {
            try {
                if (out != null) {
                    out.close();
                }
            } catch (Throwable ignored) {
            }
        }
    }

    private static String readMark() {
        if (!MARK.exists()) {
            return null;
        }
        FileInputStream in = null;
        try {
            in = new FileInputStream(MARK);
            byte[] b = new byte[512];
            int n = in.read(b);
            String s = n > 0 ? new String(b, 0, n).trim().replace('\n', ' ') : "mark";
            return s;
        } catch (Throwable t) {
            return "mark";
        } finally {
            try {
                if (in != null) {
                    in.close();
                }
            } catch (Throwable ignored) {
            }
            MARK.delete();
        }
    }

    private static boolean writable(File dir) {
        File probe = new File(dir, ".tt-probe");
        FileOutputStream out = null;
        try {
            out = new FileOutputStream(probe);
            out.write(1);
            return true;
        } catch (Throwable t) {
            return false;
        } finally {
            try {
                if (out != null) {
                    out.close();
                }
            } catch (Throwable ignored) {
            }
            probe.delete();
        }
    }

    /** route-0001.txt, route-0002.txt, ... (the head unit's clock is not the real date). */
    private static String nextName(File dir) {
        int max = 0;
        String[] names = dir.list();
        for (int i = 0; names != null && i < names.length; i++) {
            int v = number(names[i]);
            if (v > max) {
                max = v;
            }
        }
        StringBuffer b = new StringBuffer(String.valueOf(max + 1));
        while (b.length() < 4) {
            b.insert(0, '0');
        }
        return b.insert(0, "route-").append(".txt").toString();
    }

    private static int number(String name) {
        if (!name.startsWith("route-") || !name.endsWith(".txt")) {
            return -1;
        }
        try {
            return Integer.parseInt(name.substring(6, name.length() - 4));
        } catch (Throwable t) {
            return -1;
        }
    }

    /** Keep the newest "keep" recordings (a new one is about to be added). */
    private static void prune(File dir, int keep) {
        String[] names = dir.list();
        if (names == null) {
            return;
        }
        int count = 0;
        for (int i = 0; i < names.length; i++) {
            if (number(names[i]) >= 0) {
                count++;
            }
        }
        while (count > keep) {
            int min = Integer.MAX_VALUE;
            String oldest = null;
            for (int i = 0; i < names.length; i++) {
                int v = number(names[i]);
                if (v >= 0 && v < min) {
                    min = v;
                    oldest = names[i];
                }
            }
            if (oldest == null) {
                return;
            }
            new File(dir, oldest).delete();
            for (int i = 0; i < names.length; i++) {
                if (oldest.equals(names[i])) {
                    names[i] = "";
                }
            }
            count--;
        }
    }
}
