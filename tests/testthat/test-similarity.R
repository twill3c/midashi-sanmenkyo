# 正規化・類似度・クラスタリングの数理オラクル(T-001〜T-008 / G-02・G-03)。
suppressPackageStartupMessages(library(dplyr))
source("../../R/normalize.R", chdir = TRUE)
source("../../R/similarity.R", chdir = TRUE)
source("../../R/cluster.R", chdir = TRUE)

test_that("正規化: NFKC・小文字化・記号/空白除去(T-001/F-02)", {
  # 定義(SPEC F-02): NFKC 正規化 → ラテン文字小文字化 → 句読点・記号・空白(\p{P}\p{S}\p{Z})除去
  expect_equal(normalize_title("【速報】首相が表明 "), "速報首相が表明")
  expect_equal(normalize_title("GDP、3.5%増"), "gdp35増")     # 全角英数→半角+小文字
  expect_equal(normalize_title("A・B 会談「合意」"), "ab会談合意")
  expect_equal(normalize_title("ｶﾀｶﾅ"), "カタカナ")              # 半角カナ→全角(NFKC)
})

test_that("バイグラム分解の手計算例(T-002/G-02)", {
  expect_setequal(bigrams("首相が表明"), c("首相", "相が", "が表", "表明"))
  expect_equal(length(bigrams("あ")), 0)   # 1 文字はバイグラムなし
  expect_equal(bigrams(""), character(0))
})

test_that("コサイン類似度: 自己 1・直交 0(T-003/T-004/G-02)", {
  expect_equal(cosine_sim("首相が表明", "首相が表明"), 1)
  expect_equal(cosine_sim("首相が表明", "株価上昇"), 0)
})

test_that("コサイン類似度: 手計算ペアと厳密一致(T-005/G-02)", {
  # A=「首相が表明」→ {首相,相が,が表,表明}、B=「首相が謝罪」→ {首相,相が,が謝,謝罪}
  # 共有 2、|A|=4、|B|=4 → cos = 2 / (√4 × √4) = 0.5
  expect_equal(cosine_sim("首相が表明", "首相が謝罪"), 0.5)
  # A=「円安進行」→ {円安,安進,進行}、B=「円安加速」→ {円安,安加,加速}
  # 共有 1、|A|=3、|B|=3 → cos = 1/3
  expect_equal(cosine_sim("円安進行", "円安加速"), 1 / 3)
})

test_that("対称性 sim(a,b) = sim(b,a)(T-006/G-02)", {
  ttl <- c("首相が表明", "円安進行で株価下落", "台風が接近", "円安加速",
           "新型ロケット打ち上げ成功", "首相が謝罪", "打ち上げ延期", "gdp35増",
           "速報首相が表明", "会談合意")
  for (i in 1:9) for (j in (i + 1):10) {
    expect_equal(cosine_sim(ttl[i], ttl[j]), cosine_sim(ttl[j], ttl[i]),
                 info = paste(i, j))
  }
})

test_that("閾値クラスタ: 手作り 6 見出しの分割(T-007/G-03)", {
  d <- tibble::tibble(
    id = 1:6,
    title = c("首相が辞任を表明",      # クラスタ X
              "首相 辞任を表明",       # クラスタ X(空白ゆらぎ)
              "首相、辞任表明へ",      # クラスタ X
              "台風10号が九州接近",    # クラスタ Y
              "台風10号 九州に接近",   # クラスタ Y
              "プロ野球の結果")        # 単独
  )
  cl <- cluster_headlines(d$title, threshold = 0.5)
  expect_equal(length(cl), 6)
  expect_equal(cl[1], cl[2])
  expect_equal(cl[2], cl[3])
  expect_equal(cl[4], cl[5])
  expect_false(cl[1] == cl[4])
  expect_false(cl[6] %in% cl[c(1, 4)])
})

test_that("クラスタ分割の性質: 網羅・非重複・決定論(T-008/G-03)", {
  titles <- c("首相が辞任を表明", "台風10号が九州接近", "首相、辞任表明へ",
              "株価が急落", "台風10号 九州に接近", "株価急落 円高進む",
              "五輪代表が決定", "まったく無関係の見出し")
  c1 <- cluster_headlines(titles, threshold = 0.4)
  c2 <- cluster_headlines(titles, threshold = 0.4)
  expect_identical(c1, c2)                       # 決定論
  expect_equal(length(c1), length(titles))       # 網羅(全見出しに id)
  expect_false(any(is.na(c1)))
  # クラスタ id は 1..k の整数で、最初に現れる見出しの順に振られる(表示安定性)
  expect_equal(sort(unique(c1)), seq_along(unique(c1)))
  expect_equal(c1[1], 1)
})
