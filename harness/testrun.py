#!/usr/bin/env python3
"""テスト実行 + test_run 自動記録ラッパー(HC-003)。

testthat を実行し、実出力から passed/failed/errors を機械抽出して
looplog に test_run を append する。数値の手動転記を廃止するための道具。

使い方: python harness/testrun.py --loop loop_007 [--note "..."]
終了コード: テストが全 green なら 0、それ以外は 1。
"""
import argparse
import re
import subprocess
import sys
from pathlib import Path

RSCRIPT = r"C:\Users\Tetruro Sakata\AppData\Local\Programs\R\R-4.6.1\bin\Rscript.exe"
R_EXPR = (
    "suppressPackageStartupMessages(library(testthat));"
    'res <- test_dir("tests/testthat", reporter="silent", stop_on_failure=FALSE);'
    "df <- as.data.frame(res);"
    'cat(sprintf("COUNTS passed=%d failed=%d errors=%d\\n",'
    " sum(df$passed), sum(df$failed), sum(df$error)))"
)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--loop", required=True)
    ap.add_argument("--note", default=None)
    args = ap.parse_args()

    proc = subprocess.run([RSCRIPT, "-e", R_EXPR], capture_output=True, text=True)
    sys.stdout.write(proc.stdout[-2000:])
    sys.stderr.write(proc.stderr[-2000:])
    m = re.search(r"COUNTS passed=(\d+) failed=(\d+) errors=(\d+)", proc.stdout)
    if not m:
        print("testrun: counts を抽出できない(R が異常終了した可能性)", file=sys.stderr)
        return 1
    passed, failed, errors = map(int, m.groups())

    cmd = [
        sys.executable, str(Path(__file__).with_name("looplog.py")), "append",
        "--loop", args.loop, "--event", "test_run",
        "--data", "command=harness/testrun.py (testthat::test_dir)",
        f"passed={passed}", f"failed={failed}", f"errors={errors}",
    ]
    if args.note:
        cmd.append(f"note={args.note}")
    log = subprocess.run(cmd, capture_output=True, text=True)
    sys.stdout.write(log.stdout)
    sys.stderr.write(log.stderr)
    if log.returncode != 0:
        return 1
    print(f"testrun: passed={passed} failed={failed} errors={errors}")
    return 0 if (failed == 0 and errors == 0) else 1


if __name__ == "__main__":
    sys.exit(main())
