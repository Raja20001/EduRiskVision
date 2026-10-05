# ============================================================
# EduRiskVision — models/logistic_regression.R
# Multinomial Logistic Regression for risk classification
# ============================================================

library(caret)
library(nnet)   # multinom() for multinomial logistic regression

# ── Train Logistic Regression Model ─────────────────────────
train_logistic_regression <- function(train_features) {

  cat("\n[Model] Training Logistic Regression...\n")

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

  # Train multinomial logistic regression
  model <- train(
    risk_category ~ attendance + internal_marks + assignment_completion +
                    lms_engagement + prev_gpa + backlogs +
                    lab_performance + engagement_index + risk_index + has_backlog,
    data      = train_features,
    method    = "multinom",
    trControl = ctrl,
    trace     = FALSE,   # suppress multinom iteration output
    metric    = "Accuracy"
  )

  cat(sprintf("  ✔ Logistic Regression trained.\n"))
  cat(sprintf("     CV Accuracy : %.2f%%\n", max(model$results$Accuracy) * 100))

  return(model)
}

# ── Predict & Evaluate ───────────────────────────────────────
predict_logistic_regression <- function(model, test_features) {

  predictions <- predict(model, newdata = test_features)
  probs       <- predict(model, newdata = test_features, type = "prob")

  return(list(predictions = predictions, probs = probs))
}

# ── Coefficient Summary ──────────────────────────────────────
summarise_logistic_coefficients <- function(model) {
  cat("\n[Logistic Regression] Model Coefficients:\n")
  coef_df <- as.data.frame(coef(model$finalModel))
  print(round(coef_df, 4))
  return(coef_df)
}
