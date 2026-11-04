#!/usr/bin/env bash
# B0001 全局編譯測試（回合末必跑）。
# 依工程約束：不做白箱／黑箱／冒煙測試，不做 --release 編譯，不做基準測試。
set -uo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MOON="${MOON:-/tmp/moon/bin/moon}"
FAILED=0

step() { printf '\n=== %s ===\n' "$1"; }
check() { if [[ $1 -ne 0 ]]; then echo "   ✗ FAIL: $2"; FAILED=1; else echo "   ✓ OK: $2"; fi }

if [[ ! -x "$MOON" ]]; then
  echo "找不到 moon：$MOON（先跑 bash ci/bootstrap_toolchain.sh）"; exit 2
fi
export PATH="$(dirname "$MOON"):$PATH"
echo "工具鏈：$("$MOON" version)"

step "1/8 moon check --target all"
( cd "$ROOT/galois" && "$MOON" check --target all ); check $? "全目標型別檢查"

step "2/8 moon build"
( cd "$ROOT/galois" && "$MOON" build ); check $? "建置 executable"

step "3/8 moon fmt --check"
( cd "$ROOT/galois" && "$MOON" fmt --check ); check $? "格式一致"

step "4/8 樣本上下文 A6 檢核（13 條 × 3 份）"
out="$( cd "$ROOT/galois" && "$MOON" run cmd/main 2>&1 )"
echo "$out" | grep -E '上下文：|檢核（A6）|\|ℭ_A\|'
pass_lines=$(echo "$out" | grep -c '^  \[PASS\]')
fail_lines=$(echo "$out" | grep -c '^  \[FAIL\]')
echo "   PASS=$pass_lines FAIL=$fail_lines（預期 39 / 0）"
[[ "$pass_lines" -eq 39 && "$fail_lines" -eq 0 ]]; check $? "A6 全數通過"

if echo "$out" | grep -qE '\|ℭ_A\|=([0-9]+)，\|ℭ_S\|=\1'; then
  echo "   ✓ P5：三份樣本皆 |ℭ_A| = |ℭ_S|"
else
  echo "   ✗ P5：|ℭ_A| 與 |ℭ_S| 不一致"; FAILED=1
fi

step "5/8 B0002 擬陣樣本（A12 八條 × 4 份）與期望值核對"
m_all="$( cd "$ROOT/galois"; for mn in U24 'M(K3)' 'M(K4)' Fano; do "$MOON" run cmd/main -- matroid "$mn"; done 2>&1 )"
echo "$m_all" | grep -E '擬陣：|期望值核對|擬陣檢核（A12）'
m_pass=$(echo "$m_all" | grep -c '^  \[PASS\]')
m_fail=$(echo "$m_all" | grep -c '^  \[FAIL\]')
m_exp_missing=$(echo "$m_all" | grep -c '✗')
echo "   PASS=$m_pass FAIL=$m_fail 期望值不符=$m_exp_missing（預期 32 / 0 / 0）"
if [[ "$m_pass" -eq 32 && "$m_fail" -eq 0 && "$m_exp_missing" -eq 0 ]]; then
  echo "   ✓ B0002 擬陣檢核全數通過且期望值相符"
else
  echo "   ✗ B0002 擬陣檢核異常"; FAILED=1
fi

step "6/8 負控制：區間凸包必須 FAIL 交換公理（T8：檢核器不得恆真）"
neg="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- negctl 2>&1 )"
echo "$neg" | grep -E '負控制|check_exchange 結果|\[FAIL\]'
if echo "$neg" | grep -q 'FAIL（正確：非擬陣）' && echo "$neg" | grep -q '^  \[FAIL\] X5'; then
  echo "   ✓ 負控制如預期失敗（檢核器有效）"
else
  echo "   ✗ 負控制未失敗：檢核器可能失效"; FAILED=1
fi

step "7/8 B0002 繼承：K_ℱ* 上跑 B0001 的 A6（M(K3) 13/13）"
inh="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- mcheck 'M(K3)' 2>&1 )"
echo "$inh" | grep -E '繼承檢核'
if echo "$inh" | grep -q 'B0001 繼承檢核（K_ℱ 上的 A6）：13/13 通過'; then
  echo "   ✓ 提升／嵌入的可執行見證通過"
else
  echo "   ✗ B0001 繼承檢核未全通"; FAILED=1
fi

step "8/8 algorithm.xlsx 可重建且與提交版本一致"
tmp_xlsx="$(mktemp -d)"
( cd "$ROOT" && cp tools/make_registry.py "$tmp_xlsx/" && cd "$tmp_xlsx" && python3 make_registry.py >/dev/null ) \
  && python3 - "$ROOT/algorithm.xlsx" "$tmp_xlsx/algorithm.xlsx" <<'PY'
import sys
from openpyxl import load_workbook
a, b = (load_workbook(p) for p in sys.argv[1:3])
sa, sb = [s.title for s in a.worksheets], [s.title for s in b.worksheets]
if sa != sb:
    print("   工作表不同：", sa, sb); raise SystemExit(1)
for name in sa:
    ra = [[c.value for c in row] for row in a[name].iter_rows()]
    rb = [[c.value for c in row] for row in b[name].iter_rows()]
    if ra != rb:
        print(f"   工作表內容不同：{name}"); raise SystemExit(1)
print("   ✓ 登記表與產生器一致（%d 個工作表）" % len(sa))
PY
check $? "登記表一致性"
rm -rf "$tmp_xlsx"

printf '\n================ 結果 ================\n'
if [[ $FAILED -eq 0 ]]; then echo "CI 全部通過"; else echo "CI 失敗"; fi
exit $FAILED
