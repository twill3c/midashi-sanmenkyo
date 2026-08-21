# G-06 回帰フィクスチャ(tests/testthat/fixtures/stats_fixture.svg)の生成。
# 実行はフィクスチャ更新時のみ(test: update fixtures 専用コミット + 理由記録)。
# 入力は tests/testthat/test-render.R の fix_stats と同一に保つこと。
source("R/plot_stats.R")

fix_stats <- tibble::tibble(
  outlet = c("NHK", "朝日新聞", "毎日新聞"),
  n = c(10L, 20L, 30L),
  mean_len = c(24.0, 30.0, 28.0),
  rate_taigen = c(0.9, 0.5, 0.6),
  rate_digit = c(0.4, 0.3, 0.35),
  rate_kagi = c(0.1, 0.4, 0.45),
  rate_emotion = c(0.2, 0.25, 0.3)
)
dir.create("tests/testthat/fixtures", recursive = TRUE, showWarnings = FALSE)
save_svg(plot_outlet_stats(fix_stats), "tests/testthat/fixtures/stats_fixture.svg",
         width = 8, height = 5)
message("FIXTURE DONE")
