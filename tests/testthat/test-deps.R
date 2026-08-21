# 依存宣言の乖離検出(loop_008 の SPEC-DRIFT 対策)。
# CI は `dependencies: hard`(DESCRIPTION の Imports のみ)で環境を作るため、
# ローカルに入っているパッケージを宣言し忘れると **CI だけが落ちる**。
# ローカルで検出できるようにテスト化する。
root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

used_packages <- function(dirs) {
  files <- unlist(lapply(dirs, function(d)
    list.files(file.path(root, d), pattern = "\\.R$", full.names = TRUE)))
  txt <- unlist(lapply(files, readLines, warn = FALSE, encoding = "UTF-8"))
  txt <- sub("#.*$", "", txt)  # コメント内の例示(pkg::fun 等)を拾わない
  m <- regmatches(txt, gregexpr("(?:library|require)\\(([A-Za-z0-9._]+)\\)", txt))
  pkgs <- gsub("^(?:library|require)\\(|\\)$", "", unlist(m))
  # `pkg::fun` 形式も拾う
  m2 <- regmatches(txt, gregexpr("([A-Za-z][A-Za-z0-9._]*)::", txt))
  pkgs <- c(pkgs, gsub("::$", "", unlist(m2)))
  sort(unique(pkgs))
}

declared <- function(field) {
  d <- read.dcf(file.path(root, "DESCRIPTION"))
  if (!field %in% colnames(d)) return(character(0))
  v <- strsplit(d[1, field], ",")[[1]]
  sort(unique(trimws(gsub("\\(.*\\)", "", v))))
}

test_that("R/ と build/ が使う全パッケージが DESCRIPTION Imports にある", {
  used <- used_packages(c("R", "build"))
  imports <- declared("Imports")
  base_pkgs <- c("utils", "stats", "grDevices", "graphics", "methods", "tools")
  missing <- setdiff(used, c(imports, base_pkgs))
  expect_equal(missing, character(0),
               info = paste("DESCRIPTION Imports に未宣言:", paste(missing, collapse = ", ")))
})

test_that("テストのみで使うパッケージは Suggests にある", {
  used_tests <- used_packages("tests/testthat")
  ok <- c(declared("Imports"), declared("Suggests"),
          "utils", "stats", "grDevices", "graphics", "methods", "tools", "testthat")
  missing <- setdiff(used_tests, ok)
  expect_equal(missing, character(0),
               info = paste("未宣言:", paste(missing, collapse = ", ")))
})
