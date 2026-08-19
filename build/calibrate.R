# G-04 較正スイープ(F-04)。手ラベルペア集合に対し閾値ごとの precision/recall を実測する。
# 使い方: Rscript build/calibrate.R
# 出力は表のみ — 閾値・ゲート基準の「固定」は、陽性 ≥30・陰性 ≥30 を満たした
# ラベル集合での実測を確認した人間/エージェントが R/params.R と T-009 に書き込むこと。
#
# ラベル規約(tests/testthat/fixtures/labeled_pairs.csv):
#   same_event = 1: 同一の出来事・展開を報じる見出し同士
#   same_event = 0: 別事象(同一大事象の別展開 — 首相コメント vs 声明 等 — も 0)
#   注意: 現行ラベルは sim ≥ 0.15 の候補から作っており、低類似度側の陽性
#   (言い換えが激しい同事象)を含まない — recall は上振れしうる(サンプリング限界)。

suppressPackageStartupMessages({library(readr); library(dplyr)})

lp <- read_csv("tests/testthat/fixtures/labeled_pairs.csv", col_types = cols())
cat("ラベル: 陽性", sum(lp$same_event == 1), "/ 陰性", sum(lp$same_event == 0), "\n")
if (sum(lp$same_event == 1) < 30 || sum(lp$same_event == 0) < 30) {
  cat("⚠ F-04 の最少件数(各 30)未満 — この表は暫定であり、ゲート固定に使ってはならない\n")
}
cat("\n閾値  precision  recall  F1\n")
for (th in seq(0.15, 0.55, by = 0.05)) {
  pred <- lp$sim >= th
  tp <- sum(pred & lp$same_event == 1)
  fp <- sum(pred & lp$same_event == 0)
  fn <- sum(!pred & lp$same_event == 1)
  prec <- if (tp + fp == 0) NA else tp / (tp + fp)
  rec <- if (tp + fn == 0) NA else tp / (tp + fn)
  f1 <- if (is.na(prec) || is.na(rec) || prec + rec == 0) NA else
    2 * prec * rec / (prec + rec)
  cat(sprintf("%.2f  %9.3f  %6.3f  %5.3f\n", th, prec, rec, f1))
}
cat("CALIBRATE DONE\n")
