/**
 * FinanceMaster Pro - Interactive Application Scripts
 */

document.addEventListener('DOMContentLoaded', () => {
  initNavigation();
  initDashboardChart();
  initBranchProgress();
  initBranchSwitcher();
  initCollectionTable();
  initReceiptModal();
  initAppTabs();
  initLoanCalculator();
  initFaqAccordion();
  initDemoForm();
  initScrollAnimations();
});

/* --------------------------------------------------------------------------
   1. Navigation, ScrollSpy & Mobile Drawer
   -------------------------------------------------------------------------- */
function initNavigation() {
  const header = document.querySelector('.header-sticky');
  const hamburgerBtn = document.getElementById('hamburgerBtn');
  const mobileDrawer = document.getElementById('mobileDrawer');
  const drawerOverlay = document.getElementById('drawerOverlay');
  const navLinks = document.querySelectorAll('.nav-link');
  const mobileLinks = document.querySelectorAll('.mobile-nav-link');

  // Sticky header background on scroll
  window.addEventListener('scroll', () => {
    if (window.scrollY > 20) {
      header.classList.add('scrolled');
    } else {
      header.classList.remove('scrolled');
    }
    updateActiveNavOnScroll();
  });

  // Mobile menu toggle
  function toggleDrawer() {
    hamburgerBtn.classList.toggle('active');
    mobileDrawer.classList.toggle('open');
    drawerOverlay.classList.toggle('active');
    document.body.style.overflow = mobileDrawer.classList.contains('open') ? 'hidden' : '';
  }

  if (hamburgerBtn) {
    hamburgerBtn.addEventListener('click', toggleDrawer);
  }

  if (drawerOverlay) {
    drawerOverlay.addEventListener('click', toggleDrawer);
  }

  mobileLinks.forEach(link => {
    link.addEventListener('click', () => {
      if (mobileDrawer.classList.contains('open')) {
        toggleDrawer();
      }
    });
  });

  // ScrollSpy function to highlight active link in navbar and drawer
  const trackedSections = document.querySelectorAll('section[id], header[id]');
  
  function updateActiveNavOnScroll() {
    const scrollPos = window.scrollY + 120; // offset for header

    trackedSections.forEach(section => {
      const top = section.offsetTop;
      const height = section.offsetHeight;
      const id = section.getAttribute('id');

      if (scrollPos >= top && scrollPos < top + height) {
        // Desktop nav links
        navLinks.forEach(link => {
          if (link.getAttribute('href') === `#${id}`) {
            link.classList.add('active');
          } else {
            link.classList.remove('active');
          }
        });

        // Mobile drawer links
        mobileLinks.forEach(link => {
          if (link.getAttribute('href') === `#${id}`) {
            link.classList.add('active');
          } else {
            link.classList.remove('active');
          }
        });
      }
    });
  }

  updateActiveNavOnScroll();
}

/* --------------------------------------------------------------------------
   2. Dashboard Interactive SVG Chart
   -------------------------------------------------------------------------- */
const chartWeeklyData = [
  { label: 'Mon', value: 142000 },
  { label: 'Tue', value: 168000 },
  { label: 'Wed', value: 155000 },
  { label: 'Thu', value: 172000 },
  { label: 'Fri', value: 185500 },
  { label: 'Sat', value: 194000 },
  { label: 'Sun', value: 130000 }
];

const chartMonthlyData = [
  { label: 'Week 1', value: 890000 },
  { label: 'Week 2', value: 1040000 },
  { label: 'Week 3', value: 1180000 },
  { label: 'Week 4', value: 1320000 }
];

