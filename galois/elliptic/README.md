# galois/elliptic — 橢圓曲線撓群 E[n] ≅ (ℤ/n)² 及其衍生結構（B0004）

對應 `../../docs/B0004-定理體系.md`：**D-E1–D-E7、P-E1–P-E5、T15–T21、A23–A28**。

## 已獲得的定理

| 編號 | 內容 | 落點 |
|---|---|---|
| **T15** | E[n] ≅ (ℤ/n)² 的三條等價刻劃（群論／完美配對／ψ_n 的古典次數） | `divpoly.mbt`、`weil.mbt`、`check_div_poly` |
| **T16** | 軌道計數 = B0003 的同餘指數：ψφ = [SL₂:Γ₁] = #{ord=n}、ψ = [SL₂:Γ₀] = #循環子群、ψφn = [SL₂:Γ] = #辛基；另證 |GL₂| = [SL₂:Γ]·φ | `check_orbit_equals_index` |
| **T17** | Galois 等變 e(MT,MS) = det(M)·e(T,S) ⇒ 像在 GSp₂ = GL₂，保配對者恰為 SL₂ | `check_equivariance` |
| **T18** | 配對的二次特徵 ⇒ Paley 圖（q≡1 mod 4，srg、可遷、自補）／Paley 競賽（q≡3，雙正則）；Delsarte ⇒ R(ω+1,α+1) > q | `paley.mbt` |
| **T19** | 鏡像對稱：χ(det) 為平方 → 保色、非平方 → 翻色 ⇒ 圖自補、競賽反向同構 | `self_complementary_witness`、`reversal_witness` |
| **T20** | 撓群線性擬陣：秩 2、p+1 個平行類、簡化 = U(2,p+1)；p=2 時 = M(K₃) | `matroid.mbt` |
| **T21** | 團複形 Δ(P(q)) 的 GF(2) 同調；Euler–Poincaré 兩路徑一致；β₀ = BFS 分量數 | `complex.mbt` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A23 | BigInt 稀疏雙變數多項式 ＋ ψ_n 遞歸（「除以 2y」整除性判定 ⇒ ψ_n ∈ ℤ[x,y] 可執行見證） | O(n·terms²) |
| A24 | E[n] 群律、階、循環子群規範化、Weil 配對指數、GL₂ 作用、辛基計數 | O(n⁴) |
| A25 | 𝔽_p 線性擬陣：秩、迴路、平坦集、平行類、簡化均勻性 | 秩 O(k²)；列舉 O(2^k·k²) |
| A26 | ℙ¹(𝔽_q) 的 χ 著色、Paley 圖／競賽、ω/α 回溯、可遷／自補／反向見證 | 回溯 O(2^q) |
| A27 | 團列舉 ＋ GF(2) 邊界消去 ＋ Betti／Euler ＋ BFS 分量 | O(f²·f/64) |
| A28 | `paley_context`（在 `registry/`）：P(13) 閉鄰域 → 形式上下文 → A6/A3′ | 同 `lattice` |

## 依賴關係

```
elliptic ──▶ modular（ψ、φ、指數公式、sl2_group、gcd、norm_mod）
elliptic ──▶ galois（Check / Report）
registry/paley.mbt ──▶ elliptic, lattice, galois, context
cmd/main ──▶ elliptic, registry, modular, lattice, galois, context
```

## 動線與接口

- 除多項式：`div_polys(a,b,nmax)`、`np_reduce`、`np_deg_x`、`np_y_degrees`、`expected_psi_degree`。
- 撓群：`e_group(n)`、`EPt::order/add/scale/neg`、`weil_exp`、`is_basis`、`count_points_of_order`、
  `count_cyclic_subgroups`、`count_det_one_bases`、`count_all_bases`、`gl2_group`、`mact`、`stabilizer_order_of_line`。
- Paley：`projective_points`、`signature_matrix`、`paley_adjacency`、`paley_tournament`、`clique_number`、
  `complement`、`non_square`、`translation_invariant`、`self_complementary_witness`、`reversal_witness`、
  `is_doubly_regular`、`is_strongly_regular`、`max_transitive_subtournament`。
- 複形：`all_cliques`、`faces_by_dim`、`boundary_rank`、`flag_homology`、`components_of`。
- 擬陣：`rank_mod_p`、`mod_inverse`、`torsion_vectors`、`parallel_class_count`、`circuits_bruteforce`、
  `flats_bruteforce`、`simplification_is_uniform`。
- 檢核：`elliptic_report(nmax)`（69 條）。

## 已知修正（保留在程式碼註解）

- **BUG-4**：ψ_n 遞歸必須**先**做「除以 2y」再化簡 y² = h；首版反過來，n = 5 起整數性判定崩潰。
- **BUG-5**：循環子群規範鍵只能取**生成元**倍數；含 O 或非生成元會讓子群塌成一個。
- **BUG-6**：撓群擬陣迴路數 = (p+1) + (p−1)³·C(p+1,3)（p 奇），p = 2 時為 1。
