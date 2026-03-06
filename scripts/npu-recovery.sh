#!/bin/bash
# NPU Emergency Recovery Script (Hotkey Target)
# Designed to be triggered via KDE Plasma custom shortcut (e.g., Copilot Key)

# Send initial notification
notify-send -t 3000 -u critical "NPU Recovery" "Initiating hardware reset of Ryzen AI (XDNA 2)..."

# Terminate any user processes holding the NPU
fuser -k -9 /dev/accel/accel0 2>/dev/null

# Unload the driver (requires sudo/pkexec)
if pkexec modprobe -r amdxdna; then
    sleep 1
    # Reload the driver
    if pkexec modprobe amdxdna; then
        notify-send -t 3000 -u normal "NPU Recovery" "Success! NPU driver reloaded. (51 TOPS Active)"
        exit 0
    else
        notify-send -t 5000 -u critical "NPU Recovery" "Failed to reload amdxdna driver. SMU may be locked."
        exit 1
    fi
else
    notify-send -t 5000 -u critical "NPU Recovery" "Failed to unload amdxdna. Reboot may be required."
    exit 1
fi
