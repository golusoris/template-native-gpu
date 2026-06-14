/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  Shared tokenizer for GPU dispatch-strategy env-variable parsing.
 *
 *  Each GPU backend exposes an environment variable of the form:
 *
 *    PROJ_<BACKEND>_DISPATCH=<feature>:<strategy>[,<feature>:<strategy>…]
 *
 *  This header consolidates the token-parsing loop into a single static inline
 *  so the duplication is eliminated without a new link-time dependency.
 *
 *  Design constraints:
 *  - Pure C89-compatible (no VLAs, no C99 bool, no __typeof__).
 *  - No heap allocation, no global mutable state.
 *  - #include-able from both .c (CUDA/HIP/Metal) and .cpp (SYCL) TUs.
 *  Adapted from: vmaf/core/src/gpu_dispatch_parse.h.
 */
#ifndef PROJ_GPU_DISPATCH_PARSE_H_
#define PROJ_GPU_DISPATCH_PARSE_H_

#include <stddef.h>
#include <string.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * proj_gpu_dispatch_parse_env - scan an env-variable value for a per-feature
 * strategy override.
 *
 * @param env_value      Raw value of the backend's dispatch env var; may be NULL.
 * @param feature_name   Feature to look up; may be NULL.
 * @param strategy_names NULL-terminated array of strategy names, ordered to
 *                       match the caller's enum (index 0 -> enum 0, ...).
 * @param out_strategy_idx  Written with the matched index when found.
 * @return 1 if matched (and *out_strategy_idx written); 0 otherwise.
 *
 * Matching is case-sensitive; only the first matching token for a feature wins.
 */
static inline int proj_gpu_dispatch_parse_env(const char *env_value, const char *feature_name,
                                              const char *const *strategy_names,
                                              int *out_strategy_idx)
{
    size_t name_len;
    const char *p;

    if (!env_value || !feature_name || !strategy_names || !out_strategy_idx)
        return 0;

    name_len = strlen(feature_name);
    p = env_value;

    while (*p) {
        const char *colon;
        const char *v;
        const char *next;
        size_t tok_name_len;
        int idx;

        while (*p == ' ' || *p == '\t' || *p == ',')
            ++p;
        if (!*p)
            break;

        colon = strchr(p, ':');
        if (!colon)
            break;

        tok_name_len = (size_t)(colon - p);
        if (tok_name_len == name_len && memcmp(p, feature_name, name_len) == 0) {
            v = colon + 1;
            for (idx = 0; strategy_names[idx] != NULL; ++idx) {
                size_t slen = strlen(strategy_names[idx]);
                /* Boundary check: strncmp alone would match "directx" against
                 * "direct". Require a token terminator after the match. */
                if (strncmp(v, strategy_names[idx], slen) == 0 &&
                    (v[slen] == '\0' || v[slen] == ',' || v[slen] == '\n' || v[slen] == ' ' ||
                     v[slen] == '\t')) {
                    *out_strategy_idx = idx;
                    return 1;
                }
            }
            /* Feature matched but strategy unknown — skip token. */
        }

        next = strchr(colon, ',');
        if (!next)
            break;
        p = next + 1;
    }
    return 0;
}

#ifdef __cplusplus
}
#endif

#endif /* PROJ_GPU_DISPATCH_PARSE_H_ */
