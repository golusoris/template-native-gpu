/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  CUDA backend common surface. Real bodies live behind HAVE_CUDA; the -ENOSYS
 *  fallbacks live in stubs.c for the no-CUDA build.
 *  Adapted from: vmaf/core/src/cuda/common.h.
 */
#ifndef PROJ_CUDA_COMMON_H_
#define PROJ_CUDA_COMMON_H_

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* The xxd/bin2c-embedded device code symbol (see core/meson.build CUDA path).
 * `extern const unsigned char scale_kernel_ptx[];` is emitted by bin2c. */

typedef struct ProjCudaState ProjCudaState;

/* Probe + lifecycle. Return 0 / a ProjCudaState on success, <0 (negative errno)
 * on failure. With HAVE_CUDA unset, stubs.c returns -ENOSYS. */
int proj_cuda_available(void);
int proj_cuda_state_init(ProjCudaState **out);
void proj_cuda_state_free(ProjCudaState **state);

/* Run the embedded `scale_kernel` over a host buffer (illustrative). */
int proj_cuda_scale(ProjCudaState *st, float *data, size_t n, float scale);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_CUDA_COMMON_H_ */
