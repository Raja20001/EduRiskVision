# EduRiskVision — Deployment & Publication Guide

Welcome to the deployment and publication guide for **EduRiskVision (Predictive Learning Analytics Framework)**.

EduRiskVision includes a **high-performance, responsive web application** designed specifically for free, zero-config hosting and publication on **GitHub Pages** or **Vercel**.

---

## 🚀 Deployment Options Summary

| Platform | Deployment Method | Time to Deploy | Custom Domain | Cost |
| :--- | :--- | :--- | :--- | :--- |
| **GitHub Pages** | GitHub Actions (`.github/workflows/deploy.yml`) OR Branch Deploy (`main / root`) | ~1-2 min | ✅ Supported | Free |
| **Vercel** | Git Push Import OR Vercel CLI (`vercel --prod`) | ~20 sec | ✅ Supported | Free |
| **Local Preview** | Zero-dependency local server (`npm run dev` or `node scripts/serve.js`) | Instant | N/A | Free |

---

## Method 1: Deploying to GitHub Pages

GitHub Pages allows you to host the EduRiskVision website directly from your GitHub repository for free.

### Step 1: Initialize Git and Push to GitHub

If your project is not yet connected to a GitHub repository, open a terminal in the project directory and run:

```bash
# 1. Initialize git
git init

# 2. Add all project files
git add .

# 3. Create your first commit
git commit -m "feat: complete EduRiskVision web application ready for deployment"

# 4. Set main as default branch
git branch -M main

# 5. Link your GitHub remote repository (replace with your repository URL)
git remote add origin https://github.com/<YOUR_GITHUB_USERNAME>/EduRiskVision.git

# 6. Push code to GitHub
git push -u origin main
```

---

### Step 2: Enable GitHub Pages

You have **two simple options** in GitHub:

#### Option A: Automated via GitHub Actions (Recommended)
This repository already includes `.github/workflows/deploy.yml`.

1. Go to your repository on GitHub: `https://github.com/<YOUR_GITHUB_USERNAME>/EduRiskVision`
2. Click **Settings** (top tab).
3. In the left navigation, click **Pages** (under "Code and automation").
4. Under **Build and deployment** → **Source**, change the dropdown from **Deploy from a branch** to **GitHub Actions**.
5. Go to the **Actions** tab in your repository: you will see the `Deploy EduRiskVision to GitHub Pages` workflow running.
6. Once complete, your live website URL will be displayed:
   ```
   https://<YOUR_GITHUB_USERNAME>.github.io/EduRiskVision/
   ```

#### Option B: Deploy Directly from Branch
If you prefer not using GitHub Actions:
1. Go to **Settings** → **Pages**.
2. Under **Build and deployment** → **Source**, select **Deploy from a branch**.
3. Under **Branch**, select `main` and folder `/ (root)`.
4. Click **Save**.
5. In 1–2 minutes, your website will be live at `https://<YOUR_GITHUB_USERNAME>.github.io/EduRiskVision/`.

---

## Method 2: Deploying to Vercel

Vercel provides blazing-fast edge hosting, SSL certificates, and instant preview URLs.

### Option A: 1-Click Import via Vercel Web Dashboard (Easiest)

1. Push your repository to GitHub (following Step 1 above).
2. Go to [vercel.com](https://vercel.com) and log in (or sign up with your GitHub account).
3. Click the **"Add New..."** button in the top right → select **"Project"**.
4. Find your `EduRiskVision` repository in the list and click **"Import"**.
5. Vercel automatically detects `vercel.json` and configures the project:
   - **Framework Preset**: Other
   - **Root Directory**: `./`
   - **Build Command**: None (or `node scripts/prepare_web_data.js`)
   - **Output Directory**: `./`
6. Click **"Deploy"**.
7. In ~20 seconds, your site is published with a live URL (e.g. `https://eduriskvision-xi.vercel.app`)!

---

### Option B: Deploying via Vercel CLI

If you prefer deploying directly from your local terminal:

```bash
# 1. Install the Vercel CLI globally (if not already installed)
npm install -g vercel

# 2. Log in and deploy
vercel

# Follow the prompts:
# ? Set up and deploy? [Y/n] y
# ? Which scope? (Select your account)
# ? Link to existing project? [y/N] n
# ? What's your project's name? eduriskvision
# ? In which directory is your code located? ./

# 3. For production deployment
vercel --prod
```

Your terminal will print the live production URL immediately.

---

## Local Development & Testing

You can test and run the web application locally on your machine before or after deploying:

```bash
# Option 1: Using npm
npm run dev

# Option 2: Directly via Node (zero dependencies needed)
node scripts/serve.js
```

Open your browser and navigate to:
```
http://localhost:3000
```

To re-generate or update student data from `data/student_data.csv`:
```bash
npm run prepare-data
```

---

## 📁 Repository Structure for Web Deployment

```
EduRiskVision/
├── index.html                    ← Master Web Application Entrypoint
├── vercel.json                   ← Vercel Edge configuration & security headers
├── package.json                  ← NPM scripts for local dev and preview
├── DEPLOYMENT.md                 ← This step-by-step deployment guide
├── .gitignore                    ← Excludes temporary R/Node files
│
├── .github/
│   └── workflows/
│       └── deploy.yml            ← Automated GitHub Actions workflow for GitHub Pages
│
├── css/
│   └── style.css                 ← Signature Cyber-Teal & Emerald Design System
│
├── js/
│   ├── data.js                   ← 500-student dataset & model benchmarks bundle
│   ├── charts.js                 ← Chart.js interactive visualization suite
│   ├── predictor.js              ← Multi-factor ML simulator & intervention engine
│   └── app.js                    ← App state, reactive filters, search & modals
│
├── scripts/
│   ├── serve.js                  ← Zero-dependency local development server
│   └── prepare_web_data.js       ← Data processing script (CSV → JSON bundle)
│
├── data/
│   ├── student_data.csv          ← Raw student dataset (500 records)
│   └── student_data.json         ← JSON formatted student dataset
│
├── models/                       ← R Model Training Scripts (RF, DT, LR)
├── dashboard/                    ← Original R Shiny app (for local R sessions)
└── README.md                     ← Master project documentation
```

---

## 🎯 Verification Checklist

Before publishing, verify:
- [x] `index.html` loads cleanly with all KPI metrics (500 Total, 292 Low, 146 Med, 62 High).
- [x] Global filters (Department, Semester, Risk Tier) reactively update all charts and tables.
- [x] Student Register search, sorting, and pagination work smoothly.
- [x] Student Diagnostic Modal opens with full 360° details and tailored action plans.
- [x] Live Risk Predictor sliders update risk scores and probabilities in real-time.
- [x] CSV Data Export downloads filtered cohorts with 1 click.
- [x] Dark / Light theme toggle switches seamlessly.
