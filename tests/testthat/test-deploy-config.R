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
  # 収集だけでなくクラスタ計算・レンダリングまで回して out/ を更新する(F-07)
  for (s in c("build/01_collect.R", "build/02_cluster.R", "build/03_render.R")) {
    expect_match(y, s, fixed = TRUE)
  }
  expect_match(y, "git add data out", fixed = TRUE)
  expect_match(y, "cron:", fixed = TRUE)
  expect_match(y, "\\* \\* \\* \\*")
})

test_that("vercel.json: ビルドなし・outputDirectory=out(F-07)", {
  p <- file.path(root, "vercel.json")
  expect_true(file.exists(p))
  skip_if_not(file.exists(p))
  v <- jsonlite::fromJSON(p)
  expect_equal(v$outputDirectory, "out")
  expect_true(is.null(v$buildCommand))   # null = Vercel 上でビルドしない
  expect_true(is.null(v$framework))
})
