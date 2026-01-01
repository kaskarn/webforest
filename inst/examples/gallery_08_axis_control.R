# Gallery Example 8: Axis Control
# Custom range, explicit ticks, and gridlines

library(webforest)
library(dplyr)

axis_data <- tibble(
  study = c("Study A", "Study B", "Study C", "Study D", "Study E"),
  or = c(0.45, 0.72, 1.00, 1.35, 2.10),
  lower = c(0.28, 0.55, 0.78, 1.05, 1.52),
  upper = c(0.72, 0.94, 1.28, 1.74, 2.90)
)

forest_plot(
  axis_data,
  point = "or", lower = "lower", upper = "upper",
  label = "study",
  columns = list(col_interval("OR (95% CI)")),
  theme = web_theme_modern() |> set_axis(gridlines = TRUE, gridline_style = "dashed"),
  scale = "log", null_value = 1,
  axis_range = c(0.25, 4.0),
  axis_ticks = c(0.25, 0.5, 1, 2, 4),
  axis_label = "Odds Ratio (log scale)",
  title = "Axis Control",
  subtitle = "axis_range, axis_ticks, and gridlines",
  caption = "Custom range [0.25, 4.0] with explicit tick positions on log scale"
)
