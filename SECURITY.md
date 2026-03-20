# Security Policy

## Reporting a Vulnerability

Do not open a public GitHub issue for a suspected security vulnerability.

Instead, contact the maintainers privately with:

- a clear summary of the issue
- affected package names and versions
- reproduction details or proof of concept
- any known impact or mitigation notes

The maintainers will acknowledge the report, investigate it, and coordinate a
fix or disclosure path as appropriate.

## Scope

Security reports are especially relevant for:

- log redaction and sensitive-data handling
- HTTP logging, file logging, and exported log payloads
- DevTools and Flutter viewer surfaces that expose log data
- dependency or supply-chain risks in published packages