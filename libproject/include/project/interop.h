/**
 *
 *  Copyright 2026 The PROJECT Authors
 *  SPDX-License-Identifier: EUPL-1.2
 *
 *     Licensed under the EUPL-1.2 (the "Licence"). See LICENSE.
 *
 */

/*
 * interop.h — a versioned, self-describing per-frame side-data interop contract.
 *
 * THIS IS A TEMPLATE. The two section payloads below (SUMMARY, MAP) are
 * illustrative stubs — replace them with your project's real per-frame metadata.
 * What you KEEP is the framing: the magic, the section directory, the
 * append-only ABI rules, and the pack/parse API. That machinery is the reusable
 * part; the domain fields are not.
 *
 * In an FFmpeg filtergraph this blob can ride each AVFrame as
 * AV_FRAME_DATA_SEI_UNREGISTERED, prefixed by PROJ_SIDEDATA_UUID so it
 * round-trips the graph and never collides with codec-meaningful side data. The
 * same flat byte image is the IPC payload when the data plane crosses a process
 * boundary.
 *
 * ABI STABILITY CONTRACT (normative — every consumer depends on this; see
 * docs/api/interop-abi.md and docs/adr/0002-interop-sidedata-abi.md):
 *
 *   R1. APPEND-ONLY. New fields are added at the END of a section struct (above
 *       its "APPEND-ONLY" marker), or as a NEW section with a new bit. Never
 *       reorder, never resize an existing field, never repurpose a field.
 *   R2. NEVER REMOVE a section bit or a field. Deprecate by documentation;
 *       producers may stop populating it, but the slot stays reserved forever.
 *   R3. Every section is independently OPTIONAL, gated by section_mask. A
 *       consumer MUST ignore bits it does not understand (forward-compat) and
 *       MUST tolerate absence of bits it does understand (back-compat).
 *   R4. Offsets/sizes are explicit (ProjSectionDir) so a newer producer's
 *       larger section is parseable by an older consumer: read
 *       min(known_size, dir.size) bytes and ignore the tail.
 *   R5. The blob is a flat, pointer-free byte image (no embedded pointers),
 *       little-endian on the wire. v1 producers/consumers run on little-endian
 *       hosts (x86_64, aarch64); a byte-swap path is a future, additive change
 *       gated on PROJ_ABI_MINOR.
 *   R6. PROJ_ABI_MAJOR bumps ONLY on a breaking change (which R1/R2 forbid for
 *       additive evolution) — in practice it never bumps. PROJ_ABI_MINOR bumps
 *       when a new section bit or appended field lands.
 */
#ifndef PROJECT_INTEROP_H
#define PROJECT_INTEROP_H

#include <stddef.h>
#include <stdint.h>

#include "project/project.h"

