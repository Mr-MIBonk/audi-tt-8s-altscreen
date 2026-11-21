#!/bin/sh
# TT MU1462 cockpit renderer supervisor v8 (window handover stage 1). Spawned by the AltScreen
# hook with the hook's process id; no flash writes.
#
# Car runs 50/51: the head unit's own CarPlay video and our renderer cannot hold a display window
# at the same time (nvdisp "Window is in use" -> the head unit's decoder times out -> the iPhone
# ends the session). v6 killed the renderer for the CarPlay tab and restarted it on the map: slow
# map return, a kill that came too late (crash at 321 s in run51), and "dmdt gs" calls that hung
# forever when the display manager stopped answering (runs 41, 49, 50, 51), after which nothing
# was managed at all.
#
# v8: the renderer (TT build, cluster_runtime -DMU1462_TT) is started once and kept running.
#  - CarPlay tab or any non-map screen: SIGUSR1, it closes its video output (frees the window).
#  - Map view: SIGUSR2, it opens the output again and takes the next full frame.
#  - Restarted only if it exits (at most 3 times in a row).
# No dmdt calls (the jar's layer lists show layer 60 in the map contexts, as with v7).
# Test switch /tmp/mu1462-manual-pause: send no pause/resume (sh tt.sh pause|resume by hand).
export LD_LIBRARY_PATH=/eso/lib:/mnt/app/root/lib-target:/mnt/app/usr/lib:/mnt/app/armle/lib:/mnt/app/armle/lib/dll:/mnt/app/armle/usr/lib
export IPL_CONFIG_DIR=/etc/eso/production
RUNTIME=/mnt/app/root/mu1438-cluster/cluster_runtime
STATUS=/tmp/mibr-alt111-gen2.status
ACTIVE=/tmp/mu1438-cluster-active
DISABLE=/tmp/mu1438-cluster-disable
MAPVIEW=/tmp/tt-map-view
MANUAL=/tmp/mu1462-manual-pause
LOG=/tmp/mu1462-supervisor.log
parent_pid=$1
case "$parent_pid" in ''|*[!0-9]*) exit 2;; esac
test "$parent_pid" -gt 1 || exit 2

child_pid=
fails=0
car_polls=0
logged=0
want=
sent=

# Bounded trace in RAM, written only when something changes.
log() {
    test "$logged" -lt 400 || return 0
    logged=$((logged + 1))
    echo "${SECONDS}s $1" >> "$LOG"
}

stop_child() {
    if test -n "$child_pid"; then
        kill -TERM "$child_pid" 2>/dev/null
        # never wait forever: give it 3 s, then SIGKILL
        n=0
        while kill -0 "$child_pid" 2>/dev/null && test "$n" -lt 15; do sleep "$NAP"; n=$((n + 1)); done
        kill -0 "$child_pid" 2>/dev/null && kill -KILL "$child_pid" 2>/dev/null
        log "runtime $child_pid stopped"
        child_pid=
    fi
}

current_screen() {
    test -r "$STATUS" || return 0
    while IFS= read -r line || test -n "$line"; do
        case $line in mode_screen=*) echo "${line#mode_screen=}"; return 0;; esac
    done < "$STATUS"
    return 0
}

# No file (tt-zoom.jar not running): count every car screen as a map view.
map_view() {
    test -r "$MAPVIEW" || return 0
    mv=
    read -r mv < "$MAPVIEW"
    test "$mv" != 0
}

trap 'stop_child' 0
trap 'exit 0' 1 2 15

# "sleep 0.2" must really sleep; otherwise poll once a second.
s0=$SECONDS
sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null; sleep 0.5 2>/dev/null
if test $((SECONDS - s0)) -ge 1; then NAP=0.2; PER_SEC=5; else NAP=1; PER_SEC=1; fi
START_SECS=1
if test -r /tmp/mu1462-start-delay; then
    read -r d < /tmp/mu1462-start-delay
    case "$d" in ''|*[!0-9]*) ;; *) START_SECS=$d;; esac
fi
START_POLLS=$((START_SECS * PER_SEC))

screen=
last_screen=x
last_drawing=x
log "supervisor v8 $$ started for parent $parent_pid (nap $NAP, first start ${START_SECS}s on the map view, pause/resume, no dmdt)"

while kill -0 "$parent_pid" 2>/dev/null && test ! -e "$DISABLE"; do
    screen=$(current_screen)
    if test "$screen" != "$last_screen"; then
        log "screen=[$screen]"
        last_screen=$screen
    fi
    # An empty read means the status file was being rewritten: keep state.
    if test "$screen" = 2; then
        car_polls=$((car_polls + 1))
        if map_view; then want=run; else want=pause; fi
    elif test -n "$screen"; then
        car_polls=0
        want=pause
    fi
    if test -n "$child_pid" && ! kill -0 "$child_pid" 2>/dev/null; then
        wait "$child_pid"
        rc=$?
        fails=$((fails + 1))
        log "runtime $child_pid exited by itself rc=$rc fails=$fails"
        child_pid=
        sent=
        # A failed decoder must not create an unbounded restart loop.
        test "$fails" -lt 3 || exit 1
    fi
    # First start (and restarts) only after the map has been up START_SECS: never while a
    # CarPlay tab is starting its video.
    if test -z "$child_pid" && test "$want" = run && test "$car_polls" -ge "$START_POLLS"; then
        "$RUNTIME" "$parent_pid" 7<&- &
        child_pid=$!
        sent=run
        log "runtime $child_pid started"
    fi
    if test -n "$child_pid" && test -n "$want" && test "$want" != "$sent" && test ! -e "$MANUAL"; then
        if test "$want" = pause; then
            kill -USR1 "$child_pid" 2>/dev/null
        else
            kill -USR2 "$child_pid" 2>/dev/null
        fi
        sent=$want
        log "$want sent to $child_pid"
    fi
    if test -e "$ACTIVE"; then drawing=1; else drawing=0; fi
    if test "$drawing" != "$last_drawing"; then
        log "drawing=$drawing runtime=[$child_pid]"
        last_drawing=$drawing
    fi
    # fails counts failures in a row only
    test "$drawing" = 1 && fails=0
    sleep "$NAP"
done
