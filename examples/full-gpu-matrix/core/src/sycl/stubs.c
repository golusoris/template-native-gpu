/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
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

int proj_sycl_scale(ProjSyclState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* !HAVE_SYCL */
