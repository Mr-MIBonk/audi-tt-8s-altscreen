#!/bin/sh
# TT CarPlay toolkit (Audi TT MU1462). One command for everything.
# After setup, from the SSH login folder:   sh tt.sh help
PATH=/proc/boot:/bin:/usr/bin:/sbin:/usr/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin
export PATH
K=/mnt/app/root/tt
JARS=/mnt/app/eso/hmi/lsd/jars
JAR=$JARS/tt-zoom.jar
V12=5026c7c44e180352c78e1f21627331735ea108a7c5445ed0eb367a78e6a45a21
V14=ae246f4c4b9e4bc0e1235a74a119be4481ef3534f9c371833092fafa9e5df5e1
V15=f13fdd3ab74f3f85fe70900b51da0186eab0b0ef837314f7e7d4be9e0f202d08
V16=cc4110d51cf639a6502f6dfb5bcaa676bb101a553c365b123b4bd51ad78242b4
V17=651454c8695f514b0627c7f0818422820ff44245fd3dd4c1483487fa58fd1ec9
V18=a403e83dc210a4ae580c547bf63c0bf235934483b1e4096efdd5ade427e3003f
V19=a549814352b72762f1639c0343eeab829f954aa2ff92e078d6fea40fd30fb4e1
V20=146a39998585e62b59eff8e714c3e3e92271a15fb72530cd3aafddeb9000c44b
V21=43a59e05a7b5f8821428d2410a1e96ee142bddfa063fcc02af981d827da47e09
V22=1619db75cd413a614d28d17a646524cf3e51ea1492f971a29eb71452e739f763
V23=74b71d9013d088ca8a38f6b035a75da15a1c00b519a53713299aee967b7056e7
V24=a0f1c832d7ddb6e776a3d6985cc857ee5093878235cae778da675deb6c757917
V25=5ea2b40ec7f48cb62c0f0ce3f0b2dbb28ed74adec2264dddc5ae8afe3b981573
V26=42bb2f9cc16ef62c904fb9542ec0dedb86361062ea7388bcda0d16689bdc2f38
V27=f980ba096d9805ebd9d8245974a99525e0d1f48cd3f68534c892bff3cf356adf
V28=76c5cfb667ce9160724ef8cfa0732630ee6f00acdfe35069c07337ef7282d8ad
V29=f2a3405ec73b3e2325bbfb950c2bf7321ac72f0668a288cf02c3db8eb8dbbf5a
V30=8d495fb124f657554084a05ba779be75a2abef5057d50638e6e4869a33f3a323
V31=a837524259224b5a62c41f2d23ccb9173ca6871e27d173b70d2397aa0bea2b88
V32=0128845e24b72cf59eb8f9ff5225422b42591926cfd44b9407620d5bfbc1a830
V33=d60fdb3d06402a71df22974c56e758becac30d24c65ad0ef08cfa0e2c279bcc1
V34=5b0e22986b3a4aa923784b49e27eb35a0b471e33e4a7f619941a848e82bd498f
V35=3d07121dae29006e3825c3b61520a5310212bc02dfab5245b6d0a00e614f9fe2
T=$K/altscreen-sha256

say(){ echo "$*"; }
rw(){ mount -uw /mnt/app || { say 'Cannot make /mnt/app writable.'; exit 1; }; }
ro(){ sync; mount -ur /mnt/app 2>/dev/null; }
which_jar(){
    h=$("$T" "$JAR" 2>/dev/null)
    case "$h" in
        $V12) echo v12;; $V14) echo v14;; $V15) echo v15;; $V16) echo v16;; $V17) echo v17;; $V18) echo v18;; $V19) echo v19;; $V20) echo v20;; $V21) echo v21;; $V22) echo v22;; $V23) echo v23;; $V24) echo v24;; $V25) echo v25;; $V26) echo v26;; $V27) echo v27;; $V28) echo v28;; $V29) echo v29;; $V30) echo v30;; $V31) echo v31;; $V32) echo v32;; $V33) echo v33;; $V34) echo v34;; $V35) echo v35;; "") echo none;; *) echo "unknown ($h)";;
    esac
}

