/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *     Licensed under the BSD+Patent License (the "License").
 *     See LICENSE / https://opensource.org/licenses/BSDplusPatent.
 *
 */

/*
 * hello.h — a trivial illustrative core entry point.
 *
 * TEMPLATE: this is the "hello-world C function" the skeleton ships so the
 * library has at least one piece of real compute. Replace it with your actual
 * core algorithm. The companion compute shader is libproject/shaders/project.comp.
 */
#ifndef PROJECT_HELLO_H
#define PROJECT_HELLO_H

#include <stddef.h>

#include "project/project.h"

#ifdef __cplusplus
extern "C" {
#endif

/*
 * Compute the arithmetic mean of `n` samples (the trivial "compute" the
 * skeleton ships). Returns PROJ_OK and writes *out_mean on success;
 * PROJ_ERR_INVALID on a NULL pointer; PROJ_ERR_RANGE if n == 0.
 */
proj_result proj_hello_mean(const float *samples, size_t n, float *out_mean);

#ifdef __cplusplus
}
#endif
#endif /* PROJECT_HELLO_H */
