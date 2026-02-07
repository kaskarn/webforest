# Tests for set_* modifier functions

test_that("set_colors modifies theme colors", {
  theme <- web_theme_default()
  updated <- set_colors(theme, primary = "#ff0000", accent = "#00ff00")
  expect_equal(updated@colors@primary, "#ff0000")
  expect_equal(updated@colors@accent, "#00ff00")
  # Other colors unchanged

  expect_equal(updated@colors@background, theme@colors@background)
})

test_that("set_typography modifies font properties", {
  theme <- web_theme_default()
  updated <- set_typography(theme, font_family = "Georgia, serif")
  expect_equal(updated@typography@font_family, "Georgia, serif")
})

test_that("set_spacing modifies dimensions", {
  theme <- web_theme_default()
  updated <- set_spacing(theme, row_height = 40, padding = 16)
  expect_equal(updated@spacing@row_height, 40)
  expect_equal(updated@spacing@padding, 16)
})

test_that("set_shapes modifies visual properties", {
  theme <- web_theme_default()
  updated <- set_shapes(theme, point_size = 12, line_width = 2)
  expect_equal(updated@shapes@point_size, 12)
  expect_equal(updated@shapes@line_width, 2)
})

test_that("set_axis modifies axis config", {
  theme <- web_theme_default()
  updated <- set_axis(theme, range_min = -5, range_max = 5, gridlines = TRUE)
  expect_equal(updated@axis@range_min, -5)
  expect_equal(updated@axis@range_max, 5)
  expect_true(updated@axis@gridlines)
})

test_that("set_layout modifies layout config", {
  theme <- web_theme_default()
  updated <- set_layout(theme, plot_position = "left", banding = FALSE)
  expect_equal(updated@layout@plot_position, "left")
  expect_false(updated@layout@banding)
})

test_that("set_group_headers modifies group header styling", {
  theme <- web_theme_default()
  updated <- set_group_headers(theme, level1_font_weight = 700, level1_italic = TRUE)
  expect_equal(updated@group_headers@level1_font_weight, 700)
  expect_true(updated@group_headers@level1_italic)
})

test_that("set_effect_colors sets effect colors", {
  theme <- web_theme_default()
  updated <- set_effect_colors(theme, c("#ff0000", "#00ff00", "#0000ff"))
  expect_equal(updated@shapes@effect_colors, c("#ff0000", "#00ff00", "#0000ff"))
})

test_that("set_marker_shapes sets marker shapes", {
  theme <- web_theme_default()
  updated <- set_marker_shapes(theme, c("circle", "diamond"))
  expect_equal(updated@shapes@marker_shapes, c("circle", "diamond"))
})

test_that("fluent chaining works", {
  result <- web_theme_default() |>
    set_colors(primary = "#123456") |>
    set_spacing(row_height = 35) |>
    set_shapes(point_size = 10)

  expect_equal(result@colors@primary, "#123456")
  expect_equal(result@spacing@row_height, 35)
  expect_equal(result@shapes@point_size, 10)
})

test_that("set_theme on WebSpec works with name string", {
  data <- data.frame(
    study = c("A", "B"),
    point = c(1, 2),
    lower = c(0.5, 1.5),
    upper = c(1.5, 2.5)
  )

  spec <- web_spec(
    data = data,
    label = "study",
    columns = list(
      viz_forest(point = "point", lower = "lower", upper = "upper")
    )
  )

  updated <- set_theme(spec, "jama")
  expect_equal(updated@theme@name, "jama")
})

test_that("set_theme on WebSpec works with WebTheme object", {
  data <- data.frame(
    study = c("A", "B"),
    point = c(1, 2),
    lower = c(0.5, 1.5),
    upper = c(1.5, 2.5)
  )

  spec <- web_spec(
    data = data,
    label = "study",
    columns = list(
      viz_forest(point = "point", lower = "lower", upper = "upper")
    )
  )

  custom_theme <- web_theme_jama() |> set_colors(primary = "#ff0000")
  updated <- set_theme(spec, custom_theme)
  expect_equal(updated@theme@colors@primary, "#ff0000")
})

test_that("widget round-trip: forest_plot |> set_colors works", {
  data <- data.frame(
    study = c("A", "B"),
    point = c(1, 2),
    lower = c(0.5, 1.5),
    upper = c(1.5, 2.5)
  )

  widget <- forest_plot(data, point = "point", lower = "lower", upper = "upper",
                        label = "study")
  updated_spec <- set_theme(widget, "lancet")
  # Returns an htmlwidget
  expect_true(inherits(updated_spec, "htmlwidget"))
})
