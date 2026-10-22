# cuda/ — agent guide

CUDA backend. Pipeline: `scale_kernel.cu` -> `nvcc --fatbin` -> `bin2c` ->
`scale_kernel.c` (embedded `scale_kernel_ptx[]`), linked into library.

- Real device launches behind `#ifdef HAVE_CUDA` in `common.c`;
  no-CUDA build links `stubs.c` (every entry returns `-ENOSYS`). Keep two
  surfaces in exact signature lockstep.
- Dispatch overrides: `PROJ_CUDA_DISPATCH=<feature>:graph` (see
  `../gpu_dispatch_parse.h`). Strategy names array index MUST match enum.
- Gencode covers Turing->Ada plus `compute_80` PTX JIT floor. Extend in
  `core/meson.build` when adding newer arch.
- FP determinism: pass `--fmad=false` / `-Xcompiler=-ffp-contract=off` for any
  kernel whose result must be bit-exact with CPU/SIMD reference.
