# B0001 全局公理伽羅瓦對應（Global Axiom–Galois Correspondence, GAGC）

**登記編號：B0001（R1）＋ B0002（R2、R4）＋ B0003（R5）＋ B0004（R6）**　　**狀態：R1–R6 完成（R3 = A3′；R4 = B0002 延伸；R5 = B0003 同餘子群；R6 = B0004 撓群 E[n]）**　　**語言：MoonBit（最新穩定版 moon 0.1.20261102，2026-11-02）**

本專案把「公理系統 → 定理 → 演算法」做成**可執行**的鏈條：一條全局公理 + 四條局部公理，
推出四條定理與 13 條等式，再由定理的構造性內容導出 7 條演算法，並附一套能**主動找出反例**的檢核器。
所有樣本上下文都是真數學物件（含 ℚ(ζ₈)/ℚ 的伽羅瓦對應），不是人造資料。

---

## 1. 核心想法（一句話）

> 一個二元關係 R ⊆ A × S 誘導出一對**反單調伴隨映射** (Φ, Ψ)；
> 其複合給出兩側的**閉包算子**，兩側閉集族之間存在**反序格同構**。
> 「公理系統」與「演算法陳述系統」因此不是兩件事，而是同一個形式上下文的兩面。

這正是伽羅瓦理論的本質結構（子群 ↔ 中間體），B0001 把它抽成全域公理 X0，並演算法化。

---

## 2. 資料夾結構與依賴關係圖

```
B0001（本目錄）
├── docs/                    數學合約：定理體系全文（含證明）
│   ├── B0001-定理體系.md
│   ├── B0002-定理體系.md
│   ├── B0003-定理體系.md
│   └── B0004-定理體系.md
├── galois/                  MoonBit 模組 arena/b0001
│   ├── bitset/              稠密位元集（UInt64 字組）＋ GF(2) 消去所需的 xor
│   ├── context/             形式上下文 K=(A,S,R)、Φ/Ψ、分量、文字格式 parse
│   ├── galois/              A1 閉包、A4 局部閉包、A6 檢核器、參考實作
│   ├── lattice/             A2 NextClosure、A3 DG 典範基、A5 概念格與覆蓋
│   ├── matroid/             【B0002】擬陣：GF(2)、迴路、閉包、秩、平坦格、Moore 實現
│   ├── modular/             【B0003】Γ(n)/Γ₀(n)/Γ₁(n)、PSL₂(ℤ)、SL₂(ℤ/N)、X₀(N) 不變量
│   ├── elliptic/            【B0004】E[n]≅(ℤ/n)²、除多項式、Weil 配對、Paley/Ramsey、團複形同調
│   ├── registry/            樣本上下文與擬陣樣本（含 ℚ(ζ₈)/ℚ、K₃/K₄ 圖擬陣、Fano）
│   ├── cmd/main/            CLI（接入與輸出接口）
│   └── contexts/*.ctx       文字格式樣本（dump/parse 互逆）
├── tools/make_registry.py   產生 algorithm.xlsx（可重現）
├── ci/ci.sh                 全局編譯測試（回合末必跑）
├── algorithm.xlsx           定理／演算法／等式／樣本／名詞對應／缺陷總帳
├── Dev.txt                  開發流水帳（每回合更新）
├── AGENTS.md                與 uploads/工程約束.md 同文
└── uploads/                 委託方原始文件（唯讀）
```

### 依賴關係圖（以資料夾為視角，箭頭 = 「被 import」，含 B0002）

```
                 ┌───────────────┐
                 │  cmd/main     │  CLI
                 └───┬───────┬───┘
              ┌──────┘       └────────┐
        ┌─────▼─────┐          ┌─────▼─────┐        ┌──────────┐
        │ registry  │          │  lattice  │        │ matroid  │
        └──┬─────┬──┘          └──┬─────┬──┘        └────┬─────┘
           │     │                │     │         ┌──────┘  ┌──────────┐
           │  ┌──▼────────────────▼─────▼─┐       │    ┌────▼─────┐
           │  │        modular（B0003）    │◀──────┼────┤（獨立）  │
           │  └───────────────────────────┘       │    └──────────┘
           │     │                │     │                │
           │     └────────┬───────┘     │        ┌───────┘
           │     └───────┬────────┘     │
           │        ┌────▼─────┐        │
           │        │  galois  │        │
           │        └──┬────┬──┘        │
           │           │    └───────┐   │
           │     ┌─────▼─────┐      │   │
           └────▶│  context  │◀─────┴───┘
                 └─────┬─────┘
                       │
                 ┌─────▼─────┐
                 │  bitset   │
                 └───────────┘
```

