/*
 * Copyright 2026 The PROJECT Authors
 * SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 * scale_kernel.hip — trivial illustrative HIP kernel. `hipcc --genco` compiles
 * this to a .hsaco fat binary which `xxd -i` embeds as `scale_kernel_hsaco[]`
 * (see core/meson.build HIP path). TEMPLATE: replace with your real kernel.
 */
#include <hip/hip_runtime.h>

extern "C" __global__ void proj_scale_kernel(float *data, unsigned long n, float scale)
{
    unsigned long i = (unsigned long)blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        data[i] *= scale;
}
