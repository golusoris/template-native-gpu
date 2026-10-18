<!-- markdownlint-disable MD013 MD041 -->
# ADR-0005: EUPL-1.2 licence with LGPL-2.1-or-later FFmpeg patches

- **Status**: Accepted
- **Date**: 2026-10-19
- **Deciders**: maintainers
- **Tags**: license, governance

## Context

[ADR-0001](0001-project-genesis.md) chose BSD-2-Clause-Patent with an optional
MIT secondary licence. The fleet this template serves licenses its own library
code under EUPL-1.2 and keeps code that becomes part of an upstream project
under that upstream's licence. The FFmpeg filter sources under
`ffmpeg-patches/files/` and the generated patches already carry FFmpeg's
LGPL-2.1 header, so a single permissive SPDX identifier misdescribed them.

## Decision

We license the repository under EUPL-1.2, documentation text under
CC-BY-SA-4.0, and the FFmpeg filter sources and patches under
LGPL-2.1-or-later with FFmpeg's copyright next to the authors'. `REUSE.toml`
maps every file to its licence and `reuse lint` verifies it.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
| --- | --- | --- | --- |
| Keep BSD-2-Clause-Patent (+ MIT) | Permissive, patent grant | Diverges from the fleet's library licence; patches mislabelled | Permissive own code contradicts the fleet licence |
| EUPL-1.2 everywhere, patches included | One identifier | Patches modify FFmpeg's LGPL sources and cannot be relicensed | Wrong for code built into FFmpeg |
| EUPL-1.2 + LGPL-2.1-or-later override | Matches the material; EUPL-1.2 keeps a patent grant (Article 2) and lists GPL-2/3 and LGPL-2.1/3 as compatible licences (Appendix) | Two licences to explain | — (chosen) |

## Consequences

- **Positive**: SPDX headers, `REUSE.toml` and the SBOM describe the patches
  correctly; the template matches the fleet's other libraries.
- **Negative**: EUPL-1.2 is copyleft; adopters who want permissive terms must
  relicense their fork.
- **Follow-ups**: `LICENSE-MIT` and the `BSD-2-Clause-Patent OR MIT` option are
  removed; new files fall under the EUPL-1.2 default table unless
  `REUSE.toml` places them under another table.

## References

- Supersedes [ADR-0001](0001-project-genesis.md) for the licence choice.
- Maintainer licence decision, 2026-10-19 (paraphrased): whole tree EUPL-1.2,
  documentation CC-BY-SA-4.0, FFmpeg files LGPL-2.1-or-later.
- EUPL-1.2 text: `LICENSES/EUPL-1.2.txt`, Article 2 (patents) and Appendix
  (compatible licences).
