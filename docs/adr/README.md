# Architecture Decision Records

One ADR per decision, in [Nygard format](https://cognitect.com/blog/2011/11/15/documenting-architecture-decisions).
Start from [0000-template.md](0000-template.md).

## Workflow

1. `N=$(scripts/adr/next-free.sh)` to get the next number.
2. Copy the template to `docs/adr/<N>-<kebab-slug>.md`, `Status: Proposed`.
3. Discuss in the PR. On merge, flip to `Status: Accepted`.

## Immutable once Accepted

Once an ADR's status is `Accepted`, **its body is frozen**. A change of direction
is a new ADR that supersedes the old one — set the old one's status to
`Superseded by [ADR-MMMM](...)` and explain the reversal in the new ADR. Do not
rewrite Accepted bodies. The `## References` section is verbatim by design.

## Seed ADRs

| # | Title |
|---|---|
| [0001](0001-project-genesis.md) | Project genesis + the BSD-2-Clause-Patent license choice |
| [0002](0002-interop-sidedata-abi.md) | Append-only side-data interop ABI |
| [0003](0003-ffmpeg-patch-stack.md) | FFmpeg patch-stack delivery model |
| [0004](0004-gpu-backend-dispatch.md) | Multi-backend GPU dispatch + -ENOSYS stubs |
