# Security Policy

## Supported versions

| Version          | Supported          |
|------------------|--------------------|
| latest `main`    | :white_check_mark: |
| latest 2 tags    | :white_check_mark: |
| older            | :x:                |

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

Use GitHub's private vulnerability-reporting flow:
`https://github.com/your-org/myproject/security/advisories/new`

Alternative channel: email `security@example.com` — PGP-encrypt anything
sensitive; request the public key via the same address.

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

Releases ship with SLSA L3 provenance, Sigstore keyless (cosign) signatures, and
both SPDX + CycloneDX SBOMs (see `.github/workflows/supply-chain.yml`). Verify a
release artifact:

```bash
cosign verify-blob --bundle <artifact>.bundle <artifact>
```

This project targets the controls scaffolded for OWASP ASVS L2, NIST SSDF, and
SLSA L3. Downstream products assert their compliance posture in their own
`SECURITY.md`.
