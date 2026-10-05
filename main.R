# ============================================================
# EduRiskVision — main.R
# Master pipeline runner — executes all project steps in order
# Run this file to execute the complete project
# ============================================================

cat("╔══════════════════════════════════════════════════╗\n")
cat("║   EduRiskVision — Full Pipeline Runner           ║\n")
cat("║   Predictive Learning Analytics Framework        ║\n")
cat("╠══════════════════════════════════════════════════╣\n")
cat("║   Author  : Raja S  |  ME – CSE                 ║\n")
cat("║   Subject : Data Analytics  |  CP23A13           ║\n")
cat("╚══════════════════════════════════════════════════╝\n\n")

start_time <- Sys.time()

# ── Set Working Directory ────────────────────────────────────
# Uncomment and set the path to your EduRiskVision project folder:
# setwd("/path/to/EduRiskVision")
#  "shiny",
#  "shinydashboard",
#  "dplyr",
#  "ggplot2",
#  "caret",
#  "randomForest",
#  "rpart",
#  "rpart.plot",
#  "nnet",
#  "readr",
#  "gridExtra"
#), dependencies = TRUE)
#
# ── Load Libraries ───────────────────────────────────────────
suppressMessages({
  library(dplyr)
  library(ggplot2)
  library(caret)
  library(randomForest)
  library(rpart)
  library(rpart.plot)
  library(nnet)
  library(readr)
  library(gridExtra)
})

# ── Source All Modules ───────────────────────────────────────
SOURCED_BY_MAIN <- TRUE   # flag to prevent sub-scripts from running standalone

source("data/generate_data.R")
source("utils/preprocessing.R")
source("utils/evaluation.R")
source("models/logistic_regression.R")
source("models/decision_tree.R")
source("models/random_forest.R")
source("models/model_comparison.R")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 1 ─ Data Generation\n")
cat("═══════════════════════════════════════════════════\n")

raw_df <- generate_student_data(n = 500, seed = 42)
write_csv(raw_df, "data/student_data.csv")
cat("  ✔ Dataset saved to data/student_data.csv\n\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 2 ─ Data Preprocessing\n")
cat("═══════════════════════════════════════════════════\n")

validate_data(raw_df)
clean_df  <- clean_data(raw_df)
full_df   <- engineer_features(clean_df)
summarise_data(full_df)

# Train-Test Split
splits      <- split_data(full_df, train_ratio = 0.80)
train_df    <- splits$train
test_df     <- splits$test

# Prepare ML-ready feature sets
train_ml  <- prepare_ml_features(train_df)
test_ml   <- prepare_ml_features(test_df)

cat("\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 3 ─ Exploratory Data Analysis\n")
cat("═══════════════════════════════════════════════════\n")

# EDA Plots
cat("  Generating EDA plots...\n")

p_risk <- plot_risk_distribution(full_df)
p_scat <- plot_attendance_vs_marks(full_df)

# Correlation analysis
num_cols <- full_df %>%
  select(attendance, internal_marks, assignment_completion,
         lms_engagement, prev_gpa, backlogs, lab_performance,
         engagement_index, risk_score)

cor_matrix <- round(cor(num_cols, use = "complete.obs"), 3)
cat("  Correlation with risk_score:\n")
print(sort(cor_matrix[, "risk_score"], decreasing = TRUE))

cat("  ✔ EDA complete.\n\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 4 ─ Model Training\n")
cat("═══════════════════════════════════════════════════\n")

# Train all three models
lr_model <- train_logistic_regression(train_ml)
dt_model <- train_decision_tree(train_ml)
rf_model <- train_random_forest(train_ml)

cat("\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 5 ─ Model Evaluation\n")
cat("═══════════════════════════════════════════════════\n")

# Predictions on test set
lr_preds <- predict_logistic_regression(lr_model, test_ml)
dt_preds <- predict_decision_tree(dt_model, test_ml)
rf_preds <- predict_random_forest(rf_model, test_ml)

