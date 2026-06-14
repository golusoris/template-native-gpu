# Contributing to PROJECT

Thanks for contributing. This is a native (C/C++) + GPU project; the bar for
correctness and supply-chain hygiene is high. Read
[docs/principles.md](docs/principles.md) first.

## Quick start

```bash
meson setup build
meson compile -C build
meson test -C build
pre-commit install        # format + lint + gitleaks on every commit
```

For the multi-backend example:

```bash
meson setup build-gpu examples/full-gpu-matrix/core
meson compile -C build-gpu && meson test -C build-gpu
```

## The local gate (run before pushing)

```bash
pre-commit run --all-files     # clang-format, shellcheck, codespell, gitleaks, markdownlint
meson test -C build            # fast suite
```

CI additionally runs CodeQL, semgrep, trivy, sanitizers, and a fuzz smoke. Fix
findings locally rather than burning a CI round-trip.

## Conventions

- **Conventional Commits.** The title drives release-please + the changelog
  section. `feat:`/`fix:`/`perf:`/`deprecate:`/`remove:`/`security:` map to
  changelog sections.
- **Changelog fragment.** Add a `changelog.d/<section>/<slug>.md` for any
  user-facing change (see `changelog.d/README.md`).
- **ADRs.** Architecture decisions go in `docs/adr/` (Nygard format). Allocate a
  number with `scripts/adr/next-free.sh`; start from `docs/adr/0000-template.md`.
- **Coding standard.** Power-of-10 (Go-adapted in spirit), CERT-C, Google C++
  style via clang-format. Zero clang-tidy / semgrep / gitleaks findings on merge.
  A `//nolint` / suppression needs a justification comment.
- **Interop ABI is append-only.** See `libproject/AGENTS.md` rules R1–R6.
- **GPU backends** keep their `-ENOSYS` stub in lockstep with the real surface
  and document the cross-backend bit-exactness reasoning.

## Review

CODEOWNERS auto-assigns reviewers. The `required-checks` aggregator is the only
required status; it gates on every CI leg.
