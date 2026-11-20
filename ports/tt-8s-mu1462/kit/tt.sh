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
V36=03994ca30aeb49c99c10297ae991ce905477db76fc50007c7f300d8cbb2caab4
V37=9b20688cbc8d74991c7075746de6c30fe8686e0247bba62387aa7e1d9b5c66c4
V38=c3ad31212c5c364030be092dff941e7ffd39f02003cd7857d858f9684683822c
V39=0a7636fc436d53426f2684d08116172c0410651b9416914f69009ef611ef7d9f
V40=799e2cf291bfb05a728875c6c227dc5b9e93fd317796bcc1d20527dce7ac8c14
V41=0fdfdb631f0ad028af51d5e7bf78bab03d908877d344e0de03ba41c8a23864b4
V42=679ccf4a1c1951e909d1b7f7897f5b257dc89bd91b58ba8339075ebfdd7daa64
V43=b9f3e25770a2459eb6e2856d985fa9ddc763d3130345196d76d5e5382a1b5a38
V44=0bb8db47205430a9054ec4c9418dc71ce102dde92bc5c656013b30d9c0b7cdd8
V45=95ea381137bcfe69f2264499827a808ce7dc2dcc08b4e4dacf75acb5a5f4d8cb
V46=482620c0a5275b5d0614a73a59779c621151e67449efa4c77955cb0a28ba779e
V47=730bcef272b1eddd93bcaa530581135c4c6032cac9ea749364be854af1120d7c
V48=8b82caad8bedd32b6d55759404e5dc06abb04063ff4fbb6024047dca835ee063
V49=1731457db870d747bef9b7eab0ba10dc06f488412f8440e0b0b49742e4dbac3f
V50=ac5f1958763d70f4890f83ad0659807f6b18b7a67992acacaa36d4b6738b141e
V51=b01d20ed4f607aa19e8a12f5de58d670c28a7eb2320e05423cecf6c16653f2b4
SUP=/mnt/app/root/mu1438-cluster/cluster_supervisor.sh
SUP_V2=9175a6deaff6acf2c4f35b61b245476ba8827e7f4b74977b48cdafc2c7c6f57c
SUP_V3=4c37a375954a387e4938fbabcad868bb2fcc4207a97bcbe599421974e75f06bd
SUP_V4=d520d1971e843bdbdc2898a7e64b09b2fbb3d6b7495a6374a420769446bbb8ed
SUP_V5=5a746386705da855b4d88c33042122d54e44ebbd8516165325bf3839e0627282
SUP_V6=de728b175607fe702393297b7e6a73be5efea32ea29d86b23398f6f1938557d4
SUP_V7=e8dbabcaf69b08fb2532825ee5506c03e6603398f1a5293baea621136035ae26
HOOK=/mnt/app/root/lib-target/libaltscreen111.so
# CarPlay hook builds: shipped, h320 safe-area preset (what the TT runs), and their fix1 versions
HOOK_STOCK=9a8c01ec8323d5de7695e212ff6168b0bb7df99d8554c9971f5449c5a21d6256
HOOK_H320=36aedadb8e0680ad03a9a511f3844e629ca3b2ffaaf40c9745298f730fc0b3f8
FIX_STOCK=9e4b13c12895c8bddc36586661ecd82bde71666e15a847b617993d7fcb8f0dee
FIX_H320=64f700f5fffb8f91a0e5ee0fedfa9e132eb2c6fb65da3c16a063e832421792e8
# built from source (scripts/wsl-native-build.sh tt): h320 + close-on-exec + stock delegates
HOOK_TT1=028b4a73a2e6b8e6eba5e4df4a058848c7059ebdf9433815d54bb4c86f908bf3
# TT build 2: build 1 + test overrides /tmp/tt-hook-mm and /tmp/tt-hook-safe (sh tt.sh look)
HOOK_TT2=347a911454a48cc494851178d4298c29b71d8854fd3087ce6cb403e51c7885c5
T=$K/altscreen-sha256

say(){ echo "$*"; }
dm(){ LD_LIBRARY_PATH=/eso/lib:/mnt/app/root/lib-target:/mnt/app/usr/lib:/mnt/app/armle/lib:/mnt/app/armle/lib/dll:/mnt/app/armle/usr/lib IPL_CONFIG_DIR=/etc/eso/production /eso/bin/apps/dmdt "$@"; }
# Dump the display manager state into /tmp/tt-dmdt.txt with a label.
slog(){ logger -p user.info "tt: $*" 2>/dev/null || slogger -c 19 "tt: $*" 2>/dev/null; }
mark(){ for f in /tmp/tt-rgd.log /tmp/altscreen111.log /tmp/mu1438-cluster-runtime.log /tmp/mu1462-supervisor.log; do echo "===== MARK $* =====" >> $f; done; slog "MARK $*"
        { echo "===== MARK $*"; sloginfo 2>/dev/null | tail -300; } >> /tmp/tt-slog-marks.txt; say "Marked: $*"; }