（無環：bitset ← context ← galois ← {lattice, matroid, modular} ← registry ← cmd/main）
`modular` 只依賴 `galois`（取檢核型別），與 `matroid`、`lattice` 無耦合；`registry/congruence.mbt` 把 `modular` 造出的子群上下文餵給 `lattice` 的 A3′/A6。

### 動線（一次請求怎麼流動）

```
使用者 → cmd/main 解析 argv
      → registry.lookup / context.parse_context      （取得 K）
      → galois.decompose（A4 分量）                   （可選）
      → galois.closure_*（A1）／lattice.all_closed_stmts（A2）
      → lattice.canonical_basis（A3）／lattice.all_concepts+covers（A5）
      → galois.structural_report + lattice.basis_report（A6 檢核）
      → registry.summarize → 文字輸出（stdout）
```

---

## 3. 已獲得的定理（全部附證明，見 docs/B0001-定理體系.md）

| 編號 | 名稱 | 陳述（摘要） |
|---|---|---|
| **X0** | 全局公理：伽羅瓦對應 | ∀X⊆A, Y⊆S：X ⊆ Ψ(Y) ⟺ Y ⊆ Φ(X) |
| X1–X4 | 局部公理（B0001 自訂） | 有限性／支撐完全性／分離性／分量局部性 |
| P1 | 反單調性 | X⊆X′ ⟹ Φ(X′)⊆Φ(X)（Ψ 同） |
| P2 | 閉包三性 | cl_A、cl_S 擴張、單調、冪等 |
| P3 | Moore 族 | 閉集族對任意交封閉 ⇒ 完備格 |
| P4 | 反序格同構 | ℭ_A ≅ (ℭ_S)^op |
| P5 | 計數相等 | \|ℭ_A\| = \|ℭ_S\| = \|B(K)\| |
| P6 | 偽內涵列舉正確性 | 按基數遞增即可直譯 D8 |
| P7 | 與擬陣／Horn 的關係 | 本框架為四類結構的共同下界（註記） |
| L1–L4 | 伴隨律、複合單調、三角恆等、單次定點 | ΦΨΦ=Φ、ΨΦΨ=Ψ ⇒ 一次雙閉包即閉包 |
| **T1** | **全局公理伽羅瓦對應定理** | 伴隨對 + 閉包算子 + Moore 族 + 反序格同構 |
| **T2** | **重建定理（冗餘判準）** | X3 ⟺ 所有 cl_A({a})={a} ⟺ row 互不包含 |
| **T3** | **局部性定理** | 跨分量坍縮（cl=A）／分量內封閉／真閉集不越分量 |
| **T4** | **Duquenne–Guiguès 典範基** | Σ={P→cl_S(P) \| P 偽內涵} 完備且非冗餘 |

---

## 4. 已實作的演算法

| 編號 | 演算法 | 複雜度 | 位置 |
|---|---|---|---|
| A1 | 雙閉包 `closure_axioms` / `closure_stmts` | O(\|X\|·⌈n/64⌉ + \|Φ(X)\|·⌈m/64⌉) | `galois/closure.mbt` |
| A2 | NextClosure 枚舉全部閉集（多項式延遲） | 延遲 O(n·(⌈m/64⌉+⌈n/64⌉)) | `lattice/next_closure.mbt` |
| A3 | Duquenne–Guiguès 典範基（偽內涵） | O(2ⁿ·n·\|Σ\|)（輸出可指數） | `lattice/basis.mbt` |
| A4 | 分量分解（DSU）＋局部閉包 | O((m+n+\|R\|)·α) | `context/components.mbt`、`galois/closure.mbt` |
| A5 | 概念格＋上覆蓋（Hasse 邊） | O(\|ℭ\|·n·closure + \|ℭ\|·n²) | `lattice/next_closure.mbt` |
| A6 | 反例搜尋檢核器（13 條） | 窮舉上限內 | `galois/laws.mbt`、`lattice/*.mbt` |
| A7 | 文字格式 parse/dump（互逆） | O(行數×token + \|R\|) | `context/parse.mbt`、`cmd/main` |

---

## 5. 驗收：A6 檢核（三份真數學樣本，各 13 條，全部 PASS）

| 上下文 | 數學物件 | \|A\| | \|S\| | \|R\| | 分量 | \|ℭ_A\| | \|ℭ_S\| | \|B(K)\| | Hasse 邊 | \|Σ\| |
|---|---|---|---|---|---|---|---|---|---|---|
| `cyclotomic-q8` | ℚ(ζ₈)/ℚ，G ≅ C₂×C₂（子群 ↔ 中間體） | 5 | 5 | 12 | 1 | 5 | 5 | 5 | 6 | 5 |
| `divisibility` | ℤ 整除格（公倍數 ↔ 公因數） | 4 | 4 | 12 | 1 | 4 | 4 | 4 | 4 | 3 |
| `two-blocks` | 兩不交分量（T3 坍縮） | 4 | 6 | 8 | 2 | 8 | 8 | 8 | 10 | 7 |

