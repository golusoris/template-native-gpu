/*
 * Copyright 2026 The PROJECT Authors
 * SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 * scale_kernel.cu — trivial illustrative CUDA kernel. nvcc compiles this to a
 * .fatbin which bin2c embeds as `scale_kernel_ptx[]` (see core/meson.build).
 * TEMPLATE: replace with your real device kernel.
 */
extern "C" __global__ void proj_scale_kernel(float *data, unsigned long n, float scale)
{
    unsigned long i = (unsigned long)blockIdx.x * blockDim.x + threadIdx.x;
    if (i < n)
        data[i] *= scale;
}
