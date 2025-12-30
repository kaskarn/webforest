# webforest

[![R-CMD-check](https://github.com/kaskarn/webforest/actions/workflows/R-CMD-check.yaml/badge.svg)](https://github.com/kaskarn/webforest/actions/workflows/R-CMD-check.yaml)

Interactive, web-native forest plots for R. Built with Svelte 5 and D3.js.

## Installation

```r
# install.packages("pak")
pak::pak("kaskarn/webforest")
```

## Usage

```r
library(webforest)

data <- data.frame(
  study = c("Smith 2020", "Jones 2021", "Lee 2022"),
  hr = c(0.72, 0.85, 0.91),
  lower = c(0.55, 0.70, 0.75),
  upper = c(0.95, 1.03, 1.10)
)

forest_plot(data,
  point = "hr",
  lower = "lower",
  upper = "upper",
  label = "study",
  null_value = 1,
  scale = "log"
)
```

## Features

- **Publication themes** — JAMA, Lancet, modern, presentation, dark, minimal
- **Flexible columns** — numeric, interval, bar charts, p-values, sparklines
- **Hierarchical groups** — collapsible sections with nested subgroups
- **Interactive** — hover highlights, row selection, tooltips
- **Customizable** — fluent API for theme modification

```r
# Customize any preset theme
web_theme_jama() |>
  set_colors(primary = "#0066cc") |>
  set_axis(gridlines = TRUE, range_min = 0.5, range_max = 2.0)
```

## Documentation

- [Package guide](https://kaskarn.github.io/webforest/webforest-guide.html)
- [Function reference](https://kaskarn.github.io/webforest/reference/)

## License

MIT
