/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  Metal dispatch_strategy (pure C — the real Metal API dispatch is in
 *  common.m). Mirrors cuda/dispatch_strategy.c.
 *  Adapted from: vmaf/core/src/metal/dispatch_strategy.c.
 */
#include "dispatch_strategy.h"

#include "../gpu_dispatch_env.h"
#include "../gpu_dispatch_parse.h"

static const char *const k_strategy_names[] = {
    "direct",   /* PROJ_METAL_DISPATCH_DIRECT            = 0 */
    "indirect", /* PROJ_METAL_DISPATCH_INDIRECT_COMMANDS = 1 */
    NULL,
};

ProjMetalDispatchStrategy proj_metal_select_strategy(const char *feature_name, unsigned frame_w,
                                                     unsigned frame_h)
{
    int idx = (int)PROJ_METAL_DISPATCH_DIRECT;
    const char *env = proj_gpu_dispatch_env_get("PROJ_METAL_DISPATCH");

    (void)frame_w;
    (void)frame_h;

    if (proj_gpu_dispatch_parse_env(env, feature_name, k_strategy_names, &idx))
        return (ProjMetalDispatchStrategy)idx;

    return PROJ_METAL_DISPATCH_DIRECT;
}
