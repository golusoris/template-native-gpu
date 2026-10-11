<!-- markdownlint-disable MD013 -->
# Engineering principles

The foundational contract for PROJECT. CI enforces the hard gates; reviewers and
agents enforce the guidance.

## §2.1 Power of 10 (C/C++-adapted)

Hard gates (block on violation):

1. **Simple control flow.** No `goto` spaghetti, no recursion without a documented
   depth bound, no unstructured jumps.
2. **Bounded loops.** Every loop has a statically obvious upper bound.
3. **Small functions.** ~60 lines / 15 branches max (clang-tidy
   `readability-function-size`). A `//nolint` needs a justification + a refactor
   note.
4. **Checked errors.** Every fallible call's return is checked. No bare `-1`
   crosses an API boundary — use the `proj_result` enum.
5. **Zero findings on merge.** 0 clang-tidy, 0 semgrep, 0 gitleaks, sanitizer-
   green.

Guidance: limit pointer indirection, minimize dynamic allocation after init,
keep the preprocessor restrained.

## §2.2 SEI CERT C/C++

- **STR31-C** — bounded string ops only (no `strcpy`/`strcat`/`sprintf`).
- **MSC30-C / MSC32-C** — no `rand()`; deterministic, seedable RNG; output is
  reproducible.
- **FLP** — reductions use a `double` outer accumulator so the CPU reference and
  the GPU kernels agree bit-for-bit; control fused-multiply-add on the device
  (`--fmad=false` / `-ffp-contract=off`) where bit-exactness is required.
- **MEM / concurrency** — check allocations; free on every path; snapshot env
  reads once under a lock (`gpu_dispatch_env`).

Cite rule IDs in review.

## §2.3 Style

Google C++ Style as the canonical reference, enforced via clang-format (config at
repo root). One-liner WHY comments only — no boilerplate doc blocks (the CodeQL
`poorly-documented-function` rule is suppressed for this reason).

## §2.4 C4 + ADRs

Architecture decisions live in `docs/adr/` (Nygard format), one per decision.
Accepted bodies are immutable — supersede, don't edit.

## §2.5 Security + supply chain

The template scaffolds the controls for SLSA v1.0 Build Level 2 (provenance
attestation), OWASP ASVS L2, NIST SSDF, and keyless signing + SBOM on release. Products built from it assert their
own compliance posture in their `SECURITY.md`.

## §2.6 Wire protocols

If you add an HTTP surface: RFC 9457 Problem Details for error bodies, OpenAPI
3.1 for the schema. The side-data interop ABI is the in-process wire contract
(append-only; ADR-0002).

## §2.7 Tooling

EditorConfig, clang-format, Conventional Commits, SemVer, Keep-a-Changelog (via
`changelog.d/`), Trunk-Based Development. pre-commit is the local gate.

## §2.8 Testing

Table-driven where it fits, `-fsanitize` in CI (ASan/UBSan/TSan), fuzz targets
for untrusted-input parsers, integration over mocks. Target ≥70% coverage (≥85%
on security-critical paths).

## §2.9 Deployment

Twelve-Factor config, OCI images, rootless + read-only FS, GPU node affinity (see
`deploy/helm/project/`).
