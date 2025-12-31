# Grid rendering functions for static forest plot output

#' Render a single interval row (CI line + whiskers + point)
#'
#' Mirrors RowInterval.svelte rendering
#'
#' @param point Point estimate
#' @param lower Lower bound
#' @param upper Upper bound
#' @param y_pos Y position (from top, in npc units)
#' @param x_scale Scale function
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @param null_value Null/reference value
#' @noRd
render_interval <- function(point, lower, upper, y_pos, x_scale, layout, gpar_list, null_value) {
  # Skip if missing values
  if (is.na(point) || is.na(lower) || is.na(upper)) return()

  # Calculate x positions (in inches within forest viewport)
  x1 <- x_scale(lower)
  x2 <- x_scale(upper)
  cx <- x_scale(point)

  # Point size (in inches)
  point_size <- 0.06  # ~4.3 pixels

  # Whisker cap height (in inches)
  cap_h <- 0.04

  # Draw CI horizontal line
  grid::grid.segments(
    x0 = grid::unit(x1, "inches"),
    x1 = grid::unit(x2, "inches"),
    y0 = grid::unit(y_pos, "npc"),
    y1 = grid::unit(y_pos, "npc"),
    gp = gpar_list$interval_line
  )

  # Draw whisker caps (vertical lines at endpoints)
  # Only draw if not clipped
  if (x1 >= 0 && x1 <= layout$forest_width) {
    grid::grid.segments(
      x0 = grid::unit(x1, "inches"),
      x1 = grid::unit(x1, "inches"),
      y0 = grid::unit(y_pos, "npc") - grid::unit(cap_h, "inches"),
      y1 = grid::unit(y_pos, "npc") + grid::unit(cap_h, "inches"),
      gp = gpar_list$interval_line
    )
  }

  if (x2 >= 0 && x2 <= layout$forest_width) {
    grid::grid.segments(
      x0 = grid::unit(x2, "inches"),
      x1 = grid::unit(x2, "inches"),
      y0 = grid::unit(y_pos, "npc") - grid::unit(cap_h, "inches"),
      y1 = grid::unit(y_pos, "npc") + grid::unit(cap_h, "inches"),
      gp = gpar_list$interval_line
    )
  }

  # Draw point estimate square
  point_gpar <- get_point_gpar(point, null_value, gpar_list)
  if (cx >= 0 && cx <= layout$forest_width) {
    grid::grid.rect(
      x = grid::unit(cx, "inches"),
      y = grid::unit(y_pos, "npc"),
      width = grid::unit(point_size * 2, "inches"),
      height = grid::unit(point_size * 2, "inches"),
      gp = point_gpar
    )
  }
}

#' Render summary diamond
#'
#' Mirrors SummaryDiamond.svelte rendering
#'
#' @param point Point estimate
#' @param lower Lower bound
#' @param upper Upper bound
#' @param y_pos Y position (from top, in npc units)
#' @param x_scale Scale function
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @noRd
render_diamond <- function(point, lower, upper, y_pos, x_scale, layout, gpar_list) {
  # Check for missing/invalid values
  if (is.null(point) || is.null(lower) || is.null(upper)) return()
  if (length(point) == 0 || length(lower) == 0 || length(upper) == 0) return()
  if (is.na(point[1]) || is.na(lower[1]) || is.na(upper[1])) return()

  # Calculate x positions
  x_lower <- x_scale(lower)
  x_point <- x_scale(point)
  x_upper <- x_scale(upper)

  # Diamond half height (in inches)
  half_h <- 0.07

  # Clamp to visible area
  x_lower_clamped <- max(0, x_lower)
  x_upper_clamped <- min(layout$forest_width, x_upper)

  # Diamond points: left, top, right, bottom
  # Convert y_pos from npc to absolute position for polygon
  x_pts <- c(x_lower_clamped, x_point, x_upper_clamped, x_point)

  # Create polygon using viewport-relative coordinates
  grid::grid.polygon(
    x = grid::unit(x_pts, "inches"),
    y = grid::unit(y_pos, "npc") + grid::unit(c(0, half_h, 0, -half_h), "inches"),
    gp = gpar_list$summary
  )

  # Draw clipping arrows if needed
  if (x_lower < 0) {
    # Left arrow
    grid::grid.polygon(
      x = grid::unit(c(0.05, 0.12, 0.12), "inches"),
      y = grid::unit(y_pos, "npc") + grid::unit(c(0, 0.04, -0.04), "inches"),
      gp = grid::gpar(fill = gpar_list$summary$fill, col = NA)
    )
  }

  if (x_upper > layout$forest_width) {
    # Right arrow
    arrow_x <- layout$forest_width - 0.05
    grid::grid.polygon(
      x = grid::unit(c(arrow_x, arrow_x - 0.07, arrow_x - 0.07), "inches"),
      y = grid::unit(y_pos, "npc") + grid::unit(c(0, 0.04, -0.04), "inches"),
      gp = grid::gpar(fill = gpar_list$summary$fill, col = NA)
    )
  }
}

