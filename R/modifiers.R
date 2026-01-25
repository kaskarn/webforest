# Fluent API for modifying WebSpec objects
# These functions allow piping modifications after creating a spec

#' Set row-level styling on a WebSpec
#'
#' Provides a fluent API for setting row-level styling based on column values.
#' Style values are read from the specified columns at render time.
#'
#' @param x A WebSpec object or an htmlwidget created by tabviz()
#' @param bold Column name containing logical values for row-level bold
#' @param italic Column name containing logical values for row-level italic
#' @param color Column name containing CSS color strings for row text color
#' @param bg Column name containing CSS color strings for row background color
#' @param badge Column name containing text for badges on the label column
#' @param icon Column name containing emoji/unicode for icons on the label column
#' @param indent Column name containing numeric values for row indentation
#' @param type Column name containing row type ("data", "header", "summary", "spacer")
#' @param weight Column name for marker weight/size scaling (numeric values, typically 0-100)
#' @param emphasis Column name containing logical values for emphasis styling (uses theme primary color)
#' @param muted Column name containing logical values for muted styling (uses theme muted color)
#' @param accent Column name containing logical values for accent styling (uses theme accent color)
#'
#' @return The modified WebSpec object (or widget)
#'
#' @examples
#' \dontrun{
#' forest_data |>
#'   web_spec(hr, lower, upper) |>
#'   set_row_style(bold = "is_primary", badge = "significance") |>
#'   forest_plot()
#' }
#'
#' @export
set_row_style <- function(
    x,
    bold = NULL,
    italic = NULL,
    color = NULL,
    bg = NULL,
    badge = NULL,
    icon = NULL,
    indent = NULL,
    type = NULL,
    weight = NULL,
    emphasis = NULL,
    muted = NULL,
    accent = NULL) {
  # Extract WebSpec from widget if needed
  spec <- if (inherits(x, "htmlwidget")) {
    attr(x, "webspec")
  } else if (S7_inherits(x, WebSpec)) {
    x
  } else {
    cli_abort("x must be a WebSpec or htmlwidget")
  }

  # Update spec properties
  if (!is.null(bold)) spec@row_bold_col <- bold
  if (!is.null(italic)) spec@row_italic_col <- italic
  if (!is.null(color)) spec@row_color_col <- color
  if (!is.null(bg)) spec@row_bg_col <- bg
  if (!is.null(badge)) spec@row_badge_col <- badge
  if (!is.null(icon)) spec@row_icon_col <- icon
  if (!is.null(indent)) spec@row_indent_col <- indent
  if (!is.null(type)) spec@row_type_col <- type
  if (!is.null(weight)) spec@weight_col <- weight
  if (!is.null(emphasis)) spec@row_emphasis_col <- emphasis
  if (!is.null(muted)) spec@row_muted_col <- muted
  if (!is.null(accent)) spec@row_accent_col <- accent

  # Return same type as input
  if (inherits(x, "htmlwidget")) {
    # Re-create widget with updated spec
    tabviz(spec)
  } else {
    spec
  }
}

