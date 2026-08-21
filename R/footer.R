# フッタ定義(F-08)。フリート標準の並び。
# 歩き方/設計図はアーティファクト(2026-08-22 公開。閲覧には所有者の共有設定が必要)。

footer_links <- function() {
  list(
    list(label = "MIT License",
         href = "https://github.com/twill3c/midashi-sanmenkyo/blob/main/LICENSE"),
    list(label = "GitHub",
         href = "https://github.com/twill3c/midashi-sanmenkyo"),
    list(label = "三面鏡の見方",
         href = "https://claude.ai/code/artifact/47ad2bb3-e970-4623-913e-0336bea1a682"),
    list(label = "三面鏡の設計図",
         href = "https://claude.ai/code/artifact/9bede7e7-fc79-4fdc-9927-b541a301b4aa"),
    list(label = "App Menu",
         href = "https://app-menu-amber.vercel.app")
  )
}

footer_html <- function(links = footer_links()) {
  parts <- vapply(seq_along(links), function(i) {
    l <- links[[i]]
    sep <- if (i > 1) " ・ " else ""
    suffix <- if (l$label == "MIT License") " © 2026 坂田哲朗" else ""
    sprintf('%s<a href="%s" target="_blank" rel="noopener">%s</a>%s',
            sep, l$href, l$label, suffix)
  }, character(1))
  sprintf('<footer class="site-footer"><p>%s</p></footer>',
          paste(parts, collapse = ""))
}
