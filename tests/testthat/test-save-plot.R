# Tests for save_plot functionality

test_that("save_plot creates SVG file", {
  skip_if_not_installed("V8")

  data <- data.frame(
    study = c("Study A", "Study B", "Study C"),
    point = c(1.2, 0.8, 1.5),
    lower = c(0.9, 0.5, 1.1),
    upper = c(1.6, 1.2, 2.0)
  )

  spec <- web_spec(
    data = data,
    label = "study",
    columns = list(
      viz_forest(point = "point", lower = "lower", upper = "upper")
    )
  )

  svg_file <- tempfile(fileext = ".svg")
  on.exit(unlink(svg_file), add = TRUE)

  save_plot(spec, svg_file)
  expect_true(file.exists(svg_file))

  content <- readLines(svg_file, n = 2)
  expect_true(any(grepl("<svg", content)))
})

test_that("save_plot creates PNG file", {
  skip_if_not_installed("V8")
  skip_if_not_installed("rsvg")

  data <- data.frame(
    study = c("A", "B"),
    point = c(1.0, 2.0),
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

  png_file <- tempfile(fileext = ".png")
  on.exit(unlink(png_file), add = TRUE)

  save_plot(spec, png_file)
  expect_true(file.exists(png_file))
  expect_gt(file.size(png_file), 0)
})

test_that("save_plot creates PDF file", {
  skip_if_not_installed("V8")
  skip_if_not_installed("rsvg")

  data <- data.frame(
    study = c("A", "B"),
    point = c(1.0, 2.0),
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

  pdf_file <- tempfile(fileext = ".pdf")
  on.exit(unlink(pdf_file), add = TRUE)

  save_plot(spec, pdf_file)
  expect_true(file.exists(pdf_file))
  expect_gt(file.size(pdf_file), 0)
})

test_that("save_split_table creates files in directory", {
  skip_if_not_installed("V8")

  data <- data.frame(
    study = c("A", "B", "C", "D"),
    group = c("X", "X", "Y", "Y"),
    point = c(1.0, 2.0, 1.5, 0.8),
    lower = c(0.5, 1.5, 1.0, 0.4),
    upper = c(1.5, 2.5, 2.0, 1.2)
  )

  spec <- web_spec(
    data = data,
    label = "study",
    columns = list(
      viz_forest(point = "point", lower = "lower", upper = "upper")
    )
  )

  sf <- split_table(spec, by = "group")

  out_dir <- tempdir()
  save_split_table(sf, out_dir, format = "svg")

  svg_files <- list.files(out_dir, pattern = "\\.svg$", full.names = TRUE)
  expect_gt(length(svg_files), 0)

  # Clean up
  file.remove(svg_files)
})
