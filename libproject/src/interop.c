/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *     Licensed under the EUPL-1.2 (the "Licence"). See LICENSE.
 *
 */

/*
 * interop.c — pack/parse for the PROJECT side-data blob.
 *
 * Wire image (after the 16-byte UUID prefix):
 *   [ProjSideData header (40)] [ProjSectionDir dir[count] (16*count)]
 *   [section payloads, each 8-byte aligned]
 * All offsets in dir[] are relative to magic[0] (the header start). Section
 * payload starts are padded up to 8 bytes so a consumer can cast the returned
 * pointer to the section struct without an unaligned access (R5).
 */

#include "project/interop.h"

#include <stdlib.h>
#include <string.h>

/* TEMPLATE: regenerate with `uuidgen`. project-sidedata-v1 =
 * 00112233-4455-4677-8899-aabbccddeeff */
const uint8_t proj_sidedata_uuid[PROJ_SIDEDATA_UUID_LEN] = {
    0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x46, 0x77, 0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff};

#define PROJ_ALIGN8(x) (((x) + 7u) & ~7u)

/* Section bits that are individually valid (R3); reject anything else. */
static int section_bit_valid(uint32_t id)
{
    switch (id) {
    case PROJ_SEC_SUMMARY:
    case PROJ_SEC_MAP:
        return 1;
    default:
        return 0;
    }
}

/* Validate sections, derive the present-section mask, reject duplicates. */
static proj_result validate_pack_sections(const ProjPackSection *sections, int nb,
                                          uint32_t *out_mask)
{
    uint32_t mask = 0;
    int i;

    for (i = 0; i < nb; i++) {
        if (sections[i].data == NULL || sections[i].size == 0) {
            return PROJ_ERR_INVALID;
        }
        if (!section_bit_valid((uint32_t)sections[i].id)) {
            return PROJ_ERR_RANGE;
        }
        if (mask & (uint32_t)sections[i].id) {
            return PROJ_ERR_INVALID; /* duplicate section */
        }
        mask |= (uint32_t)sections[i].id;
    }
    *out_mask = mask;
    return PROJ_OK;
}

/* Fill the fixed framing fields of the blob header. */
static void write_pack_header(ProjSideData *hdr, const ProjSideData *meta, uint32_t total_size,
                              uint32_t section_mask, int nb)
{
    memcpy(hdr->magic, PROJ_MAGIC_STR, PROJ_MAGIC_LEN);
    hdr->abi_major = (uint16_t)PROJ_ABI_MAJOR;
    hdr->abi_minor = (uint16_t)PROJ_ABI_MINOR;
    hdr->total_size = total_size;
    hdr->section_mask = section_mask;
    hdr->section_count = (uint16_t)nb;
    hdr->header_size = (uint16_t)sizeof(ProjSideData);
    hdr->frame_pts = meta->frame_pts;
    hdr->grid_cols = meta->grid_cols;
    hdr->grid_rows = meta->grid_rows;
    hdr->producer_id = meta->producer_id;
}

static void write_pack_payloads(uint8_t *blob, uint32_t header_size,
                                const ProjPackSection *sections, int nb, uint32_t cursor)
{
    ProjSectionDir *dir = (ProjSectionDir *)(void *)(blob + PROJ_SIDEDATA_UUID_LEN + header_size);
    int i;
    for (i = 0; i < nb; i++) {
        dir[i].section_id = (uint32_t)sections[i].id;
        dir[i].offset = cursor; /* relative to magic[0] */
        dir[i].size = sections[i].size;
        dir[i].struct_minor = (uint32_t)PROJ_ABI_MINOR;
        memcpy(blob + PROJ_SIDEDATA_UUID_LEN + cursor, sections[i].data, sections[i].size);
        cursor += PROJ_ALIGN8(sections[i].size);
    }
}

