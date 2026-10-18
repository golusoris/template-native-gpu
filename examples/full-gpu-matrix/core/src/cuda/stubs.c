/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  -ENOSYS fallbacks for the CUDA surface when built without enable_cuda.
 *  Without this TU the symbols are not emitted at all (the real bodies in
 *  common.c sit behind `#ifdef HAVE_CUDA`), so a consumer that references them
 *  fails at link time. Meson wires this TU in only when CUDA is disabled.
 *  Adapted from: vmaf/core/src/hip/stubs.c (the -ENOSYS stub pattern).
 */
#ifndef HAVE_CUDA

#include "common.h"

#include <errno.h>
#include <stddef.h>

int proj_cuda_available(void)
{
    return 0;
}

int proj_cuda_state_init(ProjCudaState **out)
{
    if (out) {
        *out = NULL;
    }
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

#endif /* !HAVE_CUDA */