`cyclotomic-q8` 的 5 個概念正是伽羅瓦基本定理的 5 組（子群, 中間體）對應；
`|ℭ_A| = |ℭ_S| = |B(K)|` 是 P5 的可執行見證。

---

## 6. 怎麼跑

```bash
# 0) 取得工具鏈（沙盒每次重裝；已裝過可略）
bash ci/bootstrap_toolchain.sh && export PATH=/tmp/moon/bin:$PATH

# 1) 全局編譯測試（check --target all + build + fmt + 樣本檢核 + 登記表重建檢查）
bash ci/ci.sh

# 2) 直接用 CLI
cd galois
moon run cmd/main                       # 三份樣本的完整摘要（含逐條 PASS/FAIL）
moon run cmd/main -- list               # 列出樣本
moon run cmd/main -- info cyclotomic-q8 # 單一摘要
moon run cmd/main -- concepts cyclotomic-q8   # 概念格（子群 ↔ 中間體）
moon run cmd/main -- basis  divisibility # DG 典範基
moon run cmd/main -- check  two-blocks   # 只跑 A6 檢核
moon run cmd/main -- closure cyclotomic-q8 '⟨σ⟩' '⟨τ⟩'   # 計算 cl_A(X)、Φ(X)、A4 局部閉包
moon run cmd/main -- dump   cyclotomic-q8                # 匯出文字格式
moon run cmd/main -- parse  "$(cat contexts/two-blocks.ctx)"  # 解析外部上下文
```

## 7. 接入與輸出接口

- **資料接入**：`@context.parse_context(text) -> ParsedContext`（格式見 `galois/contexts/README.md`）。
- **程式接入**：`@galois.closure_axioms / local_closure / structural_report`、
  `@lattice.all_closed_stmts / canonical_basis / all_concepts / upper_covers_stmts`。
- **輸出**：CLI 文字（summary / concepts / basis / check / closure / dump）；
  `algorithm.xlsx` 為工程總帳；`contexts/*.ctx` 為可交換的文字格式。

## 8. 文件索引

- 數學合約：[`docs/B0001-定理體系.md`](docs/B0001-定理體系.md)、[`docs/B0002-定理體系.md`](docs/B0002-定理體系.md)、[`docs/B0003-定理體系.md`](docs/B0003-定理體系.md)
- 登記總帳：`algorithm.xlsx`（公理定義／命題引理定理／演算法／等式／樣本／名詞對應／開發期缺陷）
- 工程流水帳：`Dev.txt`
- 工程約束：`AGENTS.md`
- 各資料夾說明：`docs/`、`galois/`、`galois/{bitset,context,galois,lattice,matroid,modular,registry,cmd/main,contexts}/`、`tools/`、`ci/`、`uploads/`

---

# B0002：交換閉包系統（擬陣）與 Moore 族的上下文實現（R2）

B0001 的 P7 只把「擬陣／交換公理」登記為註記；B0002 把它兌現，並把擬陣**嵌入** B0001 體系。

## 定理（詳見 `docs/B0002-定理體系.md`）

| 編號 | 名稱 | 內容 |
|---|---|---|
| X5 | 交換公理 | `y,z ∉ cl(X)`：`y ∈ cl(X∪{z}) ⟹ z ∈ cl(X∪{y})` |
| X6 | 秩公理 | `r(∅)=0`、單調、次模、單位增量（**不是** `r({e})=1`；擬陣允許環） |
| P-B1–P-B4 | 閉包四性、秩—閉包對偶、極小相依＝迴路、平坦族是 Moore 族 | — |
| **T5** | 三公理等價（Whitney 1935） | 閉包／迴路系統／秩函數互相唯一決定 |
| **T6** | 平坦格 = 幾何格（Birkhoff） | 底元是 `cl(∅)`（環集）；原子 = 秩 1 平坦集 |
| **T7** | **Moore 實現／提升定理** | `cl_A^{K_ℱ}(X) = ⋂{F∈ℱ : X⊆F}`，故 `ℱ = ℭ_A`，B0001 的 T1 對擬陣逐字適用 |
| **T8** | 可判定性與負控制 | 違反 X5 的閉包不可能由迴路系統表示 ⇒ 檢核器必須在負控制上 FAIL |

## 演算法

