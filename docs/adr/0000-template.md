<!-- markdownlint-disable MD013 MD041 -->
> **Allocator**: run `scripts/adr/next-free.sh` to get the next free number
> before creating this file. Name the file `docs/adr/NNNN-<kebab-slug>.md`.

# ADR-NNNN: <short, declarative title>

- **Status**: Proposed | Accepted | Deprecated | Superseded by [ADR-MMMM](MMMM-title.md)
- **Date**: YYYY-MM-DD
- **Deciders**: <names / handles>
- **Tags**: <comma-separated — e.g. `build`, `gpu`, `cuda`, `abi`, `ci`, `security`, `license`>

## Context

What problem are we solving? What forces are at play (technical, organisational,
regulatory)? Cite constraints from [principles.md](../principles.md) (Power-of-10,
CERT, SLSA, …) where relevant. One or two paragraphs — the reader should
understand *why a decision was needed*, not the full history. Paraphrase any
discussion into neutral English; this section is explanation for future
maintainers, not a verbatim audit trail.

## Decision

State the decision in active voice: "We will use X." One paragraph max.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Option A | … | … | … |
| Option B | … | … | … |

At minimum list the runner-up. If this section is empty, the decision wasn't real
— it was a default.

## Consequences

- **Positive**: what becomes easier, faster, safer.
- **Negative**: what becomes harder, slower, more expensive.
- **Follow-ups**: new tests, docs, migration steps, deprecation timelines.

<!-- Optional, include only when relevant; delete the header otherwise: -->
<!-- ## Supply-chain impact   (new/removed dependency, build-time fetch, SBOM delta) -->

## References

<!-- Verbatim citations (issue/PR links, requirement IDs). This section is the
     audit trail — keep the original wording. -->
