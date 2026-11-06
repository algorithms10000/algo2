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

step "1/20 moon check --target all"
( cd "$ROOT/galois" && "$MOON" check --target all ); check $? "全目標型別檢查"

step "2/20 moon build"
( cd "$ROOT/galois" && "$MOON" build ); check $? "建置 executable"

step "3/20 moon fmt --check"
( cd "$ROOT/galois" && "$MOON" fmt --check ); check $? "格式一致"

step "4/20 樣本上下文 A6 檢核（13 條 × 3 份）"
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

step "5/20 B0002 擬陣樣本（A12 八條 × 4 份）與期望值核對"
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

step "6/20 負控制：區間凸包必須 FAIL 交換公理（T8：檢核器不得恆真）"
neg="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- negctl 2>&1 )"
echo "$neg" | grep -E '負控制|check_exchange 結果|\[FAIL\]'
if echo "$neg" | grep -q 'FAIL（正確：非擬陣）' && echo "$neg" | grep -q '^  \[FAIL\] X5'; then
  echo "   ✓ 負控制如預期失敗（檢核器有效）"
else
  echo "   ✗ 負控制未失敗：檢核器可能失效"; FAILED=1
fi

step "7/20 B0002 繼承：K_ℱ* 上跑 B0001 的 A6（M(K3) 13/13）"
inh="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- mcheck 'M(K3)' 2>&1 )"
echo "$inh" | grep -E '繼承檢核'
if echo "$inh" | grep -q 'B0001 繼承檢核（K_ℱ 上的 A6）：13/13 通過'; then
  echo "   ✓ 提升／嵌入的可執行見證通過"
else
  echo "   ✗ B0001 繼承檢核未全通"; FAILED=1
fi

step "8/20 A3′ 增量式典範基（與暴力版同族 × 3 份、n=24 靠 E16 判定）"
dg_out="$( cd "$ROOT/galois"; for dn in divisors-12 divisors-180 divisors-240 divisors-420; do "$MOON" run cmd/main -- dg "$dn"; done 2>&1 )"
echo "$dg_out" | grep -E '上下文：|A3′ 走訪|\[PASS\]|\[FAIL\]' | sed 's/^/  /'
dg_pass=$(echo "$dg_out" | grep -c '\[PASS\]')
dg_fail_checked=$(echo "$dg_out" | grep '\[FAIL\]' | grep -vc '未檢核')
dg_unchecked=$(echo "$dg_out" | grep -c '未檢核')
echo "   PASS=$dg_pass 真失敗=$dg_fail_checked 未檢核=$dg_unchecked（預期 15 / 0 / 1）"
if [[ "$dg_pass" -eq 15 && "$dg_fail_checked" -eq 0 && "$dg_unchecked" -eq 1 ]]; then
  echo "   ✓ A3′ 全數通過；n>20 的暴力對照明示未檢核（不以綠燈冒充）"
else
  echo "   ✗ A3′ 檢核異常"; FAILED=1
fi

step "9/20 B0002 延伸：T9–T12 全域檢核、7 份樣本、n=4 普查"
ext_all="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- mextall 2>&1 )"
echo "$ext_all" | sed 's/^/  /'
ext_global_pass=$(echo "$ext_all" | grep -c '^  \[PASS\]')
ext_global_fail=$(echo "$ext_all" | grep -c '^  \[FAIL\]')
ext_samples="$( cd "$ROOT/galois"; for mn in U24 'M(K3)' 'M(K4)' Fano 'Fano*' 'U(3,5)' 'M(K4)*'; do "$MOON" run cmd/main -- mext "$mn"; done 2>&1 )"
ext_sample_pass=$(echo "$ext_samples" | grep -c '^  \[PASS\]')
ext_sample_fail=$(echo "$ext_samples" | grep -c '^  \[FAIL\]')
reg="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- mreg 2>&1 )"
reg_pass=$(echo "$reg" | grep -c '^  \[PASS\]')
cen="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- mcensus 4 2>&1 )"
echo "$cen" | sed 's/^/  /'
cen_ok=0
if echo "$cen" | grep -q '迴路系統路線（C1–C3）：68' \
  && echo "$cen" | grep -q '獨立集路線（I1–I3）：68' \
  && echo "$cen" | grep -q '同構類數：17' \
  && echo "$cen" | grep -q '非二元：1'; then
  cen_ok=1
