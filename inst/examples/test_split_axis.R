# Test case for split forest axis scaling
#
# This test creates a split forest with two phenotypes having very different
# OR ranges. With shared_axis = FALSE (default), each sub-table should
# auto-scale independently:
# - "Normal Range" should have axis ~0.5-1.5
# - "Extreme Range" should have axis ~1-1000
#
# BUG: If both sub-tables show the same axis range (up to 500+), there's an
# issue with axis state not resetting when switching between specs.

library(webforest)

# Synthetic data with wildly different OR ranges per phenotype
test_data <- data.frame(

  phenotype = rep(c("Normal Range", "Extreme Range"), each = 5),
  mask = paste0("Mask ", 1:10),
  or = c(
    # Normal: ORs around 1
    0.8, 1.1, 0.95, 1.2, 1.05,
    # Extreme: ORs up to 500
    2.5, 50, 150, 300, 500
  ),
  lower = c(0.6, 0.9, 0.7, 1.0, 0.85, 1.2, 20, 80, 150, 250),
  upper = c(1.1, 1.4, 1.3, 1.5, 1.3, 5.0, 100, 250, 500, 900)
)

# Test 1: Default (shared_axis = FALSE) - each should auto-scale
cat("Test 1: shared_axis = FALSE (default)\n")
cat("Expected: 'Normal Range' axis ~0.5-1.5, 'Extreme Range' axis ~1-1000\n\n")

p1 <- forest_plot(test_data,
  point = "or", lower = "lower", upper = "upper",
  label = "mask",
  split_by = "phenotype",
  scale = "log", null_value = 1,
  title = "Test: Auto-scaling per sub-table"
)

# Display in viewer
p1

# Test 2: With shared_axis = TRUE - should show full range for both
cat("\nTest 2: shared_axis = TRUE\n")
cat("Expected: Both sub-tables show axis ~0.5-1000\n\n")

p2 <- forest_plot(test_data,
  point = "or", lower = "lower", upper = "upper",
  label = "mask",
  split_by = "phenotype",
  shared_axis = TRUE,
  scale = "log", null_value = 1,
  title = "Test: Shared axis across sub-tables"
)

# Uncomment to test shared axis:
# p2
