<!-- markdownlint-disable MD013 MD041 -->
# ADR-0002: Append-only side-data interop ABI

- **Status**: Accepted
- **Date**: 2026-01-01
- **Deciders**: maintainers
- **Tags**: abi, interop

## Context

The producer (an FFmpeg filter) and the consumer (downstream tooling, possibly in
another process) must exchange per-frame metadata that survives a filtergraph and
an IPC boundary, and that evolves without breaking older consumers. A naive
struct-on-the-wire breaks the moment either side adds a field.

## Decision

We define a flat, pointer-free, little-endian byte image with a magic header, a
section directory, and **append-only** evolution rules (R1–R6 in
`libproject/include/project/interop.h`): new fields append at the end of a
section or as a new section bit; `PROJ_ABI_MINOR` bumps; `PROJ_ABI_MAJOR` never
bumps for additive change; consumers read `min(known_size, dir.size)` bytes.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Protobuf/FlatBuffers | Mature evolution story | Heavy dep, not zero-copy in C filters | Overkill for a flat per-frame blob |
| Bare struct on the wire | Trivial | Breaks on any field add; no forward-compat | Fails the evolution requirement |
| Append-only section directory | Zero-copy, forward+back compat, no dep | Hand-rolled framing | — (chosen) |

## Consequences

- Positive: an N+1-minor producer's blob stays parseable by an N-minor consumer.
- Negative: discipline required — the conformance test (`interop_test.c`) and the
  `_Static_assert` size locks are the backstop.
- Follow-ups: any ABI change bumps the minor + updates the locks + test + an ADR.

## References

- `libproject/include/project/interop.h` rules R1–R6.