fi
echo "   PASS=$ext_global_pass/$ext_sample_pass 真失敗=$((ext_global_fail + ext_sample_fail)) 登記核對=$reg_pass 普查=$cen_ok"
if [[ "$ext_global_pass" -eq 13 && "$ext_sample_pass" -eq 77 && "$reg_pass" -eq 7 && "$cen_ok" -eq 1 && $((ext_global_fail + ext_sample_fail)) -eq 0 ]]; then
  echo "   ✓ B0002 延伸全數通過（T9 兩路徑 0 分歧、T10 六條、T12 多項式與著色一致）"
else
  echo "   ✗ B0002 延伸檢核異常"; FAILED=1
fi

step "10/20 B0003 同餘子群（T13、T14）與樣本上下文 congruence-12"
mod_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- modular 2>&1 )"
echo "$mod_out" | sed 's/^/  /'
mod_pass=$(echo "$mod_out" | grep -c '^  \[PASS\]')
mod_fail=$(echo "$mod_out" | grep -c '^  \[FAIL\]')
gen_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- genus 2>&1 )"
echo "$gen_out" | tail -5 | sed 's/^/  /'
gen_ok=$(echo "$gen_out" | grep -c '✓古典')
con_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- congruence 2>&1 )"
echo "$con_out" | sed 's/^/  /'
echo "   PASS=$mod_pass 真失敗=$mod_fail 虧格相符=$gen_ok/24"
if [[ "$mod_pass" -eq 62 && "$mod_fail" -eq 0 && "$gen_ok" -eq 24 ]] \
  && echo "$con_out" | grep -q '|R|=47' \
  && echo "$con_out" | grep -q '|ℭ_S|=13' \
  && echo "$con_out" | grep -q 'B0001 A6 檢核：8/8 通過' \
  && echo "$con_out" | grep -q 'A3′ 檢核：4/4 通過'; then
  echo "   ✓ B0003 全數通過（T13 指數公式、T14 虧格表 24/24、樣本上下文 A6 8/8＋DG 4/4）"
else
  echo "   ✗ B0003 檢核異常"; FAILED=1
fi

step "11/20 B0004 撓群 E[n]（T15–T21）、Paley／Ramsey 與 paley-13 樣本"
ell_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- elliptic 2>&1 )"
echo "$ell_out" | head -3 | sed 's/^/  /'
ell_pass=$(echo "$ell_out" | grep -c '^  \[PASS\]')
ell_fail=$(echo "$ell_out" | grep -c '^  \[FAIL\]')
pal_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- paley 2>&1 )"
echo "$pal_out" | sed 's/^/  /'
ept_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- eptable 2>&1 )"
ept_bad=$(echo "$ept_out" | grep -c '✗')
pctx_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- paleyctx 2>&1 )"
echo "$pctx_out" | head -6 | sed 's/^/  /'
echo "   PASS=$ell_pass 真失敗=$ell_fail 對照表不符=$ept_bad"
if [[ "$ell_pass" -eq 69 && "$ell_fail" -eq 0 && "$ept_bad" -eq 0 ]] \
  && echo "$pal_out" | grep -q 'q=17：✓ .*R(4,4) > 17' \
  && echo "$pal_out" | grep -q 'q=13：✓ f0=13+f1=39+f2=26；β0=1+β1=2+β2=1' \
  && echo "$pctx_out" | grep -q 'B0001 A6 檢核：8/8 通過' \
  && echo "$pctx_out" | grep -q 'A3′ 檢核：4/4 通過' \
  && echo "$ept_out" | grep -q 'n=6.*#循環子群：12（Γ₀ 指數 12）'; then
  echo "   ✓ B0004 全數通過（T15 ψ_n 次數、T16 軌道=指數 n=2..12、T18/T19 Paley、T21 同調、paley-13 上下文）"
