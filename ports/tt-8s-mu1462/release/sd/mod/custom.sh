#!/bin/sh
# M.I.B. -> Advanced Settings -> Run Custom Script, or the MIB2 Toolbox green-menu screen
# (Customization -> TTCarPlay, buttons in mod/tt/gem/).
# TT cockpit CarPlay: runs mod/tt/tt-setup.sh with the action written in mod/tt/action.txt
# (check, export, install, restore or logs). The output is also saved to mod/tt/last-run.txt.
# Never restarts the MMI.
# the green menu starts scripts with a minimal PATH (no printf)
PATH=/proc/boot:/bin:/usr/bin:/sbin:/usr/sbin:/mnt/app/armle/bin:/mnt/app/armle/usr/bin:/mnt/app/armle/sbin:/mnt/app/armle/usr/sbin:$PATH
export PATH
case $0 in */*) D=${0%/*};; *) D=.;; esac
D=$(cd "$D" && pwd)
if test ! -d /mnt/app/eso/hmi/lsd && test -d /net/mmx/mnt/app/eso/hmi/lsd; then
    exec on -f mmx /bin/sh "$D/custom.sh" "$@"
fi
# the card may be mounted read-only (export, logs and last-run.txt write to it)
mount -uw "${D%/*}" 2>/dev/null || :
a=check
if test -f "$D/tt/action.txt"; then
    read -r a < "$D/tt/action.txt" || :
fi
a=${a%"$(printf '\r')"}
set -- $a
a=${1:-check}
echo "TT cockpit CarPlay: action '$a' (park the car, phone unplugged)"
/bin/sh "$D/tt/tt-setup.sh" "$a" > "$D/tt/last-run.txt" 2>&1
rc=$?
cat "$D/tt/last-run.txt"
exit $rc
