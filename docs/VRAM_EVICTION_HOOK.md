# VRAM Eviction Hook (Strix Halo Resume Hang Fix)

## 1. The Problem: "The Glow but no Show"
On the HP ZBook Ultra (Strix Halo), users often encounter a resume hang where the keyboard backlight and power indicators illuminate, but the display remains black and the system is unresponsive.

This is fundamentally a **VRAM Eviction Out-of-Memory (OOM)** error.

### Architectural Root Cause
When the system suspends, the `amdgpu` driver must copy all active VRAM data into system RAM. On Strix Halo configurations with large UMA allocations (e.g., 32GB), the driver attempts this copy during the kernel's `pm_restrict_gfp_mask()` phase.

**The Conflict:** 
1. The kernel disables swap to disk *before* the VRAM eviction starts.
2. If your 32GB eviction cannot fit into the available physical RAM (because swap is disabled), the process fails.
3. The Display Microcontroller (DMUB) fails to reinitialize, leaving the screen black.

## 2. The Solution: Manual Pre-Sleep Eviction
By manually triggering a VRAM eviction *before* the kernel enters the restricted memory phase, we ensure the 32GB is moved while swap is still available.

### Implementation
We use a `systemd` sleep hook to echo a trigger to the `amdgpu` debugfs node:
```bash
echo 1 > /sys/kernel/debug/dri/1/amdgpu_evict_vram
```

## 3. Recommended Script
The following combined hook handles both the GPU VRAM eviction and the NPU driver quiescing required for Strix Halo stability.

**Location**: `/usr/lib/systemd/system-sleep/99-npu-sleep.sh`

```bash
#!/bin/bash
case $1 in
  pre)
    # 1. Manual VRAM Eviction (Crucial for 32GB UMA BIOS)
    if [ -f /sys/kernel/debug/dri/1/amdgpu_evict_vram ]; then
        echo 1 > /sys/kernel/debug/dri/1/amdgpu_evict_vram
    fi

    # 2. NPU Quiescing
    fuser -k -9 /dev/accel/accel0 2>/dev/null
    modprobe -r amdxdna
    
    sync
    sleep 2 # Allow eviction and power state to settle
    ;;
  post)
    modprobe amdxdna
    ;;
esac
```

## 4. Citations & References
This solution is based on the following research and community findings:

*   **Primary Research**: [nyanpasu64 - How I helped fix sleep-wake hangs on Linux with AMD GPUs](https://nyanpasu64.gitlab.io/blog/amdgpu-sleep-wake-hang/)
    *   *Insight*: Identifies the VRAM eviction / memory mask conflict as the root of resume hangs.
*   **Strix Halo Stability Audit (Gnosis)**: Local testing confirmed that `amd_pmf.enable=0` and `acpi_backlight=native` are required alongside eviction to stop the ACPI storm during wake-up.