function initDashboardChart() {
  const chartContainer = document.getElementById('collectionChart');
  const weeklyBtn = document.getElementById('btnChartWeekly');
  const monthlyBtn = document.getElementById('btnChartMonthly');
  
  if (!chartContainer) return;

  function renderChart(data) {
    const width = 600;
    const height = 180;
    const padding = 30;
    
    const maxVal = Math.max(...data.map(d => d.value)) * 1.15;
    const minVal = Math.min(...data.map(d => d.value)) * 0.85;

    const points = data.map((d, i) => {
      const x = padding + (i * (width - 2 * padding)) / (data.length - 1);
      const y = height - padding - ((d.value - minVal) / (maxVal - minVal)) * (height - 2 * padding);
      return { x, y, ...d };
    });

    let pathD = `M ${points[0].x} ${points[0].y}`;
    for (let i = 0; i < points.length - 1; i++) {
      const xMid = (points[i].x + points[i + 1].x) / 2;
      const yMid = (points[i].y + points[i + 1].y) / 2;
      const cpX1 = (xMid + points[i].x) / 2;
      const cpX2 = (xMid + points[i + 1].x) / 2;
      pathD += ` Q ${points[i].x} ${points[i].y}, ${xMid} ${yMid} T ${points[i + 1].x} ${points[i + 1].y}`;
    }

    const areaD = `${pathD} L ${points[points.length - 1].x} ${height - 15} L ${points[0].x} ${height - 15} Z`;

    let circlesSvg = points.map(p => `
      <g class="chart-point-group">
        <circle cx="${p.x}" cy="${p.y}" r="4.5" fill="#38BDF8" stroke="#0B132B" stroke-width="2"/>
        <text x="${p.x}" y="${height - 2}" text-anchor="middle" fill="#94A3B8" font-size="10" font-family="'Inter', sans-serif">${p.label}</text>
        <title>${p.label}: ₹${p.value.toLocaleString('en-IN')}</title>
      </g>
    `).join('');

    chartContainer.innerHTML = `
      <svg viewBox="0 0 ${width} ${height}" class="chart-svg" preserveAspectRatio="none">
        <defs>
          <linearGradient id="chartAreaGrad" x1="0%" y1="0%" x2="0%" y2="100%">
            <stop offset="0%" stop-color="#0EA5E9" stop-opacity="0.35"/>
            <stop offset="100%" stop-color="#2563EB" stop-opacity="0.0"/>
          </linearGradient>
          <linearGradient id="chartLineGrad" x1="0%" y1="0%" x2="100%" y2="0%">
            <stop offset="0%" stop-color="#38BDF8"/>
            <stop offset="50%" stop-color="#2563EB"/>
            <stop offset="100%" stop-color="#06B6D4"/>
          </linearGradient>
        </defs>
        
        <!-- Subtle Horizontal Grid Lines -->
        <line x1="${padding}" y1="${padding}" x2="${width - padding}" y2="${padding}" stroke="rgba(255,255,255,0.06)" stroke-dasharray="3 3"/>
        <line x1="${padding}" y1="${height/2}" x2="${width - padding}" y2="${height/2}" stroke="rgba(255,255,255,0.06)" stroke-dasharray="3 3"/>
        <line x1="${padding}" y1="${height - padding}" x2="${width - padding}" y2="${height - padding}" stroke="rgba(255,255,255,0.08)"/>

        <!-- Gradient Area -->
        <path d="${areaD}" fill="url(#chartAreaGrad)" />
        
        <!-- Smooth Curve Line -->
        <path d="${pathD}" fill="none" stroke="url(#chartLineGrad)" stroke-width="3" stroke-linecap="round" />
        
        <!-- Nodes -->
        ${circlesSvg}
      </svg>
    `;
  }

  renderChart(chartWeeklyData);

  if (weeklyBtn && monthlyBtn) {
    weeklyBtn.addEventListener('click', () => {
      weeklyBtn.classList.add('active');
      monthlyBtn.classList.remove('active');
      renderChart(chartWeeklyData);
    });

    monthlyBtn.addEventListener('click', () => {
      monthlyBtn.classList.add('active');
      weeklyBtn.classList.remove('active');
      renderChart(chartMonthlyData);
    });
  }
}

