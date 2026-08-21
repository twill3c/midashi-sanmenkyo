# G-04 較正ゲート(T-009)。閾値と基準は loop_006 の較正実測でのみ固定した数値であり、
# 緩和は再較正の証拠(build/calibrate.R の出力)なしに行ってはならない(AGENTS §3)。
#
# 較正実測(2026-08-22、49 スナップショット・524 ストーリー・社跨ぎ 24h 内 61,387 ペア):
#   th=0.40 → 推定精度 0.963 / 条件付き再現 0.496
#   th=0.30 → 推定精度 0.707 / 条件付き再現 0.668
#   三面鏡は誤並置が可視的に悪いため精度優先で 0.40 を採用。
#   基準は実測から余裕を取り 精度 >= 0.90・再現 >= 0.40 に固定。
suppressPackageStartupMessages({library(readr); library(dplyr)})
source("../../R/params.R", chdir = TRUE)

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))
lp <- read_csv(file.path(root, "tests", "testthat", "fixtures", "labeled_pairs.csv"),
               col_types = cols())

# 帯サイズで重み付けした母集団推定(ラベルは高類似帯を厚く抽出しているため必須)
bands <- lp |>
  group_by(band, band_size) |>
  summarise(n = n(), pos = sum(same_event), lo = min(sim), .groups = "drop") |>
  mutate(est_pos = band_size * pos / n)
POOL_MIN <- 0.15  # 候補プール下限(これ未満は閾値でなく類似度指標の限界 — calibrate.R 参照)

test_that("ラベル資産が F-04 の最少件数を満たす(T-009)", {
  expect_gte(sum(lp$same_event == 1), 30)
  expect_gte(sum(lp$same_event == 0), 30)
  # 層化の記録(帯・帯サイズ)が全行にある = 重み付け推定が可能
  expect_false(any(is.na(lp$band) | is.na(lp$band_size)))
  expect_true(all(lp$same_event %in% c(0, 1)))
})

test_that("採用閾値での推定精度・条件付き再現がゲートを満たす(T-009/G-04)", {
  sel <- bands$lo >= SIM_THRESHOLD
  expect_true(any(sel), info = "採用閾値以上の帯にラベルがない")
  tp <- sum(bands$est_pos[sel])
  npred <- sum(bands$band_size[sel])
  pool_pos <- sum(bands$est_pos[bands$lo >= POOL_MIN])
  precision <- tp / npred
  recall <- tp / pool_pos
  expect_gte(precision, 0.90)
  expect_gte(recall, 0.40)
})

test_that("閾値が較正済みの範囲にある(T-009)", {
  # 較正でスイープした範囲外の閾値は「未較正」であり使ってはならない
  expect_gte(SIM_THRESHOLD, 0.15)
  expect_lte(SIM_THRESHOLD, 0.40)
  expect_equal(SIM_THRESHOLD, 0.40)  # loop_006 の採用値(変更は再較正とセット)
})

test_that("採用閾値でのクラスタリングが陽性ペアを実際に束ねる(G-03×G-04)", {
  source(file.path(root, "R", "normalize.R"), chdir = TRUE)
  source(file.path(root, "R", "similarity.R"), chdir = TRUE)
  source(file.path(root, "R", "cluster.R"), chdir = TRUE)
  pos <- lp[lp$same_event == 1 & lp$sim >= SIM_THRESHOLD, ]
  expect_gt(nrow(pos), 0)
  for (i in seq_len(nrow(pos))) {
    cl <- cluster_headlines(c(pos$title1[i], pos$title2[i]), SIM_THRESHOLD)
    expect_equal(cl[1], cl[2], info = pos$title1[i])
  }
  # 閾値未満の陰性ペアは束ねない
  neg <- lp[lp$same_event == 0 & lp$sim < SIM_THRESHOLD, ]
  for (i in seq_len(min(20, nrow(neg)))) {
    cl <- cluster_headlines(c(neg$title1[i], neg$title2[i]), SIM_THRESHOLD)
    expect_false(cl[1] == cl[2], info = neg$title1[i])
  }
})
