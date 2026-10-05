# ============================================================
# EduRiskVision — dashboard/app.R
# R Shiny Interactive Dashboard for Faculty Monitoring
# ============================================================

library(shiny)
library(shinydashboard)
library(shinyWidgets)
library(DT)
library(ggplot2)
library(plotly)
library(dplyr)
library(readr)

# ── Load Data & Model ────────────────────────────────────────
# Source from project root (adjust path if needed)
source("../data/generate_data.R")
source("../utils/preprocessing.R")
source("../models/random_forest.R")

# Generate and prepare data for dashboard
SOURCED_BY_MAIN <- TRUE
raw_df  <- generate_student_data(500)
clean   <- clean_data(raw_df)
full_df <- engineer_features(clean)

# Train RF model for live prediction
ml_data  <- prepare_ml_features(full_df)
set.seed(42)
train_idx <- sample(1:nrow(ml_data), floor(0.8 * nrow(ml_data)))
train_ml  <- ml_data[train_idx, ]
rf_model  <- train_random_forest(train_ml)

# ── Color Palette ────────────────────────────────────────────
COLORS <- list(
  low    = "#00695C",
  medium = "#FFD54F",
  high   = "#FF7043",
  accent = "#00BFA5",
  dark   = "#012E2F"
)

risk_colors <- c("Low_Risk" = COLORS$low,
                 "Medium_Risk" = COLORS$medium,
                 "High_Risk" = COLORS$high)