/* --------------------------------------------------------------------------
   3. Branch Switcher & Progress Bars
   -------------------------------------------------------------------------- */
function initBranchProgress() {
  const branchList = document.getElementById('branchPerformanceList');
  if (!branchList || !window.FM_DATA) return;

  branchList.innerHTML = window.FM_DATA.branchesData.map(b => `
    <div class="progress-item-row">
      <div class="progress-info">
        <span class="progress-name">${b.name}</span>
        <span class="progress-val">${b.collection} <span style="color:#64748B; font-weight:400; font-size:0.75rem;">/ ${b.target} (${b.percentage}%)</span></span>
      </div>
      <div class="progress-track">
        <div class="progress-bar-fill" style="width: ${b.percentage}%"></div>
      </div>
    </div>
  `).join('');
}

function initBranchSwitcher() {
  const chips = document.querySelectorAll('.branch-chip-btn');
  const kpiTotalLoans = document.getElementById('dashKpiTotalLoans');
  const kpiTodayCol = document.getElementById('dashKpiTodayCol');
  const kpiPending = document.getElementById('dashKpiPending');
  const kpiBorrowers = document.getElementById('dashKpiBorrowers');
  const kpiAgents = document.getElementById('dashKpiAgents');
  const kpiBranches = document.getElementById('dashKpiBranches');

  if (!chips.length || !window.FM_DATA) return;

  chips.forEach(chip => {
    chip.addEventListener('click', () => {
      chips.forEach(c => c.classList.remove('active'));
      chip.classList.add('active');
      const branchKey = chip.dataset.branch || 'all';
      const data = window.FM_DATA.branchKpis[branchKey] || window.FM_DATA.branchKpis.all;

      if (kpiTotalLoans) kpiTotalLoans.textContent = data.totalLoans;
      if (kpiTodayCol) kpiTodayCol.textContent = data.todayCollection;
      if (kpiPending) kpiPending.textContent = data.pendingAmount;
      if (kpiBorrowers) kpiBorrowers.textContent = data.activeBorrowers;
      if (kpiAgents) kpiAgents.textContent = data.activeAgents;
      if (kpiBranches) kpiBranches.textContent = data.branches;
    });
  });
}

/* --------------------------------------------------------------------------
   4. Daily Collection Table with Search, Filter & Receipt Modal
   -------------------------------------------------------------------------- */
function initCollectionTable() {
  const tableBody = document.getElementById('collectionTableBody');
  const searchInput = document.getElementById('tableSearch');
  const filterButtons = document.querySelectorAll('.table-filter-btn');

  if (!tableBody || !window.FM_DATA) return;

  let currentFilter = 'all';
  let searchQuery = '';

  function renderTable() {
    const data = window.FM_DATA.collections.filter(item => {
      const matchesFilter = (currentFilter === 'all') || (item.status.toLowerCase() === currentFilter.toLowerCase());
      const query = searchQuery.toLowerCase();
      const matchesSearch = 
        item.borrower.toLowerCase().includes(query) ||
        item.agent.toLowerCase().includes(query) ||
        item.branch.toLowerCase().includes(query) ||
        item.id.toLowerCase().includes(query);
      return matchesFilter && matchesSearch;
    });

    if (data.length === 0) {
      tableBody.innerHTML = `
        <tr>
          <td colspan="6" style="text-align: center; padding: 2.5rem; color: var(--color-slate-400);">
            No collection records matching "<strong>${searchQuery}</strong>" in ${currentFilter} status.
          </td>
        </tr>
      `;
      return;
    }

    tableBody.innerHTML = data.map(item => `
      <tr>
        <td>
          <div class="table-borrower-cell">
            <div class="table-avatar">${item.avatar}</div>
            <div>
              <div class="table-borrower-name">${item.borrower}</div>
              <div class="table-borrower-loan-id">${item.id} • ${item.type}</div>
            </div>
          </div>
        </td>
        <td>
          <strong style="font-family:var(--font-heading); color:var(--color-slate-900);">${item.amount}</strong>
        </td>
        <td>
          <span class="badge ${item.statusBadge}">
            <span class="badge-dot"></span> ${item.status}
          </span>
        </td>
        <td>
          <span style="color:var(--color-slate-600); font-size:0.85rem;">${item.dueDate}</span>
        </td>
        <td>
          <div style="font-weight:600; color:var(--color-slate-800);">${item.agent}</div>
          <div style="font-size:0.75rem; color:var(--color-slate-400);">${item.branch}</div>
        </td>
        <td>
          <button class="btn btn-sm btn-secondary btn-receipt-view" data-record-id="${item.id}">
            Receipt
          </button>
        </td>
      </tr>
    `).join('');

    // Attach receipt modal click handlers
    document.querySelectorAll('.btn-receipt-view').forEach(btn => {
      btn.addEventListener('click', () => {
        const id = btn.dataset.recordId;
        const record = window.FM_DATA.collections.find(c => c.id === id);
        if (record) openReceiptModal(record);
      });
    });
  }

  renderTable();

  if (searchInput) {
    searchInput.addEventListener('input', (e) => {
      searchQuery = e.target.value;
      renderTable();
    });
  }

  filterButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      filterButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentFilter = btn.dataset.filter;
      renderTable();
    });
  });
}

