# Compiler Optimizations (Zen 5 / Strix Halo)

To squeeze every drop of performance out of the Strix Halo APU during AUR builds and custom driver compilation, you should optimize your `/etc/makepkg.conf`. 

The following flags have been verified on the **Ryzen AI Max+ PRO 395 (16-core)**.

## 1. Optimized Flags
Edit `/etc/makepkg.conf` and update these sections:

### C/C++ Flags
Using `-march=znver5` allows the compiler to use Zen 5 specific instructions (AVX-512, VNNI) and branch prediction logic.
```bash
CFLAGS="-march=znver5 -O3 -pipe -fno-plt -fopenmp -flto=auto"
CXXFLAGS="${CFLAGS}"
```

### Rust Flags
Essential for high-performance NPU and AI tool compilation.
```bash
RUSTFLAGS="-C target-cpu=znver5 -C opt-level=3"
```

### Build Parallelism
Utilize all 16 cores (32 threads) for compilation.
```bash
MAKEFLAGS="-j$(nproc)"
```

### Linker & Compression
Improve binary load times and use all threads for package creation.
```bash
LDFLAGS="-Wl,-O1,--sort-common,--as-needed,-z,relro,-z,now"
COMPRESSZST=(zstd -c -T0 --ultra -20 -)
```

## 2. Why this matters
Strix Halo is a high-bandwidth, high-compute architecture. Standard generic x86-64 flags miss out on the specific memory controller and branch predictor improvements in Zen 5. Using `znver5` ensures that your locally compiled tools (like `llama.cpp` or `amdxdna` drivers) are running with "Elite" instruction sets.
