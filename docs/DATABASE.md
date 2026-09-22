# Database Schema & Indexing Strategy

This application uses **MongoDB** via **Mongoose** with strict schema definitions, compound indexes, and multi-tenant isolation.

---

## 1. Primary Collections

### `superadmins`
Stores platform-level super administrators.
- `_id`: ObjectId
- `name`: String
- `email`: String (Unique index)
- `password`: String (Bcrypt hashed, select: false)
- `phone`: String
- `isActive`: Boolean
- `lastLogin`: Date

---

### `companies` (Tenants)
Represents independent finance companies.
- `_id`: ObjectId
- `companyCode`: String (Unique index, e.g. "APEX")
- `name`: String
- `logo`: String URL
- `email`, `phone`: String
- `address`: { street, city, state, pincode, country }
- `currency`: { code, symbol }
- `timezone`: String (Default "Asia/Kolkata")
- `workingDays`: [String]
- `subscriptionId`: ObjectId -> `Subscription`
- `status`: Enum `['ACTIVE', 'INACTIVE', 'SUSPENDED']`

---

### `users`
Unified authentication for Company Admins, Managers, Agents, Staff, and Customers.
- `_id`: ObjectId
- `companyId`: ObjectId -> `Company` (Indexed)
- `branchId`: ObjectId -> `Branch`
- `name`: String
- `email`: String
- `password`: String (Hashed)
- `phone`: String
- `role`: Enum `['SUPER_ADMIN', 'COMPANY_ADMIN', 'MANAGER', 'AGENT', 'STAFF', 'CUSTOMER']`
- `customPermissions`: [String]
- `status`: Enum `['ACTIVE', 'INACTIVE', 'SUSPENDED']`

**Compound Indexes:**
- `{ companyId: 1, email: 1 }` (Unique)
- `{ companyId: 1, phone: 1 }`
- `{ companyId: 1, role: 1, status: 1 }`

---

### `branches`
Company operational branches.
- `_id`: ObjectId
- `companyId`: ObjectId -> `Company`
- `branchCode`: String
- `name`: String
- `managerId`: ObjectId -> `User`
- `status`: Enum `['ACTIVE', 'INACTIVE']`

---

### `agents`
Collection field officers.
- `_id`: ObjectId
- `companyId`: ObjectId -> `Company`
- `userId`: ObjectId -> `User`
- `branchId`: ObjectId -> `Branch`
- `agentCode`: String (e.g. "AGT-1001")
- `assignedRoutes`: [String]
- `dailyTarget`: Number
- `commissionPercentage`: Number
- `totalCollected`: Number

---

### `customers`
Borrowers and clients.
- `_id`: ObjectId
- `companyId`: ObjectId -> `Company`
- `assignedAgentId`: ObjectId -> `Agent`
- `customerCode`: String (e.g. "CUST-00001")
- `name`: String
- `phone`: String
- `address`: { street, city, state, pincode, routeArea, latitude, longitude }
- `guarantor`: { name, phone, relation, address }
- `identityProof`: { idType, idNumber }
- `creditLimit`: Number
- `totalActiveLoans`: Number
- `totalPaidAmount`: Number
- `totalOutstandingAmount`: Number
- `status`: Enum `['ACTIVE', 'INACTIVE', 'BLOCKED']`

**Compound Indexes:**
- `{ companyId: 1, customerCode: 1 }` (Unique)
- `{ companyId: 1, phone: 1 }`
- `{ companyId: 1, assignedAgentId: 1, status: 1 }`
- `{ companyId: 1, 'address.routeArea': 1 }`

---

### `financeproducts`
Configurable finance schemes (Daily, Weekly, Monthly).
- `_id`: ObjectId
- `companyId`: ObjectId -> `Company`
- `productCode`: String
- `name`: String
- `frequency`: Enum `['DAILY', 'WEEKLY', 'MONTHLY', 'CUSTOM']`
- `calculationType`: Enum `['FLAT_INTEREST', 'DOCUMENTATION_FEE_DEDUCTION', 'REDUCING_BALANCE', 'FIXED_INSTALLMENT']`
- `minAmount`, `maxAmount`: Number
- `defaultInstallments`: Number (e.g. 100)
- `interestPercentage`: Number
- `docChargePercentage`: Number
- `deductChargesUpfront`: Boolean

---

### `financeaccounts`
Active and completed finance loans.
- `_id`: ObjectId
- `companyId`: ObjectId -> `Company`
- `accountNumber`: String (e.g. "FIN-2026-00001")
- `customerId`: ObjectId -> `Customer`
- `agentId`: ObjectId -> `Agent`
- `productId`: ObjectId -> `FinanceProduct`
- `frequency`: Enum `['DAILY', 'WEEKLY', 'MONTHLY', 'CUSTOM']`
- `principalAmount`: Number
- `netDisbursedAmount`: Number
- `totalPayableAmount`: Number
- `installmentAmount`: Number
- `totalInstallments`: Number
- `paidInstallments`: Number
- `totalPaidAmount`: Number
- `remainingAmount`: Number
- `startDate`, `endDate`, `nextDueDate`: Date
- `status`: Enum `['PENDING', 'ACTIVE', 'OVERDUE', 'COMPLETED', 'CANCELLED', 'PAUSED']`

**Compound Indexes:**
- `{ companyId: 1, accountNumber: 1 }` (Unique)
- `{ companyId: 1, customerId: 1, status: 1 }`
- `{ companyId: 1, nextDueDate: 1, status: 1 }`

---

### `installments`
Payment schedule records per finance account.
- `_id`: ObjectId
- `companyId`: ObjectId
- `financeAccountId`: ObjectId
- `customerId`: ObjectId
- `installmentNumber`: Number (1..N)
- `dueDate`: Date
- `expectedAmount`: Number
- `paidAmount`: Number
- `remainingAmount`: Number
- `status`: Enum `['UPCOMING', 'DUE', 'PARTIALLY_PAID', 'PAID', 'OVERDUE', 'WAIVED']`

---

### `payments`
Collection transaction records.
- `_id`: ObjectId
- `companyId`: ObjectId
- `paymentNumber`: String
- `receiptNumber`: String
- `financeAccountId`: ObjectId
- `customerId`: ObjectId
- `agentId`: ObjectId
- `amount`: Number
- `penaltyCollected`: Number
- `paymentMethod`: Enum `['CASH', 'UPI', 'BANK_TRANSFER', 'CARD', 'OTHER']`
- `paymentDate`: Date
- `status`: Enum `['SUCCESS', 'PENDING', 'FAILED', 'REVERSED', 'CANCELLED']`
- `idempotencyKey`: String (Sparse index)

---

### `receipts`
Snapshot records for thermal receipts and WhatsApp sharing.
- `_id`: ObjectId
- `receiptNumber`: String (Unique per company)
- `paymentId`: ObjectId
- `customerName`, `customerPhone`, `customerCode`: String
- `accountNumber`: String
- `agentName`: String
- `amountPaid`, `previousBalance`, `remainingBalance`: Number
- `formattedWhatsAppMessage`: String
- `status`: Enum `['ISSUED', 'CANCELLED']`

---

### `auditlogs`
Immutable system audit trails.
- `companyId`: ObjectId (or null for platform)
- `userId`: ObjectId
- `userName`, `userRole`: String
- `action`, `module`, `recordId`: String
- `ipAddress`, `userAgent`: String
- `metadata`: Mixed
- `createdAt`: Date (updatedAt disabled)
