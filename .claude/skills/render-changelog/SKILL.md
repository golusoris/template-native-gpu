---
name: render-changelog
description: Concatenate the changelog.d/ fragments into a Keep-a-Changelog Unreleased section for review (release-please owns the final CHANGELOG.md).
---

# render-changelog

Use to preview what the next release's notes will look like, or to sanity-check
that every PR added its fragment.

## How fragments work

Each user-facing change adds a markdown fragment under
`changelog.d/<section>/<slug>.md`, where `<section>` is one of: `added`,
`changed`, `deprecated`, `removed`, `fixed`, `security`. A fragment is a single
bullet line (see `changelog.d/README.md`).

## Render a preview

```bash
scripts/release/concat-changelog-fragments.sh
```

This prints an `## [Unreleased]` block grouping the fragments by section. It does
NOT modify `CHANGELOG.md` — release-please owns that file and assembles the real
entry from Conventional Commits at release time. Use this skill for review only;
delete consumed fragments when release-please cuts the release (or let the
release workflow do it).
