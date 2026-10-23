/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *     Licensed under the EUPL-1.2 (the "Licence"). See LICENSE.
 *
 */

/*
 * interop_test.c — conformance fixture for the append-only side-data ABI.
 *
 * Asserts the load-bearing properties of the template:
 *   1. pack -> is_present -> find_section round-trips a section.
 *   2. R4 forward-compat: a consumer that knows a SMALLER struct size reads
 *      only min(producer_size, consumer_size) bytes.
 *   3. R3 absence: an unset section bit returns PROJ_ERR_ABSENT.
 *   4. a truncated buffer is rejected, not parsed.
 */

#include "project/hello.h"
#include "project/interop.h"
#include "project/project.h"

#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

static void pack_summary(const ProjSideData *meta, const ProjSummarySection *sum, uint8_t **blob,
                         size_t *len)
{
    ProjPackSection sec;
    proj_result rc;

    sec.id = PROJ_SEC_SUMMARY;
    sec.data = sum;
    sec.size = (uint32_t)sizeof(*sum);

    rc = proj_blob_pack(meta, &sec, 1, blob, len);
    assert(rc == PROJ_OK);
    assert(*blob != NULL && *len > 0);
}

static void test_pack_find_roundtrip(void)
{
    ProjSideData meta;
    ProjSummarySection sum;
    uint8_t *blob = NULL;
    size_t len = 0;
    const void *out = NULL;
    size_t out_sz = 0;
    proj_result rc;

    memset(&meta, 0, sizeof(meta));
    meta.frame_pts = 42;
    meta.grid_cols = 4;
    meta.grid_rows = 4;
    meta.producer_id = PROJ_FOURCC('P', 'R', 'O', 'J');

    memset(&sum, 0, sizeof(sum));
    sum.metric_a = 0.5f;
    sum.metric_b = 0.25f;
    sum.flags = 1u;

    pack_summary(&meta, &sum, &blob, &len);
    assert(proj_blob_is_present(blob, len) == 1);

    rc = proj_blob_find_section(blob, len, PROJ_SEC_SUMMARY, sizeof(sum), &out, &out_sz);
    assert(rc == PROJ_OK);
    assert(out_sz == sizeof(sum));
    {
        const ProjSummarySection *got_sum = (const ProjSummarySection *)out;
        assert(got_sum->metric_a == sum.metric_a);
        assert(got_sum->metric_b == sum.metric_b);
        assert(got_sum->flags == sum.flags);
        assert(got_sum->_pad0 == sum._pad0);
    }

    /* R3: a section bit that was never packed is ABSENT. */
    rc = proj_blob_find_section(blob, len, PROJ_SEC_MAP, sizeof(ProjMapSection), &out, &out_sz);
    assert(rc == PROJ_ERR_ABSENT);

    proj_blob_free(blob);
}

static void test_r4_forward_compat(void)
{
    /* Simulate an OLDER consumer that knows a smaller struct: it must read only
     * its known size, never the producer's larger tail. */
    ProjSideData meta;
    ProjSummarySection sum;
    uint8_t *blob = NULL;
    size_t len = 0;
    const void *out = NULL;
    size_t out_sz = 0;
    const size_t older_known = sizeof(float) * 2; /* pretend v0 only had metric_a/b */
    proj_result rc;

    memset(&meta, 0, sizeof(meta));
    memset(&sum, 0, sizeof(sum));
    sum.metric_a = 1.0f;

    pack_summary(&meta, &sum, &blob, &len);

    rc = proj_blob_find_section(blob, len, PROJ_SEC_SUMMARY, older_known, &out, &out_sz);
    assert(rc == PROJ_OK);
    assert(out_sz == older_known); /* R4: clamped to the consumer's known size */

    proj_blob_free(blob);
}

static void test_truncated_rejected(void)
{
    const void *out = NULL;
    size_t out_sz = 0;
    uint8_t tiny[4] = {0};
    proj_result rc =
        proj_blob_find_section(tiny, sizeof(tiny), PROJ_SEC_SUMMARY, 16, &out, &out_sz);
    assert(rc == PROJ_ERR_ABSENT);
    assert(proj_blob_is_present(tiny, sizeof(tiny)) == 0);
}

static void test_hello_mean(void)
{
    const float xs[4] = {1.0f, 2.0f, 3.0f, 4.0f};
    float mean = 0.0f;
    assert(proj_hello_mean(xs, 4, &mean) == PROJ_OK);
    assert(mean > 2.49f && mean < 2.51f);
    assert(proj_hello_mean(NULL, 4, &mean) == PROJ_ERR_INVALID);
    assert(proj_hello_mean(xs, 0, &mean) == PROJ_ERR_RANGE);
}

int main(void)
{
    test_pack_find_roundtrip();
    test_r4_forward_compat();
    test_truncated_rejected();
    test_hello_mean();
    printf("interop-abi: ok (proj %s)\n", proj_version_string());
    return 0;
}
