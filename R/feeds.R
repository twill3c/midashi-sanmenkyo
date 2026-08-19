# フィード定義(F-01)。2026-08-19 検分。
# 不採用の記録: 共同通信 /feed/ はコーポレート PR フィード、時事 ranking.rdf は
# アクセスランキング(編集面と性質が異なる)、産経・TBS は 404。

suppressPackageStartupMessages(library(tibble))

FEED_UA <- "midashi-sanmenkyo/0.1 (+https://github.com/twill3c/midashi-sanmenkyo)"

feeds <- function() {
  tibble(
    outlet = c("NHK", "朝日新聞", "毎日新聞"),
    feed_id = c("nhk", "asahi", "mainichi"),
    url = c(
      "https://news.web.nhk/n-data/conf/na/rss/cat0.xml",
      "https://www.asahi.com/rss/asahi/newsheadlines.rdf",
      "https://mainichi.jp/rss/etc/mainichi-flash.rss"
    ),
    format = c("rss2", "rdf", "rdf"),
    terms_note = c(
      "NHK ニュース RSS(hodo-hangenki と同一ソース)。見出し+リンクのみ・出典明記",
      "朝日新聞 RSS(公開見出しフィード)。見出し+リンクのみ・非営利・出典明記",
      "毎日新聞 ニュース速報(総合)RSS。見出し+リンクのみ・非営利・出典明記"
    )
  )
}
