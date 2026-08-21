# 三面鏡クラスタの抽出(F-06/T-017)。純関数。
# 「三面鏡クラスタ」= 2 社以上を含む事象クラスタ(SPEC §2)。1 社だけのクラスタは
# 対照にならないため表示しない。

suppressPackageStartupMessages(library(dplyr))

# st: tibble(guid, outlet, title, link, first_seen)
# 返り値: cluster_id 付きの行(2 社以上のクラスタのみ)。
#   cluster_id は「クラスタ内の最新 first_seen」の降順に 1..k で振り直す(新着順表示)。
build_mirror_clusters <- function(st, threshold) {
  if (nrow(st) == 0) {
    return(mutate(st, cluster_id = integer(0)))
  }
  st$raw_cluster <- cluster_headlines(st$title, threshold)
  multi <- st |>
    group_by(raw_cluster) |>
    filter(n_distinct(outlet) >= 2) |>
    ungroup()
  if (nrow(multi) == 0) {
    return(mutate(multi, cluster_id = integer(0)) |> select(-raw_cluster))
  }
  order_tbl <- multi |>
    group_by(raw_cluster) |>
    summarise(latest = max(first_seen), .groups = "drop") |>
    arrange(desc(latest), raw_cluster) |>
    mutate(cluster_id = row_number())
  multi |>
    left_join(order_tbl, by = "raw_cluster") |>
    arrange(cluster_id, first_seen, outlet) |>
    select(-raw_cluster, -latest)
}
