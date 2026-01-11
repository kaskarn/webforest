#' @keywords internal
"_PACKAGE"

## usethis namespace: start
#' @import S7
#' @importFrom htmlwidgets createWidget shinyWidgetOutput shinyRenderWidget
#' @importFrom jsonlite toJSON
#' @importFrom rlang %||% abort warn inform is_scalar_character is_scalar_double
#' @importFrom cli cli_abort cli_warn cli_inform
#' @importFrom checkmate assert_flag assert_number assert_string assert_choice assert_subset assert_character
## usethis namespace: end
NULL

.onAttach <- function(libname, pkgname) {
  version <- utils::packageVersion("webforest")

  msg <- c(
    cli::col_cyan(cli::symbol$bullet),
    " ",
    cli::style_bold("webforest"),
    " v", as.character(version),
    " ",
    cli::col_yellow("[pre-release]"),
    "\n  ",
    cli::col_silver(cli::symbol$info),
    " ",
    cli::col_silver("API may change in future versions."),
    "\n  ",
    cli::col_silver(cli::symbol$pointer),
    " ",
    cli::col_silver("Report issues: "),
    cli::col_blue(cli::style_underline("https://github.com/kaskarn/webforest/issues"))
  )

  packageStartupMessage(paste0(msg, collapse = ""))
}
