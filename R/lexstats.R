# 語彙指標の純関数(F-05/G-01)。すべて決定的:
#   体言止め: 末尾の記号・空白(\p{P}\p{S}\p{Z})を除去した最終文字が「ひらがな以外」
#             (カタカナ・漢字・ラテン・数字止めは体言扱い — 見出しの慣用に合わせた定義)
#   数字使用: NFKC 正規化後に半角アラビア数字 [0-9] を含む(漢数字は数えない)
#   かぎ括弧: 生の見出しに 「」『』 のいずれかを含む
#   感情語:   固定辞書(data/dict/kokoro_dict.csv)の語を生見出しの部分文字列として含む。
#             同一語の重複出現は 1 語と数える。否定文脈の除外はしない(見出しでは稀 — SPEC §6)
#   見出し長: 前後空白を除いた文字数

suppressPackageStartupMessages({
  library(stringi)
  library(dplyr)
  library(readr)
})

is_taigendome <- function(x) {
  s <- stri_replace_all_regex(x, "[\\p{P}\\p{S}\\p{Z}]+$", "")
  n <- stri_length(s)
  if (is.na(n) || n == 0) return(FALSE)
  last <- stri_sub(s, n, n)
  !stri_detect_regex(last, "^[\\p{Hiragana}]$")
}

has_digit <- function(x) stri_detect_regex(stri_trans_nfkc(x), "[0-9]")

has_kagi <- function(x) stri_detect_regex(x, "[「」『』]")

title_len <- function(x) stri_length(trimws(x))

# 辞書語のうち、見出しに部分文字列として現れるユニーク語数
emo_count <- function(x, dict_words) {
  sum(vapply(unique(dict_words), function(w) stri_detect_fixed(x, w), logical(1)))
}

has_emotion <- function(x, dict_words) emo_count(x, dict_words) > 0

load_kokoro_dict <- function(path) {
  read_csv(path, comment = "#", col_types = "cdc")
}

# 社別集計。rate_* は「該当見出しの割合」。
lexstats_by_outlet <- function(df, dict_words) {
  df |>
    rowwise() |>
    mutate(
      taigen = is_taigendome(title),
      digit = has_digit(title),
      kagi = has_kagi(title),
      emo = has_emotion(title, dict_words),
      len = title_len(title)
    ) |>
    ungroup() |>
    group_by(outlet) |>
    summarise(
      n = n(),
      mean_len = mean(len),
      rate_taigen = mean(taigen),
      rate_digit = mean(digit),
      rate_kagi = mean(kagi),
      rate_emotion = mean(emo),
      .groups = "drop"
    )
}
