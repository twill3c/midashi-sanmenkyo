# 閾値グラフの連結成分によるクラスタリング(F-03/G-03)。
# 返り値: 見出しごとのクラスタ id(整数)。id は「最初に現れる見出しの順」に 1..k で
# 振る(決定論・表示安定性)。O(n²) — 1 ウィンドウ数百件の想定で十分。

cluster_headlines <- function(titles, threshold) {
  stopifnot(is.numeric(threshold), length(threshold) == 1)
  n <- length(titles)
  if (n == 0) return(integer(0))
  bg <- lapply(titles, bigrams)
  # 隣接リスト(閾値以上の辺)
  adj <- vector("list", n)
  for (i in seq_len(n - 1)) {
    if (length(bg[[i]]) == 0) next
    for (j in (i + 1):n) {
      if (length(bg[[j]]) == 0) next
      sim <- length(intersect(bg[[i]], bg[[j]])) /
        sqrt(length(bg[[i]]) * length(bg[[j]]))
      if (sim >= threshold) {
        adj[[i]] <- c(adj[[i]], j)
        adj[[j]] <- c(adj[[j]], i)
      }
    }
  }
  # BFS で連結成分(訪問順 = インデックス順 → id が出現順で安定)
  cl <- rep(NA_integer_, n)
  k <- 0L
  for (s in seq_len(n)) {
    if (!is.na(cl[s])) next
    k <- k + 1L
    queue <- s
    cl[s] <- k
    while (length(queue) > 0) {
      v <- queue[1]; queue <- queue[-1]
      for (w in adj[[v]]) {
        if (is.na(cl[w])) {
          cl[w] <- k
          queue <- c(queue, w)
        }
      }
    }
  }
  cl
}
