# EduRiskVision — Predictive Learning Analytics Framework

> **AI-Powered Early Student Academic Risk Identification & Faculty Decision Support System**  
> **Course:** Data Analytics (CP23A13)  
> **Author:** Raja S | ME – CSE  
> **Live Web Publication:** Ready for deployment on **GitHub Pages** or **Vercel**

---

## 🌐 Live Web Deployment & Publication

EduRiskVision includes a **high-performance, standalone interactive web application** ready for instant public hosting on **GitHub Pages** and **Vercel**:

- **GitHub Pages:** Automated deployment via `.github/workflows/deploy.yml` or branch deploy (`main / root`).
- **Vercel:** Zero-config edge hosting via `vercel.json`.
- **Complete Step-by-Step Guide:** See [DEPLOYMENT.md](DEPLOYMENT.md) for full publishing instructions.

### Quick Local Preview
To test and explore the web dashboard locally on your machine:
```bash
# Option 1: Using npm
npm run dev

# Option 2: Directly with Node (zero external dependencies)
node scripts/serve.js
```
Open **http://localhost:3000** in your browser.

---

## 🌟 Key Web Platform Features

1. **Executive Analytics Overview:** Real-time KPI cards, Risk Category Donut Distribution, Department-wise Stacked Breakdown, and Attendance vs. Internal Marks Scatter Plot.
2. **Student Risk Register:** Searchable and sortable registry of 500 students with multi-factor filtering (Department, Semester, Risk Tier) and interactive 360° student diagnostic cards.
3. **Deep Analytics:** Box distributions of attendance, internal marks, LMS engagement, and GPA across risk categories, plus an interactive 9×9 Pearson Feature Correlation Heatmap.
4. **Machine Learning Model Comparison:** Benchmarks comparing Logistic Regression (78.4%), Decision Tree (81.2%), and champion Random Forest (89.1%), including Feature Importance and Confusion Matrix heatmaps.
5. **Real-time Live Risk Predictor:** Interactive "What-If" simulator allowing faculty to tweak academic sliders (Attendance %, Marks, Assignments, LMS, GPA, Backlogs, Lab) to see instant risk score changes, ensemble probabilities, and tailored pedagogical action plans.
6. **Early Warning & Alert Triage:** Prioritized register of critical high-risk students, attendance deficits (&lt;75%), and active backlogs.
7. **One-Click Export:** Download filtered cohorts as CSV or print academic summary reports.
8. **Dark / Light Theme:** Custom cyber-teal and emerald design system with smooth glassmorphism.

---

## 📁 Project Architecture

```
EduRiskVision/
├── index.html                        ← Master Web Application
├── DEPLOYMENT.md                     ← GitHub Pages & Vercel deployment guide
├── vercel.json                       ← Vercel Edge hosting configuration
├── package.json                      ← NPM scripts & metadata
├── .gitignore                        ← Clean deployment filter
│
├── .github/
│   └── workflows/
│       └── deploy.yml                ← GitHub Actions workflow for GitHub Pages
│
├── css/
│   └── style.css                     ← Cyber-Teal design system & animations
│
├── js/
│   ├── data.js                       ← 500-student dataset & model benchmarks
│   ├── charts.js                     ← Chart.js interactive visualization suite
│   ├── predictor.js                  ← Multi-factor ML simulator & intervention engine
│   └── app.js                        ← State manager, table pagination, search & modal
│
├── scripts/
│   ├── serve.js                      ← Zero-dependency local preview server
│   └── prepare_web_data.js           ← CSV to JSON compilation script
│
├── data/
│   ├── generate_data.R               ← Synthetic dataset generator (R)
│   ├── student_data.csv              ← Generated 500-student dataset (CSV)
│   └── student_data.json             ← Web-ready student dataset (JSON)
│
├── utils/
│   ├── preprocessing.R               ← Data cleaning & feature engineering (R)
│   └── evaluation.R                  ← Model evaluation helpers (R)
│
├── models/
│   ├── logistic_regression.R         ← Logistic Regression model (~78% accuracy)
│   ├── decision_tree.R               ← Decision Tree model (~81% accuracy)
│   ├── random_forest.R               ← Random Forest model (~89% accuracy - Best)
│   └── model_comparison.R            ← Model comparison benchmarks
│
├── dashboard/
│   └── app.R                         ← Original R Shiny interactive dashboard
│
├── main.R                            ← Master R pipeline runner
└── install_packages.R                ← R dependency installer
```

---

## 🔬 Model Benchmarks Summary

| Model | Accuracy | Cohen's Kappa | Precision | Recall | Status |
| :--- | :---: | :---: | :---: | :---: | :---: |
| Logistic Regression | 78.4% | 0.582 | 77.1% | 76.5% | Baseline |
| Decision Tree (CART) | 81.2% | 0.635 | 80.4% | 79.8% | Interpretable |
| **Random Forest** | **89.1%** | **0.774** | **88.6%** | **88.2%** | **★ Champion Model** |

---

## 🛠️ How to Run the Original R Pipeline (Optional)

If you wish to execute the underlying R research pipeline and R Shiny app locally:

### Step 1 — Install R dependencies
```r
source("install_packages.R")
```

### Step 2 — Run full pipeline
```r
source("main.R")
```

### Step 3 — Launch R Shiny dashboard
```r
shiny::runApp("dashboard/app.R")
```

---

## 📜 Publication Instructions

Follow the complete instructions in [DEPLOYMENT.md](DEPLOYMENT.md) to publish on:
1. **GitHub Pages:** Enable GitHub Actions in **Settings** → **Pages** → **Source: GitHub Actions**.
2. **Vercel:** Import your GitHub repository directly on [vercel.com](https://vercel.com).
