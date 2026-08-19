# 直近ウィンドウ(既定 48h)の見出しをクラスタリングし、data/processed/ に書き出す。
#
# 契約(loop_002〜003 で実装、テスト T-001〜T-009 が先行):
#  - 正規化(R/normalize.R)→ 文字バイグラム化 → コサイン類似度(R/similarity.R)
#    → 閾値グラフの連結成分(R/cluster.R)。すべて純関数・辞書非依存
#  - 類似度閾値は G-04 較正(手ラベルペア集合)で固定した定数を R/params.R に置く
#  - 出力: data/processed/clusters.csv(cluster_id, outlet, guid, title, link, t)
#          + 三面鏡クラスタ(2 社以上)のフラグ
#  - 語彙指標(R/lexstats.R): 体言止め率・数字使用率・かぎ括弧率・感情語率・見出し長。
#    感情辞書は data/dict/kokoro_419.csv(kokoro-graph からの固定コピー、loop 時に取得)

stop("loop_002 以降で実装する(テスト先行)。SPEC §2/§3 F-02〜F-05 参照")
