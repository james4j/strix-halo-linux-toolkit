#!/bin/bash
# Temporary script to disable noisy wakeup triggers for S2idle testing
# Disables XHC (USB) and NHI (Thunderbolt) wakeups

echo "Disabling noisy wakeup triggers..."
for dev in /sys/bus/pci/devices/0000:c*/power/wakeup; do
    if grep -q "enabled" "$dev"; then
        echo "Disabling $dev"
        echo "disabled" | sudo tee "$dev" > /dev/null
    fi
done

echo "Current wakeup status:"
grep . /sys/bus/pci/devices/0000:c*/power/wakeup
