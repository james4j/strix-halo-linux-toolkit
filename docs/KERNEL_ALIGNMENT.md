# Kernel Alignment (Zen 5 / Strix Halo)

These parameters are mandatory for achieving "Elite" stability on the Strix Halo platform, specifically for the **HP ZBook Ultra G1A**.

## 1. The Gnosis Master Stack (V10)

Add these to your `/etc/default/limine` or bootloader configuration:

```text
pcie_aspm=force mem_sleep_default=s2idle intremap=off amd_iommu=fullflush iommu=pt acpi_enforce_resources=lax ttm.pages_limit=25165824 ttm.page_pool_size=25165824 rootdelay=20 nowatchdog nvme_load=YES zswap.enabled=0 loglevel=7 earlyprintk=vga,keep nvme_core.default_ps_max_latency_us=6000 amdgpu.dcfeaturemask=0x8 amdgpu.cwsr_enable=0 acpi.prefer_microsoft_guid=1 amdgpu.sg_display=0 amd_pmf.enable=0 acpi_backlight=native acpi_mask_gpe=0x10,0x03 pci=realloc
```

## 2. Parameter Breakdown

### AI & NPU Performance
*   **`ttm.pages_limit=25165824`**: Locks a 96GB memory pool for the iGPU/NPU. (Math: 25.1M pages * 4KB = 96GB).
*   **`iommu=pt`**: Enables IOMMU Pass-Through. Essential for 51 TOPS NPU throughput by reducing address translation latency.
*   **`amd_iommu=fullflush`**: Stabilizes the IOMMU under heavy tiling loads (14k+ contexts).

### Stability & Silencing the Storm
*   **`amd_pmf.enable=0`**: Disables the AMD Platform Management Framework. Prevents the kernel from trying to talk to missing BIOS symbols.
*   **`acpi_mask_gpe=0x10,0x03`**: The "Double Sniper" mask. Silences the constant `AE_NOT_FOUND` interrupt storm triggered by the HP Embedded Controller.
*   **`pci=realloc`**: **CRITICAL for Thunderbolt 4.** Forces the kernel to reallocate PCIe bridge windows that the BIOS fails to assign. Fixes "can't assign; no space" errors for Intel Goshen Ridge controllers.

### Display & Power
*   **`acpi_backlight=native`**: Hands backlight control to the `amdgpu` driver, bypassing buggy ACPI display methods.
*   **`mem_sleep_default=s2idle`**: Required for Zen 5 modern standby stability.
*   **`pcie_aspm=force`**: Enables aggressive power management for the PCIe bus to prevent battery drain.