A8 迴路消去閉包、A9 秩（貪心）、A10 平坦集＋幾何格四項檢核、A11 Moore 實現（雙向）、
A12 檢核報告（8 條）＋B0001 繼承（13 條）、A13 GF(2) 線性擬陣（秩／迴路）、A14 交換公理反例搜尋。

## 驗收（真數字，全部由程式算出並與期望值比對）

| 樣本 | 構造 | \|E\| | \|𝒞\| | r(E) | \|ℱ\| | A12 | B0001 繼承 |
|---|---|---|---|---|---|---|---|
| `U24` | 均勻擬陣 U(2,4)（非二元） | 4 | 4 | 2 | 6 | 8/8 PASS | — |
| `M(K3)` | 三角形圖擬陣 | 3 | 1 | 2 | 5 = Bell(3) | 8/8 PASS | 13/13 PASS |
| `M(K4)` | K₄ 圖擬陣（4 三角形+3 四環） | 6 | 7 | 3 | 15 = Bell(4) | 8/8 PASS | 13/13 PASS |
| `Fano` | PG(2,2)（7 線+7 線補集） | 7 | 14 | 3 | 16 | 8/8 PASS | 規模超出（明示未檢核） |
| `interval-4` | 區間凸包（antimatroid） | 4 | — | — | — | **X5 FAIL（正確）** | — |

負控制 `interval-4` 的回報反例：`X={0}, y=1, z=2`。CI 強制檢查它必須 FAIL，
否則判定檢核器失效（工程約束：嚴禁恆真永綠假象）。

## 怎麼跑（B0002）

```bash
cd galois
moon run cmd/main -- matroids             # 列出擬陣樣本
moon run cmd/main -- matroid Fano         # 摘要＋A12 八條檢核
moon run cmd/main -- mcheck 'M(K4)'       # 另跑 B0001 繼承（K_ℱ* 上 13 條）
moon run cmd/main -- mcircuits Fano       # 列出 14 條迴路（7 線 + 7 線補集）
moon run cmd/main -- negctl               # 負控制：必須 FAIL 交換公理
```

## 本輪由檢核抓到的三個「人為錯誤」（已修正，記錄於 `algorithm.xlsx`）

1. **DOC-1**：文件把 Fano 迴路數寫成 7 → 實為 14（7 線 + 7 個 4 元線補集）。
2. **AXIOM-1**：X6 的 R4 誤寫 `r({e})=1` → 遇含環擬陣即失敗，改為 `r(∅)=0` ＋單位增量。
3. **FIX-1**：幾何格檢核誤要求底元有下覆蓋 → 底元是 `cl(∅)`（環集），已豁免並修正 T6 敘述。
   另有 **NOTE-1**：`K_ℱ` 必然違反 B0001 X2（空平坦集無見證）→ 增設 `ℱ*` 變體並升格為正面斷言。

---

# A3′：增量式 Duquenne–Guiguès 典範基（R3）

## 問題

A3 原版依基數遞增走訪 S 的**全部 2^n 個子集**：n = 24 就是 16,777,215 次候選判定。
這是量級問題，不只是常數問題。

## 做法（偽內涵 + 偽閉包）

對已找到的偽內涵集 𝔓 定義**偽閉包**

```
clp_𝔓(X) = X ∪ ⋃ { cl_S(Q) : Q ∈ 𝔓, Q ⊊ X }         （迭代至不動點）
```

則 **P6′**：`P 是偽內涵 ⟺ clp_𝔓(P) = P 且 cl_S(P) ≠ P`。
於是可以直接對閉包算子 clp_𝔓 跑 **NextClosure**——每步只做 ≤ n 次「加一元素再取 clp 不動點」，
**完全沒有 2^n 因子**。**T4′** 證明 lectic 走訪不重不漏，靠三條不變量：
Q ⊊ P ⟹ Q 先走訪（不漏）、𝔓 單調增 ⟹ 真偽內涵永遠是不動點（不被跳過）、落點嚴格遞增（不重複）。

## 驗證階梯（真數字）

| 樣本 | n | A3′ 走訪步數 | A3 暴力候選數 | 同族核對 | E16 閉集族 | 非冗餘 |
|---|---|---|---|---|---|---|
| `divisors-12` | 6 | 12 | 63 | PASS | PASS | PASS |
| `divisors-180` | 18 | 45 | 262,143 | PASS | PASS | PASS |
| `divisors-240` | 20 | 50 | 1,048,575 | PASS | PASS | PASS |
| `divisors-420` | 24 | 62 | 16,777,215 | **明示未檢核**（n>20） | PASS | PASS |

