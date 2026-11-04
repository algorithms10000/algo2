# galois/braid — 拓撲辮群 B_n 及其表示（B0005）

對應 `../../docs/B0005-定理體系.md`：**D-B1–D-B6、P-B1–P-B4、T22–T24、A29–A30**。
檢核：`moon run cmd/main -- braid` ⇒ **27/27 通過**。

## 已獲得的定理

| 編號 | 內容 | 落點 |
|---|---|---|
| **T22** | 置換商是滿射：π: B_n ↠ S_n，σ_i ↦ (i, i+1)；⟨σ₁,…,σ_{n−1}⟩ 在 S_n 中生成全群（\|im\| = n!，n = 2..6）；σ_i 在置換層滿足辮關係 | `check_permutation_quotient`、`permutation_braid_relation` |
| **T23** | Burau β_n: B_n → GL_n(ℤ[t^{±1}]) 是表示：辮關係與遠處交換律在多項式層**精確**成立（n = 2..6）；行列式是乘法指標 `det β_n(w) = (−t)^{exp w}`；長度 ≤ L 內無偽核（**有界**陳述，另附界限數字） | `check_burau_representation`、`check_burau_determinant`、`check_burau_no_fake_kernel` |
| **T24** | B_3 → PSL₂(ℤ) 接縫：σ₁ ↦ T、σ₂ ↦ STS 給出同態，中心 ⟨(σ₁σ₂)³⟩ ↦ ±I；其像在 SL₂(ℤ/n) 的投影**生成全群**（n = 2..12）⇒ B_3 ↠ PSL₂(ℤ/n)，即 B0003 的 Γ(n) 是這條滿射的核 | `check_b3_to_psl`、`check_b3_image_generates`、`psl_image_generates_sl2` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A29 | 辮字引擎：`BraidWord`（生成元序列、逆、接合、指數和）、置換商、BFS 生成置換群、群階 = n! 判定、B_3 的 2×2 整數像與 PSL₂ 意義下的 ±I 等價 | 字長 O(L)；BFS O(n!·n) |
| A30 | Laurent 多項式（`t^{±1}`、BigInt 係數、規範形）＋ n×n Laurent 矩陣乘法／餘因子行列式；Burau 生成元與其逆、字的像、`t = −1` 特化、長度 ≤ L 的偽核搜索 | 矩陣 O(n³·terms²)，偽核 O((2(n−1))^L) |

## 視角依賴關係圖

```
braid ──▶ galois（Check / Report）
braid ──▶ modular（sl2_make、同餘子群指數；B_3 影像 mod n）
cmd/main ──▶ braid（子命令 braid）
docs/B0005-定理體系.md §2–§4 ──▶ 本套件
```

## 動線與接口

- 辮字：`bw_gen(n, i, inv)`、`bw_make(n, letters)`、`bw_empty(n)`、`BraidWord::concat/inverse/length/exponent_sum`。
- 置換：`perm_identity`、`transposition`、`perm_mul`、`perm_key`、`word_permutation`、`generated_permutation_count`、`factorial`、`permutation_braid_relation`。
- Burau：`lp_zero/lp_one/lp_t/lp_const/lp_add/lp_mul/lp_sub/lp_neg/lp_at_minus_one/lp_eq/lp_render`、
  `burau_generator`、`burau_inverse`、`burau_of_word`、`lm_mul`、`lm_det`、`burau_braid_relation`、`burau_commutes`、
  `burau_fake_kernels`、`burau_specialize_minus_one`。
- B_3 → PSL₂：`psl_image(i)`、`psl_image_of_word`、`mat2_mul`、`mat2_is_pm_identity`、`mat2_same_pm`、`psl_image_generates_sl2(n)`。
- 檢核：`braid_report()`（27 條）。

## 已知修正（保留在程式碼註解）

- **R7-ERR-1**：B_3 → PSL₂(ℤ) 的生成元影像必須是 {T, STS}（或等價的 {S, ST}），首版曾用 {T, S} ⇒ 辮關係不成立。
- **BUG-9**：PSL₂ 的相等是「差 ±I」，逐元素比較會讓 σ₁σ₂σ₁ 與 σ₂σ₁σ₂ 誤判不等 ⇒ `mat2_same_pm`（且必須在首次使用前定義）。
