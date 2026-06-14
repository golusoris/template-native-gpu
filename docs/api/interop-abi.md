<!-- markdownlint-disable MD013 -->
# Interop ABI reference

The normative contract is the header: `libproject/include/project/interop.h`.
This page is the prose companion.

## Wire image

After a 16-byte UUID prefix (`proj_sidedata_uuid`), the blob is a flat,
pointer-free, little-endian image:

```text
[ProjSideData header (32 B)]
[ProjSectionDir dir[section_count] (16 B each)]
[section payloads, each 8-byte aligned]
```

All `dir[]` offsets are relative to the header start (`magic[0]`).

## Evolution rules (R1–R6)

| Rule | Meaning |
|---|---|
| R1 | **Append-only.** New fields at the end of a section, or a new section bit. |
| R2 | **Never remove** a bit or field. Deprecate by docs; the slot stays reserved. |
| R3 | Every section is optional (gated by `section_mask`). Ignore unknown bits; tolerate missing known bits. |
| R4 | A consumer reads `min(known_size, dir.size)` bytes — newer producers' tails are ignored safely. |
| R5 | Flat, pointer-free, little-endian. Payloads are 8-byte aligned. |
| R6 | `PROJ_ABI_MAJOR` bumps only on a break (R1/R2 forbid that for additive change). `PROJ_ABI_MINOR` bumps on every new bit/field. |

## API

```c
proj_result proj_blob_pack(const ProjSideData *meta, const ProjPackSection *sections,
                           int nb, uint8_t **out_blob, size_t *out_len);
void        proj_blob_free(uint8_t *blob);
proj_result proj_blob_find_section(const uint8_t *blob, size_t len, enum proj_section sec,
                                   size_t consumer_known_size, const void **out_ptr,
                                   size_t *out_size);
int         proj_blob_is_present(const uint8_t *blob, size_t len);
```

## Changing the ABI — checklist

1. Append the field (or add a new section bit) — never reorder/resize.
2. Bump `PROJ_ABI_MINOR`.
3. Update the `_Static_assert` size lock for the changed struct.
4. Extend `libproject/test/interop_test.c` to cover the new field + the R4
   forward-compat path.
5. Add a `changelog.d/changed/` fragment and (for a new section) an ADR.

The conformance test (`interop-abi` in the fast suite) is the backstop: it proves
an N+1-minor blob stays parseable by an N-minor consumer.
