/**
 * FinanceMaster Pro - Realistic Demo & Simulation Data
 */

window.FM_DATA = {
  // Exact required KPI numbers (All Branches baseline)
  kpis: {
    totalLoans: "₹24,50,000",
    todayCollection: "₹1,85,500",
    pendingAmount: "₹3,25,000",
    activeBorrowers: "1,248",
    activeAgents: "42",
    branches: "8"
  },

  // Branch-specific dataset for interactive switcher
  branchKpis: {
    all: {
      totalLoans: "₹24,50,000",
      todayCollection: "₹1,85,500",
      pendingAmount: "₹3,25,000",
      activeBorrowers: "1,248",
      activeAgents: "42",
      branches: "8"
    },
    central: {
      totalLoans: "₹8,40,000",
      todayCollection: "₹52,400",
      pendingAmount: "₹68,000",
      activeBorrowers: "390",
      activeAgents: "12",
      branches: "Central HQ"
    },
    north: {
      totalLoans: "₹6,80,000",
      todayCollection: "₹41,200",
      pendingAmount: "₹54,000",
      activeBorrowers: "310",
      activeAgents: "10",
      branches: "North Hub"
    },
    east: {
      totalLoans: "₹5,20,000",
      todayCollection: "₹38,900",
      pendingAmount: "₹72,000",
      activeBorrowers: "285",
      activeAgents: "9",
      branches: "East Zone"
    },
    south: {
      totalLoans: "₹4,10,000",
      todayCollection: "₹32,600",
      pendingAmount: "₹45,000",
      activeBorrowers: "263",
      activeAgents: "8",
      branches: "South Ext"
    }
  },

  // Daily Collections Table Records
  collections: [
    {
      id: "LN-84920",
      borrower: "Rajesh Kumar",
      phone: "+91 98450 12345",
      type: "Daily Finance",
      amount: "₹1,200",
      rawAmount: 1200,
      totalLoan: "₹20,000",
      paidSoFar: "₹14,400",
      balance: "₹5,600",
      status: "Paid",
      statusBadge: "badge-success",
      dueDate: "Today, 11:30 AM",
      agent: "Vikram Sharma",
      branch: "North City Hub",
      avatar: "RK",
      txnId: "TXN-9842109"
    },
    {
      id: "LN-84921",
      borrower: "Ananya Deshmukh",
      phone: "+91 98765 43210",
      type: "Weekly Finance",
      amount: "₹4,500",
      rawAmount: 4500,
      totalLoan: "₹45,000",
      paidSoFar: "₹31,500",
      balance: "₹13,500",
      status: "Paid",
      statusBadge: "badge-success",
      dueDate: "Today, 12:15 PM",
      agent: "Suresh Patil",
      branch: "Central Market HQ",
      avatar: "AD",
      txnId: "TXN-9842110"
    },
    {
      id: "LN-84922",
      borrower: "Meenakshi Sundaram",
      phone: "+91 94432 10987",
      type: "Daily Finance",
      amount: "₹850",
      rawAmount: 850,
      totalLoan: "₹15,000",
      paidSoFar: "₹8,500",
      balance: "₹6,500",
      status: "Pending",
      statusBadge: "badge-warning",
      dueDate: "Today, 03:00 PM",
      agent: "Vikram Sharma",
      branch: "North City Hub",
      avatar: "MS",
      txnId: "TXN-9842111"
    },
    {
      id: "LN-84923",
      borrower: "Gopal Krishna Rao",
      phone: "+91 91234 56789",
      type: "Monthly Finance",
      amount: "₹12,000",
      rawAmount: 12000,
      totalLoan: "₹1,20,000",
      paidSoFar: "₹72,000",
      balance: "₹48,000",
      status: "Overdue",
      statusBadge: "badge-danger",
      dueDate: "Yesterday",
      agent: "Ramesh Reddy",
      branch: "South Ext Branch",
      avatar: "GK",
      txnId: "TXN-9842112"
    },
    {
      id: "LN-84924",
      borrower: "Pooja Verma",
      phone: "+91 99887 76655",
      type: "Daily Finance",
      amount: "₹1,500",
      rawAmount: 1500,
      totalLoan: "₹25,000",
      paidSoFar: "₹18,000",
      balance: "₹7,000",
      status: "Paid",
      statusBadge: "badge-success",
      dueDate: "Today, 01:45 PM",
      agent: "Manoj Singh",
      branch: "East Zone",
      avatar: "PV",
      txnId: "TXN-9842113"
    },
    {
      id: "LN-84925",
      borrower: "Arunachalam S.",
      phone: "+91 97654 32190",
      type: "Daily Finance",
      amount: "₹950",
      rawAmount: 950,
      totalLoan: "₹18,000",
      paidSoFar: "₹11,400",
      balance: "₹6,600",
      status: "Pending",
      statusBadge: "badge-warning",
      dueDate: "Today, 04:30 PM",
      agent: "Suresh Patil",
      branch: "Central Market HQ",
      avatar: "AS",
      txnId: "TXN-9842114"
    },
    {
      id: "LN-84926",
      borrower: "Kavitha R.",
      phone: "+91 94455 66778",
      type: "Weekly Finance",
      amount: "₹3,200",
      rawAmount: 3200,
      totalLoan: "₹32,000",
      paidSoFar: "₹25,600",
      balance: "₹6,400",
      status: "Paid",
      statusBadge: "badge-success",
      dueDate: "Today, 10:00 AM",
      agent: "Ramesh Reddy",
      branch: "South Ext Branch",
      avatar: "KR",
      txnId: "TXN-9842115"
    }
  ],

  // Branch Performance
  branchesData: [
    { name: "Central Market Branch", collection: "₹52,400", target: "₹60,000", percentage: 87 },
    { name: "North City Hub", collection: "₹41,200", target: "₹45,000", percentage: 91 },
    { name: "East Industrial Zone", collection: "₹38,900", target: "₹45,000", percentage: 86 },
    { name: "South Extension", collection: "₹32,600", target: "₹40,000", percentage: 81 },
    { name: "West Gate Plaza", collection: "₹20,400", target: "₹25,000", percentage: 82 }
  ],

  // Top Performing Field Agents
  agentLeaderboard: [
    { name: "Vikram Sharma", branch: "North City Hub", collected: "₹34,800", count: "38 Collections", rate: "98%" },
    { name: "Suresh Patil", branch: "Central Market", collected: "₹31,500", count: "32 Collections", rate: "95%" },
    { name: "Manoj Singh", branch: "East Zone", collected: "₹28,200", count: "29 Collections", rate: "93%" },
    { name: "Ramesh Reddy", branch: "South Ext", collected: "₹24,600", count: "25 Collections", rate: "91%" }
  ]
};
