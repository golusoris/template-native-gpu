/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  Backend-agnostic GPU picture pool.
 *
 *  The pool's SHAPE (config + alloc/sync/free callbacks + cookie + a mutex
 *  round-robin) is backend-agnostic — CUDA, SYCL, HIP, Metal, and Vulkan all
 *  vend slots from the same code. Each backend supplies:
 *    - `pic_cnt` slots
 *    - alloc_picture_callback   — populate pic->data[] (host/device)
 *    - synchronize_picture_callback (optional) — drain the slot's prior GPU work
 *    - free_picture_callback    — release the per-slot GPU resources
 *    - cookie                   — a per-backend pointer the callbacks read for
 *                                 the CUstream / SYCL queue / VkDevice / etc.
 *  Adapted from: vmaf/core/src/gpu_picture_pool.h.
 */
#ifndef PROJ_GPU_PICTURE_POOL_H_
#define PROJ_GPU_PICTURE_POOL_H_

#include <stddef.h>

#ifdef __cplusplus
extern "C" {
#endif

/* Minimal picture handle. TEMPLATE: replace data[]/stride[] with your real
 * frame descriptor (or your project's VmafPicture-equivalent). */
typedef struct ProjPicture {
    void *data[4];    /* per-plane host or device pointer */
    size_t stride[4]; /* per-plane row stride in bytes    */
    unsigned w, h;
    void *backend_priv; /* per-slot backend handle (e.g. device alloc record) */
} ProjPicture;

typedef struct ProjGpuPicturePoolConfig {
    unsigned pic_cnt;
    int (*alloc_picture_callback)(ProjPicture *pic, void *cookie);
    int (*synchronize_picture_callback)(ProjPicture *pic, void *cookie);
    int (*free_picture_callback)(ProjPicture *pic, void *cookie);
    void *cookie;
} ProjGpuPicturePoolConfig;

typedef struct ProjGpuPicturePool ProjGpuPicturePool;

int proj_gpu_picture_pool_init(ProjGpuPicturePool **pool, ProjGpuPicturePoolConfig cfg);
int proj_gpu_picture_pool_close(ProjGpuPicturePool *pool);

/* Returns the next slot in round-robin order. The synchronize callback fires
 * before the slot is vended, so callers drain prior GPU work without a separate
 * wait. */
int proj_gpu_picture_pool_fetch(ProjGpuPicturePool *pool, ProjPicture *pic);

#ifdef __cplusplus
}
#endif

#endif /* PROJ_GPU_PICTURE_POOL_H_ */