/* --------------------------------------------------------------------------
   5. Digital Receipt Modal Handler
   -------------------------------------------------------------------------- */
function initReceiptModal() {
  const modalOverlay = document.getElementById('receiptModalOverlay');
  const closeBtn = document.getElementById('btnCloseReceiptModal');
  const printBtn = document.getElementById('btnPrintReceipt');

  if (!modalOverlay) return;

  function closeModal() {
    modalOverlay.classList.remove('active');
    document.body.style.overflow = '';
  }

  if (closeBtn) closeBtn.addEventListener('click', closeModal);
  modalOverlay.addEventListener('click', (e) => {
    if (e.target === modalOverlay) closeModal();
  });

  if (printBtn) {
    printBtn.addEventListener('click', () => {
      alert('Receipt sent to Bluetooth Thermal Printer / PDF Download initialized.');
    });
  }
}

function openReceiptModal(record) {
  const modalOverlay = document.getElementById('receiptModalOverlay');
  if (!modalOverlay) return;

  document.getElementById('receiptModalTxnId').textContent = record.txnId || 'TXN-9842109';
  document.getElementById('receiptModalAmount').textContent = record.amount;
  document.getElementById('receiptModalBorrower').textContent = `${record.borrower} (${record.phone})`;
  document.getElementById('receiptModalLoanId').textContent = `${record.id} (${record.type})`;
  document.getElementById('receiptModalAgent').textContent = `${record.agent} (${record.branch})`;
  document.getElementById('receiptModalBalance').textContent = record.balance || '₹5,600';
  document.getElementById('receiptModalDueDate').textContent = record.dueDate;

  modalOverlay.classList.add('active');
  document.body.style.overflow = 'hidden';
}

/* --------------------------------------------------------------------------
   6. Mobile App Triple Mockup Tabs
   -------------------------------------------------------------------------- */
function initAppTabs() {
  const tabButtons = document.querySelectorAll('.app-tab-btn');
  const phoneCards = document.querySelectorAll('.phone-mockup-card');

  if (!tabButtons.length || !phoneCards.length) return;

  tabButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      tabButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      const targetRole = btn.dataset.appRole;

      phoneCards.forEach(card => {
        if (targetRole === 'all' || card.dataset.appRole === targetRole) {
          card.style.display = 'flex';
          card.style.opacity = '1';
          card.style.transform = 'scale(1)';
        } else {
          card.style.display = 'none';
        }
      });
    });
  });
}

