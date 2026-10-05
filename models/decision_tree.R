# ============================================================
# EduRiskVision — models/decision_tree.R
# Decision Tree (CART) for risk classification + visualization
# ============================================================

library(caret)
library(rpart)
library(rpart.plot)
library(ggplot2)

# ── Train Decision Tree ──────────────────────────────────────
train_decision_tree <- function(train_features) {

  cat("\n[Model] Training Decision Tree (CART)...\n")

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

  # Grid search over complexity parameter (cp)
  tune_grid <- expand.grid(cp = seq(0.001, 0.05, by = 0.002))

  model <- train(
    risk_category ~ attendance + internal_marks + assignment_completion +
                    lms_engagement + prev_gpa + backlogs +
                    lab_performance + engagement_index + risk_index + has_backlog,
    data      = train_features,
    method    = "rpart",
    trControl = ctrl,
    tuneGrid  = tune_grid,
    metric    = "Accuracy"
  )

  best_cp <- model$bestTune$cp
  cat(sprintf("  ✔ Decision Tree trained.\n"))
  cat(sprintf("     Best cp (complexity): %.4f\n", best_cp))
  cat(sprintf("     CV Accuracy         : %.2f%%\n", max(model$results$Accuracy) * 100))

  return(model)
}

# ── Predict ──────────────────────────────────────────────────
predict_decision_tree <- function(model, test_features) {

  predictions <- predict(model, newdata = test_features)
  probs       <- predict(model, newdata = test_features, type = "prob")

  return(list(predictions = predictions, probs = probs))
}

# ── Plot Decision Tree ───────────────────────────────────────
plot_decision_tree <- function(model, save_path = NULL) {
  cat("  Plotting Decision Tree structure...\n")

  if (!is.null(save_path)) {
    png(save_path, width = 1400, height = 900, res = 120)
  }

  rpart.plot(
    model$finalModel,
    type        = 4,
    extra       = 104,
    under       = TRUE,
    fallen.leaves = TRUE,
    main        = "EduRiskVision — Decision Tree",
    col         = "#012E2F",
    border.col  = "#014D4E",
    box.palette = list("Low_Risk"    = "#00695C",
                       "Medium_Risk" = "#00BFA5",
                       "High_Risk"   = "#FF7043"),
    shadow.col  = "gray80",
    nn          = TRUE,
    cex         = 0.75
  )

  if (!is.null(save_path)) dev.off()
}

# ── Variable Importance ──────────────────────────────────────
get_dt_importance <- function(model) {
  imp <- as.data.frame(varImp(model)$importance)
  imp$Feature <- rownames(imp)
  imp <- imp %>%
    rename(Importance = Overall) %>%
    arrange(desc(Importance))
  return(imp)
}
