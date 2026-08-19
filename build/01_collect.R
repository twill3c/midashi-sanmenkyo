# 多社 RSS → data/snapshots/ 1 収集 = 1 不変 CSV + SHA256 台帳(F-01)。
# 使い方: Rscript build/01_collect.R [--at 2026-08-19T15:00:00Z]
# 1 社の取得失敗では止めない(取れた社だけで書く)。全社失敗なら stop。

suppressPackageStartupMessages({
  library(readr)
  library(xml2)
  library(digest)
  library(dplyr)
})
source("R/feeds.R")
source("R/parse_feed.R")
source("R/timeutil.R")

args <- commandArgs(trailingOnly = TRUE)
at <- if (length(args) >= 2 && args[1] == "--at") {
  as.POSIXct(args[2], tz = "UTC", format = "%Y-%m-%dT%H:%M:%SZ")
} else {
  utc_minute(Sys.time())
}
stopifnot(!is.na(at))
dest <- file.path("data/snapshots", paste0("snap-", utc_stamp(at), ".csv"))
if (file.exists(dest)) stop("スナップショットが既に存在する(不変規約): ", dest)

f <- feeds()
rows <- list()
for (i in seq_len(nrow(f))) {
  message("fetch: ", f$feed_id[i], " (", f$outlet[i], ")")
  rows[[i]] <- tryCatch({
    con <- url(f$url[i], headers = c(`User-Agent` = FEED_UA))
    parse_feed(read_xml(con), f$outlet[i])
  }, error = function(e) {
    message("SKIP ", f$outlet[i], ": ", conditionMessage(e))
    NULL
  })
}
snap <- bind_rows(rows)
if (nrow(snap) == 0) stop("全社の取得に失敗")
snap$collected_at_utc <- utc_iso(at)
stopifnot(!any(duplicated(paste(snap$outlet, snap$guid))))

write_csv(snap, dest)
sha <- digest(file = dest, algo = "sha256")
cat(sprintf("%s,%s,%s\n", basename(dest), sha, utc_iso(at)),
    file = "data/ledger.csv", append = TRUE)
message("collected: ", nrow(snap), " rows (",
        length(unique(snap$outlet)), " outlets) -> ", dest)
message("COLLECT DONE")
