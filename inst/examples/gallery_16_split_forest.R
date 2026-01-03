# Split Forest Example: Subgroup Analysis Navigation
#
# Demonstrates splitting a forest plot by categorical variables,
# creating a sidebar navigation for exploring subgroups.

library(webforest)

# Create mock clinical trial data with subgroup variables
set.seed(42)
n_studies <- 40

data <- data.frame(
  study = paste0("Study ", sprintf("%02d", 1:n_studies)),
  region = sample(c("North America", "Europe", "Asia Pacific"), n_studies, replace = TRUE,
                  prob = c(0.4, 0.35, 0.25)),
  age_group = sample(c("18-40", "41-65", "65+"), n_studies, replace = TRUE),
  sex = sample(c("Male", "Female"), n_studies, replace = TRUE),
  treatment = sample(c("Drug A", "Drug B"), n_studies, replace = TRUE)
)

# Generate effect sizes with some regional variation
base_effects <- c("North America" = 0.75, "Europe" = 0.80, "Asia Pacific" = 0.70)
data$or <- sapply(seq_len(n_studies), function(i) {
  base <- base_effects[data$region[i]]
  # Add some variation by age and treatment
  age_mod <- switch(data$age_group[i], "18-40" = 0.95, "41-65" = 1.0, "65+" = 1.05)
  trt_mod <- if (data$treatment[i] == "Drug A") 0.9 else 1.1
  exp(rnorm(1, log(base * age_mod * trt_mod), 0.3))
})

# Generate confidence intervals
data$se <- runif(n_studies, 0.15, 0.4)
data$lower <- data$or * exp(-1.96 * data$se)
data$upper <- data$or * exp(1.96 * data$se)

# Split by a single variable - creates flat navigation
single_split <- forest_plot(
  data,
  point = "or",
  lower = "lower",
  upper = "upper",
  label = "study",
  split_by = "region",
  scale = "log",
  null_value = 1,
  axis_label = "Odds Ratio (95% CI)",
  title = "Treatment Effect by Region"
)

# Split by multiple variables - creates hierarchical navigation
hierarchical_split <- data |>
  web_spec(
    point = "or",
    lower = "lower",
    upper = "upper",
    label = "study",
    scale = "log",
    null_value = 1,
    axis_label = "Odds Ratio (95% CI)",
    columns = list(
      col_text("region", header = "Region"),
      col_text("treatment", header = "Treatment"),
      col_numeric("or", header = "OR")
    )
  ) |>
  split_forest(by = c("sex", "age_group")) |>
  forest_plot()

# With shared axis for easier comparison across subgroups
shared_axis_split <- data |>
  web_spec(
    point = "or",
    lower = "lower",
    upper = "upper",
    label = "study",
    scale = "log",
    null_value = 1,
    axis_label = "Odds Ratio"
  ) |>
  split_forest(by = "treatment", shared_axis = TRUE) |>
  forest_plot()

# Return the hierarchical split as the main example
hierarchical_split
