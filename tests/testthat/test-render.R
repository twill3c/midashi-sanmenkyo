# レンダリング(T-015〜T-017 / F-06・G-06)。
# 単体はフィクスチャ駆動、統合は build/02_cluster.R → build/03_render.R 実行後の out/。
suppressPackageStartupMessages({library(digest); library(dplyr)})
source("../../R/normalize.R", chdir = TRUE)
source("../../R/similarity.R", chdir = TRUE)
source("../../R/cluster.R", chdir = TRUE)
source("../../R/params.R", chdir = TRUE)
source("../../R/mirror.R", chdir = TRUE)
source("../../R/lexstats.R", chdir = TRUE)
source("../../R/plot_stats.R", chdir = TRUE)
source("../../R/render_page.R", chdir = TRUE)
source("../../R/footer.R", chdir = TRUE)

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
out_dir <- file.path(root, "out")

fix_stats <- tibble::tibble(
  outlet = c("NHK", "朝日新聞", "毎日新聞"),
  n = c(10L, 20L, 30L),
  mean_len = c(24.0, 30.0, 28.0),
  rate_taigen = c(0.9, 0.5, 0.6),
  rate_digit = c(0.4, 0.3, 0.35),
  rate_kagi = c(0.1, 0.4, 0.45),
  rate_emotion = c(0.2, 0.25, 0.3)
)

test_that("G-06: 統計チャート SVG の 2 回レンダリングでバイト一致(T-016)", {
  f1 <- tempfile(fileext = ".svg"); f2 <- tempfile(fileext = ".svg")
  save_svg(plot_outlet_stats(fix_stats), f1, width = 8, height = 5)
  save_svg(plot_outlet_stats(fix_stats), f2, width = 8, height = 5)
  expect_equal(digest(file = f1, algo = "sha256"), digest(file = f2, algo = "sha256"))
})

test_that("G-06: 回帰フィクスチャとハッシュ一致(T-016)", {
  fixture <- file.path(testthat::test_path(), "fixtures", "stats_fixture.svg")
  expect_true(file.exists(fixture), info = "build/make_fixture.R 未実行")
  skip_if_not(file.exists(fixture))
  f <- tempfile(fileext = ".svg")
  save_svg(plot_outlet_stats(fix_stats), f, width = 8, height = 5)
  expect_equal(digest(file = f, algo = "sha256"), digest(file = fixture, algo = "sha256"))
})

test_that("三面鏡カード HTML: 見出しが配信元リンク・評価語なし(T-015/F-06)", {
  cl <- tibble::tibble(
    cluster_id = c(1L, 1L),
    outlet = c("NHK", "朝日新聞"),
    title = c("首相が辞任を表明", "首相、辞任を表明へ"),
    link = c("https://news.web.nhk/newsweb/na/nd-1",
             "https://www.asahi.com/articles/ASV1.html")
  )
  html <- render_cluster_card(cl)
  # 見出しは必ず配信元への <a href>(SVG に埋めない — SPEC §5 リンク義務)
  expect_match(html, 'href="https://news.web.nhk/newsweb/na/nd-1"', fixed = TRUE)
  expect_match(html, 'href="https://www.asahi.com/articles/ASV1.html"', fixed = TRUE)
  expect_match(html, "首相が辞任を表明", fixed = TRUE)
  expect_match(html, "NHK", fixed = TRUE)
  expect_match(html, 'rel="noopener"', fixed = TRUE)
  # HTML エスケープ(見出しに < > & が来ても壊れない)
  cl2 <- cl; cl2$title[1] <- "A&B <社> の\"合意\""
  h2 <- render_cluster_card(cl2)
  expect_match(h2, "A&amp;B &lt;社&gt;", fixed = TRUE)
  expect_false(grepl("<社>", h2, fixed = TRUE))
})

test_that("三面鏡クラスタの抽出: 2 社以上のみ・単独社は除く(T-017/F-06)", {
  st <- tibble::tibble(
    guid = as.character(1:5),
    outlet = c("NHK", "朝日新聞", "毎日新聞", "NHK", "朝日新聞"),
    title = c("首相が辞任を表明", "首相、辞任を表明へ", "まったく別の話題です",
              "台風10号が九州に接近", "台風10号が九州に接近"),
    link = paste0("https://example.com/", 1:5),
    first_seen = as.POSIXct("2026-08-22 00:00:00", tz = "UTC") + c(0, 60, 120, 180, 240)
  )
  cl <- build_mirror_clusters(st, threshold = SIM_THRESHOLD)
  # 「首相辞任」(NHK+朝日)と「台風」(NHK+朝日)が三面鏡クラスタ、「別の話題」は単独で除外
  expect_equal(length(unique(cl$cluster_id)), 2)
  expect_false(any(cl$title == "まったく別の話題です"))
  # 各クラスタは 2 社以上
  per <- cl |> group_by(cluster_id) |> summarise(k = n_distinct(outlet), .groups = "drop")
  expect_true(all(per$k >= 2))
})

test_that("フッタ定義: 公開済みリンクのみ・全 https(F-08)", {
  links <- footer_links()
  expect_equal(vapply(links, function(l) l$label, ""), c("MIT License", "GitHub", "App Menu"))
  for (l in links) expect_match(l$href, "^https://")
  expect_match(footer_html(links), "© 2026 坂田哲朗", fixed = TRUE)
})

# ---- 統合(out/) ----

test_that("out/ の構成と規約(T-015/F-06)", {
  expect_true(file.exists(file.path(out_dir, "index.html")), info = "03_render 未実行")
  skip_if_not(file.exists(file.path(out_dir, "index.html")))
  expect_true(file.exists(file.path(out_dir, "style.css")))
  expect_true(file.exists(file.path(out_dir, "toukei", "index.html")))
  expect_true(file.exists(file.path(out_dir, "toukei", "stats.svg")))

  idx <- paste(readLines(file.path(out_dir, "index.html"), encoding = "UTF-8",
                         warn = FALSE), collapse = "\n")
  expect_false(grepl("<script", idx, fixed = TRUE))     # 閲覧時 JS なし(F-06)
  expect_match(idx, "site-footer", fixed = TRUE)
  expect_match(idx, "NHK", fixed = TRUE)                 # 出典明記(SPEC §5)
  expect_match(idx, "取得", fixed = TRUE)                # 取得時刻
  # 見出しリンクが 3 社の配信元ドメインを指す
  expect_match(idx, "news.web.nhk", fixed = TRUE)
  expect_match(idx, "asahi.com", fixed = TRUE)
  expect_match(idx, "mainichi.jp", fixed = TRUE)

  st <- paste(readLines(file.path(out_dir, "toukei", "index.html"), encoding = "UTF-8",
                        warn = FALSE), collapse = "\n")
  expect_false(grepl("<script", st, fixed = TRUE))
  expect_match(st, "体言止め", fixed = TRUE)
  expect_match(st, "site-footer", fixed = TRUE)
})

test_that("固定フッタのフリート慣例が CSS にある(F-06)", {
  css <- file.path(out_dir, "style.css")
  skip_if_not(file.exists(css))
  s <- paste(readLines(css, encoding = "UTF-8", warn = FALSE), collapse = "\n")
  expect_match(s, "position: fixed", fixed = TRUE)
  expect_match(s, "padding-bottom", fixed = TRUE)
})