暴力不可行時不假綠：改用 **E16**（由 Σ 定義的 Horn 閉包系統，其閉集族必須與 K 的閉集族逐元素相同，
|ℭ|=d(420)=24）與「刪去任一條，前提的閉包必須真的變小」的非冗餘判準——兩者成本 ∝ 閉集數，故 n=24 仍可判定。
CI 第 8 步強制：`divisors-12/180/240` 共 12 條 PASS，`divisors-420` 必須「3 PASS + 1 條未檢核」。

## 由實測得到的三條等式（已寫回 docs 與登記表）

- **E14** `cl(∅) = Φ(A)`：空前提的閉包是「所有公理共有的陳述」，**不是 S**。
- **E15** ∅ 是偽內涵 ⟺ `cl(∅) ≠ ∅`（我在開發期把這條手算錯兩次，檢核器把它變成紅燈）。
- **E16** `ℭ(Σ) = ℭ_S`：典範基定義的 Horn 閉包系統與原上下文有同一閉集族。

## 怎麼跑

```bash
cd galois
moon run cmd/main -- dg divisors-240      # 統計 + 四條檢核
moon run cmd/main -- dg divisors-420      # n=24：62 步 vs 16,777,215
moon run cmd/main -- dgbasis divisors-420 # 列出 38 條蘊含
```

介面：`@lattice.canonical_basis_incremental`、`dg_report`、`dg_stats_line`、`render_basis`、
`theory_closed_sets`、`check_incremental_agrees_naive`、`check_basis_lectic`、
`check_theory_equivalent`、`check_theory_irredundant`。

---

# B0002 延伸：二元性、對偶、Tutte 多項式、擬陣普查（R4）

## 新立的定理

| 編號 | 內容 | 驗證方式 |
|---|---|---|
| **T9** | M 二元 ⟺ M 無 **U(2,4)** minor（Tutte 1958） | 兩條**完全獨立**的路徑：禁 minor 判準 vs 由基 + 基本迴路顯式構造 GF(2) 表示 |
| **T9′** | M 正則 ⟺ 無 {U(2,4), F7, F7\*} minor；**Fano 二元但非正則** | `check_fano_binary_not_regular`；圖／餘圖擬陣必正則 |
| **T10** | 對偶：(M\*)\*=M、餘迴路＝超平面補集、對偶平坦秩判準、U(r,n)\*≅U(n−r,n)、T_{M\*}(x,y)=T_M(y,x)、M(K₄) 自對偶 | 六條逐項檢核 |
| **T11** | \|ℱ(U(r,n))\| = 2 + Σ_{1≤k<r} C(n,k) | 多組 (r,n) 對照 |
| **T11′** | 用 **C1–C3** 與 **I1–I3** 兩條公理路線列舉全部擬陣，計數必須相同 | 普查 n = 2..5 |
| **T12** | Tutte 特化、χ=(−1)^r T(1−λ,0)、**Whitney** P(G,λ)=λ^{c}χ_{M(G)}(λ)、χ_{F7}=(λ−1)(λ−2)(λ−4) | 多項式與計數互比 |

## 實測數字

**擬陣普查**（兩條路線完全一致）：

| n | 迴路路線 | 獨立集路線 | 同構類 | 非二元 | 非正則 |
|---|---|---|---|---|---|
| 2 | 5 | 5 | 4 | 0 | 0 |
| 3 | 16 | 16 | 8 | 0 | 0 |
| 4 | 68 | 68 | 17 | **1（= U(2,4)）** | 1 |
| 5 | 406 | 406 | 38 | 32（6 類） | 32 |

n = 5 的 406 個擬陣上，「禁 minor 判準」與「基本迴路構造」**0 次分歧**。

**樣本**（`mext` 實測）：

| 樣本 | 二元 | 正則 | T_M(x,y) | χ_M(λ) |
|---|---|---|---|---|
| U(2,4) | 否 | 否 | x²+2x+y²+2y | λ²−4λ+3 |
| M(K₃) | 是 | 是 | x²+x+y | λ²−3λ+2 |
| M(K₄) | 是 | 是 | x³+3x²+4x+2xy+3y²+y³+2y | λ³−6λ²+11λ−6 |
| Fano | **是** | 否 | x³+4x²+3x+7xy+6y²+3y³+y⁴+3y | λ³−7λ²+14λ−8 = (λ−1)(λ−2)(λ−4) |
| Fano\* | 是 | 否 | x⁴+3x³+6x²+3x+7xy+4y²+y³+3y | λ⁴−7λ³+21λ²−28λ+13 |
| U(3,5) | 否 | 否 | x³+2x²+3x+y²+3y | λ³−5λ²+10λ−6 |
| M(K₄)\* | 是 | 是 | 同 M(K₄)（自對偶） | λ³−6λ²+11λ−6 |

## 這輪被檢核器抓到的四個「定理寫錯」（全部已修正並寫進登記表）

