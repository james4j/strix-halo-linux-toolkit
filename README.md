# HP ZBook Ultra Survival Guide (Strix Halo Linux)

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
*Note: `amd_iommu=fullflush` is specifically for NPU stability under heavy 14k+ tiling loads. See [docs/KERNEL_TAINTS.md](docs/KERNEL_TAINTS.md) for the memory math.*

## 3. NPU Stack Installation (XRT)

To use the NPU for Local LLMs, you need the `amdxdna` kernel driver and the XRT runtime.

**Note for Source Builders:** If you are building XRT from the official AMD source on **CachyOS**, the dependency script will fail. Apply the patch included in this repo: [docs/XRT_PATCH_GUIDE.md](docs/XRT_PATCH_GUIDE.md).

1. **Install Headers First**:
   ```bash
   sudo pacman -S linux-cachyos-headers  # Match your kernel!
   ```
2. **Install the Stack**:
   ```bash
   paru -S xrt-amdxdna psmisc  # psmisc is required for the npu-recovery script
   ```
3. **Environment Setup**: Add to your `~/.zshrc` or `~/.bashrc`:
   ```bash
   export XILINX_XRT=/opt/xilinx/xrt
   export LD_LIBRARY_PATH=$XILINX_XRT/lib:$LD_LIBRARY_PATH
   export PATH=$XILINX_XRT/bin:$PATH
   ```

## 4. Running Models (The Engine)
The Strix Halo NPU (XDNA 2) is **not** currently supported by standard `llama.cpp` or LM Studio. You must use a native XDNA 2 engine to achieve 51 TOPS.

* **Primary Engine**: [FastFlowLM](https://github.com/hpcaitech/FastFlowLM) (The current standard for native XDNA 2 inference on Linux).

## 5. Toolkit Scripts & Discovery

**⚠️ IMPORTANT:** The scripts in this toolkit contain PCI IDs (like `0000:c5:00.5`) specific to the HP ZBook Ultra. You **must** verify your own IDs before running them.

### Finding Your Hardware IDs
Run these commands to identify your specific hardware paths:

*   **For USB4 (S2idle Fix)**:
    ```bash
    lspci -D | grep "USB4 Host Router"
    ```
    Take these IDs and update the `TARGETS` array in `scripts/s2idle_fix.sh`.

*   **For the NPU**:
    ```bash
    lspci -D | grep "Processing accelerators"
    # Should return something like [0000:c4:00.1]
    ```

### Script Overview
* **`s2idle_fix.sh`**: Disables the USB4 Host Routers that cause S2idle resume hangs. Update the `TARGETS` with your IDs from above.
* **`npu-recovery.sh`**: **Trigger this with a Hotkey.** Map to a custom shortcut. It force-kills NPU-locked processes and reloads the driver.
* **`test-npu-api.sh`**: Quick verification for your inference server.
* **`test_limine.sh`**: A **Safe UI Sandbox** tool. (See [docs/LIMINE_SANDBOX.md](docs/LIMINE_SANDBOX.md)).

## 4. System Automation (Highly Recommended)
Manually running scripts before every sleep is annoying. You can automate the S2idle fix and the NPU driver reload using `systemd-sleep` hooks.

See [docs/AUTOMATION.md](docs/AUTOMATION.md) for the setup instructions.

## 5. Emergency Recovery (Btrfs/UKI)

... [Rest of recovery section]
