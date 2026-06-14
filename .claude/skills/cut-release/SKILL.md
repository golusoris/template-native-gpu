---
name: cut-release
description: Drive a release — verify the gate is green, merge the release-please PR, and confirm the signed supply-chain workflow ran.
---

# cut-release

Releases are automated by release-please; this skill is the human-in-the-loop
checklist around it.

## Steps

1. **Confirm the release PR.** release-please maintains an open PR titled
   `chore(main): release <version>`. Review the generated CHANGELOG diff and the
   version bump (in `project.h` + the manifest).

   ```bash
   gh pr list --label "autorelease: pending"
   ```

2. **Gate is green.** The `required-checks` status must be passing on the release
   PR (CI, security-scans, sanitizers).

3. **Merge.** Merging the PR makes release-please push the tag and publish a
   GitHub release.

   ```bash
   gh pr merge <N> --squash
   ```

4. **Supply chain.** The `release: published` event triggers
   `supply-chain.yml` (SLSA L3 provenance + cosign signatures + SBOM). Confirm:

   ```bash
   gh run list --workflow supply-chain.yml --limit 1
   ```

5. **Verify a signed artifact** (smoke):

   ```bash
   cosign verify-blob --bundle <artifact>.bundle <artifact>
   ```

Never hand-edit CHANGELOG.md or hand-create the tag — let release-please own
both.
