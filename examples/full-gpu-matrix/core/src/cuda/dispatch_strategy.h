/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  CUDA dispatch_strategy — translates a per-feature request into a CUDA
 *  submission strategy. Today every path uses direct stream submission; this
 *  exposes the decision surface so graph-capture can be opted in later for
 *  high-dispatch-density features without touching call sites.
 *  Adapted from: vmaf/core/src/cuda/dispatch_strategy.h.
 */
#ifndef PROJ_CUDA_DISPATCH_STRATEGY_H_
#define PROJ_CUDA_DISPATCH_STRATEGY_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    PROJ_CUDA_DISPATCH_DIRECT = 0,    /* direct stream submission per kernel */
    PROJ_CUDA_DISPATCH_GRAPH_CAPTURE, /* capture per-frame work into a CUDA graph */
} ProjCudaDispatchStrategy;

/**
 * Returns the CUDA dispatch strategy for a feature.
 * Env override: PROJ_CUDA_DISPATCH=<feature>:graph,<feature>:direct,...
 */
ProjCudaDispatchStrategy proj_cuda_select_strategy(const char *feature_name, unsigned frame_w,
                                                   unsigned frame_h);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_CUDA_DISPATCH_STRATEGY_H_ */
