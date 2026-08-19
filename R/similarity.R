# 文字バイグラム類似度の純関数(F-03/G-02)。辞書・形態素解析に依存しない。

suppressPackageStartupMessages(library(stringi))

# 正規化済み(または生)文字列 → バイグラムのユニーク集合
bigrams <- function(x) {
  s <- normalize_title(x)
  n <- stri_length(s)
  if (is.na(n) || n < 2) return(character(0))
  unique(vapply(seq_len(n - 1), function(i) stri_sub(s, i, i + 1), character(1)))
}

# バイグラム集合のコサイン類似度(集合版: |A∩B| / sqrt(|A||B|))。
# 挙動表: 空集合が絡む場合(1 文字・空文字)は 0 と定義する。
cosine_sim <- function(a, b) {
  A <- bigrams(a); B <- bigrams(b)
  if (length(A) == 0 || length(B) == 0) return(0)
  length(intersect(A, B)) / sqrt(length(A) * length(B))
}
