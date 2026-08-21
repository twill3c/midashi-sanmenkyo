# data/processed/ から index(三面鏡カード)+ toukei(社別統計)を out/ に生成(F-06)。
suppressPackageStartupMessages({
  library(readr)
  library(dplyr)
})
source("R/plot_stats.R")
source("R/render_page.R")
source("R/footer.R")

MAX_CARDS <- 40  # index に載せるクラスタ数の上限(新着順)

cl <- read_csv("data/processed/clusters.csv", col_types = cols())
stats <- read_csv("data/processed/stats.csv", col_types = cols())
meta <- read_csv("data/processed/meta.csv", col_types = cols())

tpl_index <- paste(readLines("site/template_index.html", encoding = "UTF-8"), collapse = "\n")
tpl_stats <- paste(readLines("site/template_stats.html", encoding = "UTF-8"), collapse = "\n")
footer <- footer_html()

dir.create("out", showWarnings = FALSE)
dir.create("out/toukei", showWarnings = FALSE, recursive = TRUE)
file.copy("site/style.css", "out/style.css", overwrite = TRUE)

ids <- head(sort(unique(cl$cluster_id)), MAX_CARDS)
cards <- vapply(ids, function(id) render_cluster_card(cl[cl$cluster_id == id, ]),
                character(1))
if (length(cards) == 0) cards <- '<p class="definition">まだ三面鏡クラスタがありません(データ蓄積中)。</p>'

writeLines(render_index_html(tpl_index, paste(cards, collapse = "\n      "),
                             n_clusters = length(ids), n_stories = meta$n_stories,
                             n_snapshots = meta$n_snapshots,
                             first_utc = meta$first_utc, latest_utc = meta$latest_utc,
                             footer = footer),
           "out/index.html", useBytes = TRUE)

stats <- stats |> arrange(match(outlet, OUTLET_ORDER))
save_svg(plot_outlet_stats(stats), "out/toukei/stats.svg", width = 8, height = 5)
writeLines(render_stats_html(tpl_stats, render_stats_table(stats),
                             n_stories = meta$n_stories,
                             first_utc = meta$first_utc, latest_utc = meta$latest_utc,
                             footer = footer),
           "out/toukei/index.html", useBytes = TRUE)
message("RENDER DONE")
