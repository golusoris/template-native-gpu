/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  HIP dispatch_strategy. Mirrors the CUDA twin. Env override:
 *  PROJ_HIP_DISPATCH=<feature>:graph,<feature>:direct,...
 */
#ifndef PROJ_HIP_DISPATCH_STRATEGY_H_
#define PROJ_HIP_DISPATCH_STRATEGY_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    PROJ_HIP_DISPATCH_DIRECT = 0,
    PROJ_HIP_DISPATCH_GRAPH_CAPTURE,
} ProjHipDispatchStrategy;

ProjHipDispatchStrategy proj_hip_select_strategy(const char *feature_name, unsigned frame_w,
                                                 unsigned frame_h);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_HIP_DISPATCH_STRATEGY_H_ */