else
  echo "   ✗ B0004 檢核異常"; FAILED=1
fi

step "12/20 B0005 拓撲辮群 B_n（T22–T24）：置換商、Burau、B_3 → PSL₂(ℤ)"
br_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- braid 2>&1 )"
echo "$br_out" | head -3 | sed 's/^/  /'
br_pass=$(echo "$br_out" | grep -c '^  \[PASS\]')
br_fail=$(echo "$br_out" | grep -c '^  \[FAIL\]')
echo "   PASS=$br_pass 真失敗=$br_fail（預期 27 / 0）"
if [[ "$br_pass" -eq 27 && "$br_fail" -eq 0 ]] \
  && echo "$br_out" | grep -q '辮群 B_n 檢核（T22–T24）：27/27 通過' \
  && echo "$br_out" | grep -q 'T24 像生成 SL₂(ℤ/n)（n=12）'; then
  echo "   ✓ B0005 辮群全數通過（T22 n! 生成、T23 精確多項式關係與 det、T24 模群接縫 n=2..12）"
else
  echo "   ✗ B0005 辮群檢核異常"; FAILED=1
fi

step "13/20 B0005 圖雅可比簇 J(G)（T25–T31）：τ 三路徑、SNF、RR、Arf、超立方體"
jb_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- jacobian 2>&1 )"
echo "$jb_out" | head -3 | sed 's/^/  /'
jb_pass=$(echo "$jb_out" | grep -c '^  \[PASS\]')
jb_fail=$(echo "$jb_out" | grep -c '^  \[FAIL\]')
jt_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- jtable 2>&1 )"
jt_bad=$(echo "$jt_out" | grep -c '✗')
arf_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- arf 2>&1 )"
echo "$arf_out" | sed 's/^/  /'
echo "   PASS=$jb_pass 真失敗=$jb_fail 結構表不符=$jt_bad（預期 54 / 0 / 0）"
if [[ "$jb_pass" -eq 54 && "$jb_fail" -eq 0 && "$jt_bad" -eq 0 ]] \
  && echo "$jb_out" | grep -q '雅可比簇檢核（T25–T31）：54/54 通過' \
  && echo "$jt_out" | grep -q 'K₄.*不變因子 \[1,4,4\].*|J(G)|=16' \
  && echo "$jt_out" | grep -q '蝴蝶結.*不變因子 \[1,1,3,3\].*|J(G)|=9' \
  && echo "$arf_out" | grep -q 'g=3：Arf=0：36、Arf=1：28、無效細化：0'; then
  echo "   ✓ B0005 雅可比簇全數通過（|J|=τ 三路徑、外部 SNF、RR 0 反例、Arf 2^{g−1}(2^g±1)、Q_n）"
else
  echo "   ✗ B0005 雅可比簇檢核異常"; FAILED=1
fi

step "14/20 B0006 真 KK-理論片段（T32–T40）：UCT、六項正合列、指標—繞數"
kk_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- kk 2>&1 )"
echo "$kk_out" | head -3 | sed 's/^/  /'
kk_pass=$(echo "$kk_out" | grep -c '^  \[PASS\]')
kk_fail=$(echo "$kk_out" | grep -c '^  \[FAIL\]')
kt_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- kktable 2>&1 )"
ks_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- kksix 2>&1 )"
echo "$ks_out" | head -4 | sed 's/^/  /'
echo "   PASS=$kk_pass 真失敗=$kk_fail（預期 46 / 0）"
if [[ "$kk_pass" -eq 46 && "$kk_fail" -eq 0 ]] \
  && echo "$kk_out" | grep -q '真 KK-理論片段檢核（T32–T40）：46/46 通過' \
  && echo "$kk_out" | grep -q 'T34 K₀(O_8) = ℤ/7' \
  && echo "$kk_out" | grep -q 'T39 index(T_f) = −wind(f)（單項）' \
  && echo "$kk_out" | grep -q 'T40 B0001 邊界：含零商時 X2 必失敗（預期）' \
  && echo "$kt_out" | grep -q 'KK(C(S¹), C(S¹))：Hom = ℤ^2、Ext¹ = 0 ⇒ KK ≅ ℤ^2' \
  && echo "$kt_out" | grep -q 'KK(ℂ, O₃)：Hom = ℤ/2、Ext¹ = 0 ⇒ KK ≅ ℤ/2' \
  && echo "$ks_out" | grep -q '0 → K → 𝒯 → C(S¹) → 0：正合 ✓' \
  && echo "$ks_out" | grep -q 'K₀ = ℤ/5、K₁ = 0'; then
  echo "   ✓ B0006 全數通過（UCT 值表、六項正合列、Cuntz 三路徑、index = −wind、跨輪接縫）"
