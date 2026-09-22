# REST API Documentation (API v1)

Base URL: `http://localhost:5000/api/v1`

---

## 1. Authentication Endpoints

### `POST /api/v1/auth/login`
Authenticate user (Super Admin, Company Admin, Manager, Agent, Staff, or Customer).
- **Body**:
```json
{
  "email": "admin@apexfinance.com",
  "password": "ApexAdmin@2026!"
}
```
- **Response**:
```json
{
  "success": true,
  "message": "Login successful",
  "data": {
    "user": {
      "id": "60d0fe4f5311236168a109ca",
      "name": "Suresh Menon",
      "email": "admin@apexfinance.com",
      "role": "COMPANY_ADMIN",
      "company": {
        "id": "60d0fe4f5311236168a109cb",
        "name": "Apex Micro Finance Ltd",
        "companyCode": "APEX",
        "currency": { "code": "INR", "symbol": "₹" }
      }
    },
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "eyJhbGciOi..."
  }
}
```

### `POST /api/v1/auth/refresh`
Get new access token using refresh token.

### `POST /api/v1/auth/change-password`
Update user password with validation.

---

## 2. Super Admin Endpoints (Requires `SUPER_ADMIN` Role)

- `GET /api/v1/super-admin/dashboard`: Platform metrics, company count, user count, collection volume.
- `GET /api/v1/super-admin/companies`: List all tenant companies with pagination and search.
- `POST /api/v1/super-admin/companies`: Onboard new finance company + initial Company Admin user.
- `GET /api/v1/super-admin/companies/:id`: Full company details and stats.
- `PUT /api/v1/super-admin/companies/:id`: Update company status (`ACTIVE`, `INACTIVE`, `SUSPENDED`).
- `GET /api/v1/super-admin/subscription-plans`: List subscription plans.
- `POST /api/v1/super-admin/subscription-plans`: Create subscription plan.
- `GET /api/v1/super-admin/audit-logs`: System-wide audit log stream.

---

## 3. Company Admin & Dashboard Endpoints

- `GET /api/v1/company/dashboard`: Executive metrics (Active loans, today's collected, pending amount, all-time volume).
- `GET /api/v1/company/profile`: Company details.
- `PUT /api/v1/company/profile`: Update address, phone, logo, working days.
- `GET /api/v1/company/settings`: Receipt settings, penalty rules, notifications.
- `PUT /api/v1/company/settings`: Update settings.

---

## 4. Agent & Route Management

- `GET /api/v1/agents`: List all company agents with targets and collections.
- `POST /api/v1/agents`: Create new agent account with login credentials.
- `GET /api/v1/agents/my-dashboard`: Agent-specific field dashboard (Today's due, pending, collected).
- `GET /api/v1/agents/my-customers`: High-speed assigned customer list for mobile quick-pad.

---

## 5. Customer Management

- `GET /api/v1/customers`: List customers with routeArea & agent filters, search, pagination.
- `POST /api/v1/customers`: Onboard new customer with KYC and guarantor.
- `GET /api/v1/customers/:id`: Full profile, active loans, payment history & receipts.
- `PUT /api/v1/customers/:id`: Update customer info or assign agent.

---

## 6. Finance Products & Schemes

- `GET /api/v1/finance-products`: List schemes (Daily 100-Day, Weekly 10-Week, Monthly EMI).
- `POST /api/v1/finance-products`: Create new product (configure interest, doc charges, upfront deduction, frequency).

---

## 7. Loan Disbursement ("Giving")

- `POST /api/v1/finance-accounts/preview-disbursement`: Calculate schedule, net payout, and installments in real time before creating.
- `POST /api/v1/finance-accounts/disburse`: Atomically disburse loan, generate installment schedule, and update customer ledger.
- `GET /api/v1/finance-accounts`: List accounts with status/frequency filters.
- `GET /api/v1/finance-accounts/:id`: Account details with complete installment schedule table.

---

## 8. Collection Management ("Collecting")

- `POST /api/v1/collections/record`: Atomically record single installment payment, generate receipt, update account balance, and update daily collection log.
- `GET /api/v1/collections/today-sheet`: Today's collection sheet filtered by route and agent.
- `POST /api/v1/collections/bulk`: Batch rapid keyboard collection entry.
- `POST /api/v1/collections/settle-handover`: Settle agent cash handover to cashier.

---

## 9. Payments & Digital Receipts

- `GET /api/v1/payments`: Payment collection transactions history.
- `GET /api/v1/payments/:id`: Payment details with installment allocation breakdown.
- `GET /api/v1/receipts/:id`: Get digital receipt snapshot.
- `GET /api/v1/receipts/:id/whatsapp`: Generate 1-click WhatsApp formatted receipt link.

---

## 10. Financial Reports & Export

- `GET /api/v1/reports/daily`: Daily collection summary (Expected vs Collected, Recovery %).
- `GET /api/v1/reports/weekly`: 7-day trend analysis.
- `GET /api/v1/reports/monthly`: 12-month performance.
- `GET /api/v1/reports/agents`: Agent performance ranking.
- `GET /api/v1/reports/defaulters`: Overdue aging report.
- `GET /api/v1/reports/export-csv`: CSV file stream of payment transactions.
