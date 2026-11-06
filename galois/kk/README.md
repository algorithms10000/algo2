# galois/kk — 真 KK-理論的可計算片段（B0006）

對應 `../../docs/B0006-定理體系.md`：**A-K1–A-K4、D-K1–D-K8、P-K1–P-K6、T32–T40、A36–A43**，
以及 `../../docs/B0007-定理體系.md` §9–§12 的**界外部份**：**A-K5、D-H9、T48–T50、A51**。
檢核：`moon run cmd/main -- kk` ⇒ **46/46 通過**；`-- kkout` ⇒ **6/6 通過**；
另有三條輸出子命令 `kktable`／`kksix`／`kkctx`。

## 這一輪的界（先劃界，再落地）

KK(A, B) 一般是 Hilbert 模上 Fredholm 模的算子同倫類，**不可判定**。本套件只做
**bootstrap 類 + K-群有限生成**的片段——此時 Kasparov 的萬有係數定理（UCT）把它化約成
`Hom` 與 `Ext¹` 的整數線性代數。凡超出此界的問題，`UCTData.kind = 0` 會**明示「只決定到擴張」**，
不以綠燈冒充（A-K1）。

## 已獲得的定理

| 編號 | 內容 | 落點 |
|---|---|---|
| **T32** | Hilbert C*-模的投影類 ⇒ K₀(A) = ℤ^r：歸一化秩向量 (rank p_i / n_i) 可加、生成、且 [1] = (1,…,1) | `checks.mbt`（`check_projection_algebra`、`check_hilbert_module_k0`） |
| **T33** | 六項正合列的**秩—零化度判準**：自由群上「後映射∘前映射 = 0 且兩秩相加 = 節點秩」⟺ 正合；Toeplitz 擴張與有限維分裂擴張全通過，β 改壞則**必須**失敗 | `cstar.mbt`（`six_term_check`）、`check_six_term_*` |
| **T34** | MvN 計算 (n−1)[1] = −[p] ⇒ **K₀(O_n) = ℤ/(n−1)、K₁(O_n) = 0**；三條路徑（coker/ker、UCT、SNF）交叉驗證（n = 2..8） | `cuntz_ktheory`、`check_cuntz_ktheory` |
| **T35** | UCT 值表：KK(ℂ,B) = K₀(B)、KK(A,ℂ) = K⁰(A)、KK(C(S¹),C(S¹)) = ℤ²、KK(ℂ,O_n) = ℤ/(n−1)、KK(O_n,ℂ) = 0 | `kk_uct`、`check_uct_case` |
| **T36** | Kasparov 乘積 = K-群映射的合成：單位律、結合律、K-理論函子性（diag/pr₁ 給出 pr₁∘diag = id） | `kk_compose`、`check_kk_product_*` |
| **T37** | 在 UCT 片段內 **KK-等價 ⟺ K-群同構**（ℂ ~ M₂ ~ M₃、ℂ ≁ C(S¹)、O₂ ≁ O₃）；並證 K-理論**不完備**（K_*(O₂) = (0,0)） | `kk_equivalent`、`check_kk_equivalence_cases`、`check_k_theory_incomplete` |
| **T38** | 穩定性 A⊗K ~ A（K_*(A⊗K) = K_*(A)、KK(A⊗K,B) = KK(A,B)）與 Bott 週期性 K_{i+2} = K_i | `kpair_tensor_k`、`kpair_bott_periodic` |
| **T39** | **index(T_f) = −wind(f)**：算子側用非方截斷的精確秩、符號側用幅角原理；並明示界限（方截斷恆 0、一般符號的截斷不保指標） | `hilbert.mbt`、`check_index_winding`、`check_winding_general`、`check_index_is_boundary` |
| **T40** | 接縫：(a) K₀(C*(S_n)) = ℤ^{p(n)} 且 Σd_λ² = n! = \\|im(B_n→S_n)\\|（B0005）(b) K₀(C*(SL₂(ℤ/n))) = ℤ^{#共軛類}（B0003）(c) 理想格的 A6 8/8、A3′ 4/4、閉集 = 2³（B0001 公理層） | `sym.mbt`、`check_seam_*` |

| **T48** | **界外清單合規**（A-K5）：O1–O6 每項都有 reason／inside_part／witness 且 verdict 合法；並把「不決定」做成可檢核的斷言——kind = 0 的樣本 K₀ = ℤ、K₁ = ℤ/2 給出 **兩個都符合 UCT 的可能值** ℤ⊕ℤ/2⊕ℤ/2 與 ℤ⊕ℤ/4，程式斷言兩者不相等。負控制：缺 witness／verdict 非法 ⇒ 不合規 | `outside.mbt`（`check_outside_manifest`、`check_outside_negative_control`、`scope_item_compliant`） |
| **T49** | **自由積 K-群**：K₁(A*B) = K₁(A) ⊕ K₁(B) **可加**（C*_r(𝔽_n) 給 ℤⁿ，與 Pimsner–Voiculescu 登記值一致）；K₀ **不可加**（可加性預測 ℤⁿ、登記值 ℤ）⇒ K₀ 的自由積計算明示界外 | `check_free_product_k`、`free_product_k1`、`free_group_cstar_kpair` |
| **T50** | **Künneth 的界內截面**：K_n(A⊗B) = ⊕K_i(A)⊗K_j(B) ⊕ ⊕Tor(K_i,K_j)；M₂⊗M₃ = M₆（K₀ = ℤ）、M₂⊗C(S¹)（K₀ = ℤ、K₁ = ℤ）、Tor(ℤ/2,ℤ/2) = ℤ/2、Tor(ℤ/2,ℤ/3) = 0；非核情形（min/max 分歧）只登記不宣稱 | `check_kunneth_inside`、`fga_tensor`、`fga_tor`、`kunneth_kpair` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A36 | 有限生成交換群引擎：SNF（歐幾里得 + 除法修正）、coker、ker、Hom、Ext¹、直和規範化 | O(n³ log‖a‖) |
| A37 | 六項正合列檢核器與分裂擴張建構 | O(6n³) |
| A38 | C*-代數模型：有限維（⊕M_{n_i}）、Toeplitz 𝒯_n、Cuntz O_n、圓 C(S¹) | O(1) 每族 |
| A39 | UCT KK 計算器（含「未被決定」的明示） | O(n²) |
| A40 | Kasparov 乘積（自由部分合成）+ 單位／結合律／函子性檢核 | O(n³) |
| A41 | Hilbert 模秩向量、投影判準（ℚ 上精確） | O(n³) |
| A42 | 精確有理線性代數 + Fredholm 指標 + 因式法繞數 | O(n³) |
| A43 | 對稱群不可約維度（hook length）與有限群共軛類 | O(p(n)·n²) |
| A51 | 界外清單引擎（A-K5 的可執行版）＋ 自由積截面 ＋ 張量／Tor／Künneth | O(k²) |

## 視角依賴關係圖

```
kk ──▶ galois（Check / Report）
kk ──▶ context + lattice（把理想格做成形式上下文，跑 B0001 的 A6／A3′）
kk ──▶ braid（T40a：|im(B_n→S_n)| = n! 對照 Σd_λ²）
kk ──▶ modular（T40b：SL₂(ℤ/n) 的共軛類計數）
hyper ──▶ kk（T47 借用 `partitions`；反向不依賴）
cmd/main ──▶ kk（kk / kktable / kksix / kkctx / kkout）
docs/B0006-定理體系.md §2–§11 ──▶ 本套件
```

## 動線與接口

- 交換群：`FgAb`、`fga_free/cyclic/make/zero`、`fga_direct_sum`、`fga_canonical`、`fga_hom`、`fga_ext1`、`fga_render`、`fga_eq`。
- 矩陣：`IntMat`、`intmat_of/zero/identity/mul/transpose/apply/rank`、`snf_diag`、`coker_of`、`kernel_of`、`is_injective/surjective`。
- K-群與代數：`KPair`、`kpair/kpair_render/kpair_shift/kpair_eq`、`FDA`、`fda/fda_dim/fda_rank/fda_k/fda_unit/fda_quotient/fda_ideal/fda_is_simple`、
  `k_of_compact/k_of_circle/k_of_toeplitz`、`toeplitz_circle_extension`、`toeplitz_extension`、`cuntz_ktheory`、`fda_extension`。
- 六項正合列：`SixTerm`、`six_term`、`six_term_check`、`SixCheck`。
- KK：`UCTData`、`kk_uct`、`uct_group`、`uct_determined`、`uct_render`、`KKClass`、`kk_class`、`kk_identity`、`kk_compose`、`kk_class_eq`、`kk_class_invertible`、
  `kk_equivalent`、`kpair_tensor_k`、`kpair_bott_periodic`。
- Hilbert：`Rat`（精確有理數）、`QMat`、`qmat_rank/qmat_nullity/qmat_fredholm_index`、`is_projection`、`hilbert_module_rank_vector`、
  `Laur`、`laur_of/laur_mul/laur_render`、`wind_of_factors`、`laur_of_factors`、`rat_inside_unit`、`toeplitz_truncation`、`toeplitz_truncation_rect`、`toeplitz_truncation_linear`。
- 群：`partitions`、`hook_product`、`irrep_dim`、`sum_dim_squares`、`k_of_symmetric_group`。
- 公理層：`kk_ideal_context`、`kk_ideal_context_with_zero`、`quotient_label`。
- 界外（B0007）：`ScopeItem`、`outside_items`、`outside_count`、`scope_item_compliant`、`fga_tensor`、`fga_tor`、`kunneth_kpair`、
  `free_product_k1`、`free_product_k0_naive`、`free_group_cstar_kpair`、`circle_free_factors`、`outside_render`。
- 檢核：`kk_report()`（46 條）、`outside_report()`（6 條）。

## 已知修正（保留在程式碼註解）

- **BUG-13**：`fga_hom` 必須含「自由 ℤ → H 的撓部分」（Hom(ℤ,H) = H），`fga_ext1` 必須含 (ℤ/d)^{rank H}；
  漏掉任一項會讓 KK(ℂ,O_n) 算成 0（與六項正合列互相矛盾）。
- **BUG-14**：Laurent 多項式建構必須合併同指數項。
- **BUG-15**：方矩陣截斷的指標恆為 0；指標必須用非方截斷 ℂ^N → ℂ^{N+k} 才看得見。
- **BUG-16**：理想格上下文若含零商（支撐為空），B0001 的 X2 必失敗 ⇒ 主上下文只取非零商，零商另立邊界檢核。

## 界外清單（B0007，`-- kkout` 可印全文）

| 編號 | 項目 | 判定 | 界內截面 |
|---|---|---|---|
| O1 | 非 bootstrap 類的 KK | 界內截面 | 組裝圖 ∪ 有界同態（kind = 0 明示不決定） |
| O2 | 無窮維 Fredholm 模 | 界內截面 | 有限截斷的指標（N = 1..4 全 −1，方截斷全 0） |
| O3 | min／max 張量範疇 | **界外** | 有限維與 C(S¹) 皆核 ⇒ min = max |
| O4 | 自由積 K-群 | 界內截面 | K₁ 可加（ℤⁿ）；K₀ 界外 |
| O5 | 非有限生成的 K-群 | **界外** | 有限生成（秩 ≤ 8） |
| O6 | KK 的環結構與撓部分乘積 | 界內截面 | 自由部分的合成與律（T36） |
