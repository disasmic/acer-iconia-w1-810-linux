# Shared helper for the LightDM hooks (sourced, not executed).

# Kill the process groups matching pattern $1 that belong to the current $DISPLAY.
# Each helper is started with setsid, so killing its group also stops its children
# (monitor-sensor, onboard) without touching other displays.
kill_on_display() {
    for p in $(pgrep -f "$1"); do
        tr '\0' '\n' 2>/dev/null < "/proc/$p/environ" | grep -qx "DISPLAY=$DISPLAY" || continue
        kill -- "-$(ps -o pgid= -p "$p" | tr -d ' ')" 2>/dev/null
    done
}
