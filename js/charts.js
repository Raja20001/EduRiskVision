/* ============================================================
   EduRiskVision — js/charts.js
   Interactive Visualization Engine powered by Chart.js
   ============================================================ */

const EduRiskCharts = (function() {
  const chartInstances = {};

  // Color Tokens
  const COLOR_LOW = '#10B981';
  const COLOR_MED = '#F59E0B';
  const COLOR_HIGH = '#EF4444';
  const COLOR_TEAL = '#00BFA5';
  const COLOR_CYAN = '#00E5FF';
  const COLOR_CARD_BG = 'rgba(16, 27, 33, 0.85)';

  // Destroy previous chart safely before redrawing
  function destroyChart(key) {
    if (chartInstances[key]) {
      chartInstances[key].destroy();
      chartInstances[key] = null;
    }
  }

  // ── 1. Overview: Risk Distribution Donut Chart ───────────────
  function renderRiskDistribution(students, canvasId = 'chartRiskDist') {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    destroyChart(canvasId);

    const low = students.filter(s => s.risk_category === 'Low_Risk').length;
    const med = students.filter(s => s.risk_category === 'Medium_Risk').length;
    const high = students.filter(s => s.risk_category === 'High_Risk').length;

    const ctx = canvas.getContext('2d');
    chartInstances[canvasId] = new Chart(ctx, {
      type: 'doughnut',
      data: {
        labels: ['Low Risk (Safe)', 'Medium Risk (Moderate)', 'High Risk (Critical)'],
        datasets: [{
          data: [low, med, high],
          backgroundColor: [COLOR_LOW, COLOR_MED, COLOR_HIGH],
          borderColor: '#070D10',
          borderWidth: 3,
          hoverOffset: 8
        }]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        cutout: '72%',
        plugins: {
          legend: {
            position: 'bottom',
            labels: {
              color: '#94A3B8',
              font: { family: 'Inter', size: 12 },
              padding: 16,
              usePointStyle: true
            }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const val = context.parsed;
                const total = low + med + high;
                const pct = ((val / total) * 100).toFixed(1);
                return ` ${context.label}: ${val} students (${pct}%)`;
              }
            }
          }
        }
      }
    });
  }

  // ── 2. Overview: Department-wise Risk Breakdown ─────────────
  function renderDeptRiskBreakdown(students, canvasId = 'chartDeptRisk') {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    destroyChart(canvasId);

    const depts = [...new Set(students.map(s => s.department))].sort();
    const lowCounts = [];
    const medCounts = [];
    const highCounts = [];

    depts.forEach(d => {
      const dStudents = students.filter(s => s.department === d);
      lowCounts.push(dStudents.filter(s => s.risk_category === 'Low_Risk').length);
      medCounts.push(dStudents.filter(s => s.risk_category === 'Medium_Risk').length);
      highCounts.push(dStudents.filter(s => s.risk_category === 'High_Risk').length);
    });

    const ctx = canvas.getContext('2d');
    chartInstances[canvasId] = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: depts,
        datasets: [
          {
            label: 'Low Risk',
            data: lowCounts,
            backgroundColor: COLOR_LOW,
            borderRadius: 4
          },
          {
            label: 'Medium Risk',
            data: medCounts,
            backgroundColor: COLOR_MED,
            borderRadius: 4
          },
          {
            label: 'High Risk',
            data: highCounts,
            backgroundColor: COLOR_HIGH,
            borderRadius: 4
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            stacked: true,
            grid: { display: false },
            ticks: { color: '#94A3B8', font: { family: 'Inter', weight: '600' } }
          },
          y: {
            stacked: true,
            grid: { color: 'rgba(255, 255, 255, 0.06)' },
            ticks: { color: '#64748B' }
          }
        },
        plugins: {
          legend: {
            position: 'top',
            labels: { color: '#94A3B8', usePointStyle: true, font: { size: 11 } }
          }
        }
      }
    });
  }

  // ── 3. Overview: Attendance vs Internal Marks Scatter ────────
  function renderAttendanceVsMarks(students, canvasId = 'chartScatter') {
    const canvas = document.getElementById(canvasId);
    if (!canvas) return;
    destroyChart(canvasId);

    // Group points by risk category for discrete color mapping
    const lowPoints = students
      .filter(s => s.risk_category === 'Low_Risk')
      .map(s => ({ x: s.attendance, y: s.internal_marks, id: s.student_id, dept: s.department }));
    const medPoints = students
      .filter(s => s.risk_category === 'Medium_Risk')
      .map(s => ({ x: s.attendance, y: s.internal_marks, id: s.student_id, dept: s.department }));
    const highPoints = students
      .filter(s => s.risk_category === 'High_Risk')
      .map(s => ({ x: s.attendance, y: s.internal_marks, id: s.student_id, dept: s.department }));

    const ctx = canvas.getContext('2d');
    chartInstances[canvasId] = new Chart(ctx, {
      type: 'scatter',
      data: {
        datasets: [
          {
            label: 'Low Risk',
            data: lowPoints,
            backgroundColor: 'rgba(16, 185, 129, 0.75)',
            borderColor: COLOR_LOW,
            pointRadius: 4.5,
            pointHoverRadius: 7
          },
          {
            label: 'Medium Risk',
            data: medPoints,
            backgroundColor: 'rgba(245, 158, 11, 0.75)',
            borderColor: COLOR_MED,
            pointRadius: 4.5,
            pointHoverRadius: 7
          },
          {
            label: 'High Risk',
            data: highPoints,
            backgroundColor: 'rgba(239, 68, 68, 0.85)',
            borderColor: COLOR_HIGH,
            pointRadius: 5.5,
            pointHoverRadius: 8
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: {
            title: { display: true, text: 'Attendance Rate (%)', color: '#94A3B8' },
            min: 25,
            max: 100,
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: { color: '#64748B' }
          },
          y: {
            title: { display: true, text: 'Internal Marks (%)', color: '#94A3B8' },
            min: 10,
            max: 100,
            grid: { color: 'rgba(255, 255, 255, 0.05)' },
            ticks: { color: '#64748B' }
          }
        },
        plugins: {
          legend: {
            position: 'top',
            labels: { color: '#94A3B8', usePointStyle: true }
          },
          tooltip: {
            callbacks: {
              label: function(context) {
                const pt = context.raw;
                return `${pt.id} (${pt.dept}) — Att: ${pt.x}%, Marks: ${pt.y}%`;
              }
            }
          }
        }
      }
    });
  }

  // ── 4. Analytics: Performance Comparisons ───────────────────
  function renderAnalyticsMetrics(students) {
    // Attendance by Risk
    const attCanvas = document.getElementById('chartAttByRisk');
    if (attCanvas) {
      destroyChart('chartAttByRisk');
      const calcAvg = tier => {
        const set = students.filter(s => s.risk_category === tier);
        return set.length ? (set.reduce((a, b) => a + b.attendance, 0) / set.length).toFixed(1) : 0;
      };

      chartInstances['chartAttByRisk'] = new Chart(attCanvas.getContext('2d'), {
        type: 'bar',
        data: {
          labels: ['Low Risk', 'Medium Risk', 'High Risk'],
          datasets: [{
            label: 'Avg Attendance (%)',
            data: [calcAvg('Low_Risk'), calcAvg('Medium_Risk'), calcAvg('High_Risk')],
            backgroundColor: [COLOR_LOW, COLOR_MED, COLOR_HIGH],
            borderRadius: 6
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: { min: 0, max: 100, grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748B' } },
            x: { grid: { display: false }, ticks: { color: '#94A3B8', font: { weight: '600' } } }
          },
          plugins: { legend: { display: false } }
        }
      });
    }

    // Marks by Risk
    const marksCanvas = document.getElementById('chartMarksByRisk');
    if (marksCanvas) {
      destroyChart('chartMarksByRisk');
      const calcAvg = tier => {
        const set = students.filter(s => s.risk_category === tier);
        return set.length ? (set.reduce((a, b) => a + b.internal_marks, 0) / set.length).toFixed(1) : 0;
      };

      chartInstances['chartMarksByRisk'] = new Chart(marksCanvas.getContext('2d'), {
        type: 'bar',
        data: {
          labels: ['Low Risk', 'Medium Risk', 'High Risk'],
          datasets: [{
            label: 'Avg Internal Marks (%)',
            data: [calcAvg('Low_Risk'), calcAvg('Medium_Risk'), calcAvg('High_Risk')],
            backgroundColor: [COLOR_LOW, COLOR_MED, COLOR_HIGH],
            borderRadius: 6
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: { min: 0, max: 100, grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748B' } },
            x: { grid: { display: false }, ticks: { color: '#94A3B8', font: { weight: '600' } } }
          },
          plugins: { legend: { display: false } }
        }
      });
    }

    // LMS Engagement vs Risk
    const lmsCanvas = document.getElementById('chartLmsByRisk');
    if (lmsCanvas) {
      destroyChart('chartLmsByRisk');
      const calcAvg = tier => {
        const set = students.filter(s => s.risk_category === tier);
        return set.length ? (set.reduce((a, b) => a + b.lms_engagement, 0) / set.length).toFixed(1) : 0;
      };

      chartInstances['chartLmsByRisk'] = new Chart(lmsCanvas.getContext('2d'), {
        type: 'bar',
        data: {
          labels: ['Low Risk', 'Medium Risk', 'High Risk'],
          datasets: [{
            label: 'Avg LMS Score (0-100)',
            data: [calcAvg('Low_Risk'), calcAvg('Medium_Risk'), calcAvg('High_Risk')],
            backgroundColor: [COLOR_LOW, COLOR_MED, COLOR_HIGH],
            borderRadius: 6
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: { min: 0, max: 100, grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748B' } },
            x: { grid: { display: false }, ticks: { color: '#94A3B8', font: { weight: '600' } } }
          },
          plugins: { legend: { display: false } }
        }
      });
    }

    // GPA by Risk
    const gpaCanvas = document.getElementById('chartGpaByRisk');
    if (gpaCanvas) {
      destroyChart('chartGpaByRisk');
      const calcAvg = tier => {
        const set = students.filter(s => s.risk_category === tier);
        return set.length ? (set.reduce((a, b) => a + b.prev_gpa, 0) / set.length).toFixed(2) : 0;
      };

      chartInstances['chartGpaByRisk'] = new Chart(gpaCanvas.getContext('2d'), {
        type: 'bar',
        data: {
          labels: ['Low Risk', 'Medium Risk', 'High Risk'],
          datasets: [{
            label: 'Avg Previous GPA',
            data: [calcAvg('Low_Risk'), calcAvg('Medium_Risk'), calcAvg('High_Risk')],
            backgroundColor: [COLOR_LOW, COLOR_MED, COLOR_HIGH],
            borderRadius: 6
          }]
        },
        options: {
          responsive: true,
          maintainAspectRatio: false,
          scales: {
            y: { min: 0, max: 10, grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748B' } },
            x: { grid: { display: false }, ticks: { color: '#94A3B8', font: { weight: '600' } } }
          },
          plugins: { legend: { display: false } }
        }
      });
    }
  }

  // ── 5. Analytics: Correlation Heatmap Grid ───────────────────
  function renderCorrelationHeatmap(corrData, containerId = 'heatmapContainer') {
    const container = document.getElementById(containerId);
    if (!container || !corrData) return;

    const { labels, matrix } = corrData;
    let html = `<div style="display:grid; grid-template-columns: 100px repeat(${labels.length}, 1fr); gap: 4px; overflow-x: auto; padding: 10px;">`;

    // Header row
    html += `<div></div>`;
    labels.forEach(l => {
      html += `<div style="font-size: 0.72rem; font-weight:700; color:#94A3B8; text-align:center; padding: 4px;">${l}</div>`;
    });

    // Matrix rows
    matrix.forEach((row, i) => {
      html += `<div style="font-size: 0.72rem; font-weight:700; color:#94A3B8; display:flex; align-items:center;">${labels[i]}</div>`;
      row.forEach(val => {
        let bg;
        if (val > 0) {
          const intensity = Math.min(1, val);
          bg = `rgba(0, 191, 165, ${0.15 + intensity * 0.75})`;
        } else {
          const intensity = Math.min(1, Math.abs(val));
          bg = `rgba(239, 68, 68, ${0.15 + intensity * 0.75})`;
        }
        html += `
          <div style="background:${bg}; border-radius:4px; padding: 10px 4px; text-align:center; font-family:'JetBrains Mono', monospace; font-size:0.75rem; font-weight:600; color:#fff;" title="${labels[i]} vs ${labels[labels.indexOf(val)]}: ${val}">
            ${val.toFixed(2)}
          </div>
        `;
      });
    });

    html += `</div>`;
    container.innerHTML = html;
  }

  // ── 6. Models: Model Comparison Bar Chart ────────────────────
  function renderModelComparison(models, canvasId = 'chartModelComparison') {
    const canvas = document.getElementById(canvasId);
    if (!canvas || !models) return;
    destroyChart(canvasId);

    const ctx = canvas.getContext('2d');
    chartInstances[canvasId] = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: models.map(m => m.model),
        datasets: [
          {
            label: 'Accuracy (%)',
            data: models.map(m => m.accuracy),
            backgroundColor: ['#00695C', '#00897B', '#00BFA5'],
            borderRadius: 6
          }
        ]
      },
      options: {
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          y: { min: 65, max: 95, grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748B' } },
          x: { grid: { display: false }, ticks: { color: '#94A3B8', font: { weight: '600' } } }
        },
        plugins: {
          legend: { display: false }
        }
      }
    });
  }

  // ── 7. Models: Feature Importance Horizontal Bar ─────────────
  function renderFeatureImportance(features, canvasId = 'chartFeatureImportance') {
    const canvas = document.getElementById(canvasId);
    if (!canvas || !features) return;
    destroyChart(canvasId);

    const sorted = [...features].sort((a, b) => b.importance - a.importance);
    const ctx = canvas.getContext('2d');
    chartInstances[canvasId] = new Chart(ctx, {
      type: 'bar',
      data: {
        labels: sorted.map(f => f.feature),
        datasets: [{
          label: 'Importance Score (%)',
          data: sorted.map(f => f.importance),
          backgroundColor: '#00BFA5',
          borderRadius: 4
        }]
      },
      options: {
        indexAxis: 'y',
        responsive: true,
        maintainAspectRatio: false,
        scales: {
          x: { grid: { color: 'rgba(255, 255, 255, 0.05)' }, ticks: { color: '#64748B' } },
          y: { grid: { display: false }, ticks: { color: '#94A3B8', font: { weight: '600' } } }
        },
        plugins: { legend: { display: false } }
      }
    });
  }

  // ── 8. Models: Confusion Matrix Visual ───────────────────────
  function renderConfusionMatrix(cmData, containerId = 'confusionMatrixContainer') {
    const container = document.getElementById(containerId);
    if (!container || !cmData) return;

    const { labels, matrix } = cmData;
    let html = `
      <div style="max-width: 480px; margin: 0 auto;">
        <div style="display:flex; justify-content:space-between; margin-bottom: 8px; font-size: 0.78rem; font-weight:700; color:#00BFA5; text-transform:uppercase; letter-spacing:0.05em;">
          <span>Predicted \\ Actual</span>
          <span>Sample: Test Split (N=100)</span>
        </div>
        <div style="display:grid; grid-template-columns: 110px repeat(3, 1fr); gap: 6px;">
          <div></div>
          ${labels.map(l => `<div style="text-align:center; font-size:0.75rem; font-weight:700; color:#94A3B8; padding: 4px;">${l}</div>`).join('')}
    `;

    matrix.forEach((row, rIdx) => {
      html += `<div style="font-size:0.75rem; font-weight:700; color:#94A3B8; display:flex; align-items:center;">${labels[rIdx]}</div>`;
      row.forEach((count, cIdx) => {
        const isDiag = rIdx === cIdx;
        const bg = isDiag
          ? `rgba(0, 191, 165, ${0.25 + (count / 60) * 0.75})`
          : (count > 0 ? `rgba(239, 68, 68, ${0.2 + count * 0.2})` : 'rgba(255, 255, 255, 0.03)');
        html += `
          <div style="background:${bg}; border-radius:6px; padding: 16px; text-align:center; border: 1px solid rgba(255,255,255,0.08);">
            <div style="font-family:'Outfit',sans-serif; font-size:1.4rem; font-weight:800; color:#fff;">${count}</div>
            <div style="font-size:0.68rem; color:${isDiag ? '#00BFA5' : '#EF4444'}; font-weight:600;">${isDiag ? 'Correct' : 'Misclass'}</div>
          </div>
        `;
      });
    });

    html += `</div></div>`;
    container.innerHTML = html;
  }

  return {
    renderRiskDistribution,
    renderDeptRiskBreakdown,
    renderAttendanceVsMarks,
    renderAnalyticsMetrics,
    renderCorrelationHeatmap,
    renderModelComparison,
    renderFeatureImportance,
    renderConfusionMatrix
  };

})();
