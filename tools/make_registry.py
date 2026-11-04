#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""B0001 登記表產生器：重建 algorithm.xlsx。

登記表是工程的「定理及演算法與等式」總帳。每次改動定理體系或程式碼後重跑本腳本，
確保 algorithm.xlsx 與 docs/B0001-定理體系.md、程式碼三者一致。

用法：python3 tools/make_registry.py
"""

from openpyxl import Workbook
from openpyxl.styles import Alignment, Border, Font, PatternFill, Side
from openpyxl.utils import get_column_letter

HEADER_FILL = PatternFill("solid", fgColor="1F3864")
HEADER_FONT = Font(color="FFFFFF", bold=True, size=11)
THIN = Side(style="thin", color="BFBFBF")
BORDER = Border(left=THIN, right=THIN, top=THIN, bottom=THIN)
WRAP = Alignment(wrap_text=True, vertical="top")


def style_sheet(ws, widths):
    for idx, w in enumerate(widths, start=1):
        ws.column_dimensions[get_column_letter(idx)].width = w
    for cell in ws[1]:
        cell.fill = HEADER_FILL
        cell.font = HEADER_FONT
        cell.alignment = Alignment(wrap_text=True, vertical="center")
    for row in ws.iter_rows(min_row=1):
        for cell in row:
            cell.border = BORDER
            if cell.row > 1:
                cell.alignment = WRAP
    ws.freeze_panes = "A2"


def add(ws, rows):
    for r in rows:
        ws.append(r)


wb = Workbook()

# ---------------------------------------------------------------- 公理與定義
ws = wb.active
ws.title = "公理與定義"
add(ws, [
    ["編號", "類型", "名稱", "陳述", "依賴", "實作位置", "狀態"],
    ["X0", "全局公理", "伽羅瓦對應（伴隨對）",
     "∀X⊆A,∀Y⊆S：X ⊆ Ψ(Y) ⟺ Y ⊆ Φ(X)。公理系統與陳述系統之間的伽羅瓦對應是全域結構原則。",
     "D1–D3", "galois.laws.check_adjunction", "已實作＋窮舉檢核"],
    ["X1", "局部公理 LA-1", "有限性與反單調性",
     "X⊆X′ ⟹ Φ(X′)⊆Φ(X)；Y⊆Y′ ⟹ Ψ(Y′)⊆Ψ(Y)；A、S 有限。",
     "D2,D3", "galois.laws.check_antitone", "已實作＋窮舉檢核"],
    ["X2", "局部公理 LA-2", "支撐完全性",
     "∀a∈A：row(a)≠∅；∀s∈S：col(s)≠∅。",
     "D1", "galois.laws.check_support", "已實作＋檢核"],
    ["X3", "局部公理 LA-3", "分離性",
     "∀a≠a′，∃s：(a,s)∈R ∧ (a′,s)∉R，等價於 row(a) ⊄ row(a′)。",
     "D1", "galois.check_separation / redundant_axioms", "已實作＋檢核"],
    ["X4", "局部公理 LA-4", "分量局部性",
     "Γ(K)=(A⊎S,R) 的每個連通分量決定子上下文 K_C；K 為分量的不交併，派生只沿分量傳播。",
     "D1", "context.components_of / galois.decompose", "已實作＋檢核"],
    ["D1", "定義", "形式上下文", "K=(A,S,R)，A 公理集（|A|=m）、S 陳述集（|S|=n）、R⊆A×S 派生關係。",
     "—", "context.FormalContext", "已實作"],
    ["D2", "定義", "內涵映射 Φ", "Φ(X)=⋂_{a∈X} row(a)，Φ(∅)=S。", "D1", "context.FormalContext::intent", "已實作"],
    ["D3", "定義", "外延映射 Ψ", "Ψ(Y)=⋂_{s∈Y} col(s)，Ψ(∅)=A。", "D1", "context.FormalContext::extent", "已實作"],
    ["D4", "定義", "兩側閉包算子", "cl_A=Ψ∘Φ、cl_S=Φ∘Ψ。", "D2,D3", "galois.closure_axioms / closure_stmts", "已實作"],
    ["D5", "定義", "閉集", "X 閉 ⟺ cl_A(X)=X；Y 閉 ⟺ cl_S(Y)=Y。", "D4", "galois.is_closed_axioms / is_closed_stmts", "已實作"],
    ["D6", "定義", "形式概念與概念格", "(X,Y) 滿足 Φ(X)=Y 且 Ψ(Y)=X；以 X⊆X′ 排序得 B(K)。", "D2,D3", "lattice.Concept / all_concepts", "已實作"],
    ["D7", "定義", "蘊含與完備公理基", "P→Q：所有閉集 Y，P⊆Y ⟹ Q⊆Y；Σ 完備 ⟺ 對 Σ 封閉 ⟺ 閉。",
     "D5", "lattice.Implication / check_basis_completeness", "已實作＋檢核"],
    ["D8", "定義", "偽內涵", "P≠cl_S(P) 且 ∀偽內涵 Q⊊P：cl_S(Q)⊆P。", "D5", "lattice.pseudo_intents", "已實作"],
])

# ---------------------------------------------------------------- 命題引理定理
ws = wb.create_sheet("命題引理定理")
add(ws, [
    ["編號", "類型", "名稱", "陳述（摘要）", "證明要點", "實作／檢核", "狀態"],
    ["P1", "命題", "反單調性", "X⊆X′ ⟹ Φ(X′)⊆Φ(X)；Y⊆Y′ ⟹ Ψ(Y′)⊆Ψ(Y)。",
     "較大族之交 ⊆ 較小族之交；Φ(∅)=S 為端點相容。", "galois.laws.check_antitone", "已證＋窮舉檢核"],
    ["P2", "命題", "閉包三性", "cl_A、cl_S 皆擴張、單調、冪等。",
     "擴張=C1；單調=P1 兩次；冪等=L3。", "galois.laws.check_closure_laws", "已證＋窮舉檢核"],
    ["P3", "命題", "Moore 族與完備格", "兩側閉集族對任意交封閉且含最大元，故各為完備格。",
     "夾逼：⋂X_i ⊆ cl(⋂X_i) ⊆ ⋂cl(X_i) = ⋂X_i。", "galois.laws.check_moore", "已證＋窮舉檢核"],
    ["P4", "命題", "反序格同構", "Φ|ℭ_A 與 Ψ|ℭ_S 互為反序逆映射，ℭ_A ≅ (ℭ_S)^op。",
     "L3 ⟹ Φ(X)∈ℭ_S 且 ΨΦ(X)=X；反單調由 P1。", "galois.laws.check_duality", "已證＋窮舉檢核"],
    ["P5", "命題", "計數相等", "|ℭ_A| = |ℭ_S| = |B(K)|。", "P4 的計數推論（雙射）。",
     "lattice.closed_stmt_count vs galois.all_closed_bruteforce", "已證＋交叉檢核"],
    ["P6", "命題", "偽內涵列舉正確性", "若所有基數小於 |P| 的子集已判定，則 P 為偽內涵 ⟺ D8 的兩條件成立。",
     "真子集基數必小，故已判定；代入 D8 即得。", "lattice.pseudo_intents", "已證＋隨機對照"],
    ["P7", "命題（註記）", "與擬陣／Horn 的關係",
     "在 P2 上追加交換公理即得擬陣閉集族；本框架為擬陣、Moore 族、Horn 蘊含系統、FCA 概念格的共同下界。",
     "交換公理未在 B0001 實作。", "—（B0002+）", "登記待辦"],
    ["L1", "引理", "伴隨律", "X⊆Ψ(Y) ⟺ Y⊆Φ(X)。",
     "量詞互換：(a,s)∈R 的雙重全稱可換序。", "galois.laws.check_adjunction", "已證＋窮舉檢核"],
    ["L2", "引理", "複合單調性", "Φ∘Ψ、Ψ∘Φ 皆單調。", "P1 兩次。", "（P2 的一部分）", "已證"],
    ["L3", "引理", "三角恆等", "ΦΨΦ=Φ，ΨΦΨ=Ψ。",
     "由 L1 得 X⊆ΨΦ(X)，套 P1 得 ΦΨΦ(X)⊆Φ(X)；反向由 L1 取 X:=Φ(X)。", "galois.laws.check_closure_laws", "已證＋檢核"],
    ["L4", "引理", "單次雙閉包即定點", "cl_A∘cl_A = cl_A。",
     "ΨΦΨΦ=Ψ(ΦΨΦ)=ΨΦ。", "galois.closure_axioms vs closure_axioms_iterated", "已證＋雙路徑對照"],
    ["C1", "推論", "擴張性", "X⊆cl_A(X)，Y⊆cl_S(Y)。", "L1 取 Y:=Φ(X)。", "check_closure_laws", "已證＋檢核"],
    ["T1", "定理", "全局公理伽羅瓦對應（GAGC）",
     "(1) (Φ,Ψ) 為反單調伴隨對；(2) 兩側閉包算子單次即定點；(3) 閉集族為 Moore 族、完備格；(4) ℭ_A ≅ (ℭ_S)^op 且三種計數相等。",
     "X0 + P2 + L3 + P3 + P4。", "galois.structural_report（8 條檢核）", "已證＋13 條檢核"],
    ["T2", "定理", "重建定理（冗餘判準）",
     "X3 ⟺ 所有 cl_A({a})={a} ⟺ row(a) 互不包含（且單射）。",
     "cl_A({a})={a′ | row(a)⊆row(a′)}，故等價於無包含關係。", "galois.redundant_axioms / check_separation", "已證＋檢核"],
    ["T3", "定理", "局部性定理（分量分解）",
     "X2 下：(1) X 觸及 ≥2 分量 ⟹ Φ(X)=∅ ⟹ cl_A(X)=A；(2) X⊆A_i 且 Φ(X)≠∅ ⟹ cl_A(X)=cl_{A_i}(X)⊆A_i；(3) X⊆A_i 且 Φ(X)=∅ ⟹ cl=A；(4) 真閉集必在單一分量內。",
     "不同分量之 row 為非空不交集，交為 ∅；跨分量 a 不可能包含 Φ(X)。",
     "galois.local_closure / check_locality", "已證＋窮舉檢核"],
    ["T4", "定理", "Duquenne–Guiguès 典範基", "Σ={P→cl_S(P) | P 偽內涵} 為完備且非冗餘的蘊含基。",
     "健全：閉集對 Σ 封閉；完備：取基數極小偽內涵；非冗餘：刪任一條即失效（Duquenne–Guiguès 1986）。",
     "lattice.canonical_basis / 3 條檢核", "已證＋3 條檢核"],
])

# ---------------------------------------------------------------- 演算法
ws = wb.create_sheet("演算法")
add(ws, [
    ["編號", "名稱", "依據定理", "輸入 → 輸出", "時間複雜度", "空間", "實作位置", "狀態"],
    ["A1", "galois_biclosure（雙閉包）", "T1(2)、L4",
     "(K, X⊆A) → cl_A(X)；(K, Y⊆S) → cl_S(Y)",
     "O(|X|·⌈n/64⌉ + |Φ(X)|·⌈m/64⌉)", "O(m+n) 位元",
     "galois.closure_axioms / closure_stmts", "已實作"],
    ["A2", "next_closure（NextClosure 枚舉）", "T1(3)、P2",
     "K → 全部閉集（lectic 序，多項式延遲）",
     "延遲 O(n·(⌈m/64⌉+⌈n/64⌉))；總量 O(|ℭ|·n·closure)", "O(|ℭ|·n)",
     "lattice.next_closed_stmts / all_closed_stmts", "已實作＋完整性檢核"],
    ["A3", "canonical_basis（DG 典範基）", "P6、T4",
     "K → 偽內涵與其閉包（Σ）", "O(2^n·n·|Σ|)（輸出可指數）", "O(|Σ|·n)",
     "lattice.pseudo_intents / canonical_basis", "已實作＋3 條檢核"],
    ["A4", "components + local_closure（分量閉包）", "X4、T3",
     "K → {K_C}；(K,X) → cl 且標記坍縮", "DSU O((m+n+|R|)·α)；局部閉包 O(|X∩A_i|·⌈n_i/64⌉)",
     "O(m+n)", "context.components_of / galois.decompose, local_closure", "已實作＋窮舉檢核"],
    ["A5", "concept_lattice + covers（概念格）", "T1(4)、P4",
     "K → 概念清單、|B(K)|、Hasse 覆蓋邊", "O(|ℭ|·n·closure + |ℭ|·n²)", "O(|ℭ|·n)",
     "lattice.all_concepts / upper_covers_stmts / hasse_edge_count", "已實作＋2 條檢核"],
    ["A6", "verify_*（反例搜尋檢核器）", "X0、L1、P1–P5、T2、T3、T4",
     "K → 檢核報告（PASS/FAIL＋反例）", "窮舉上限內 O(2^m·2^n·(m+n)/64)", "O(m+n)",
     "galois.laws / lattice.basis, next_closure", "已實作（39 條檢核）"],
    ["A7", "parse/dump（文字格式互轉）", "D1",
     "文字 ⇄ K", "O(行數×token 數 + |R|)", "O(m+n+|R|)",
     "context.parse_context / cmd.dump_text", "已實作（往返一致）"],
])

# ---------------------------------------------------------------- 等式
ws = wb.create_sheet("等式")
add(ws, [
    ["編號", "等式", "名稱", "來源", "程式對應"],
    ["E1", "Φ(X) = ⋂_{a∈X} row(a)，Φ(∅)=S", "內涵定義式", "D2", "FormalContext::intent"],
    ["E2", "Ψ(Y) = ⋂_{s∈Y} col(s)，Ψ(∅)=A", "外延定義式", "D3", "FormalContext::extent"],
    ["E3", "cl_A = Ψ∘Φ，cl_S = Φ∘Ψ", "閉包複合式", "D4", "closure_axioms / closure_stmts"],
    ["E4", "X ⊆ Ψ(Y) ⟺ Y ⊆ Φ(X)", "伴隨律", "X0／L1", "check_adjunction"],
    ["E5", "ΦΨΦ = Φ，ΨΦΨ = Ψ", "三角恆等", "L3", "check_closure_laws"],
    ["E6", "cl_A∘cl_A = cl_A，cl_S∘cl_S = cl_S", "冪等", "L4", "closure_axioms vs closure_axioms_iterated"],
    ["E7", "ℭ_A ≅ (ℭ_S)^op，|ℭ_A| = |ℭ_S| = |B(K)|", "反序格同構／計數", "P4、P5", "check_duality / closed_stmt_count"],
    ["E8", "cl_A({a}) = {a′ | row(a) ⊆ row(a′)}", "單點閉包", "T2", "singleton_closure"],
    ["E9", "P∈PI ⟺ P≠cl_S(P) ∧ ∀Q∈PI, Q⊊P ⟹ cl_S(Q)⊆P", "偽內涵判準", "D8／P6", "pseudo_intents"],
    ["E10", "cl_A(X) = A ⟺ Φ(X) = ∅（X2 下）", "坍縮判準", "T3(1)(3)", "local_closure.collapsed"],
    ["E11", "A = ⊎A_i，S = ⊎S_i，R = ⊎R_i", "分量分解", "X4", "components_of / decompose"],
    ["E12", "Σ = {P → cl_S(P) | P∈PI} 完備且非冗餘", "典範基", "T4", "canonical_basis + 3 檢核"],
    ["E13", "covers(Y) = min{cl_S(Y∪{s}) | s∉Y}", "上覆蓋式（對偶的 cl_S(Y∖{s}) 取極大者不成立，反例見開發期缺陷 BUG-2）", "A5", "upper_covers_stmts"],
])

# ---------------------------------------------------------------- 樣本上下文
ws = wb.create_sheet("樣本上下文")
add(ws, [
    ["名稱", "數學物件", "|A|", "|S|", "|R|", "分量", "|ℭ_A|", "|ℭ_S|", "|B(K)|", "Hasse 邊", "|Σ|", "檢核"],
    ["cyclotomic-q8", "ℚ(ζ₈)/ℚ，伽羅瓦群 C₂×C₂（子群 ↔ 中間體）", 5, 5, 12, 1, 5, 5, 5, 6, 5, "13/13 PASS"],
    ["divisibility", "ℤ 的整除格（公倍數 ↔ 公因數）", 4, 4, 12, 1, 4, 4, 4, 4, 3, "13/13 PASS"],
    ["two-blocks", "兩個不交分量的合成上下文（T3 坍縮）", 4, 6, 8, 2, 8, 8, 8, 10, 7, "13/13 PASS"],
])

# ---------------------------------------------------------------- 名詞對應
ws = wb.create_sheet("工程內容2名詞對應")
add(ws, [
    ["名詞（工程內容2）", "B0001 的處理", "狀態", "後續登記"],
    ["全局公理伽羅瓦對應", "X0 + T1（主體）", "已實作", "—"],
    ["圓體擴張伽羅瓦群、圓周群的所有單位根群", "樣本 K_cyclotomic：ℚ(ζ₈)/ℚ，由單位根群基底 {1,i,√2,i√2} 精確計算", "已實作（實例）", "—"],
    ["擬陣、Moore 族、閉包系統", "P7：本框架為共同下界；未加交換公理", "註記", "B0002"],
    ["主同餘子群 Γ(n)、Γ₀(n)、Γ₁(n)、射影模群 PSL₂(ℤ)", "未涉（需模形式／離散群資料）", "待辦", "B0002+"],
    ["真 KK-理論、內部張量積、循環同調、漸新態射", "未涉（C*-代數範疇論）", "待辦", "B0003+"],
    ["橢圓曲線 n 等分點群、雅可比簇群分", "未涉（可作扭子群伽羅瓦模樣本）", "待辦", "B0004+"],
    ["拓撲辮群、超立方體網絡群、正則圖邊置換群", "未涉（置換群樣本上下文）", "待辦", "B0005+"],
    ["近似單位元、投射與非交換投影、自由同倫不變性", "未涉（閉單點與投影冪等性僅形式類比，不宣稱同構）", "待辦", "B0006+"],
])

# ---------------------------------------------------------------- 缺陷記錄
ws = wb.create_sheet("開發期缺陷")
add(ws, [
    ["編號", "發現方式", "缺陷", "修正", "教訓"],
    ["BUG-1", "A6 常設檢核（check_nextclosure 的前身，開發期比對窮舉）",
     "NextClosure 後繼只取 cl(A∪{i}) 而不丟棄索引 ≥ i 的元素，導致漏枚舉閉集（cyclotomic 只得 3 個，應為 5）。",
     "改為 Ganter 的 A^{×i} = (A∩{0..i−1})∪{i} 再閉包；並把「枚舉 vs 窮舉」升格為常設檢核 A6。",
     "枚舉型演算法必須與獨立窮舉對照，且對照要留在交付物中。"],
    ["DOC-1", "期望值核對（B0002 樣本摘要）",
     "文件把 Fano 擬陣的迴路數寫成 7（只算 7 條線）。實際為 14：7 條線 + 7 個線補集（4 元極小相依集）。",
     "更正 docs/B0002 §6 E-B9 並於樣本表加註理由；程式未改（程式原本就對）。",
     "「文件數字」也必須由程式核對：期望值寫進程式才不會漂移。"],
    ["AXIOM-1", "隨機 GF(2) 擬陣檢核（含零列）",
     "B0002 的 X6 把 R4 誤寫為 r({e}) = 1，遇到含環（loop）的擬陣即失敗。",
     "改為標準形式：r(∅) = 0 且單位增量 r(X) ≤ r(X∪e) ≤ r(X)+1。",
     "公理必須對「退化情形」（環、平行元素）也成立；隨機資料是最好的公理壓力測試。"],
    ["FIX-1", "隨機 GF(2) 擬陣的幾何格檢核",
     "幾何格檢核要求每個非空平坦集都有下覆蓋；對有環擬陣誤判（回報「平坦集 {0} 無下覆蓋」）。",
     "認清平坦格底元是 cl(∅)（環集）：底元豁免下覆蓋要求；T6 敘述同步修正。",
     "定理的「邊界元素」要先算清楚（底元、頂元），否則檢核會誤報。"],
    ["NOTE-1", "B0001 繼承檢核的 X2 FAIL",
     "K_ℱ 因包含空平坦集 ∅，陳述 ∅ 無見證，必然違反 B0001 X2。",
     "不是缺陷：新增 ℱ* = ℱ∖{∅} 變體（X2 成立、閉包等式仍成立），並把「K_ℱ 違反／K_ℱ* 滿足」升格為正面斷言 check_empty_flat_support。",
     "預期中的失敗要寫成斷言，不能留成沉默的紅燈。"],
    ["BUG-2", "A6 常設檢核（check_covers）",
     "下覆蓋誤用 cl(Y∖{s}) 取極大者：divisibility 上下文 Y={6,12,18} 的真閉子集 {12} 永遠取不到（∀s, cl(Y∖{s})=Y）。",
     "改用對偶的上覆蓋公式 min{cl(Y∪{s}) | s∉Y}，並在程式與文件中留下反例警告。",
     "對偶性不能靠「看起來對稱」套用；每一側都要獨立驗證。"],
])

# ---------------------------------------------------------------- 讀我
ws = wb.create_sheet("說明")
add(ws, [
    ["項目", "內容"],
    ["登記編號（本輪）", "B0002 交換閉包系統（擬陣）與 Moore 族的上下文實現（B0001 之後第二筆登記）"],
    ["登記編號（前置）", "B0001 全局公理伽羅瓦對應（Global Axiom–Galois Correspondence, GAGC）"],
    ["工程代號", "arena/b0001（MoonBit 模組）"],
    ["工具鏈", "moon 0.1.20261102（MoonBit 最新穩定版，2026-11-02 發佈）"],
    ["數學合約", "docs/B0001-定理體系.md（D1–D8、X0–X4、P1–P7、L1–L4、T1–T4、E1–E13）＋ docs/B0002-定理體系.md（D-B1–D-B7、X5–X7、P-B1–P-B4、T5–T8、E-B1–E-B10）"],
    ["程式入口", "galois/cmd/main（CLI）；套件：bitset、context、galois、lattice、matroid、registry"],
    ["檢核方式", "B0001 A6：三份上下文各 13 條（39/39 PASS）；B0002 A12：四份擬陣各 8 條（32/32 PASS）；負控制 interval-4 必須 FAIL；M(K3)/M(K4) 另跑 B0001 繼承 13/13"],
    ["產生方式", "python3 tools/make_registry.py（本檔案由腳本產生，請勿手改）"],
])

# ---------------------------------------------------------------- B0002 公理定義
ws = wb.create_sheet("B0002 公理定義")
add(ws, [
    ["編號", "類型", "名稱", "陳述", "依賴", "實作位置", "狀態"],
    ["D-B1", "定義", "迴路系統",
     "𝒞 ⊆ 2^E∖{∅}：(C1) 非空；(C2) 反鏈；(C3) 迴路消去（∀C₁≠C₂,∀e∈C₁∩C₂ ∃C₃⊆(C₁∪C₂)∖{e}）。",
     "—", "matroid.Matroid::from_circuits / check_circuit_axioms", "已實作＋檢核"],
    ["D-B2", "定義", "生成閉包 cl_𝒞",
     "最小超集使每個迴路 ⊆ X 或 |C∖X| ≥ 2；以迴路消去迭代求不動點。",
     "D-B1", "Matroid::closure", "已實作"],
    ["D-B3", "定義", "獨立集與秩",
     "I 獨立 ⟺ 不含迴路；r(X) = X 中最大獨立子集大小（擬陣貪心）。",
     "D-B1", "Matroid::independent / rank", "已實作"],
    ["D-B4", "定義", "平坦集", "F 平坦 ⟺ cl(F) = F。", "D-B2", "Matroid::is_flat / flats", "已實作"],
    ["D-B5", "定義", "幾何格", "原子生成 + 分級 + 半模（+ Jordan–Dedekind）。",
     "—", "Matroid::check_geometric", "已實作＋檢核"],
    ["D-B6", "定義", "Moore 族與實現上下文",
     "ℱ 對交封閉且 E∈ℱ；K_ℱ = (E, ℱ, ∈)，(e,F)∈R ⟺ e∈F。",
     "B0001 D1", "context_of_moore_family / moore_family_of_context", "已實作"],
    ["D-B7", "定義", "擬陣", "M = (E, 𝒞) 滿足 D-B1。", "D-B1", "matroid.Matroid", "已實作"],
    ["X5", "公理（擬陣）", "交換公理",
     "y,z ∉ cl(X)：y ∈ cl(X∪{z}) ⟹ z ∈ cl(X∪{y})。",
     "D-B2", "check_exchange（A14）", "已實作＋窮舉檢核"],
    ["X6", "公理（擬陣）", "秩公理 R1–R4",
     "(R1) r(∅)=0、0≤r(X)≤|X|；(R2) 單調；(R3) 次模；(R4) 單位增量 r(X) ≤ r(X∪e) ≤ r(X)+1。"
     "（注意：R4 不是 r({e})=1——擬陣允許環。）",
     "D-B3", "Matroid::check_rank_axioms", "已實作＋窮舉檢核（開發期曾誤寫，見缺陷 AXIOM-1）"],
    ["X7", "公理（有限性）", "有限性", "E 有限 ⇒ X5 可 O(2ⁿ·n²) 判定（T8）。",
     "B0001 X1", "check_exchange", "已實作"],
])

# ---------------------------------------------------------------- B0002 命題定理
ws = wb.create_sheet("B0002 命題定理")
add(ws, [
    ["編號", "類型", "名稱", "陳述（摘要）", "證明要點", "實作／檢核", "狀態"],
    ["P-B1", "命題", "閉包四性", "cl_𝒞 擴張、單調、冪等；cl(X)=X ⟺ X 平坦。",
     "承 B0001 P2；平坦為 D-B4 的定義式。", "check_rank_axioms（含 P-B2）", "已證＋檢核"],
    ["P-B2", "命題", "秩—閉包對偶", "r(cl(X))=r(X)，且 cl_r(X)={e: r(X∪e)=r(X)} 等於 cl_𝒞(X)。",
     "交換性使「由 X 生成」⟺「不增秩」。", "closure vs closure_by_rank 雙路徑", "已證＋雙路徑檢核"],
    ["P-B3", "命題", "極小相依 = 迴路", "X 相依 ⟺ ∃C∈𝒞, C⊆X。",
     "D-B1+D-B3 直譯。", "Matroid::check_independence", "已證＋窮舉檢核"],
    ["P-B4", "命題", "平坦族是 Moore 族", "ℱ(M) 對交封閉、含 cl(∅) 與 E。",
     "夾逼：cl(⋂F_i) ⊆ ⋂cl(F_i) = ⋂F_i ⊆ cl(⋂F_i)。", "T7 檢核（ℭ_A == ℱ）", "已證＋檢核"],
    ["T5", "定理", "三公理等價（Whitney 1935）",
     "閉包（X1+X5）／迴路系統（D-B1）／秩函數（X6）三者互相唯一決定且等價。",
     "標準結果；B0002 把三條路徑都實作並互比（GF(2)→迴路→閉包→秩→閉包）。",
     "A8+A9+A13 與 A12 報告", "已實作＋交叉檢核"],
    ["T6", "定理", "平坦格 = 幾何格（Birkhoff）",
     "ℱ(M) 在 ⊆ 下為幾何格；ρ(F)=r(F)；底元 = cl(∅)（有環時即環集），原子 = 秩 1 平坦集。",
     "⟹ 分級由單位增量、半模即 R3、原子生成由秩；⟸ 幾何格秩誘導秩函數。",
     "Matroid::check_geometric（四項）", "已實作＋四項檢核＋負控制"],
    ["T7", "定理", "Moore 實現／提升定理",
     "ℱ 為 Moore 族 ⇒ cl_A^{K_ℱ}(X)=⋂{F∈ℱ: X⊆F}=ℱ-閉包；故 ℱ=ℭ_A，B0001 T1 逐字適用；"
     "特別地每個擬陣的平坦族都可由某形式上下文實現。",
     "Φ(X)={F⊇X}、Ψ(Y)=⋂Y；再由 B0001 P3/T1。",
     "check_realization（ℱ 與 ℱ* 兩變體）＋check_b0001_inheritance", "已實作＋雙向＋13 條繼承檢核"],
    ["T8", "定理", "可判定性與負控制",
     "X5 可 O(2ⁿ n²) 判定；違反 X5 的閉包不可能由迴路系統表示；"
     "故 A14 必須在負控制（區間凸包）上 FAIL 才算有效。",
     "T5 的逆否 + 顯式反例 X={0},y=1,z=2。", "check_exchange / interval_report", "已實作＋CI 強制"],
])

# ---------------------------------------------------------------- B0002 演算法
ws = wb.create_sheet("B0002 演算法")
add(ws, [
    ["編號", "名稱", "依據", "輸入 → 輸出", "複雜度", "實作位置", "狀態"],
    ["A8", "closure（迴路消去）", "D-B2、P-B1", "(M, X) → cl(X)",
     "O(|𝒞|·n·|cl(X)|)（位元運算）", "matroid.Matroid::closure", "已實作"],
    ["A9", "rank / independent（貪心）", "D-B3、P-B2", "(M, X) → r(X)、獨立性",
     "O(n·|𝒞|·n)", "Matroid::rank / independent", "已實作"],
    ["A10", "flats + check_geometric", "T6", "M → 平坦族、幾何格四項檢核",
     "O(2ⁿ·closure + |ℱ|²·closure)", "Matroid::flats / check_geometric", "已實作"],
    ["A11", "context_of_moore_family / moore_family_of_context", "T7",
     "ℱ → K_ℱ；K → ℭ_A（互逆）", "O(|ℱ|·n)", "matroid.realize.mbt", "已實作＋雙向檢核"],
    ["A12", "matroid_report / check_b0001_inheritance", "T5–T8",
     "M → 8 條擬陣檢核；K_ℱ* 上 13 條 B0001 檢核", "見各檢核", "matroid.checks.mbt", "已實作"],
    ["A13", "circuits_from_gf2（GF(2) 線性擬陣）", "T5",
     "GF(2) 列向量 → 秩、獨立、迴路", "秩 O(n·⌈m/64⌉)；迴路 O(2ⁿ·n·r·⌈m/64⌉)",
     "matroid.gf2.mbt", "已實作"],
    ["A14", "check_exchange（交換公理反例搜尋）", "X5、T8",
     "閉包 oracle → PASS/FAIL＋最小反例", "O(2ⁿ·n²)", "matroid.checks.mbt", "已實作"],
])

# ---------------------------------------------------------------- B0002 等式
ws = wb.create_sheet("B0002 等式")
add(ws, [
    ["編號", "等式", "名稱", "來源", "程式對應"],
    ["E-B1", "cl_𝒞(X) = X ⟺ X 平坦", "平坦判準", "P-B1", "is_flat / closure"],
    ["E-B2", "r(X) = r(cl(X))，cl_r(X) = {e : r(X∪{e}) = r(X)}", "秩—閉包對偶", "P-B2、X6", "closure vs closure_by_rank"],
    ["E-B3", "X 相依 ⟺ ∃C∈𝒞, C ⊆ X", "相依判準", "P-B3", "independent"],
    ["E-B4", "ℱ(M) 為 Moore 族", "Moore 性", "P-B4", "flats + check_realization"],
    ["E-B5", "ρ(F) = r(F)，F ⋖ G ⟹ r(G) = r(F)+1", "分級", "T6", "check_geometric（分級）"],
    ["E-B6", "r(F)+r(G) ≥ r(F∨G)+r(F∧G)", "半模", "T6", "check_geometric（半模）"],
    ["E-B7", "cl_A^{K_ℱ}(X) = ⋂{F∈ℱ : X ⊆ F}", "實現等式", "T7", "check_realization"],
    ["E-B8", "|ℱ(M(K_m))| = B_m（Bell 數）：K₃→5、K₄→15、K₅→52", "圖擬陣平坦數", "T6 推論", "Matroid::flat_count（開發期以 K3/K4/K5 對照）"],
    ["E-B9", "Fano：|𝒞| = 14 = 7 線 + 7 線補集；|ℱ| = 16；r(E) = 3", "Fano 計數", "T5", "mcircuits Fano"],
    ["E-B10", "U(r,n)：𝒞 = 所有 (r+1)-子集；r=2 時 |ℱ| = n+2", "均勻擬陣", "D-B1", "Matroid::uniform"],
])

# ---------------------------------------------------------------- B0002 樣本
ws = wb.create_sheet("B0002 樣本")
add(ws, [
    ["名稱", "構造", "|E|", "|𝒞|（算）", "r(E)", "|ℱ|（算）", "期望 |ℱ|", "A12", "B0001 繼承", "備註"],
    ["U24", "均勻擬陣 U(2,4)：𝒞 = 所有 3-子集（非二元）", 4, 4, 2, 6, 6, "8/8 PASS", "—", "E-B10"],
    ["M(K3)", "三角形圖擬陣（GF(2) 關聯矩陣）", 3, 1, 2, 5, 5, "8/8 PASS", "13/13 PASS", "Bell(3)"],
    ["M(K4)", "K₄ 圖擬陣（6 邊）", 6, 7, 3, 15, 15, "8/8 PASS", "13/13 PASS", "Bell(4)：4 三角形+3 四環"],
    ["Fano", "PG(2,2)：F₂³ 的 7 個非零向量", 7, 14, 3, 16, 16, "8/8 PASS", "—（規模超出繼承預算）", "7 線 + 7 線補集"],
    ["interval-4", "區間凸包（antimatroid，非擬陣）", 4, "—", "—", "—", "—", "X5 FAIL（正確）", "—", "負控制：證明檢核器非恆真"],
])

style_sheet(wb["公理與定義"], [8, 14, 22, 60, 14, 34, 18])
style_sheet(wb["命題引理定理"], [8, 14, 24, 60, 40, 34, 18])
style_sheet(wb["演算法"], [8, 28, 18, 34, 30, 16, 40, 20])
style_sheet(wb["等式"], [8, 46, 18, 16, 42])
style_sheet(wb["樣本上下文"], [16, 44, 6, 6, 6, 8, 8, 8, 8, 10, 8, 12])
style_sheet(wb["工程內容2名詞對應"], [46, 56, 14, 12])
style_sheet(wb["開發期缺陷"], [8, 30, 56, 46, 34])
style_sheet(wb["說明"], [18, 110])
style_sheet(wb["B0002 公理定義"], [9, 16, 24, 62, 12, 40, 26])
style_sheet(wb["B0002 命題定理"], [9, 14, 26, 62, 42, 36, 26])
style_sheet(wb["B0002 演算法"], [9, 30, 16, 34, 28, 34, 20])
style_sheet(wb["B0002 等式"], [9, 50, 18, 16, 40])
style_sheet(wb["B0002 樣本"], [14, 42, 7, 12, 7, 12, 12, 12, 18, 34])

wb.save("algorithm.xlsx")
print("已寫出 algorithm.xlsx：", [s.title for s in wb.worksheets])
