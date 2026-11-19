# Security Policy

## Supported versions

| Version          | Supported          |
|------------------|--------------------|
| latest `main`    | :white_check_mark: |
| latest 2 tags    | :white_check_mark: |
| older            | :x:                |

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Use GitHub private vulnerability reporting: open this repository's
**Security and quality** tab and choose **Report a vulnerability** (the form
lives at `<repository URL>/security/advisories/new`). The report stays
private: only you, the repository admins and security managers, and the
collaborators they add to the advisory can see it.

Please include:

1. Affected version(s) / commit SHA.
2. A minimal reproducer (inputs, command line, expected vs. actual).
3. Your assessment of impact (crash / memory corruption / DoS / info leak).
4. Whether you believe a CVE should be requested.

## Response timeline

- **Acknowledgment**: within 72 hours.
- **Initial triage**: within 7 days.
- **Fix + coordinated disclosure**: severity-dependent; we aim for 90 days max.

## Supply-chain assurances

Releases ship with a build provenance attestation, Sigstore keyless (cosign)
signatures, and both SPDX + CycloneDX SBOMs (see
`.github/workflows/supply-chain.yml`). The attestation is a GitHub artifact
attestation, which GitHub documents as SLSA v1.0 Build Level 2; no higher level
is claimed. Verify a release artifact:

```bash
cosign verify-blob --bundle <artifact>.bundle <artifact>
gh attestation verify <artifact> --repo <owner>/<repository>
```

This project targets the controls scaffolded for OWASP ASVS L2, NIST SSDF, and
SLSA v1.0 Build Level 2. Downstream products assert their compliance posture in
their own `SECURITY.md`.
