<!-- markdownlint-disable MD013 -->
# Full GPU-matrix example

The **vmafx-shaped** variant of this template: a `core/` tree that wires up
multi-backend GPU compute dispatch for **CUDA, HIP, Metal, SYCL, and Vulkan**
behind one host-side dispatch layer. Use this when your project needs more than
the single-Vulkan-shader minimal seed at the repo root.

## What it demonstrates

| Backend | Device-code pipeline | Host wiring |
| --- | --- | --- |
| CUDA | `.cu` → `nvcc --fatbin` → `bin2c` → embedded `*_ptx[]` C array | `cuda/common.c` (HAVE_CUDA) / `cuda/stubs.c` (-ENOSYS) |
| HIP | `.hip` → `hipcc --genco` → `.hsaco` → `xxd -i` → embedded `*_hsaco[]` | `hip/common.c` (HAVE_HIP/HAVE_HIPCC) / `hip/stubs.c` |
| Metal | `.metal` → `xcrun metal` → `.air` → `xcrun metallib` → embedded `__TEXT,__metallib` | `metal/common.m` (HAVE_METAL, darwin only) / `metal/stubs.c` |
| SYCL | single-source `.cpp` → `icpx -fsycl` → `.o` | `sycl/common.cpp` (HAVE_SYCL) / `sycl/stubs.c` |
| Vulkan | `.comp` → `glslangValidator -V` → `.spv` | runtime-loaded SPIR-V |

Plus the **backend-agnostic** host glue that every backend shares:

- `gpu_dispatch_parse.h` — a header-only `PROJ_<BACKEND>_DISPATCH=feat:strategy`
  tokenizer, #include-able from both C and C++ TUs.
- `gpu_dispatch_env.{h,c}` — a thread-safe once-only `getenv` snapshot.
- `gpu_picture_pool.{h,c}` — a backend-agnostic round-robin GPU picture pool
  (alloc/sync/free callbacks + a cookie).

## The two load-bearing patterns

1. **`-fsycl` link propagation.** SYCL is single-source: the device kernel is a
   lambda in `queue::submit`. `-fsycl` must be present at every link step that
   pulls in a SYCL `.o`, or the runtime never registers the kernel and the first
   submit null-derefs. We propagate it once via
   `declare_dependency(link_args: ['-fsycl'])` (see `core/meson.build`).
2. **`-ENOSYS` stub TUs.** Every backend's public entry points are emitted even
   when the backend is disabled — the disabled build links a `stubs.c` whose
   bodies return `-ENOSYS`. Without this, a downstream consumer that references
   the symbols fails at link time.

## Build

Every backend is OFF/`auto` by default, so this configures and compiles on a
stock runner with no GPU SDK installed (all entry points return `-ENOSYS`):

```bash
meson setup build
meson compile -C build
meson test -C build          # backend-agnostic tests run green without a GPU
```

Enable a backend with its toolchain installed:

```bash
meson setup build -Denable_cuda=true -Denable_nvcc=true
meson setup build -Denable_hip=true -Denable_hipcc=true
meson setup build -Denable_sycl=true -Dsycl_compiler=icpx
meson setup build -Denable_sycl=true -Dsycl_compiler=acpp -Dsycl_acpp_targets=generic
# Metal auto-enables on a darwin host.
```

## How to fold this into your repo

Two options:

- **Keep it as `examples/`** (this layout) — the repo root stays the minimal
  seed; this tree is a reference you copy from.
- **Promote it to a top-level `core/`** — move `examples/full-gpu-matrix/core/`
  to `core/`, fold `core/meson_options.txt` into the root, and `subdir('core')`
  from the root `meson.build`. The `/add-gpu-backend` skill scaffolds a new
  backend either way.

All kernels here are trivial `scale` stubs — replace them with your real
compute; keep the build wiring and the dispatch pattern.