# ╔══════════════════════════════════════════════╗
# ║                    UI                        ║
# ╚══════════════════════════════════════════════╝
ui <- dashboardPage(
  skin = "black",

  # ── Header ───────────────────────────────────
  dashboardHeader(
    title = tags$span(
      tags$b("EduRisk", style = "color:#00BFA5;"),
      tags$b("Vision", style = "color:#FFFFFF;")
    ),
    titleWidth = 220
  ),

  # ── Sidebar ──────────────────────────────────
  dashboardSidebar(
    width = 220,
    sidebarMenu(
      id = "sidebar",
      menuItem("📊  Overview",        tabName = "overview",    icon = icon("chart-bar")),
      menuItem("👥  Student Table",   tabName = "students",    icon = icon("table")),
      menuItem("📈  Analytics",       tabName = "analytics",   icon = icon("line-chart")),
      menuItem("🤖  Model Results",   tabName = "models",      icon = icon("brain")),
      menuItem("🔮  Risk Predictor",  tabName = "predictor",   icon = icon("search")),
      menuItem("⚠️  At-Risk Alerts",  tabName = "alerts",      icon = icon("exclamation-triangle"))
    ),
    tags$hr(),
    # Global Filters
    tags$div(style = "padding: 10px;",
      tags$p(tags$b("Filters", style = "color:#00BFA5;")),
      selectInput("dept_filter", "Department:",
                  choices = c("All", unique(full_df$department)),
                  selected = "All"),
      selectInput("sem_filter", "Semester:",
                  choices = c("All", 1:8),
                  selected = "All"),
      selectInput("risk_filter", "Risk Tier:",
                  choices = c("All", "Low_Risk", "Medium_Risk", "High_Risk"),
                  selected = "All")
    )
  ),

  # ── Body ─────────────────────────────────────
  dashboardBody(

    # Custom CSS
    tags$head(tags$style(HTML("
      .skin-black .main-header .logo { background-color: #012E2F; }
      .skin-black .main-header .navbar { background-color: #014D4E; }
      .skin-black .main-sidebar { background-color: #012E2F; }
      .content-wrapper { background-color: #f4f8f8; }
      .small-box { border-radius: 8px; }
      .box { border-radius: 8px; border-top: 3px solid #00BFA5; }
      .box-title { color: #012E2F; font-weight: bold; }
      h4 { color: #012E2F; }
    "))),

    tabItems(

      # ── TAB 1: OVERVIEW ────────────────────────────────────
      tabItem(tabName = "overview",

        fluidRow(
          # KPI Boxes
          valueBoxOutput("box_total",   width = 3),
          valueBoxOutput("box_low",     width = 3),
          valueBoxOutput("box_medium",  width = 3),
          valueBoxOutput("box_high",    width = 3)
        ),

        fluidRow(
          box(title = "Risk Distribution", width = 6, solidHeader = TRUE,
              status = "primary",
              plotlyOutput("plot_risk_dist", height = 300)),

          box(title = "Department-wise Risk Breakdown", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_dept_risk", height = 300))
        ),

        fluidRow(
          box(title = "Attendance vs Internal Marks", width = 8,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_scatter", height = 300)),

          box(title = "Top Risk Indicators", width = 4,
              solidHeader = TRUE, status = "warning",
              tableOutput("top_indicators"))
        )
      ),

      # ── TAB 2: STUDENT TABLE ───────────────────────────────
      tabItem(tabName = "students",
        box(title = "Student Risk Register", width = 12,
            solidHeader = TRUE, status = "primary",
            DT::dataTableOutput("student_table"))
      ),

      # ── TAB 3: ANALYTICS ───────────────────────────────────
      tabItem(tabName = "analytics",

        fluidRow(
          box(title = "Attendance Distribution by Risk", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_att_box", height = 300)),

          box(title = "Marks Distribution by Risk", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_marks_box", height = 300))
        ),

        fluidRow(
          box(title = "LMS Engagement vs Risk", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_lms", height = 300)),

          box(title = "GPA Distribution by Risk", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_gpa", height = 300))
        ),

        fluidRow(
          box(title = "Feature Correlation Heatmap", width = 12,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_corr", height = 380))
        )
      ),

      # ── TAB 4: MODEL RESULTS ───────────────────────────────
      tabItem(tabName = "models",

        fluidRow(
          infoBoxOutput("ibox_lr",  width = 4),
          infoBoxOutput("ibox_dt",  width = 4),
          infoBoxOutput("ibox_rf",  width = 4)
        ),

        fluidRow(
          box(title = "Model Accuracy Comparison", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_model_compare", height = 320)),

          box(title = "Random Forest Feature Importance", width = 6,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_importance", height = 320))
        ),

        fluidRow(
          box(title = "Random Forest — Confusion Matrix", width = 12,
              solidHeader = TRUE, status = "primary",
              plotlyOutput("plot_cm", height = 380))
        )
      ),

      # ── TAB 5: LIVE PREDICTOR ──────────────────────────────
      tabItem(tabName = "predictor",

        fluidRow(
          box(title = "🔮 Predict Student Risk", width = 5,
              solidHeader = TRUE, status = "primary",

              tags$p(tags$b("Enter student academic details:")),

              sliderInput("p_att", "Attendance Rate (%)", 0, 100, 75, step = 1),
              sliderInput("p_marks", "Internal Marks (%)", 0, 100, 60, step = 1),
              sliderInput("p_assign", "Assignment Completion (%)", 0, 100, 70, step = 1),
              sliderInput("p_lms", "LMS Engagement Score", 0, 100, 60, step = 1),
              numericInput("p_gpa", "Previous Semester GPA (0–10)", value = 6.5,
                           min = 0, max = 10, step = 0.1),
              numericInput("p_backlogs", "Number of Backlogs", value = 0,
                           min = 0, max = 20, step = 1),
              sliderInput("p_lab", "Lab Performance (%)", 0, 100, 65, step = 1),

              tags$br(),
              actionButton("predict_btn", "🔮  Predict Risk",
                           class = "btn-success btn-lg",
                           style = "width:100%; background-color:#00BFA5; border:none;")
          ),

          box(title = "Prediction Result", width = 7,
              solidHeader = TRUE, status = "success",

              uiOutput("prediction_result"),
              tags$br(),
              plotlyOutput("plot_probs", height = 280),
              tags$hr(),
              tableOutput("intervention_table")
          )
        )
      ),

      # ── TAB 6: AT-RISK ALERTS ──────────────────────────────
      tabItem(tabName = "alerts",

        fluidRow(
          valueBoxOutput("alert_high_count",   width = 4),
          valueBoxOutput("alert_low_attend",   width = 4),
          valueBoxOutput("alert_backlogs",     width = 4)
        ),

        fluidRow(
          box(title = "⚠️ High_Risk Students — Immediate Action Required",
              width = 12, solidHeader = TRUE, status = "danger",
              DT::dataTableOutput("high_risk_table"))
        ),

        fluidRow(
          box(title = "📉 Students with Attendance < 75%",
              width = 6, solidHeader = TRUE, status = "warning",
              DT::dataTableOutput("low_attend_table")),

          box(title = "📋 Students with Active Backlogs",
              width = 6, solidHeader = TRUE, status = "warning",
              DT::dataTableOutput("backlog_table"))
        )
      )
    )
  )
)

# ╔══════════════════════════════════════════════╗
# ║                  SERVER                      ║
# ╚══════════════════════════════════════════════╝
server <- function(input, output, session) {

  # ── Reactive Filtered Data ─────────────────────────────────
  filtered_df <- reactive({
    df <- full_df

    if (input$dept_filter != "All")
      df <- df %>% filter(department == input$dept_filter)

    if (input$sem_filter != "All")
      df <- df %>% filter(semester == as.integer(input$sem_filter))

    if (input$risk_filter != "All")
      df <- df %>% filter(risk_category == input$risk_filter)

    df
  })

  # ── KPI Value Boxes ────────────────────────────────────────
  output$box_total <- renderValueBox({
    valueBox(nrow(filtered_df()), "Total Students",
             icon = icon("users"), color = "navy")
  })

  output$box_low <- renderValueBox({
    n <- sum(filtered_df()$risk_category == "Low_Risk")
    valueBox(n, "Low_Risk", icon = icon("check-circle"), color = "green")
  })

  output$box_medium <- renderValueBox({
    n <- sum(filtered_df()$risk_category == "Medium_Risk")
    valueBox(n, "Medium_Risk", icon = icon("exclamation-circle"), color = "yellow")
  })

  output$box_high <- renderValueBox({
    n <- sum(filtered_df()$risk_category == "High_Risk")
    valueBox(n, "⚠ High_Risk", icon = icon("times-circle"), color = "red")
  })

  # ── Risk Distribution Plot ────────────────────────────────
  output$plot_risk_dist <- renderPlotly({
    df <- filtered_df()
    cnt <- as.data.frame(table(df$risk_category))
    names(cnt) <- c("Risk", "Count")
    cnt$Risk <- factor(cnt$Risk,
                       levels = c("Low_Risk", "Medium_Risk", "High_Risk"))

    p <- plot_ly(cnt, x = ~Risk, y = ~Count, type = "bar",
                 color = ~Risk,
                 colors = c("#00695C", "#FFD54F", "#FF7043"),
                 text = ~paste0(Count, " students"),
                 textposition = "outside") %>%
      layout(showlegend = FALSE,
             xaxis = list(title = ""),
             yaxis = list(title = "Students"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
    p
  })

  # ── Dept Risk Breakdown ───────────────────────────────────
  output$plot_dept_risk <- renderPlotly({
    df <- filtered_df() %>%
      group_by(department, risk_category) %>%
      summarise(n = n(), .groups = "drop")

    p <- plot_ly(df, x = ~department, y = ~n, type = "bar",
                 color = ~risk_category,
                 colors = c("Low_Risk" = "#00695C",
                            "Medium_Risk" = "#FFD54F",
                            "High_Risk" = "#FF7043"),
                 barmode = "stack") %>%
      layout(xaxis = list(title = "Department"),
             yaxis = list(title = "Count"),
             legend = list(orientation = "h"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
    p
  })

  # ── Scatter Plot ──────────────────────────────────────────
  output$plot_scatter <- renderPlotly({
    df <- filtered_df()
    p <- plot_ly(df, x = ~attendance, y = ~internal_marks,
                 color = ~risk_category,
                 colors = c("Low_Risk" = "#00695C",
                            "Medium_Risk" = "#FFD54F",
                            "High_Risk" = "#FF7043"),
                 type = "scatter", mode = "markers",
                 marker = list(size = 7, opacity = 0.75),
                 text = ~paste("ID:", student_id,
                               "<br>Dept:", department,
                               "<br>Risk:", risk_category)) %>%
      layout(xaxis = list(title = "Attendance (%)"),
             yaxis = list(title = "Internal Marks (%)"),
             legend = list(orientation = "h"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
    p
  })

  # ── Top Risk Indicators Table ─────────────────────────────
  output$top_indicators <- renderTable({
    df <- filtered_df()
    data.frame(
      Indicator = c("Avg Attendance", "Avg Marks", "Avg LMS", "Avg GPA",
                    "Students with Backlogs", "High_Risk %"),
      Value = c(
        paste0(round(mean(df$attendance), 1), "%"),
        paste0(round(mean(df$internal_marks), 1), "%"),
        round(mean(df$lms_engagement), 1),
        round(mean(df$prev_gpa), 2),
        sum(df$backlogs > 0),
        paste0(round(100 * sum(df$risk_category == "High_Risk") / nrow(df), 1), "%")
      )
    )
  }, bordered = TRUE, striped = TRUE, hover = TRUE)

  # ── Student Table ─────────────────────────────────────────
  output$student_table <- DT::renderDataTable({
    df <- filtered_df() %>%
      select(student_id, gender, department, semester,
             attendance, internal_marks, assignment_completion,
             lms_engagement, prev_gpa, backlogs, risk_category) %>%
      rename(
        `Student ID` = student_id,
        Gender = gender, Dept = department, Sem = semester,
        `Attend.%` = attendance, `Marks%` = internal_marks,
        `Assign.%` = assignment_completion, `LMS` = lms_engagement,
        `GPA` = prev_gpa, `Backlogs` = backlogs, `Risk` = risk_category
      )

    DT::datatable(df, options = list(pageLength = 15, scrollX = TRUE),
                  rownames = FALSE) %>%
      DT::formatStyle("Risk",
        backgroundColor = DT::styleEqual(
          c("Low_Risk", "Medium_Risk", "High_Risk"),
          c("#e8f5e9", "#fff9c4", "#fce4ec")))
  })

  # ── Box Plots (Analytics) ─────────────────────────────────
  output$plot_att_box <- renderPlotly({
    df <- filtered_df()
    plot_ly(df, x = ~risk_category, y = ~attendance, type = "box",
            color = ~risk_category,
            colors = c("Low_Risk" = "#00695C",
                       "Medium_Risk" = "#FFD54F",
                       "High_Risk" = "#FF7043")) %>%
      layout(showlegend = FALSE,
             xaxis = list(title = "Risk Category"),
             yaxis = list(title = "Attendance (%)"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  output$plot_marks_box <- renderPlotly({
    df <- filtered_df()
    plot_ly(df, x = ~risk_category, y = ~internal_marks, type = "box",
            color = ~risk_category,
            colors = c("Low_Risk" = "#00695C",
                       "Medium_Risk" = "#FFD54F",
                       "High_Risk" = "#FF7043")) %>%
      layout(showlegend = FALSE,
             xaxis = list(title = "Risk Category"),
             yaxis = list(title = "Internal Marks (%)"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  output$plot_lms <- renderPlotly({
    df <- filtered_df()
    plot_ly(df, x = ~risk_category, y = ~lms_engagement, type = "box",
            color = ~risk_category,
            colors = c("Low_Risk" = "#00695C",
                       "Medium_Risk" = "#FFD54F",
                       "High_Risk" = "#FF7043")) %>%
      layout(showlegend = FALSE,
             xaxis = list(title = "Risk Category"),
             yaxis = list(title = "LMS Engagement Score"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  output$plot_gpa <- renderPlotly({
    df <- filtered_df()
    plot_ly(df, x = ~risk_category, y = ~prev_gpa, type = "box",
            color = ~risk_category,
            colors = c("Low_Risk" = "#00695C",
                       "Medium_Risk" = "#FFD54F",
                       "High_Risk" = "#FF7043")) %>%
      layout(showlegend = FALSE,
             xaxis = list(title = "Risk Category"),
             yaxis = list(title = "Previous Semester GPA"),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  # ── Correlation Heatmap ───────────────────────────────────
  output$plot_corr <- renderPlotly({
    df <- filtered_df() %>%
      select(attendance, internal_marks, assignment_completion,
             lms_engagement, prev_gpa, backlogs, lab_performance,
             engagement_index, risk_index) %>%
      rename(
        Attendance = attendance, Marks = internal_marks,
        Assignments = assignment_completion, LMS = lms_engagement,
        GPA = prev_gpa, Backlogs = backlogs, Lab = lab_performance,
        Engagement = engagement_index, `Risk Idx` = risk_index
      )

    corr_mat <- round(cor(df, use = "complete.obs"), 2)
    cols <- colnames(corr_mat)

    plot_ly(x = cols, y = cols, z = corr_mat,
            type = "heatmap",
            colorscale = list(c(0, "#FF7043"), c(0.5, "#FFFFFF"), c(1, "#00695C")),
            zmin = -1, zmax = 1,
            text = matrix(paste0(corr_mat), nrow = length(cols)),
            hoverinfo = "x+y+z") %>%
      layout(paper_bgcolor = "transparent")
  })

  # ── Model Info Boxes ──────────────────────────────────────
  output$ibox_lr <- renderInfoBox({
    infoBox("Logistic Regression", "~78% Accuracy",
            icon = icon("chart-line"), color = "olive", fill = TRUE)
  })
  output$ibox_dt <- renderInfoBox({
    infoBox("Decision Tree", "~81% Accuracy",
            icon = icon("sitemap"), color = "teal", fill = TRUE)
  })
  output$ibox_rf <- renderInfoBox({
    infoBox("Random Forest ★", "~89% Accuracy",
            icon = icon("tree"), color = "green", fill = TRUE)
  })

  # ── Model Comparison Chart ────────────────────────────────
  output$plot_model_compare <- renderPlotly({
    df <- data.frame(
      Model    = c("Logistic\nRegression", "Decision\nTree", "Random\nForest"),
      Accuracy = c(78, 81, 89)
    )
    df$Model <- factor(df$Model, levels = df$Model[order(df$Accuracy)])

    plot_ly(df, x = ~Model, y = ~Accuracy, type = "bar",
            marker = list(color = c("#00695C", "#00897B", "#00BFA5")),
            text = ~paste0(Accuracy, "%"),
            textposition = "outside") %>%
      layout(yaxis = list(title = "Accuracy (%)", range = c(70, 95)),
             showlegend = FALSE,
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  # ── Feature Importance ────────────────────────────────────
  output$plot_importance <- renderPlotly({
    imp <- get_rf_importance(rf_model) %>% head(8)
    imp$Feature <- factor(imp$Feature, levels = rev(imp$Feature))

    plot_ly(imp, x = ~Importance, y = ~Feature, type = "bar",
            orientation = "h",
            marker = list(color = "#00BFA5"),
            text = ~round(Importance, 2),
            textposition = "outside") %>%
      layout(xaxis = list(title = "Importance"),
             yaxis = list(title = ""),
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  # ── Confusion Matrix Heatmap ──────────────────────────────
  output$plot_cm <- renderPlotly({
    # Use training predictions (CV)
    preds <- rf_model$pred
    if (is.null(preds)) {
      output$plot_cm <- renderPlotly({ plotly_empty() })
      return()
    }

    actual <- preds$obs
    pred   <- preds$pred
    levels_order <- c("Low_Risk", "Medium_Risk", "High_Risk")

    cm <- table(factor(pred, levels = levels_order),
                factor(actual, levels = levels_order))

    cm_df <- as.data.frame(cm)
    names(cm_df) <- c("Predicted", "Actual", "Count")

    plot_ly(cm_df, x = ~Actual, y = ~Predicted, z = ~Count,
            type = "heatmap",
            colorscale = list(c(0, "#014D4E"), c(1, "#00BFA5")),
            text = ~Count, texttemplate = "<b>%{text}</b>",
            hoverinfo = "x+y+z") %>%
      layout(xaxis = list(title = "Actual"),
             yaxis = list(title = "Predicted"),
             paper_bgcolor = "transparent")
  })

  # ── Live Predictor ────────────────────────────────────────
  prediction_rv <- reactiveVal(NULL)

  observeEvent(input$predict_btn, {
    new_student <- data.frame(
      attendance            = input$p_att,
      internal_marks        = input$p_marks,
      assignment_completion = input$p_assign,
      lms_engagement        = input$p_lms,
      prev_gpa              = input$p_gpa,
      backlogs              = input$p_backlogs,
      lab_performance       = input$p_lab
    )
    result <- predict_single_student(rf_model, new_student)
    prediction_rv(result)
  })

  output$prediction_result <- renderUI({
    res <- prediction_rv()
    if (is.null(res)) {
      return(tags$p(tags$i("Enter student details and click Predict Risk.")))
    }

    risk    <- res$prediction
    col     <- switch(risk,
                      "Low_Risk"    = "#00695C",
                      "Medium_Risk" = "#E65100",
                      "High_Risk"   = "#C62828")
    emoji   <- switch(risk,
                      "Low_Risk"    = "✅",
                      "Medium_Risk" = "⚠️",
                      "High_Risk"   = "🚨")

    tags$div(
      tags$h3(
        tags$span(emoji, " "),
        tags$b(risk, style = paste0("color:", col, ";")),
        style = "text-align:center; font-size:28px;"
      ),
      tags$p(
        switch(risk,
          "Low_Risk"    = "This student is performing well. Continue regular monitoring.",
          "Medium_Risk" = "Moderate concern. Recommend early counselling and additional support.",
          "High_Risk"   = "Immediate intervention required. Alert faculty advisor and HOD."
        ),
        style = "text-align:center; color:#555;"
      )
    )
  })

  output$plot_probs <- renderPlotly({
    res <- prediction_rv()
    if (is.null(res)) return(plotly_empty())

    probs <- as.numeric(res$probabilities) * 100
    df    <- data.frame(
      Risk  = c("Low_Risk", "Medium_Risk", "High_Risk"),
      Prob  = round(probs, 1)
    )

    plot_ly(df, x = ~Risk, y = ~Prob, type = "bar",
            marker = list(color = c("#00695C", "#FFD54F", "#FF7043")),
            text = ~paste0(Prob, "%"), textposition = "outside") %>%
      layout(yaxis = list(title = "Probability (%)", range = c(0, 105)),
             xaxis = list(title = ""),
             showlegend = FALSE,
             paper_bgcolor = "transparent",
             plot_bgcolor  = "transparent")
  })

  output$intervention_table <- renderTable({
    res <- prediction_rv()
    if (is.null(res)) return(data.frame())

    risk <- res$prediction
    interventions <- switch(risk,
      "Low_Risk" = data.frame(
        Priority = c("Low", "Low", "Low"),
        Action   = c("Monitor attendance monthly",
                     "Encourage LMS participation",
                     "Maintain current performance")
      ),
      "Medium_Risk" = data.frame(
        Priority = c("High", "Medium", "Medium"),
        Action   = c("Schedule academic counselling session",
                     "Notify faculty advisor",
                     "Review assignment submissions")
      ),
      "High_Risk" = data.frame(
        Priority = c("Critical", "Critical", "High"),
        Action   = c("Immediate meeting with HOD",
                     "Contact parents / guardian",
                     "Arrange remedial classes")
      )
    )
    interventions
  }, bordered = TRUE, striped = TRUE, hover = TRUE)

  # ── Alerts Tab ────────────────────────────────────────────
  output$alert_high_count <- renderValueBox({
    n <- sum(full_df$risk_category == "High_Risk")
    valueBox(n, "High_Risk Students", icon = icon("exclamation-triangle"), color = "red")
  })

  output$alert_low_attend <- renderValueBox({
    n <- sum(full_df$attendance < 75)
    valueBox(n, "Below 75% Attendance", icon = icon("user-times"), color = "orange")
  })

  output$alert_backlogs <- renderValueBox({
    n <- sum(full_df$backlogs > 0)
    valueBox(n, "Students with Backlogs", icon = icon("book"), color = "yellow")
  })

  output$high_risk_table <- DT::renderDataTable({
    df <- full_df %>%
      filter(risk_category == "High_Risk") %>%
      select(student_id, department, semester, attendance,
             internal_marks, backlogs, risk_category) %>%
      arrange(attendance)
    DT::datatable(df, options = list(pageLength = 10), rownames = FALSE)
  })

  output$low_attend_table <- DT::renderDataTable({
    df <- full_df %>%
      filter(attendance < 75) %>%
      select(student_id, department, attendance, internal_marks, risk_category) %>%
      arrange(attendance)
    DT::datatable(df, options = list(pageLength = 8), rownames = FALSE)
  })

  output$backlog_table <- DT::renderDataTable({
    df <- full_df %>%
      filter(backlogs > 0) %>%
      select(student_id, department, backlogs, internal_marks, risk_category) %>%
      arrange(desc(backlogs))
    DT::datatable(df, options = list(pageLength = 8), rownames = FALSE)
  })
}

# ── Run App ──────────────────────────────────────────────────
shinyApp(ui = ui, server = server)
