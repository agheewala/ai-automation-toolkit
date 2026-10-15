# Security & Compliance

> Covers safety, data protection, OWASP rules, and third-party governance.  
> Authority: Defers to `governance/copilot-instruction.md`.

---

## 1. Core Security Principles

| Principle | Requirement |
|---|---|
| Input validation | Validate all user input at the controller boundary — never trust client data |
| Output encoding | All user-controlled data rendered in UI must be encoded by default (most frameworks auto-encode — never bypass this with a "raw HTML" / unescaped-output helper on user input) |
| Least privilege | Code should only access what it needs — no over-permissioned queries or roles |
| Defense in depth | Multiple layers of control — never rely on a single check |
| Fail secure | On error, deny access by default — do not silently continue |
| No secret exposure | No credentials, connection strings, API keys, or tokens in source code |
| Audit trail | Log all security-relevant events with sufficient context |

---

## 2. OWASP Top 10 Controls

| OWASP Risk | Control in Place |
|---|---|
| **A01 Broken Access Control** | Shared authenticated base/middleware validates session on every request; role checks enforced in service layer |
| **A02 Cryptographic Failures** | No PII or secrets in logs; connection strings in environment-level secrets only |
| **A03 Injection** | Parameterised SQL stored procedure calls only; no dynamic SQL string concatenation |
| **A04 Insecure Design** | Input validated at system boundary; no client-side-only validation |
| **A05 Security Misconfiguration** | Environment-specific config; no stack traces or debug info in production error responses |
| **A06 Vulnerable Components** | OWASP Dependency Check runs via `dependencycheck-suppression.xml`; no unreviewed third-party additions |
| **A07 Authentication Failures** | Session-based auth enforced by the shared authenticated base/middleware; a session-timeout utility handles inactivity logout; cache-busting prevents back-button replay of authenticated pages |
| **A08 Software & Data Integrity** | Anti-forgery token embedded in all forms via the project's shared form-state partial/component; no unsigned package installs |
| **A09 Security Logging Failures** | Logging framework logs all critical actions; sensitive data (PII, passwords, tokens) never logged |
| **A10 SSRF** | External service calls go through the controlled outbound integration layer only |

---

## 3. Authentication & Session Rules

- All pages that require authentication must use the project's shared authenticated base/middleware.
- Public/unauthenticated pages must use the project's shared public (unauthenticated) base.
- Session data is accessed via the project's session-context abstraction — never bypass this by reading the raw session store directly.
- Session timeout is enforced by the project's session-timeout utility — do not modify timeout values without approval.
- Back-navigation prevention: apply the project's cache-busting pattern at the end of every authenticated page.
- Direct URL access to authenticated pages must redirect to login if session is invalid.

---

## 4. Input Validation Rules

- Validate at the **controller boundary** — the first point of entry.
- Use model `DataAnnotations` where applicable.
- Do NOT trust client-side validation as the sole gate — always validate server-side.
- Reject inputs that do not conform to expected format, length, or type.
- Return structured errors via the project's standard error-collection mechanism — never expose raw exception messages.
- Never pass unvalidated user input directly into a SQL query, stored procedure parameter that constructs dynamic SQL, file path, or URL redirect.

---

## 5. Output & Rendering Rules

- Templated/rendered output must be encoded by default — do NOT use an unescaped-output helper with any user-controlled content.
- JSON responses must not include sensitive session data, internal IDs, or stack traces.
- Error responses in production must be generic: "An error occurred. Please try again." — no technical details.
- AJAX responses must use the standard structure defined by this project's conventions.

---

## 6. CSRF Protection

- All forms include the anti-forgery token via the project's shared form-state partial/component — this is non-negotiable.
- AJAX POST requests must include the anti-forgery token header.
- Do NOT disable anti-forgery validation on any form-based action method.

---

## 7. Data Handling & Privacy

- Do NOT log PII (names, SSNs, TINs, addresses, account numbers).
- Do NOT store sensitive data in client-side view state, hidden fields, or URL query strings without careful review.
- Do NOT include sensitive data in error messages, validation summaries, or AJAX responses.
- Database queries must include appropriate `WHERE` clauses — never return unbounded datasets.
- Paginate large result sets — use the project's standard page/block-size constant.

---

## 8. Secret & Credential Management

- No hardcoded credentials, API keys, connection strings, or tokens in any source file.
- Use `.vscode/mcp.json` placeholders only — real values live in environment-level secrets or a vault. This file must never be committed (see `scm-workflow.md` Section 4).
- `.env` files and secrets files must be in `.gitignore` — never committed to source control.
- Rotate credentials immediately if accidentally committed.

---

## 9. Third-Party Dependency Rules

- No new third-party libraries without:
  1. Explicit user/team lead approval
  2. License compatibility confirmed (permissive license required — no GPL in proprietary code)
  3. OWASP Dependency Check review
  4. Security assessment of the library's reputation and maintenance status
- No CDN references in production code — all assets must be locally bundled.
- No copied external code without attribution and license review.
- Existing dependency versions must not be downgraded without review.

---

## 10. Build & Static Analysis

| Check | Tool | When |
|---|---|---|
| Compilation | Project's build tool (`{{BUILD_COMMAND_MODULE}}` or full `{{BUILD_COMMAND_FULL}}` per ticket Type — see `behavior/setting.md`) | After every code change, before push |
| Dependency vulnerabilities | OWASP Dependency Check | As part of CI pipeline |
| Code quality & security | SonarQube | CI pipeline; quality gate must not be broken |
| Secrets scanning | TBD (pipeline-level) | On every commit |

---

## 11. Deployment & Environment Rules

| Environment | Rule |
|---|---|
| **Development** | Verbose logging; detailed error pages permitted; feature flags freely toggled |
| **Staging** | Production-like config; no debug pages; real data snapshots; all secrets in vault |
| **Production** | No detailed error messages; all secrets in vault; feature flags default to `false`; no debug assemblies |

---

## 12. Security Incident Response

If a security issue is discovered during implementation:

1. **STOP** all code changes immediately.
2. Document the issue in the chat response to the user (Security section of the analysis) — this workspace uses chat-based tickets (see `copilot-instruction.md` Section 3), not a `tickets/<TicketID>/` file structure. Offer to save it as `<TicketID>_Security_Analysis.txt` if the user wants a file copy (per `copilot-instruction.md` Section 5.4).
3. Notify the team lead and security contact.
4. Do NOT attempt to fix a security vulnerability as an undocumented side-effect of another ticket.
5. Create a separate, dedicated security ticket for the fix.
6. Never disclose the vulnerability publicly before it is patched.

---
