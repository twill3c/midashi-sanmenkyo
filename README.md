# midashi-sanmenkyo — 見出しの三面鏡

同じ出来事が、報道各社でどう違う見出しになるか。多社のニュース RSS を毎時観測し、
同一事象の見出しをクラスタリングして多社並置で見せる「三面鏡」。あわせて各社の
見出しの癖(体言止め率・数字使用率・感情語率・かぎ括弧率・見出し長)を統計化する。

- 仕様: [SPEC.md](SPEC.md) / オラクル設計: [TEST_SPEC.md](TEST_SPEC.md) / 開発規範: [AGENTS.md](AGENTS.md)

## 構成

```
R/          純関数(正規化・バイグラム類似度・クラスタリング・語彙指標・描画)
build/      01_collect(多社 RSS→不変スナップショット)→ 02_cluster → 03_render
data/       snapshots/(append-only)+ ledger.csv(SHA256 台帳)+ dict/(感情辞書の固定コピー)
tests/      手計算オラクル・数理不変量・手ラベル較正ゲート(labeled_pairs.csv)
out/        静的サイト(Actions がコミット、Vercel Git 連携が配信)
```

## オラクル

決定的計算(語彙指標・類似度)は手計算と厳密一致、クラスタリングは数理的不変量
(分割の網羅・非重複・決定論)+ **手ラベルペア集合への較正ゲート**(閾値・基準は
較正実験の実測でのみ固定)。台帳・SVG 決定論は hodo-hangenki と同一規約。

## 系譜

hodo-hangenki(観測インフラ)× kokoro-graph(感情辞書)× yamato-gaze(多者比較)の合流点。
