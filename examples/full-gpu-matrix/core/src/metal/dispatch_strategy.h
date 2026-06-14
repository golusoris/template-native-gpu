/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  Metal dispatch_strategy. Env override:
 *  PROJ_METAL_DISPATCH=<feature>:indirect,<feature>:direct,...
 */
#ifndef PROJ_METAL_DISPATCH_STRATEGY_H_
#define PROJ_METAL_DISPATCH_STRATEGY_H_

#ifdef __cplusplus
extern "C" {
#endif

typedef enum {
    PROJ_METAL_DISPATCH_DIRECT = 0,        /* one MTLComputeCommandEncoder per kernel */
    PROJ_METAL_DISPATCH_INDIRECT_COMMANDS, /* MTLIndirectCommandBuffer replay */
} ProjMetalDispatchStrategy;

ProjMetalDispatchStrategy proj_metal_select_strategy(const char *feature_name, unsigned frame_w,
                                                     unsigned frame_h);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_METAL_DISPATCH_STRATEGY_H_ */
