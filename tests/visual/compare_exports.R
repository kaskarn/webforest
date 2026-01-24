# Visual Comparison Script for SVG Export Testing
#
# This script helps compare web rendering vs SVG export to verify WYSIWYG behavior.
# It generates side-by-side comparisons of gallery examples.
#
# Usage:
#   source("tests/visual/compare_exports.R")
#   compare_example("gallery_15_minimal")  # Compare single example
#   compare_all_galleries()                # Compare all gallery examples

# Note: Don't load webforest as it masks tabviz functions
library(htmltools)

# Get package root directory
get_pkg_root <- function() {

  # When developing, use current working directory or walk up to find DESCRIPTION
  # Start from current dir and walk up
  path <- getwd()
  for (i in 1:5) {
    if (file.exists(file.path(path, "DESCRIPTION"))) {
      return(path)
    }
    path <- dirname(path)
  }

  # Fall back to installed package location
  pkg_path <- system.file(package = "tabviz")
  if (nzchar(pkg_path) && file.exists(file.path(pkg_path, "DESCRIPTION"))) {
    return(pkg_path)
  }

  stop("Could not find package root directory. Run from package directory.")
}

# Gallery examples in order of complexity (simple to complex)
gallery_examples <- c(
  "gallery_15_minimal",      # 6 rows, log scale, minimal
  "gallery_03_table_only",   # no forest column
  "gallery_01_nested_groups", # hierarchy
  "gallery_02_multi_effects", # multiple effects
  "gallery_04_custom_theme",
  "gallery_05_sparklines_bars",
  "gallery_06_row_styling",
  "gallery_07_annotations",
  "gallery_08_axis_control",
  "gallery_09_clinical_trial",
  "gallery_10_exec_dashboard",
  "gallery_11_meta_analysis",
  "gallery_12_full_monty",
  "gallery_13_jama",
  "gallery_14_lancet",
  "gallery_16_split_table"
)

