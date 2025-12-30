#' Create a web specification for table visualizations
#'
#' `web_spec()` creates the core data structure that can be rendered as
#' a forest plot, interactive table, or other visualizations. This is
#' the recommended way to prepare data for rendering.
#'
#' @param data A data.frame, data.table, or tibble
#' @param point Column name for point estimates (unquoted or string)
#' @param lower Column name for lower bounds of intervals
#' @param upper Column name for upper bounds of intervals
#' @param label Column name for row labels (optional)
#' @param label_header Header text for the label column (default: "Study")
#' @param group Column name for grouping/categories (optional)
#' @param columns List of column specifications (use `col_*()` helpers)
#' @param scale Scale type: "linear" (default) or "log"
#' @param null_value Reference value for null effect. Default: 0 for linear, 1 for log
#' @param axis_label Label for the graphical axis
#' @param effects List of EffectSpec objects for multi-effect plots (use `web_effect()`)
#' @param annotations List of annotation objects (use `forest_refline()`, `forest_annotation()`)
#' @param title Main title (displayed above the plot)
#' @param subtitle Subtitle (displayed below the title)
#' @param caption Caption (displayed below the plot)
#' @param footnote Footnote (displayed below caption, italicized)
#' @param theme Theme object (use `web_theme_*()` functions)
#' @param interaction Interaction settings (use `web_interaction()`)
#'
#' @return A WebSpec object that can be rendered with `forest_plot()` or `webtable()`
#'
#' @examples
#' \dontrun{
#' # Basic specification
#' data <- data.frame(
#'   item = c("A", "B", "C"),
#'   value = c(1.2, 0.8, 1.5),
#'   lo = c(0.9, 0.5, 1.1),
#'   hi = c(1.6, 1.2, 2.0)
#' )
#'
#' spec <- web_spec(data, point = "value", lower = "lo", upper = "hi", label = "item")
#'
#' # Render as forest plot
#' forest_plot(spec)
#'
#' # Render as table only
#' webtable(spec)
#'
#' # With log scale (for ratios)
#' spec_log <- web_spec(
#'   data,
#'   point = "value",
#'   lower = "lo",
#'   upper = "hi",
#'   scale = "log",
#'   null_value = 1,
#'   axis_label = "Odds Ratio"
#' )
#' }
#'
#' @export
web_spec <- function(
    data,
    point,
    lower,
    upper,
    label = NULL,
    label_header = "Study",
    group = NULL,
    columns = NULL,
    scale = c("linear", "log"),
    null_value = NULL,
    axis_label = NULL,
    effects = NULL,
    annotations = NULL,
    title = NULL,
    subtitle = NULL,
    caption = NULL,
    footnote = NULL,
    theme = web_theme_default(),
    interaction = web_interaction()) {
  # Match scale
 scale <- match.arg(scale)

  # Set default null_value based on scale
  if (is.null(null_value)) {
    null_value <- if (scale == "log") 1 else 0
  }

  # Set default axis_label
  if (is.null(axis_label)) {
    axis_label <- "Estimate"
  }

  # Convert data to data.frame
  data <- as.data.frame(data)

  # Resolve column names (support for strings)
  point_col <- as.character(substitute(point))
  if (length(point_col) > 1 || !point_col %in% names(data)) {
    # Try as literal string
    if (is.character(point) && point %in% names(data)) {
      point_col <- point
    } else {
      cli_abort("Column {.arg point} not found in data")
    }
  }

  lower_col <- as.character(substitute(lower))
  if (length(lower_col) > 1 || !lower_col %in% names(data)) {
    if (is.character(lower) && lower %in% names(data)) {
      lower_col <- lower
    } else {
      cli_abort("Column {.arg lower} not found in data")
    }
  }

  upper_col <- as.character(substitute(upper))
  if (length(upper_col) > 1 || !upper_col %in% names(data)) {
    if (is.character(upper) && upper %in% names(data)) {
      upper_col <- upper
    } else {
      cli_abort("Column {.arg upper} not found in data")
    }
  }

  # Handle optional label column
  label_col <- NA_character_
  if (!is.null(label)) {
    label_col <- as.character(substitute(label))
    if (length(label_col) > 1 || !label_col %in% names(data)) {
      if (is.character(label) && label %in% names(data)) {
        label_col <- label
      } else {
        cli_abort("Column {.arg label} not found in data")
      }
    }
  }

  # Handle optional group column
  group_col <- NA_character_
  groups <- list()
  if (!is.null(group)) {
    group_col <- as.character(substitute(group))
    if (length(group_col) > 1 || !group_col %in% names(data)) {
      if (is.character(group) && group %in% names(data)) {
        group_col <- group
      } else {
        cli_abort("Column {.arg group} not found in data")
      }
    }

    # Extract unique groups
    unique_groups <- unique(data[[group_col]])
    unique_groups <- unique_groups[!is.na(unique_groups)]
    groups <- lapply(unique_groups, function(g) {
      GroupSpec(id = as.character(g), label = as.character(g))
    })
  }

  # Process columns - ensure they're ColumnSpec or ColumnGroup objects
  if (is.null(columns)) {
    columns <- list()
  } else {
    columns <- lapply(columns, function(col) {
      if (S7_inherits(col, ColumnSpec) || S7_inherits(col, ColumnGroup)) {
        col
      } else if (is.character(col)) {
        col_text(col)
      } else {
        cli_abort("columns must be ColumnSpec objects or column names")
      }
    })
  }

  # Build labels if any are provided
  labels <- NULL
  if (!is.null(title) || !is.null(subtitle) || !is.null(caption) || !is.null(footnote)) {
    labels <- PlotLabels(
      title = title %||% NA_character_,
      subtitle = subtitle %||% NA_character_,
      caption = caption %||% NA_character_,
      footnote = footnote %||% NA_character_
    )
  }

  # Process effects list
  effects_list <- list()
  if (!is.null(effects)) {
    effects_list <- effects
  }

  # Process annotations list
  annotations_list <- list()
  if (!is.null(annotations)) {
    annotations_list <- annotations
  }

  # Build and return WebSpec
  WebSpec(
    data = data,
    point_col = point_col,
    lower_col = lower_col,
    upper_col = upper_col,
    label_col = label_col,
    label_header = label_header,
    group_col = group_col,
    columns = columns,
    groups = groups,
    scale = scale,
    null_value = null_value,
    axis_label = axis_label,
    effects = effects_list,
    theme = theme,
    interaction = interaction,
    labels = labels,
    annotations = annotations_list
  )
}

#' Extract data from a WebSpec
#'
#' @param x A WebSpec object
#' @param ... Ignored
#'
#' @return A data.frame
#' @export
as.data.frame.WebSpec <- function(x, ...) {
  x@data
}

# Register the S3 method for S7 class
method(as.data.frame, WebSpec) <- function(x, ...) {
  x@data
}
