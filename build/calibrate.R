# G-04 較正スイープ(F-04)。層化サンプルの手ラベルから、帯サイズで重み付けした
# precision / conditional recall を推定する。
# 使い方: Rscript build/calibrate.R
#
# 重み付けの理由: ラベルは陽性が集中する高類似帯を厚く抽出しているため、
# 単純集計の precision は実運用値と一致しない。帯ごとの陽性率を帯サイズで
# 重み付けし、母集団(社跨ぎ・初出 24h 以内の全ペア)での値を推定する。
#
# recall の定義(重要): 母集団の陽性総数は未知(最下位帯 [0,0.05) は 59,970 ペアあり、
# 標本 10 件で陽性 0 だが上限は抑えられない)。よって recall は
# **候補プール(sim >= 0.15)内の条件付き recall** として報告する。
# 0.15 未満で取り逃す陽性は「閾値の問題」ではなく「バイグラム類似度の限界」であり、
# 閾値選択のゲートには含めない(この限界は SPEC §6 のスコープ外事項として記す)。

suppressPackageStartupMessages({library(readr); library(dplyr)})

lp <- read_csv("tests/testthat/fixtures/labeled_pairs.csv", col_types = cols())
cat("ラベル総数:", nrow(lp), " 陽性:", sum(lp$same_event),
    " 陰性:", sum(1 - lp$same_event), "\n")
if (sum(lp$same_event == 1) < 30 || sum(lp$same_event == 0) < 30) {
  stop("F-04 の最少件数(各 30)未満 — ゲート固定に使ってはならない")
}

bands <- lp |>
  group_by(band, band_size) |>
  summarise(n = n(), pos = sum(same_event), lo = min(sim), .groups = "drop") |>
  mutate(rate = pos / n, est_pos = band_size * rate) |>
  arrange(desc(lo))
print(as.data.frame(bands))

POOL_MIN <- 0.15
pool_pos <- sum(bands$est_pos[bands$lo >= POOL_MIN])
cat("\n候補プール(sim>=", POOL_MIN, ")の推定陽性総数: ", round(pool_pos, 1), "\n\n", sep = "")

cat("閾値  予測数  推定精度  条件付き再現  F1\n")
for (th in c(0.15, 0.20, 0.25, 0.30, 0.40)) {
  sel <- bands$lo >= th
  npred <- sum(bands$band_size[sel])
  tp <- sum(bands$est_pos[sel])
  prec <- tp / npred
  rec <- tp / pool_pos
  f1 <- 2 * prec * rec / (prec + rec)
  cat(sprintf("%.2f  %6d  %8.3f  %12.3f  %5.3f\n", th, npred, prec, rec, f1))
}
cat("CALIBRATE DONE\n")
