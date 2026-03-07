#!/bin/bash
# Limine Configuration Tester
# This script launches QEMU using the loopback sandbox on the ESP.

OVMF="/usr/share/edk2/x64/OVMF.4m.fd"
SANDBOX="/boot/limine_test.img"

if [ ! -f "$SANDBOX" ]; then
    echo "Error: Sandbox image not found at $SANDBOX"
    exit 1
fi

echo "Starting Limine Test Environment..."
echo "Press Ctrl+Alt+G to release mouse, or Close the window to exit."

qemu-system-x86_64 -enable-kvm -cpu host -m 2G -bios "$OVMF" -drive file="$SANDBOX",format=raw,if=virtio,snapshot=on -net none -vga virtio -display sdl,gl=on
