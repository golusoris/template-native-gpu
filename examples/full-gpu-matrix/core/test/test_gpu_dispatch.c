/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *  Backend-agnostic dispatch tests. No GPU required — these exercise the env
 *  parser, the once-snapshot, and the round-robin picture pool.
 */
// NOLINTNEXTLINE(bugprone-reserved-identifier,cert-dcl37-c,cert-dcl51-cpp) /* WHY: POSIX feature test macro required for setenv before system headers */
#define _POSIX_C_SOURCE 200809L /* setenv */

#include "../src/gpu_dispatch_env.h"
#include "../src/gpu_dispatch_parse.h"
#include "../src/gpu_picture_pool.h"

#include <assert.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static const char *const names[] = {"direct", "graph", NULL};

static void test_parse(void)
{
    int idx = -1;

    /* exact match */
    assert(proj_gpu_dispatch_parse_env("vif:graph", "vif", names, &idx) == 1);
    assert(idx == 1);

    /* second token */
    idx = -1;
    assert(proj_gpu_dispatch_parse_env("adm:direct,vif:graph", "vif", names, &idx) == 1);
    assert(idx == 1);

    /* boundary check: "graphx" must NOT match "graph" */
    idx = -1;
    assert(proj_gpu_dispatch_parse_env("vif:graphx", "vif", names, &idx) == 0);

    /* unknown feature */
    assert(proj_gpu_dispatch_parse_env("vif:graph", "psnr", names, &idx) == 0);

    /* NULL inputs are safe */
    assert(proj_gpu_dispatch_parse_env(NULL, "vif", names, &idx) == 0);
}

static void test_env_snapshot(void)
{
    /* The snapshot is once-only; setenv after the first read is not observed. */
    // NOLINTNEXTLINE(concurrency-mt-unsafe) /* WHY: single-threaded unit test setup */
    setenv("PROJ_TEST_DISPATCH", "vif:graph", 1);
    const char *a = proj_gpu_dispatch_env_get("PROJ_TEST_DISPATCH");
    assert(a != NULL && strcmp(a, "vif:graph") == 0);
    // NOLINTNEXTLINE(concurrency-mt-unsafe) /* WHY: single-threaded unit test setup */
    setenv("PROJ_TEST_DISPATCH", "vif:direct", 1);
    const char *b = proj_gpu_dispatch_env_get("PROJ_TEST_DISPATCH");
    assert(b == a); /* same cached pointer; later setenv ignored by design */
}

static int alloc_cb(ProjPicture *p, void *cookie)
{
    int *counter = (int *)cookie;
    p->data[0] = malloc(16);
    (*counter)++;
    return p->data[0] ? 0 : -1;
}
static int free_cb(ProjPicture *p, void *cookie)
{
    (void)cookie;
    free(p->data[0]);
    p->data[0] = NULL;
    return 0;
}

static void test_pool(void)
{
    ProjGpuPicturePool *pool = NULL;
    ProjGpuPicturePoolConfig cfg;
    ProjPicture pic;
    int allocs = 0;
    int i;

    memset(&cfg, 0, sizeof(cfg));
    cfg.pic_cnt = 3;
    cfg.alloc_picture_callback = alloc_cb;
    cfg.free_picture_callback = free_cb;
    cfg.cookie = &allocs;

    assert(proj_gpu_picture_pool_init(&pool, cfg) == 0);
    assert(allocs == 3);

    /* round-robin: 6 fetches cycle through the 3 slots twice */
    for (i = 0; i < 6; i++) {
        assert(proj_gpu_picture_pool_fetch(pool, &pic) == 0);
        assert(pic.data[0] != NULL);
    }
    assert(proj_gpu_picture_pool_close(pool) == 0);
}

int main(void)
{
    test_parse();
    test_env_snapshot();
    test_pool();
    printf("gpu-dispatch: ok\n");
    return 0;
}