case "${1:-help}" in
setup)
    # Run from /tmp after copying the kit there. Safe to run again for a kit update.
    test -f /tmp/tt-zoom-v35.jar || { say 'Copy the kit files to /tmp first.'; exit 1; }
    rw
    mkdir -p "$K/logs"
    for f in altscreen-sha256 tt-zoom-v35.jar stock-replay.txt catalogue.txt komo-test.txt panel-test.txt kdk-test.txt fit-test.txt win-test.txt new-test.txt map-test.txt place-test.txt; do
        cp "/tmp/$f" "$K/$f" || { say "missing /tmp/$f"; ro; exit 1; }
    done
    for f in tt-zoom-v12.jar tt-zoom-v14.jar tt-zoom-v15.jar tt-zoom-v16.jar tt-zoom-v17.jar tt-zoom-v18.jar tt-zoom-v19.jar tt-zoom-v20.jar tt-zoom-v21.jar tt-zoom-v22.jar tt-zoom-v23.jar tt-zoom-v24.jar tt-zoom-v25.jar tt-zoom-v26.jar tt-zoom-v27.jar tt-zoom-v28.jar tt-zoom-v29.jar tt-zoom-v30.jar tt-zoom-v31.jar tt-zoom-v32.jar tt-zoom-v33.jar tt-zoom-v34.jar; do
        test -f "/tmp/$f" && cp "/tmp/$f" "$K/$f"
    done
    # Optional panel background picture (made with scripts/mkbg.py; kept on the car, not in git).
    test -f /tmp/panel-bg.a8 && cp /tmp/panel-bg.a8 "$K/panel-bg.a8" && say 'Panel background installed.'
    cp /tmp/tt.sh /mnt/app/root/tt.sh
    chmod 755 "$T" /mnt/app/root/tt.sh
    ok=1
    "$T" $V35 "$K/tt-zoom-v35.jar" || ok=0
    ro
    if test $ok = 1; then say 'Kit installed. From now on just type:  sh tt.sh help'
    else say 'A kit file is damaged - copy the kit again and rerun setup.'; exit 1; fi
    ;;
use)
    v=${2:-}
    case "$v" in v12) h=$V12;; v14) h=$V14;; v15) h=$V15;; v16) h=$V16;; v17) h=$V17;; v18) h=$V18;; v19) h=$V19;; v20) h=$V20;; v21) h=$V21;; v22) h=$V22;; v23) h=$V23;; v24) h=$V24;; v25) h=$V25;; v26) h=$V26;; v27) h=$V27;; v28) h=$V28;; v29) h=$V29;; v30) h=$V30;; v31) h=$V31;; v32) h=$V32;; v33) h=$V33;; v34) h=$V34;; v35) h=$V35;; *) say 'Usage: sh tt.sh use v35   (or v34 ... v12)'; exit 2;; esac
    test -f "$K/tt-zoom-$v.jar" || { say "$v is not in the kit on the car."; exit 1; }
    "$T" $h "$K/tt-zoom-$v.jar" || { say "Stored $v jar is damaged."; exit 1; }
    rw
    cp "$K/tt-zoom-$v.jar" "$JAR.new" && chmod 755 "$JAR.new" && mv "$JAR.new" "$JAR"
    "$T" $h "$JAR" && r=0 || r=1
    ro
    test $r = 0 && say "Installed $v. Now restart the MMI." || say 'Copy failed - nothing changed.'
    ;;
remove)
    rw; rm -f "$JAR"; ro; say 'tt-zoom.jar removed. Restart the MMI for stock behaviour.'
    ;;
play)
    case "${2:-stock}" in
        stock) cp "$K/stock-replay.txt" /tmp/tt-rgi-play.txt && say 'Stock-nav replay playing (about 2 min, repeats). Stop: sh tt.sh stop';;
        win) cp "$K/win-test.txt" /tmp/tt-rgi-play.txt && say 'Window test playing (about 65 s, repeats): stay in the TACH-CENTRED view, one photo per step (W1, W2, W3). Stop: sh tt.sh stop';;
        map) cp "$K/map-test.txt" /tmp/tt-rgi-play.txt && say 'Map test playing (about 80 s, repeats): CarPlay connected, follow the steps M1..M4, one photo each. Stop: sh tt.sh stop';;
        new) cp "$K/new-test.txt" /tmp/tt-rgi-play.txt && say 'New pictures playing (about 75 s, repeats): one photo per step N1..N11, any view. Stop: sh tt.sh stop';;
        fit) cp "$K/fit-test.txt" /tmp/tt-rgi-play.txt && say 'Panel test playing (about 65 s, repeats): switch views and tabs while it runs. Stop: sh tt.sh stop';;
        kdk) cp "$K/kdk-test.txt" /tmp/tt-rgi-play.txt && say 'Banner-spot test 2 playing (about 110 s, repeats). Stop: sh tt.sh stop';;
        panel) cp "$K/panel-test.txt" /tmp/tt-rgi-play.txt && say 'Turn panel demo playing (about 2 min, repeats). Stop: sh tt.sh stop';;
        komo) cp "$K/komo-test.txt" /tmp/tt-rgi-play.txt && say 'KOMO test playing (about 100 s, repeats). Stop: sh tt.sh stop';;
        arrows) cp "$K/catalogue.txt" /tmp/tt-rgi-play.txt && say 'Arrow catalogue playing (about 3 min). Stop: sh tt.sh stop';;
        *) say 'Usage: sh tt.sh play map | new | fit | win | kdk | panel | komo | stock | arrows'; exit 2;;
    esac
    ;;
