# Gallery Example 7: Annotations & Reference Lines
# Custom reference lines with labels at specific values

library(tabviz)
library(dplyr)

annotation_data <- tibble(
  study = c("LOW-DOSE", "MID-DOSE", "HIGH-DOSE", "COMBO-A", "COMBO-B"),
  or = c(0.92, 0.75, 0.58, 0.62, 0.48),
  lower = c(0.78, 0.62, 0.45, 0.50, 0.38),
  upper = c(1.08, 0.91, 0.75, 0.77, 0.61),
  dose_mg = c(50, 100, 200, 150, 250)
)

tabviz(
  annotation_data,
  label = "study",
  columns = list(
    col_numeric("dose_mg", "Dose (mg)", width = 100),
    col_interval("OR (95% CI)"),
    viz_forest(
      point = "or", lower = "lower", upper = "upper",
      scale = "log", null_value = 1,
      axis_label = "Odds Ratio",
      annotations = list(
        refline(0.80, label = "Clinically meaningful", style = "dashed", color = "#16a34a"),
        refline(0.50, label = "Target effect", style = "solid", color = "#dc2626")
      )
    )
  ),
  theme = web_theme_modern(),
  title = "Annotations & Reference Lines",
  subtitle = "refline() adds labeled vertical lines",
  caption = "Green dashed = clinically meaningful threshold, Red solid = target"
)
