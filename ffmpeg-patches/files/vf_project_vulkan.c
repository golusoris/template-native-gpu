/*
 * Copyright 2026 The PROJECT Authors
 *
 * This file is part of FFmpeg.
 *
 * FFmpeg is free software; you can redistribute it and/or modify it under
 * the terms of the GNU Lesser General Public License as published by the
 * Free Software Foundation; either version 2.1 of the License, or (at
 * your option) any later version.
 *
 * FFmpeg is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public
 * License for more details.
 */

/**
 * @file
 * PROJECT illustrative Vulkan compute filter (zero-copy, pre-encode).
 *
 * TEMPLATE: a trivial per-pixel scale+bias compute pass run entirely in VRAM.
 * Replace the embedded GLSL and the push-constant block with your real kernel.
 * The structure here — FFVulkanContext-first priv struct, shader build in
 * init(), per-frame dispatch in filter_frame(), and the optional libproject
 * side-data attach gated on `meta` — is the part you keep.
 *
 * Interop: when `meta=1` the filter links libproject and attaches a PROJECT
 * side-data blob (AV_FRAME_DATA_SEI_UNREGISTERED, UUID-keyed) so a downstream
 * consumer can read per-frame metadata. See <project/interop.h>.
 */

#include "libavutil/buffer.h"
#include "libavutil/frame.h"
#include "libavutil/mem.h"
#include "libavutil/opt.h"
#include "libavutil/vulkan_spirv.h"
#include "vulkan_filter.h"

#include "filters.h"
#include "video.h"

#include <string.h>

#include <project/interop.h>

typedef struct ProjectVulkanContext {
    FFVulkanContext vkctx; /* MUST be first — generic init casts priv to this */

    int initialized;
    FFVkExecPool e;
    AVVulkanDeviceQueueFamily *qf;
    FFVulkanShader shd;

    /* push constants — mirror the GLSL std430 block below, byte-for-byte */
    struct {
        int32_t width;
        int32_t height;
        float scale;
        float bias;
    } opts;

    float scale;
    float bias;
    int meta; /* 1 => attach a libproject interop blob to each output frame */
} ProjectVulkanContext;

static const char project_comp[] = {
    C(0, void main() {                                                       )
    C(1,     ivec2 pos = ivec2(gl_GlobalInvocationID.xy);                    )
    C(1,     if (pos.x >= p.width || pos.y >= p.height) return;              )
    C(1,     vec4 c = imageLoad(src_img[0], pos);                            )
    C(1,     c = clamp(c * p.scale + p.bias, 0.0, 1.0);                      )
    C(1,     imageStore(dst_img[0], pos, c);                                 )
    C(0, }                                                                   )
};

static av_cold int init_filter(AVFilterContext *ctx)
{
    ProjectVulkanContext *s = ctx->priv;
    FFVulkanContext *vkctx = &s->vkctx;
    FFVkSPIRVCompiler *spv;
    FFVulkanShader *shd = &s->shd;
    int err;

    spv = ff_vk_spirv_init();
    if (!spv)
        return AVERROR_EXTERNAL;

    s->qf = ff_vk_qf_find(vkctx, VK_QUEUE_COMPUTE_BIT, 0);
    RET(ff_vk_exec_pool_init(vkctx, s->qf, &s->e, 1, 0, 0, 0, NULL));
    RET(ff_vk_shader_init(vkctx, shd, "project", VK_SHADER_STAGE_COMPUTE_BIT,
                          NULL, 0, 16, 16, 1, 0));

    GLSLC(0, layout(push_constant, std430) uniform pushConstants {           );
    GLSLC(1,     int   width;                                                );
    GLSLC(1,     int   height;                                               );
    GLSLC(1,     float scale;                                                );
    GLSLC(1,     float bias;                                                 );
    GLSLC(0, };                                                              );
    ff_vk_shader_add_push_const(shd, 0, sizeof(s->opts), VK_SHADER_STAGE_COMPUTE_BIT);

    GLSLD(project_comp);
    RET(spv->compile_shader(vkctx, spv, shd, &spv_data, &spv_len, "main", &spv_opaque));
    RET(ff_vk_shader_link(vkctx, shd, spv_data, spv_len, "main"));
    RET(ff_vk_shader_register_exec(vkctx, &s->e, shd));

    s->initialized = 1;
    err = 0;
fail:
    if (spv)
        spv->uninit(&spv);
    return err;
}

