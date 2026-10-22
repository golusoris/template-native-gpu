/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  -ENOSYS fallbacks for the HIP surface when built without enable_hip.
 *  Adapted from: vmaf/core/src/hip/stubs.c.
 */
#ifndef HAVE_HIP

#include "common.h"

#include <errno.h>
#include <stddef.h>

int proj_hip_available(void)
{
    return 0;
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

// NOLINTNEXTLINE(readability-non-const-parameter) /* WHY: stub signature must match common.h (data modified in-place when backend enabled) */
int proj_hip_scale(ProjHipState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* !HAVE_HIP */
