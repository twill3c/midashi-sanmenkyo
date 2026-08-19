# 多社 RSS を取得して data/snapshots/ に 1 収集 = 1 CSV(不変)+ 台帳追記(F-01)。
#
# 契約(loop_001 で実装、テスト T-013/T-014 が先行):
#  - フィード定義は R/feeds.R(loop_001 で各社の実 URL・利用条件を検分して pin。
#    NHK は hodo-hangenki の 8 フィードのうち cat0 主要 を再利用、他社は総合/主要ニュース面)
#  - 列: outlet, guid, link, title, collected_at_utc(同一性は outlet × guid)
#  - 不変規約・SHA256 台帳・utc_minute() は hodo-hangenki と同一
#  - 1 社の取得失敗で全体を止めない(取れた社だけで書き、欠けは stderr に記録)

stop("loop_001 で実装する(テスト先行)。SPEC §3 F-01 参照")
