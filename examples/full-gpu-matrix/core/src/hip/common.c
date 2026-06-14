/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  HIP backend host glue (HAVE_HIP path). The bodies return -ENOSYS until the
 *  real hipModuleLoadData / hipModuleLaunchKernel calls replace them. When
 *  enable_hipcc=true the device blob is available as scale_kernel_hsaco[].
 */
#ifdef HAVE_HIP

#include "common.h"

#include <errno.h>
#include <stddef.h>

#ifdef HAVE_HIPCC
extern const unsigned char scale_kernel_hsaco[];
#endif

struct ProjHipState {
    void *stream;
};

int proj_hip_available(void)
{
    return 1;
}

int proj_hip_state_init(ProjHipState **out)
{
    if (out) {
        *out = NULL;
    }
    return -ENOSYS;
}

void proj_hip_state_free(ProjHipState **state)
{
    if (state) {
        *state = NULL;
    }
}

int proj_hip_scale(ProjHipState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* HAVE_HIP */
