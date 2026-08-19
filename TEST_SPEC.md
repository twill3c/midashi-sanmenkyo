# TEST_SPEC.md — midashi-sanmenkyo

<!-- scaffold template v1.8.0 から展開(2026-08-19) -->

## 実行規約

- `pytest -x -q` を stage 3–5 の判定に使用。マーカー: `unit` / `integration` / `validation`
- フィクスチャ更新は専用コミット(`test: update fixtures`)で行い、理由をループログに記す
- 解析解を期待する合成フィクスチャは、期待値の導出前提(直交性・一意性・単一帰属等)を
  **テスト内の assert で検算**し、導出過程をコメントに残す。前提を検算しない期待値は
  正しい実装を落とす(VERIF-FALSE / HC-004)

## ケース一覧

| ID | 対応要求 | ケース | 期待 |
|---|---|---|---|
| T-001 | F-01 | | |
