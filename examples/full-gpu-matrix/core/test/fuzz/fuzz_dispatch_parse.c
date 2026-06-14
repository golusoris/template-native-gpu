/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  libFuzzer target for the dispatch env parser. The parser walks untrusted
 *  env-variable bytes, so it is a natural fuzz surface. Build via the meson
 *  `-fsanitize=fuzzer` branch (clang) or the `fuzz` CI workflow.
 */
#include "../../src/gpu_dispatch_parse.h"

#include <stddef.h>
#include <stdint.h>
#include <stdlib.h>
#include <string.h>

static const char *const names[] = {"direct", "graph", "indirect", NULL};

int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size)
{
    /* NUL-terminate a copy so the parser sees a valid C string. */
    char *buf = (char *)malloc(size + 1);
    if (!buf)
        return 0;
    memcpy(buf, data, size);
    buf[size] = '\0';

    int idx = -1;
    (void)proj_gpu_dispatch_parse_env(buf, "vif", names, &idx);
    (void)proj_gpu_dispatch_parse_env(buf, "psnr", names, &idx);

    free(buf);
    return 0;
}
