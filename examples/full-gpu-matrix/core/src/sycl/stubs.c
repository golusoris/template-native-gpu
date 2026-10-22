/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  -ENOSYS fallbacks for the SYCL surface when built without enable_sycl.
 *  Compiled by the host C compiler (no icpx needed for the disabled build).
 */
#ifndef HAVE_SYCL

#include "common.h"

#include <errno.h>
#include <stddef.h>

int proj_sycl_available(void)
{
    return 0;
}

int proj_sycl_state_init(ProjSyclState **out)
{
    if (out) {
        *out = NULL;
    }
    return -ENOSYS;
}

void proj_sycl_state_free(ProjSyclState **state)
{
    if (state) {
        *state = NULL;
    }
}

// NOLINTNEXTLINE(readability-non-const-parameter) /* WHY: stub signature must match common.h (data modified in-place when backend enabled) */
int proj_sycl_scale(ProjSyclState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* !HAVE_SYCL */
