# 見出し正規化の純関数(F-02)。
# 定義: NFKC 正規化(全角英数→半角・半角カナ→全角)→ ラテン文字小文字化 →
#       句読点(\p{P})・記号(\p{S})・空白(\p{Z})の除去。
# この順序は固定(先に NFKC しないと全角記号が除去対象にならない)。

suppressPackageStartupMessages(library(stringi))

normalize_title <- function(x) {
  x <- stri_trans_nfkc(x)
  x <- stri_trans_tolower(x)
  stri_replace_all_regex(x, "[\\p{P}\\p{S}\\p{Z}]+", "")
}
