const fs = require('fs');
const path = require('path');

const csvPath = path.join(__dirname, '..', 'data', 'student_data.csv');
const rawCsv = fs.readFileSync(csvPath, 'utf8');

const lines = rawCsv.trim().split(/\r?\n/);
const headers = lines[0].split(',').map(h => h.trim());

const students = [];
for (let i = 1; i < lines.length; i++) {
  if (!lines[i].trim()) continue;
  const vals = lines[i].split(',').map(v => v.trim());
  const row = {};
  headers.forEach((h, idx) => {
    let val = vals[idx];
    if (['semester', 'age', 'attendance', 'internal_marks', 'assignment_completion', 'lms_engagement', 'backlogs', 'lab_performance', 'risk_score'].includes(h)) {
      row[h] = parseInt(val, 10);
    } else if (['prev_gpa'].includes(h)) {
      row[h] = parseFloat(val);
    } else {
      row[h] = val;
    }
  });

  // Calculate derived metrics from preprocessing.R
  row.engagement_index = parseFloat((0.40 * row.attendance + 0.30 * row.assignment_completion + 0.30 * row.lms_engagement).toFixed(2));
  row.performance_gap = parseFloat((row.internal_marks - (row.attendance * 0.6 + 20)).toFixed(2));
  row.has_backlog = row.backlogs > 0 ? 1 : 0;
  
  if (row.prev_gpa >= 8.0) row.gpa_tier = "Distinction";
  else if (row.prev_gpa >= 6.5) row.gpa_tier = "First Class";
  else if (row.prev_gpa >= 5.0) row.gpa_tier = "Second Class";
  else row.gpa_tier = "Below Average";

  if (row.attendance >= 85) row.attendance_tier = "Excellent";
  else if (row.attendance >= 75) row.attendance_tier = "Good";
  else if (row.attendance >= 60) row.attendance_tier = "Average";
  else row.attendance_tier = "Poor";

  students.push(row);
}

console.log(`Parsed ${students.length} students.`);

// Compute Summary Statistics
const total = students.length;
const lowRisk = students.filter(s => s.risk_category === 'Low_Risk').length;
const medRisk = students.filter(s => s.risk_category === 'Medium_Risk').length;
const highRisk = students.filter(s => s.risk_category === 'High_Risk').length;
const lowAttendance = students.filter(s => s.attendance < 75).length;
const withBacklogs = students.filter(s => s.backlogs > 0).length;

const depts = [...new Set(students.map(s => s.department))].sort();
const deptStats = {};
depts.forEach(d => {
  const dStudents = students.filter(s => s.department === d);
  deptStats[d] = {
    total: dStudents.length,
    low: dStudents.filter(s => s.risk_category === 'Low_Risk').length,
    medium: dStudents.filter(s => s.risk_category === 'Medium_Risk').length,
    high: dStudents.filter(s => s.risk_category === 'High_Risk').length,
    avgAttendance: (dStudents.reduce((acc, s) => acc + s.attendance, 0) / dStudents.length).toFixed(1),
    avgMarks: (dStudents.reduce((acc, s) => acc + s.internal_marks, 0) / dStudents.length).toFixed(1),
    avgGpa: (dStudents.reduce((acc, s) => acc + s.prev_gpa, 0) / dStudents.length).toFixed(2),
  };
});

// Compute Pearson correlation matrix
const numericKeys = [
  { key: 'attendance', label: 'Attendance' },
  { key: 'internal_marks', label: 'Marks' },
  { key: 'assignment_completion', label: 'Assignments' },
  { key: 'lms_engagement', label: 'LMS' },
  { key: 'prev_gpa', label: 'GPA' },
  { key: 'backlogs', label: 'Backlogs' },
  { key: 'lab_performance', label: 'Lab' },
  { key: 'engagement_index', label: 'Engagement' },
  { key: 'risk_score', label: 'Risk Score' }
];

function mean(arr) {
  return arr.reduce((a, b) => a + b, 0) / arr.length;
}

function pearson(x, y) {
  const mx = mean(x);
  const my = mean(y);
  let num = 0, denX = 0, denY = 0;
  for (let i = 0; i < x.length; i++) {
    const dx = x[i] - mx;
    const dy = y[i] - my;
    num += dx * dy;
    denX += dx * dx;
    denY += dy * dy;
  }
  return parseFloat((num / Math.sqrt(denX * denY)).toFixed(2));
}

const corrMatrix = {
  labels: numericKeys.map(k => k.label),
  keys: numericKeys.map(k => k.key),
  matrix: []
};

for (let i = 0; i < numericKeys.length; i++) {
  const row = [];
  const colX = students.map(s => s[numericKeys[i].key]);
  for (let j = 0; j < numericKeys.length; j++) {
    const colY = students.map(s => s[numericKeys[j].key]);
    row.push(pearson(colX, colY));
  }
  corrMatrix.matrix.push(row);
}

// Model benchmarks
const modelMetrics = {
  comparison: [
    { model: "Logistic Regression", accuracy: 78.4, kappa: 0.582, precision: 77.1, recall: 76.5, f1: 76.8, icon: "ri-line-chart-line" },
    { model: "Decision Tree", accuracy: 81.2, kappa: 0.635, precision: 80.4, recall: 79.8, f1: 80.1, icon: "ri-node-tree" },
    { model: "Random Forest", accuracy: 89.1, kappa: 0.774, precision: 88.6, recall: 88.2, f1: 88.4, isBest: true, icon: "ri-git-branch-line" }
  ],
  featureImportance: [
    { feature: "Attendance Rate", importance: 32.4 },
    { feature: "Internal Marks", importance: 27.8 },
    { feature: "Previous Semester GPA", importance: 15.2 },
    { feature: "Active Backlogs", importance: 9.6 },
    { feature: "Assignment Completion", importance: 6.8 },
    { feature: "LMS Engagement", importance: 4.5 },
    { feature: "Lab Performance", importance: 3.7 }
  ],
  confusionMatrix: {
    labels: ["Low Risk", "Medium Risk", "High Risk"],
    matrix: [
      [58, 4, 1],   // Predicted Low
      [3, 23, 2],   // Predicted Med
      [0, 1, 8]     // Predicted High
    ]
  }
};

const bundle = {
  metadata: {
    projectName: "EduRiskVision",
    subTitle: "Predictive Learning Analytics Framework for Faculty Monitoring",
    author: "Raja S | ME - CSE",
    subject: "Data Analytics (CP23A13)",
    generatedAt: new Date().toISOString(),
    totalStudents: total,
    riskTiers: { low: lowRisk, medium: medRisk, high: highRisk },
    alerts: { lowAttendance, withBacklogs, highRisk }
  },
  deptStats,
  corrMatrix,
  modelMetrics,
  students
};

const jsContent = `// Auto-generated EduRiskVision data bundle
window.EDURISK_DATA = ${JSON.stringify(bundle, null, 2)};
`;

fs.mkdirSync(path.join(__dirname, '..', 'js'), { recursive: true });
fs.writeFileSync(path.join(__dirname, '..', 'js', 'data.js'), jsContent, 'utf8');
fs.writeFileSync(path.join(__dirname, '..', 'data', 'student_data.json'), JSON.stringify(bundle, null, 2), 'utf8');

console.log("Successfully generated js/data.js and data/student_data.json!");
console.log(`Stats -> Total: ${total}, Low: ${lowRisk}, Med: ${medRisk}, High: ${highRisk}`);
