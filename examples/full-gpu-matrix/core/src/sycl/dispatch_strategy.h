/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  SYCL dispatch_strategy. Env override:
 *  PROJ_SYCL_DISPATCH=<feature>:graph,<feature>:direct,...
 *  Backend default is a resolution-area heuristic (graph replay wins on large
 *  frames; direct wins on small ones).
 *  Adapted from: vmaf/core/src/sycl/dispatch_strategy.{h,cpp}.
 */
#ifndef PROJ_SYCL_DISPATCH_STRATEGY_H_
#define PROJ_SYCL_DISPATCH_STRATEGY_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    PROJ_SYCL_DISPATCH_DIRECT = 0,
    PROJ_SYCL_DISPATCH_GRAPH_REPLAY,
} ProjSyclDispatchStrategy;

ProjSyclDispatchStrategy proj_sycl_select_strategy(const char *feature_name, unsigned frame_w,
                                                   unsigned frame_h);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_SYCL_DISPATCH_STRATEGY_H_ */
