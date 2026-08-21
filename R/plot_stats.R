# 社別語彙統計のチャート(F-06)。ggplot 構築は純関数、save_svg のみ IO。

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
})

OUTLET_ORDER <- c("NHK", "朝日新聞", "毎日新聞")

# lexstats_by_outlet の出力 → 指標別のグループ棒グラフ
plot_outlet_stats <- function(stats) {
  d <- stats |>
    select(outlet, rate_taigen, rate_digit, rate_kagi, rate_emotion) |>
    pivot_longer(-outlet, names_to = "metric", values_to = "value") |>
    mutate(
      metric = factor(metric,
                      levels = c("rate_taigen", "rate_digit", "rate_kagi", "rate_emotion"),
                      labels = c("体言止め", "数字を含む", "かぎ括弧", "感情語を含む")),
      outlet = factor(outlet, levels = OUTLET_ORDER)
    )
  ggplot(d, aes(metric, value, fill = outlet)) +
    geom_col(position = position_dodge(width = 0.75), width = 0.68) +
    scale_y_continuous(labels = function(x) paste0(round(x * 100), "%"),
                       limits = c(0, 1)) +
    scale_fill_manual(values = c("NHK" = "#2563eb", "朝日新聞" = "#e07a3f",
                                 "毎日新聞" = "#4a9d6b"), name = NULL, drop = FALSE) +
    labs(x = NULL, y = "その特徴を持つ見出しの割合",
         title = "見出しの癖 — 社別比較") +
    theme_minimal(base_family = "sans", base_size = 11) +
    theme(plot.background = element_rect(fill = "#ffffff", colour = NA),
          panel.grid.major.x = element_blank(),
          panel.grid.minor = element_blank(),
          legend.position = "top",
          plot.title = element_text(size = 12, face = "bold"))
}

save_svg <- function(p, path, width, height) {
  ggsave(path, p, device = svglite::svglite, width = width, height = height,
         bg = "#ffffff")
  invisible(path)
}
