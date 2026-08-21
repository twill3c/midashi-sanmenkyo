# HTML 生成の純関数(F-06)。見出しは必ず配信元への <a href> 付き(SPEC §5 リンク義務)。
# 並置に優劣・正誤の評価語は使わない(社名と見出しのみを並べる)。

suppressPackageStartupMessages({
  library(glue)
  library(dplyr)
})

esc <- function(x) {
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  gsub('"', "&quot;", x, fixed = TRUE)
}

OUTLET_CLASS <- c("NHK" = "o-nhk", "朝日新聞" = "o-asahi", "毎日新聞" = "o-mainichi")

# 1 クラスタ分のカード。cl: cluster_id/outlet/title/link を持つ行群
render_cluster_card <- function(cl) {
  rows <- vapply(seq_len(nrow(cl)), function(i) {
    sprintf('<li class="mirror-row"><span class="outlet %s">%s</span>%s<a class="headline" href="%s" target="_blank" rel="noopener">%s</a></li>',
            unname(OUTLET_CLASS[cl$outlet[i]]) %||% "o-other",
            esc(cl$outlet[i]), "",
            esc(cl$link[i]), esc(cl$title[i]))
  }, character(1))
  sprintf('<article class="mirror-card"><ul class="mirror-list">%s</ul></article>',
          paste(rows, collapse = ""))
}

`%||%` <- function(a, b) if (is.null(a) || is.na(a)) b else a

# 社別統計の表(HTML)
render_stats_table <- function(stats) {
  head <- '<tr><th>社</th><th>見出し数</th><th>平均文字数</th><th>体言止め</th><th>数字</th><th>かぎ括弧</th><th>感情語</th></tr>'
  pct <- function(x) sprintf("%.0f%%", 100 * x)
  rows <- vapply(seq_len(nrow(stats)), function(i) {
    s <- stats[i, ]
    sprintf('<tr><td>%s</td><td>%s</td><td>%.1f</td><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
            esc(s$outlet), format(s$n, big.mark = ","), s$mean_len,
            pct(s$rate_taigen), pct(s$rate_digit), pct(s$rate_kagi), pct(s$rate_emotion))
  }, character(1))
  sprintf('<table class="stats-table">%s%s</table>', head, paste(rows, collapse = ""))
}

render_index_html <- function(tpl, cards, n_clusters, n_stories, n_snapshots,
                              first_utc, latest_utc, footer) {
  glue(tpl, cards = cards,
       n_clusters = format(n_clusters, big.mark = ","),
       n_stories = format(n_stories, big.mark = ","),
       n_snapshots = format(n_snapshots, big.mark = ","),
       first_utc = first_utc, latest_utc = latest_utc, footer = footer,
       .open = "{{", .close = "}}")
}

render_stats_html <- function(tpl, table_html, n_stories, first_utc, latest_utc, footer) {
  glue(tpl, stats_table = table_html,
       n_stories = format(n_stories, big.mark = ","),
       first_utc = first_utc, latest_utc = latest_utc, footer = footer,
       .open = "{{", .close = "}}")
}
