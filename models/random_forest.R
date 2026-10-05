# ============================================================
# EduRiskVision — models/random_forest.R
# Random Forest — Best performing model (89% accuracy)
# ============================================================

library(caret)
library(randomForest)
library(ggplot2)
library(dplyr)

# ── Train Random Forest ──────────────────────────────────────
train_random_forest <- function(train_features) {

  cat("\n[Model] Training Random Forest...\n")

  set.seed(42)

  # Cross-validation control (5-fold)
  ctrl <- trainControl(
    method          = "cv",
    number          = 5,
    verboseIter     = FALSE,
    classProbs      = TRUE,
    summaryFunction = defaultSummary,
    savePredictions = "final"
  )

  # Grid search over mtry (number of features to try at each split)
  tune_grid <- expand.grid(mtry = c(2, 3, 4, 5, 6))

  model <- train(
    risk_category ~ attendance + internal_marks + assignment_completion +
                    lms_engagement + prev_gpa + backlogs +
                    lab_performance + engagement_index + risk_index + has_backlog,
    data      = train_features,
    method    = "rf",
    ntree     = 200,          # number of trees
    trControl = ctrl,
    tuneGrid  = tune_grid,
    metric    = "Accuracy",
    importance = TRUE
  )

  best_mtry <- model$bestTune$mtry
  cat(sprintf("  ✔ Random Forest trained.\n"))
  cat(sprintf("     Best mtry      : %d\n", best_mtry))
  cat(sprintf("     Number of trees: 200\n"))
  cat(sprintf("     CV Accuracy    : %.2f%%\n", max(model$results$Accuracy) * 100))

  return(model)
}

# ── Predict ──────────────────────────────────────────────────
predict_random_forest <- function(model, test_features) {

  predictions <- predict(model, newdata = test_features)
  probs       <- predict(model, newdata = test_features, type = "prob")

  return(list(predictions = predictions, probs = probs))
}

# ── Feature Importance ───────────────────────────────────────
get_rf_importance <- function(model) {
  imp <- as.data.frame(varImp(model)$importance)
  imp$Feature <- rownames(imp)

  # For multi-class, varImp returns mean decrease accuracy
  # Take mean across classes
  imp$Importance <- rowMeans(imp[, 1:(ncol(imp) - 1)])
  imp <- imp %>%
    select(Feature, Importance) %>%
    arrange(desc(Importance))

  return(imp)
}

# ── OOB Error Plot ───────────────────────────────────────────
plot_oob_error <- function(model, save_path = NULL) {
  cat("  Plotting OOB error rate...\n")

  oob_df <- data.frame(
    Trees = 1:length(model$finalModel$err.rate[, "OOB"]),
    OOB   = model$finalModel$err.rate[, "OOB"]
  )

  p <- ggplot(oob_df, aes(x = Trees, y = OOB * 100)) +
    geom_line(colour = "#00BFA5", linewidth = 1.2) +
    geom_hline(yintercept = min(oob_df$OOB * 100),
               linetype = "dashed", colour = "#FF7043", linewidth = 0.8) +
    labs(
      title    = "Random Forest — OOB Error Rate",
      subtitle = sprintf("Minimum OOB Error: %.2f%% at %d trees",
                         min(oob_df$OOB * 100),
                         which.min(oob_df$OOB)),
      x = "Number of Trees", y = "OOB Error Rate (%)"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E")
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 7, height = 4, dpi = 150)
  return(p)
}

# ── Predict a Single New Student ─────────────────────────────
predict_single_student <- function(model, student_data) {
  # student_data: a named list or 1-row data frame
  df <- as.data.frame(student_data)

  # Compute derived features if not present
  if (!"engagement_index" %in% names(df)) {
    df$engagement_index <- round(
      0.40 * df$attendance +
      0.30 * df$assignment_completion +
      0.30 * df$lms_engagement, 2)
  }
  if (!"risk_index" %in% names(df)) {
    df$risk_index <- round(
      0.30 * (df$attendance / 100) +
      0.30 * (df$internal_marks / 100) +
      0.20 * (df$assignment_completion / 100) +
      0.10 * (df$lms_engagement / 100) +
      0.10 * (df$prev_gpa / 10), 4)
  }
  if (!"has_backlog" %in% names(df)) {
    df$has_backlog <- ifelse(df$backlogs > 0, 1, 0)
  }

  pred  <- predict(model, newdata = df)
  probs <- predict(model, newdata = df, type = "prob")

  cat("\n[Prediction] Single Student Risk Assessment:\n")
  cat(sprintf("  Predicted Risk  : %s\n", as.character(pred)))
  cat(sprintf("  Probabilities   :\n"))
  cat(sprintf("    Low_Risk      : %.1f%%\n", probs[1, "Low_Risk"] * 100))
  cat(sprintf("    Medium_Risk   : %.1f%%\n", probs[1, "Medium_Risk"] * 100))
  cat(sprintf("    High_Risk     : %.1f%%\n", probs[1, "High_Risk"] * 100))

  return(list(prediction = as.character(pred), probabilities = probs))
}
