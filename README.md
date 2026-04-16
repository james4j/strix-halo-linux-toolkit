# HP ZBook Ultra G1a Survival Guide (Strix Halo Platform)

A definitive collection of kernel parameters, firmware fixes, and optimization guides for the **ZBook Ultra G1a** (AMD Ryzen AI / Strix Halo).

## 🚀 The Golden Parameters (Kernel v7.0+)

The following command line is the validated **"Dynamic Gnosis"** state for Strix Halo. It leverages the enhanced TTM memory management of Kernel 7.0 to dynamically allocate up to 96GB for the GPU/NPU while preserving host RAM.

```bash
root=UUID=<ROOT_UUID> rw rootflags=subvol=@ pcie_aspm=force mem_sleep_default=s2idle intremap=off amd_iommu=fullflush iommu=pt acpi_enforce_resources=lax ttm.pages_limit=25165824 ttm.page_pool_size=25165824 rootdelay=20 nowatchdog nvme_load=YES zswap.enabled=0 loglevel=7 earlyprintk=vga,keep nvme_core.default_ps_max_latency_us=0 amdgpu.dcfeaturemask=0x8 amdgpu.cwsr_enable=0 acpi.prefer_microsoft_guid=1 amdgpu.sg_display=0 acpi_backlight=native pci=realloc preempt=full amdgpu.abmlevel=0
```

### Key Flags Explained:
- **`ttm.pages_limit=25165824`**: (96GB) The dynamic memory ceiling for the iGPU/NPU.
- **`nvme_core.default_ps_max_latency_us=0`**: Disables NVMe power states for maximum weight streaming performance.
- **`preempt=full`**: Ensures UI responsiveness during massive NPU/GPU prefill tasks.
- **`pcie_aspm=force`**: Overrides the BIOS FADT to enable PCIe ASPM (Critical for battery life).
- **`amdgpu.dcfeaturemask=0x8`**: Disables PSR (Panel Self Refresh) to prevent sleep-hangs.
- **`pci=realloc`**: **Mandatory for Thunderbolt 4 bridge assignment.**

### 🧠 The "Dynamic Gnosis" Strategy
On systems with **128GB RAM**, set the BIOS UMA Buffer to the **Minimum (512MB/2GB)**. Kernel 7.0 and ROCm 7.2.2 will automatically scale the memory usage up to your `ttm.pages_limit` dynamically. This "unleashes" 30GB+ of RAM for the Host OS/VMs that was previously wasted by firmware-stolen "VRAM".

---

## 📁 Repository Structure
- `configs/`: Standard systemd services and kernel templates.
- `docs/`: Deep dives into ASPM, S2idle, and UKIs.
- `scripts/`: Automation for hardware fixes and recovery.

## 📦 Maintenance Checklist
- After any systemd or kernel update, verify your parameters:
  ```bash
  cat /proc/cmdline
  ```
- If using UKIs, ensure you re-run:
  ```bash
  sudo mkinitcpio -P
  ```

---
*Maintained by the ZBook Ultra Community (Strix Halo Alpha Team)*
