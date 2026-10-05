# ============================================================
# EduRiskVision — data/generate_data.R
# Generates a realistic synthetic student academic dataset
# ============================================================

generate_student_data <- function(n = 500, seed = 42) {

  set.seed(seed)
  cat(sprintf("  Generating synthetic dataset with %d students...\n", n))

  # ── Student IDs ────────────────────────────────────────────
  student_id <- sprintf("STU%04d", 1:n)

  # ── Demographics ───────────────────────────────────────────
  gender       <- sample(c("Male", "Female"), n, replace = TRUE, prob = c(0.52, 0.48))
  department   <- sample(c("CSE", "ECE", "MECH", "CIVIL", "IT"), n, replace = TRUE)
  semester     <- sample(1:8, n, replace = TRUE)
  age          <- round(rnorm(n, mean = 20.5, sd = 1.5))
  age          <- pmax(18, pmin(26, age))

  # ── Academic Features ──────────────────────────────────────
  # Three performance groups: high / medium / low performers
  group <- sample(c("high", "medium", "low"), n, replace = TRUE, prob = c(0.55, 0.30, 0.15))

  attendance <- round(pmin(100, pmax(30, ifelse(
    group == "high",   rnorm(n, 88, 6),
    ifelse(group == "medium", rnorm(n, 73, 7), rnorm(n, 52, 10))
  ))))

  internal_marks <- round(pmin(100, pmax(10, ifelse(
    group == "high",   rnorm(n, 78, 8),
    ifelse(group == "medium", rnorm(n, 58, 8), rnorm(n, 36, 10))
  ))))

  assignment_completion <- round(pmin(100, pmax(0, ifelse(
    group == "high",   rnorm(n, 85, 8),
    ifelse(group == "medium", rnorm(n, 65, 10), rnorm(n, 40, 12))
  ))))

  lms_engagement <- round(pmin(100, pmax(0, ifelse(
    group == "high",   rnorm(n, 80, 9),
    ifelse(group == "medium", rnorm(n, 60, 9), rnorm(n, 35, 10))
  ))))

  prev_gpa <- round(pmin(10, pmax(2, ifelse(
    group == "high",   rnorm(n, 8.0, 0.8),
    ifelse(group == "medium", rnorm(n, 6.2, 0.8), rnorm(n, 4.2, 0.9))
  ))), 2)

  backlogs <- pmax(0, round(ifelse(
    group == "high",   rpois(n, 0.1),
    ifelse(group == "medium", rpois(n, 0.8), rpois(n, 2.5))
  )))

  lab_performance <- round(pmin(100, pmax(20, ifelse(
    group == "high",   rnorm(n, 80, 9),
    ifelse(group == "medium", rnorm(n, 62, 9), rnorm(n, 40, 10))
  ))))

  # ── Risk Score ─────────────────────────────────────────────
  raw_score <- (
    0.30 * attendance +
    0.30 * internal_marks +
    0.15 * assignment_completion +
    0.10 * lms_engagement +
    0.10 * (prev_gpa * 10) +
    0.05 * lab_performance
  )

  # Rescale to 0-100 so all 3 tiers are well-populated
  s_min <- min(raw_score)
  s_max <- max(raw_score)
  risk_score <- round(100 * (raw_score - s_min) / (s_max - s_min) + rnorm(n, 0, 3))
  risk_score <- pmax(0, pmin(100, risk_score))

  # ── Risk Category ───────────────────────────────────────────
  # Thresholds produce ~55-60% Low / ~25-30% Medium / ~13-15% High
  risk_category <- cut(
    risk_score,
    breaks = c(-Inf, 40, 65, Inf),
    labels = c("High_Risk", "Medium_Risk", "Low_Risk")
  )

  # ── Compose Data Frame ─────────────────────────────────────
  df <- data.frame(
    student_id,
    gender,
    department,
    semester,
    age,
    attendance,
    internal_marks,
    assignment_completion,
    lms_engagement,
    prev_gpa,
    backlogs,
    lab_performance,
    risk_score,
    risk_category,
    stringsAsFactors = FALSE
  )

  cat(sprintf("  Done: %d rows x %d columns\n", nrow(df), ncol(df)))
  cat("  Risk distribution:\n")
  print(table(df$risk_category))

  return(df)
}

# ── Run if executed directly ────────────────────────────────
if (!exists("SOURCED_BY_MAIN")) {
  df <- generate_student_data(500)
  readr::write_csv(df, "data/student_data.csv")
  cat("  Saved to data/student_data.csv\n")
}