/* --------------------------------------------------------------------------
   7. Interactive Loan & Collection Estimator
   -------------------------------------------------------------------------- */
function initLoanCalculator() {
  const principalSlider = document.getElementById('calcPrincipalSlider');
  const principalValDisplay = document.getElementById('calcPrincipalVal');
  const durationSlider = document.getElementById('calcDurationSlider');
  const durationValDisplay = document.getElementById('calcDurationVal');
  const interestSlider = document.getElementById('calcInterestSlider');
  const interestValDisplay = document.getElementById('calcInterestVal');
  const freqButtons = document.querySelectorAll('.freq-btn');

  // Outputs
  const outInstallment = document.getElementById('calcOutInstallment');
  const outInstallmentLabel = document.getElementById('calcOutInstallmentLabel');
  const outTotalRepay = document.getElementById('calcOutTotalRepay');
  const outTotalInterest = document.getElementById('calcOutTotalInterest');
  const outInstallmentCount = document.getElementById('calcOutInstallmentCount');
  const summaryPrincipal = document.getElementById('calcSummaryPrincipal');

  if (!principalSlider) return;

  let currentFrequency = 'daily'; // daily, weekly, monthly

  function calculate() {
    const principal = parseFloat(principalSlider.value);
    const duration = parseInt(durationSlider.value, 10);
    const interestRate = parseFloat(interestSlider.value);

    principalValDisplay.textContent = `₹${principal.toLocaleString('en-IN')}`;
    if (summaryPrincipal) summaryPrincipal.textContent = `₹${principal.toLocaleString('en-IN')}`;
    interestValDisplay.textContent = `${interestRate}%`;

    const totalInterest = Math.round(principal * (interestRate / 100));
    const totalRepayment = principal + totalInterest;

    let installmentCount = duration;
    let label = "Daily Collection";

    if (currentFrequency === 'daily') {
      durationValDisplay.textContent = `${duration} Days`;
      installmentCount = duration;
      label = "Daily Collection Amount";
    } else if (currentFrequency === 'weekly') {
      durationValDisplay.textContent = `${duration} Weeks`;
      installmentCount = duration;
      label = "Weekly Collection Amount";
    } else if (currentFrequency === 'monthly') {
      durationValDisplay.textContent = `${duration} Months`;
      installmentCount = duration;
      label = "Monthly Collection Amount";
    }

    const installmentAmount = Math.ceil(totalRepayment / installmentCount);

    outInstallment.textContent = `₹${installmentAmount.toLocaleString('en-IN')}`;
    outInstallmentLabel.textContent = label;
    outTotalRepay.textContent = `₹${totalRepayment.toLocaleString('en-IN')}`;
    outTotalInterest.textContent = `₹${totalInterest.toLocaleString('en-IN')}`;
    outInstallmentCount.textContent = `${installmentCount} Installments`;
  }

  principalSlider.addEventListener('input', calculate);
  durationSlider.addEventListener('input', calculate);
  interestSlider.addEventListener('input', calculate);

  freqButtons.forEach(btn => {
    btn.addEventListener('click', () => {
      freqButtons.forEach(b => b.classList.remove('active'));
      btn.classList.add('active');
      currentFrequency = btn.dataset.frequency;

      if (currentFrequency === 'daily') {
        durationSlider.min = "10";
        durationSlider.max = "120";
        durationSlider.value = "100";
      } else if (currentFrequency === 'weekly') {
        durationSlider.min = "4";
        durationSlider.max = "52";
        durationSlider.value = "16";
      } else if (currentFrequency === 'monthly') {
        durationSlider.min = "3";
        durationSlider.max = "36";
        durationSlider.value = "12";
      }

      calculate();
    });
  });

  calculate();
}

/* --------------------------------------------------------------------------
   8. Enterprise FAQ Accordion Toggle
   -------------------------------------------------------------------------- */
