# HP ZBook Ultra G1A: BIOS Configuration (Silicon Alignment)

Verified settings for the **Ryzen AI Max+ PRO 395 (Strix Halo)** to achieve stability on Linux Kernel 6.19+.

## 1. Power Management Options
**Path**: `F10 > Advanced > Power Management Options`

| Setting | Value | Impact |
|---------|-------|--------|
| **Power Control** | **Disabled** | **CRITICAL**: Silences the `ACPI BIOS Error: [^PMF.ATST] AE_NOT_FOUND` storm. Stops the EC from calling broken power hooks. |
| **PSPP (PCIe Speed Power Policy)** | **Disabled** | **CRITICAL**: Fixes `bridge window failed to assign` errors for Thunderbolt 4 and NPU bridges. Ensures stable bus mapping. |
| **AMD Core Performance Boost** | **Enabled** | Keep enabled to allow Zen 5 cores to reach maximum frequency during AI prefill/compilation. |

## 2. Display & Boot Options
**Path**: `F10 > Advanced > Boot Options`

| Setting | Value | Impact |
|---------|-------|--------|
| **Fast Boot** | **Disabled** | Recommended to ensure reliable initialization of the NPU and Thunderbolt firmware. |

## 3. Hardware Insights (AMD PMF)
A "hidden" or "3rd Party" menu exists labeled **AMD PMF Feature**. 

**Verified Path**: `Advanced > AMD PMF Feature` (May require "3rd Party Option" or "Advanced" toggle).

| Setting | Recommendation | Impact |
|---------|----------------|--------|
| **PMF Device Support** | **Enabled** (Default) | Main toggle for AMD Platform Management. |
| **ATST / APMF Functions** | **Disabled** | Individual sub-functions were observed to be **Disabled** by default in the sub-menus. |

**Research Note**: The existence of this menu confirms the "Firmware Disconnect." The DSDT defines the `ATST` and `APTS` symbols as `External`, but because the individual functions are **Disabled** at the UEFI level, the logic is never exported to the OS. This confirms that the `AE_NOT_FOUND` error is a literal hardware-state report. Disabling "Power Control" in the main Power menu is the primary fix to stop the EC from attempting to call these dead logic paths.

## 4. Integrated GPU (VRAM)
**Path**: `Advanced > Device Options`
*   **UMA Video Memory Size**: Set to **Minimum (512MB or 2GB)**.
*   **The 7.0 Strategy**: Unlike previous generations, **Strix Halo on Kernel 7.0+** uses an advanced TTM (Translation Table Manager) that can dynamically scale the GPU/NPU into system RAM. By setting the BIOS to the minimum, you reclaim **30GB+ of RAM** for the Host OS/VMs, while still allowing the GPU to scale up to the limit defined by the `ttm.pages_limit` kernel parameter (e.g., 96GB).