/* Attach a libproject side-data blob announcing this filter ran. */
static int attach_interop(AVFrame *out)
{
    ProjSideData meta;
    ProjSummarySection sum;
    ProjPackSection sec;
    uint8_t *blob = NULL;
    size_t len = 0;
    AVBufferRef *buf;

    memset(&meta, 0, sizeof(meta));
    meta.frame_pts = (uint64_t)out->pts;
    meta.producer_id = PROJ_FOURCC('P', 'R', 'O', 'J');

    memset(&sum, 0, sizeof(sum));
    sum.flags = 1u;

    sec.id = PROJ_SEC_SUMMARY;
    sec.data = &sum;
    sec.size = (uint32_t)sizeof(sum);

    if (proj_blob_pack(&meta, &sec, 1, &blob, &len) != PROJ_OK)
        return AVERROR(ENOMEM);

    buf = av_buffer_create(blob, len, NULL, NULL, 0);
    if (!buf) {
        proj_blob_free(blob);
        return AVERROR(ENOMEM);
    }
    if (!av_frame_new_side_data_from_buf(out, AV_FRAME_DATA_SEI_UNREGISTERED, buf)) {
        av_buffer_unref(&buf);
        return AVERROR(ENOMEM);
    }
    return 0;
}

static int filter_frame(AVFilterLink *link, AVFrame *in)
{
    AVFilterContext *ctx = link->dst;
    ProjectVulkanContext *s = ctx->priv;
    AVFilterLink *outlink = ctx->outputs[0];
    AVFrame *out = NULL;
    int err;

    if (!s->initialized)
        RET(init_filter(ctx));

    out = ff_get_video_buffer(outlink, outlink->w, outlink->h);
    if (!out) {
        err = AVERROR(ENOMEM);
        goto fail;
    }

    s->opts.width = in->width;
    s->opts.height = in->height;
    s->opts.scale = s->scale;
    s->opts.bias = s->bias;

    RET(ff_vk_filter_process_simple(&s->vkctx, &s->e, &s->shd, out, in,
                                    VK_NULL_HANDLE, &s->opts, sizeof(s->opts)));
    RET(av_frame_copy_props(out, in));

    if (s->meta)
        RET(attach_interop(out));

    av_frame_free(&in);
    return ff_filter_frame(outlink, out);
fail:
    av_frame_free(&in);
    av_frame_free(&out);
    return err;
}

static void uninit(AVFilterContext *ctx)
{
    ProjectVulkanContext *s = ctx->priv;
    ff_vk_exec_pool_free(&s->vkctx, &s->e);
    ff_vk_shader_free(&s->vkctx, &s->shd);
    ff_vk_uninit(&s->vkctx);
    s->initialized = 0;
}

#define OFFSET(x) offsetof(ProjectVulkanContext, x)
#define FLAGS (AV_OPT_FLAG_FILTERING_PARAM | AV_OPT_FLAG_VIDEO_PARAM)
static const AVOption project_vulkan_options[] = {
    { "scale", "per-pixel multiply",       OFFSET(scale), AV_OPT_TYPE_FLOAT, {.dbl = 1.0}, 0.0, 4.0, FLAGS },
    { "bias",  "per-pixel add (0..1)",     OFFSET(bias),  AV_OPT_TYPE_FLOAT, {.dbl = 0.0}, 0.0, 1.0, FLAGS },
    { "meta",  "attach libproject blob",   OFFSET(meta),  AV_OPT_TYPE_BOOL,  {.i64 = 0},   0,   1,   FLAGS },
    { NULL }
};

AVFILTER_DEFINE_CLASS(project_vulkan);

static const AVFilterPad project_vulkan_inputs[] = {
    { .name = "default", .type = AVMEDIA_TYPE_VIDEO, .filter_frame = filter_frame,
      .config_props = &ff_vk_filter_config_input },
};

static const AVFilterPad project_vulkan_outputs[] = {
    { .name = "default", .type = AVMEDIA_TYPE_VIDEO, .config_props = &ff_vk_filter_config_output },
};

const FFFilter ff_vf_project_vulkan = {
    .p.name        = "project_vulkan",
    .p.description  = NULL_IF_CONFIG_SMALL("PROJECT illustrative Vulkan compute pass."),
    .p.priv_class  = &project_vulkan_class,
    .p.flags       = AVFILTER_FLAG_HWDEVICE,
    .priv_size     = sizeof(ProjectVulkanContext),
    .init          = &ff_vk_filter_init,
    .uninit        = &uninit,
    FILTER_INPUTS(project_vulkan_inputs),
    FILTER_OUTPUTS(project_vulkan_outputs),
    FILTER_SINGLE_PIXFMT(AV_PIX_FMT_VULKAN),
    .flags_internal = FF_FILTER_FLAG_HWFRAME_AWARE,
};