#' Render x-axis with ticks and labels
#'
#' Mirrors EffectAxis.svelte rendering
#'
#' @param ticks Numeric vector of tick values
#' @param x_scale Scale function
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @param axis_label Optional axis label
#' @param show_gridlines Whether to show gridlines
#' @param plot_height Height of plot area for gridlines
#' @noRd
render_axis <- function(ticks, x_scale, layout, gpar_list, axis_label = NULL,
                        show_gridlines = FALSE, plot_height = 0) {
  # Axis is at y = 0 (bottom of axis viewport)
  axis_y <- 0.95  # Near top of axis viewport in npc

  # Draw axis line
  grid::grid.segments(
    x0 = grid::unit(0, "inches"),
    x1 = grid::unit(layout$forest_width, "inches"),
    y0 = grid::unit(axis_y, "npc"),
    y1 = grid::unit(axis_y, "npc"),
    gp = gpar_list$axis_line
  )

  # Draw ticks and labels
  tick_h <- 0.03  # Tick height in inches

  for (tick in ticks) {
    tick_x <- x_scale(tick)

    # Skip if outside visible area
    if (tick_x < 0 || tick_x > layout$forest_width) next

    # Tick mark
    grid::grid.segments(
      x0 = grid::unit(tick_x, "inches"),
      x1 = grid::unit(tick_x, "inches"),
      y0 = grid::unit(axis_y, "npc"),
      y1 = grid::unit(axis_y, "npc") - grid::unit(tick_h, "inches"),
      gp = gpar_list$axis_line
    )

    # Tick label
    grid::grid.text(
      label = format_tick(tick),
      x = grid::unit(tick_x, "inches"),
      y = grid::unit(axis_y, "npc") - grid::unit(0.12, "inches"),
      just = "center",
      gp = gpar_list$text_muted
    )
  }

  # Axis label
  if (!is.null(axis_label) && axis_label != "") {
    grid::grid.text(
      label = axis_label,
      x = grid::unit(layout$forest_width / 2, "inches"),
      y = grid::unit(0.15, "npc"),
      just = "center",
      gp = grid::gpar(
        fontsize = gpar_list$text_muted$fontsize,
        fontfamily = gpar_list$text_muted$fontfamily,
        col = gpar_list$text_muted$col,
        fontface = "bold"
      )
    )
  }
}

#' Render null reference line
#'
#' @param null_value The null/reference value
#' @param x_scale Scale function
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @noRd
render_null_line <- function(null_value, x_scale, layout, gpar_list) {
  null_x <- x_scale(null_value)

  # Skip if outside visible area
  if (null_x < 0 || null_x > layout$forest_width) return()

  grid::grid.segments(
    x0 = grid::unit(null_x, "inches"),
    x1 = grid::unit(null_x, "inches"),
    y0 = grid::unit(0, "npc"),
    y1 = grid::unit(1, "npc"),
    gp = gpar_list$null_line
  )
}

#' Render gridlines for specified ticks
#'
#' @param ticks Numeric vector of tick values
#' @param x_scale Scale function
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @noRd
render_gridlines <- function(ticks, x_scale, layout, gpar_list) {
  for (tick in ticks) {
    tick_x <- x_scale(tick)
    if (tick_x < 0 || tick_x > layout$forest_width) next

    grid::grid.segments(
      x0 = grid::unit(tick_x, "inches"),
      x1 = grid::unit(tick_x, "inches"),
      y0 = grid::unit(0, "npc"),
      y1 = grid::unit(1, "npc"),
      gp = grid::gpar(
        col = gpar_list$gridline$col,
        lwd = 0.5,
        lty = "dotted",
        alpha = 0.5
      )
    )
  }
}

