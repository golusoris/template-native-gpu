# sycl/ — agent guide

SYCL/DPC++ backend. `common.cpp` is **single-source SYCL** — the device kernel
is the lambda inside `queue::submit`. Compiled per-TU by `icpx -fsycl` (or
AdaptiveCpp `acpp`) into `.o` objects folded into the library via `objects:`.

THE LOAD-BEARING RULE: `-fsycl` must be on **every link step** that pulls in a
SYCL `.o`. Without it the SYCL runtime never registers the device kernels and
the first `queue.submit()` null-derefs. It is propagated via
`declare_dependency(link_args:['-fsycl'])` in `core/meson.build` — never remove
that, and never rely on a per-target duplicate instead.

- AOT vs JIT: `-Dsycl_icpx_aot_targets=<arches>` emits native ISA + a SPIR-V
  fallback; empty (default) is SPIR-V JIT only.
- No-SYCL build links `stubs.c` (compiled by the host C compiler, no icpx).
- Dispatch overrides: `PROJ_SYCL_DISPATCH=<feature>:graph`; default is a
  720p-area heuristic.
- The shared `../gpu_dispatch_parse.h` is `extern "C"` and #include-able here.
