# LICENSES/

One file per third-party license / redistributed asset, named by SPDX
identifier (e.g. `Apache-2.0-<asset>.txt`, `MIT-<lib>.txt`). The root `NOTICE`
indexes them.

This directory is empty in the template by design — populate it when you vendor
code or redistribute a model/asset whose license requires the verbatim text to
travel with the binary (Apache-2.0 §4, BSD attribution clauses, etc.). The
`supply-chain.yml` workflow stages any files here alongside the release
artifacts so they are signed + provenance-covered.
