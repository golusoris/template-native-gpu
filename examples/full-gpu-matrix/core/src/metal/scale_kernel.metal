/*
 * Copyright 2026 The PROJECT Authors
 * SPDX-License-Identifier: EUPL-1.2
 *
 * scale_kernel.metal — trivial illustrative Metal compute kernel. `xcrun metal`
 * compiles this to a .air, then `xcrun metallib` links it into default.metallib
 * which is embedded into the binary (see core/meson.build Metal path).
 * TEMPLATE: replace with your real kernel.
 */
#include <metal_stdlib>
using namespace metal;

kernel void proj_scale_kernel(device float *data        [[buffer(0)]],
                              constant float &scale      [[buffer(1)]],
                              constant uint  &n          [[buffer(2)]],
                              uint            gid        [[thread_position_in_grid]])
{
    if (gid < n)
        data[gid] *= scale;
}
