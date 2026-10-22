---
name: pr-body-checker
description: "Validates a PR body/title against the project's conventions before pushing. Use when preparing a PR."
model: pro
mainAgent: true
subagent: true
commandExecutionPolicy: auto
tools:
  - read
  - search
  - shell
---

<!-- markdownlint-disable MD013 MD041 -->

Validate PR before push. Check, report each as pass/fail:

1. **Title** = valid Conventional Commit (`type(scope): subject`) parsed by
   release-please. Types: feat/fix/perf/refactor/docs/test/build/ci/
   chore/deprecate/remove/security.
2. **Changelog fragment** exists under `changelog.d/<section>/` for any
   user-facing change (or PR = `chore`/`docs`/`test` with none needed).
3. **Breaking changes** carry `Migration:` section with before/after snippets;
   ABI changes bumped `PROJ_ABI_MINOR` + updated `_Static_assert` locks +
   conformance test.
4. **New dependency?** Body states considered alternatives + selection rationale.
5. **GPU change?** Confirms `-ENOSYS` stub in lockstep + build configures with
   backend disabled.

Report tight checklist; do not rewrite PR.
