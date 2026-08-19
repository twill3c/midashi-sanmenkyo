# 時刻ユーティリティの純関数。
# 罠(loop_003 で実証): as.POSIXct(trunc(Sys.time(), "mins"), tz = "UTC") は
# POSIXlt が持つローカル時計値を UTC として**再解釈**し、JST 環境では 9 時間ずれる。
# 必ず tzone を UTC に切り替えてから trunc する。

# now(POSIXct)→ 分単位に切り捨てた UTC の POSIXct
utc_minute <- function(now) {
  stopifnot(inherits(now, "POSIXct"))
  attr(now, "tzone") <- "UTC"
  as.POSIXct(trunc(now, "mins"), tz = "UTC")
}

utc_iso <- function(t) format(t, "%Y-%m-%dT%H:%M:%SZ", tz = "UTC")
utc_stamp <- function(t) format(t, "%Y%m%d-%H%M", tz = "UTC")
