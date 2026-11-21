#!/bin/sh
# CarPlay maps on the Audi TT 8S Virtual Cockpit - installer @@VERSION@@
# For MHI2_US_AU43x_P5180 / MU1462 only: every file is checked by SHA-256 and
# nothing is changed unless all checks pass.
# Based on aberbic/Audi-MHI2-Virtual-Cockpit-Altscreen-CarPlay-AndroidAuto (GPL-3.0).
#
# Run from M.I.B. (mod/custom.sh reads the action from mod/tt/action.txt) or
# over SSH:  sh tt-setup.sh check|export|install|restore|logs
#
#   check    read-only: is this car supported, is the SD card complete
#   export   copies lsd.jxe and dio_manager to mod/tt/export/ for the PC builder
#   install  backs up, installs, verifies (flash write)
#   restore  puts back every file the last install changed (flash write)
#   logs     copies the logs to mod/tt/logs/ for a bug report
#   recoff   route recorder off for good (one small file on flash); recon turns it back on
# Never restarts the MMI; do that yourself afterwards (hold the MMI knob).
#
# Route recorder (in the HMI jar): every route is saved to the SD card in this slot's
# tt-routes/ folder (last 20; without a card: RAM until the MMI restarts). A recording holds
# what the phone sent for that route, street names and the destination included. It stays on
# the card, is never sent anywhere, and is only needed for bug reports.
set -u
PATH=/proc/boot:/bin:/usr/bin:/sbin:/usr/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:/mnt/app/armle/sbin:/mnt/app/armle/usr/sbin
export PATH
unset LD_PRELOAD || :
case $0 in */*) D=${0%/*};; *) D=.;; esac
D=$(cd "$D" && pwd)
VERSION=@@VERSION@@
action=${1:-check}

# Stock MU1462 P5180 files.
STOCK_JXE=@@STOCK_JXE@@
STOCK_AIRPLAY=@@STOCK_AIRPLAY@@
STOCK_IAP2=@@STOCK_IAP2@@
STOCK_DIO=@@STOCK_DIO@@
STOCK_MMIPOD=@@STOCK_MMIPOD@@
# What gets installed.
NEW_DIO=@@NEW_DIO@@
NEW_LIB=@@NEW_LIB@@
NEW_RT=@@NEW_RT@@
NEW_SUP=@@NEW_SUP@@
NEW_JAR=@@NEW_JAR@@
NEW_KIT=@@NEW_KIT@@
SHA_TOOL=@@SHA_TOOL@@
# chefranov's route-guidance hook v1.1.10 (optional, supplied by the user).
RGD_HOOK=@@RGD_HOOK@@

BIN=/mnt/app/eso/bin/apps/dio_manager
LIB=/mnt/app/root/lib-target/libaltscreen111.so
RT=/mnt/app/root/mu1438-cluster/cluster_runtime
SUP=/mnt/app/root/mu1438-cluster/cluster_supervisor.sh
JARS=/mnt/app/eso/hmi/lsd/jars
JAR=$JARS/tt-zoom.jar
K=/mnt/app/root/tt
SBIN=/mnt/app/armle/usr/sbin
MMIPOD=$SBIN/mm-ipod
RGD=/mnt/app/root/rgd
LAYOUT=/mnt/app/root/mibr-carplay111-nav.maneuverLayout
# the hook sends the map options (card position, ETA bar) only while this marker exists
QUERY=/mnt/app/root/mibr-carplay111-nav-query.enabled
ETA=/mnt/app/root/mibr-carplay111-nav.showETA
# the hook's persistent surface: "map" = no iPhone turn card (its own fallback is the card)
SURFACE=/mnt/app/root/mibr-carplay111-nav.surface
BACKUPS=/mnt/app/root/tt-backups
PF_DIR=/mnt/system/etc
BLOCK='block drop in quick on carplay0 all'
RULE='pass in quick on carplay0 proto tcp from any to any port = 6031 allow-opts'

P=$D/payload
B=$D/build
E=$D/export
U=$D/user

say(){ echo "$*"; }
fail=0
ok(){ say "OK    $1"; }
bad(){ say "FAIL  $1"; fail=1; }
note(){ say "note  $1"; }

test -d /mnt/app/eso/hmi/lsd && test -f /ifs/lsd.jxe || { say 'This must run on the MMX head unit.'; exit 1; }
say "TT cockpit CarPlay $VERSION - $action"

tool=/tmp/tt-sha.$$
cp "$P/altscreen-sha256" "$tool" 2>/dev/null && chmod 755 "$tool" || { say 'payload/altscreen-sha256 missing - copy the whole release to the SD card again.'; exit 1; }
is(){ "$tool" "$1" "$2" >/dev/null 2>&1; }
hash(){ "$tool" "$1" 2>/dev/null; }
is "$SHA_TOOL" "$tool" || { say 'payload/altscreen-sha256 is damaged - copy the release again.'; rm -f "$tool"; exit 1; }

rw_app=0
rw_sys=0
backup=
cleanup(){
    rc=$?
    if test "$rw_sys" = 1; then sync || :; mount -ur /mnt/system || say 'WARNING: /mnt/system still writable'; fi
    if test "$rw_app" = 1; then sync || :; mount -ur /mnt/app || say 'WARNING: /mnt/app still writable'; fi
    rm -f "$tool" /tmp/tt-pf.$$.* /tmp/tt-ps.$$ /tmp/tt-shim.$$ || :
    if test "$rc" != 0 && test -n "$backup"; then say "FAILED. Backup of the changed files: $backup"; fi
}
trap cleanup 0
trap 'exit 1' 1 2 15

# ---- firmware -------------------------------------------------------------------------
firmware(){
    is "$STOCK_JXE" /ifs/lsd.jxe && ok 'HMI image is MU1462 P5180' || bad 'HMI image is not MU1462 P5180 (unsupported firmware)'
    is "$STOCK_AIRPLAY" /mnt/app/eso/lib/libairplay.so && ok 'CarPlay library is stock' || bad 'CarPlay library differs (unsupported firmware)'
    is "$STOCK_IAP2" /mnt/app/armle/lib/dll/ipod-drvr-iap2.so && ok 'iAP2 driver is stock' || bad 'iAP2 driver differs (unsupported firmware)'
}

# ---- logs (read-only on flash) -----------------------------------------------------------
if test "$action" = logs; then
    n=$(date +%Y%m%d-%H%M%S)
    L=$D/logs/$n
    mkdir -p "$L" || { say 'Cannot write to the SD card.'; exit 1; }
    for f in /tmp/tt-rgd.log /tmp/tt-rgd.log.1 /tmp/tt-zoom.log /tmp/altscreen111.log /tmp/mu1438-cluster-runtime.log \
             /tmp/mibr-alt111-gen2.status /tmp/mibr-carplay111.state /tmp/mu1462-supervisor.log /tmp/tt-routes/route-*.txt; do
        test -f "$f" && cp "$f" "$L/"
    done
    {
        say "version $VERSION"
        for f in /ifs/lsd.jxe "$BIN" "$LIB" "$RT" "$SUP" "$JAR" "$MMIPOD" "$K/tt.sh"; do
            say "$f $(hash "$f")"
        done
        ls -l "$BACKUPS" 2>/dev/null
        pidin ar 2>/dev/null | grep -E 'dio_manager|cluster_runtime|mm-ipod|supervisor'
    } > "$L/report.txt" 2>&1
    say "Logs saved to the SD card: mod/tt/logs/$n"
    say 'Route recordings on a card are in its tt-routes/ folder (they include street names and the destination).'
    exit 0
fi

# ---- route recorder on/off (one marker file on flash) ------------------------------------------
if test "$action" = recoff || test "$action" = recon; then
    mount -uw /mnt/app && rw_app=1 || { say 'Cannot make /mnt/app writable.'; exit 1; }
    if test "$action" = recoff; then
        : > /mnt/app/root/tt-rec-off && say 'Route recorder off (from the next MMI restart). Existing recordings: delete the tt-routes/ folder on the card.'
    else
        rm -f /mnt/app/root/tt-rec-off && say 'Route recorder on (from the next MMI restart).'
    fi
    exit 0
fi

# ---- export (read-only on flash) ---------------------------------------------------------
if test "$action" = export; then
    firmware
    is "$STOCK_DIO" "$BIN" && ok 'dio_manager is stock' || bad 'dio_manager is not the stock file (already modified?)'
    test "$fail" = 0 || { say 'Stopped: this car cannot be used to build the install files.'; exit 1; }
    mkdir -p "$E" || { say 'Cannot write to the SD card.'; exit 1; }
    cp /ifs/lsd.jxe "$E/lsd.jxe" && cp "$BIN" "$E/dio_manager" || { say 'Copy to the SD card failed (full?).'; exit 1; }
    is "$STOCK_JXE" "$E/lsd.jxe" && is "$STOCK_DIO" "$E/dio_manager" || { say 'The copies on the SD card are damaged - try another card.'; exit 1; }
    say 'Exported: mod/tt/export/lsd.jxe and dio_manager.'
    say 'Next: put the SD card in your computer and run the builder (see README).'
    exit 0
fi

# ---- restore -----------------------------------------------------------------------------
if test "$action" = restore; then
    last=$(ls -d "$BACKUPS"/2* 2>/dev/null | tail -1)
    test -n "$last" && test -f "$last/manifest" || { say "No backup found in $BACKUPS - nothing to restore."; exit 1; }
    backup=$last
    say "Restoring from $last"
    while IFS='|' read -r name dest mode old new; do
        if test "$old" != absent; then
            is "$old" "$last/$name.before" || { say "Backup file $name is damaged - stopping, nothing changed."; exit 1; }
        fi
    done < "$last/manifest"
    mount -uw /mnt/app && rw_app=1
    mount -uw /mnt/system && rw_sys=1
    # reverse order: the route-guidance shim goes back before its real binary is removed
    : > /tmp/tt-ps.$$
    while IFS= read -r line; do
        { printf '%s\n' "$line"; cat /tmp/tt-ps.$$; } > /tmp/tt-ps.$$.r && mv /tmp/tt-ps.$$.r /tmp/tt-ps.$$
    done < "$last/manifest"
    while IFS='|' read -r name dest mode old new; do
        if test "$old" = absent; then
            test -e "$dest" && mv "$dest" "$last/$name.removed"
        else
            cp "$last/$name.before" "$dest.tt-restore" && chmod "$mode" "$dest.tt-restore" \
                && is "$old" "$dest.tt-restore" && mv "$dest.tt-restore" "$dest" && is "$old" "$dest" \
                || { say "Could not restore $dest"; exit 1; }
        fi
    done < /tmp/tt-ps.$$
    rmdir "$SBIN/rgd_real" "$RGD" "$K" 2>/dev/null || :
    mv "$last" "$last.restored"
    say 'Restored and verified. Restart the MMI (hold the MMI knob) while parked.'
    exit 0
fi

case "$action" in check|install) ;; *) say "Unknown action '$action' (check, export, install, restore, logs, recoff, recon)."; exit 2;; esac

# ---- check / install -----------------------------------------------------------------------
firmware
cur=$(hash "$BIN")
if test "$cur" = "$STOCK_DIO"; then ok 'dio_manager is stock'
elif test "$cur" = "$NEW_DIO"; then bad 'already installed (dio_manager is patched) - run restore first'
else bad 'dio_manager is modified by something else'; fi
test -e "$LIB" && bad "another AltScreen install is present ($LIB)" || ok 'no other AltScreen install'
is "$STOCK_MMIPOD" "$MMIPOD" && ok 'mm-ipod is stock' || bad 'mm-ipod is modified (another route-guidance mod?)'
for other in mu1438-cluster.jar rgd_hook.jar carplay_hook.jar tt-zoom.jar; do
    test ! -e "$JARS/$other" || bad "$JARS/$other present - another CarPlay HMI mod"
done
is "$NEW_LIB" "$P/libaltscreen111.so" && ok 'payload: CarPlay hook' || bad 'payload/libaltscreen111.so damaged or missing'
is "$NEW_RT" "$P/cluster_runtime" && ok 'payload: cockpit renderer' || bad 'payload/cluster_runtime damaged or missing'
is "$NEW_SUP" "$P/cluster_supervisor.sh" && ok 'payload: renderer supervisor' || bad 'payload/cluster_supervisor.sh damaged or missing'
is "$NEW_KIT" "$P/tt.sh" && ok 'payload: tt.sh toolkit' || bad 'payload/tt.sh damaged or missing'
if is "$NEW_JAR" "$B/tt-zoom.jar" && is "$NEW_DIO" "$B/dio_manager"; then ok 'build: HMI jar and dio_manager (from the PC builder)'
else bad 'build/ is missing or does not match - run export, then the PC builder'; fi
rgd=0
if test -f "$U/librgd_hook.so"; then
    if is "$RGD_HOOK" "$U/librgd_hook.so"; then ok 'user: librgd_hook.so v1.1.10 (turn-by-turn panel on)'; rgd=1
    else bad 'user/librgd_hook.so is not the v1.1.10 file - remove it or use the right file'; fi
else note 'no user/librgd_hook.so: map only, no turn-by-turn panel'; fi

pf_count=0
for f in "$PF_DIR"/pf.conf "$PF_DIR"/pf.*.conf; do
    test -f "$f" || continue
    b=${f##*/}
    if grep -q 'port = 6031' "$f"; then bad "firewall $b already has a 6031 rule (another install?)"; continue; fi
    n=0
    : > "/tmp/tt-pf.$$.$b"
    while IFS= read -r line || test -n "$line"; do
        case $line in "$BLOCK"*) printf '%s\n' "$RULE" >> "/tmp/tt-pf.$$.$b"; n=$((n+1));; esac
        printf '%s\n' "$line" >> "/tmp/tt-pf.$$.$b"
    done < "$f"
    case $n in
        1) if pfctl -n -f "/tmp/tt-pf.$$.$b" >/dev/null 2>&1; then pf_count=$((pf_count+1)); else bad "firewall $b: new rule rejected"; fi;;
        0) rm -f "/tmp/tt-pf.$$.$b";;
        *) bad "firewall $b: $n carplay0 block lines";;
    esac
