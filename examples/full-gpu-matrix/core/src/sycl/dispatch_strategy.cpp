/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  SYCL dispatch_strategy. Compiled by icpx -fsycl (see core/meson.build).
 *  Demonstrates that the shared gpu_dispatch_parse.h header is #include-able
 *  from a .cpp TU as well as the .c backends.
 *  Adapted from: vmaf/core/src/sycl/dispatch_strategy.cpp.
 */
#include "dispatch_strategy.h"

#include "../gpu_dispatch_env.h"
#include "../gpu_dispatch_parse.h"

/* Empirical: graph replay wins above 720p; smaller frames pay more in graph
 * setup than they save in dispatch overhead. */
#define PROJ_SYCL_DEFAULT_AREA_THRESHOLD (1280U * 720U)

static const char *const k_strategy_names[] = {
    "direct", /* PROJ_SYCL_DISPATCH_DIRECT       = 0 */
    "graph",  /* PROJ_SYCL_DISPATCH_GRAPH_REPLAY = 1 */
    nullptr,
};

extern "C" ProjSyclDispatchStrategy proj_sycl_select_strategy(const char *feature_name,
                                                              unsigned frame_w, unsigned frame_h)
{
    int idx = static_cast<int>(PROJ_SYCL_DISPATCH_DIRECT);
    const char *env = proj_gpu_dispatch_env_get("PROJ_SYCL_DISPATCH");
    if (proj_gpu_dispatch_parse_env(env, feature_name, k_strategy_names, &idx))
        return static_cast<ProjSyclDispatchStrategy>(idx);

    const unsigned long area = static_cast<unsigned long>(frame_w) * frame_h;
    return (area >= PROJ_SYCL_DEFAULT_AREA_THRESHOLD) ? PROJ_SYCL_DISPATCH_GRAPH_REPLAY :
                                                        PROJ_SYCL_DISPATCH_DIRECT;
}
