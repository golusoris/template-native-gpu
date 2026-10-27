# changelog.d/ — changelog fragments

Every user-facing change adds a small Markdown fragment here instead of editing
`CHANGELOG.md` directly. This avoids merge conflicts on the changelog and lets
release-please assemble the release notes mechanically.

## How

Create `changelog.d/<section>/<slug>.md` where `<section>` is one of:

| Section | For |
|---|---|
| `added` | new features / APIs / backends |
| `changed` | behavior changes to existing features |
| `deprecated` | soon-to-be-removed features |
| `removed` | removed features |
| `fixed` | bug fixes |
| `security` | security-relevant fixes |

The fragment body is a single bullet (or a few), e.g.:

```markdown
- Add the HIP backend scaffold with `hipcc --genco` HSACO embedding (#123).
```

`<slug>` is a short kebab description; prefix with the PR/issue number if you
like (`0123-hip-backend.md`).

## Preview / gate

```bash
scripts/release/concat-changelog-fragments.sh           # render the Unreleased body
scripts/release/concat-changelog-fragments.sh --check   # CI gate
```

release-please consumes Conventional Commits to write the final `CHANGELOG.md`;
these fragments are the human-readable, conflict-free staging area and the
preview source.

Planted probe: this line will recieve a codespell finding.
