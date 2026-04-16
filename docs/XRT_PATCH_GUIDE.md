# Patching XRT Dependencies for CachyOS/Arch Families

When building the Xilinx Runtime (XRT) from source on **CachyOS**, **Manjaro**, or **EndeavourOS**, the official dependency script (`xrtdeps.sh`) will fail. 

## The Problem: Brittle OS Detection
The official script explicitly looks for `ID=arch` in `/etc/os-release`. Because high-performance distributions like CachyOS have their own unique IDs, the script fails to recognize the system as an Arch-based family, leading to "Unknown OS flavor" errors and failed builds.

## The Fix: Family-Aware Mapping
The included patch (`scripts/xrtdeps.sh.patch`) refactors the detection logic to map common Arch and Debian derivatives to their parent families.

### How to Apply the Patch

1.  Navigate to your XRT source directory (inside the `xdna-driver` repo):
    ```bash
    cd xdna-driver/xrt/src/runtime_src/tools/scripts/
    ```
2.  Apply the patch from this toolkit:
    ```bash
    patch xrtdeps.sh < <PATH_TO_HOME>/Gemini/zbook-ultra-survival-guide/scripts/xrtdeps.sh.patch
    ```
3.  Run the dependency installer as usual:
    ```bash
    sudo ./xrtdeps.sh
    ```

## Why this is "Senior-Grade"
Instead of adding a long list of `if/elif` statements for every new distribution, this patch uses a `case` statement at the entry point to normalize the `BASE_FLAVOR`. This keeps the rest of the script's logic clean and focused on the package manager rather than the brand name of the OS.
