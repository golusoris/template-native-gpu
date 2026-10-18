/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  Metal backend host glue (HAVE_METAL path). Objective-C; compiled only on a
 *  darwin host (see core/meson.build add_languages('objc')). The bodies return
 *  -ENOSYS until the real MTLDevice / MTLComputePipelineState calls land. The
 *  metallib is loaded from the embedded __TEXT,__metallib section.
 *  Adapted from: vmaf/core/src/metal/common.mm.
 */
#ifdef HAVE_METAL

#import <Foundation/Foundation.h>
#import <Metal/Metal.h>

#include "common.h"

#include <errno.h>

struct ProjMetalState {
    id<MTLDevice> dev;
    id<MTLCommandQueue> queue;
    id<MTLComputePipelineState> pso;
};

int proj_metal_available(void)
{
    id<MTLDevice> d = MTLCreateSystemDefaultDevice();
    return d != nil ? 1 : 0;
}

int proj_metal_state_init(ProjMetalState **out)
{
    if (out) {
        *out = NULL;
    }
    /* TODO(template): MTLCreateSystemDefaultDevice, load the embedded metallib
     * via the linker-defined __TEXT,__metallib section symbols, create the
     * compute pipeline for proj_scale_kernel. */
    return -ENOSYS;
}

void proj_metal_state_free(ProjMetalState **state)
{
    if (state) {
        *state = NULL;
    }
}

int proj_metal_scale(ProjMetalState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* HAVE_METAL */
