# galois/matroid — 交換閉包系統（擬陣）與 Moore 實現（B0002）

對應 `../../docs/B0002-定理體系.md`：**D-B1–D-B7、X5–X7、P-B1–P-B4、T5–T8、A8–A14**。

## 已獲得的定理（本資料夾的落點）

| 編號 | 名稱 | 落點 |
|---|---|---|
| P-B1、P-B2 | 閉包四性、秩—閉包對偶 | `matroid.mbt`（`closure`）、`checks.mbt`（雙路徑對照） |
| P-B3、P-B4 | 極小相依＝迴路、平坦族為 Moore 族 | `checks.mbt`、`flats.mbt` |
| T5 | 三公理等價（閉包／迴路／秩） | `gf2.mbt` ＋ `matroid.mbt` ＋ `checks.mbt` 三路徑互比 |
| T6 | 平坦格＝幾何格（底元 = cl(∅)） | `flats.mbt`（`check_geometric` 四項） |
| T7 | Moore 實現／提升（ℱ → K_ℱ，ℱ = ℭ_A） | `realize.mbt`（`check_realization`、`check_b0001_inheritance`） |
| T8 | 可判定性與負控制（檢核器不得恆真） | `checks.mbt`（`check_exchange`）、`antimatroid.mbt` |

## B0002 延伸（`minors.mbt`、`tutte.mbt`、`classify.mbt`、`checks2.mbt`）

| 編號 | 內容 | 落點 |
|---|---|---|
| D-B8／A15 | minor（刪除、壓縮、一般 M/D.C；秩公式） | `minors.mbt` |
| D-B9／T9 | 二元 ⟺ 無 U(2,4) minor；**兩條獨立路徑**：禁 minor vs 基本迴路顯式 GF(2) 構造 | `classify.mbt`、`checks2.mbt` |
| T9′ | 正則 ⟺ 無 U(2,4)、F7、F7* minor；F7 **二元但非正則** | `classify.mbt`、`checks2.mbt` |
| D-B10／T10 | 對偶 r*(X)=|X|−r(E)+r(E∖X)；(M*)*=M；餘迴路=超平面補集；對偶平坦秩判準；U(r,n)*≅U(n−r,n)；T_{M*}(x,y)=T_M(y,x)；M(K₄) 自對偶 | `minors.mbt`、`checks2.mbt` |
| D-B11／T12 | Tutte 多項式（刪除–壓縮 vs 子集和）、特化、χ = (−1)^r T(1−λ,0)、Whitney P(G,λ)=λ^{c}χ、χ(F7)=(λ−1)(λ−2)(λ−4) | `tutte.mbt`、`checks2.mbt` |
| T11／T11′ | |ℱ(U(r,n))| = 2+Σ_{1≤k<r}C(n,k)；小型擬陣普查（C1–C3 與 I1–I3 兩路線） | `classify.mbt` |

普查實測：n=2/3/4/5 → 5/16/68/406 個擬陣（兩路線完全一致），同構類 4/8/17/38，
非二元 0/0/**1（=U(2,4)）**/32。n=5 的 406 個擬陣上「禁 minor 判準」與「基本迴路構造」**0 次分歧**。

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A8 | `Matroid::closure`（迴路消去） | O(\|𝒞\|·n·\|cl(X)\|) |
| A9 | `Matroid::rank` / `independent`（貪心） | O(n·\|𝒞\|·n) |
| A10 | `Matroid::flats` / `check_geometric` | O(2ⁿ·closure + \|ℱ\|²·closure) |
| A11 | `context_of_moore_family` / `moore_family_of_context` / `without_empty` | O(\|ℱ\|·n) |
| A12 | `matroid_report`（8 條）／`check_b0001_inheritance`（K_ℱ* 上 13 條） | 見各檢核 |
| A13 | `rank_gf2` / `circuits_from_gf2` / `graphic_columns` / `fano_columns` | 秩 O(n·⌈m/64⌉)；迴路 O(2ⁿ·n·r·⌈m/64⌉) |
| A14 | `check_exchange`（對任意閉包 oracle 搜反例） | O(2ⁿ·n²) |
| A15 | `delete_at` / `contract_at` / `minor_of` | O(2^k·rank) |
| A16 | `dual` / `cocircuits` / `isomorphic` / `has_minor_in` | O(2ⁿ·rank) / O(3ⁿ·n!) |
| A17 | `tutte_deletion_contraction` / `tutte_subsets` | O(2ⁿ·rank) / O(2ⁿ·n²) |
| A18 | 特徵／色多項式（定義式、Tutte 路徑、暴力著色） | O(2ⁿ) / O(λ^v) |
| A19 | `all_matroids_by_circuits` / `all_matroids_by_independent_sets` / `isomorphism_classes` | O(Dedekind(n)·n²) |

## 依賴關係

```
matroid ──▶ lattice ──▶ galois ──▶ context ──▶ bitset
matroid ◀── registry ◀── cmd/main
```

## 動線與接口

- 建構：`Matroid::uniform(r,n)`、`Matroid::graphic(name, vertices, edges)`、`Matroid::fano()`、
  `Matroid::from_gf2(name, columns)`、`Matroid::from_circuits(name, n, circuits)`。
- 計算：`closure` / `rank` / `is_flat` / `flats` / `atoms` / `circuit_count`。
- 檢核：`matroid_report`（A12）、`check_b0001_inheritance`（B0001 繼承）、
  `check_exchange`（可套在任意閉包 oracle 上，含負控制）。
- 實現：`context_of_moore_family` 產出 `@context.FormalContext`，可直接餵給 B0001 的 A1–A6。

## 三個實測修正（保留在程式碼註解與 `algorithm.xlsx`「開發期缺陷」頁）

1. **X6 的 R4** 不可寫成 `r({e}) = 1`：擬陣允許環 → 改為 `r(∅)=0` ＋單位增量。
2. **平坦格底元是 `cl(∅)`（環集）**，不是 `∅`：分級性只在底元以上要求。
3. **`K_ℱ` 必然違反 B0001 X2**（空平坦集無見證）→ 增設 `ℱ* = ℱ∖{∅}`，並把此事寫成正面斷言
   `check_empty_flat_support`，而非留下沉默的 FAIL。
