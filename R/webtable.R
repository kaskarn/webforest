#' Create an interactive web table
#'
#' `webtable()` renders a web-native, interactive table visualization
#' without the forest plot graphical column. Useful for displaying
#' tabular data with sorting, filtering, and other interactive features.
#'
#' @param x Either a WebSpec object or a data.frame/data.table/tibble
#' @param ... Arguments passed to `web_spec()` when x is a data frame.
#'   Common arguments: `point`, `lower`, `upper`, `label`, `group`,
#'   `columns`, `theme`, `interaction`
#' @param width Widget width (default NULL for auto)
#' @param height Widget height (default NULL for auto)
#' @param elementId HTML element ID (optional)
#'
#' @return An htmlwidget object
#'
#' @examples
#' \dontrun{
#' data <- data.frame(
#'   item = c("A", "B", "C"),
#'   value = c(1.2, 0.8, 1.5),
#'   lo = c(0.9, 0.5, 1.1),
#'   hi = c(1.6, 1.2, 2.0),
#'   n = c(100, 150, 75)
#' )
#'
#' # Create spec
#' spec <- web_spec(
#'   data,
#'   point = "value",
#'   lower = "lo",
#'   upper = "hi",
#'   label = "item",
#'   columns = list(col_n(), col_interval())
#' )
#'
#' # Table only (no forest column)
#' webtable(spec)
#'
#' # With forest column
#' forest_plot(spec)
#' }
#'
#' @seealso [web_spec()] for creating specifications, [forest_plot()] for forest plot rendering
#'
#' @export
webtable <- function(
    x,
    ...,
    width = NULL,
    height = NULL,
    elementId = NULL) {
  # Handle WebSpec or raw data
  if (inherits(x, "webforest::WebSpec")) {
    spec <- x
  } else if (is.data.frame(x)) {
    spec <- web_spec(x, ...)
  } else {
    cli_abort("{.arg x} must be a WebSpec object or a data frame")
  }

  # Serialize to JSON-ready structure (without forest column)
  payload <- serialize_spec(spec, include_forest = FALSE)

  # Create widget (uses same JS, but with includeForest = FALSE)
  htmlwidgets::createWidget(
    name = "webforest",
    x = payload,
    width = width,
    height = height,
    package = "webforest",
    elementId = elementId,
    sizingPolicy = htmlwidgets::sizingPolicy(
      defaultWidth = "100%",
      defaultHeight = 300,
      viewer.fill = TRUE,
      browser.fill = TRUE,
      knitr.figure = FALSE,
      knitr.defaultWidth = "100%",
      knitr.defaultHeight = 300
    )
  )
}
