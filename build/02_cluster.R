# スナップショット列 → ストーリー畳み込み → 三面鏡クラスタ + 社別統計(F-03〜F-05)。
# 出力: data/processed/clusters.csv, stats.csv, meta.csv

suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
source("R/normalize.R")
source("R/similarity.R")
source("R/cluster.R")
source("R/params.R")
source("R/mirror.R")
source("R/lexstats.R")

WINDOW_H <- 48  # クラスタ表示の対象: 直近このウィンドウ内に初出した見出し

ledger <- read_csv("data/ledger.csv", col_types = "ccc")
stopifnot(nrow(ledger) > 0)
parse_utc <- function(x) {
  t <- as.POSIXct(x, tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")  # format 明示(HC-001)
  stopifnot(!any(is.na(t)))
  t
}

snaps <- lapply(ledger$filename, function(fn)
  suppressMessages(read_csv(file.path("data/snapshots", fn), col_types = "ccccc")))
all <- bind_rows(snaps)
all$t <- parse_utc(all$collected_at_utc)

# ストーリー単位に畳む(初出時刻・初出時のタイトルを採る)
st <- all |>
  arrange(t) |>
  group_by(outlet, guid) |>
  summarise(title = first(title), link = first(link), first_seen = min(t),
            .groups = "drop")
message("stories: ", nrow(st), " / snapshots: ", nrow(ledger))

latest <- max(all$t)
recent <- st |> filter(first_seen >= latest - WINDOW_H * 3600)
message("recent(", WINDOW_H, "h): ", nrow(recent))

cl <- build_mirror_clusters(recent, threshold = SIM_THRESHOLD)
message("mirror clusters: ", length(unique(cl$cluster_id)))

dict <- load_kokoro_dict("data/dict/kokoro_dict.csv")
stats <- lexstats_by_outlet(st, dict_words = dict$word)

dir.create("data/processed", showWarnings = FALSE, recursive = TRUE)
write_csv(cl, "data/processed/clusters.csv")
write_csv(stats, "data/processed/stats.csv")
write_csv(tibble(
  n_snapshots = nrow(ledger),
  n_stories = nrow(st),
  n_clusters = length(unique(cl$cluster_id)),
  first_utc = format(min(all$t), "%Y-%m-%dT%H:%M:%SZ", tz = "UTC"),
  latest_utc = format(latest, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
), "data/processed/meta.csv")
message("CLUSTER DONE")
