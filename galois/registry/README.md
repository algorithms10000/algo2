# galois/registry — 樣本上下文（真數學物件）與摘要

## 樣本（不是人造資料）

| 名稱 | 數學物件 | 說明 |
|---|---|---|
| `cyclotomic-q8` | ℚ(ζ₈)/ℚ，G ≅ C₂×C₂ | R 由群作用對基底 {1, i, √2, i√2} 的**符號表計算**：(H,F)∈R ⟺ F⊆Fix(H)。 |
| `divisibility` | ℤ 的整除格 | (a,s)∈R ⟺ a \| s；古典「公倍數 ↔ 公因數」伽羅瓦對應。 |
| `two-blocks` | 兩個不交分量 | 驗證 T3 的局部封閉（分量內）與跨分支坍縮（cl=A）。 |

`cyclotomic-q8` 的實作要點（`cyclotomic.mbt`）：
σ(i)=−i、τ(√2)=−√2，故 G 對基底只做變號；於是「g 固定基底元素 b」是純符號判定，
R 的每個元素都由群作用算出，沒有任何手寫邊。

## 已獲得的定理（本資料夾的落點）

樣本本身不新增定理，而是 T1／P5 的**實例見證**：
`|ℭ_A| = |ℭ_S| = |B(K)| = 5`，且 5 個概念即伽羅瓦基本定理的 5 組（子群, 中間體）。

## B0002 追加：擬陣樣本（`matroids.mbt`）

| 名稱 | 構造 | 驗證目標 |
|---|---|---|
| `U24` | 均勻擬陣 U(2,4)（非二元，迴路直接給出） | \|𝒞\|=4、\|ℱ\|=6、r=2 |
| `M(K3)` | 三角形圖擬陣（GF(2) 關聯矩陣） | \|𝒞\|=1、\|ℱ\|=5 = Bell(3) |
| `M(K4)` | K₄ 圖擬陣（4 三角形 + 3 四環） | \|𝒞\|=7、\|ℱ\|=15 = Bell(4) |
| `Fano` | PG(2,2)：F₂³ 的 7 個非零向量 | \|𝒞\|=14、\|ℱ\|=16、r=3 |
| `interval-4` | 負控制：區間凸包（antimatroid） | `check_exchange` 必須 FAIL |
| `Fano*` | F7 的對偶（二元、非正則） | |ℱ| 無獨立公式（登記為 −1）；|𝒞|=7 = 超平面補集 |
| `U(3,5)` | 均勻擬陣 | |ℱ|=2+C(5,1)+C(5,2)=17、|𝒞|=5 |
| `M(K4)*` | K₄ 的餘圖擬陣（正則） | 自對偶故 |ℱ|=15、|𝒞|=7（= 7 個割） |

## B0004 追加：撓群配對生成的上下文（`paley.mbt`）

`paley-13`：A = S = 𝔽₁₃ 的 13 個點，關係 = P(13) 的**閉鄰域**（i~j ⟺ i=j 或 χ₁₃(i−j)=1；
鄰接矩陣直接取自 `@elliptic.paley_adjacency(13)`，其來源是 E[13] 的 Weil 配對二次特徵）。
實測 |R| = 91、|ℭ_S| = |ℭ_A| = 210、DG 基 |Σ| = 221（A3′ 走 431 步 vs 暴力 8191），
B0001 A6 8/8、A3′ 4/4 全通過。取閉鄰域而非純鄰接，是為了讓每列唯一含有自己的索引（X3 分離性）。

## B0003 追加：同餘子群上下文（`congruence.mbt`）

`congruence-12`：A = S = { Γ₀(2), Γ(2), Γ₀(3), Γ₁(3), Γ(3), Γ₀(4), Γ₁(4), Γ(4), Γ₀(6), Γ₁(6), Γ(6), SL₂(ℤ) }，
R = 包含關係，**由 SL₂(ℤ/12) 的暴力判定給出**。實測 |R| = 47、|ℭ_S| = 13、DG 基 |Σ| = 16，
B0001 的 A6 8/8、A3′ 4/4 全通過。Γ₁(2) 被排除，因 φ(2)=1 ⇒ Γ₀(2)=Γ₁(2)（會破壞分離性）。

## A3′ 追加：整除上下文族（`registry.mbt` 的 `registered_dg()`）

| 名稱 | N | \|A\|=\|S\| | \|Σ\| | 用途 |
|---|---|---|---|
| `divisors-12` | 12 | 6 | 6 | A3′ vs 暴力 A3 同族核對 |
| `divisors-180` | 180 | 18 | 27 | 同上（2^18 仍可暴力） |
| `divisors-240` | 240 | 20 | 30 | 同上（暴力的最後可負擔點） |
| `divisors-420` | 420 | 24 | 38 | 暴力不可行（16,777,215），改用 E16 判定 |

## 已實作的演算法

- `cyclotomic_context / divisibility_context / two_blocks_context`：由數學定義生成 K。
- `summarize(reg)`：一次算出閉集數、概念數、Hasse 邊、\|Σ\|、冗餘公理、A6 報告（`summary.mbt`）。
- 【B0002 延伸】`registered_matroids_ext()`、`lookup_matroid_ext(name)`、`all_matroid_names()`、
  `extension_summary(reg)`、`extension_global_report()`、`check_registered_expectations()`、`census_summary(n)`。
- 【B0002】`matroid_summary(reg, with_inherit)`、`interval_summary(n)`：擬陣摘要＋A12 檢核＋（可選）B0001 繼承（`matroids.mbt`）。

## 依賴關係

```
registry ──▶ lattice ──▶ galois ──▶ context ──▶ bitset
registry ◀── cmd/main
```

## 接口

`registered() / lookup(name) / registered_names() / summarize(reg) / Registered::make(...)`
【A3′】`registered_dg() / lookup_dg(name) / registered_dg_names() / divisor_context(value)`
【B0002】`registered_matroids() / lookup_matroid(name) / registered_matroid_names() / matroid_summary(reg, with_inherit) / interval_summary(n)`
