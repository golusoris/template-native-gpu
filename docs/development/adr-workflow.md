<!-- markdownlint-disable MD013 -->
# ADR workflow

How architecture decisions are recorded and evolved.

## When to write one

Write an ADR when a change makes a decision a future maintainer would want the
*reasoning* for: a new GPU backend, an interop-ABI evolution, a build-system
choice, adding/removing a dependency, a license or governance change.

## Steps

1. Allocate a number:

   ```bash
   N=$(scripts/adr/next-free.sh)
   ```

2. Copy `docs/adr/0000-template.md` to `docs/adr/<N>-<kebab-slug>.md`. Set
   `Status: Proposed`.

3. Fill in Context, Decision, Alternatives considered (at least the runner-up),
   Consequences, References. Paraphrase discussion into neutral English in
   Context/Alternatives; keep `## References` citations verbatim (it's the audit
   trail).

4. Open the PR. Discuss. On merge, flip `Status` to `Accepted`.

## Immutable once Accepted

An Accepted ADR body is frozen. To change direction, write a NEW ADR that
supersedes it: set the old one's status to `Superseded by [ADR-MMMM](...)` and
explain the reversal in the new one. Never rewrite an Accepted body.

## Tie-in

- Add the ADR to the index table in `docs/adr/README.md`.
- Add a `changelog.d/` fragment if the decision ships a user-facing change.
- The `new-adr` Claude skill automates steps 1–3.
