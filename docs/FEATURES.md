# Feature Specification & Functional Capabilities

The **Finance Collection SaaS** platform delivers an end-to-end suite for microfinance companies, lending operators, and debt collectors.

---

## 1. Multi-Tenant Architecture & Platform Administration
- **Tenant Self-Containment**: Complete database and service isolation per company.
- **Tenant Management**: Super Admin portal for provisioning, monitoring, and managing company tenants and subscriptions.
- **Subscription Tiers**: Starter, Professional, and Enterprise plans with user, customer, and branch limits.

---

## 2. Configurable Loan Schemes ("Giving")
- **Daily Micro Finance**:
  - Example: 100-day or 50-day loans with 5% doc fee deducted upfront.
  - Net payout calculated automatically (e.g. ₹10,000 principal - ₹500 doc fee = ₹9,500 disbursed; customer pays ₹100/day).
- **Weekly Commercial Loans**:
  - Example: 10-week or 12-week market line loans.
- **Monthly Business Loans**:
  - Example: 12-month EMI schemes.
- **Custom Schedules**:
  - Configurable interest calculations (Flat Interest vs Upfront Doc Fee vs Fixed Installments).
  - Optional Sunday / Holiday exclusion.

---

## 3. High-Speed Collection System ("Collecting")
- **Field Agent Quick-Pad**:
  - 1-Tap collection pad designed for rapid field operation on mobile & tablet.
  - Route/Line filtering (e.g. "Line 1 - Wholesale Market", "Line 2 - Station Road").
  - Quick action presets: `[1x Due]`, `[2x Due]`, `[Full Balance]`.
  - Payment modes: Cash, UPI / QR, Bank Transfer.
- **Atomic Balance Updates**:
  - Payments are sequentially applied across oldest unpaid/due installments (FIFO).
  - Automatically updates `Installment.paidAmount`, `FinanceAccount.remainingAmount`, `Customer.totalOutstandingAmount`, and daily `Collection` summaries.
- **1-Click WhatsApp Receipts**:
  - Generates instant WhatsApp share link opening `wa.me/<phone>?text=<receipt>` with customer name, loan #, paid amount, and remaining balance.

---

## 4. Route & Field Officer Management
- **Geographic Line Allocations**: Assign collectors to specific commercial lines/markets.
- **Target Tracking**: Daily collection targets vs actual recovery rates.
- **Cashier Handover**: End-of-day cash drawer reconciliation and verified handover settling.

---

## 5. Financial Reports & Risk Analytics
- **Live Daily Collection Summary**: Expected dues vs actual collected, with real-time recovery percentage.
- **7-Day Trend Analysis**: Interactive charts for daily collection velocity.
- **12-Month Performance**: Long-term revenue and recovery progression.
- **Agent Performance Ranking**: Top performing field officers ranked by volume and transactions.
- **Defaulter & NPA Aging**: Tracks overdue accounts with overdue days counter.
- **Data Export**: Direct CSV streaming of collection logs for external accounting.
