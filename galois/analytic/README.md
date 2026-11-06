# galois/analytic/ — B0009 近似單位元、投影與非交換投影、自由同倫不變性

本套件是 R11 的實作。數學合約正本是 [`docs/B0009-定理體系.md`](../../docs/B0009-定理體系.md)；
登記表在 `algorithm.xlsx` 的「B0009 分析」工作表。

## 已得定理（全部由 `moon run cmd/main -- analytic` 逐條執行，9/9）

| 編號 | 定理 | 落點 |
|---|---|---|
| T64 | 近似單位元：N=5，‖e_nS − S‖₂² = N−1−n = 4,3,2,1,0；‖(1−e_n)P₂‖₂² = 2,1,0,0,0；遞增 | `check_approx_identity` |
| T65 | **負控制**：么代數上 ‖e_n·1 − 1‖₂² = N−n = 5,4,3,2,1 全 > 0 ⇒ {e_n} 不是么代數的近似單位元 | `check_approx_negative` |
| T66 | 投影與 K₀：E₁₁ 與 q=[[9/25,12/25],[12/25,16/25]] 皆秩一冪等，正交和跡 3，[p]+[q]=[p⊕q] | `check_projection_k0` |
| T67 | Murray–von Neumann：p ~ q 的顯式部分等距；{E₁₁,E₂₂} 生成維度 2、{E₁₁,q} 生成維度 4 | `check_mvn` |
| T68 | 非交換投影：pq ≠ qp、pq 非投影、tr(pq)=9/25、‖pq−qp‖₂²=288/625、cos²θ=9/25 | `check_noncommutative` |
| T69 | 冪等元同倫（A²=0）：[1 1;0 0] → [1 1/2;0 0] → [1 0;0 0]，每步冪等、秩恆 1 | `check_idempotent_homotopy` |
| T70 | 自由同倫不變性：K₀ 秩在族上恆定；Cayley 正交族 det≡1、diag(−1,1) det=−1 ⇒ K₁ 兩分量 | `check_projection_homotopy` |
| T71 | **負控制**：A²=0 不可省（用 antisym_12 代入 ⇒ 冪等性失效）；不同秩不同類 | `check_homotopy_negative_controls` |
| T72 | 秩的兩套演算法：`rmat_rank`（ℚ 高斯）× `@cyclic.rank_q`（F_p 高斯）在 6 個樣本上一致 | `check_rank_cross` |

## 已實作演算法

| 編號 | 演算法 | 位置 | 成本 |
|---|---|---|---|
| A57 | 有理線性代數：Rat 四則＋gcd 歸一、RMat 秩／det／inv／trace／Frobenius 範數、通分轉整數 | `rat.mbt` | O(n³) |
| A58 | 近似單位元與壓縮：`diag_proj`、閉式 `approx_conv_shift_sq`、么代數負控制、`approx_rest_sq` | `approx.mbt` | O(N³) |
| A59 | 投影與主角度：秩一投影建構（3-4-5）、正交和判準、MvN、cos²θ 與交換子範數 | `projection.mbt` | O(n³) |
| A60 | 冪等元路徑與 Cayley 族：`idem_path`、`nilpotent_12`／`antisym_12`、`cayley_orth`、K₁ det | `homotopy.mbt` | O(n³) |

## 視角依賴關係圖

```
rat.mbt（Rat／RMat：精確有理矩陣、秩、det、inv、Frobenius 範數）
   ├──▶ approx.mbt（diag_proj、shift_matrix、閉式收斂、么代數負控制、壓縮）
   ├──▶ projection.mbt（proj_e11／proj_angled、block_diag、generated_dim／span_dim_rmat）
   │        └──▶ homotopy.mbt（idem_path、nilpotent_12／antisym_12、square_zero、cayley_orth）
   └──▶ checks.mbt（T64–T72、analytic_report()、analytic_table_render()）
            └──▶ 交叉見證：@cyclic.rank_q（F_p 高斯）／@galois.Check、Report
```

## 動線（怎麼跑）

```bash
cd galois
moon run cmd/main -- analytic    # T64–T72 全部檢核（9/9）
moon run cmd/main -- anatable    # 近似單位元收斂表＋非交換投影數字＋同倫族
```

## 接入與輸出接口

* **接入**：`rat_new`／`rat_of_int`（自建有理數）、`rmat_of_int`（自建矩陣）、`diag_proj`、
  `shift_matrix`、`proj_angled`、`nilpotent_12`、`antisym_12`。
* **輸出**：`analytic_report() -> @galois.Report`、`analytic_table_render() -> String`；
  單項可直接呼叫 `rmat_rank`／`rmat_det`／`rmat_inv`／`rmat_norm2`／`check_*` 家族。

## 注意（陷阱）

1. 冪等元路徑 e(t) = (1+tA)e(1−tA) **必須 A² = 0**；用 `antisym_12`（A² = −1）代入得非冪等元（BUG-27／T71）。
2. 全部計算在 ℚ 上；不要為了「快」改成浮點——判準是「是否等於 288/625」這種精確值。
3. MoonBit 泛型用方括號 `Array[Rat]`；`Int32`／`Int64` 不可直接比較（BUG-25、BUG-26）。