done
test "$pf_count" -ge 1 && ok "firewall: $pf_count file(s) to update" || bad 'firewall: nothing to update'

pidin ar > /tmp/tt-ps.$$ 2>/dev/null || :
if grep -q 'dio_manager' /tmp/tt-ps.$$; then
    if test "$action" = install; then bad 'a phone is connected (dio_manager running): unplug it, wait 10 s, run again'
    else note 'unplug the phone before installing'; fi
fi
test "$fail" = 0 || { say 'Stopped: nothing was changed.'; exit 1; }
if test "$action" = check; then say 'All checks passed. Nothing was changed.'; exit 0; fi

# ---- install: stage everything next to its target, then swap -------------------------------
backup=$BACKUPS/$(date +%Y%m%d-%H%M%S)
mount -uw /mnt/app && rw_app=1 || { say 'Cannot make /mnt/app writable.'; exit 1; }
mount -uw /mnt/system && rw_sys=1 || { say 'Cannot make /mnt/system writable.'; exit 1; }
mkdir -p "$backup" || exit 1
: > "$backup/manifest"

# name dest mode newhash source
stage(){
    if test -e "$2"; then
        old=$(hash "$2")
        cp "$2" "$backup/$1.before" && is "$old" "$backup/$1.before" || { say "Backup of $2 failed"; exit 1; }
    else old=absent; fi
    mkdir -p "${2%/*}"
    cp "$5" "$2.tt-new" && chmod "$3" "$2.tt-new" && is "$4" "$2.tt-new" || { say "Staging $2 failed"; exit 1; }
    printf '%s|%s|%s|%s|%s\n' "$1" "$2" "$3" "$old" "$4" >> "$backup/manifest"
}
stage dio_manager "$BIN" 777 "$NEW_DIO" "$B/dio_manager"
stage libaltscreen111.so "$LIB" 755 "$NEW_LIB" "$P/libaltscreen111.so"
stage cluster_runtime "$RT" 755 "$NEW_RT" "$P/cluster_runtime"
stage cluster_supervisor.sh "$SUP" 755 "$NEW_SUP" "$P/cluster_supervisor.sh"
stage tt-zoom.jar "$JAR" 755 "$NEW_JAR" "$B/tt-zoom.jar"
stage tt.sh "$K/tt.sh" 755 "$NEW_KIT" "$P/tt.sh"
stage altscreen-sha256 "$K/altscreen-sha256" 755 "$SHA_TOOL" "$P/altscreen-sha256"
printf 'top\n' > /tmp/tt-ps.$$
stage maneuverLayout "$LAYOUT" 644 "$(hash /tmp/tt-ps.$$)" /tmp/tt-ps.$$
printf '1\n' > /tmp/tt-ps.$$
stage nav-query "$QUERY" 644 "$(hash /tmp/tt-ps.$$)" /tmp/tt-ps.$$
# the app's own ETA bar off by default (the car's bottom strip shows the same); sh tt.sh eta on
printf 'no\n' > /tmp/tt-ps.$$
stage showETA "$ETA" 644 "$(hash /tmp/tt-ps.$$)" /tmp/tt-ps.$$
# the iPhone's turn card off by default, also before the HMI has started (sh tt.sh card auto|on)
printf 'map\n' > /tmp/tt-ps.$$
stage navSurface "$SURFACE" 644 "$(hash /tmp/tt-ps.$$)" /tmp/tt-ps.$$
for t in /tmp/tt-pf.$$.*; do
    test -f "$t" || continue
    b=${t##*.$$.}
    if test -x "$PF_DIR/$b"; then m=755; else m=644; fi
    stage "$b" "$PF_DIR/$b" "$m" "$(hash "$t")" "$t"
done
if test "$rgd" = 1; then
    {
        echo '#!/bin/sh'
        echo '# TT cockpit CarPlay: starts the stock mm-ipod with the route-guidance hook.'
        echo "# Off without a flash write: touch /tmp/rgd_disable, replug the phone."
        echo "if [ ! -e /tmp/rgd_disable ] && [ ! -e $RGD/disable ]; then"
        echo "    LD_PRELOAD=$RGD/librgd_hook.so"
        echo '    export LD_PRELOAD'
        echo 'fi'
        echo "exec $SBIN/rgd_real/mm-ipod \"\$@\""
    } > /tmp/tt-shim.$$
    stage librgd_hook.so "$RGD/librgd_hook.so" 755 "$RGD_HOOK" "$U/librgd_hook.so"
    stage mm-ipod.real "$SBIN/rgd_real/mm-ipod" 755 "$STOCK_MMIPOD" "$MMIPOD"
    stage mm-ipod "$MMIPOD" 755 "$(hash /tmp/tt-shim.$$)" /tmp/tt-shim.$$
fi
while IFS='|' read -r name dest mode old new; do
    mv "$dest.tt-new" "$dest" && is "$new" "$dest" || { say "Could not install $dest - run restore."; exit 1; }
done < "$backup/manifest"
cp "$0" "$backup/tt-setup.sh" 2>/dev/null || :
# a copy of the backup on the SD card as well
mkdir -p "$D/backups" && cp -R "$backup" "$D/backups/" 2>/dev/null || note 'could not copy the backup to the SD card'
say "Installed and verified. Backup: $backup (copy on the SD card: mod/tt/backups/)"
say 'Restart the MMI (hold the MMI knob) while parked, then plug the iPhone in.'
exit 0
