# Kernel Alignment (Zen 5 / Strix Halo)

These parameters are mandatory for achieving "Elite" stability on the Strix Halo platform, specifically for the **HP ZBook Ultra G1A**.

## 1. The Gnosis Master Stack (V11)

Add these to your `/etc/default/limine` or bootloader configuration:

```text
pcie_aspm=force mem_sleep_default=s2idle intremap=off amd_iommu=fullflush iommu=pt acpi_enforce_resources=lax ttm.pages_limit=25165824 ttm.page_pool_size=25165824 rootdelay=20 nowatchdog nvme_load=YES zswap.enabled=0 loglevel=7 earlyprintk=vga,keep nvme_core.default_ps_max_latency_us=0 amdgpu.dcfeaturemask=0x8 amdgpu.cwsr_enable=0 acpi.prefer_microsoft_guid=1 amdgpu.sg_display=0 acpi_backlight=native pci=realloc preempt=full amdgpu.abmlevel=0
```

## 2. Parameter Breakdown

### AI & NPU Performance
*   **`ttm.pages_limit=25165824`**: Locks a 96GB memory pool for the iGPU/NPU. (Math: 25.1M pages * 4KB = 96GB).
*   **`iommu=pt`**: Enables IOMMU Pass-Through. Essential for 51 TOPS NPU throughput.
*   **`nvme_core.default_ps_max_latency_us=0`**: Disables NVMe power savings for low-latency model weight loading.
*   **`preempt=full`**: Real-time preemption for a fluid UI during inference saturation.

### Stability & Silencing the Storm
*   **BIOS FIX (Mandatory)**: Ensure **"AMD Platform Management"** is enabled in F10. This enables the native `amd_pmf` driver, removing the need for `amd_pmf.enable=0` or manual GPE masking.
*   **`pci=realloc`**: **CRITICAL for Thunderbolt 4.** Forces the kernel to reallocate PCIe bridge windows. Fixes "can't assign; no space" errors.

### Display & Power
*   **`acpi_backlight=native`**: Hands backlight control to the `amdgpu` driver, bypassing buggy ACPI display methods.
*   **`mem_sleep_default=s2idle`**: Required for Zen 5 modern standby stability.
*   **`pcie_aspm=force`**: Enables aggressive power management for the PCIe bus to prevent battery drain.
