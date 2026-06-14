# Governance

## Model

PROJECT uses a **BDFL-delegated maintainer** model. A small set of maintainers
(see [MAINTAINERS.md](MAINTAINERS.md)) holds merge rights; one lead maintainer
breaks ties and owns the roadmap.

## Decision making

- **Code changes** merge after CODEOWNERS review + a green `required-checks`
  status. Trivial/mechanical changes (dependency bumps, doc typos) may be
  self-merged by a maintainer.
- **Architecture decisions** are recorded as ADRs (`docs/adr/`). An ADR is
  proposed as `Status: Proposed`, discussed in the PR, and flipped to `Accepted`
  on merge. Accepted ADR bodies are **immutable** — a change of direction is a
  new superseding ADR, not an edit.
- **Breaking changes** to the public API or the interop ABI require an ADR and an
  explicit maintainer sign-off.

## Becoming a maintainer

Sustained, high-quality contribution over time, plus demonstrated judgment on
reviews. Existing maintainers nominate; the lead maintainer confirms. New
maintainers are added to MAINTAINERS.md and the CODEOWNERS team.

## Releases

Releases are cut by release-please from Conventional Commits (SemVer). The
publish event triggers the signed, provenance-backed supply-chain workflow. See
[CONTRIBUTING.md](CONTRIBUTING.md) and `docs/development/adr-workflow.md`.

## Security

Security issues follow the private disclosure flow in [SECURITY.md](SECURITY.md),
handled by maintainers under embargo until a coordinated fix ships.
