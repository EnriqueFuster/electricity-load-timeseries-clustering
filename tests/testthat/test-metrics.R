test_that("adjusted Rand is label permutation invariant", {
  expect_equal(calculate_adjusted_rand(c(1, 1, 2, 2), c(9, 9, 4, 4)), 1)
})

test_that("cluster balance is bounded", {
  expect_equal(calculate_cluster_balance(c(1, 1, 1, 2)), 1 / 3)
})
