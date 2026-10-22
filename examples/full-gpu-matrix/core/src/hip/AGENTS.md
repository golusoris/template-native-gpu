# hip/ — agent guide

HIP (AMD ROCm) backend (CUDA twin). Pipeline: `scale_kernel.hip` ->
`hipcc --genco` -> `scale_kernel.hsaco` -> `xxd -i` -> embedded
`scale_kernel_hsaco[]`.

- `common.c` real bodies behind `#ifdef HAVE_HIP`; embedded blob behind
  `#ifdef HAVE_HIPCC`. No-HIP build links `stubs.c` (`-ENOSYS`).
- GFX target discovery (`core/meson.build`): explicit
  `-Dhip_gfx_targets=` -> `rocm_agent_enumerator` -> multi-target fallback
  (`gfx90a,gfx1030,gfx1100`); no-GPU sandbox still emits runnable fat binary.
- Dispatch overrides: `PROJ_HIP_DISPATCH=<feature>:graph`.
- Port CUDA kernel call-graph-for-call-graph; replace `__shfl_down_sync`
  warp reductions with `atomicAdd` accumulators for bit-exactness on CDNA/RDNA.