stop)
    rm -f /tmp/tt-rgi-play.txt; say 'Playback stopped; iPhone feed resumes in a few seconds.'
    ;;
test)
    # One session, one SSH connection (v35): parked demo, the new pictures, live Google and
    # Apple Maps routes, then the iPhone's own maneuver card switched off. Saves at the end.
    # Keep this SSH window open; if it drops, run it again (it starts over).
    PL=/tmp/tt-rgi-play.txt
    UM=/tmp/mibr-alt111-url-mode
    wait_s(){ n=$1; while test "$n" -gt 0; do sleep 5; n=$((n-5)); say "      ... $n s"; done; }
    step(){ say ''; say "== $1"; }
    rm -f /tmp/tt-panel-pos
    say 'Full test, about 9 minutes. iPhone plugged in, CarPlay running, parked. Photos where it says PHOTO.'
    step 'PART 1: parked demo (no route needed). Starting in 10 s.'
    sleep 10
    cp "$K/map-test.txt" "$PL" || exit 1
    step 'M1 (20 s) LARGE view, MAP tab: CarPlay map + our framed panel. PHOTO'
    wait_s 20
    step 'M2 (20 s) LARGE view, CAR tab: panel inside the stock frame. PHOTO'
    wait_s 20
    step 'M3 (20 s) SMALL view with the MAP: panel over the map, left of the tach. PHOTO'
    wait_s 20
    step 'M4 (20 s) SMALL view, trip computer page: panel at its usual spot. PHOTO'
    wait_s 20
    cp "$K/new-test.txt" "$PL"
    step 'N (75 s) LARGE view, MAP tab: all new pictures with our own frame. PHOTO only if one looks wrong.'
    wait_s 75
    rm -f "$PL"
    step 'PART 2: live routes.'
    step 'G0 (30 s) Start a GOOGLE MAPS route now, somewhere a few miles away.'
    wait_s 30
    step 'G1 (15 s) LARGE view, MAP tab. PHOTO'
    wait_s 15
    step 'G2 (15 s) LARGE view, CAR tab. PHOTO'
    wait_s 15
    step 'G3 (15 s) SMALL view with the MAP. PHOTO'
    wait_s 15
    step 'G4 (15 s) SMALL view, trip computer. PHOTO'
    wait_s 15
    step 'A0 (30 s) End the Google route. Start an APPLE MAPS route now.'
    wait_s 30
    step 'A1 (15 s) LARGE view, MAP tab. PHOTO'
    wait_s 15
    step 'A2 (15 s) SMALL view with the MAP. PHOTO'
    wait_s 15
    step 'PART 3: the iPhone draws its own maneuver card on the map. Try switching it off.'
    echo map > "$UM"
    step 'C0 (60 s) UNPLUG the iPhone, wait 5 s, PLUG it back in, wait for CarPlay, start any route.'
    wait_s 60
    step 'C1 (20 s) LARGE view, MAP tab: is the iPhone card (top left of the map) gone? Map still there? PHOTO'
    wait_s 20
    step 'C2 (15 s) SMALL view with the MAP. PHOTO'
    wait_s 15
    rm -f "$UM"
    step 'END (10 s) End the route. Saving the logs. (Unplug and replug once more to get the card back.)'
    wait_s 10
    sh "$0" save
    say 'Done. Send the photos (named by step) and the newest logs folder.'
    ;;
mode)
    case "${2:-}" in
        default) rm -f /tmp/tt-rgi-kdk-map /tmp/tt-rgi-noactive /tmp/tt-rgi-kdk /tmp/tt-rgi-nokdk /tmp/tt-rgi-nokdk-small /tmp/tt-rgi-nopad /tmp/tt-rgi-off /tmp/tt-panel-off; say 'Mode: default (our panel inside the stock banner, every view).';;
        kdkmap) touch /tmp/tt-rgi-kdk-map; say 'Mode: stock banner on the map too (v32 behaviour, hides the CarPlay map).';;
        nokdk) touch /tmp/tt-rgi-nokdk; say 'Mode: no stock banner (v26 behaviour: small view only).';;
        kdk) rm -f /tmp/tt-rgi-nokdk; touch /tmp/tt-rgi-kdk; say 'Mode: stock banner in every view.';;
        nokdksmall) touch /tmp/tt-rgi-nokdk-small; say 'Mode: no stock banner in the small view either.';;
        nopanel) touch /tmp/tt-panel-off; say 'Mode: nopanel (our turn panel off).';;
        noactive) touch /tmp/tt-rgi-noactive; say 'Mode: never report route active.';;
        nopad) touch /tmp/tt-rgi-nopad; say 'Arrows: bare 2-number shape.';;
        off) touch /tmp/tt-rgi-off; say 'Cockpit feed off.';;
        on) rm -f /tmp/tt-rgi-off; say 'Cockpit feed on.';;
        *) say 'Usage: sh tt.sh mode default|kdkmap|nokdk|kdk|nopanel|noactive|nopad|off|on'; exit 2;;
    esac
    ;;
