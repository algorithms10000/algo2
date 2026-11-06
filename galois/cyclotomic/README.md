# galois/cyclotomic/ — B0009 圓體擴張伽羅華群、圓周群的所有單位根群

本套件是 R11 的實作，把原本只有一條樣本上下文（B0001 的 `K_cyclotomic`：ℚ(ζ₈)/ℚ）
的兩個名詞升級成**可算的分圓算術**。數學合約正本是
[`docs/B0009-定理體系.md`](../../docs/B0009-定理體系.md)；登記表在 `algorithm.xlsx` 的「B0009 圓體」工作表。

## 已得定理（全部由 `moon run cmd/main -- cyclo` 逐條執行，8/8）

| 編號 | 定理 | 落點 |
|---|---|---|
| T73 | μ_n ≅ ℤ/n：階為 d 的元素恰 φ(d) 個（d \| n），生成元 φ(n) 個（n ≤ 16） | `check_mu_n` |
| T74 | ℚ/ℤ ≅ ∪_n μ_n（Prüfer）：全撓、可除（m·y = x 有解）、μ_n = {x : nx = 0} 恰 n 個 | `check_qz` |
| T75 | Pontryagin 對偶 μ_n^ ≅ ℤ/n：χ_j(ζ^k)=ζ^{jk} 同態且非退化（n = 2..12） | `check_pontryagin_dual` |
| T76 | Φ_n：deg = φ(n)、Φ_n \| x^n−1（n ≤ 20）、已知係數對撞（Φ₁、Φ₅、Φ₈、Φ₁₂） | `check_cyclotomic_poly` |
| T77 | **Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^×**：σ_k 么正環同態、σ_kσ_l = σ_{kl}、雙射；det σ_k = ±1 交叉 | `check_galois_group` |
| T78 | 跡 = Ramanujan 和：Tr(ζ^j) = μ(n/d)φ(n)/φ(n/d)（d = gcd(n,j)），n ≤ 20 | `check_trace_ramanujan` |
| T79 | **伽羅華對應**：dim ℚ(ζ_n)^H = [G:H]（兩套秩演算法一致）；負控制 k ∉ (ℤ/n)^× | `check_galois_correspondence_all` |
| T80 | 二次子體 ℚ(√((−1)^{(p−1)/2}p))（p = 5,7,11,13）＋分圓特徵 Gal ≅ Aut(μ_n)（n = 3..12） | `check_quadratic_and_character` |

## 已實作演算法

| 編號 | 演算法 | 位置 | 成本 |
|---|---|---|---|
| A61 | 分圓多項式引擎：整係數多項式乘／精確除／整除判定、Φ_n 遞迴、φ(n)、因數清單 | `poly.mbt` | O(n²·φ(n)) |
| A62 | ℚ(ζ_n) 與 σ_k：多項式乘法＋對 Φ_n 降次、σ_k 矩陣、矩陣乘／相等、元素階、單位群 | `cyclotomic.mbt` | O(φ(n)³) |
| A63 | 單位根群與對偶：μ_n 階分佈、ℚ/ℤ 分數加法 mod 1 與可除性、Pontryagin 非退化配對 | `cyclotomic.mbt` | O(n²) |
| A64 | 跡與 Ramanujan：精算 Σσ_k 與 Möbius 公式對撞、不動子空間維度（堆疊秩）、高斯週期二次式 | `cyclotomic.mbt` | O(n·φ(n)³) |

## 視角依賴關係圖

```
poly.mbt（Poly：整係數多項式、Φ_n 遞迴、φ(n)、divisors）
   └──▶ cyclotomic.mbt
          ├── μ_n / ℚ/ℤ / Pontryagin（T73–T75）
          ├── reduce_mod_cyclo、cyclo_mul、sigma_matrix（ℚ(ζ_n) 算術與伽羅華群 T76–T77）
          ├── trace_of_basis／ramanujan_formula（T78）
          ├── fixed_subspace_dim／check_galois_correspondence（T79，用 @cyclic.rank_q）
          └── gauss_period_quadratic／quadratic 子體、分圓特徵（T80）
                 └──▶ checks.mbt（T73–T80、cyclotomic_report()、cyclotomic_table_render()）
交叉見證：@analytic.rmat_rank／rmat_det（ℚ 高斯）、@cyclic.rank_q（F_p 高斯）、@galois.Check/Report
```

## 動線（怎麼跑）

```bash
cd galois
moon run cmd/main -- cyclo        # T73–T80 全部檢核（8/8）
moon run cmd/main -- cyclotable   # Φ_n 表、(ℤ/n)^× 與跡、μ_n 階分佈
```

## 接入與輸出接口

* **接入**：`cyclotomic_poly(n)`、`reduce_mod_cyclo(n, coeffs)`、`cyclo_mul(n, x, y)`、
  `sigma_matrix(n, k)`、`units_mod(n)`、`subgroups_of_units` 由 `@bc` 使用；
  `cyclo_dim(n)`＝φ(n)。
* **輸出**：`cyclotomic_report() -> @galois.Report`、`cyclotomic_table_render() -> String`；
  單項可呼叫 `trace_of_basis`、`ramanujan_formula`、`fixed_subspace_dim`、`mu_order`、`qz_add`。
* **下游客戶**：`@bc`（B0010）用它算 ℤ/n 的 DFT 正交性與子群格的伽羅華對應。

## 注意（陷阱）

1. `reduce_mod_cyclo` 會把輸入補零到 φ(n)；輸入長度小於維度是常態（BUG-28 就是這裡越界）。
2. 一切是**整數**矩陣：Φ_n 么正 ⇒ ζ^{ik} 對 Φ_n 降次後係數仍是整數，不需要代數數型別。
3. 伽羅華對應是**反序**的：dim = [G:H]（不是 |H|，BUG-29）。
4. 非單位 k 會讓 ζ ↦ ζ^k **不良定義**（Φ_n(ζ^k) ≠ 0），這正是 T79 的負控制。
