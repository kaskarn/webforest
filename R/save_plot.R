# Static image export for forest plots

#' Save a forest plot as a static image
#'
#' Exports a forest plot to a static file format (SVG, PDF, or PNG).
#' Uses native R graphics via the grid package for high-quality output.
#'
#' @param x A WebSpec object or forest_plot() htmlwidget output
#' @param file Output file path. Extension determines format:
#'   - `.svg` - Scalable Vector Graphics (requires svglite package)
#'   - `.pdf` - PDF document
#'   - `.png` - PNG image (requires ragg package for best quality)
#' @param width Plot width in inches (default: 10)
#' @param height Plot height in inches. If NULL (default), auto-calculated
#'   based on the number of rows
#' @param scale Scaling factor for all elements (default: 1). Values > 1
#'   increase font sizes, line widths, etc.
#' @param bg Background color. If NULL, uses theme background
#' @param dpi Resolution for PNG output (default: 300)
#' @param ... Additional arguments passed to the graphics device
#'
#' @return Invisibly returns the file path
#'
#' @examples
#' \dontrun{
#' # Create a forest plot spec
#' spec <- web_spec(
#'   data.frame(
#'     study = c("Study A", "Study B", "Study C"),
#'     estimate = c(1.2, 0.8, 1.5),
#'     lower = c(0.9, 0.5, 1.1),
#'     upper = c(1.6, 1.2, 2.0)
#'   ),
#'   point = "estimate",
#'   lower = "lower",
#'   upper = "upper",
#'   label = "study"
#' )
#'
#' # Save as SVG
#' save_plot(spec, "forest.svg")
#'
#' # Save as PDF with custom dimensions
#' save_plot(spec, "forest.pdf", width = 8, height = 6)
#'
#' # Save from htmlwidget output
#' p <- forest_plot(spec)
#' save_plot(p, "forest.svg")
#' }
#'
#' @export
save_plot <- function(x, file, width = 10, height = NULL, scale = 1,
                      bg = NULL, dpi = 300, ...) {
 # Validate inputs
  if (missing(file) || is.null(file)) {
    cli::cli_abort("{.arg file} is required")
  }

  # Extract WebSpec from input
  spec <- extract_webspec(x)

  # Validate spec
  if (is.null(spec)) {
    cli::cli_abort(c(
      "{.arg x} must be a WebSpec object or forest_plot() output",
      "i" = "Create a spec with {.fn web_spec} or plot with {.fn forest_plot}"
    ))
  }

  # Determine format from extension
  ext <- tolower(tools::file_ext(file))

  if (!ext %in% c("svg", "pdf", "png")) {
    cli::cli_abort(c(
      "Unsupported file format: {.file .{ext}}",
      "i" = "Supported formats: .svg, .pdf, .png"
    ))
  }

  # Compute layout
  layout <- compute_layout(spec, width = width, height = height, scale = scale)

  # Use theme background if not specified
  if (is.null(bg)) {
    bg <- spec@theme@colors@background
  }

  # Get graphics parameters from theme
  gpar_list <- theme_to_gpar(spec@theme)

  # Open appropriate device
  open_device(
    file = file,
    ext = ext,
    width = layout$total_width,
    height = layout$total_height,
    bg = bg,
    dpi = dpi,
    ...
  )

  # Ensure device is closed on exit
  on.exit(grDevices::dev.off(), add = TRUE)

  # Create new page
  grid::grid.newpage()

  # Render the forest plot
  render_forest_grid(spec, layout, gpar_list)

  cli::cli_alert_success("Saved plot to {.file {file}}")

  invisible(file)
}

#' Extract WebSpec from various input types
#'
#' @param x Input object (WebSpec, htmlwidget, or list)
#' @return WebSpec object or NULL
#' @noRd
extract_webspec <- function(x) {
  # Direct WebSpec (check S7 class)
  if (S7::S7_inherits(x, WebSpec)) {
    return(x)
  }

  # htmlwidget from forest_plot()
  if (inherits(x, "htmlwidget")) {
    # Check for attached spec
    spec <- attr(x, "webspec")
    if (!is.null(spec) && S7::S7_inherits(spec, WebSpec)) {
      return(spec)
    }

    # Try to extract from widget data
    # The x$x contains the serialized payload
    if (!is.null(x$x)) {
      cli::cli_warn(c(
        "Cannot extract WebSpec from htmlwidget",
        "i" = "Pass the WebSpec object directly to {.fn save_plot}"
      ))
    }
    return(NULL)
  }

  NULL
}

#' Open graphics device based on file extension
#'
#' @param file File path
#' @param ext File extension
#' @param width Width in inches
#' @param height Height in inches
#' @param bg Background color
#' @param dpi DPI for raster output
#' @param ... Additional arguments
#' @noRd
open_device <- function(file, ext, width, height, bg, dpi, ...) {
  switch(
    ext,
    svg = {
      if (!requireNamespace("svglite", quietly = TRUE)) {
        cli::cli_abort(c(
          "Package {.pkg svglite} is required for SVG output",
          "i" = "Install it with: {.code install.packages(\"svglite\")}"
        ))
      }
      svglite::svglite(
        filename = file,
        width = width,
        height = height,
        bg = bg,
        ...
      )
    },
    pdf = {
      grDevices::pdf(
        file = file,
        width = width,
        height = height,
        bg = bg,
        ...
      )
    },
    png = {
      if (requireNamespace("ragg", quietly = TRUE)) {
        ragg::agg_png(
          filename = file,
          width = width,
          height = height,
          units = "in",
          res = dpi,
          background = bg,
          ...
        )
      } else {
        grDevices::png(
          filename = file,
          width = width,
          height = height,
          units = "in",
          res = dpi,
          bg = bg,
          ...
        )
      }
    }
  )
}
