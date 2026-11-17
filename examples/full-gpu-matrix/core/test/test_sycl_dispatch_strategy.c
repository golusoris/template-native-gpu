/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 */
// NOLINTNEXTLINE(bugprone-reserved-identifier,cert-dcl37-c,cert-dcl51-cpp) /* WHY: POSIX feature test macro required for unsetenv before system headers */
#define _POSIX_C_SOURCE 200809L /* unsetenv */

#include "../src/sycl/dispatch_strategy.h"

#include <limits.h>
#include <stdio.h>
#include <stdlib.h>

struct dispatch_case {
    unsigned width;
    unsigned height;
    ProjSyclDispatchStrategy expected;
};

int main(void)
{
    static const struct dispatch_case cases[] = {
        {65536U, 65536U, PROJ_SYCL_DISPATCH_GRAPH_REPLAY},
        {UINT_MAX, UINT_MAX, PROJ_SYCL_DISPATCH_GRAPH_REPLAY},
        {1280U, 720U, PROJ_SYCL_DISPATCH_GRAPH_REPLAY},
        {1280U, 719U, PROJ_SYCL_DISPATCH_DIRECT},
        {1279U, 720U, PROJ_SYCL_DISPATCH_DIRECT},
        {0U, 0U, PROJ_SYCL_DISPATCH_DIRECT},
    };
    int failed = 0;

    /* The env snapshot is once-only, so the unset must precede the first selector call. */
    // NOLINTNEXTLINE(concurrency-mt-unsafe) /* WHY: single-threaded unit test setup */
    if (unsetenv("PROJ_SYCL_DISPATCH") != 0) {
        return 1;
    }

    for (size_t i = 0; i < sizeof(cases) / sizeof(cases[0]); i++) {
        ProjSyclDispatchStrategy actual =
            proj_sycl_select_strategy("vif", cases[i].width, cases[i].height);
        printf("%ux%u: expected %d, observed %d\n", cases[i].width, cases[i].height,
               cases[i].expected, actual);
        if (actual != cases[i].expected) {
            failed = 1;
        }
    }
    return failed;
}
