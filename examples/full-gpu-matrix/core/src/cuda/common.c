/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  CUDA backend host glue (HAVE_CUDA path). TEMPLATE: the bodies here are
 *  illustrative stubs that return -ENOSYS even when HAVE_CUDA is set, because
 *  the real cuModuleLoadFatBinary / cuLaunchKernel calls depend on a runtime
 *  this template does not vendor. Replace with real CUDA Driver API calls.
 *  The non-CUDA build uses stubs.c instead.
 */
#ifdef HAVE_CUDA

#include "common.h"

#include <errno.h>
#include <stddef.h>

/* bin2c emits this from scale_kernel.cu when enable_nvcc=true. */
extern const unsigned char scale_kernel_ptx[];

struct ProjCudaState {
    void *ctx; /* CUcontext */
    void *str; /* CUstream  */
};

int proj_cuda_available(void)
{
    return 1; /* compiled with HAVE_CUDA; a real probe would cuInit + count devices */
}

int proj_cuda_state_init(ProjCudaState **out)
{
    if (out) {
        *out = NULL;
    }
    /* TODO(template): cuInit, cuDeviceGet, cuCtxCreate, cuStreamCreate,
     * cuModuleLoadFatBinary(scale_kernel_ptx). */
    return -ENOSYS;
}

void proj_cuda_state_free(ProjCudaState **state)
{
    if (state) {
        *state = NULL;
    }
}

int proj_cuda_scale(ProjCudaState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* HAVE_CUDA */
