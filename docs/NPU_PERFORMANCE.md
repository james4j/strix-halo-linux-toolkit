# NPU Performance Observations (XDNA 2 / Strix Halo)

Real-world performance metrics for the **Ryzen AI Max+ PRO 395** (16-core) using the **FastFlowLM** engine on CachyOS.

## 1. Verified Benchmarks

| Model | Size | Task | Performance | Observation |
|-------|------|------|-------------|-------------|
| **gpt-oss-sg** | 20B | Reasoning | **19.30 tokens/s** | Sustained decoding with full AIE saturation. |
| **qwen3vl-it** | 4B | Vision | **148.70 tokens/s** | Rapid image prefill/encoding (Prefill speed). |
| **qwen3vl-it** | 4B | Vision | **17.50 tokens/s** | Reasoning/Decoding from image context. |
| **deepseek-r1**| 8B | Reasoning | **~40.00 tokens/s** | (Estimated) Interactive CoT monologues. |

## 2. Hardware Utilization (6x8 Topology)

Monitoring via `xrt-smi examine -r all` confirms:
*   **Column Saturation**: All 8 AIE columns are engaged during multi-threaded inference.
*   **Memory Efficiency**: The 96GB AI memory pool (`ttm.pages_limit`) allows loading 20B+ models without swapping, maintaining high bandwidth to the AIE.
*   **Instruction BO**: Overhead is minimal (~3.6MB), allowing the fabric to focus on weight streaming.

## 3. The "Silent Workstation" Advantage

A key architectural benefit of the Strix Halo NPU is its thermal independence:
*   **Observation**: During 20B reasoning tasks, system fans remained near-silent. 
*   **Contrast**: Standard CPU-bound tasks (like model compilation) triggered immediate fan ramps.
*   **Verdict**: Offloading to the AIE significantly reduces the thermal and acoustic footprint of the machine while maintaining high AI throughput.

## 4. Stability under Load

With the **Double GPE Sniper** mask (0x10, 0x03) and **PCI Reallocation** active, the NPU remains stable over sustained inference runs. No kernel deadlocks or driver resets were observed during 1000+ token generations.
