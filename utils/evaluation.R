# ============================================================
# EduRiskVision — utils/evaluation.R
# Model evaluation: confusion matrix, metrics, ROC, plots
# ============================================================

library(caret)
library(ggplot2)
library(pROC)

# ── 1. Full Evaluation Report ────────────────────────────────
evaluate_model <- function(model_name, actual, predicted, predicted_probs = NULL) {

  cat(sprintf("\n══════════════════════════════════════\n"))
  cat(sprintf(" Model: %s\n", model_name))
  cat(sprintf("══════════════════════════════════════\n"))

  # Confusion matrix
  cm <- confusionMatrix(
    factor(predicted, levels = c("Low_Risk", "Medium_Risk", "High_Risk")),
    factor(actual,    levels = c("Low_Risk", "Medium_Risk", "High_Risk"))
  )

  acc       <- round(cm$overall["Accuracy"] * 100, 2)
  kappa_val <- round(cm$overall["Kappa"], 4)

  cat(sprintf("  Accuracy  : %.2f%%\n", acc))
  cat(sprintf("  Kappa     : %.4f\n",  kappa_val))
  cat("\n  Confusion Matrix:\n")
  print(cm$table)

  cat("\n  Per-class Metrics:\n")
  per_class <- cm$byClass[, c("Sensitivity", "Specificity",
                               "Precision", "F1", "Balanced Accuracy")]
  print(round(per_class, 4))

  return(list(
    model_name = model_name,
    accuracy   = acc,
    kappa      = kappa_val,
    cm         = cm,
    cm_table   = cm$table,
    per_class  = per_class
  ))
}

# ── 2. Plot Confusion Matrix ─────────────────────────────────
plot_confusion_matrix <- function(eval_result, save_path = NULL) {

  cm_df <- as.data.frame(eval_result$cm_table)
  names(cm_df) <- c("Predicted", "Actual", "Freq")

  p <- ggplot(cm_df, aes(x = Predicted, y = Actual, fill = Freq)) +
    geom_tile(colour = "white", size = 0.8) +
    geom_text(aes(label = Freq), size = 7, fontface = "bold", colour = "white") +
    scale_fill_gradient(low = "#014D4E", high = "#00BFA5") +
    labs(
      title    = paste("Confusion Matrix —", eval_result$model_name),
      subtitle = sprintf("Accuracy: %.2f%%  |  Kappa: %.4f",
                         eval_result$accuracy, eval_result$kappa),
      x = "Predicted Class",
      y = "Actual Class"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E"),
      panel.grid    = element_blank(),
      legend.position = "none"
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 6, height = 5, dpi = 150)
  return(p)
}

# ── 3. Model Comparison Bar Chart ───────────────────────────
plot_model_comparison <- function(results_list, save_path = NULL) {

  df <- data.frame(
    Model    = sapply(results_list, `[[`, "model_name"),
    Accuracy = sapply(results_list, `[[`, "accuracy"),
    Kappa    = sapply(results_list, `[[`, "kappa")
  )

  df$Model <- factor(df$Model, levels = df$Model[order(df$Accuracy)])

  p <- ggplot(df, aes(x = Model, y = Accuracy, fill = Model)) +
    geom_col(width = 0.55, show.legend = FALSE) +
    geom_text(aes(label = paste0(Accuracy, "%")),
              hjust = -0.1, size = 4.5, fontface = "bold") +
    coord_flip(ylim = c(60, 100)) +
    scale_fill_manual(values = c("#00695C", "#00897B", "#00BFA5")) +
    labs(
      title    = "Model Accuracy Comparison",
      subtitle = "EduRiskVision — All Three Classifiers",
      x = NULL, y = "Accuracy (%)"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E"),
      panel.grid.major.y = element_blank()
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 7, height = 4, dpi = 150)
  return(p)
}

# ── 4. Feature Importance Plot ───────────────────────────────
plot_feature_importance <- function(importance_df, model_name, save_path = NULL) {

  importance_df <- importance_df %>%
    arrange(desc(Importance)) %>%
    head(10)

  importance_df$Feature <- factor(importance_df$Feature,
                                   levels = rev(importance_df$Feature))

  p <- ggplot(importance_df, aes(x = Feature, y = Importance, fill = Importance)) +
    geom_col(width = 0.6, show.legend = FALSE) +
    coord_flip() +
    scale_fill_gradient(low = "#014D4E", high = "#00BFA5") +
    labs(
      title    = paste("Feature Importance —", model_name),
      subtitle = "Higher score = stronger predictor of risk",
      x = NULL, y = "Importance Score"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E"),
      panel.grid.major.y = element_blank()
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 7, height = 5, dpi = 150)
  return(p)
}

# ── 5. Risk Distribution Plot ───────────────────────────────
plot_risk_distribution <- function(df, save_path = NULL) {

  risk_counts <- as.data.frame(table(df$risk_category))
  names(risk_counts) <- c("Risk", "Count")
  risk_counts$Pct <- round(100 * risk_counts$Count / sum(risk_counts$Count), 1)
  risk_counts$Risk <- factor(risk_counts$Risk,
                              levels = c("Low_Risk", "Medium_Risk", "High_Risk"))

  p <- ggplot(risk_counts, aes(x = Risk, y = Count, fill = Risk)) +
    geom_col(width = 0.5, show.legend = FALSE) +
    geom_text(aes(label = paste0(Count, "\n(", Pct, "%)")),
              vjust = -0.3, size = 4, fontface = "bold") +
    scale_fill_manual(values = c(
      "Low_Risk"    = "#00695C",
      "Medium_Risk" = "#00BFA5",
      "High_Risk"   = "#FF7043"
    )) +
    labs(
      title    = "Student Risk Distribution",
      subtitle = "Classified by EduRiskVision",
      x = "Risk Category", y = "Number of Students"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E"),
      panel.grid.major.x = element_blank()
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 6, height = 5, dpi = 150)
  return(p)
}

# ── 6. Attendance vs Marks Scatter ───────────────────────────
plot_attendance_vs_marks <- function(df, save_path = NULL) {

  p <- ggplot(df, aes(x = attendance, y = internal_marks, colour = risk_category)) +
    geom_point(alpha = 0.7, size = 2.2) +
    geom_smooth(method = "lm", se = FALSE, linewidth = 0.8) +
    scale_colour_manual(values = c(
      "Low_Risk"    = "#00695C",
      "Medium_Risk" = "#FFD54F",
      "High_Risk"   = "#FF7043"
    )) +
    labs(
      title    = "Attendance vs Internal Marks",
      subtitle = "Coloured by predicted risk category",
      x = "Attendance (%)", y = "Internal Marks (%)",
      colour = "Risk Category"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E"),
      legend.position = "bottom"
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 7, height = 5, dpi = 150)
  return(p)
}
