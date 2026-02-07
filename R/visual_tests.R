#' Render Visual Tests from Example Files
#'
#' Renders all (or a subset of) example files from `inst/examples/` to PNG
#' images using the V8 + rsvg SVG export pipeline. Useful for verifying that
#' frontend changes produce correct visual output.
#'
#' @param pattern Optional regex pattern to filter example filenames (matched
#'   against basename). For example, `"jama"` matches `gallery_13_jama.R`.
#' @param output_dir Directory to save PNG files. Default is
#'   `"tests/visual/output"`.
#' @param width Plot width in pixels (default: 800).
#' @param scale Scaling factor for PNG output (default: 2 for retina quality).
#'
#' @return Invisibly returns a named list with `status`, `file`, and `error`
#'   for each example.
#'
#' @export
#' @examples
#' \dontrun{
#' render_visual_tests()
#' render_visual_tests("jama")
#' render_visual_tests("gallery_05")
#' }
render_visual_tests <- function(pattern = NULL, output_dir = "tests/visual/output",
                                width = 800, scale = 2) {
  checkmate::assert_string(pattern, null.ok = TRUE)
  checkmate::assert_string(output_dir)
  checkmate::assert_number(width, lower = 100)
  checkmate::assert_number(scale, lower = 0.5, upper = 10)

  # Check required packages
  if (!requireNamespace("V8", quietly = TRUE)) {
    cli_abort(c(
      "Package {.pkg V8} is required for {.fn render_visual_tests}",
      "i" = "Install it with: {.code install.packages(\"V8\")}"
    ))
  }
  if (!requireNamespace("rsvg", quietly = TRUE)) {
    cli_abort(c(
      "Package {.pkg rsvg} is required for {.fn render_visual_tests}",
      "i" = "Install it with: {.code install.packages(\"rsvg\")}"
    ))
  }

  # Get example files
  example_dir <- system.file("examples", package = "tabviz")
  if (example_dir == "") {
    # Fallback for development
    example_dir <- "inst/examples"
  }

  examples <- list.files(example_dir, pattern = "[.]R$", full.names = TRUE)

  if (length(examples) == 0) {
    cli::cli_warn("No example files found")
    return(invisible(list()))
  }

  # Filter by pattern if provided
  if (!is.null(pattern)) {
    matches <- grepl(pattern, basename(examples), ignore.case = TRUE)
    examples <- examples[matches]
    if (length(examples) == 0) {
      cli::cli_warn("No examples matched pattern {.val {pattern}}")
      return(invisible(list()))
    }
  }

  # Create output directory
  if (!dir.exists(output_dir)) {
    dir.create(output_dir, recursive = TRUE)
  }

  cli::cli_h1("Rendering Visual Tests")
  cli::cli_alert_info("Output directory: {.path {output_dir}}")
  cli::cli_alert_info("Examples to render: {length(examples)}")

  results <- list()

  for (ex in examples) {
    name <- tools::file_path_sans_ext(basename(ex))
    outfile <- file.path(output_dir, paste0(name, ".png"))

    res <- tryCatch({
      # Run example in clean environment
      env <- new.env(parent = globalenv())
      result <- source(ex, local = env)
      obj <- result$value

      # Determine object type and export
      if (S7_inherits(obj, WebSpec)) {
        save_plot(obj, outfile, width = width, scale = scale)
        cli::cli_alert_success("{.file {name}}")
        list(status = "success", file = outfile, error = NULL)
      } else if (S7_inherits(obj, SplitForest)) {
        # SplitForest: export first spec as representative
        first_key <- names(obj@specs)[[1]]
        save_plot(obj@specs[[first_key]], outfile, width = width, scale = scale)
        cli::cli_alert_success("{.file {name}} (first split)")
        list(status = "success", file = outfile, error = NULL)
      } else if (inherits(obj, "htmlwidget")) {
        # Try to extract WebSpec or SplitForest from widget
        spec <- attr(obj, "webspec")
        sf <- attr(obj, "splitforest")
        if (!is.null(sf) && S7_inherits(sf, SplitForest)) {
          first_key <- names(sf@specs)[[1]]
          save_plot(sf@specs[[first_key]], outfile, width = width, scale = scale)
          cli::cli_alert_success("{.file {name}} (first split)")
          list(status = "success", file = outfile, error = NULL)
        } else if (!is.null(spec) && S7_inherits(spec, WebSpec)) {
          save_plot(spec, outfile, width = width, scale = scale)
          cli::cli_alert_success("{.file {name}}")
          list(status = "success", file = outfile, error = NULL)
        } else {
          cli::cli_alert_warning("{.file {name}} - skipped (no extractable spec)")
          list(status = "skipped", file = NULL,
               error = "htmlwidget without extractable spec")
        }
      } else {
        cli::cli_alert_warning("{.file {name}} - skipped ({class(obj)[1]})")
        list(status = "skipped", file = NULL,
             error = "Not a WebSpec, SplitForest, or htmlwidget")
      }
    }, error = function(e) {
      cli::cli_alert_danger("{.file {name}} - {conditionMessage(e)}")
      list(status = "error", file = NULL, error = conditionMessage(e))
    })

    results[[name]] <- res
  }

  # Summary
  n_success <- sum(vapply(results, function(x) x$status == "success", logical(1)))
  n_skipped <- sum(vapply(results, function(x) x$status == "skipped", logical(1)))
  n_error <- sum(vapply(results, function(x) x$status == "error", logical(1)))

  cli::cli_h2("Summary")
  cli::cli_alert_info("Succeeded: {n_success}, Skipped: {n_skipped}, Failed: {n_error}")

  invisible(results)
}
