#' Shiny output function for forest plot
#'
#' @param outputId Output variable name
#' @param width Widget width (CSS units)
#' @param height Widget height (CSS units)
#'
#' @return A Shiny output element
#' @export
forestOutput <- function(outputId, width = "100%", height = "400px") {
  htmlwidgets::shinyWidgetOutput(
    outputId,
    "webforest",
    width,
    height,
    package = "webforest"
  )
}

#' Shiny render function for forest plot
#'
#' @param expr An expression that returns a forest plot (from `forest_plot()`)
#' @param env The environment in which to evaluate expr
#' @param quoted Is expr a quoted expression?
#'
#' @return A Shiny render function
#' @export
renderForest <- function(expr, env = parent.frame(), quoted = FALSE) {
  if (!quoted) {
    expr <- substitute(expr)
  }
  htmlwidgets::shinyRenderWidget(expr, forestOutput, env, quoted = TRUE)
}

#' Create a forest plot proxy object
#'
#' Creates a proxy object that can be used to update a forest plot in a Shiny
#' app without re-rendering the entire widget.
#'
#' @param id The widget ID
#' @param session The Shiny session (default: current session)
#'
#' @return A forest_proxy object
#' @export
forestProxy <- function(id, session = shiny::getDefaultReactiveDomain()) {
  if (is.null(session)) {
    cli_abort("forestProxy must be called from within a Shiny reactive context")
  }

  structure(
    list(id = id, session = session),
    class = "forest_proxy"
  )
}

#' Update forest plot data via proxy
#'
#' @param proxy A forest_proxy object
#' @param data New data (same format as forest_plot)
#' @param ... Additional arguments passed to coerce_to_studies
#'
#' @return The proxy object (invisibly), for chaining
#' @export
forest_update_data <- function(proxy, data, ...) {
  studies <- coerce_to_studies(data, ...)
  forest_data <- ForestData(studies = studies)

  invoke_proxy_method(proxy, "updateData", list(
    spec = list(data = serialize_data(forest_data))
  ))
}

#' Toggle subgroup collapse state
#'
#' @param proxy A forest_proxy object
#' @param subgroup_id The subgroup ID to toggle
#' @param collapsed Whether to collapse (TRUE), expand (FALSE), or toggle (NULL)
#'
#' @return The proxy object (invisibly), for chaining
#' @export
forest_toggle_subgroup <- function(proxy, subgroup_id, collapsed = NULL) {
  invoke_proxy_method(proxy, "toggleSubgroup", list(
    subgroupId = subgroup_id,
    collapsed = collapsed
  ))
}

#' Apply a filter to the forest plot
#'
#' @param proxy A forest_proxy object
#' @param field Field to filter on
#' @param operator Filter operator: "eq", "neq", "gt", "lt", "contains"
#' @param value Filter value
#'
#' @return The proxy object (invisibly), for chaining
#' @export
forest_filter <- function(
    proxy,
    field,
    operator = c("eq", "neq", "gt", "lt", "contains"),
    value) {
  operator <- match.arg(operator)
  invoke_proxy_method(proxy, "applyFilter", list(
    filter = list(
      field = field,
      operator = operator,
      value = value
    )
  ))
}

#' Clear filters from the forest plot
#'
#' @param proxy A forest_proxy object
#'
#' @return The proxy object (invisibly), for chaining
#' @export
forest_clear_filter <- function(proxy) {
  invoke_proxy_method(proxy, "clearFilter", list())
}

#' Sort the forest plot by a column
#'
#' @param proxy A forest_proxy object
#' @param column Column to sort by
#' @param direction Sort direction: "asc", "desc", or "none"
#'
#' @return The proxy object (invisibly), for chaining
#' @export
forest_sort <- function(
    proxy,
    column,
    direction = c("asc", "desc", "none")) {
  direction <- match.arg(direction)
  invoke_proxy_method(proxy, "sortBy", list(
    column = column,
    direction = direction
  ))
}

#' Internal: Invoke a proxy method
#' @keywords internal
invoke_proxy_method <- function(proxy, method, args) {
  if (!inherits(proxy, "forest_proxy")) {
    cli_abort("proxy must be a forest_proxy object created with forestProxy()")
  }

  msg <- list(id = proxy$id, method = method, args = args)
  proxy$session$sendCustomMessage("webforest-proxy", msg)

  invisible(proxy)
}
