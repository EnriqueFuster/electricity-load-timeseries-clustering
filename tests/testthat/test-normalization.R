test_that("z-normalization is row-wise", {
  x <- rbind(a = 1:4, b = 11:14)
  out <- normalize_load_curve(x, "zscore")
  expect_equal(rowMeans(out), c(a = 0, b = 0), tolerance = 1e-12)
  expect_equal(apply(out, 1, sd), c(a = 1, b = 1), tolerance = 1e-12)
})
