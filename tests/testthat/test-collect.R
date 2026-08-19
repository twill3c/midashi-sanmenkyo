# 収集系(T-013/T-014)。パーサは保存済みフィクスチャ(2026-08-19 取得)に対して検証し、
# テストからネットワークへは出ない。
suppressPackageStartupMessages({
  library(readr)
  library(digest)
  library(xml2)
})
source("../../R/feeds.R", chdir = TRUE)
source("../../R/parse_feed.R", chdir = TRUE)
source("../../R/timeutil.R", chdir = TRUE)

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
fx <- function(name) file.path(testthat::test_path(), "fixtures", name)

test_that("フィード定義: 3 社・全 https・利用条件メモ付き(F-01)", {
  f <- feeds()
  expect_equal(f$outlet, c("NHK", "朝日新聞", "毎日新聞"))
  expect_true(all(grepl("^https://", f$url)))
  expect_true(all(nchar(f$terms_note) > 0))
})

test_that("パーサ: NHK(RSS2.0、guid あり)(T-014)", {
  d <- parse_feed(read_xml(fx("nhk_sample.xml")), outlet = "NHK")
  expect_equal(nrow(d), 7)  # フィクスチャ取得時の item 数
  expect_true(all(c("outlet", "guid", "link", "title") == names(d)))
  expect_true(all(grepl("^https://", d$guid)))
  expect_false(any(duplicated(d$guid)))
})

test_that("パーサ: 朝日(RSS1.0 RDF、guid なし → link 代用・channel link を拾わない)(T-014)", {
  d <- parse_feed(read_xml(fx("asahi_sample.xml")), outlet = "朝日新聞")
  expect_gt(nrow(d), 10)
  # channel の link(トップページ)が item として混入していない
  expect_false(any(d$link == "http://www.asahi.com/"))
  expect_true(all(grepl("^https?://www\\.asahi\\.com/articles/", d$link)))
  expect_equal(d$guid, d$link)
  expect_true(all(nchar(d$title) > 0))
})

test_that("パーサ: 毎日(RDF)(T-014)", {
  d <- parse_feed(read_xml(fx("mainichi_sample.xml")), outlet = "毎日新聞")
  expect_gt(nrow(d), 10)
  expect_true(all(grepl("^https://mainichi\\.jp/articles/", d$link)))
  expect_false(any(duplicated(paste(d$outlet, d$guid))))
})

test_that("台帳整合: SHA256・集合一致・時刻単調(T-013/G-05)", {
  ledger <- read_csv(file.path(root, "data", "ledger.csv"), col_types = "ccc")
  snaps <- list.files(file.path(root, "data", "snapshots"), pattern = "^snap-.*\\.csv$")
  expect_setequal(ledger$filename, snaps)
  expect_gt(nrow(ledger), 0)  # 初回収集済み
  expect_false(is.unsorted(ledger$collected_at_utc))
  for (i in seq_len(nrow(ledger))) {
    path <- file.path(root, "data", "snapshots", ledger$filename[i])
    expect_equal(digest(file = path, algo = "sha256"), ledger$sha256[i],
                 info = ledger$filename[i])
  }
})

test_that("スナップショットの列規約と outlet×guid 一意(T-013)", {
  ledger <- read_csv(file.path(root, "data", "ledger.csv"), col_types = "ccc")
  skip_if(nrow(ledger) == 0)
  for (fn in ledger$filename) {
    s <- read_csv(file.path(root, "data", "snapshots", fn), col_types = "ccccc")
    expect_equal(names(s), c("outlet", "guid", "link", "title", "collected_at_utc"))
    expect_false(any(duplicated(paste(s$outlet, s$guid))), info = fn)
    expect_gte(length(unique(s$outlet)), 2)  # 多社であること(1 社失敗までは許容)
    # 挙動表(HC-001): 時刻は ISO8601 T/Z 付き。format/tz 明示でパース
    t <- as.POSIXct(s$collected_at_utc, tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")
    expect_false(any(is.na(t)), info = fn)
    stamp <- sub("^snap-([0-9]{8}-[0-9]{4})\\.csv$", "\\1", fn)
    expect_true(all(format(t, "%Y%m%d-%H%M", tz = "UTC") == stamp), info = fn)
  }
})
