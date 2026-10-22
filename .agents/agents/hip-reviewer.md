---
name: hip-reviewer
description: "Reviews HIP backend changes. Use before merging examples/*/core/src/hip/ or the HIP meson custom_targets."
model: pro
mainAgent: true
subagent: true
commandExecutionPolicy: auto
tools:
  - read
  - search
  - shell
---

<!-- markdownlint-disable MD013 MD041 -->

Review HIP backend (CUDA twin). Review only changed files.

- **Stub lockstep.** `proj_hip_*` in `common.c` (HAVE_HIP) matches `stubs.c`
  (-ENOSYS). Embedded blob behind `HAVE_HIPCC`.
- **HSACO wiring.** New `.hip` kernels in `hip_kernels` in `core/meson.build`;
  `hipcc --genco` + `xxd -i` produce `<name>_hsaco`, matching consumer
  `extern const unsigned char`.
- **GFX targets.** Discovery chain (explicit option -> rocm_agent_enumerator ->
  multi-target fallback) yields runnable fat binary in no-GPU sandbox.
- **CUDA parity.** Porting CUDA kernel: replace `__shfl_down_sync` warp
  reductions with `atomicAdd` accumulators for bit-exactness on CDNA/RDNA; pass
  `-ffp-contract=off` where CUDA twin passes `--fmad=false`.
