# ============================================================
# EduRiskVision — install_packages.R
# Installs all required R packages for the project
# ============================================================

cat("╔══════════════════════════════════════════════╗\n")
cat("║   EduRiskVision — Installing Packages        ║\n")
cat("╚══════════════════════════════════════════════╝\n\n")

required_packages <- c(
  # Core data manipulation
  "dplyr",       # Data wrangling
  "tidyr",       # Data reshaping
  "readr",       # CSV reading/writing
  "lubridate",   # Date handling

  # Visualization
  "ggplot2",     # Core plotting
  "ggcorrplot",  # Correlation matrix plot
  "gridExtra",   # Multi-panel plots
  "scales",      # Axis formatting
  "RColorBrewer",# Color palettes

  # Machine Learning
  "caret",       # ML training framework
  "randomForest",# Random Forest
  "rpart",       # Decision Tree
  "rpart.plot",  # Decision Tree visualization
  "e1071",       # SVM & Naive Bayes (for caret)
  "pROC",
  "MLmetrics",        # ROC curves

  # Reporting
  "knitr",       # R Markdown
  "rmarkdown",   # HTML reports

  # Dashboard
  "shiny",           # Web dashboard framework
  "shinydashboard",  # Dashboard layout
  "shinythemes",     # Themes
  "shinyWidgets",    # Extra UI widgets
  "DT",              # Interactive tables
  "plotly"           # Interactive charts
)

install_if_missing <- function(pkg) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("  Installing: %s ...\n", pkg))
    install.packages(pkg, repos = "https://cran.rstudio.com/", quiet = TRUE)
    cat(sprintf("  ✔ Installed: %s\n", pkg))
  } else {
    cat(sprintf("  ✔ Already installed: %s\n", pkg))
  }
}

for (pkg in required_packages) {
  install_if_missing(pkg)
}

cat("\n✅ All packages ready. Run main.R to start.\n")