dmdump(){ { echo "===== $1"; echo '--- gs'; dm gs; echo '--- gc'; dm gc; echo '--- gd'; dm gd; } >> /tmp/tt-dmdt.txt 2>&1; }
# Displayables of one context, from the newest gc dump.
ctxlist(){ dm gc 2>/dev/null | awk -v c="$1" '$1==c && $2=="|" {f=1; next} f && /^[ \t]*-+/ {next} f && NF==0 {exit} f && $1 ~ /^-?[0-9]+$/ {printf "%s ", $1}'; }
rw(){ mount -uw /mnt/app || { say 'Cannot make /mnt/app writable.'; exit 1; }; }
ro(){ sync; mount -ur /mnt/app 2>/dev/null; }
which_jar(){
    h=$("$T" "$JAR" 2>/dev/null)
    case "$h" in
        $V12) echo v12;; $V14) echo v14;; $V15) echo v15;; $V16) echo v16;; $V17) echo v17;; $V18) echo v18;; $V19) echo v19;; $V20) echo v20;; $V21) echo v21;; $V22) echo v22;; $V23) echo v23;; $V24) echo v24;; $V25) echo v25;; $V26) echo v26;; $V27) echo v27;; $V28) echo v28;; $V29) echo v29;; $V30) echo v30;; $V31) echo v31;; $V32) echo v32;; $V33) echo v33;; $V34) echo v34;; $V35) echo v35;; $V36) echo v36;; $V37) echo v37;; $V38) echo v38;; $V39) echo v39;; $V40) echo v40;; $V41) echo v41;; $V42) echo v42;; $V43) echo v43;; $V44) echo v44;; $V45) echo v45;; $V46) echo v46;; $V47) echo v47;; $V48) echo v48;; $V49) echo v49;; $V50) echo v50;; $V51) echo v51;; "") echo none;; *) echo "unknown ($h)";;
    esac
}

case "${1:-help}" in
setup)
    # Run from /tmp after copying the kit there. Safe to run again for a kit update.
    test -f /tmp/tt-zoom-v51.jar || { say 'Copy the kit files to /tmp first.'; exit 1; }
    rw
    mkdir -p "$K/logs"
    for f in altscreen-sha256 tt-zoom-v51.jar stock-replay.txt catalogue.txt komo-test.txt panel-test.txt kdk-test.txt fit-test.txt win-test.txt new-test.txt map-test.txt place-test.txt; do
        cp "/tmp/$f" "$K/$f" || { say "missing /tmp/$f"; ro; exit 1; }
    done
    for f in tt-zoom-v12.jar tt-zoom-v14.jar tt-zoom-v15.jar tt-zoom-v16.jar tt-zoom-v17.jar tt-zoom-v18.jar tt-zoom-v19.jar tt-zoom-v20.jar tt-zoom-v21.jar tt-zoom-v22.jar tt-zoom-v23.jar tt-zoom-v24.jar tt-zoom-v25.jar tt-zoom-v26.jar tt-zoom-v27.jar tt-zoom-v28.jar tt-zoom-v29.jar tt-zoom-v30.jar tt-zoom-v31.jar tt-zoom-v32.jar tt-zoom-v33.jar tt-zoom-v34.jar tt-zoom-v35.jar tt-zoom-v36.jar tt-zoom-v37.jar tt-zoom-v42.jar tt-zoom-v43.jar tt-zoom-v44.jar tt-zoom-v49.jar tt-zoom-v50.jar libaltscreen111-tt1.so libaltscreen111-tt2.so cluster_supervisor-v6.sh cluster_supervisor-v7.sh; do
        test -f "/tmp/$f" && cp "/tmp/$f" "$K/$f"
    done
    # Optional panel background picture (made with scripts/mkbg.py; kept on the car, not in git).
    test -f /tmp/panel-bg.a8 && cp /tmp/panel-bg.a8 "$K/panel-bg.a8" && say 'Panel background installed.'
    cp /tmp/tt.sh /mnt/app/root/tt.sh
    chmod 755 "$T" /mnt/app/root/tt.sh
    ok=1
    "$T" $V51 "$K/tt-zoom-v51.jar" || ok=0
    ro
    if test $ok = 1; then say 'Kit installed. From now on just type:  sh tt.sh help'
    else say 'A kit file is damaged - copy the kit again and rerun setup.'; exit 1; fi
    ;;
