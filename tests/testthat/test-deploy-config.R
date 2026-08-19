# 自動化設定の規約テスト(F-07)。
root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("collect ワークフロー: cron 毎時・書き込み権限・収集段(F-07)", {
  p <- file.path(root, ".github", "workflows", "collect.yml")
  expect_true(file.exists(p))
  skip_if_not(file.exists(p))
  y <- paste(readLines(p, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_match(y, "schedule:", fixed = TRUE)
  expect_match(y, "workflow_dispatch", fixed = TRUE)
  expect_match(y, "contents: write", fixed = TRUE)
  expect_match(y, "concurrency", fixed = TRUE)
  expect_match(y, "build/01_collect.R", fixed = TRUE)
  expect_match(y, "cron:", fixed = TRUE)
  expect_match(y, "\\* \\* \\* \\*")
})
