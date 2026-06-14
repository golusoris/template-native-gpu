/**
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: BSD-2-Clause-Patent
 *
 *  SYCL backend host glue (HAVE_SYCL path). Compiled by icpx -fsycl.
 *
 *  This is single-source SYCL: the device kernel is the lambda inside
 *  queue::submit. THIS is exactly why -fsycl must be on every link step that
 *  pulls in this object — without it, clang-offload-wrapper never runs, the SYCL
 *  runtime's ProgramManager never registers the kernel, and the first submit()
 *  null-derefs. The -fsycl link arg is propagated via the meson
 *  declare_dependency(link_args:['-fsycl']) in core/meson.build.
 *  Adapted from: vmaf/core/src/sycl/common.cpp.
 */
#ifdef HAVE_SYCL

#include "common.h"

#include <errno.h>

#include <sycl/sycl.hpp>

struct ProjSyclState {
    sycl::queue q;
};

extern "C" int proj_sycl_available(void)
{
    try {
        sycl::device d{sycl::default_selector_v};
        (void)d;
        return 1;
    } catch (const sycl::exception &) {
        return 0;
    }
}

extern "C" int proj_sycl_state_init(ProjSyclState **out)
{
    if (!out)
        return -EINVAL;
    try {
        *out = new ProjSyclState{sycl::queue{sycl::default_selector_v}};
        return 0;
    } catch (const sycl::exception &) {
        *out = nullptr;
        return -ENODEV;
    }
}

extern "C" void proj_sycl_state_free(ProjSyclState **state)
{
    if (state && *state) {
        delete *state;
        *state = nullptr;
    }
}

extern "C" int proj_sycl_scale(ProjSyclState *st, float *data, size_t n, float scale)
{
    if (!st || !data)
        return -EINVAL;
    if (n == 0)
        return 0;
    try {
        sycl::queue &q = st->q;
        float *dev = sycl::malloc_device<float>(n, q);
        if (!dev)
            return -ENOMEM;
        q.memcpy(dev, data, n * sizeof(float)).wait();
        q.submit([&](sycl::handler &h) {
             h.parallel_for(sycl::range<1>(n), [=](sycl::id<1> i) { dev[i] *= scale; });
         }).wait();
        q.memcpy(data, dev, n * sizeof(float)).wait();
        sycl::free(dev, q);
        return 0;
    } catch (const sycl::exception &) {
        return -EIO;
    }
}

#endif /* HAVE_SYCL */
