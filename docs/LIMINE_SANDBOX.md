# Guide: UEFI Limine Testing Sandbox (CachyOS/Linux)

This document describes how to create a safe, virtualized "sandbox" for iterating on Limine bootloader configurations without risking system stability. It uses a loopback FAT32 image physically stored on your ESP but managed as a local directory.

---

## 1. Architecture Overview
- **Storage:** A raw disk image (`limine_test.img`) residing on your actual EFI System Partition (ESP).
- **Mount Point:** The image is loopback-mounted to a local folder (e.g., `~/VMs/limine_test`) with user-level permissions.
- **Emulation:** QEMU boots this image in UEFI mode using OVMF firmware, treating the folder contents as a physical boot disk.

---

## 2. Prerequisites
Ensure you have the necessary tools installed:
```bash
sudo pacman -S qemu-full edk2-ovmf
```

---

## 3. Environment Setup

### Step 1: Create the Sandbox Image
Create a 256MB FAT32 image directly on your boot partition.
```bash
sudo dd if=/dev/zero of=/boot/limine_test.img bs=1M count=256
sudo mkfs.fat -F 32 /boot/limine_test.img
```

### Step 2: Create the Mount Point
Create the local directory and mount the image with user permissions.
```bash
mkdir -p ~/VMs/limine_test
sudo mount -o loop,uid=$(id -u),gid=$(id -g) /boot/limine_test.img ~/VMs/limine_test
```

### Step 3: Populate the Sandbox
Initialize the standard UEFI directory structure and copy your active Limine files.
```bash
mkdir -p ~/VMs/limine_test/EFI/BOOT
cp /boot/EFI/BOOT/BOOTX64.EFI ~/VMs/limine_test/EFI/BOOT/
cp /boot/limine.conf ~/VMs/limine_test/
cp /boot/cachyos.png ~/VMs/limine_test/
```

---

## 4. Automation & Persistence

### Permanent Mount (Optional)
Add the following to `/etc/fstab` to ensure the sandbox is available after reboot:
```text
/boot/limine_test.img /home/james/VMs/limine_test vfat loop,uid=1000,gid=1000,nofail 0 0
```

### The QEMU Test Script
Create `test_limine.sh` to launch the sandbox instantly.
```bash
#!/bin/bash
OVMF="/usr/share/edk2/x64/OVMF.4m.fd"
SANDBOX="/boot/limine_test.img"

qemu-system-x86_64 
    -enable-kvm 
    -cpu host 
    -m 2G 
    -bios "$OVMF" 
    -drive file="$SANDBOX",format=raw,if=virtio,snapshot=on 
    -net none 
    -vga virtio 
    -display sdl,gl=on
```
*Note: `snapshot=on` ensures that any writes performed during the test are discarded when QEMU closes.*

---

## 5. Iteration Workflow
1. **Modify:** Edit `~/VMs/limine_test/limine.conf`.
2. **Launch:** Run `bash test_limine.sh`.
3. **Verify:** Check UI, menu hierarchy, and theme colors.
4. **Deploy:** Once satisfied, copy the tested config back to the real ESP:
   ```bash
   sudo cp ~/VMs/limine_test/limine.conf /boot/limine.conf
   ```

---

## 6. Troubleshooting
- **Black Screen:** Often caused by a configuration file that is too large (recursion bugs) or invalid protocol paths. Check file size with `ls -lh`.
- **Permission Denied:** Ensure the image is mounted with the correct `uid/gid` in Step 2.
- **Mouse Trapped:** Use `Ctrl+Alt+G` to release the cursor from the QEMU window.