1. **DOC-3**：把 F7、F7\* 放進**二元**禁 minor 集 —— 那是**正則**的判準。**Fano = PG(2,2) 本身就是二元擬陣**（GF(2)³ 的 7 個非零向量）。
2. **THM-1**：我據「平坦格對偶」寫 `|ℱ(M*)| = |ℱ(M)|` —— 錯。U(2,3) 有 5 個平坦集，其對偶 U(1,3) 只有 2 個。改為秩判準 P-B7；Fano\* 因此**不設平坦數期望值**（登記 −1），不拿程式自己的輸出當期望值。
3. **THM-2**：著色多項式漏掉 λ^{c(G)} 因子 —— K₃ 在 λ=3 上 χ=2 而著色數 6。
4. **THM-3**：均勻擬陣平坦公式差一層 —— U(1,2) 實得 2、舊公式 3。

## 怎麼跑

```bash
cd galois
moon run cmd/main -- mext Fano        # 二元/正則判定 + Tutte + 11 條檢核
moon run cmd/main -- mextall          # 13 條全域定理檢核
moon run cmd/main -- mreg             # 登記期望值核對（7 份樣本）
moon run cmd/main -- mcensus 5        # 406 個擬陣、38 個同構類、32 個非二元
```

介面：`@matroid.{minor_of,delete_at,contract_at,dual,cocircuits,isomorphic,has_minor_in,
is_binary_by_minors,is_binary_by_construction,is_regular,tutte_deletion_contraction,tutte_subsets,
characteristic_definition,characteristic_from_tutte,proper_coloring_count,
all_matroids_by_circuits,all_matroids_by_independent_sets,isomorphism_classes,extension_report}`。

---

# B0003：主同餘子群 Γ(n)/Γ₀(n)/Γ₁(n) 與射影模群 PSL₂(ℤ)（R5）

`工程內容2.md` 的名詞群要求「**射影模群 PSL₂(ℤ)**」與「**主同餘子群 Γ(n)、Γ₀(n)、Γ₁(n)**」。
B0001 把「子群 ↔ 中間體」的伽羅瓦對應做成了可執行框架，B0003 換上**真的一組子群**：同餘子群。
它們由模 N 的同餘條件定義，因此「包含、指數、正規性」都能在有限群 SL₂(ℤ/N) 上**暴力判定**，
給封閉公式一個完全獨立的對照；而 X₀(N) 又有古典的解析不變量（尖點、橢圓點、虧格）可作外部期望值。

## 定理（詳見 `docs/B0003-定理體系.md`）

| 編號 | 內容 | 驗證 |
|---|---|---|
| **T13** | [SL₂(ℤ):Γ₀(N)] = ψ(N)、[SL₂:Γ₁(N)] = ψ(N)φ(N)、[SL₂:Γ(N)] = ψ(N)φ(N)N = N³∏(1−1/p²) | N = 2..6 在 SL₂(ℤ/N) 上暴力數元素比對；另核對 [Γ₀:Γ₁]=φ(N)、[Γ₁:Γ]=N |
| **T14** | X₀(N)：ν_∞ = Σ_{d\|N}φ(gcd(d,N/d))、ν₂、ν₃、**12g = 12 + ψ − 3ν₂ − 4ν₃ − 6ν_∞** | 與古典虧格表 N = 1..24 **逐一相符**；表外明示「未檢核」 |
| P-C1／P-C2 | Γ(N) ◁ SL₂(ℤ/N)；Γ₁(N) ◁ Γ₀(N)、Γ₀/Γ₁ ≅ (ℤ/N)^×，但 N ≥ 2 時 Γ₁(N) **不**正規於 SL₂ | 全元素共軛暴力；附**顯式共軛見證** |
| P-C3／P-C4 | −I ∈ Γ₀(N) 恆真；−I ∈ Γ₁(N)/Γ(N) ⟺ N\|2；N ≥ 3：\|PSL₂(ℤ/N)\| = \|SL₂\|/2，N = 2：PSL₂ = SL₂ = S₃ | ± 成對暴力計數 |

## 演算法

A20 算術函數（φ、ψ、χ₋₄、χ₋₃、ν₂、ν₃、ν_∞、g，全整數運算，12g 整除性即時攔錯）、
A21 有限群暴力（`sl2_group`、`in_subgroup`、指數／包含／正規性／共軛見證）、
A22 同餘子群上下文（12 個子群的包含關係，由 SL₂(ℤ/12) 的暴力判定給出）。

## 驗收（真數字）

**虧格表**（`moon run cmd/main -- genus`，N = 1..24 全部「✓古典」）：