use)
    v=${2:-}
    case "$v" in v12) h=$V12;; v14) h=$V14;; v15) h=$V15;; v16) h=$V16;; v17) h=$V17;; v18) h=$V18;; v19) h=$V19;; v20) h=$V20;; v21) h=$V21;; v22) h=$V22;; v23) h=$V23;; v24) h=$V24;; v25) h=$V25;; v26) h=$V26;; v27) h=$V27;; v28) h=$V28;; v29) h=$V29;; v30) h=$V30;; v31) h=$V31;; v32) h=$V32;; v33) h=$V33;; v34) h=$V34;; v35) h=$V35;; v36) h=$V36;; v37) h=$V37;; v38) h=$V38;; v39) h=$V39;; v40) h=$V40;; v41) h=$V41;; v42) h=$V42;; v43) h=$V43;; v44) h=$V44;; v45) h=$V45;; v46) h=$V46;; v47) h=$V47;; v48) h=$V48;; v49) h=$V49;; v50) h=$V50;; v51) h=$V51;; *) say 'Usage: sh tt.sh use v51   (or v50 ... v12)'; exit 2;; esac
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
    # One session, one SSH connection, paced by you: each step waits for Enter, so steps can
    # be skipped or taken slowly. q (then Enter) at any prompt stops, cleans up and saves.
    PL=/tmp/tt-rgi-play.txt
    UM=/tmp/mibr-alt111-url-mode
    DIRECT=/tmp/tt-kdk-direct
    finish(){ rm -f "$PL" "$UM" "$DIRECT"; say ''; say '== Saving the logs.'; sh "$0" save; say 'Done. Send the photos (named by step) and the newest logs folder.'; }
    next(){ echo "      [Enter] next step, q = stop and save"; read a; case "$a" in q|Q) finish; exit 0;; esac; }
    step(){ say ''; say "== $1"; }
    rm -f /tmp/tt-panel-pos "$DIRECT"
    say 'Guided test. iPhone plugged in, CarPlay running, parked. PHOTO = take one photo.'
    say 'Each step waits for Enter. Skip a step by just pressing Enter.'
    next
    step 'PART 1: parked demo (no route needed). A demo panel (exit 12A with lanes) stays up.'
    cp "$K/place-test.txt" "$PL" || exit 1
    step 'M1 CLASSIC view, MAP tab: CarPlay map + our framed panel. PHOTO'
    next
    step 'M2 CLASSIC view, CAR tab: panel inside the stock frame. PHOTO'
    next
    step 'M3 SPORT view with the MAP: panel over the map, left of the tach. PHOTO'
    next
    step 'M4 SPORT view, trip computer page: panel at its usual spot. PHOTO'
    next
    cp "$K/new-test.txt" "$PL"
    step 'N CLASSIC view, MAP tab: all new pictures cycle (about 75 s for all). PHOTO only if one looks wrong.'
    next
    rm -f "$PL"
    step 'PART 2: live routes. G0: start a GOOGLE MAPS route now, somewhere a few miles away.'
    next
    step 'G1 CLASSIC view, MAP tab. PHOTO'
    next
    step 'G2 CLASSIC view, CAR tab. PHOTO'
    next
    step 'G3 SPORT view with the MAP. PHOTO'
    next
    step 'G4 SPORT view, trip computer. PHOTO'
    next
    step 'A0: end the Google route, start an APPLE MAPS route now.'
    next
    step 'A1 CLASSIC view, MAP tab. PHOTO'
    next
    step 'A2 SPORT view with the MAP. PHOTO'
    next
    step 'PART X: experiment, keep the Apple route running. Banner window opened directly, nav engine left out.'
    touch "$DIRECT"
    step 'X1 SPORT view with the MAP: CarPlay map AND the panel on the right? PHOTO'
    next
    step 'X2 CLASSIC view, MAP tab: CarPlay map still there? PHOTO'
    next
    step 'X3 CLASSIC view, CAR tab: panel in its window? PHOTO'
    next
    rm -f "$DIRECT"
    step 'Experiment off (back to normal).'
    step 'PART 3: the iPhone draws its own maneuver card on the map. Try switching it off.'
    echo map > "$UM"
    step 'C0: UNPLUG the iPhone, wait 5 s, PLUG it back in, wait for CarPlay, start any route. Then Enter.'
    next
    step 'C1 CLASSIC view, MAP tab: is the iPhone card (top left of the map) gone? Map still there? PHOTO'
    next
    step 'C2 SPORT view with the MAP. PHOTO'
    next
    rm -f "$UM"
    step 'END: end the route. (Unplug and replug once more to get the iPhone card back.)'
    finish
    ;;
layers)
    # Parked test of the cockpit layer lists (dmdt). Context 89 = map + banner; its layer
    # list is changed in the display manager's memory only (no flash; an MMI restart or
    # the end of this test puts the stock list back).
    DIRECT=/tmp/tt-kdk-direct
    S89=
    finish(){
        if test -n "$S89"; then dm dc 89 $S89 >/dev/null 2>&1 && say "Context 89 back to stock: $S89"; fi
        rm -f "$DIRECT" /tmp/tt-layer-off; dmdump 'end'
        say ''; say '== Saving the logs.'; sh "$0" save; say 'Done. Send the photos (named by step) and the newest logs folder.'
    }
    next(){ echo "      [Enter] next step, q = stop and save"; read a; case "$a" in q|Q) finish; exit 0;; esac; }
    step(){ say ''; say "== $1"; }
    try(){
        # $1 = name, rest = layer list for context 89
        n=$1; shift
        if dm dc 89 "$@" >/dev/null 2>&1; then
            echo "89 = $*" >> /tmp/tt-dmdt.txt
            step "$n: context 89 is now: $* (stock: $S89)"
        else
            step "$n: dmdt refused '$*' - just press Enter"; next; return
        fi
        say "   CLASSIC view: tap the CAR tab, then the MAP tab again (that applies it)."
        say "   $n-a CLASSIC view, MAP tab: CarPlay map? panel? PHOTO"
        next
        say "   $n-b SPORT view with the map: CarPlay map? panel on the right? PHOTO"
        next
        dmdump "$n"
    }
    test -x /eso/bin/apps/dmdt || { say 'dmdt not found on this unit.'; exit 1; }
    rm -f /tmp/tt-rgi-play.txt "$DIRECT"
    touch /tmp/tt-layer-off   # v37: keep the jar's own layer lists out of the way
    say 'Layer test. Parked, CarPlay running. About 10 steps, Enter for each, q stops (stock layers come back).'
    step 'L0: start any route on the iPhone (parked is fine). CLASSIC view, MAP tab. CarPlay map showing? Then Enter.'
    next
    dmdump 'L0 map, banner off (context 10)'
    touch "$DIRECT"
    step 'L1: banner window opened (experiment mode). Stock map should now cover CarPlay. PHOTO'
    next
    dmdump 'L1 banner on (context 89)'
    # Stock list from the HMI (defineContextsForG24); never read back from the unit, because
    # an interrupted earlier run can leave a test list in memory.
    S89="20 16 19"
    say "   context 10 = $(ctxlist 10)   context 89 now = $(ctxlist 89)   (stock 89 = $S89)"
    try LA 20 16
    try LB 16 19 20
    try LC 20 16 60
    try LD 16 60 20
    try LE 20 60 16
    dm dc 89 $S89 >/dev/null 2>&1 && say "Context 89 back to stock: $S89"; S89=
    # Photo 3 of the v36 test: right after the window closed, the Sport view showed the
    # CarPlay map AND the panel in the right window. Try to catch that state on purpose.
    step 'LZ: SPORT view with the map. Tap CAR, then MAP (window open, stock map). Then Enter: the window closes.'
    next
    rm -f "$DIRECT"; sleep 1; dmdump 'LZ 1 s after close'
    step 'LZ-a right after closing: CarPlay map AND panel on the right? PHOTO now, and again after 10 s.'
    next
    dmdump 'LZ later'
    finish
    ;;
