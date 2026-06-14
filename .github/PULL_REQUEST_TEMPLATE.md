<!-- markdownlint-disable MD041 -->
## What

<!-- One-paragraph summary of the change and why. -->

## Type

- [ ] feat / fix / perf / refactor / docs / test / build / ci / chore

## Checklist

- [ ] Conventional Commit title (release-please depends on it).
- [ ] A `changelog.d/<section>/<slug>.md` fragment is added (or `chore`/`docs`
      with no user-facing change).
- [ ] `pre-commit run --all-files` is clean (format + lint + gitleaks).
- [ ] `meson test` passes locally; race/sanitizer-relevant changes were run
      under ASan/TSan.
- [ ] Public API / interop-ABI change? — bumped `PROJ_ABI_MINOR`, updated the
      `_Static_assert` size locks + `interop_test.c`, and wrote an ADR.
- [ ] GPU backend change? — kept the `-ENOSYS` stub in lockstep and added/kept
      the cross-backend parity reasoning.

## Migration (breaking changes only)

<!-- before/after snippets; what downstream consumers must change. -->
