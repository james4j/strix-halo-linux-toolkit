# Strix Halo Kernel Parameter Reference

This document provides a technical breakdown of the kernel parameters ("Taints") required for stable operation and maximum NPU performance on the AMD Strix Halo (Ryzen AI 300) platform.

## Power & Suspend Management

**`pcie_aspm=force`**
* **Technical Impact:** Overrides BIOS and kernel defaults to force Active State Power Management (ASPM) on all PCIe devices.
* **Rationale:** On Strix Halo hardware, standard ASPM settings often fail to initialize properly, leading to high idle power consumption (15W-20W). Forcing this state is required to achieve acceptable battery life on Linux.

**`mem_sleep_default=s2idle`**
* **Technical Impact:** Sets the default suspend state to "Suspend-to-Idle."
* **Rationale:** Modern AMD platforms use "Modern Standby" (S0ix). The older S3 (Suspend-to-RAM) state is typically unsupported or buggy in the HP ZBook/EliteBook BIOS. Using `s2idle` is mandatory to prevent resume hangs and "hot-bag" issues.

## IOMMU & Hardware Stability

**`amd_iommu=fullflush`**
* **Technical Impact:** Configures the AMD IOMMU driver to perform a full TLB flush on every unmap operation.
* **Rationale:** Essential for NPU stability. The XDNA 2 architecture performs massive, high-speed memory transactions. Standard lazy flushing can result in memory desynchronization under heavy NPU tiling loads (14k+ width), leading to driver panics or SMU lockups.

**`iommu=pt`**
* **Technical Impact:** Sets the IOMMU to "Pass-Through" mode.
* **Rationale:** Prevents the IOMMU from translating every DMA request for devices that have their own memory management units (like the GPU and NPU), reducing latency and overhead.

**`intremap=off`**
* **Technical Impact:** Disables Interrupt Remapping.
* **Rationale:** Used as a workaround for hardware-specific interrupt routing conflicts found on early Strix Halo motherboard revisions.

## Memory Allocation (TTM) Tuning

**`ttm.pages_limit=[PAGE_COUNT]` and `ttm.page_pool_size=[PAGE_COUNT]`**

* **The Problem:** The Linux kernel strictly limits how much system RAM a device (like the NPU) can claim. If you attempt to load large LLM weights (10GB-30GB) into the NPU without increasing these limits, the allocation will fail, resulting in an immediate Out-Of-Memory (OOM) crash.
* **Hardware Limit:** On Strix Halo, some documentation suggests a **96GB ceiling** for combined memory processes (GPU + NPU). 

### Calculating Your Page Count
Do not simply copy the numbers below. You must calculate the page count based on your total physical RAM. 

**Formula:** `(Target_GB * 1024 * 1024 * 1024) / 4096 = Page Count`

*   **For 128GB RAM (System Max):** Use `25165824` (~96GB Limit).
*   **For 64GB RAM:** Use `12582912` (~48GB Limit).
*   **For 32GB RAM:** Use `6291456` (~24GB Limit).

*Note: Setting this higher than your physical RAM or too close to your total capacity can cause system-wide instability or lockups.*

## ACPI & BIOS Compatibility

**`acpi_enforce_resources=lax`**
* **Technical Impact:** Relaxes kernel enforcement of ACPI resource conflicts.
* **Rationale:** Required for HP BIOS implementations that incorrectly report hardware registers as occupied. This allows the `amdxdna` and `amdgpu` drivers to initialize hardware that the BIOS might otherwise "gate."

**`acpi.prefer_microsoft_guid=1`**
* **Technical Impact:** Instructs the kernel to use Microsoft's ACPI power management GUIDs.
* **Rationale:** HP firmware is primarily validated against the Windows power management stack. Forcing these GUIDs aligns the Linux kernel with the BIOS's expected power state transitions, significantly improving sleep/wake reliability.