else
  echo "   ✗ B0006 檢核異常"; FAILED=1
fi

step "15/20 B0006 × B0001 公理層：理想格上下文（kk-ideal）"
kkc_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- kkctx 2>&1 )"
echo "$kkc_out" | head -6 | sed 's/^/  /'
if echo "$kkc_out" | grep -q '|A|=7、|S|=3、|R|=12、閉集數=8' \
  && echo "$kkc_out" | grep -q 'B0001 A6 檢核：8/8 通過' \
  && echo "$kkc_out" | grep -q 'A3′ 檢核：4/4 通過'; then
  echo "   ✓ 理想格（K-理論的 quotients）通過 B0001 全部公理檢核"
else
  echo "   ✗ kk-ideal 上下文檢核異常"; FAILED=1
fi

step "16/20 B0007 超立方體網絡群完整刻劃（T41–T47）：窮舉＝預測、方向映射、邊置換"
hy_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- hyper 2>&1 )"
echo "$hy_out" | head -3 | sed 's/^/  /'
hy_pass=$(echo "$hy_out" | grep -c '^  \[PASS\]')
hy_fail=$(echo "$hy_out" | grep -c '^  \[FAIL\]')
ht_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- hypertable 2>&1 )"
echo "$ht_out" | head -4 | sed 's/^/  /'
echo "   PASS=$hy_pass 真失敗=$hy_fail（預期 29 / 0）"
if [[ "$hy_pass" -eq 29 && "$hy_fail" -eq 0 ]] \
  && echo "$hy_out" | grep -q '超立方體網絡群檢核（T41–T47）：29/29 通過' \
  && echo "$hy_out" | grep -q 'T41 Q_4 的自同構 = 平移 ⋊ 座標置換' \
  && echo "$hy_out" | grep -q 'T41 負控制：非仿射雙射被排除' \
  && echo "$hy_out" | grep -q 'T43 Q_4 的方向映射' \
  && echo "$hy_out" | grep -q 'T45(b) n ≤ 2 的退化邊界' \
  && echo "$hy_out" | grep -q 'T47 Aut(Q_4) 的共軛類個數' \
  && echo "$ht_out" | grep -q 'n=4	|V|=16 |E|=32 |Aut|=384 (=2ⁿ·n!=384)' \
  && echo "$ht_out" | grep -q '階數分布：1^1 2^5 4^2' \
  && echo "$ht_out" | grep -q 'n=4：窮舉 384 個、預測 384 個、集合相等=true' \
  && echo "$ht_out" | grep -q '摺疊 Q_n → Q_{n−1}（T45）'; then
  echo "   ✓ B0007 超立方體群全數通過（完整刻劃、2ⁿ·n!、方向映射核、邊置換、摺疊、共軛類）"
else
  echo "   ✗ B0007 超立方體群檢核異常"; FAILED=1
fi

