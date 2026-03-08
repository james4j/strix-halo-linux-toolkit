# Automating the Fixes (systemd hooks)

To make these fixes "permanent" so they run automatically every time your laptop goes to sleep, you must install them as `systemd-sleep` hooks.

## 1. Automated S2idle Fix
The `s2idle_fix.sh` script is designed to run right before the system suspends. This prevents the USB4 Host Routers from triggering a wake-up hang.

### Installation:
1. Copy the script to the system sleep directory:
   ```bash
   sudo cp scripts/s2idle_fix.sh /usr/lib/systemd/system-sleep/cachyos-s2idle-fix
   ```
2. Ensure it is executable:
   ```bash
   sudo chmod +x /usr/lib/systemd/system-sleep/cachyos-s2idle-fix
   ```

## 2. Automated NPU Recovery
The XDNA 2 NPU driver (`amdxdna`) can sometimes cause kernel panics or "zombie" states if the system suspends while the driver is active or if the SMU (System Management Unit) power states aren't synchronized.

The solution is to **unload the driver before suspend** and **reload it after resume**.

### Installation:
1. Create the hook file:
   ```bash
   sudo vim /usr/lib/systemd/system-sleep/99-npu-sleep.sh
   ```
2. Paste the following logic:
   ```bash
   #!/bin/bash
   # Strix Halo NPU (XDNA 2) Suspend Workaround
   case $1 in
     pre)
       echo "Unloading amdxdna driver before suspend..."
       fuser -k -9 /dev/accel/accel0 2>/dev/null
       modprobe -r amdxdna
       ;;
     post)
       echo "Reloading amdxdna driver after resume..."
       modprobe amdxdna
       ;;
   esac
   ```
3. Make it executable:
   ```bash
   sudo chmod +x /usr/lib/systemd/system-sleep/99-npu-sleep.sh
   ```

## Why this is necessary
Without these hooks, your ZBook Ultra may appear to sleep but will actually be "hot" in your bag, or it will simply refuse to wake up, forcing a hard-reboot (power button hold). These hooks ensure the hardware is in a "clean" state before the power transition happens.
