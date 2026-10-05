/* ============================================================
   EduRiskVision — js/app.js
   Application Controller, Reactive State Management & UI Binding
   ============================================================ */

document.addEventListener('DOMContentLoaded', function() {

  // Safety check on data bundle
  if (!window.EDURISK_DATA) {
    console.error("EduRiskVision Data Bundle missing!");
    return;
  }

  const DATA = window.EDURISK_DATA;
  const allStudents = DATA.students;

  // Application State
  const state = {
    currentTab: 'overview',
    filters: {
      dept: 'All',
      semester: 'All',
      risk: 'All'
    },
    searchQuery: '',
    sortKey: 'risk_score',
    sortAsc: true,
    page: 1,
    pageSize: 15,
    selectedStudent: null,
    theme: localStorage.getItem('edurisk_theme') || 'dark'
  };

  // Set Initial Theme
  document.documentElement.setAttribute('data-theme', state.theme);

  // ── 1. DOM Elements ─────────────────────────────────────────
  const navItems = document.querySelectorAll('.nav-item');
  const tabPanes = document.querySelectorAll('.tab-pane');
  const currentTabBreadcrumb = document.getElementById('currentTabBreadcrumb');

  const deptFilter = document.getElementById('deptFilter');
  const semFilter = document.getElementById('semFilter');
  const riskFilter = document.getElementById('riskFilter');
  const resetFiltersBtn = document.getElementById('resetFiltersBtn');
  const filteredCountEl = document.getElementById('filteredCount');

  // KPI Elements
  const kpiTotalEl = document.getElementById('kpiTotal');
  const kpiLowEl = document.getElementById('kpiLow');
  const kpiMedEl = document.getElementById('kpiMed');
  const kpiHighEl = document.getElementById('kpiHigh');
  const kpiLowPctEl = document.getElementById('kpiLowPct');
  const kpiMedPctEl = document.getElementById('kpiMedPct');
  const kpiHighPctEl = document.getElementById('kpiHighPct');

  // Student Table Elements
  const searchInput = document.getElementById('studentSearchInput');
  const studentTableBody = document.getElementById('studentTableBody');
  const paginationControls = document.getElementById('paginationControls');
  const tableShowingInfo = document.getElementById('tableShowingInfo');

  // Modal Elements
  const studentModal = document.getElementById('studentModal');
  const modalCloseBtn = document.getElementById('modalCloseBtn');
  const modalStudentId = document.getElementById('modalStudentId');
  const modalBodyContent = document.getElementById('modalBodyContent');

  // Predictor Inputs
  const pAtt = document.getElementById('p_att');
  const pMarks = document.getElementById('p_marks');
  const pAssign = document.getElementById('p_assign');
  const pLms = document.getElementById('p_lms');
  const pGpa = document.getElementById('p_gpa');
  const pBacklogs = document.getElementById('p_backlogs');
  const pLab = document.getElementById('p_lab');

  // Predictor Outputs
  const predScoreVal = document.getElementById('predScoreVal');
  const predTierBadge = document.getElementById('predTierBadge');
  const probLowFill = document.getElementById('probLowFill');
  const probMedFill = document.getElementById('probMedFill');
  const probHighFill = document.getElementById('probHighFill');
  const probLowPct = document.getElementById('probLowPct');
  const probMedPct = document.getElementById('probMedPct');
  const probHighPct = document.getElementById('probHighPct');
  const interventionList = document.getElementById('interventionList');

  // Action Buttons
  const exportCsvBtn = document.getElementById('exportCsvBtn');
  const printReportBtn = document.getElementById('printReportBtn');
  const themeToggleBtn = document.getElementById('themeToggleBtn');
  const mobileMenuToggle = document.getElementById('mobileMenuToggle');
  const sidebar = document.getElementById('sidebar');

  // ── 2. Filter & Data Processing ──────────────────────────────
  function getFilteredStudents() {
    return allStudents.filter(s => {
      if (state.filters.dept !== 'All' && s.department !== state.filters.dept) return false;
      if (state.filters.semester !== 'All' && s.semester !== parseInt(state.filters.semester, 10)) return false;
      if (state.filters.risk !== 'All' && s.risk_category !== state.filters.risk) return false;
      if (state.searchQuery) {
        const q = state.searchQuery.toLowerCase();
        const matchId = s.student_id.toLowerCase().includes(q);
        const matchDept = s.department.toLowerCase().includes(q);
        const matchTier = s.risk_category.toLowerCase().includes(q);
        if (!matchId && !matchDept && !matchTier) return false;
      }
      return true;
    });
  }

  function getSortedStudents(students) {
    return [...students].sort((a, b) => {
      let valA = a[state.sortKey];
      let valB = b[state.sortKey];

      if (typeof valA === 'string') {
        return state.sortAsc ? valA.localeCompare(valB) : valB.localeCompare(valA);
      }
      return state.sortAsc ? valA - valB : valB - valA;
    });
  }

  // ── 3. Update UI Views & KPIs ───────────────────────────────
  function refreshDashboard() {
    const filtered = getFilteredStudents();

    // 1. Update KPI Value Cards
    const total = filtered.length;
    const low = filtered.filter(s => s.risk_category === 'Low_Risk').length;
    const med = filtered.filter(s => s.risk_category === 'Medium_Risk').length;
    const high = filtered.filter(s => s.risk_category === 'High_Risk').length;

    kpiTotalEl.textContent = total;
    kpiLowEl.textContent = low;
    kpiMedEl.textContent = med;
    kpiHighEl.textContent = high;

    kpiLowPctEl.textContent = total ? `${((low / total) * 100).toFixed(1)}%` : '0%';
    kpiMedPctEl.textContent = total ? `${((med / total) * 100).toFixed(1)}%` : '0%';
    kpiHighPctEl.textContent = total ? `${((high / total) * 100).toFixed(1)}%` : '0%';

    filteredCountEl.textContent = total;

    // 2. Refresh Active Tab Visualizations
    if (state.currentTab === 'overview') {
      EduRiskCharts.renderRiskDistribution(filtered);
      EduRiskCharts.renderDeptRiskBreakdown(filtered);
      EduRiskCharts.renderAttendanceVsMarks(filtered);
    } else if (state.currentTab === 'students') {
      renderStudentTable(filtered);
    } else if (state.currentTab === 'analytics') {
      EduRiskCharts.renderAnalyticsMetrics(filtered);
      EduRiskCharts.renderCorrelationHeatmap(DATA.corrMatrix);
    } else if (state.currentTab === 'models') {
      EduRiskCharts.renderModelComparison(DATA.modelMetrics.comparison);
      EduRiskCharts.renderFeatureImportance(DATA.modelMetrics.featureImportance);
      EduRiskCharts.renderConfusionMatrix(DATA.modelMetrics.confusionMatrix);
    } else if (state.currentTab === 'alerts') {
      renderAlertsTables(filtered);
    }
  }

  // ── 4. Student Table Renderer ────────────────────────────────
  function renderStudentTable(students) {
    const sorted = getSortedStudents(students);
    const total = sorted.length;
    const startIdx = (state.page - 1) * state.pageSize;
    const endIdx = Math.min(startIdx + state.pageSize, total);
    const paged = sorted.slice(startIdx, endIdx);

    tableShowingInfo.textContent = total
      ? `Showing ${startIdx + 1}–${endIdx} of ${total} students`
      : 'No matching records found';

    if (paged.length === 0) {
      studentTableBody.innerHTML = `
        <tr>
          <td colspan="9" style="text-align:center; padding: 2.5rem; color: var(--text-muted);">
            <i class="ri-search-line" style="font-size: 2rem; display:block; margin-bottom: 0.5rem; color: var(--accent-teal);"></i>
            No students found matching your criteria.
          </td>
        </tr>
      `;
      paginationControls.innerHTML = '';
      return;
    }

    studentTableBody.innerHTML = paged.map(s => {
      let badgeClass = 'badge-low';
      let tierLabel = 'Low Risk';
      if (s.risk_category === 'High_Risk') {
        badgeClass = 'badge-high';
        tierLabel = 'High Risk';
      } else if (s.risk_category === 'Medium_Risk') {
        badgeClass = 'badge-medium';
        tierLabel = 'Medium Risk';
      }

      return `
        <tr data-id="${s.student_id}">
          <td class="student-id-cell">${s.student_id}</td>
          <td><strong>${s.department}</strong></td>
          <td>Sem ${s.semester}</td>
          <td>
            <span style="color: ${s.attendance < 75 ? 'var(--risk-high)' : 'inherit'}; font-weight: ${s.attendance < 75 ? '700' : '500'};">
              ${s.attendance}%
            </span>
          </td>
          <td>${s.internal_marks}/100</td>
          <td>${s.prev_gpa.toFixed(2)}</td>
          <td>
            ${s.backlogs > 0
              ? `<span style="color:var(--risk-high); font-weight:700;">${s.backlogs}</span>`
              : `<span style="color:var(--text-muted);">0</span>`}
          </td>
          <td>
            <span class="badge ${badgeClass}">
              <span class="badge-dot"></span>
              ${tierLabel} (${s.risk_score})
            </span>
          </td>
          <td>
            <button class="btn btn-outline view-profile-btn" style="padding: 0.3rem 0.75rem; font-size: 0.78rem;" data-id="${s.student_id}">
              <i class="ri-eye-line"></i> View
            </button>
          </td>
        </tr>
      `;
    }).join('');

    // Bind View Profile buttons
    document.querySelectorAll('.view-profile-btn').forEach(btn => {
      btn.addEventListener('click', (e) => {
        e.stopPropagation();
        openStudentModal(btn.getAttribute('data-id'));
      });
    });

    renderPagination(total);
  }

  function renderPagination(totalItems) {
    const totalPages = Math.ceil(totalItems / state.pageSize);
    if (totalPages <= 1) {
      paginationControls.innerHTML = '';
      return;
    }

    let html = `
      <button class="page-btn" id="prevPageBtn" ${state.page === 1 ? 'disabled' : ''}>
        <i class="ri-arrow-left-s-line"></i>
      </button>
    `;

    for (let p = 1; p <= totalPages; p++) {
      if (p === 1 || p === totalPages || (p >= state.page - 1 && p <= state.page + 1)) {
        html += `<button class="page-btn ${p === state.page ? 'active' : ''}" data-page="${p}">${p}</button>`;
      } else if (p === state.page - 2 || p === state.page + 2) {
        html += `<span style="padding: 0 4px; color: var(--text-muted);">…</span>`;
      }
    }

    html += `
      <button class="page-btn" id="nextPageBtn" ${state.page === totalPages ? 'disabled' : ''}>
        <i class="ri-arrow-right-s-line"></i>
      </button>
    `;

    paginationControls.innerHTML = html;

    // Attach listeners
    paginationControls.querySelectorAll('.page-btn[data-page]').forEach(btn => {
      btn.addEventListener('click', () => {
        state.page = parseInt(btn.getAttribute('data-page'), 10);
        renderStudentTable(getFilteredStudents());
      });
    });

    const prev = document.getElementById('prevPageBtn');
    if (prev) {
      prev.addEventListener('click', () => {
        if (state.page > 1) {
          state.page--;
          renderStudentTable(getFilteredStudents());
        }
      });
    }

    const next = document.getElementById('nextPageBtn');
    if (next) {
      next.addEventListener('click', () => {
        if (state.page < totalPages) {
          state.page++;
          renderStudentTable(getFilteredStudents());
        }
      });
    }
  }

  // ── 5. Student Diagnostic 360° Modal ─────────────────────────
  function openStudentModal(studentId) {
    const s = allStudents.find(x => x.student_id === studentId);
    if (!s) return;

    modalStudentId.textContent = `${s.student_id} — ${s.department} (Sem ${s.semester})`;

    let badgeClass = s.risk_category === 'High_Risk' ? 'badge-high' : (s.risk_category === 'Medium_Risk' ? 'badge-medium' : 'badge-low');
    let tierLabel = s.risk_category === 'High_Risk' ? 'High Risk' : (s.risk_category === 'Medium_Risk' ? 'Medium Risk' : 'Low Risk');

    const prediction = RiskPredictor.calculateRiskScore(s);

    modalBodyContent.innerHTML = `
      <div style="display:flex; align-items:center; justify-content:space-between; margin-bottom: 1.5rem; background: var(--bg-card); padding: 1.25rem; border-radius: var(--radius-sm); border: 1px solid var(--border-card);">
        <div>
          <div style="font-size: 0.8rem; color: var(--text-muted); text-transform: uppercase;">Current Academic Standing</div>
          <div style="font-size: 1.6rem; font-weight: 800; color: var(--text-primary); margin-top: 0.2rem;">
            Risk Score: ${s.risk_score} / 100
          </div>
        </div>
        <span class="badge ${badgeClass}" style="font-size: 0.9rem; padding: 0.4rem 1rem;">
          <span class="badge-dot"></span> ${tierLabel}
        </span>
      </div>

      <div class="student-card-grid">
        <div class="stat-chip">
          <div class="stat-chip-label">Attendance</div>
          <div class="stat-chip-val" style="color:${s.attendance < 75 ? 'var(--risk-high)' : 'var(--accent-teal)'}">${s.attendance}%</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">Internal Marks</div>
          <div class="stat-chip-val">${s.internal_marks}/100</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">Previous GPA</div>
          <div class="stat-chip-val">${s.prev_gpa.toFixed(2)}</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">Backlogs</div>
          <div class="stat-chip-val" style="color:${s.backlogs > 0 ? 'var(--risk-high)' : 'inherit'}">${s.backlogs}</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">Assignments</div>
          <div class="stat-chip-val">${s.assignment_completion}%</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">LMS Score</div>
          <div class="stat-chip-val">${s.lms_engagement}</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">Lab Score</div>
          <div class="stat-chip-val">${s.lab_performance}%</div>
        </div>
        <div class="stat-chip">
          <div class="stat-chip-label">Engagement</div>
          <div class="stat-chip-val">${s.engagement_index}</div>
        </div>
      </div>

      <div class="intervention-box" style="margin-top: 1.5rem;">
        <div class="intervention-title">
          <i class="ri-lightbulb-flash-line" style="color:var(--accent-teal);"></i>
          Tailored Academic Action Plan:
        </div>
        <ul class="intervention-list">
          ${prediction.interventions.map(item => `<li>${item}</li>`).join('')}
        </ul>
      </div>
    `;

    studentModal.classList.add('active');
  }

  function closeStudentModal() {
    studentModal.classList.remove('active');
  }

  // ── 6. Live Risk Predictor Event Listeners ────────────────────
  function updatePredictorSimulation() {
    const inputs = {
      attendance: parseInt(pAtt.value, 10),
      internal_marks: parseInt(pMarks.value, 10),
      assignment_completion: parseInt(pAssign.value, 10),
      lms_engagement: parseInt(pLms.value, 10),
      prev_gpa: parseFloat(pGpa.value),
      backlogs: parseInt(pBacklogs.value, 10),
      lab_performance: parseInt(pLab.value, 10)
    };

    // Update Slider Value Bubbles
    document.getElementById('val_att').textContent = `${inputs.attendance}%`;
    document.getElementById('val_marks').textContent = `${inputs.internal_marks}%`;
    document.getElementById('val_assign').textContent = `${inputs.assignment_completion}%`;
    document.getElementById('val_lms').textContent = inputs.lms_engagement;
    document.getElementById('val_gpa').textContent = inputs.prev_gpa.toFixed(1);
    document.getElementById('val_backlogs').textContent = inputs.backlogs;
    document.getElementById('val_lab').textContent = `${inputs.lab_performance}%`;

    const res = RiskPredictor.calculateRiskScore(inputs);

    // Score & Tier
    predScoreVal.textContent = res.score;
    predTierBadge.textContent = res.label;
    predTierBadge.style.color = res.color;
    predTierBadge.style.backgroundColor = `${res.color}22`;
    predTierBadge.style.border = `1px solid ${res.color}55`;

    // Probability Bars
    probLowFill.style.width = `${res.probabilities.low}%`;
    probMedFill.style.width = `${res.probabilities.medium}%`;
    probHighFill.style.width = `${res.probabilities.high}%`;

    probLowPct.textContent = `${res.probabilities.low}%`;
    probMedPct.textContent = `${res.probabilities.medium}%`;
    probHighPct.textContent = `${res.probabilities.high}%`;

    // Interventions
    interventionList.innerHTML = res.interventions.map(item => `<li>${item}</li>`).join('');
  }

  [pAtt, pMarks, pAssign, pLms, pGpa, pBacklogs, pLab].forEach(slider => {
    slider.addEventListener('input', updatePredictorSimulation);
  });

  // ── 7. Alerts Center Table Render ────────────────────────────
  function renderAlertsTables(students) {
    const highRiskStudents = students.filter(s => s.risk_category === 'High_Risk');
    const lowAttStudents = students.filter(s => s.attendance < 75);
    const backlogStudents = students.filter(s => s.backlogs > 0);

    document.getElementById('alertHighCount').textContent = highRiskStudents.length;
    document.getElementById('alertLowAttCount').textContent = lowAttStudents.length;
    document.getElementById('alertBacklogCount').textContent = backlogStudents.length;

    const tbodyHigh = document.getElementById('alertHighTableBody');
    if (tbodyHigh) {
      tbodyHigh.innerHTML = highRiskStudents.slice(0, 10).map(s => `
        <tr>
          <td class="student-id-cell">${s.student_id}</td>
          <td>${s.department}</td>
          <td>Sem ${s.semester}</td>
          <td style="color:var(--risk-high); font-weight:700;">${s.attendance}%</td>
          <td>${s.internal_marks}%</td>
          <td>${s.backlogs}</td>
          <td>
            <button class="btn btn-outline" style="padding: 0.25rem 0.6rem; font-size: 0.75rem;" onclick="openStudentModal('${s.student_id}')">
              Intervene
            </button>
          </td>
        </tr>
      `).join('');
    }
  }

  // ── 8. Tab Navigation ────────────────────────────────────────
  navItems.forEach(item => {
    item.addEventListener('click', () => {
      const targetTab = item.getAttribute('data-tab');
      if (!targetTab) return;

      navItems.forEach(n => n.classList.remove('active'));
      tabPanes.forEach(p => p.classList.remove('active'));

      item.classList.add('active');
      const activePane = document.getElementById(`tab-${targetTab}`);
      if (activePane) activePane.classList.add('active');

      state.currentTab = targetTab;
      currentTabBreadcrumb.textContent = item.querySelector('.nav-label')?.textContent || targetTab;

      // Close mobile menu if open
      sidebar.classList.remove('mobile-open');

      refreshDashboard();
    });
  });

  // ── 9. Filter Event Listeners ────────────────────────────────
  deptFilter.addEventListener('change', () => {
    state.filters.dept = deptFilter.value;
    state.page = 1;
    refreshDashboard();
  });

  semFilter.addEventListener('change', () => {
    state.filters.semester = semFilter.value;
    state.page = 1;
    refreshDashboard();
  });

  riskFilter.addEventListener('change', () => {
    state.filters.risk = riskFilter.value;
    state.page = 1;
    refreshDashboard();
  });

  resetFiltersBtn.addEventListener('click', () => {
    state.filters.dept = 'All';
    state.filters.semester = 'All';
    state.filters.risk = 'All';
    state.searchQuery = '';
    state.page = 1;

    deptFilter.value = 'All';
    semFilter.value = 'All';
    riskFilter.value = 'All';
    searchInput.value = '';

    refreshDashboard();
    showToast("Filters reset to default.");
  });

  searchInput.addEventListener('input', () => {
    state.searchQuery = searchInput.value.trim();
    state.page = 1;
    renderStudentTable(getFilteredStudents());
  });

  // Table header sorting
  document.querySelectorAll('.data-table th[data-sort]').forEach(th => {
    th.addEventListener('click', () => {
      const key = th.getAttribute('data-sort');
      if (state.sortKey === key) {
        state.sortAsc = !state.sortAsc;
      } else {
        state.sortKey = key;
        state.sortAsc = true;
      }
      renderStudentTable(getFilteredStudents());
    });
  });

  // ── 10. Data Export Functions ────────────────────────────────
  exportCsvBtn.addEventListener('click', () => {
    const students = getFilteredStudents();
    if (!students.length) {
      showToast("No data to export!");
      return;
    }

    const headers = [
      'student_id', 'department', 'semester', 'age', 'attendance',
      'internal_marks', 'assignment_completion', 'lms_engagement',
      'prev_gpa', 'backlogs', 'lab_performance', 'engagement_index',
      'risk_score', 'risk_category'
    ];

    const csvRows = [];
    csvRows.push(headers.join(','));

    students.forEach(s => {
      const row = headers.map(h => s[h]);
      csvRows.push(row.join(','));
    });

    const csvContent = "data:text/csv;charset=utf-8," + csvRows.join('\n');
    const encodedUri = encodeURI(csvContent);
    const link = document.createElement("a");
    link.setAttribute("href", encodedUri);
    link.setAttribute("download", `EduRiskVision_Export_${new Date().toISOString().slice(0,10)}.csv`);
    document.body.appendChild(link);
    link.click();
    document.body.removeChild(link);

    showToast(`Exported ${students.length} students to CSV!`);
  });

  printReportBtn.addEventListener('click', () => {
    window.print();
  });

  // ── 11. Modal Close Handlers ─────────────────────────────────
  modalCloseBtn.addEventListener('click', closeStudentModal);
  studentModal.addEventListener('click', (e) => {
    if (e.target === studentModal) closeStudentModal();
  });
  document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') closeStudentModal();
  });

  // Make openStudentModal available globally for inline onclicks
  window.openStudentModal = openStudentModal;

  // ── 12. Theme Toggle & Mobile Menu ───────────────────────────
  themeToggleBtn.addEventListener('click', () => {
    const newTheme = document.documentElement.getAttribute('data-theme') === 'light' ? 'dark' : 'light';
    document.documentElement.setAttribute('data-theme', newTheme);
    localStorage.setItem('edurisk_theme', newTheme);
    themeToggleBtn.innerHTML = newTheme === 'light' ? '<i class="ri-moon-line"></i>' : '<i class="ri-sun-line"></i>';
    showToast(`Switched to ${newTheme} mode.`);
  });

  mobileMenuToggle.addEventListener('click', () => {
    sidebar.classList.toggle('mobile-open');
  });

  // Toast Notification Helper
  function showToast(message) {
    let container = document.getElementById('toastContainer');
    if (!container) {
      container = document.createElement('div');
      container.id = 'toastContainer';
      container.className = 'toast-container';
      document.body.appendChild(container);
    }

    const toast = document.createElement('div');
    toast.className = 'toast';
    toast.innerHTML = `<i class="ri-information-line" style="color:var(--accent-teal);"></i><span>${message}</span>`;
    container.appendChild(toast);

    setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
      toast.style.transition = 'all 0.3s ease';
      setTimeout(() => toast.remove(), 300);
    }, 3200);
  }

  // Initial Boot
  updatePredictorSimulation();
  refreshDashboard();
  console.log("EduRiskVision Master Controller initialized successfully.");

});
