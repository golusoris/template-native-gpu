/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  HIP dispatch_strategy. Mirrors cuda/dispatch_strategy.c.
 */
#include "dispatch_strategy.h"

#include "../gpu_dispatch_env.h"
#include "../gpu_dispatch_parse.h"

static const char *const k_strategy_names[] = {
    "direct", /* PROJ_HIP_DISPATCH_DIRECT        = 0 */
    "graph",  /* PROJ_HIP_DISPATCH_GRAPH_CAPTURE = 1 */
    NULL,
};

ProjHipDispatchStrategy proj_hip_select_strategy(const char *feature_name, unsigned frame_w,
                                                 unsigned frame_h)
{
    int idx = (int)PROJ_HIP_DISPATCH_DIRECT;
    const char *env = proj_gpu_dispatch_env_get("PROJ_HIP_DISPATCH");

    (void)frame_w;
    (void)frame_h;

    if (proj_gpu_dispatch_parse_env(env, feature_name, k_strategy_names, &idx))
        return (ProjHipDispatchStrategy)idx;

    return PROJ_HIP_DISPATCH_DIRECT;
}
