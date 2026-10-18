/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  Metal backend common surface. Real bodies behind HAVE_METAL (common.m, an
 *  Objective-C TU); -ENOSYS fallbacks in stubs.c. The compiled metallib is
 *  embedded in the binary's __TEXT,__metallib section (see core/meson.build).
 *  Adapted from: vmaf/core/src/metal/common.h.
 */
#ifndef PROJ_METAL_COMMON_H_
#define PROJ_METAL_COMMON_H_

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ProjMetalState ProjMetalState;

int proj_metal_available(void);
int proj_metal_state_init(ProjMetalState **out);
void proj_metal_state_free(ProjMetalState **state);
int proj_metal_scale(ProjMetalState *st, float *data, size_t n, float scale);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_METAL_COMMON_H_ */