#' Generate visual comparison for a single example
#'
#' @param example_name Name of the gallery example (without .R extension)
#' @param output_dir Directory to save comparison files
#' @return Invisible path to comparison HTML file
compare_example <- function(example_name, output_dir = "tests/visual/output") {
  pkg_root <- get_pkg_root()

  # Create output directory
  dir.create(output_dir, recursive = TRUE, showWarnings = FALSE)

  # Source the example to get the plot
  example_file <- file.path(pkg_root, "inst", "examples", paste0(example_name, ".R"))
  if (!file.exists(example_file)) {
    stop("Example file not found: ", example_file)
  }

  message("Processing: ", example_name)

  # Create a new environment to source into
  env <- new.env(parent = globalenv())

  # Source and capture the result (many examples don't assign to a variable)
  result <- tryCatch({
    source(example_file, local = env, echo = FALSE)
  }, error = function(e) {
    warning("Error sourcing ", example_name, ": ", e$message)
    return(NULL)
  })

  # The last expression result is often the plot
  plot_obj <- NULL

  # Check if source returned a value (last expression)
  if (!is.null(result) && !is.null(result$value)) {
    if (inherits(result$value, "webspec") ||
        inherits(result$value, "htmlwidget") ||
        inherits(result$value, "SplitForest")) {
      plot_obj <- result$value
    }
  }

  # If not found, look for named objects
  if (is.null(plot_obj)) {
    plot_names <- c("plot", "forest_plot", "fp", "spec", "widget")
    for (name in plot_names) {
      if (exists(name, envir = env)) {
        obj <- get(name, envir = env)
        if (inherits(obj, "webspec") || inherits(obj, "htmlwidget") || inherits(obj, "SplitForest")) {
          plot_obj <- obj
          break
        }
      }
    }
  }

  # If still not found, look for any webspec/htmlwidget object
if (is.null(plot_obj)) {
    for (name in ls(env)) {
      obj <- get(name, envir = env)
      if (inherits(obj, "webspec") || inherits(obj, "htmlwidget") || inherits(obj, "SplitForest")) {
        plot_obj <- obj
        break
      }
    }
  }

  if (is.null(plot_obj)) {
    warning("No webspec/htmlwidget object found in ", example_name)
    return(invisible(NULL))
  }

  # Export SVG
  svg_file <- file.path(output_dir, paste0(example_name, ".svg"))
  tryCatch({
    save_plot(plot_obj, svg_file, format = "svg")
    message("  SVG saved: ", svg_file)
  }, error = function(e) {
    warning("  SVG export failed: ", e$message)
    return(invisible(NULL))
  })

  # Generate comparison HTML
  html_file <- file.path(output_dir, paste0(example_name, "_comparison.html"))

  html_content <- sprintf('<!DOCTYPE html>
<html>
<head>
  <title>%s - Visual Comparison</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 20px; background: #f5f5f5; }
    h1 { color: #333; margin-bottom: 10px; }
    .comparison { display: flex; gap: 20px; }
    .panel { flex: 1; background: white; padding: 15px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
    .panel h2 { margin-top: 0; color: #666; font-size: 14px; }
    .svg-container { border: 1px solid #ddd; overflow: auto; }
    .svg-container img { max-width: 100%%; height: auto; }
    .notes { margin-top: 20px; padding: 15px; background: #fff9c4; border-radius: 8px; }
    .notes h3 { margin-top: 0; }
  </style>
</head>
<body>
  <h1>%s</h1>
  <div class="comparison">
    <div class="panel">
      <h2>SVG Export</h2>
      <div class="svg-container">
        <img src="%s.svg" alt="SVG Export">
      </div>
    </div>
  </div>
  <div class="notes">
    <h3>Verification Checklist</h3>
    <ul>
      <li>[ ] Interval lines align with axis bounds</li>
      <li>[ ] Arrow positions match clipping boundaries</li>
      <li>[ ] Point markers are correctly positioned</li>
      <li>[ ] Column headers align with content</li>
      <li>[ ] Reference lines at correct positions</li>
      <li>[ ] Axis labels readable and correctly positioned</li>
    </ul>
  </div>
</body>
</html>', example_name, example_name, example_name)

  writeLines(html_content, html_file)
  message("  Comparison HTML: ", html_file)

  invisible(html_file)
}

#' Compare all gallery examples
#'
#' @param output_dir Directory to save comparison files
#' @return Invisible list of comparison file paths
compare_all_galleries <- function(output_dir = "tests/visual/output") {
  results <- list()

  for (example in gallery_examples) {
    tryCatch({
      result <- compare_example(example, output_dir)
      results[[example]] <- result
    }, error = function(e) {
      warning("Failed to process ", example, ": ", e$message)
      results[[example]] <- NULL
    })
  }

  # Generate index HTML
  index_file <- file.path(output_dir, "index.html")

  links <- sapply(names(results), function(name) {
    if (!is.null(results[[name]])) {
      sprintf('  <li><a href="%s_comparison.html">%s</a></li>', name, name)
    } else {
      sprintf('  <li><span style="color: red;">%s (failed)</span></li>', name)
    }
  })

  index_html <- sprintf('<!DOCTYPE html>
<html>
<head>
  <title>Visual Comparison Index</title>
  <style>
    body { font-family: system-ui, sans-serif; margin: 40px; }
    h1 { color: #333; }
    ul { line-height: 2; }
    a { color: #2563eb; }
  </style>
</head>
<body>
  <h1>SVG Export Visual Comparisons</h1>
  <ul>
%s
  </ul>
</body>
</html>', paste(links, collapse = "\n"))

  writeLines(index_html, index_file)
  message("\nIndex file: ", index_file)

  invisible(results)
}

#' Quick test with minimal example
#'
#' @return Path to comparison file
quick_test <- function() {
  compare_example("gallery_15_minimal")
}

message("Visual comparison functions loaded.")
message("  compare_example('gallery_15_minimal')  # Single example")
message("  compare_all_galleries()                # All examples")
message("  quick_test()                           # Quick minimal test")