step "17/20 B0007 KK 界外部份（T48–T50）：清單合規、自由積、Künneth"
ko_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- kkout 2>&1 )"
echo "$ko_out" | head -3 | sed 's/^/  /'
ko_pass=$(echo "$ko_out" | grep -c '^  \[PASS\]')
ko_fail=$(echo "$ko_out" | grep -c '^  \[FAIL\]')
echo "   PASS=$ko_pass 真失敗=$ko_fail（預期 6 / 0）"
if [[ "$ko_pass" -eq 6 && "$ko_fail" -eq 0 ]] \
  && echo "$ko_out" | grep -q 'KK 界外部份檢核（T48–T50）：6/6 通過' \
  && echo "$ko_out" | grep -q 'T48 界外清單合規與 kind=0 的明示' \
  && echo "$ko_out" | grep -q 'T48 負控制：缺見證／判定詞錯誤的記錄不合規' \
  && echo "$ko_out" | grep -q 'T49 自由積：K₁ 可加（ℤ^4）、K₀ 不可加' \
  && echo "$ko_out" | grep -q 'T50 Künneth 的界內截面與界外標記' \
  && echo "$ko_out" | grep -q '\[O1\]\[界內截面\] 非 bootstrap 類的 KK' \
  && echo "$ko_out" | grep -q '\[O3\]\[界外\] min／max 張量範疇' \
  && echo "$ko_out" | grep -q '\[O6\]\[界內截面\] KK 的環結構'; then
  echo "   ✓ B0007 界外部分全數通過（A-K5 清單合規、kind=0 兩值、K₁ 可加／K₀ 不可加、Künneth）"
else
  echo "   ✗ B0007 界外部分檢核異常"; FAILED=1
fi

step "18/20 B0008 循環同調／內部張量積／漸新態射（T51–T63）"
cy_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- cyclic 2>&1 )"
echo "$cy_out" | head -3 | sed 's/^/  /'
cy_pass=$(echo "$cy_out" | grep -c '^  \[PASS\]')
cy_fail=$(echo "$cy_out" | grep -c '^  \[FAIL\]')
ct_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- cyctable 2>&1 )"
xp_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- xprod 2>&1 )"
echo "   PASS=$cy_pass 真失敗=$cy_fail（預期 59 / 0）"
if [[ "$cy_pass" -eq 59 && "$cy_fail" -eq 0 ]] \
  && echo "$cy_out" | grep -q '循環同調／內部張量積／漸新態射檢核（T51–T63）：59/59 通過' \
  && echo "$cy_out" | grep -q 'T54 ℂ\[S₃\] 的 HC（混複體 vs λ-複體，0..2）' \
  && echo "$cy_out" | grep -q 'T55 負控制：有符號 λ 的 HC 公式在 k 上失效' \
  && echo "$cy_out" | grep -q 'T56 ℂ\[D₈\] 是半單（5 個單模）的 HH/HC' \
  && echo "$cy_out" | grep -q 'T59 ℂ\[S₃\]：HH₀ = 共軛類、HH_n = 0' \
  && echo "$cy_out" | grep -q 'T61b 負控制：零作用模不是雙模，單位定理失效' \
  && echo "$cy_out" | grep -q 'T62d ASAssembly：正度數 HH_n = 0' \
  && echo "$cy_out" | grep -q 'T63 rank_q 與 rank_exact 交叉一致' \
  && echo "$ct_out" | grep -q 'ℂ\[D₈\]（dim 8）  n0:5/5  n1:0/0  n2:0/5' \
  && echo "$ct_out" | grep -q 'k\[x\]/(x^2)（dim 2）  n0:2/2  n1:1/0  n2:1/2' \
  && echo "$xp_out" | grep -q 'M_2(ℂ)：dim=4、A⊗_A A=4、無增廣、共端(Aᵉ)=1、HH₀=1、Hom(A,A)=1、Z(A)=1' \
  && echo "$xp_out" | grep -q '(ℂ\[ℤ/3\]) ⊗ (k\[x\]/(x^1))：dim=3、HH₀=3（預測 3）、HC₂=3（預測 3）'; then
  echo "   ✓ B0008 全數通過（兩條 HC 路徑、半單/Morita/加法性/群代數、內部張量積、漸新態射、秩交叉驗證）"
else
  echo "   ✗ B0008 循環同調檢核異常"; FAILED=1
fi