#' Set column-level styling on a WebSpec
#'
#' Provides a fluent API for setting per-cell styling on specific columns.
#' The styling is based on values from other columns in the data.
#'
#' @param x A WebSpec object or an htmlwidget created by tabviz()
#' @param column The field name of the column to style
#' @param bold Column name containing logical values for cell-level bold
#' @param italic Column name containing logical values for cell-level italic
#' @param color Column name containing CSS color strings for cell text color
#' @param bg Column name containing CSS color strings for cell background color
#' @param badge Column name containing text for per-cell badges
#' @param icon Column name containing emoji/unicode for per-cell icons
#'
#' @return The modified WebSpec object (or widget)
#'
#' @examples
#' \dontrun{
#' forest_data |>
#'   web_spec(hr, lower, upper) |>
#'   set_column_style("study", badge = "significance", bold = "is_primary") |>
#'   forest_plot()
#' }
#'
#' @export
set_column_style <- function(
    x,
    column,
    bold = NULL,
    italic = NULL,
    color = NULL,
    bg = NULL,
    badge = NULL,
    icon = NULL) {
  # Extract WebSpec from widget if needed
  spec <- if (inherits(x, "htmlwidget")) {
    attr(x, "webspec")
  } else if (S7_inherits(x, WebSpec)) {
    x
  } else {
    cli_abort("x must be a WebSpec or htmlwidget")
  }

  # Find and update the column
  found <- FALSE
  for (i in seq_along(spec@columns)) {
    col <- spec@columns[[i]]

    # Handle ColumnGroup - search within
    if (S7_inherits(col, ColumnGroup)) {
      for (j in seq_along(col@columns)) {
        if (col@columns[[j]]@field == column) {
          if (!is.null(bold)) col@columns[[j]]@style_bold <- bold
          if (!is.null(italic)) col@columns[[j]]@style_italic <- italic
          if (!is.null(color)) col@columns[[j]]@style_color <- color
          if (!is.null(bg)) col@columns[[j]]@style_bg <- bg
          if (!is.null(badge)) col@columns[[j]]@style_badge <- badge
          if (!is.null(icon)) col@columns[[j]]@style_icon <- icon
          spec@columns[[i]] <- col
          found <- TRUE
          break
        }
      }
    } else if (S7_inherits(col, ColumnSpec) && col@field == column) {
      if (!is.null(bold)) col@style_bold <- bold
      if (!is.null(italic)) col@style_italic <- italic
      if (!is.null(color)) col@style_color <- color
      if (!is.null(bg)) col@style_bg <- bg
      if (!is.null(badge)) col@style_badge <- badge
      if (!is.null(icon)) col@style_icon <- icon
      spec@columns[[i]] <- col
      found <- TRUE
    }

    if (found) break
  }

  if (!found) {
    cli_warn("Column '{column}' not found in spec columns")
  }

  # Return same type as input
  if (inherits(x, "htmlwidget")) {
    tabviz(spec)
  } else {
    spec
  }
}

#' Set marker styling on a WebSpec
#'
#' Provides a fluent API for setting marker styling (color, shape, opacity, size)
#' based on column values. These styles apply to the primary effect's markers.
#' For multi-effect plots, additional effects use their `effect_forest()` properties.
#'
#' @param x A WebSpec object or an htmlwidget created by tabviz()
#' @param color Column name containing CSS color strings for marker fill color
#' @param shape Column name containing shape values ("square", "circle", "diamond", "triangle")
#' @param opacity Column name containing numeric values (0-1) for marker opacity
#' @param size Column name containing numeric values for marker size multiplier
#'
#' @return The modified WebSpec object (or widget)
#'
#' @examples
#' \dontrun{
#' forest_data |>
#'   web_spec(hr, lower, upper) |>
#'   set_marker_style(color = "significance_color", shape = "study_type") |>
#'   forest_plot()
#' }
#'
#' @export
set_marker_style <- function(
    x,
    color = NULL,
    shape = NULL,
    opacity = NULL,
    size = NULL) {
  # Extract WebSpec from widget if needed
  spec <- if (inherits(x, "htmlwidget")) {
    attr(x, "webspec")
  } else if (S7_inherits(x, WebSpec)) {
    x
  } else {
    cli_abort("x must be a WebSpec or htmlwidget")
  }

  # Update spec properties
  if (!is.null(color)) spec@marker_color_col <- color
  if (!is.null(shape)) spec@marker_shape_col <- shape
  if (!is.null(opacity)) spec@marker_opacity_col <- opacity
  if (!is.null(size)) spec@marker_size_col <- size

  # Return same type as input
  if (inherits(x, "htmlwidget")) {
    # Re-create widget with updated spec
    tabviz(spec)
  } else {
    spec
  }
}