proj_result proj_blob_pack(const ProjSideData *meta, const ProjPackSection *sections, int nb,
                           uint8_t **out_blob, size_t *out_len)
{
    const uint32_t header_size = (uint32_t)sizeof(ProjSideData);
    const uint32_t dir_size = (uint32_t)sizeof(ProjSectionDir);
    uint32_t section_mask = 0;
    uint32_t cursor;
    uint32_t total_size;
    size_t blob_len;
    uint8_t *blob;
    ProjSideData *hdr;
    int i;
    proj_result rc;

    if (meta == NULL || out_blob == NULL || out_len == NULL || nb < 0 ||
        (nb > 0 && sections == NULL)) {
        return PROJ_ERR_INVALID;
    }
    if (nb > 32) { /* at most one entry per possible section bit */
        return PROJ_ERR_RANGE;
    }

    rc = validate_pack_sections(sections, nb, &section_mask);
    if (rc != PROJ_OK) {
        return rc;
    }

    /* Layout: header, dir[], then 8-aligned section payloads. */
    cursor = PROJ_ALIGN8(header_size + (uint32_t)nb * dir_size);
    *out_blob = NULL;
    *out_len = 0;

    total_size = cursor;
    for (i = 0; i < nb; i++) {
        total_size += PROJ_ALIGN8(sections[i].size);
    }

    blob_len = (size_t)PROJ_SIDEDATA_UUID_LEN + (size_t)total_size;
    blob = calloc(1, blob_len); /* zero-fill so padding is deterministic */
    if (blob == NULL) {
        return PROJ_ERR_NOMEM;
    }

    /* UUID prefix. */
    memcpy(blob, proj_sidedata_uuid, PROJ_SIDEDATA_UUID_LEN);

    /* Header. */
    hdr = (ProjSideData *)(void *)(blob + PROJ_SIDEDATA_UUID_LEN);
    write_pack_header(hdr, meta, total_size, section_mask, nb);

    /* Directory + payloads. */
    write_pack_payloads(blob, header_size, sections, nb, cursor);

    *out_blob = blob;
    *out_len = blob_len;
    return PROJ_OK;
}

void proj_blob_free(uint8_t *blob)
{
    free(blob);
}

int proj_blob_is_present(const uint8_t *blob, size_t len)
{
    const ProjSideData *hdr;

    if (blob == NULL || len < (size_t)PROJ_SIDEDATA_UUID_LEN + sizeof(ProjSideData)) {
        return 0;
    }
    if (memcmp(blob, proj_sidedata_uuid, PROJ_SIDEDATA_UUID_LEN) != 0) {
        return 0;
    }
    hdr = (const ProjSideData *)(const void *)(blob + PROJ_SIDEDATA_UUID_LEN);
    if (memcmp(hdr->magic, PROJ_MAGIC_STR, PROJ_MAGIC_LEN) != 0) {
        return 0;
    }
    return hdr->abi_major == (uint16_t)PROJ_ABI_MAJOR;
}

proj_result proj_blob_find_section(const uint8_t *blob, size_t len, enum proj_section sec,
                                   size_t consumer_known_size, const void **out_ptr,
                                   size_t *out_size)
{
    const ProjSideData *hdr;
    const ProjSectionDir *dir;
    const uint8_t *image;
    size_t image_len;
    uint16_t i;

    if (out_ptr != NULL) {
        *out_ptr = NULL;
    }
    if (out_size != NULL) {
        *out_size = 0;
    }
    if (blob == NULL || out_ptr == NULL || out_size == NULL) {
        return PROJ_ERR_INVALID;
    }
    if (len < (size_t)PROJ_SIDEDATA_UUID_LEN + sizeof(ProjSideData) ||
        memcmp(blob, proj_sidedata_uuid, PROJ_SIDEDATA_UUID_LEN) != 0) {
        return PROJ_ERR_ABSENT;
    }

    image = blob + PROJ_SIDEDATA_UUID_LEN;
    image_len = len - (size_t)PROJ_SIDEDATA_UUID_LEN;
    hdr = (const ProjSideData *)(const void *)image;

    if (memcmp(hdr->magic, PROJ_MAGIC_STR, PROJ_MAGIC_LEN) != 0) {
        return PROJ_ERR_ABSENT;
    }
    if (hdr->abi_major != (uint16_t)PROJ_ABI_MAJOR) {
        return PROJ_ERR_ABI; /* consumer cannot trust the layout (R6) */
    }
    /* Framing sanity: declared size must fit, dir[] must fit. */
    if (hdr->total_size > image_len || hdr->header_size < sizeof(*hdr) ||
        (size_t)hdr->header_size + (size_t)hdr->section_count * sizeof(ProjSectionDir) >
            image_len) {
        return PROJ_ERR_TRUNCATED;
    }
    if ((hdr->section_mask & (uint32_t)sec) == 0) {
        return PROJ_ERR_ABSENT;
    }

    dir = (const ProjSectionDir *)(const void *)(image + hdr->header_size);
    for (i = 0; i < hdr->section_count; i++) {
        size_t off;
        size_t sz;

        if (dir[i].section_id != (uint32_t)sec) {
            continue;
        }
        off = dir[i].offset;
        sz = dir[i].size;
        if (off > image_len || sz > image_len - off) {
            return PROJ_ERR_TRUNCATED;
        }
        *out_ptr = image + off;
        *out_size = (sz < consumer_known_size) ? sz : consumer_known_size; /* R4 */
        return PROJ_OK;
    }
    return PROJ_ERR_ABSENT;
}
