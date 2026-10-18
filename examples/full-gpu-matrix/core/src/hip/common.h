/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  HIP backend common surface. Real bodies behind HAVE_HIP; -ENOSYS fallbacks
 *  in stubs.c. The device kernel is embedded as `scale_kernel_hsaco[]` via
 *  hipcc --genco + xxd when enable_hipcc=true.
 *  Adapted from: vmaf/core/src/hip/common.h.
 */
#ifndef PROJ_HIP_COMMON_H_
#define PROJ_HIP_COMMON_H_

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ProjHipState ProjHipState;

int proj_hip_available(void);
int proj_hip_state_init(ProjHipState **out);
void proj_hip_state_free(ProjHipState **state);
int proj_hip_scale(ProjHipState *st, float *data, size_t n, float scale);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_HIP_COMMON_H_ */
