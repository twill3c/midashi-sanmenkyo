# RSS 2.0 / RSS 1.0(RDF)→ 行データの純関数(T-014)。
# 名前空間は xml_ns_strip で剥がし、//item を両形式共通で拾う。
# RDF の channel <link> は <item> の外にあるため //item/link だけを見る設計で混入しない。
# guid が無い形式(RDF)は link を同一性キーにする(SPEC §2)。

suppressPackageStartupMessages({
  library(xml2)
  library(tibble)
})

parse_feed <- function(xml, outlet) {
  xml <- xml_ns_strip(xml)
  items <- xml_find_all(xml, "//item")
  if (length(items) == 0) stop(outlet, ": item が 0 件")
  link <- xml_text(xml_find_first(items, "./link"))
  guid <- xml_text(xml_find_first(items, "./guid"))
  guid <- ifelse(is.na(guid) | guid == "", link, guid)
  d <- tibble(
    outlet = outlet,
    guid = guid,
    link = link,
    title = trimws(xml_text(xml_find_first(items, "./title")))
  )
  if (any(is.na(d$guid) | d$guid == "")) stop(outlet, ": guid も link も無い item")
  if (any(is.na(d$title) | d$title == "")) stop(outlet, ": title の無い item")
  d[!duplicated(d$guid), ]
}