step "19/20 B0009 近似單位元／投影／同倫＋圓體與單位根（T64–T80）與 B0010 Baum–Connes（T81–T90）"
an_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- analytic 2>&1 )"
cy_out2="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- cyclo 2>&1 )"
bc_out="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- bc 2>&1 )"
an_table="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- anatable 2>&1 )"
cy_table="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- cyclotable 2>&1 )"
bc_table="$( cd "$ROOT/galois" && "$MOON" run cmd/main -- bctable 2>&1 )"
an_pass=$(echo "$an_out" | grep -c '^  \[PASS\]'); an_fail=$(echo "$an_out" | grep -c '^  \[FAIL\]')
cy2_pass=$(echo "$cy_out2" | grep -c '^  \[PASS\]'); cy2_fail=$(echo "$cy_out2" | grep -c '^  \[FAIL\]')
bc_pass=$(echo "$bc_out" | grep -c '^  \[PASS\]'); bc_fail=$(echo "$bc_out" | grep -c '^  \[FAIL\]')
echo "   analytic PASS=$an_pass 真失敗=$an_fail（預期 9 / 0）；cyclotomic PASS=$cy2_pass 真失敗=$cy2_fail（預期 8 / 0）；bc PASS=$bc_pass 真失敗=$bc_fail（預期 10 / 0）"
if [[ "$an_pass" -eq 9 && "$an_fail" -eq 0 && "$cy2_pass" -eq 8 && "$cy2_fail" -eq 0 && "$bc_pass" -eq 10 && "$bc_fail" -eq 0 ]] \
  && echo "$an_out" | grep -q '檢核（T64–T72）：9/9 通過' \
  && echo "$an_out" | grep -q 'T65 負控制：么代數上 {e_n} 不是近似單位元' \
  && echo "$an_out" | grep -q 'T68 非交換投影（主角度與交換子閉式）' \
  && echo "$an_out" | grep -q 'T71 負控制：A²=0 不可省、不同秩不同類' \
  && echo "$an_out" | grep -q 'T72 秩的兩套演算法' \
  && echo "$an_table" | grep -q 'n=4：‖e_nS − S‖₂² = 0、‖(1−e_n)P₂‖₂² = 0' \
  && echo "$an_table" | grep -q 'cos²θ = tr(pq) = 9/25' \
  && echo "$cy_out2" | grep -q '檢核（T73–T80）：8/8 通過' \
  && echo "$cy_out2" | grep -q 'T74 ℚ/ℤ' \
  && echo "$cy_out2" | grep -q 'T78 Tr(ζ^j) = Ramanujan 和' \
  && echo "$cy_out2" | grep -q 'T79 伽羅華對應：dim ℚ(ζ_n)^H = \[(ℤ/n)^× : H\]' \
  && echo "$cy_table" | grep -q 'n=12：\[1x^4 + -1x^2 + 1\]' \
  && echo "$cy_table" | grep -q 'n=5：(ℤ/5)^× 階 4、Tr(ζ) = -1、Tr(1) = 4' \
  && echo "$bc_out" | grep -q '檢核（T81–T90）：10/10 通過' \
  && echo "$bc_out" | grep -q 'T82 特徵正交性' \
  && echo "$bc_out" | grep -q 'T83 循環群 ℤ/n：μ 矩陣 = DFT' \
  && echo "$bc_out" | grep -q 'T86 ℂ\[ℤ\] 無非平凡冪等元' \
  && echo "$bc_out" | grep -q 'T89 全局公理伽羅華對應' \
  && echo "$bc_out" | grep -q 'T90 局部公理 8 條由代理裁決' \
  && echo "$bc_table" | grep -q 'Σdim²=|G|' \
  && echo "$bc_table" | grep -q 'A₄：ℤ\[ω\] 特徵表展開秩 8 = 2·4（只用 ℚ 後掉到 6）' \
  && echo "$bc_table" | grep -q 'BC4 SL_n(ℤ), n ≥ 3 的滿射性' \
  && echo "$bc_table" | grep -q 'BC5 粗 Baum–Connes'; then
  echo "   ✓ B0009／B0010 全數通過（近似單位元、投影、同倫、分圓與單位根、Baum–Connes 兩側對撞、界外清單）"
else
  echo "   ✗ B0009／B0010 檢核異常"; FAILED=1
fi

step "20/20 algorithm.xlsx 可重建且與提交版本一致"
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
