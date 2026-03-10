#!/bin/bash
# scripts/s2idle_fix.sh
# Purpose: Surgically disable USB4 Host Router wakeup triggers to fix S2idle resume hangs.
# 
# Targeted Devices:
# - 0000:c5:00.5 (USB4 Host Router 0)
# - 0000:c5:00.6 (USB4 Host Router 1)
# 
# Standard XHCI (USB 3.1) controllers and the fingerprint reader are left ENABLED.

TARGETS=("0000:c5:00.5" "0000:c5:00.6")

disable_targets() {
    echo "Surgically disabling USB4 wakeup triggers..."
    for id in "${TARGETS[@]}"; do
        dev="/sys/bus/pci/devices/$id/power/wakeup"
        if [ -e "$dev" ]; then
            echo "disabled" | sudo tee "$dev" > /dev/null
            echo "Target $id: DISABLED"
        fi
    done
}

case "$1" in
    pre|--disable)
        disable_targets
        ;;
    post|--status)
        echo "Wakeup Status for Targets:"
        for id in "${TARGETS[@]}"; do
            grep . "/sys/bus/pci/devices/$id/power/wakeup" 2>/dev/null | sed "s/^/$id: /"
        done
        ;;
    *)
        echo "Usage: $0 [pre|post|--disable|--status]"
        exit 1
        ;;
esac
