# sycl/ — agent guide

SYCL/DPC++ backend. `common.cpp` = **single-source SYCL**; device kernel =
lambda inside `queue::submit`. Compiled per-TU by `icpx -fsycl` (or
AdaptiveCpp `acpp`) into `.o` objects folded into library via `objects:`.

LOAD-BEARING RULE: `-fsycl` MUST remain on **every link step** pulling in
SYCL `.o`. Without it SYCL runtime never registers device kernels ->
first `queue.submit()` null-derefs. Propagated via
`declare_dependency(link_args:['-fsycl'])` in `core/meson.build`; never remove,
never rely on per-target duplicate instead.

- AOT vs JIT: `-Dsycl_icpx_aot_targets=<arches>` emits native ISA + SPIR-V
  fallback; empty (default) = SPIR-V JIT only.
- No-SYCL build links `stubs.c` (compiled by host C compiler, zero icpx).
- Dispatch overrides: `PROJ_SYCL_DISPATCH=<feature>:graph`; default =
  720p-area heuristic.
- Shared `../gpu_dispatch_parse.h` = `extern "C"` and #include-able here.
