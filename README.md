# B0001 全局公理伽羅瓦對應（Global Axiom–Galois Correspondence, GAGC）

**登記編號：B0001（R1）＋ B0002（R2）**　　**狀態：兩輪開發完成**　　**語言：MoonBit（最新穩定版 moon 0.1.20261102，2026-11-02）**

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
│   └── B0001-定理體系.md
├── galois/                  MoonBit 模組 arena/b0001
│   ├── bitset/              稠密位元集（UInt64 字組）＋ GF(2) 消去所需的 xor
│   ├── context/             形式上下文 K=(A,S,R)、Φ/Ψ、分量、文字格式 parse
│   ├── galois/              A1 閉包、A4 局部閉包、A6 檢核器、參考實作
│   ├── lattice/             A2 NextClosure、A3 DG 典範基、A5 概念格與覆蓋
│   ├── matroid/             【B0002】擬陣：GF(2)、迴路、閉包、秩、平坦格、Moore 實現
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

（無環：bitset ← context ← galois ← lattice ← registry ← cmd/main）

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

- 數學合約：[`docs/B0001-定理體系.md`](docs/B0001-定理體系.md)、[`docs/B0002-定理體系.md`](docs/B0002-定理體系.md)
- 登記總帳：`algorithm.xlsx`（公理定義／命題引理定理／演算法／等式／樣本／名詞對應／開發期缺陷）
- 工程流水帳：`Dev.txt`
- 工程約束：`AGENTS.md`
- 各資料夾說明：`docs/`、`galois/`、`galois/{bitset,context,galois,lattice,matroid,registry,cmd/main,contexts}/`、`tools/`、`ci/`、`uploads/`

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
