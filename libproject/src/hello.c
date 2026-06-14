/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *     Licensed under the BSD+Patent License (the "License").
 *     See LICENSE / https://opensource.org/licenses/BSDplusPatent.
 *
 */

/* hello.c — the trivial illustrative core. Replace with your real algorithm. */

#include "project/hello.h"

proj_result proj_hello_mean(const float *samples, size_t n, float *out_mean)
{
    /* Outer accumulator is double on purpose: a float accumulator would make
     * the result order-dependent between a scalar and a SIMD/GPU reduction.
     * This mirrors the .semgrep.yml `no-double-precision-loss-in-reduction`
     * rule the template ships. */
    double acc = 0.0;
    size_t i;

    if (samples == NULL || out_mean == NULL) {
        return PROJ_ERR_INVALID;
    }
    if (n == 0u) {
        return PROJ_ERR_RANGE;
    }

    for (i = 0; i < n; i++) {
        acc += (double)samples[i];
    }

    *out_mean = (float)(acc / (double)n);
    return PROJ_OK;
}