check)
    # v37 guided check, paced by Enter (q stops and saves).
    finish(){ dmdump 'check end'; say ''; say '== Saving the logs.'; sh "$0" save; say 'Done. Send the photos (named by step) and the newest logs folder.'; }
    next(){ while :; do echo "      [Enter] next step, c = mark a CarPlay crash now, q = stop and save"; read a; case "$a" in q|Q) finish; exit 0;; c|C) mark "crash (step $S)";; *) return;; esac; done; }
    step(){ S=${1%%:*}; S=${S%% *}; say ''; say "== $1"; }
    rm -f /tmp/tt-rgi-play.txt /tmp/tt-kdk-direct /tmp/tt-layer-off /tmp/tt-rgi-kdk-map /tmp/tt-panel-pos
    say "v39 check. jar: $(which_jar). Parked, iPhone plugged in, CarPlay running."
    say '   If the CarPlay tab goes black at any time: type c and Enter right away (marks the logs).'
    say '   If the CarPlay icon only flickers after a replug: q, then sh tt.sh diag, then restart the MMI.'
    say "   layer lists now: map 10 = $(ctxlist 10)   map+banner 89 = $(ctxlist 89)"
    grep 'layers:' /tmp/tt-rgd.log 2>/dev/null | tail -2
    step 'P0: start a route on the iPhone (Google or Apple, parked is fine). Then Enter.'
    next
    dmdump 'P0 route on'
    step 'P1 CLASSIC view, MAP tab: no stock straight-arrow before the first turn; then CarPlay map + panel in the stock frame? PHOTO'
    next
    step 'P2 CLASSIC view, CAR tab: panel in the stock frame. PHOTO'
    next
    step 'P3 SPORT view with the map: CarPlay map + panel on the right? PHOTO'
    next
    step 'P4 SPORT view, trip computer: panel on the right. PHOTO'
    next
    dmdump 'P4'
    step 'P5: END the route. CLASSIC view, MAP tab: banner gone within about 3 s, CarPlay map still there? PHOTO'
    next
    step 'P6: UNPLUG the iPhone, wait 15 s, do NOT touch the tabs. MAP tab: STOCK map (not black)? PHOTO'
    next
    dmdump 'P6 phone off'
    say "   layer lists now: map 10 = $(ctxlist 10)   map+banner 89 = $(ctxlist 89)"
    step 'P7: PLUG the iPhone back in, wait for CarPlay, do NOT touch the tabs. MAP tab: CarPlay map back by itself? PHOTO'
    next
    step 'P8: flip CAR tab -> CarPlay tab -> CAR tab a few times. If CarPlay goes black: type c, then note how long you waited.'
    next
    dmdump 'P7 phone back'
    say "   layer lists now: map 10 = $(ctxlist 10)   map+banner 89 = $(ctxlist 89)"
    finish
    ;;
hookfix)
    # CarPlay hook TT build 2 (carplay/src/native, scripts/wsl-native-build.sh tt): h320 safe
    # area, listening sockets close-on-exec (no busy port after a crash), stock delegates first;
    # build 2 adds the RAM-only test overrides of sh tt.sh look.
    # Writes one file on flash, keeps the original next to the kit. Takes effect after an MMI restart.
    cur=$("$T" "$HOOK" 2>/dev/null)
    case "${2:-}" in
        undo)
            src="$K/libaltscreen111.so.orig"; test -f "$src" || { say 'Nothing to undo.'; exit 1; }
            want=$("$T" "$src" 2>/dev/null)
            case "$want" in $HOOK_STOCK|$HOOK_H320) ;; *) say 'Saved original is damaged - nothing changed.'; exit 1;; esac;;
        "")
            case "$cur" in
                $HOOK_STOCK|$HOOK_H320|$FIX_STOCK|$FIX_H320|$HOOK_TT1) src="$K/libaltscreen111-tt2.so"; want=$HOOK_TT2;;
                $HOOK_TT2) say 'Already in place.'; exit 0;;
                *) say "Unknown hook on the car ($cur) - nothing changed."; exit 1;;
            esac
            test -f "$src" || { say "missing $src - copy the kit and run setup again."; exit 1; }
            "$T" $want "$src" || { say "$src is damaged - nothing changed."; exit 1; };;
        *) say 'Usage: sh tt.sh hookfix   |   sh tt.sh hookfix undo'; exit 2;;
    esac
    test "$cur" = "$want" && { say 'Already in place.'; exit 0; }
    rw
    case "$cur" in $HOOK_STOCK|$HOOK_H320) test -f "$K/libaltscreen111.so.orig" || cp "$HOOK" "$K/libaltscreen111.so.orig";; esac
    # new file + rename: the running process keeps the old file, the next start loads the new one
    cp "$src" "$HOOK.new" && chmod 755 "$HOOK.new" && mv "$HOOK.new" "$HOOK"
    "$T" $want "$HOOK" && r=0 || r=1
    ro
    test $r = 0 && say 'Done. Restart the MMI (hold the MMI knob) to load it.' || say 'Copy failed - check with: sh tt.sh report'
    ;;