panel)
    # Live position/size of our turn panel per view; read on every redraw (no restart).
    P=/tmp/tt-panel-pos
    case "${2:-}" in
        kdk-small|kdk-smallmap|kdk-large|left|right|small|flap)
            test -n "${4:-}" || { say 'Usage: sh tt.sh panel kdk-small|kdk-large X Y [SCALE]'; exit 2; }
            touch $P; grep -v "^$2 " $P > $P.new 2>/dev/null; echo "$2 $3 $4 ${5:-1}" >> $P.new; mv $P.new $P
            say "Panel $2 view: x=$3 y=$4 scale=${5:-1} (applies at the next update)";;
        reset) rm -f $P; say 'Panel position back to defaults.';;
        show) cat $P 2>/dev/null || say '(defaults: kdk-small 991 160 1, kdk-large 1105 110 1)';;
        *) say 'Usage: sh tt.sh panel kdk-small|kdk-large X Y [SCALE] | reset | show'; exit 2;;
    esac
    ;;
report)
    say "== jar: $(which_jar)    (v35 is the current one)"
    test -f "$K/panel-bg.a8" && say '== panel background: installed' || say '== panel background: none'
    say '== switches:'
    ls /tmp/tt-rgi-* 2>/dev/null || say '(none)'
    say '== iPhone and cockpit (last 8):'
    grep -E 'rgi on=|hmi|combi|listening|hook (dis)?connected' /tmp/tt-rgd.log 2>/dev/null | tail -8
    say '== playback (last 3):'
    grep -E 'play|panel' /tmp/tt-rgd.log 2>/dev/null | tail -6
    say '== nav log:'
    if test -f /tmp/tt-nav.log; then
        say "$(wc -l < /tmp/tt-nav.log) lines; last 5 non-street:"
        grep -v -E ' street | dtm | nextDest | direction ' /tmp/tt-nav.log | tail -8
        say '== guidance view answers:'
        grep -E 'komo(Result|RgSelResult|Type|Enabled|Visible|Gfx)' /tmp/tt-nav.log | tail -8
    else say 'none'; fi
    ;;
seen)
    # v32 research log: what the iPhone has sent so far (lost at power-off, so run save).
    if test -s /tmp/tt-rgd-cat.txt; then
        say "$(grep -c ' type=' /tmp/tt-rgd-cat.txt) distinct maneuvers, $(grep -c '^[0-9]* lg' /tmp/tt-rgd-cat.txt) lane sets. Maneuver types (count type):"
        sed -n 's/.* type=\([0-9]*\).*/\1/p' /tmp/tt-rgd-cat.txt | sort -n | uniq -c
    else say 'Nothing captured yet: start a route on the iPhone (parked is fine).'; fi
    ;;
save)
    n=1; while test -e "$K/logs/run$n"; do n=$((n+1)); done
    rw; mkdir -p "$K/logs/run$n"
    for f in /tmp/tt-rgd.log /tmp/tt-rgd.log.1 /tmp/tt-nav.log /tmp/tt-zoom.log /tmp/tt-rgd.txt /tmp/tt-rgd-cat.txt /tmp/tt-route.txt; do test -f "$f" && cp "$f" "$K/logs/run$n/"; done
    ro
    say "Saved to $K/logs/run$n (kept across MMI restarts). On the Mac:"
    say "scp -O -r -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa root@10.173.189.1:$K/logs ~/Downloads/tt-logs"
    ;;
*)
    say 'sh tt.sh report              what is installed and what it is doing (paste this)'
    say 'sh tt.sh use v35             switch version (v35 ... v12), then restart the MMI'
    say 'sh tt.sh play map|new|fit|win|kdk|panel|komo|stock  parked tests'
    say 'sh tt.sh play arrows | stop  arrow catalogue / stop playback'
    say 'sh tt.sh test                the full guided test (about 9 min), then saves the logs'
    say 'sh tt.sh seen                what the iPhone sent so far (maneuver types, lanes)'
    say 'sh tt.sh mode default|nokdk|kdk|nopanel|noactive|nopad|off|on'
    say 'sh tt.sh panel kdk-small|kdk-large X Y [S]  move/resize the panel live (reset | show)'
    say 'sh tt.sh save                keep the logs across MMI restarts'
    say 'sh tt.sh remove              take tt-zoom.jar out (restart the MMI)'
    ;;
esac
