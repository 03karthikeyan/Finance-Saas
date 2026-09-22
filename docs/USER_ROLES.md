# User Roles & Permission Matrix

The platform implements strict Role-Based Access Control (RBAC) across 6 distinct user roles.

---

## 1. Role Definitions

### 1. `SUPER_ADMIN` (Platform Owner)
- **Scope**: Platform-wide
- **Capabilities**:
  - View platform analytics (total companies, global volume, subscriptions)
  - Onboard new finance company tenants & create initial company admin accounts
  - Activate, deactivate, or suspend companies
  - Manage SaaS subscription tiers (Starter, Pro, Enterprise)
  - Inspect global audit logs & platform system settings

---

### 2. `COMPANY_ADMIN` (Tenant Owner / CEO)
- **Scope**: Tenant-isolated (`companyId`)
- **Capabilities**:
  - Executive financial dashboard (today's collections, total outstanding, active loans)
  - Customer registration & KYC management
  - Loan disbursement ("Giving") & automated installment generation
  - Agent and employee management, line & route assignment
  - Branch creation and allocation
  - Configurable daily/weekly/monthly finance products setup
  - Daily, weekly, and monthly reports + CSV data export
  - Receipt template and penalty rule configuration

---

### 3. `MANAGER` (Branch / Line Supervisor)
- **Scope**: Branch / assigned lines
- **Capabilities**:
  - Customer approvals and loan disbursement
  - Collection sheet monitoring and cash drawer settlement
  - Overdue account tracking and collection performance analysis

---

### 4. `AGENT` (Field Collection Officer)
- **Scope**: Assigned customers and geographic lines
- **Capabilities**:
  - Fast mobile quick-pad collection entry
  - View today's due installments and pending collections
  - Collect payments with Cash or UPI
  - 1-click digital receipt generation and WhatsApp direct share
  - Daily collection handover summary

---

### 5. `STAFF` (Back-Office Operator)
- **Scope**: Tenant operations
- **Capabilities**:
  - Batch / bulk collection entry from physical field sheets
  - Customer records entry

---

### 6. `CUSTOMER` (Borrower)
- **Scope**: Own finance account only
- **Capabilities**:
  - View active loan balance, installment schedule, and next due date
  - Payment transaction history & digital receipt access