sup)
    # Supervisor v7 (scripts/mksup.py): the cockpit renderer runs for the whole session (started
    # after 3 s of car screen, never stopped for the CarPlay tab), no display switching.
    # One file on flash, v2 kept; next replug.
    cur=$("$T" "$SUP" 2>/dev/null)
    case "${2:-}" in
        undo) src="$K/cluster_supervisor.sh.v2"; want=$SUP_V2; test -f "$src" || { say 'Nothing to undo.'; exit 1; };;
        v6) src="$K/cluster_supervisor-v6.sh"; want=$SUP_V6
            case "$cur" in $SUP_V2|$SUP_V3|$SUP_V4|$SUP_V5|$SUP_V6|$SUP_V7) ;; *) say "Unknown supervisor on the car ($cur) - nothing changed."; exit 1;; esac;;
        ""|v7) src="$K/cluster_supervisor-v7.sh"; want=$SUP_V7
            case "$cur" in $SUP_V2|$SUP_V3|$SUP_V4|$SUP_V5|$SUP_V6|$SUP_V7) ;; *) say "Unknown supervisor on the car ($cur) - nothing changed."; exit 1;; esac;;
        *) say 'Usage: sh tt.sh sup [v7]  |  sh tt.sh sup v6  |  sh tt.sh sup undo'; exit 2;;
    esac
    test "$cur" = "$want" && { say 'Already in place.'; exit 0; }
    "$T" $want "$src" || { say "$src is missing or damaged - nothing changed."; exit 1; }
    rw
    test "$cur" = "$SUP_V2" -a ! -f "$K/cluster_supervisor.sh.v2" && cp "$SUP" "$K/cluster_supervisor.sh.v2"
    cp "$src" "$SUP.new" && chmod 755 "$SUP.new" && mv "$SUP.new" "$SUP"
    "$T" $want "$SUP" && r=0 || r=1
    ro
    test $r = 0 && say 'Done. Unplug the iPhone, wait 10 s, plug it back in.' || say 'Copy failed - check with: sh tt.sh report'
    ;;
crash)
    # v41 + supervisor v5 check: tab flips, map return speed, unplug and replug.
    finish(){ rm -f /tmp/mu1462-keep-renderer; mark 'crash test end'; say ''; say '== Saving the logs.'; sh "$0" save; say 'Done. Send the newest logs folder.'; }
    next(){ while :; do echo "      [Enter] next step, c = something went wrong just now, q = stop and save"; read a; case "$a" in q|Q) finish; exit 0;; c|C) mark "problem (step $S)";; *) return;; esac; done; }
    step(){ S=${1%%:*}; S=${S%% *}; say ''; say "== $1"; mark "step $S"; }
    say "Check. $(sh "$0" report 2>/dev/null | grep -E 'jar:|supervisor')"
    say 'Parked, CarPlay connected, no route needed. c + Enter whenever something goes wrong (black, crash, slow).'
    step 'Q: CAR tab <-> CarPlay tab, quick flips, 6 times. Any black CarPlay tab or crash?'
    next
    step 'M: MAP view <-> CarPlay tab, 10 times, some FAST. CarPlay tab always shows CarPlay (not the map)? Map back at once? With a route too if you can.'
    next
    step 'U1: on the MAP view, UNPLUG the iPhone. Within about 5 s: stock map (not black)? PHOTO if not.'
    next
    step 'U2: PLUG it back in, stay on the MAP view. CarPlay connects (no flicker) and the CarPlay map comes back?'
    next
    finish
    ;;
card)
    # The iPhone's own maneuver card on the cockpit CarPlay map.
    #   auto           (default, tt-zoom v49) Classic: card only near turns (1 km, motorway 2 km); Sport: never
    #   off | on       map only / card in both views (until "card auto" or an MMI restart)
    #   left|right|top card position when it shows (small settings file on flash)
    #   default        auto, hook default position
    # Changes go to the iPhone at once when CarPlay is connected (the hook re-sends showUI).
    LAYOUT=/mnt/app/root/mibr-carplay111-nav.maneuverLayout
    send(){ touch /tmp/mibr-alt111-show-only; }
    case "${2:-}" in
        auto) rm -f /tmp/tt-card-fixed; say 'Card: only near turns (switches within a few seconds).';;
        off) touch /tmp/tt-card-fixed; echo map > /tmp/mibr-alt111-url-mode; send; say 'Card off (map only) in both views.';;
        on) touch /tmp/tt-card-fixed; echo base > /tmp/mibr-alt111-url-mode; send; say 'Card on in both views.';;
        left|right|top)
            rw; echo "$2" > "$LAYOUT"; ro; send
            say "Card position $2 (whenever the card shows).";;
        default)
            rm -f /tmp/tt-card-fixed
            if test -f "$LAYOUT"; then rw; rm -f "$LAYOUT"; ro; fi
            send
            say 'Card: automatic, hook default position.';;
        *) say "Usage: sh tt.sh card auto | off | on | left | right | top | default"
           say "   now: $(test -e /tmp/tt-card-fixed && echo fixed || echo auto), surface $(cat /tmp/mibr-alt111-url-mode 2>/dev/null || echo base), position $(cat $LAYOUT 2>/dev/null || echo default)"
           exit 2;;
    esac
    ;;
autozoom)
    # Zoom the cockpit CarPlay map in near a turn and out after it (tt-zoom v47), through the
    # steering-wheel zoom path. RAM only.
    #   on | off     (default on)
    #   steps N      how far, 1-6 zoom steps (default 2)
    case "${2:-}" in
        on) rm -f /tmp/tt-autozoom-off; say 'Auto zoom on.';;
        off) touch /tmp/tt-autozoom-off; say 'Auto zoom off.';;
        steps) case "${3:-}" in [1-6]) echo "$3" > /tmp/tt-autozoom-steps; say "Auto zoom: $3 steps.";;
               *) say 'Usage: sh tt.sh autozoom steps 1-6'; exit 2;; esac;;
        *) say 'Usage: sh tt.sh autozoom on | off | steps N'
           say "   now: $(test -e /tmp/tt-autozoom-off && echo off || echo on), $(cat /tmp/tt-autozoom-steps 2>/dev/null || echo 2) steps (log: /tmp/tt-zoom.log)"
           exit 2;;
    esac
    ;;
