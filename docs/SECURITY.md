# Security & Data Protection Architecture

Financial applications demand stringent defense-in-depth measures. Below are the key security layers built into the SaaS.

---

## 1. Multi-Tenant Data Isolation
- **Tenant Context Extraction**: Authentication middleware decodes the JWT and binds `companyId` strictly to `req.tenantId`.
- **Backend Query Guards**: Non-superadmin users can never manipulate or query data across other tenants.
- **Compound Database Keys**: Index constraints ensure cross-tenant uniqueness without exposing company IDs.

---

## 2. Authentication & Credential Security
- **Bcrypt Password Hashing**: Passwords hashed with 10 salt rounds before database persistence. Plaintext passwords are never logged or stored.
- **JWT Access & Refresh Token Rotation**: Short-lived access tokens (7 days) coupled with refresh tokens (30 days).
- **Session Eviction**: Immediate token revocation and session invalidation on logout.

---

## 3. Financial Integrity & Transaction Atomicity
- **FIFO Installment Payment Engine**: Sequential balance reduction across past due/upcoming installments.
- **Idempotency Safeguard**: Collection requests accept optional `idempotencyKey` headers to prevent double-charging over unstable field network connections.
- **Balance Bounds Checking**: Rejects any collection amount that exceeds remaining debt.

---

## 4. API & Network Protection
- **Helmet.js**: Configures secure HTTP headers (XSS Filter, HSTS, Content Security Policy, Hide Powered-By).
- **Rate Limiting**:
  - Global API rate limiter: 1,000 requests per 15-minute window.
  - Auth rate limiter: 30 login attempts per 15-minute window to prevent brute force attacks.
- **Input Validation**: Centralized Joi schemas sanitize and validate all request payloads.
- **Audit Logging**: Immutable audit records for critical events (Logins, Loan Disbursements, Collections, Settings changes).
