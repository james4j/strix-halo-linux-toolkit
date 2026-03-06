# XDNA 2 (Ryzen AI) Architecture Notes

The NPU on the Strix Halo platform is part of AMD's **XDNA 2** architecture, capable of delivering 51 TOPS (Trillion Operations Per Second).

## High-Level Pipeline

To interact with the NPU, your software relies on the following stack:

1. **User Application** (e.g., FastFlowLM, LM Studio)
2. **XRT (Xilinx Runtime)**: The user-space library (`/opt/xilinx/xrt`) that manages memory buffers, queues up compute tasks, and loads the XCLBIN files.
3. **amdxdna**: The kernel driver that handles the hardware interrupt routing, IOMMU translation, and the SMU (System Management Unit) power states.
4. **The Hardware (accel0)**: Exposed in Linux as `/dev/accel/accel0`.

## Memory Management

Unlike dedicated GPUs with isolated VRAM, the Strix Halo NPU shares memory directly with the CPU via the memory controller. 

* The `amdxdna` driver uses the Linux `dmabuf` framework to pin memory.
* If your system limits the TTM (Translation Table Maps) pool too aggressively, the NPU will fail to initialize large model weights (like those required for LLMs).
* This is why the `ttm.pages_limit` kernel parameter is strictly required for this generation of hardware.

## Driver Recovery
If a user-space application crashes while holding a lock on the NPU memory, the `amdxdna` driver can enter a hung state. The `npu-recovery.sh` script in this toolkit uses `fuser` to break any locks on `/dev/accel/accel0` and forces a reload of the kernel module, restoring the 51 TOPS capability without rebooting.

---

## Technology Stack Comparison

It is important to distinguish between the various compute engines on the Strix Halo platform:

| Engine | Hardware | Software Stack | Use Case |
| :--- | :--- | :--- | :--- |
| **NPU** | **XDNA 2** | `amdxdna` + **XRT** | Low-power AI, FastFlowLM |
| **iGPU** | **RDNA 3.5** | `amdgpu` + **Vulkan** | Graphics, standard GGUF (llama.cpp) |
| **iGPU** | **RDNA 3.5** | `amdgpu` + **ROCm** | HPC, legacy compute (often buggy on mobile) |

**Note:** ROCm and Vulkan **cannot** access the NPU. If you are troubleshooting NPU performance, ensure you are using an XRT-compatible runner like FastFlowLM.