banner)
    # Our turn banner on the CarPlay map (tt-zoom v45/v46). RAM only, applies within 2 s.
    #   always     (default) shown the whole route
    #   auto       shown when the next turn is within 1 km (motorway exits 2 km), for 10 s at
    #              route start and 5 s after a turn; faded out in between
    #   alpha N    background opacity on the CarPlay map, 0-100 (default 95)
    case "${2:-}" in
        auto) touch /tmp/tt-panel-auto; say 'Banner: only near turns.';;
        always) rm -f /tmp/tt-panel-auto; say 'Banner: always shown.';;
        alpha) case "${3:-}" in [0-9]|[0-9][0-9]|100) echo "$3" > /tmp/tt-panel-alpha; say "Banner background: $3% on the CarPlay map.";;
                *) say 'Usage: sh tt.sh banner alpha 0-100'; exit 2;; esac;;
        *) say 'Usage: sh tt.sh banner auto | always | alpha N'
           say "   now: $(test -e /tmp/tt-panel-auto && echo auto || echo always), background $(cat /tmp/tt-panel-alpha 2>/dev/null || echo 95)%"
           exit 2;;
    esac
    ;;
look)
    # How much road the cockpit CarPlay map shows (hook TT build 2). RAM only, read by the hook
    # when the iPhone connects: replug after a change; an MMI restart forgets it.
    #   1..4           screen size the iPhone is told: 1 = 320x120 mm (built in), 2 = 430x160,
    #                  3 = 580x215, 4 = 780x290. A bigger screen should make iOS draw smaller.
    #   mm W H         any size
    #   safe X Y W H   the safe window (built in 520 110 400 320)
    #   reset          built-in values
    test "$("$T" "$HOOK" 2>/dev/null)" = "$HOOK_TT2" || say 'Note: needs hook TT build 2 (sh tt.sh hookfix) - the current hook ignores this.'
    MM=/tmp/tt-hook-mm; SAFE=/tmp/tt-hook-safe
    case "${2:-}" in
        1) rm -f $MM;;
        2) echo '430 160' > $MM;;
        3) echo '580 215' > $MM;;
        4) echo '780 290' > $MM;;
        mm) test -n "${4:-}" || { say 'Usage: sh tt.sh look mm W H'; exit 2; }; echo "$3 $4" > $MM;;
        safe) test -n "${6:-}" || { say 'Usage: sh tt.sh look safe X Y W H'; exit 2; }; echo "$3 $4 $5 $6" > $SAFE;;
        reset) rm -f $MM $SAFE;;
        # v51: safe window lower/taller: the car sits lower during guidance, the app's ETA bar lower
        low1) echo '520 110 400 360' > $SAFE;;
        low2) echo '520 110 400 400' > $SAFE;;
        low3) echo '520 170 400 360' > $SAFE;;
        *) say 'Usage: sh tt.sh look 1|2|3|4 | low1|low2|low3 | mm W H | safe X Y W H | reset'
           say "   now: mm $(cat $MM 2>/dev/null || echo 320 120), safe $(cat $SAFE 2>/dev/null || echo 520 110 400 320)"
           exit 2;;
    esac
    say "Screen $(cat $MM 2>/dev/null || echo 320 120) mm, safe window $(cat $SAFE 2>/dev/null || echo 520 110 400 320). Unplug the iPhone, wait 5 s, plug it back in."
    ;;
unstick)
    # After a crash the next connections fail ("cannot bind renderer tee port"): something from
    # the dead session still holds 127.0.0.1:19820. Record who, then stop leftover supervisor /
    # renderer processes whose session (dio_manager PID, their last argument) is gone.
    sh "$0" diag >/dev/null 2>&1
    n=0
    stopped=
    pidin ar 2>/dev/null | grep -E 'cluster_supervisor.sh|cluster_runtime' | grep -v grep > /tmp/tt-unstick.$$
    while read -r pid rest; do
        owner=${rest##* }
        case "$owner" in ''|*[!0-9]*) continue;; esac
        if ! kill -0 "$owner" 2>/dev/null; then
            say "stopping $pid ($rest): its session $owner is gone"
            kill -TERM "$pid" 2>/dev/null; n=$((n + 1)); stopped="$stopped $pid"
        fi
    done < /tmp/tt-unstick.$$
    if test $n -gt 0; then
        sleep 2
        for pid in $stopped; do kill -0 "$pid" 2>/dev/null && kill -KILL "$pid" 2>/dev/null && say "forced $pid"; done
    fi
    rm -f /tmp/tt-unstick.$$
    d=$(pidin ar 2>/dev/null | grep -c '[d]io_manager')
    say "Stopped $n leftover process(es). dio_manager processes running: $d"
    test "$d" -gt 1 && say 'More than one dio_manager: an old session did not end - send the logs (sh tt.sh save).'
    { echo "===== UNSTICK stopped=$n dio_manager=$d"; } >> /tmp/tt-diag.txt
    say 'Now unplug the iPhone, wait 10 s, plug it back in. If it still flickers: sh tt.sh save, then restart the MMI.'
    ;;
