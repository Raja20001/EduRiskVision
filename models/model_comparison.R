# ============================================================
# EduRiskVision — models/model_comparison.R
# Side-by-side comparison of all 3 trained models
# ============================================================

library(dplyr)
library(ggplot2)
library(gridExtra)

# ── Compare All Models ───────────────────────────────────────
compare_models <- function(lr_eval, dt_eval, rf_eval) {

  cat("\n╔══════════════════════════════════════════════╗\n")
  cat("║        MODEL COMPARISON SUMMARY              ║\n")
  cat("╠══════════════════════════════════════════════╣\n")

  results <- list(lr_eval, dt_eval, rf_eval)

  comparison_df <- data.frame(
    Model    = sapply(results, `[[`, "model_name"),
    Accuracy = sapply(results, `[[`, "accuracy"),
    Kappa    = sapply(results, `[[`, "kappa")
  )

  # Format table
  for (i in 1:nrow(comparison_df)) {
    is_best <- comparison_df$Accuracy[i] == max(comparison_df$Accuracy)
    badge   <- if (is_best) " ◄ BEST" else ""
    cat(sprintf("║  %-28s  %.2f%%  %s\n",
                comparison_df$Model[i],
                comparison_df$Accuracy[i],
                badge))
  }

  cat("╚══════════════════════════════════════════════╝\n")

  return(comparison_df)
}

# ── Accuracy + Kappa Comparison Plot ─────────────────────────
plot_full_comparison <- function(comparison_df, save_path = NULL) {

  df <- comparison_df
  df$Model <- factor(df$Model, levels = df$Model[order(df$Accuracy)])

  p1 <- ggplot(df, aes(x = Model, y = Accuracy, fill = Model)) +
    geom_col(width = 0.55, show.legend = FALSE) +
    geom_text(aes(label = paste0(Accuracy, "%")),
              hjust = -0.1, size = 4.2, fontface = "bold") +
    coord_flip(ylim = c(60, 100)) +
    scale_fill_manual(values = c("#00695C", "#00897B", "#00BFA5")) +
    labs(title = "Accuracy (%)", x = NULL, y = NULL) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", colour = "#012E2F"),
          panel.grid.major.y = element_blank())

  p2 <- ggplot(df, aes(x = Model, y = Kappa, fill = Model)) +
    geom_col(width = 0.55, show.legend = FALSE) +
    geom_text(aes(label = round(Kappa, 3)),
              hjust = -0.1, size = 4.2, fontface = "bold") +
    coord_flip(ylim = c(0, 1)) +
    scale_fill_manual(values = c("#00695C", "#00897B", "#00BFA5")) +
    labs(title = "Cohen's Kappa", x = NULL, y = NULL) +
    theme_minimal(base_size = 12) +
    theme(plot.title = element_text(face = "bold", colour = "#012E2F"),
          panel.grid.major.y = element_blank())

  combined <- grid.arrange(p1, p2, ncol = 2,
    top = grid::textGrob("EduRiskVision — Model Comparison",
                          gp = grid::gpar(fontsize = 15, fontface = "bold",
                                          col = "#012E2F")))

  if (!is.null(save_path))
    ggsave(save_path, combined, width = 10, height = 4, dpi = 150)

  return(combined)
}

# ── Cross-Validation Result Plot ─────────────────────────────
plot_cv_results <- function(lr_model, dt_model, rf_model, save_path = NULL) {

  extract_cv <- function(model, name) {
    res <- model$results
    best_idx <- which.max(res$Accuracy)
    data.frame(
      Model    = name,
      Accuracy = res$Accuracy[best_idx] * 100,
      AccSD    = res$AccuracySD[best_idx] * 100
    )
  }

  cv_df <- rbind(
    extract_cv(lr_model, "Logistic Regression"),
    extract_cv(dt_model, "Decision Tree"),
    extract_cv(rf_model, "Random Forest")
  )
  cv_df$Model <- factor(cv_df$Model, levels = cv_df$Model[order(cv_df$Accuracy)])

  p <- ggplot(cv_df, aes(x = Model, y = Accuracy, fill = Model)) +
    geom_col(width = 0.5, show.legend = FALSE) +
    geom_errorbar(aes(ymin = Accuracy - AccSD, ymax = Accuracy + AccSD),
                  width = 0.2, colour = "#014D4E") +
    geom_text(aes(label = paste0(round(Accuracy, 1), "%")),
              vjust = -1.2, size = 4.5, fontface = "bold") +
    ylim(60, 100) +
    scale_fill_manual(values = c("#00695C", "#00897B", "#00BFA5")) +
    labs(
      title    = "5-Fold Cross-Validation Accuracy",
      subtitle = "Error bars show ±1 SD across folds",
      x = NULL, y = "Accuracy (%)"
    ) +
    theme_minimal(base_size = 13) +
    theme(
      plot.title    = element_text(face = "bold", colour = "#012E2F"),
      plot.subtitle = element_text(colour = "#014D4E"),
      panel.grid.major.x = element_blank()
    )

  if (!is.null(save_path)) ggsave(save_path, p, width = 7, height = 5, dpi = 150)
  return(p)
}
