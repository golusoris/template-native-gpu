/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  Backend-agnostic GPU picture pool — see gpu_picture_pool.h.
 *  Adapted from: vmaf/core/src/gpu_picture_pool.{h,c}.
 */
#include "gpu_picture_pool.h"

#include <errno.h>
#include <stdlib.h>
#include <string.h>

#ifdef _WIN32
#include <windows.h>
#else
#include <pthread.h>
#endif

struct ProjGpuPicturePool {
    ProjGpuPicturePoolConfig cfg;
    ProjPicture *pics;
    unsigned next;
#ifdef _WIN32
    CRITICAL_SECTION lock;
#else
    pthread_mutex_t lock;
#endif
};

static void pool_lock(ProjGpuPicturePool *p)
{
#ifdef _WIN32
    EnterCriticalSection(&p->lock);
#else
    pthread_mutex_lock(&p->lock);
#endif
}
static void pool_unlock(ProjGpuPicturePool *p)
{
#ifdef _WIN32
    LeaveCriticalSection(&p->lock);
#else
    pthread_mutex_unlock(&p->lock);
#endif
}

int proj_gpu_picture_pool_init(ProjGpuPicturePool **out, ProjGpuPicturePoolConfig cfg)
{
    ProjGpuPicturePool *p;
    unsigned i;

    if (!out || cfg.pic_cnt == 0u || !cfg.alloc_picture_callback || !cfg.free_picture_callback) {
        return -EINVAL;
    }
    p = (ProjGpuPicturePool *)calloc(1, sizeof(*p));
    if (!p) {
        return -ENOMEM;
    }
    p->cfg = cfg;
    p->pics = (ProjPicture *)calloc(cfg.pic_cnt, sizeof(ProjPicture));
    if (!p->pics) {
        free(p);
        return -ENOMEM;
    }
#ifdef _WIN32
    InitializeCriticalSection(&p->lock);
#else
    pthread_mutex_init(&p->lock, NULL);
#endif
    for (i = 0; i < cfg.pic_cnt; i++) {
        int err = cfg.alloc_picture_callback(&p->pics[i], cfg.cookie);
        if (err < 0) {
            /* unwind already-allocated slots */
            unsigned j;
            for (j = 0; j < i; j++) {
                cfg.free_picture_callback(&p->pics[j], cfg.cookie);
            }
            free(p->pics);
            free(p);
            return err;
        }
    }
    *out = p;
    return 0;
}

int proj_gpu_picture_pool_fetch(ProjGpuPicturePool *p, ProjPicture *pic)
{
    ProjPicture *slot;

    if (!p || !pic) {
        return -EINVAL;
    }
    pool_lock(p);
    slot = &p->pics[p->next];
    p->next = (p->next + 1u) % p->cfg.pic_cnt;
    pool_unlock(p);

    if (p->cfg.synchronize_picture_callback) {
        int err = p->cfg.synchronize_picture_callback(slot, p->cfg.cookie);
        if (err < 0) {
            return err;
        }
    }
    *pic = *slot;
    return 0;
}

int proj_gpu_picture_pool_close(ProjGpuPicturePool *p)
{
    unsigned i;
    if (!p) {
        return -EINVAL;
    }
    for (i = 0; i < p->cfg.pic_cnt; i++) {
        p->cfg.free_picture_callback(&p->pics[i], p->cfg.cookie);
    }
#ifdef _WIN32
    DeleteCriticalSection(&p->lock);
#else
    pthread_mutex_destroy(&p->lock);
#endif
    free(p->pics);
    free(p);
    return 0;
}