#' Render table column text
#'
#' @param spec WebSpec object
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @param side "left" or "right"
#' @noRd
render_table_column <- function(spec, layout, gpar_list, side = "left") {
  data <- spec@data

  # For now, render just the label column on the left

  if (side == "left" && !is.null(spec@label_col) && spec@label_col != "") {
    labels <- data[[spec@label_col]]
    n_rows <- length(labels)

    for (i in seq_len(n_rows)) {
      if (is.na(labels[i])) next

      # Calculate y position (from top)
      y_pos <- 1 - ((i - 0.5) / n_rows)

      grid::grid.text(
        label = as.character(labels[i]),
        x = grid::unit(0.1, "npc"),
        y = grid::unit(y_pos, "npc"),
        just = "left",
        gp = gpar_list$text
      )
    }
  }
}

#' Render column headers
#'
#' @param spec WebSpec object
#' @param layout Layout list
#' @param gpar_list List of gpar objects
#' @noRd
render_headers <- function(spec, layout, gpar_list) {
  # Label column header
  if (!is.null(spec@label_header) && spec@label_header != "") {
    grid::grid.text(
      label = spec@label_header,
      x = grid::unit(0.1, "npc"),
      y = grid::unit(0.5, "npc"),
      just = "left",
      gp = gpar_list$text_header
    )
  }
}

#' Main function to render forest plot using grid graphics
#'
#' @param spec WebSpec object
#' @param layout Layout list from compute_layout
#' @param gpar_list List of gpar objects from theme_to_gpar
#' @noRd
render_forest_grid <- function(spec, layout, gpar_list) {
  data <- spec@data
  theme <- spec@theme
  n_rows <- nrow(data)

  # Compute x-scale
  x_scale <- compute_x_scale(spec, layout$forest_width)

  # Compute axis ticks
  ticks <- compute_axis_ticks(spec, x_scale, layout$forest_width)

  # Get column data
  points <- data[[spec@point_col]]
  lowers <- data[[spec@lower_col]]
  uppers <- data[[spec@upper_col]]

  # Create main viewport layout
  grid::pushViewport(grid::viewport(
    layout = grid::grid.layout(
      nrow = 3,
      ncol = 3,
      widths = grid::unit(c(layout$table_width, layout$forest_width, 0.1), "inches"),
      heights = grid::unit(c(layout$header_height, layout$plot_height, layout$axis_height), "inches")
    ),
    name = "main"
  ))

  # Background
  grid::grid.rect(gp = gpar_list$background)

  # --- Header row ---
  grid::pushViewport(grid::viewport(layout.pos.row = 1, layout.pos.col = 1, name = "header_table"))
  render_headers(spec, layout, gpar_list)
  grid::popViewport()

  # --- Table column (left) ---
  grid::pushViewport(grid::viewport(layout.pos.row = 2, layout.pos.col = 1, name = "table"))
  render_table_column(spec, layout, gpar_list, side = "left")
  grid::popViewport()

  # --- Forest plot area ---
  grid::pushViewport(grid::viewport(layout.pos.row = 2, layout.pos.col = 2, name = "forest"))

  # Gridlines (behind data)
  if (theme@axis@gridlines) {
    render_gridlines(ticks, x_scale, layout, gpar_list)
  }

  # Null reference line
  render_null_line(layout$null_value, x_scale, layout, gpar_list)

  # Render each row
  for (i in seq_len(n_rows)) {
    # Y position: from top, centered in row
    y_pos <- 1 - ((i - 0.5) / n_rows)

    render_interval(
      point = points[i],
      lower = lowers[i],
      upper = uppers[i],
      y_pos = y_pos,
      x_scale = x_scale,
      layout = layout,
      gpar_list = gpar_list,
      null_value = layout$null_value
    )
  }

  # Render overall summary if present
  summary_obj <- spec@overall_summary
  if (!is.null(summary_obj) && S7::S7_inherits(summary_obj, GroupSummary)) {
    # Summary goes at the bottom, after all rows
    summary_y <- 1 - ((n_rows + 0.75) / (n_rows + 1.5))

    render_diamond(
      point = summary_obj@point,
      lower = summary_obj@lower,
      upper = summary_obj@upper,
      y_pos = summary_y,
      x_scale = x_scale,
      layout = layout,
      gpar_list = gpar_list
    )
  }

  grid::popViewport()

  # --- Axis ---
  grid::pushViewport(grid::viewport(layout.pos.row = 3, layout.pos.col = 2, name = "axis"))
  render_axis(
    ticks = ticks,
    x_scale = x_scale,
    layout = layout,
    gpar_list = gpar_list,
    axis_label = spec@axis_label,
    show_gridlines = FALSE
  )
  grid::popViewport()

  # Pop main viewport
  grid::popViewport()
}