delay)
    # Seconds the cockpit renderer waits on the map view before starting (supervisor v5 reads it
    # at the next connect; lost at an MMI restart). Longer = fewer crashes, slower map return.
    case "${2:-}" in
        ''|*[!0-9]*) say "Usage: sh tt.sh delay SECONDS   (now: $(cat /tmp/mu1462-start-delay 2>/dev/null || echo 1))"; exit 2;;
    esac
    echo "$2" > /tmp/mu1462-start-delay
    say "Renderer start delay on the map view: $2 s from the next connect (replug)."
    ;;
diag)
    # When the CarPlay icon only flickers: who holds the hook's ports? Added to the logs.
    { echo "===== DIAG"; echo '--- processes'; pidin arg 2>/dev/null | grep -E 'dio_manager|cluster_|mm-ipod|sleep' | grep -v grep
      echo '--- sockets'; netstat -an 2>/dev/null | grep -E '19820|19821|6031|19810'
      echo '--- hook'; tail -20 /tmp/altscreen111.log 2>/dev/null
      echo '--- renderer'; tail -10 /tmp/mu1438-cluster-runtime.log 2>/dev/null
      for p in $(pidin arg 2>/dev/null | grep -E 'dio_manager|cluster_' | grep -v grep | awk '{print $1}'); do
          echo "--- fds of $p"; pidin -p $p fds 2>/dev/null | head -40; done; } >> /tmp/tt-diag.txt 2>&1
    tail -40 /tmp/tt-diag.txt; say ''; say 'Saved in /tmp/tt-diag.txt (sh tt.sh save keeps it).'
    ;;
mark)
    shift; mark "${*:-crash}"
    ;;
layer89)
    # Set the map + banner layer list by hand (memory only; an MMI restart restores it).
    case "${2:-}" in
        stock) dm dc 89 20 16 19 && say 'Context 89 back to stock: 20 16 19';;
        [0-9]*) shift; dm dc 89 "$@" && say "Context 89 is now: $* (tap CAR, then MAP to apply)";;
        *) say "Usage: sh tt.sh layer89 stock | sh tt.sh layer89 20 16   (now: $(ctxlist 89))"; exit 2;;
    esac
    ;;
dm)
    dmdump "${2:-manual}"; say "Display manager state added to /tmp/tt-dmdt.txt (context 89: $(ctxlist 89))"
    ;;
mode)
    case "${2:-}" in
        default) rm -f /tmp/tt-layer-off /tmp/tt-kdk-direct /tmp/tt-rgi-kdk-map /tmp/tt-rgi-noactive /tmp/tt-rgi-kdk /tmp/tt-rgi-nokdk /tmp/tt-rgi-nokdk-small /tmp/tt-rgi-nopad /tmp/tt-rgi-off /tmp/tt-panel-off; say 'Mode: default (our panel inside the stock banner, every view).';;
        direct) touch /tmp/tt-kdk-direct; say 'Mode: experiment, banner window opened directly (no nav-engine view).';;
        layersoff) touch /tmp/tt-layer-off; say 'Mode: stock layer lists (v36 behaviour: banner off on the map). Back: sh tt.sh mode default';;
        kdkmap) touch /tmp/tt-rgi-kdk-map; say 'Mode: stock banner on the map too (v32 behaviour, hides the CarPlay map).';;
        nokdk) touch /tmp/tt-rgi-nokdk; say 'Mode: no stock banner (v26 behaviour: Sport view only).';;
        kdk) rm -f /tmp/tt-rgi-nokdk; touch /tmp/tt-rgi-kdk; say 'Mode: stock banner in every view.';;
        nokdksmall) touch /tmp/tt-rgi-nokdk-small; say 'Mode: no stock banner in the Sport view either.';;
        nopanel) touch /tmp/tt-panel-off; say 'Mode: nopanel (our turn panel off).';;
        noactive) touch /tmp/tt-rgi-noactive; say 'Mode: never report route active.';;
        nopad) touch /tmp/tt-rgi-nopad; say 'Arrows: bare 2-number shape.';;
        off) touch /tmp/tt-rgi-off; say 'Cockpit feed off.';;
        on) rm -f /tmp/tt-rgi-off; say 'Cockpit feed on.';;
        *) say 'Usage: sh tt.sh mode default|layersoff|direct|kdkmap|nokdk|kdk|nopanel|noactive|nopad|off|on'; exit 2;;
    esac
    ;;
panel)
    # Live position/size of our turn panel per view (v50: redrawn at once, no restart).
    #   where      report: skin, view, panel mode and position, the stock banner window
    P=/tmp/tt-panel-pos
    case "${2:-}" in
        kdk-small|kdk-smallmap|kdk-large|left|right|small|flap)
            test -n "${4:-}" || { say 'Usage: sh tt.sh panel kdk-small|kdk-large X Y [SCALE]'; exit 2; }
            touch $P; grep -v "^$2 " $P > $P.new 2>/dev/null; echo "$2 $3 $4 ${5:-1}" >> $P.new; mv $P.new $P
            say "Panel $2 view: x=$3 y=$4 scale=${5:-1} (applies at the next update)";;
        reset) rm -f $P; say 'Panel position back to defaults.';;
        where) touch /tmp/tt-panel-where; sleep 2
               w=$(grep 'where:' /tmp/tt-rgd.log 2>/dev/null | tail -1 | sed 's/^[0-9]* //'); say "$w"
               c=$(echo "$w" | sed -n 's/.* ctx \([0-9-]*\).*/\1/p')
               test -n "$c" && say "context $c layers: $(ctxlist "$c")   (16 HMI, 19 stock map, 20 banner, 60 CarPlay)"
               test -e /tmp/tt-panel-where && say '(no answer: is tt-zoom v50 or newer loaded? sh tt.sh report)';;
        show) cat $P 2>/dev/null || say '(defaults: kdk-small 991 160 1, kdk-large 1105 110 1)';;
        *) say 'Usage: sh tt.sh panel kdk-small|kdk-large X Y [SCALE] | where | reset | show'; exit 2;;
    esac
    ;;
