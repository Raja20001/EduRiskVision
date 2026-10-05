# ============================================================
# EduRiskVision — utils/preprocessing.R
# Data cleaning, validation, and feature engineering
# ============================================================

library(dplyr)
library(tidyr)

# ── 1. Validate Raw Data ────────────────────────────────────
validate_data <- function(df) {
  cat("\n[Preprocessing] Validating data...\n")

  issues <- list()

  # Check required columns
  required_cols <- c("attendance", "internal_marks", "assignment_completion",
                     "lms_engagement", "prev_gpa", "backlogs",
                     "lab_performance", "risk_category")

  missing_cols <- setdiff(required_cols, names(df))
  if (length(missing_cols) > 0) {
    stop(paste("Missing columns:", paste(missing_cols, collapse = ", ")))
  }

  # Check for missing values
  na_counts <- colSums(is.na(df))
  if (any(na_counts > 0)) {
    cat("  ⚠ Missing values detected:\n")
    print(na_counts[na_counts > 0])
    issues$has_na <- TRUE
  }

  # Range checks
  if (any(df$attendance < 0 | df$attendance > 100, na.rm = TRUE))
    issues$attendance_range <- TRUE

  if (any(df$internal_marks < 0 | df$internal_marks > 100, na.rm = TRUE))
    issues$marks_range <- TRUE

  if (any(df$prev_gpa < 0 | df$prev_gpa > 10, na.rm = TRUE))
    issues$gpa_range <- TRUE

  cat(sprintf("  ✔ Validation complete. Issues found: %d\n", length(issues)))
  return(issues)
}

# ── 2. Clean Data ────────────────────────────────────────────
clean_data <- function(df) {
  cat("[Preprocessing] Cleaning data...\n")

  original_rows <- nrow(df)

  df <- df %>%
    # Clamp numeric ranges
    mutate(
      attendance            = pmax(0, pmin(100, attendance)),
      internal_marks        = pmax(0, pmin(100, internal_marks)),
      assignment_completion = pmax(0, pmin(100, assignment_completion)),
      lms_engagement        = pmax(0, pmin(100, lms_engagement)),
      prev_gpa              = pmax(0, pmin(10,  prev_gpa)),
      backlogs              = pmax(0, backlogs),
      lab_performance       = pmax(0, pmin(100, lab_performance))
    ) %>%
    # Impute missing numerics with median
    mutate(across(where(is.numeric), ~ ifelse(is.na(.), median(., na.rm = TRUE), .))) %>%
    # Drop duplicate student IDs if any
    distinct(student_id, .keep_all = TRUE)

  removed <- original_rows - nrow(df)
  cat(sprintf("  ✔ Cleaned. Rows removed: %d. Remaining: %d\n", removed, nrow(df)))

  return(df)
}

# ── 3. Feature Engineering ───────────────────────────────────
engineer_features <- function(df) {
  cat("[Preprocessing] Engineering features...\n")

  df <- df %>%
    mutate(
      # Academic engagement index (weighted composite)
      engagement_index = round(
        0.40 * attendance +
        0.30 * assignment_completion +
        0.30 * lms_engagement, 2),

      # Performance gap: difference between expected and actual marks
      performance_gap = round(internal_marks - (attendance * 0.6 + 20), 2),

      # GPA tier grouping
      gpa_tier = case_when(
        prev_gpa >= 8.0 ~ "Distinction",
        prev_gpa >= 6.5 ~ "First Class",
        prev_gpa >= 5.0 ~ "Second Class",
        TRUE            ~ "Below Average"
      ),

      # Attendance tier
      attendance_tier = case_when(
        attendance >= 85 ~ "Excellent",
        attendance >= 75 ~ "Good",
        attendance >= 60 ~ "Average",
        TRUE             ~ "Poor"
      ),

      # At-risk flag (binary for logistic regression)
      at_risk_binary = ifelse(risk_category == "High_Risk", 1, 0),

      # Backlog flag
      has_backlog = ifelse(backlogs > 0, 1, 0),

      # Normalised features (0–1 scale) for ML
      att_norm   = round(attendance / 100, 4),
      marks_norm = round(internal_marks / 100, 4),
      gpa_norm   = round(prev_gpa / 10, 4),

      # Combined risk index
      risk_index = round(
        0.30 * att_norm +
        0.30 * marks_norm +
        0.20 * (assignment_completion / 100) +
        0.10 * (lms_engagement / 100) +
        0.10 * gpa_norm, 4
      )
    )

  cat(sprintf("  ✔ Feature engineering complete. New features added: %d\n",
              ncol(df) - 14))
  return(df)
}

# ── 4. Train-Test Split ──────────────────────────────────────
split_data <- function(df, train_ratio = 0.80, seed = 42) {
  cat(sprintf("[Preprocessing] Splitting data: %.0f%% train / %.0f%% test...\n",
              train_ratio * 100, (1 - train_ratio) * 100))

  set.seed(seed)
  n        <- nrow(df)
  train_idx <- sample(1:n, size = floor(train_ratio * n))

  train_df <- df[train_idx, ]
  test_df  <- df[-train_idx, ]

  cat(sprintf("  ✔ Train: %d rows | Test: %d rows\n", nrow(train_df), nrow(test_df)))

  return(list(train = train_df, test = test_df))
}

# ── 5. Prepare ML Features ───────────────────────────────────
prepare_ml_features <- function(df) {
  # Select only numeric predictors + target
  features <- df %>%
    select(
      attendance,
      internal_marks,
      assignment_completion,
      lms_engagement,
      prev_gpa,
      backlogs,
      lab_performance,
      engagement_index,
      risk_index,
      has_backlog,
      risk_category
    ) %>%
    mutate(risk_category = factor(risk_category,
                                  levels = c("Low_Risk", "Medium_Risk", "High_Risk")))
  return(features)
}

# ── 6. Summary Stats ─────────────────────────────────────────
summarise_data <- function(df) {
  cat("\n[Summary] Dataset Overview:\n")
  cat(sprintf("  Total students  : %d\n", nrow(df)))
  cat(sprintf("  Features        : %d\n", ncol(df)))
  cat(sprintf("  Departments     : %s\n", paste(unique(df$department), collapse = ", ")))

  cat("\n  Risk Distribution:\n")
  risk_tbl <- table(df$risk_category)
  for (tier in names(risk_tbl)) {
    pct <- round(100 * risk_tbl[tier] / sum(risk_tbl), 1)
    bar <- strrep("█", round(pct / 3))
    cat(sprintf("    %-14s : %3d (%5.1f%%)  %s\n", tier, risk_tbl[tier], pct, bar))
  }

  cat("\n  Key Feature Stats:\n")
  stats <- df %>%
    summarise(
      `Avg Attendance`    = round(mean(attendance, na.rm = TRUE), 1),
      `Avg Marks`         = round(mean(internal_marks, na.rm = TRUE), 1),
      `Avg GPA`           = round(mean(prev_gpa, na.rm = TRUE), 2),
      `Avg LMS Engagement`= round(mean(lms_engagement, na.rm = TRUE), 1)
    )
  print(as.data.frame(stats))
}
