# Full-Stack Multi-Tenant Finance Management SaaS

[![Node.js](https://img.shields.io/badge/Node.js-v18+-green.svg)](https://nodejs.org)
[![Flutter](https://img.shields.io/badge/Flutter-v3.20+-blue.svg)](https://flutter.dev)
[![MongoDB](https://img.shields.io/badge/MongoDB-v6.0+-brightgreen.svg)](https://www.mongodb.com)
[![License](https://img.shields.io/badge/License-Commercial%20SaaS-indigo.svg)](#)

A production-grade, multi-tenant Finance Management SaaS platform tailored for microfinance institutions, daily collection money lenders, and installment lending companies operating on **Daily**, **Weekly**, and **Monthly** schedules.

---

## 🌟 Key Highlights & Capabilities

- **Strict Multi-Tenancy**: Zero cross-tenant data leaks. Enforced at MongoDB schema, JWT middleware, service, and controller layers.
- **Configurable Loan Schemes ("Giving")**:
  - **Daily Finance** (e.g. 100-day or 50-day loans with upfront doc charge deduction)
  - **Weekly Finance** (e.g. 10-week or 12-week commercial loans)
  - **Monthly Finance** (e.g. 12-month EMI schemes)
  - Configurable interest calculations, grace periods, and Sunday/holiday exclusions.
- **High-Speed Field Collection System ("Collecting")**:
  - Field agent **Quick-Pad** for mobile & tablet with 1-tap `[1x Due]`, `[2x Due]`, `[Full Balance]` buttons.
  - Route/Line filtering (e.g. "Line 1 - Wholesale Market", "Line 2 - Station Road").
  - Instant digital receipt snapshot with 1-click **WhatsApp Share Link** (`wa.me/?text=...`).
- **Atomic Financial Transactions**:
  - FIFO sequential installment settlement with idempotency safeguards.
- **Dynamic Analytics & Risk Management**:
  - Real-time recovery rates (Expected vs Collected today), 7-day trend chart, agent performance rankings, and Defaulter/NPA overdue aging reports.
  - CSV export stream.
- **Cross-Platform Flutter Client**:
  - **Flutter Web**: Executive dashboard & administrative console for Super Admins, Company Admins, and Managers.
  - **Flutter Mobile**: Ultra-fast collection pad for field collection officers.

---

## 📂 Project Structure

```
├── backend/                       # Node.js + Express + MongoDB REST API
│   ├── src/
│   │   ├── config/                # Database, environment, roles & permissions
│   │   ├── constants/             # Enums, status codes, financial constants
│   │   ├── controllers/           # Auth, SuperAdmin, Company, Customer, Loan, Collection, Reports
│   │   ├── middlewares/           # JWT Auth, Tenant isolation, RBAC, Validation, Rate Limiter
│   │   ├── models/                # 21+ Mongoose multi-tenant schemas
│   │   ├── routes/                # Modular API v1 router
│   │   ├── scripts/               # Super admin seed, demo tenant seed, and end-to-end tests
│   │   ├── services/              # Collection transaction engine, Finance calculator, Reports
│   │   ├── validators/            # Joi payload validation schemas
│   │   ├── app.js                 # Express application pipeline
│   │   └── server.js              # Server entrypoint with graceful shutdown
│   ├── package.json
│   └── .env.example
├── frontend/                      # Flutter Web & Mobile Application
│   ├── lib/
│   │   ├── core/                  # ApiClient (Dio), Storage, AppTheme, Formatters, Widgets
│   │   ├── features/              # Auth, Layout, Dashboard, Customers, Loans, Collections, Reports
│   │   └── main.dart              # Flutter entrypoint with role-based routing
│   └── pubspec.yaml
├── docs/                          # Comprehensive Technical Documentation
│   ├── ARCHITECTURE.md
│   ├── DATABASE.md
│   ├── API_DOCUMENTATION.md
│   ├── SETUP.md
│   ├── DEPLOYMENT.md
│   ├── SECURITY.md
│   ├── ENVIRONMENT.md
│   ├── USER_ROLES.md
│   └── FEATURES.md
├── .env.example
└── README.md
```

---

## 🚀 Quick Start

### 1. Start the Backend API
```bash
cd backend
npm install
npm run seed:super-admin     # Create initial Super Admin and subscription plans
npm run seed:demo            # (Optional) Seed realistic demo company (APEX Microfinance)
npm test                     # Run 10/10 end-to-end API test assertions
npm start                    # Starts on http://localhost:5000/api/v1
```

### 2. Start the Flutter Web Application
```bash
cd frontend
flutter pub get
flutter run -d chrome
```

---

## 🔑 Default Seeded Credentials

| Role | Email | Password | Tenant Code |
|---|---|---|---|
| **Super Admin** | `superadmin@financesaas.com` | `SuperAdmin@2026!` | *Global* |
| **Company Admin** | `admin@apexfinance.com` | `ApexAdmin@2026!` | `APEX` |
| **Collection Agent** | `rajesh.agent@apexfinance.com` | `Agent@2026!` | `APEX` |

---

## 📖 Complete Documentation
For full architectural details, database schemas, and API documentation, please explore the [`/docs`](file:///d:/MediaWaveTech/FINANCE%20COLLECTION%20SaaS/docs/README.md) directory.
