# Phase 8 — GHAS + GitHub Administration

> **Goal:** stand up a secure-by-default org — CodeQL, secret scanning, push protection, Dependabot, SSO/SCIM, rulesets, audit log streaming.

Companion to Chapter 8 in [BOOK.md](../index.md).

## What you build

`secure-org/` test org with:

- CodeQL default + `security-extended` queries.
- Secret scanning + push protection with a custom pattern.
- Dependabot alerts + security updates + version updates.
- SSO via Entra ID + SCIM provisioning.
- Rulesets enforcing CODEOWNERS, signed commits, required checks.
- Audit log streaming to Azure Event Hub.
- An enterprise Actions policy allowing only `actions/*` + verified creators.

## 8 hands-on exercises

1. Enable CodeQL on a repo and inspect the SARIF.
2. Write a custom QL query for a forbidden function call.
3. Configure a custom secret pattern (regex + test string).
4. Trigger push protection by attempting to commit a fake key.
5. Open a Dependabot security update PR; merge it.
6. Create a ruleset on `main` requiring CodeQL + signed commits.
7. Stream the audit log to Event Hub (or a file for testing).
8. Define an enterprise allow-list for Actions creators.

## Quiz answers

See [exercises.md](exercises.md).

## Next

[Phase 9 — Exam Prep](../Chapter22_Exam_Prep/index.md).
