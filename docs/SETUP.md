# Project Setup Guide

Follow this guide to configure and run the **Full-Stack Multi-Tenant Finance Management SaaS** locally.

---

## 1. Prerequisites
- **Node.js**: v18.0.0 or higher
- **npm**: v9.0.0 or higher
- **Flutter SDK**: 3.20.0 or higher (Web & Android enabled)
- **MongoDB**: Local MongoDB instance (default port 27017) or MongoDB Atlas connection string. (Note: In development, if no MongoDB is active, an embedded in-memory MongoDB will automatically start).

---

## 2. Backend Setup

1. **Navigate to the Backend Directory**:
```bash
cd backend
```

2. **Install Node Dependencies**:
```bash
npm install
```

3. **Configure Environment Variables**:
Copy the sample environment file:
```bash
cp .env.example .env
```
Ensure your `.env` contains:
```env
PORT=5000
MONGODB_URI=mongodb://127.0.0.1:27017/finance_saas_db
JWT_SECRET=super_secret_production_jwt_key_finance_saas_2026_x89a0f
SUPER_ADMIN_EMAIL=superadmin@financesaas.com
SUPER_ADMIN_PASSWORD=SuperAdmin@2026!
```

4. **Bootstrap Super Admin Account & Subscription Plans**:
```bash
npm run seed:super-admin
```

5. **(Optional) Seed Realistic Demo Tenant (APEX Microfinance)**:
```bash
npm run seed:demo
```

6. **Run End-to-End API Test Suite**:
```bash
npm test
```

7. **Start Backend Server**:
```bash
npm start
# Server starts on http://localhost:5000/api/v1
```

---

## 3. Frontend (Flutter) Setup

1. **Navigate to the Frontend Directory**:
```bash
cd ../frontend
```

2. **Get Flutter Packages**:
```bash
flutter pub get
```

3. **Run Flutter Web Application**:
```bash
flutter run -d chrome
```

4. **Run Flutter Android Application**:
```bash
flutter run -d android
```

---

## 4. Default Seeded Credentials for Testing

| Role | Email | Password | Tenant Code |
|---|---|---|---|
| **Super Admin** | `superadmin@financesaas.com` | `SuperAdmin@2026!` | *Global* |
| **Company Admin** | `admin@apexfinance.com` | `ApexAdmin@2026!` | `APEX` |
| **Field Agent 1** | `rajesh.agent@apexfinance.com` | `Agent@2026!` | `APEX` |
| **Field Agent 2** | `priya.agent@apexfinance.com` | `Agent@2026!` | `APEX` |
