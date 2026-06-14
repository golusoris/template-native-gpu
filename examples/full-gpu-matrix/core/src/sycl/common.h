/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  SYCL backend common surface. Real bodies behind HAVE_SYCL (common.cpp,
 *  compiled with icpx -fsycl); -ENOSYS fallbacks in stubs.c.
 *  Adapted from: vmaf/core/src/sycl/common.h.
 */
#ifndef PROJ_SYCL_COMMON_H_
#define PROJ_SYCL_COMMON_H_

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct ProjSyclState ProjSyclState;

int proj_sycl_available(void);
int proj_sycl_state_init(ProjSyclState **out);
void proj_sycl_state_free(ProjSyclState **state);
int proj_sycl_scale(ProjSyclState *st, float *data, size_t n, float scale);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_SYCL_COMMON_H_ */
