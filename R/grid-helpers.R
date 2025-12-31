# Grid graphics helper functions for static plot rendering

#' Parse CSS-like font size to points
#'
#' @param size Character font size (e.g., "0.875rem", "12pt", "14px")
#' @param base_pt Base font size in points (default 12)
#' @return Numeric font size in points
#' @noRd
parse_font_size <- function(size, base_pt = 12) {
  if (is.numeric(size)) return(size)
  if (is.null(size) || is.na(size)) return(base_pt)

  size <- tolower(trimws(size))

  # Extract number and unit
  num <- as.numeric(gsub("[^0-9.]", "", size))
  if (is.na(num)) return(base_pt)

  if (grepl("rem$", size)) {
    # rem is relative to root font size (assume 16px = 12pt base)
    return(num * base_pt)
  } else if (grepl("em$", size)) {
    return(num * base_pt)
  } else if (grepl("pt$", size)) {
    return(num)
  } else if (grepl("px$", size)) {
    # Convert px to pt (approximately 0.75)
    return(num * 0.75)
  } else {
    # Assume raw number is points
    return(num)
  }
}

#' Parse CSS font family to R-compatible font
#'
#' @param family CSS font-family string
#' @return R font family name
#' @noRd
parse_font_family <- function(family) {
  if (is.null(family) || family == "") return("sans")

  # Common CSS to R mappings
  family <- tolower(family)

  if (grepl("serif", family) && !grepl("sans", family)) {
    return("serif")
  } else if (grepl("mono", family)) {
    return("mono")
  } else {
    return("sans")
  }
}

#' Convert WebTheme to grid gpar objects
#'
#' @param theme WebTheme object
#' @return List of gpar objects for different element types
#' @noRd
theme_to_gpar <- function(theme) {
  colors <- theme@colors
  typo <- theme@typography
  shapes <- theme@shapes

  base_fontsize <- parse_font_size(typo@font_size_base)
  fontfamily <- parse_font_family(typo@font_family)

  list(
    # Text styling
    text = grid::gpar(
      fontsize = base_fontsize,
      fontfamily = fontfamily,
      col = colors@foreground
    ),
    text_sm = grid::gpar(
      fontsize = parse_font_size(typo@font_size_sm),
      fontfamily = fontfamily,
      col = colors@foreground
    ),
    text_muted = grid::gpar(
      fontsize = parse_font_size(typo@font_size_sm),
      fontfamily = fontfamily,
      col = colors@secondary
    ),
    text_header = grid::gpar(
      fontsize = base_fontsize,
      fontfamily = fontfamily,
      fontface = "bold",
      col = colors@foreground
    ),

    # Interval/forest plot elements
    interval_line = grid::gpar(
      col = colors@interval_line,
      lwd = shapes@line_width
    ),
    interval_positive = grid::gpar(
      fill = colors@interval_positive,
      col = colors@interval_positive
    ),
    interval_negative = grid::gpar(
      fill = colors@interval_negative,
      col = colors@interval_negative
    ),
    interval_neutral = grid::gpar(
      fill = colors@interval_neutral,
      col = colors@interval_neutral
    ),

    # Summary diamond
    summary = grid::gpar(
      fill = colors@summary_fill,
      col = colors@summary_border,
      lwd = 1
    ),

    # Axis/grid
    axis_line = grid::gpar(
      col = colors@border,
      lwd = 1
    ),
    gridline = grid::gpar(
      col = colors@border,
      lwd = 0.5,
      lty = "dotted"
    ),
    null_line = grid::gpar(
      col = colors@muted,
      lwd = 1,
      lty = "dashed"
    ),

    # Background
    background = grid::gpar(
      fill = colors@background,
      col = NA
    )
  )
}

#' Compute layout dimensions for static rendering
#'
#' Mirrors the layout computation from forestStore.svelte.ts
#'
#' @param spec WebSpec object
#' @param width Total width in inches
#' @param height Total height in inches (NULL for auto)
#' @param scale Scaling factor
#' @return List with computed layout dimensions
#' @noRd
compute_layout <- function(spec, width = 10, height = NULL, scale = 1) {
  theme <- spec@theme
  spacing <- theme@spacing
  layout_config <- theme@layout

  # Row dimensions (convert from pixels to inches, ~72 pixels per inch)
  px_per_inch <- 72
  row_height <- (spacing@row_height / px_per_inch) * scale
  header_height <- (spacing@header_height / px_per_inch) * scale
  axis_height <- 0.4 * scale  # Fixed axis space
  padding <- (spacing@padding / px_per_inch) * scale

  # Count rows
  data <- spec@data
  n_rows <- nrow(data)

  # Check for overall summary
  has_overall <- !is.null(spec@overall_summary)

  # Calculate plot height from row count
  plot_height <- n_rows * row_height
  if (has_overall) {
    plot_height <- plot_height + row_height * 1.5
  }

  # Auto-calculate height if not provided
  if (is.null(height)) {
    height <- plot_height + header_height + axis_height + padding * 2
  }

  # Forest plot width (default 35% of total width)
  forest_width <- width * 0.35
  table_width <- width - forest_width - 0.1  # Small gap

  # Column gap
  column_gap <- (spacing@column_gap / px_per_inch) * scale

  list(
    total_width = width,
    total_height = height,
    table_width = table_width,
    forest_width = forest_width,
    header_height = header_height,
    row_height = row_height,
    plot_height = plot_height,
    axis_height = axis_height,
    padding = padding,
    column_gap = column_gap,
    n_rows = n_rows,
    has_overall = has_overall,
    null_value = spec@null_value %||% 0,
    scale_type = spec@scale %||% "linear"
  )
}