report)
    say "== jar: $(which_jar)    (v51 is the current one)"
    say "== layers: map 10 = $(ctxlist 10)  map+banner 89 = $(ctxlist 89)  (v37 with CarPlay: 16 60 / 20 16 60)"
    grep "layers:" /tmp/tt-rgd.log 2>/dev/null | tail -3
    h=$("$T" "$HOOK" 2>/dev/null); case "$h" in $HOOK_STOCK) say '== CarPlay hook: original';; $HOOK_H320) say '== CarPlay hook: original (h320 preset)';; $FIX_STOCK|$FIX_H320) say '== CarPlay hook: fix1 (old byte patch - replace with: sh tt.sh hookfix)';; $HOOK_TT1) say '== CarPlay hook: TT build 1 (from source: no port leak, always falls back to plain CarPlay)';; $HOOK_TT2) say "== CarPlay hook: TT build 2 (build 1 + look tests: mm $(cat /tmp/tt-hook-mm 2>/dev/null || echo 320 120), safe $(cat /tmp/tt-hook-safe 2>/dev/null || echo 520 110 400 320))";; *) say "== CarPlay hook: unknown ($h)";; esac
    h=$("$T" "$SUP" 2>/dev/null); case "$h" in $SUP_V2) say '== supervisor: v2 (switches the display to 901)';; $SUP_V3) say '== supervisor: v3 (no display switch: no CarPlay map in the map views - replace it)';; $SUP_V4) say '== supervisor: v4 (4 s start delay: slow map - replace with v5)';; $SUP_V5) say "== supervisor: v5 (renderer only on the map view)";; $SUP_V6) say '== supervisor: v6 (test switch version - replace with v7)';; $SUP_V7) say '== supervisor: v7 (renderer runs all session, no display switching)';; *) say "== supervisor: unknown ($h)";; esac
    tail -3 /tmp/mu1462-supervisor.log 2>/dev/null
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
    sloginfo 2>/dev/null | tail -4000 > /tmp/tt-slog.txt
    rw; mkdir -p "$K/logs/run$n"
    for f in /tmp/tt-rgd.log /tmp/tt-rgd.log.1 /tmp/tt-nav.log /tmp/tt-zoom.log /tmp/tt-rgd.txt /tmp/tt-rgd-cat.txt /tmp/tt-route.txt /tmp/tt-dmdt.txt /tmp/altscreen111.log /tmp/mu1438-cluster-runtime.log /tmp/mibr-alt111-gen2.status /tmp/mibr-carplay111.state /tmp/tt-diag.txt /tmp/tt-slog.txt /tmp/mu1462-supervisor.log /tmp/tt-slog-marks.txt; do test -f "$f" && cp "$f" "$K/logs/run$n/"; done
    ro
    say "Saved to $K/logs/run$n (kept across MMI restarts). On the Mac:"
    say "scp -O -r -o HostKeyAlgorithms=+ssh-rsa -o PubkeyAcceptedAlgorithms=+ssh-rsa root@10.173.189.1:$K/logs ~/Downloads/tt-logs"
    ;;
*)
    say 'sh tt.sh report              what is installed and what it is doing (paste this)'
    say 'sh tt.sh use v51             switch version (v51 ... v12), then restart the MMI'
    say 'sh tt.sh play map|new|fit|win|kdk|panel|komo|stock  parked tests'
    say 'sh tt.sh play arrows | stop  arrow catalogue / stop playback'
    say 'sh tt.sh test                the full guided test, Enter for each step, then saves the logs'
    say 'sh tt.sh check               v38 guided check (Enter for each step, c marks a CarPlay crash)'
    say 'sh tt.sh hookfix [undo]      CarPlay hook TT build 2 (flash, then MMI restart)'
    say 'sh tt.sh autozoom on|off|steps N  zoom the map in near turns, out after'
    say 'sh tt.sh banner always|auto|alpha N  our banner always / only near turns, background opacity'
    say 'sh tt.sh look 1|2|3|4|reset  how much road the cockpit map shows (next replug, RAM only)'
    say 'sh tt.sh sup [v6|v7|undo]    renderer supervisor: v6 (keeps the display switch), v7, or back to v2 (flash, then replug)'
    say 'sh tt.sh crash               check: tab flips, map return, unplug and replug'
    say 'sh tt.sh card auto|off|on|left|right|top|default  the iPhone card: near turns / never / always, position'
    say 'sh tt.sh unstick             after a crash, when CarPlay will not reconnect: clear the old session'
    say 'sh tt.sh delay SECONDS       renderer start delay on the map view (default 1)'
    say 'sh tt.sh diag                when the CarPlay icon only flickers: record who holds the ports'
    say 'sh tt.sh mark [text]         put a marker line into all logs (e.g. right after a crash)'
    say 'sh tt.sh layers              parked layer test for the map + banner (context 89)'
    say 'sh tt.sh layer89 stock|LIST  set the map + banner layers by hand (memory only)'
    say 'sh tt.sh dm [label]          add the display manager state to the logs'
    say 'sh tt.sh seen                what the iPhone sent so far (maneuver types, lanes)'
    say 'sh tt.sh mode default|nokdk|kdk|nopanel|noactive|nopad|off|on'
    say 'sh tt.sh panel kdk-small|kdk-large X Y [S]  move/resize the panel live (reset | show)'
    say 'sh tt.sh save                keep the logs across MMI restarts'
    say 'sh tt.sh remove              take tt-zoom.jar out (restart the MMI)'
    ;;
esac
