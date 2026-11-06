# galois/cyclic/ — B0008 循環同調、內部張量積、漸新態射

本套件是 R10 的實作。數學合約正本是 [`docs/B0008-定理體系.md`](../../docs/B0008-定理體系.md)；
登記表在 `algorithm.xlsx` 的「B0008 循環」「B0008 樣本」兩張工作表。

## 已得定理（全部由 `moon run cmd/main -- cyclic` 逐條執行，59/59）

| 編號 | 定理 | 落點 |
|---|---|---|
| T51 | 8 個樣本代數的單位與結合律（`unit_vec`／`aug` 皆為向量） | `check_axioms`（`checks.mbt`） |
| T51b | **負控制**：破壞 x·x² = 0 後結合律必失效 | `check_axioms_negative` |
| T52 | dim A/[A,A] = dim H₀(混複體)（HH₀ 兩條獨立算式） | `hh0_by_commutators`、`hh_dim` |
| T53 | b² = 0、bB + Bb = 0、D² = 0（逐度，上限見 §B9） | `check_complex_axioms` |
| T54 | **HC 兩條路徑**：混複體總同調 = λ-複體 C_n/im(1−τ_n) 的同調 | `hc_dim_bicomplex`、`hc_dim_lambda` |
| T55 | **負控制**：有符號 λ_n = (−1)^n t_n 的 HC 公式失效（k 給 0，真值 1） | `hc_dim_lambda_signed` |
| T56 | 半單：HH_n = 0（n ≥ 1）、HC_{2k} = 單模個數、HC_{2k+1} = 0 | `check_semisimple` |
| T57 | Morita：M₂(ℂ) 與 ℂ 的 HH/HC 相同 | `check_morita` |
| T58 | 直和加法性 | `check_additivity` |
| T59 | dim HH₀(ℂ[G]) = 共軛類個數（Cayley 表暴力 × 代數） | `check_group_algebra` |
| T60 | 外部張量積：HH₀、HC_{2k} 的乘法性 | `check_tensor_multiplicative` |
| T61 | 內部張量積：X1 單位、**X2 共端 = HH₀**、X3 Hom(A,A) = Z(A) | `check_internal_tensor` |
| T61b | **負控制**：么性不可省（零作用模不是雙模） | `check_internal_tensor_negative` |
| T62 | 漸新態射四支：ASForget／ASIndex／ASBott／ASAssembly | `check_assembly` |
| T63 | `rank_q`（F_p，三質數取最大）× `rank_exact`（BigInt）交叉一致 | `check_rank_cross` |
| — | 循環算子階：t_n^{n+1} = id（n = 0..3） | `check_tau_order`（`bar.mbt`） |

## 已實作演算法

| 編號 | 演算法 | 位置 | 成本 |
|---|---|---|---|
| A52 | 精確秩：F_p 高斯（`mod_p`／`mod_inv`）＋ BigInt 整數消去（gcd 歸一） | `linalg.mbt` | O(min²·max) |
| A53 | 桶複體：基底元組 ↔ 整數索引、b_n、t_n、B_n = (1−t)sN、前插單位向量 | `bar.mbt` | O(d^{n+2}) |
| A54 | HH／HC 引擎：秩差公式、混複體奇偶分層總和、λ-複體兩路徑 | `homology.mbt` | O(d^{2n}) |
| A55 | 雙模共端與內部 Hom：關係矩陣（d·d₁·d₂ 列）與約束矩陣求秩 | `xprod.mbt` | O((d d₁ d₂)²·d₁d₂) |
| A56 | 群表合法性／單位／逆／共軛類閉包＋裝配映射秩與消失檢核 | `assembly.mbt` | O(n³) |

## 樣本代數（HH / HC）

| 代數 | dim | HH₀, HH₁, HH₂, HH₃ | HC₀, HC₁, HC₂, HC₃ |
|---|---|---|---|
| k | 1 | 1, 0, 0, 0 | 1, 0, 1, 0 |
| k ⊕ k | 2 | 2, 0, 0, 0 | 2, 0, 2, 0 |
| k[x]/x² | 2 | 2, 1, 1, 1 | 2, 0, 2, 0 |
| k[x]/x³ | 3 | 3, 2, 2, 2 | 3, 0, 3, 0 |
| M₂(ℂ) | 4 | 1, 0, 0, 0 | 1, 0, 1, 0 |
| ℂ[ℤ/3] | 3 | 3, 0, 0, 0 | 3, 0, 3, 0 |
| ℂ[S₃] | 6 | 3, 0, 0 | 3, 0, 3 |
| ℂ[D₈] | 8 | 5, 0, 0 | 5, 0, 5 |

## 視角依賴關係圖

```
alg.mbt（FdAlg：name, dim, unit_vec, aug, mult；構造子；unit/assoc 公理）
   ├──▶ bar.mbt（b_n、τ_n、λ_n、B_n；s 以前插 unit_vec 實現）
   │        ├──▶ homology.mbt（HH、混複體 HC、λ-複體 HC、秩差、公理檢核）
   │        │        └──▶ checks.mbt（T51–T63、報告、HH/HC 表）
   │        └──▶ xprod.mbt（Bimod、共端、內部 Hom、外部張量積乘法性）
   │                 └──▶ assembly.mbt（ASForget／ASIndex／ASBott／ASAssembly）
   └──▶ @galois（Check / Report 型別，與 B0001–B0007 共用）
linalg.mbt（矩陣、精確秩）被以上全部使用。
```

## 動線（怎麼跑）

```bash
cd galois
moon run cmd/main -- cyclic      # T51–T63 全部檢核（59/59）
moon run cmd/main -- cyctable    # HH/HC 結構表（8 個樣本）
moon run cmd/main -- xprod       # 內部張量積（共端／Hom）＋外部張量積乘法性
```

## 接入與輸出接口

* **接入**：`@cyclic.cyclic_samples()`（8 個樣本與各自度數上限）、
  `alg_*` 家族（可自建任意有限維么結合代數：給 `dim`、`unit_vec`、`aug`、`mult`）、
  `bimod_make`（自建雙模：給左右作用矩陣）。
* **輸出**：`cyclic_report() -> @galois.Report`、`cyc_table_render() -> String`、
  `xprod_render() -> String`、`xprod_tensor_render() -> String`；
  單項則可直接呼叫 `hh_dim`／`hc_dim_bicomplex`／`hc_dim_lambda`／`bimod_tensor_dim`。

## 注意（成本與陷阱）

1. `chain_size(d, n) = d^{n+1}`，d = 8、n = 3 時單一矩陣就是 4096×32768（1 GB）——**會靜默 OOM**。
   度數上限寫在 `cyclic_samples()` 與 `axiom_bounds()`，不要手動加大。
2. 單位與增廣**都是向量**（M_n 的單位是 ΣE_ii、ℂ[G] 的增廣是全 1 向量、M_n 沒有增廣）。
3. 有符號 λ_n = (−1)^n t_n **不是** HC 的正確模型（T55），別把 `hc_dim_lambda_signed` 當工具用。
4. MoonBit 綁定名必須小寫開頭（大寫會被當構造器）；長字串串接一律用 `StringBuilder`。
