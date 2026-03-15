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
A "hidden" or "3rd Party" menu exists labeled **AMD PMF Feature**. It contains:
*   `APTS Control Method Settings`
*   `ATST Function`

**Research Note**: The existence of this menu confirms that the `ATST` and `APTS` symbols are present in the firmware but incorrectly linked in the ACPI DSDT. Disabling "Power Control" (above) is the effective workaround to prevent the system from deadlocking on these unlinked symbols.

## 4. Integrated GPU (VRAM)
**Path**: `Advanced > Device Options`
*   **UMA Video Memory Size**: Set to **32GB** or **64GB**.
*   **Result**: Combined with the `ttm.pages_limit` kernel parameter, this enables a **96GB-128GB** unified memory pool for LLM inference.
