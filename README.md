# AMD Strix Halo (Ryzen AI 300) Linux Toolkit

**⚠️ CRITICAL WARNING: THIS CAN BREAK YOUR MACHINE ⚠️**
> **READ THIS BEFORE COPYING AND PASTING COMMANDS.**
>
> If the following warnings don't scare you, you either have the money to lose, the skills to deal with a bricked bootloader, or you're too dumb to know better. This repository modifies core kernel parameters, power states, and Unified Kernel Images (UKIs). 
> 
> **HP ZBOOK ULTRA / BIOS WARNING:** This toolkit was developed and tested on an **HP ZBook Power G1A Ultra (Strix Halo)**. HP BIOS implementations are notoriously "sensitive." If you botch your `limine.conf` or `cmdline`, the BIOS may drop your EFI entry entirely, leaving you staring at a "No Bootable Device" screen.
>
> **RECOVERY PRE-REQS:** Do not touch these files unless you have a CachyOS/Arch Live USB ready and know how to `chroot`.

---

## 1. The CachyOS "Every Other Day" Ritual
In CachyOS-land, kernel updates (`linux-cachyos`) arrive almost daily. Every time you run `pacman -Syu`, there is a risk that your "Taints" (kernel parameters) or your UKI paths will be desynchronized.

**The Post-Update Checklist:**
1. **Re-verify DKMS**: Ensure `amdxdna` built for the new kernel: `dkms status`.
2. **Rebuild UKIs**: Run `sudo mkinitcpio -P` to bake the new kernel and parameters into your images.
3. **Re-sync Limine**: Run `sudo ./scripts/limine-snapper-sync.sh`.
4. **Audit the Taint**: Check `/boot/limine.conf` to ensure your parameters haven't been stripped.

## 2. The Golden Kernel Parameters (The Taints)
These parameters are mandatory for Strix Halo stability. Without them, your NPU will crash, your battery will drain in 2 hours, and your system will hang on wake.

**Add these to your bootloader:**
```text
pcie_aspm=force mem_sleep_default=s2idle intremap=off amd_iommu=fullflush iommu=pt acpi_enforce_resources=lax ttm.pages_limit=25165824 ttm.page_pool_size=25165824
```
*Note: `amd_iommu=fullflush` is specifically for NPU stability under heavy 14k+ tiling loads.*

## 3. Toolkit Scripts & Hotkeys

* **`s2idle_fix.sh`**: Disables the USB4 Host Routers (`0000:c5:00.5/.6`) that cause S2idle resume hangs.
* **`npu-recovery.sh`**: **Trigger this with a Hotkey.** On the ZBook Ultra, we map this to a custom shortcut (like the **Copilot Key** or `Ctrl+Alt+N`). It force-kills NPU-locked processes and reloads the `amdxdna` driver.
* **`test-npu-api.sh`**: Quick verification for your **FastFlowLM** server.
* **`test_limine.sh`**: A **Safe UI Sandbox** tool. Launches a virtualized (QEMU) instance of your Limine menu. This allows you to test themes and layout changes without risking your real hardware. **Note:** This tests the *menu aesthetics only*; the kernel will not actually boot in the VM. (See [docs/LIMINE_SANDBOX.md](docs/LIMINE_SANDBOX.md)).

## 4. Emergency Recovery (Btrfs/UKI)

If you hosed the machine and it won't boot, use your Live USB:

1. **Mount Root with Subvolumes**:
   ```bash
   sudo mount /dev/nvme0n1p1 /mnt -o subvol=@
   sudo mount /dev/nvme0n1p1 /mnt/home -o subvol=@home
   ```
2. **Mount EFI**:
   ```bash
   sudo mount /dev/nvme0n1p2 /mnt/boot
   ```
3. **Fix the Config with Vim**:
   ```bash
   arch-chroot /mnt
   vim /boot/limine.conf
   # Ensure your cmdline matches the "Golden Parameters" above.
   ```
4. **Re-enroll (If BIOS lost the entry)**:
   ```bash
   limine enroll-config /boot/limine.conf /dev/nvme0n1
   ```
5. **Exit and Unmount (CRITICAL)**:
   ```bash
   exit # Exit the chroot
   sudo umount -R /mnt
   reboot
   ```

## 5. XRT Environment (`/opt/xilinx/xrt`)
The NPU requires the Xilinx Runtime. After installing `xrt-amdxdna`, you **must** source the environment in your `.zshrc` or `.bashrc`:
```bash
export XILINX_XRT=/opt/xilinx/xrt
export LD_LIBRARY_PATH=$XILINX_XRT/lib:$LD_LIBRARY_PATH
export PATH=$XILINX_XRT/bin:$PATH
```
*Note: This environment is required specifically for engines like **FastFlowLM**. Standard GGUF runners using Vulkan (iGPU) do not require the NPU stack.*