#' Compute x-scale function (linear or log)
#'
#' Creates a function that maps data values to x positions
#'
#' @param spec WebSpec object
#' @param forest_width Width of forest plot area in inches
#' @return Function that maps numeric values to x positions
#' @noRd
compute_x_scale <- function(spec, forest_width) {
  data <- spec@data
  axis_config <- spec@theme@axis
  scale_type <- spec@scale %||% "linear"
  padding_frac <- 0.15

  # Get data range
  lower_vals <- data[[spec@lower_col]]
  upper_vals <- data[[spec@upper_col]]
  all_vals <- c(lower_vals, upper_vals)
  all_vals <- all_vals[is.finite(all_vals)]

  if (length(all_vals) == 0) {
    return(function(x) x * forest_width)
  }

  data_min <- min(all_vals, na.rm = TRUE)
  data_max <- max(all_vals, na.rm = TRUE)

  # Check for explicit range in theme
  range_min <- axis_config@range_min
  range_max <- axis_config@range_max

  if (is.na(range_min)) {
    range <- data_max - data_min
    range_min <- data_min - range * padding_frac
  }
  if (is.na(range_max)) {
    range <- data_max - data_min
    range_max <- data_max + range * padding_frac
  }

  # Create scale function
  if (scale_type == "log") {
    # Ensure positive domain for log scale
    range_min <- max(range_min, 0.01)
    range_max <- max(range_max, 0.02)

    function(x) {
      log_min <- log(range_min)
      log_max <- log(range_max)
      log_x <- log(pmax(x, range_min))
      ((log_x - log_min) / (log_max - log_min)) * forest_width
    }
  } else {
    function(x) {
      ((x - range_min) / (range_max - range_min)) * forest_width
    }
  }
}

#' Get point color based on direction relative to null
#'
#' @param point Point estimate value
#' @param null_value Null/reference value
#' @param gpar_list List of gpar objects from theme_to_gpar
#' @return gpar object for the point color
#' @noRd
get_point_gpar <- function(point, null_value, gpar_list) {
  if (is.na(point)) return(gpar_list$interval_neutral)

  if (point > null_value) {
    gpar_list$interval_positive
  } else if (point < null_value) {
    gpar_list$interval_negative
  } else {
    gpar_list$interval_neutral
  }
}

#' Generate nice tick values for axis
#'
#' @param spec WebSpec object
#' @param x_scale Scale function
#' @param forest_width Width in inches
#' @return Numeric vector of tick values
#' @noRd
compute_axis_ticks <- function(spec, x_scale, forest_width) {
  axis_config <- spec@theme@axis

  # Use explicit ticks if provided
  if (!is.null(axis_config@tick_values) && length(axis_config@tick_values) > 0) {
    return(axis_config@tick_values)
  }

  # Get data range for tick generation
  data <- spec@data
  lower_vals <- data[[spec@lower_col]]
  upper_vals <- data[[spec@upper_col]]
  all_vals <- c(lower_vals, upper_vals)
  all_vals <- all_vals[is.finite(all_vals)]

  if (length(all_vals) == 0) {
    return(c(0, 0.5, 1))
  }

  # Determine range
  range_min <- axis_config@range_min
  range_max <- axis_config@range_max

  if (is.na(range_min)) range_min <- min(all_vals) * 0.85
  if (is.na(range_max)) range_max <- max(all_vals) * 1.15

  # Generate nice ticks
  tick_count <- if (!is.na(axis_config@tick_count)) axis_config@tick_count else 5
  pretty(c(range_min, range_max), n = tick_count)
}

#' Format tick value for display
#'
#' @param value Numeric tick value
#' @return Formatted string
#' @noRd
format_tick <- function(value) {
  if (abs(value) < 0.01) return("0")
  if (abs(value) >= 100) return(sprintf("%.0f", value))
  if (abs(value) >= 10) return(sprintf("%.1f", value))
  sprintf("%.2f", value)
}

# NULL coalescing operator
`%||%` <- function(x, y) if (is.null(x)) y else x