#ifdef __cplusplus
extern "C" {
#endif

/* ---- Identity ----------------------------------------------------------- */

/* Canonical 8-byte magic at the head of every blob: ASCII "PROJ01\0\0".
 * Compare as bytes (memcmp); do NOT reinterpret as an integer. */
#define PROJ_MAGIC_STR "PROJ01\0\0"
#define PROJ_MAGIC_LEN 8

/* Semantic ABI version of the blob LAYOUT (independent of PROJ_VERSION_*). */
#define PROJ_ABI_MAJOR 1u
#define PROJ_ABI_MINOR 0u

/* The 16-byte UUID prefixing an AV_FRAME_DATA_SEI_UNREGISTERED payload (the
 * leading uuid_iso_iec_11578 mandated by the user-data-unregistered SEI
 * layout). Fixed, project-owned, version-4 random UUID — the routing key that
 * distinguishes a PROJECT blob from any other unregistered SEI on a frame.
 *
 *   TEMPLATE: regenerate this with `uuidgen` for your project and update both
 *   this comment and the byte array in interop.c.
 *   project-sidedata-v1 = 00112233-4455-4677-8899-aabbccddeeff
 */
#define PROJ_SIDEDATA_UUID_LEN 16
extern const uint8_t proj_sidedata_uuid[PROJ_SIDEDATA_UUID_LEN];

/* ---- Section catalogue (R1/R2: append-only; bits are NEVER reused) ------ */

enum proj_section {
    PROJ_SEC_SUMMARY = 1u << 0, /* (a) per-frame scalar summary (illustrative)  */
    PROJ_SEC_MAP = 1u << 1      /* (b) per-cell map summary (illustrative)      */
    /* bits 2..31 reserved — a retired bit is NEVER reused (R2). Add your own
     * real sections here as new bits; never renumber an existing one. */
};

/* fourcc of the writing stage, for diagnostics (e.g. 'PROJ'). */
#define PROJ_FOURCC(a, b, c, d)                                                                    \
    ((uint32_t)(a) | ((uint32_t)(b) << 8) | ((uint32_t)(c) << 16) | ((uint32_t)(d) << 24))

/* ---- Blob framing ------------------------------------------------------- */

/* One entry per present section; lets an older consumer locate and tail-skip a
 * newer producer's section (R4). The dir[] array immediately follows the
 * ProjSideData header; section payloads follow dir[] at their offsets. */
typedef struct ProjSectionDir {
    uint32_t section_id;   /* one enum proj_section bit                       */
    uint32_t offset;       /* byte offset from the start of the blob          */
    uint32_t size;         /* byte size of that section's struct in THIS blob */
    uint32_t struct_minor; /* producer's PROJ_ABI_MINOR for this section      */
} ProjSectionDir;

/* Blob header. Fixed layout; only ever appended to at the tail (R1). All
 * offsets are blob-relative (start of magic[0]). header_size lets a consumer
 * find dir[] regardless of future header growth. */
typedef struct ProjSideData {
    uint8_t magic[8];       /* PROJ_MAGIC_STR                                  */
    uint16_t abi_major;     /* PROJ_ABI_MAJOR                                  */
    uint16_t abi_minor;     /* producer's PROJ_ABI_MINOR                       */
    uint32_t total_size;    /* total blob bytes (header + dir[] + sections)    */
    uint32_t section_mask;  /* OR of present enum proj_section bits            */
    uint16_t section_count; /* number of ProjSectionDir entries following      */
    uint16_t header_size;   /* sizeof(ProjSideData); dir[] starts here         */
    uint64_t frame_pts;     /* echo of AVFrame.pts for desync detection        */
    uint16_t grid_cols;     /* cell grid shared by all map summaries           */
    uint16_t grid_rows;
    uint32_t producer_id; /* PROJ_FOURCC of the writer                       */
    /* ProjSectionDir dir[section_count] follows immediately. */
} ProjSideData;

/* ===================================================================== *
 *  Section payloads. Flat POD; APPEND fields only at the END of each.
 *  TEMPLATE: these two are placeholders — swap in your real sections.
 * ===================================================================== */

/* (a) A trivial per-frame scalar summary. */
typedef struct ProjSummarySection {
    float metric_a; /* whatever your producer measures, frame-level           */
    float metric_b;
    uint32_t flags; /* producer-defined bit flags                             */
    uint32_t _pad0; /* reserved, zero                                         */
    /* --- APPEND-ONLY below this line --- */
} ProjSummarySection;

/* (b) A per-cell map summary referencing a (grid_cols x grid_rows) cell array
 * via a blob-relative offset, so the map lives contiguously after the struct. */
typedef struct ProjMapSection {
    float global_value;        /* frame-level aggregate of the map                */
    uint32_t cell_data_offset; /* blob-relative; uint8 value per cell           */
    uint32_t cell_data_size;   /* grid_cols*grid_rows bytes                       */
    uint32_t _pad0;            /* reserved, zero                                  */
    /* --- APPEND-ONLY below this line --- */
} ProjMapSection;

/* ---- Layout locks (ABI is frozen byte-for-byte; see R1/R2) -------------- */
#if defined(__STDC_VERSION__) && __STDC_VERSION__ >= 201112L
_Static_assert(sizeof(ProjSectionDir) == 16, "ProjSectionDir ABI");
_Static_assert(sizeof(ProjSideData) == 40, "ProjSideData header ABI");
_Static_assert(sizeof(ProjSummarySection) == 16, "summary section ABI");
_Static_assert(sizeof(ProjMapSection) == 16, "map section ABI");
#endif

/* ---- Pack / parse API (implemented in interop.c) ------------------------ */

/* One section to be packed: its bit, a pointer to the POD struct, and the
 * struct's size as known by THIS producer (sizeof(ProjXxxSection)). */
typedef struct ProjPackSection {
    enum proj_section id;
    const void *data;
    uint32_t size;
} ProjPackSection;

/*
 * Pack a UUID-prefixed PROJECT blob. On success allocates *out_blob (caller
 * frees with proj_blob_free) and sets *out_len to (16 + total_size). The first
 * 16 bytes are proj_sidedata_uuid; the remainder is the flat ProjSideData image.
 * `nb` of 0 is valid (a header-only blob). Returns PROJ_OK or a negative
 * proj_result.
 */
proj_result proj_blob_pack(const ProjSideData *meta, const ProjPackSection *sections, int nb,
                           uint8_t **out_blob, size_t *out_len);

/* Free a buffer returned by proj_blob_pack. */
void proj_blob_free(uint8_t *blob);

/*
 * Validate a UUID-prefixed blob (uuid + magic + abi_major) and locate a
 * section. Returns a pointer into the blob (no copy) plus the number of bytes
 * the consumer may safely read: min(producer_size, consumer_known_size) (R4).
 * Returns PROJ_OK, PROJ_ERR_ABSENT, PROJ_ERR_ABI, or PROJ_ERR_TRUNCATED.
 */
proj_result proj_blob_find_section(const uint8_t *blob, size_t len, enum proj_section sec,
                                   size_t consumer_known_size, const void **out_ptr,
                                   size_t *out_size);

/* True if blob/len carries a valid PROJECT blob (uuid + magic + abi_major). */
int proj_blob_is_present(const uint8_t *blob, size_t len);

#ifdef __cplusplus
}
#endif
#endif /* PROJECT_INTEROP_H */
