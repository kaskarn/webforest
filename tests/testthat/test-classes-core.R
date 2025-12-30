# Tests for core S7 classes

test_that("WebSpec validates required columns exist", {
  data <- data.frame(
    label = c("A", "B"),
    point = c(1.0, 2.0),
    lower = c(0.5, 1.5)
    # missing upper
  )

  expect_error(
    WebSpec(
      data = data,
      point_col = "point",
      lower_col = "lower",
      upper_col = "upper"  # doesn't exist
    ),
    "upper"
  )
})

test_that("WebSpec validates scale value", {
  data <- data.frame(
    point = c(1.0, 2.0),
    lower = c(0.5, 1.5),
    upper = c(1.5, 2.5)
  )

  expect_error(
    WebSpec(
      data = data,
      point_col = "point",
      lower_col = "lower",
      upper_col = "upper",
      scale = "invalid"
    ),
    "scale"
  )
})

test_that("WebSpec creates valid object with defaults", {
  data <- data.frame(
    point = c(1.0, 2.0),
    lower = c(0.5, 1.5),
    upper = c(1.5, 2.5)
  )

  spec <- WebSpec(
    data = data,
    point_col = "point",
    lower_col = "lower",
    upper_col = "upper"
  )

  expect_true(inherits(spec, "webforest::WebSpec"))
  expect_equal(spec@point_col, "point")
  expect_equal(spec@scale, "linear")
  expect_equal(spec@null_value, 0)
  expect_equal(nrow(spec@data), 2)
})

test_that("WebSpec accepts log scale with positive null_value", {
  data <- data.frame(
    point = c(1.0, 2.0),
    lower = c(0.5, 1.5),
    upper = c(1.5, 2.5)
  )

  spec <- WebSpec(
    data = data,
    point_col = "point",
    lower_col = "lower",
    upper_col = "upper",
    scale = "log",
    null_value = 1
  )

  expect_equal(spec@scale, "log")
  expect_equal(spec@null_value, 1)
})

test_that("GroupSpec creates valid object", {
  group <- GroupSpec(
    id = "group1",
    label = "Subgroup A",
    collapsed = FALSE
  )

  expect_true(inherits(group, "webforest::GroupSpec"))
  expect_equal(group@id, "group1")
  expect_equal(group@label, "Subgroup A")
  expect_false(group@collapsed)
})

test_that("GroupSummary creates valid object", {
  summary <- GroupSummary(
    group_id = "group1",
    point = 1.5,
    lower = 1.2,
    upper = 1.8
  )

  expect_true(inherits(summary, "webforest::GroupSummary"))
  expect_equal(summary@group_id, "group1")
  expect_equal(summary@point, 1.5)
})

# Theme preset tests
test_that("web_theme_jama creates valid theme", {
  theme <- web_theme_jama()
  expect_true(inherits(theme, "webforest::WebTheme"))
  expect_equal(theme@name, "jama")
  expect_equal(theme@colors@foreground, "#000000")
  expect_equal(theme@shapes@border_radius, 0)
})

test_that("web_theme_lancet creates valid theme", {
  theme <- web_theme_lancet()
  expect_true(inherits(theme, "webforest::WebTheme"))
  expect_equal(theme@name, "lancet")
  expect_equal(theme@colors@primary, "#00407a")
})

test_that("web_theme_modern creates valid theme", {
  theme <- web_theme_modern()
  expect_true(inherits(theme, "webforest::WebTheme"))
  expect_equal(theme@name, "modern")
  expect_equal(theme@spacing@row_height, 32)
})

test_that("web_theme_presentation creates valid theme", {
  theme <- web_theme_presentation()
  expect_true(inherits(theme, "webforest::WebTheme"))
  expect_equal(theme@name, "presentation")
  expect_equal(theme@spacing@row_height, 40)
  expect_equal(theme@shapes@point_size, 10)
})

# Column helper tests
test_that("col_bar creates column with options", {
  col <- col_bar("weight", max_value = 100, show_label = FALSE)
  expect_equal(col@type, "bar")
  expect_equal(col@options$bar$maxValue, 100)
  expect_false(col@options$bar$showLabel)
})

test_that("col_pvalue creates column with options", {
  col <- col_pvalue("p", stars = FALSE, format = "scientific")
  expect_equal(col@type, "pvalue")
  expect_false(col@options$pvalue$stars)
  expect_equal(col@options$pvalue$format, "scientific")
})

test_that("col_sparkline creates column with options", {
  col <- col_sparkline("trend", type = "area", height = 30)
  expect_equal(col@type, "sparkline")
  expect_equal(col@options$sparkline$type, "area")
  expect_equal(col@options$sparkline$height, 30)
})
