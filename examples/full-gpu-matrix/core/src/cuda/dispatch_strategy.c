/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  CUDA dispatch_strategy. Today returns DIRECT for every feature; the env
 *  override + decision surface are wired so graph capture can land later.
 *  Adapted from: vmaf/core/src/cuda/dispatch_strategy.c.
 */
#include "dispatch_strategy.h"

#include "../gpu_dispatch_env.h"
#include "../gpu_dispatch_parse.h"

/* index matches ProjCudaDispatchStrategy. See gpu_dispatch_parse.h. */
static const char *const k_strategy_names[] = {
    "direct", /* PROJ_CUDA_DISPATCH_DIRECT        = 0 */
    "graph",  /* PROJ_CUDA_DISPATCH_GRAPH_CAPTURE = 1 */
    NULL,
};

ProjCudaDispatchStrategy proj_cuda_select_strategy(const char *feature_name, unsigned frame_w,
                                                   unsigned frame_h)
{
    int idx = (int)PROJ_CUDA_DISPATCH_DIRECT;
    const char *env = proj_gpu_dispatch_env_get("PROJ_CUDA_DISPATCH");

    (void)frame_w;
    (void)frame_h;

    if (proj_gpu_dispatch_parse_env(env, feature_name, k_strategy_names, &idx))
        return (ProjCudaDispatchStrategy)idx;

    return PROJ_CUDA_DISPATCH_DIRECT;
}