| N | 1 | 2 | 3 | 4 | 5 | 6 | 11 | 12 | 17 | 19 | 22 | 23 | 24 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| ψ | 1 | 3 | 4 | 6 | 6 | 12 | 12 | 24 | 18 | 20 | 36 | 24 | 48 |
| ν_∞ | 1 | 2 | 2 | 3 | 2 | 4 | 2 | 6 | 2 | 2 | 4 | 2 | 8 |
| g | 0 | 0 | 0 | 0 | 0 | 0 | **1** | 0 | 1 | 1 | **2** | **2** | 1 |

**樣本上下文 `congruence-12`**：A = S = { Γ₀(2), Γ(2), Γ₀(3), Γ₁(3), Γ(3), Γ₀(4), Γ₁(4), Γ(4), Γ₀(6), Γ₁(6), Γ(6), SL₂(ℤ) }，
R = 包含（SL₂(ℤ/12) 暴力判定）。實測 |R| = 47、|ℭ_S| = 13、DG 基 |Σ| = 16（A3′ 走 29 步 vs 暴力 4095），
**B0001 的 A6 8/8、A3′ 4/4 全通過**——B0001 的結構定理在這一組真子群上逐字成立。
（Γ₁(2) 被排除：φ(2)=1 ⇒ Γ₀(2)=Γ₁(2)，同時入表會破壞分離性 X3。）

## 這輪被抓到的兩個錯（已修，記於 `algorithm.xlsx`）

1. **BUG-3**：`(a*d − b*c) % n == 1` —— MoonBit 的 `%` 對負數給負餘數，N = 2 時只數到 3 個元素（正確 6）。
   改為 `norm_mod`。**最小的例子最能翻臉。**
2. **DOC-4**：把「−I ∈ Γ ⟺ N\|2」套到三種子群（其實 −I ∈ Γ₀(N) 恆真，因 c = 0）；
   又把 |PSL₂(ℤ/N)| 一律寫成 |SL₂|/2（N = 2 時 −I ≡ I，故 PSL₂ = SL₂ = S₃）。

## 怎麼跑

```bash
cd galois
moon run cmd/main -- modular      # T13、T14：62 條檢核
moon run cmd/main -- genus        # ψ/φ/ν₂/ν₃/ν_∞/g 並與古典表比對（N=1..24）
moon run cmd/main -- congruence   # 樣本上下文：A6 8/8、DG 基 |Σ|=16
```

介面：`@modular.{sl2_group, in_subgroup, index_by_bruteforce, subset_by_bruteforce,
is_normal_by_bruteforce, conjugation_witness, gamma_zero, gamma_one, gamma_level, full_sl2,
dedekind_psi, euler_phi, cusp_count, elliptic_two_count, elliptic_three_count, genus_x0,
classical_genus, modular_report}`、`@registry.congruence_context / congruence_summary`。

---

# B0004：橢圓曲線撓群 E[n] ≅ (ℤ/n)²，及其衍生結構（R6）

## 為什麼是它

B0003 做出 Γ(n)/Γ₀/Γ₁ 與 PSL₂(ℤ)，但留下一個缺口：**Γ(n) 是什麼東西的自同構群？**
答案是把 E[n] 的一組基（level-n structure）保住的那一群。本輪補上撓群，兩套體系因此**併攏**：

| 撓群上的軌道 | 個數 | 等於 B0003 的指數 |
|---|---|---|
| 階恰為 n 的點 | ψ(n)φ(n) | [SL₂(ℤ) : Γ₁(n)] |
| 階為 n 的循環子群 = ℙ¹(ℤ/n) | ψ(n) | [SL₂(ℤ) : Γ₀(n)] |
| 辛基（det = 1） | ψ(n)φ(n)n | [SL₂(ℤ) : Γ(n)] |
| 全部有序基 | ψ(n)φ(n)n·φ(n) = \|GL₂(ℤ/n)\| | [SL₂:Γ(n)]·φ(n) |

**T16** 就是這張表。它把「算術函數 ψ、φ」與「有限群軌道—穩定化子」溶成同一個計數
（n = 2..12 全部對上，見 `moon run cmd/main -- eptable`）。

## 定理（詳見 `docs/B0004-定理體系.md`）

