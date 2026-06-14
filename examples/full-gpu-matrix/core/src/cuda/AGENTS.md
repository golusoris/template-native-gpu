# cuda/ — agent guide

CUDA backend. Pipeline: `scale_kernel.cu` → `nvcc --fatbin` → `bin2c` →
`scale_kernel.c` (embedded `scale_kernel_ptx[]`), linked into the library.

- Real device launches go behind `#ifdef HAVE_CUDA` in `common.c`; the
  no-CUDA build links `stubs.c` (every entry returns `-ENOSYS`). Keep the two
  surfaces in exact signature lockstep.
- Dispatch overrides: `PROJ_CUDA_DISPATCH=<feature>:graph` (see
  `../gpu_dispatch_parse.h`). Strategy names array index MUST match the enum.
- Gencode covers Turing→Ada plus a `compute_80` PTX JIT floor. Extend in
  `core/meson.build` when you add a newer arch.
- FP determinism: pass `--fmad=false` / `-Xcompiler=-ffp-contract=off` for any
  kernel whose result must be bit-exact with a CPU/SIMD reference.