# Evaluate each model
lr_eval <- evaluate_model("Logistic Regression", test_ml$risk_category, lr_preds$predictions)
dt_eval <- evaluate_model("Decision Tree",        test_ml$risk_category, dt_preds$predictions)
rf_eval <- evaluate_model("Random Forest",        test_ml$risk_category, rf_preds$predictions)

cat("\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 6 ─ Model Comparison\n")
cat("═══════════════════════════════════════════════════\n")

comparison_df <- compare_models(lr_eval, dt_eval, rf_eval)

# Feature importance from Random Forest
rf_importance <- get_rf_importance(rf_model)
cat("\n  Random Forest — Top 5 Most Important Features:\n")
print(head(rf_importance, 5))

cat("\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 7 ─ Visualizations\n")
cat("═══════════════════════════════════════════════════\n")

cat("  Generating plots...\n")

# All evaluation plots (displayed in RStudio Plots pane)
p1 <- plot_confusion_matrix(rf_eval)
p2 <- plot_model_comparison(list(lr_eval, dt_eval, rf_eval))
p3 <- plot_feature_importance(rf_importance, "Random Forest")
p4 <- plot_oob_error(rf_model)
p5 <- plot_risk_distribution(full_df)
p6 <- plot_attendance_vs_marks(full_df)
p7 <- plot_cv_results(lr_model, dt_model, rf_model)

# Display key plots
print(p5)
print(p6)
print(p2)
print(p3)

cat("  ✔ Plots generated.\n\n")

cat("═══════════════════════════════════════════════════\n")
cat("STEP 8 ─ Sample Predictions\n")
cat("═══════════════════════════════════════════════════\n")

cat("\n  Example 1 — A high-performing student:\n")
predict_single_student(rf_model, list(
  attendance = 92, internal_marks = 85,
  assignment_completion = 95, lms_engagement = 88,
  prev_gpa = 8.5, backlogs = 0, lab_performance = 90
))

cat("\n  Example 2 — A borderline student:\n")
predict_single_student(rf_model, list(
  attendance = 72, internal_marks = 55,
  assignment_completion = 60, lms_engagement = 50,
  prev_gpa = 5.8, backlogs = 1, lab_performance = 58
))

cat("\n  Example 3 — A high-risk student:\n")
predict_single_student(rf_model, list(
  attendance = 45, internal_marks = 30,
  assignment_completion = 35, lms_engagement = 20,
  prev_gpa = 3.2, backlogs = 4, lab_performance = 32
))

cat("\n")

# ── Timer ────────────────────────────────────────────────────
end_time   <- Sys.time()
elapsed    <- round(difftime(end_time, start_time, units = "secs"), 1)

cat("╔══════════════════════════════════════════════════╗\n")
cat(sprintf("║  ✅ Pipeline Complete in %.1f seconds             ║\n", as.numeric(elapsed)))
cat("╠══════════════════════════════════════════════════╣\n")
cat("║  Next Step: Launch the Shiny Dashboard           ║\n")
cat("║  > shiny::runApp('dashboard/app.R')              ║\n")
cat("╚══════════════════════════════════════════════════╝\n")

# ── Save Final Dataset ───────────────────────────────────────
write_csv(full_df, "data/student_data_processed.csv")

# ── Save Trained Models ──────────────────────────────────────
if (!dir.exists("models/saved")) dir.create("models/saved")
saveRDS(rf_model, "models/saved/rf_model.rds")
saveRDS(dt_model, "models/saved/dt_model.rds")
saveRDS(lr_model, "models/saved/lr_model.rds")
cat("  ✔ Models saved to models/saved/\n")
cat("  ✔ Processed data saved to data/student_data_processed.csv\n\n")
cat("  Run shiny::runApp('dashboard/app.R') to launch the dashboard!\n")
