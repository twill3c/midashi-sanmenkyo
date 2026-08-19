# 語彙指標(T-010〜T-012 / G-01)。定義は R/lexstats.R 冒頭のとおり決定的。
suppressPackageStartupMessages(library(dplyr))
source("../../R/normalize.R", chdir = TRUE)
source("../../R/lexstats.R", chdir = TRUE)

root <- normalizePath(file.path(testthat::test_path(), "..", ".."))

test_that("体言止め判定(T-010): 末尾記号を除去した最終文字がひらがな以外", {
  expect_true(is_taigendome("首相が辞任を表明"))    # 漢字止め
  expect_false(is_taigendome("首相が辞任を表明した")) # ひらがな止め
  expect_false(is_taigendome("円安が進む"))
  expect_true(is_taigendome("国内で最高気温を更新?"))  # 末尾記号は除去して判定
  expect_true(is_taigendome("決勝進出はカナダ"))     # カタカナ止め = 体言扱い
  expect_false(is_taigendome("決勝へ"))              # 助詞ひらがな
  expect_true(is_taigendome("選手がV"))              # ラテン文字止め = 体言扱い(定義)
})

test_that("数字・かぎ括弧・見出し長(T-011)", {
  # 数字: NFKC 正規化後の半角アラビア数字のみ。漢数字は数えない(定義)
  expect_true(has_digit("3人が死亡"))
  expect_true(has_digit("GDP3.5%増"))   # 全角→NFKC→半角
  expect_false(has_digit("三人が死亡"))
  # かぎ括弧: 生の見出しに 「」『』 のいずれかを含む
  expect_true(has_kagi("首相「大変残念」"))
  expect_true(has_kagi("『合意』の内幕"))
  expect_false(has_kagi("首相が表明"))
  # 見出し長: 前後空白を除いた文字数
  expect_equal(title_len(" 首相が表明 "), 5)
})

test_that("感情語マッチ(T-012): 部分集合辞書での手数え一致", {
  mini_dict <- c("勝利", "不安", "あきらめる")
  expect_equal(emo_count("代表が勝利 市場に不安広がる", mini_dict), 2)
  expect_equal(emo_count("首相が表明", mini_dict), 0)
  expect_equal(emo_count("勝利の勝利", mini_dict), 1)  # 同一語の重複は 1 語として数える(定義)
  expect_true(has_emotion("勝利した", mini_dict))
})

test_that("固定辞書の読込: 419 語・列規約(F-05)", {
  d <- load_kokoro_dict(file.path(root, "data", "dict", "kokoro_dict.csv"))
  expect_equal(nrow(d), 419)
  expect_equal(names(d), c("word", "polarity", "category"))
  expect_false(any(duplicated(d$word)))
  expect_true(all(abs(d$polarity) <= 1))
})

test_that("社別集計(G-01): 手計算フィクスチャと厳密一致", {
  df <- tibble::tibble(
    outlet = c("A", "A", "A", "B"),
    title = c("首相が辞任を表明",       # 体言止め・数字なし・かぎなし
              "「合意」3人が語った",     # かぎ・数字・た止め(用言)
              "市場に不安",             # 体言止め・感情語
              "五輪代表が決定")          # 体言止め
  )
  st <- lexstats_by_outlet(df, dict_words = c("不安"))
  a <- st[st$outlet == "A", ]
  expect_equal(a$n, 3)
  expect_equal(a$rate_taigen, 2 / 3)
  expect_equal(a$rate_digit, 1 / 3)
  expect_equal(a$rate_kagi, 1 / 3)
  expect_equal(a$rate_emotion, 1 / 3)
  expect_equal(a$mean_len, mean(c(8, 10, 5)))
  b <- st[st$outlet == "B", ]
  expect_equal(b$rate_taigen, 1)
})