#' Set theme on a WebSpec
#'
#' Provides a fluent API for setting or changing the theme on a WebSpec or widget.
#' Accepts either a theme name (string) or a WebTheme object.
#'
#' @param x A WebSpec object or an htmlwidget created by tabviz()
#' @param theme Either a WebTheme object or a string matching a built-in theme name:
#'   "default", "minimal", "dark", "jama", "lancet", "modern", "presentation",
#'   "cochrane", or "nature"
#'
#' @return The modified WebSpec object (or widget)
#'
#' @examples
#' \dontrun{
#' # Using a theme name
#' forest_data |>
#'   web_spec(hr, lower, upper) |>
#'   set_theme("jama") |>
#'   forest_plot()
#'
#' # Using a WebTheme object
#' my_theme <- web_theme_jama() |>
#'   set_colors(interval = "#0066cc")
#'
#' forest_data |>
#'   web_spec(hr, lower, upper) |>
#'   set_theme(my_theme) |>
#'   forest_plot()
#' }
#'
#' @export
set_theme <- function(x, theme) {
  # Extract WebSpec from widget if needed
  spec <- if (inherits(x, "htmlwidget")) {
    attr(x, "webspec")
  } else if (S7_inherits(x, WebSpec)) {
    x
  } else {
    cli_abort("x must be a WebSpec or htmlwidget")
  }

  # Resolve theme from name or use directly
  resolved_theme <- if (is.character(theme) && length(theme) == 1) {
    theme_name <- theme
    # Map of theme names to theme functions
    theme_map <- list(
      default = web_theme_default,
      minimal = web_theme_minimal,
      dark = web_theme_dark,
      jama = web_theme_jama,
      lancet = web_theme_lancet,
      modern = web_theme_modern,
      presentation = web_theme_presentation,
      cochrane = web_theme_cochrane,
      nature = web_theme_nature
    )
    if (!theme_name %in% names(theme_map)) {
      valid_names <- paste(names(theme_map), collapse = ", ")
      cli_abort("Unknown theme name: {.val {theme_name}}. Valid names: {valid_names}")
    }
    theme_map[[theme_name]]()
  } else if (S7_inherits(theme, WebTheme)) {
    theme
  } else {
    cli_abort("theme must be a theme name string or a WebTheme object")
  }

  # Update spec theme
  spec@theme <- resolved_theme

  # Return same type as input
  if (inherits(x, "htmlwidget")) {
    # Re-create widget with updated spec
    tabviz(spec)
  } else {
    spec
  }
}

#' Set zoom and container constraints
#'
#' Provides a fluent API for controlling zoom level and container size constraints.
#'
#' @param x An htmlwidget created by `tabviz()`
#' @param zoom Zoom level (0.5 to 2.0, default 1.0)
#' @param auto_fit When TRUE (default), shrink content to fit container if too large.
#'   Never enlarges content. When FALSE, render at zoom level with scrollbars if needed.
#' @param max_width Maximum container width in pixels (NULL for none)
#' @param max_height Maximum container height in pixels (NULL for none)
#' @param show_controls Show zoom controls on hover
#'
#' @return The modified htmlwidget
#'
#' @examples
#' \dontrun{
#' # Zoom to 80% with auto-fit
#' forest_plot(data, point, lower, upper) |>
#'   set_zoom(zoom = 0.8)
#'
#' # Constrain to max 800px width
#' forest_plot(data, point, lower, upper) |>
#'   set_zoom(max_width = 800)
#'
#' # Disable auto-fit, hide controls
#' forest_plot(data, point, lower, upper) |>
#'   set_zoom(auto_fit = FALSE, show_controls = FALSE)
#' }
#'
#' @export
set_zoom <- function(
    x,
    zoom = 1.0,
    auto_fit = TRUE,
    max_width = NULL,
    max_height = NULL,
    show_controls = TRUE) {
  if (!inherits(x, "htmlwidget")) {
    cli_abort("{.fn set_zoom} only works on htmlwidgets from {.fn tabviz}")
  }

  checkmate::assert_number(zoom, lower = 0.5, upper = 2.0)
  checkmate::assert_flag(auto_fit)
  if (!is.null(max_width)) checkmate::assert_number(max_width, lower = 100)
  if (!is.null(max_height)) checkmate::assert_number(max_height, lower = 100)
  checkmate::assert_flag(show_controls)

  # Update widget payload directly
  x$x$zoom <- zoom
  x$x$autoFit <- auto_fit
  x$x$maxWidth <- max_width
  x$x$maxHeight <- max_height
  x$x$showZoomControls <- show_controls

  x
}
