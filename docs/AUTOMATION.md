# Automating the Fixes (systemd)

To ensure your Strix Halo hardware remains stable without manual intervention, you should install the following automation tools.

## 1. Permanent USB4 Wakeup Fix (Service)
On the HP ZBook Ultra, the USB4 Host Routers send ghost signals during sleep that freeze the system. Disabling these at boot is the most reliable solution.

### Installation:
1. Copy the service file from the toolkit:
   ```bash
   sudo cp configs/strix-halo-usb-fix.service /etc/systemd/system/
   ```
2. Reload and enable the service:
   ```bash
   sudo systemctl daemon-reload
   sudo systemctl enable --now strix-halo-usb-fix.service
   ```
3. **Verify:** `grep . /sys/bus/pci/devices/0000:c5:00.[56]/power/wakeup` should show `disabled`.

---

## 2. Automated NPU Driver Reload (Sleep Hook)
The NPU driver (`amdxdna`) must be cycled during the sleep transition to maintain SMU synchronization.

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
This dual-layer approach (Boot Service + Sleep Hook) ensures that the USB4 triggers are locked down permanently while the NPU driver is safely managed during every power transition.
