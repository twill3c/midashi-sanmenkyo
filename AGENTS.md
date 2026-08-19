<!-- scaffold:block agents_core v1.8.0 -->
## 共通規律(scaffold 管理領域 — 手動編集禁止)

このセクションはスキャフォールド・レジストリが管理する。内容を変更したい場合は、
このファイルを直接編集せず、失敗ログ → HARNESS_CHANGELOG 起票 → レジストリ改訂 → `scaffoldctl update` の経路で行うこと。

### 7 段階ループプロトコル

| 段階 | 名称 | 完了条件 |
|---|---|---|
| 1 | 計画 | 対象の要求 ID を特定し、`loop_start` を記録した |
| 2 | 文脈読込 | SPEC.md / IMPLEMENTATION_GUIDE.md の該当箇所と、直近ループのログを読んだ |
| 3 | テスト先行 | TEST_SPEC.md にトレースする失敗するテストを書き、赤を確認した |
| 4 | 実装 | ファイル編集 2 回ごとにテストを実行し、赤のまま次の編集に進んでいない |
| 5 | 検証 | 全テスト合格 + 独立再計算(該当時)を確認した |
| 6 | 文書同期 | SPEC/docs と実装の乖離(SPEC-DRIFT)を解消し、生成ドキュメントを再生成した |
| 7 | 完了 | `loop_end` を記録し、ループログ validate に合格し、専用コミットを積んだ |

### ループ可観測性

全ループは loop-observability の規律(LOOP_LOG_SPEC / FAILURE_TAXONOMY)に従い
`logs/loops/{loop_id}.jsonl` に記録する。失敗は気づいた瞬間に分類コード付きで記録する。
ツーストライク(LL-10)と S1 即時起票(LL-12)は本プロジェクトでも有効である。

### エスカレーション規範

以下の場合は作業を止め、`escalation` を記録してから人間に確認する:
仕様の複数解釈(SPEC-AMB 相当)/ スコープ外ファイルへの変更が必要になった /
破壊的操作(履歴改変・データ削除・強制 push)/ 同種の修正の 3 回目の失敗(PROC-LOOP)。

### コミット規約

Conventional Commits(feat/fix/test/docs/refactor/chore)。スキャフォールド更新は
`chore: scaffold vX.Y.Z` の専用コミットで行い、機能変更と混ぜない。
<!-- /scaffold:block agents_core -->

# AGENTS.md — midashi-sanmenkyo

見出しの三面鏡。多社ニュース RSS を毎時観測し、同一事象の見出しをクラスタリングして
多社並置+社別語彙統計を静的公開する。仕様は SPEC.md、テストは TEST_SPEC.md。

## 1. 技術構成

- R 4.6.1(`%LOCALAPPDATA%\Programs\R\R-4.6.1`、PATH 未登録 — Rscript.exe をフルパスで呼ぶ)
- xml2 / dplyr / readr / ggplot2 / glue / svglite / digest / tibble / testthat
- 形態素解析エンジンは使わない(文字バイグラム+決定的規則)。サイトは glue テンプレート直生成
- 自動更新: GitHub Actions cron → out/ コミット → Vercel Git 連携(hodo-hangenki 方式)

## 2. looplog 運用の注意

- テスト実行と `test_run` 記録は **`python harness/testrun.py --loop <loop_id>` 経由を必須**とする
- loop_end の failure_count は `grep -c '"event": "failure"'` で数える(記憶で書かない)
- enum の許容値は `schema/taxonomy.json` と looplog.py の ENUMS が正

## 3. 品質ゲート(完了条件)

testthat 全 green(SPEC §4 の G-01〜G-06)。ゲート緩和(類似度閾値・precision 基準の変更を
含む)は再較正の証拠なしに行わない。手ラベルペア集合の変更は専用コミット + 理由記録。

## 4. アーキテクチャ規約

- `R/` は**純関数のみ**(ネットワーク・ファイル IO・時刻・乱数の直接呼び出し禁止)
- 時刻は R/timeutil.R の utc_minute() 系を hodo-hangenki からコピーして使う
  (as.POSIXct(trunc(Sys.time()),tz="UTC") は JST を UTC 再解釈する — hodo で実証済みの罠)
- スナップショットは不変・台帳 append-only。**.gitattributes の EOL 保護を初日から入れる**
  (autocrlf が CI 生成 CSV を CRLF 化して SHA256 台帳を壊す — hodo loop_006 で実証)
- 照合・パースのテストは特殊値の挙動表を作ってから書く(hodo HC-001)
- ネイティブ経路のスモーク必須・`Rscript … | tail` のパイプ包み禁止(toukei HC-002)
- 感情辞書は固定コピー(kokoro-graph の変更に引きずられない)。出典と取得日をファイル頭に記す
- 実フィードへのアクセスはテストから行わない(保存フィクスチャのみ)
- 見出しの表示は必ず配信元へのリンク付き HTML(SVG に見出し文字列を埋めない — リンク義務)

## 5. 変更禁止領域

- `data/snapshots/` と `data/ledger.csv` の既存行
- `tests/testthat/fixtures/labeled_pairs.csv`(手ラベル較正資産 — 変更は専用コミット + 理由)
- 回帰フィクスチャ SVG・scaffold:block 管理領域

## 6. デプロイ

- Vercel Git 連携 + vercel.json(buildCommand null / outputDirectory out)。予定 URL
  https://midashi-sanmenkyo.vercel.app。初回デプロイ後に app-menu 登録(死にリンク事前公開なし)
- ローカル作業後の push は bot コミットとの rebase を挟む(毎時コミットと競合するため)
