# galois/jacobian — 圖的雅可比簇（沙堆群）J(G)（B0005）

對應 `../../docs/B0005-定理體系.md`：**D-J1–D-J7、P-J1–P-J5、T25–T31、A31–A35**。
檢核：`moon run cmd/main -- jacobian` ⇒ **54/54 通過**；`moon run cmd/main -- jtable`／`-- arf` 另給表格與計數。

## 已獲得的定理

| 編號 | 內容 | 落點 |
|---|---|---|
| **T25** | \|J(G)\| = τ(G)（Matrix–Tree 的群論版）：三條**獨立**路徑——Bareiss 餘子行列式、生成樹暴力枚舉、子式 gcd 不變因子——在 K₃/K₄/K₅/C₄/C₅/θ/蝴蝶結上給出同一個數 | `check_jacobian_order`、`spanning_trees_by_det`、`spanning_trees_bruteforce`、`jacobian_order` |
| **T26** | 不變因子結構：J(K_n) ≅ (ℤ/n)^{n−2}（n = 3,4,5）；與**外部登記的** Smith 正規形逐一比對（K₃=(1,3)、K₄=(1,4,4)、K₅=(1,5,5,5)、C₄=(1,1,4)、C₅=(1,1,1,5)、θ=(3)、蝴蝶結=(1,1,3,3)）；\|J[2]\| = ∏ gcd(dᵢ,2) = 2^{β₁} | `check_complete_graph_jacobian`、`check_registered_invariants`、`check_two_torsion` |
| **T27** | 圈秩的兩條路徑：β₁ = \|E\| − \|V\| + c = \|E\| − rank_ℚ(L)（7 個樣本全一致）。**並證僞**：用 rank_{𝔽₂}(L) 取代 rank_ℚ(L) 是錯的（BUG-8，C₅ 即反例） | `check_cycle_rank`、`rank_over_q`、`laplacian_rank_mod2` |
| **T28** | Riemann–Roch：r(D) − r(K−D) = deg D − g + 1（g = \|E\| − \|V\| + 1）；在 K₃/C₄/θ/K₄ 上**全部**除子枚舉，反例 0 | `check_riemann_roch`、`divisor_rank`、`riemann_roch`、`canonical_divisor` |
| **T29** | theta 特徵／Arf：二次細化 q = q₀ + ℓ 的有效性判定；#{Arf=0} = 2^{g−1}(2^g+1)、#{Arf=1} = 2^{g−1}(2^g−1)（g = 1,2,3：3/1、10/6、36/28）；Arf 在 Sp_{2g}(𝔽₂) 下不變（g = 1,2 的**全部**矩陣枚舉） | `check_arf_counts`、`check_arf_invariance`、`count_refinements`、`arf_of_pullback` |
| **T30** | 生成樹計數的第三條路徑：刪縮遞迴 τ(G) = τ(G−e) + τ(G/e) 與 \|J(G)\| 一致（7 個樣本） | `check_deletion_contraction`、`edge_delete`、`edge_contract`、`tau_deletion_contraction` |
| **T31** | 超立方體網絡 Q_n：τ(Q₂)=4、τ(Q₃)=384、τ(Q₄)=42 467 328（行列式路徑對登記值）；不變因子 Q₂=(1,1,4)、Q₃=(1,1,1,1,2,8,24)；Q₂/Q₃ 另以刪縮遞迴互印 | `check_hypercube_tau`、`check_hypercube_tau_dc`、`check_hypercube_invariants`、`hypercube` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A31 | `BigMat`（BigInt 矩陣）＋ Bareiss 無分數行列式 ＋ 全子式 gcd 不變因子 ＋ Laplacian 建構 ＋ 連通分量 ＋ 圈秩 ＋ 有理秩 | 行列式 O(n³)；不變因子 O(Σ_k C(n,k)²·k³)（實用上限 n ≤ 8） |
| A32 | 生成樹三路徑：Bareiss 餘子、邊集暴力枚舉、刪縮遞迴；`jacobian_order` = 行列式路徑 | O(n³) / O(2^{\|E\|}·n) / O(2^{\|E\|}) |
| A33 | 除子引擎：`in_laplacian_image`（Σx = 0 ＋ Cramer 全整數）、有效等價 `eff`、除子秩 `divisor_rank`、Riemann–Roch 全枚舉、典範除子 | 線性等價 O(n⁴)；秩 O(C(E+n,n)·n⁴)（g ≤ 3 可行） |
| A34 | 𝔽₂ 交錯形式、二次細化（q₀ + ℓ）、Arf 不變量、細化計數、Sp_{2g}(𝔽₂) 全矩陣枚舉與拉回 | O(2^{2g}·g) 每個 ℓ；全群 O(\|Sp\|·2^{2g})（g ≤ 2） |
| A35 | 超立方體 Q_n 建構（𝔽₂ⁿ 位元串、翻位元求鄰）＋ 三條 τ 路徑中的可行者 | O(2ⁿ·n) 建圖 |

## 視角依賴關係圖

```
jacobian ──▶ galois（Check / Report）
cmd/main ──▶ jacobian（子命令 jacobian / jtable / arf）
docs/B0005-定理體系.md §5–§9 ──▶ 本套件
（不依賴 braid：辮群走 `braid` 套件；兩者在 B0005 中以「表示 ↔ 不變量」並置）
```

## 動線與接口

- 矩陣：`bigmat`、`bigmat_of`、`bigmat_minor`、`det_bareiss`、`gcd_big`、`minor_gcd`、`invariant_factors`、`rank_over_q`。
- 圖：`Graph`（`n`、`edges`，允許重邊）、`Graph::num_vertices/num_edges/components/cycle_rank`、`laplacian`、`laplacian_rank_mod2`、`edge_delete`、`edge_contract`、`hypercube(n)`、`jump_bit(x,i)`。
- 群：`jacobian_order`、`spanning_trees_by_det`、`spanning_trees_bruteforce`、`tau_deletion_contraction`、`compositions`。
- 除子：`in_laplacian_image`、`is_effectively_equivalent`、`divisor_rank`、`canonical_divisor`、`riemann_roch`、`render_divisor`、`RRResult`。
- 二次型：`symplectic_pair`、`base_quadratic`、`refined_quadratic`、`popcount_parity`、`is_quadratic_refinement`、`arf_invariant`、`count_refinements`、`expected_arf0/1`、`F2Mat`、`is_symplectic`、`arf_of_pullback`、`all_f2_matrices`。
- 檢核：`jacobian_report()`（54 條）、`sample_graphs()`。

## 已知修正（保留在程式碼註解）

- **BUG-7**：不可把「\|J[2]\| = 2^{β₁}」當定理（K₄：4 vs 8）⇒ 降級為整除不等式 `\|J[2]\| \| 2^{β₁}`。
- **BUG-8**：圈秩不可用 rank_{𝔽₂}(L)——L mod 2 會退化（C₅：rank_{𝔽₂}=1 而 rank_ℚ=4）；順帶修掉 BigInt 負餘數取模。
- **BUG-10**：`in_laplacian_image` 漏驗 Σx = 0 ⇒ 假反例；正解為「Σx = 0 且 Cramer 解全整數」。
- **BUG-11**：手寫交換式 Smith 正規形會 ZeroDivision ⇒ 改用子式 gcd 版 dₖ = gₖ/gₖ₋₁（實用上限 n ≤ 8）。
- **BUG-12**：`jacobian_order` 走子式 gcd，Q₄ 的 16×16 是 C(32,16) 個子式 ⇒ 超立方體檢核只走行列式路徑，且不呼叫 `jacobian_order`。
