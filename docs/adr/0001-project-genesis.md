<!-- markdownlint-disable MD013 MD041 -->
# ADR-0001: Project genesis + BSD-2-Clause-Patent license

- **Status**: Accepted
- **Date**: 2026-01-01
- **Deciders**: maintainers
- **Tags**: license, governance

## Context

A new native (C/C++) + GPU + FFmpeg-filter project needs a license that is (a)
simple and permissive, (b) GPL-2-compatible so the artifacts can link into
GPL/LGPL ecosystems like FFmpeg, and (c) carries an express patent grant to
protect downstream consumers — GPU compute touches patented codec/filter
territory.

## Decision

We license the project under **BSD-2-Clause-Patent** (SPDX: `BSD-2-Clause-Patent`,
a.k.a. BSD+Patent), with an optional secondary **MIT** for dual-licensed files
(SPDX `BSD-2-Clause-Patent OR MIT`).

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Apache-2.0 | Express patent grant, widely understood | Not GPL-2 compatible | Blocks linking into GPL-2 FFmpeg builds |
| MIT / BSD-2 | Minimal, ubiquitous | No patent grant | GPU/codec patent exposure for users |
| BSD-2-Clause-Patent | Permissive + GPL-2 compat + patent grant | Less common, slightly longer | — (chosen) |

## Consequences

- Positive: downstream can link into GPL/LGPL builds and gets a patent grant.
- Follow-ups: every source file carries the SPDX header; redistributed
  third-party assets get a `LICENSES/<id>.txt` + a `NOTICE` entry.

## References

- SPDX: BSD-2-Clause-Patent.