| 編號 | 內容 | 驗證方式 |
|---|---|---|
| **T15** | E[n] ≅ (ℤ/n)² 的三條等價刻劃：群論／完美配對／**deg ψ_n = (n²−1)/2（奇）、(n²−4)/2（偶）** | BigInt 精確算 ψ_n：3 條曲線 × n = 2..12，含「除以 2y」整除性斷言 |
| **T16** | 軌道計數 = 同餘指數（上表）＋ 軌道—穩定化子 \|orbit\|·\|stab\| = \|SL₂(ℤ/n)\| | n = 2..12 暴力計數 vs `@modular` 的公式 |
| **T17** | Galois 等變 e(MT,MS) = det(M)·e(T,S) ⇒ ρ_{E,n} 的像 ⊂ GSp₂ = GL₂，**保配對者恰為 SL₂** | n = 2,3,4 對全部 GL₂(ℤ/n) 元素窮舉 |
| **T18** | 配對值的二次特徵 ⇒ **Paley 圖**（q≡1 mod 4，srg、可遷、自補）／**Paley 競賽**（q≡3，雙正則）；Delsarte ⇒ **R(ω+1,α+1) > q** | q = 3,5,7,11,13,17，外部古典參數全部對上 |
| **T19** | 鏡像對稱：χ(det) 平方→保色、非平方→翻色 ⇒ 圖自補、競賽反向同構；μ_n 共軛使 e_n 反演 | 顯式給出 λ 並逐元素比對 |
| **T20** | 撓群線性擬陣：秩 2、p+1 個平行類、**簡化 = U(2,p+1)**；p = 2 時 = M(K₃)（B0002 樣本） | p = 2,3,5,7（p ≤ 3 暴力列迴路與平坦集） |
| **T21** | 團複形 Δ(P(q)) 的 GF(2) 同調：β₀ = BFS 分量、Euler–Poincaré 兩路徑一致；並餵回 B0001 的 A6/A3′ | q = 5,13,17 ＋ 樣本上下文 `paley-13` |

## 實測（真數字）

| q | 類型 | 不變量 | ω | α | Ramsey 結論 |
|---|---|---|---|---|---|
| 5 | 圖 | srg(5,2,0,1) = C₅ | 2 | 2 | R(3,3) > 5 |
| 13 | 圖 | srg(13,6,2,3) | 3 | 3 | R(4,4) > 13 |
| 17 | 圖 | srg(17,8,3,4) | 3 | 3 | **R(4,4) > 17**（古典值 18，此處最優） |
| 3／7／11 | 競賽 | 雙正則（出度 1/3/5、λ = 0/1/2） | 遞移子競賽 2/3/4 | — | — |

| q | 面數 (f₀,f₁,f₂) | GF(2) Betti | χ(面) | χ(β) |
|---|---|---|---|---|
| 5 | (5, 5, 0) | (1, 1, 0) | 0 | 0 |
| 13 | (13, 39, 26) | (1, 2, 1) | 0 | 0 |
| 17 | (17, 68, 68) | (1, 0, 16) | 17 | 17 |

`paley-13` 樣本上下文（P(13) 的閉鄰域）：\|R\| = 91、\|ℭ\| = 210、DG 基 \|Σ\| = 221
（A3′ 走 431 步 vs 暴力 8191），**A6 8/8、A3′ 4/4 全通過**。

## 這輪被抓到的三個錯（已修，記於 `algorithm.xlsx`）

1. **BUG-4**：ψ_n 遞歸必須**先**「除以 2y」再化簡 y² = h(x)；首版反過來，n = 5 起整數性判定崩潰
   （商環裡「是否含 y 因子」不可判定）。
2. **BUG-5**：循環子群規範鍵誤取全部倍數（含 O 與非生成元）⇒ n = 4,5,6 的子群數塌成 1 或 9；
   順帶發現「#基」要分成 det = 1 的辛基（= [SL₂:Γ]）與全部基（= \|GL₂\| = [SL₂:Γ]·φ）。
3. **BUG-6**：撓群擬陣迴路數漏了「每條線 p−1 個非零向量」⇒ p 奇時應為 (p+1) + (p−1)³·C(p+1,3)。

## 怎麼跑

```bash
cd galois
moon run cmd/main -- elliptic    # T15–T21：69 條檢核
moon run cmd/main -- eptable     # E[n] 軌道計數 vs B0003 同餘指數（n=2..12）
moon run cmd/main -- paley       # Paley 圖／競賽、Ramsey 下界、團複形同調
moon run cmd/main -- paleyctx    # paley-13 樣本上下文：A6 8/8、A3′ 4/4
```

介面：`@elliptic.{div_polys, np_reduce, e_group, weil_exp, is_basis, count_points_of_order,
count_cyclic_subgroups, count_det_one_bases, count_all_bases, gl2_group, mact, legendre,
paley_adjacency, paley_tournament, clique_number, is_strongly_regular, is_doubly_regular,
self_complementary_witness, reversal_witness, flag_homology, components_of, rank_mod_p,
circuits_bruteforce, flats_bruteforce, simplification_is_uniform, elliptic_report}`、
`@registry.paley_context / paley_summary`。