function initFaqAccordion() {
  const faqItems = document.querySelectorAll('.faq-item');
  if (!faqItems.length) return;

  faqItems.forEach(item => {
    const question = item.querySelector('.faq-question');
    question.addEventListener('click', () => {
      const isOpen = item.classList.contains('open');
      faqItems.forEach(i => i.classList.remove('open'));
      if (!isOpen) {
        item.classList.add('open');
      }
    });
  });
}

/* --------------------------------------------------------------------------
   9. Demo Request Lead Form (Direct Email Dispatch to support@mediawavetech.com)
   -------------------------------------------------------------------------- */
function initDemoForm() {
  const form = document.getElementById('demoLeadForm');
  const successBox = document.getElementById('demoSuccessBox');
  const resetBtn = document.getElementById('btnResetDemoForm');

  if (!form || !successBox) return;

  form.addEventListener('submit', (e) => {
    e.preventDefault();

    const submitBtn = form.querySelector('button[type="submit"]');
    const originalText = submitBtn.innerHTML;

    // Collect Form Data
    const name = document.getElementById('contactName')?.value || 'Prospective Client';
    const company = document.getElementById('companyName')?.value || 'Finance Company';
    const phone = document.getElementById('phoneNumber')?.value || 'Not provided';
    const email = document.getElementById('emailAddress')?.value || 'Not provided';
    const branches = document.getElementById('branchCount')?.value || '1 Branch';
    const agents = document.getElementById('agentCount')?.value || '1-5 Agents';
    const message = document.getElementById('messageText')?.value || '';

    submitBtn.innerHTML = `
      <svg class="animate-spin" width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" style="display:inline-block; vertical-align:middle; margin-right:8px;">
        <circle cx="12" cy="12" r="10" stroke-opacity="0.25"></circle>
        <path d="M12 2a10 10 0 0 1 10 10" stroke-linecap="round"></path>
      </svg> Sending Demo Request...
    `;
    submitBtn.disabled = true;

    // Dispatch Email directly to support@mediawavetech.com via FormSubmit.co
    fetch('https://formsubmit.co/ajax/support@mediawavetech.com', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      },
      body: JSON.stringify({
        _subject: `New FinanceMaster Pro Demo Request from ${company} (${name})`,
        _template: "table",
        _captcha: "false",
        "Customer Name": name,
        "Company Name": company,
        "Phone / WhatsApp": phone,
        "Email Address": email,
        "Total Branches": branches,
        "Field Agents": agents,
        "Message & Needs": message || "Interested in a live FinanceMaster Pro software demo."
      })
    })
    .then(res => res.json())
    .then(data => {
      console.log('Demo request sent successfully:', data);
      form.style.display = 'none';
      successBox.classList.add('show');
    })
    .catch(err => {
      console.warn('Form dispatch notice:', err);
      form.style.display = 'none';
      successBox.classList.add('show');
    })
    .finally(() => {
      submitBtn.innerHTML = originalText;
      submitBtn.disabled = false;
    });
  });

  if (resetBtn) {
    resetBtn.addEventListener('click', () => {
      form.reset();
      form.style.display = 'flex';
      successBox.classList.remove('show');
    });
  }
}

/* --------------------------------------------------------------------------
   10. Scroll Reveal Observer
   -------------------------------------------------------------------------- */
function initScrollAnimations() {
  const elements = document.querySelectorAll('.reveal-init');
  
  if (!elements.length || !('IntersectionObserver' in window)) {
    elements.forEach(el => el.classList.add('revealed'));
    return;
  }

  const observer = new IntersectionObserver((entries, obs) => {
    entries.forEach(entry => {
      if (entry.isIntersecting) {
        entry.target.classList.add('revealed');
        obs.unobserve(entry.target);
      }
    });
  }, {
    threshold: 0.12,
    rootMargin: '0px 0px -30px 0px'
  });

  elements.forEach(el => observer.observe(el));
}
