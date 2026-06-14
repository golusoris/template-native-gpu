/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  -ENOSYS fallbacks for the Metal surface when built without Metal (the auto
 *  option resolves to disabled on every non-darwin host).
 *  Adapted from: vmaf/core/src/metal/stubs.c.
 */
#ifndef HAVE_METAL

#include "common.h"

#include <errno.h>
#include <stddef.h>

int proj_metal_available(void)
{
    return 0;
}

int proj_metal_state_init(ProjMetalState **out)
{
    if (out) {
        *out = NULL;
    }
    return -ENOSYS;
}

void proj_metal_state_free(ProjMetalState **state)
{
    if (state) {
        *state = NULL;
    }
}

int proj_metal_scale(ProjMetalState *st, float *data, size_t n, float scale)
{
    (void)st;
    (void)data;
    (void)n;
    (void)scale;
    return -ENOSYS;
}

#endif /* !HAVE_METAL */
