---
name: new-adr
description: Allocate the next free ADR number and scaffold a new architecture decision record from the template.
---

# new-adr

Use when a change makes an architecture decision worth recording (a new GPU
backend, an interop-ABI evolution, a build-system choice, a dependency).

## Steps

1. Allocate the next number:

   ```bash
   N=$(scripts/adr/next-free.sh)
   ```

2. Create `docs/adr/<N>-<kebab-slug>.md` from `docs/adr/0000-template.md`.

3. Fill in: Title, `Status: Proposed`, Context, Decision, Consequences,
   Alternatives considered, References. Paraphrase user input into neutral
   English in Context/Alternatives; keep References citations verbatim.

4. On merge, flip `Status: Proposed` → `Accepted`. **Accepted bodies are
   immutable** — a later change of direction is a new superseding ADR, not an
   edit (record `Superseded by ADR-<M>` in the old one's status line).

5. Add a `changelog.d/` fragment if the decision ships a user-facing change.
