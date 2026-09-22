# Architecture & System Design Documentation

## 1. Overview
The **Finance Collection SaaS** platform is a production-grade, multi-tenant system designed for finance companies that disburse loans ("Giving") and collect installments ("Collecting") across **Daily**, **Weekly**, **Monthly**, and **Custom** schedules.

```
+-----------------------------------------------------------------------------------+
|                           CLIENT TIER (Flutter Web & Mobile)                      |
|  - Web Console: Super Admin & Company Admin / Managers                            |
|  - Mobile App: Field Collection Agents & Borrowers/Customers                      |
+-----------------------------------------------------------------------------------+
                                         │  (REST API over HTTPS)
                                         ▼
+-----------------------------------------------------------------------------------+
|                       API GATEWAY & SECURITY MIDDLEWARE                           |
|  - Helmet Security Headers, CORS Policy, Rate Limiter                             |
|  - JWT Authentication Middleware                                                  |
|  - Strict Tenant Isolation Guard (req.tenantId)                                   |
|  - RBAC & Permission Guards                                                       |
|  - Joi Request Payload Validation                                                 |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
|                        APPLICATION LOGIC (Node.js Services)                       |
|  - AuthService (JWT & Refresh Token Rotation)                                     |
|  - FinanceCalculatorService (Daily / Weekly / Monthly Schedule & Fee Math)        |
|  - CollectionService (Atomic Mongoose Collections, FIFO Allocation & Receipts)     |
|  - ReportService (Daily/Weekly/Monthly Aggregations & Defaulters)                 |
|  - AuditService (Immutable Event Logging)                                         |
+-----------------------------------------------------------------------------------+
                                         │
                                         ▼
+-----------------------------------------------------------------------------------+
|                          PERSISTENCE TIER (MongoDB)                               |
|  - 22+ Mongoose Collections with Compound Multi-Tenant Indexes                    |
+-----------------------------------------------------------------------------------+
```

---

## 2. Multi-Tenancy Architecture
Every database collection containing company-specific data has a mandatory `companyId` reference indexed as compound keys (e.g. `{ companyId: 1, customerCode: 1 }`).

### Isolation Rules:
1. **Middleware Level**: `tenant.middleware.js` automatically resolves `req.tenantId` from verified JWT claims. Non-superadmin users can NEVER override or access any other tenant's records.
2. **Database Query Level**: Every controller and service explicitly queries `{ companyId: req.tenantId, ... }`.
3. **Super Admin Isolation**: Super Admins have platform-wide analytics and can manage tenants without polluting operational accounting data.

---

## 3. Financial Integrity & Transaction Processing
1. **FIFO Installment Allocation**: When an agent records a payment, `CollectionService` systematically settles the earliest due or overdue installments before applying payments to upcoming installments.
2. **Idempotency**: Prevents double collections through optional `idempotencyKey`.
3. **Receipt Generation**: Creates snapshot receipts immediately with real-time balance calculations, formatted thermal print slips, and 1-click WhatsApp customer share links.
