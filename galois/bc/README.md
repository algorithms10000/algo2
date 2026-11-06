# galois/bc/ — B0010 用已實作的定理與演算法論證古典 Baum–Connes 猜想

本套件是 R11 的實作。數學合約正本是
[`docs/B0010-Baum-Connes-論證.md`](../../docs/B0010-Baum-Connes-論證.md)；
登記表在 `algorithm.xlsx` 的「B0010 Baum–Connes」工作表。

**一句話說清楚它做什麼**：把 Baum–Connes 猜想在「兩側都能完整算出」的樣本上**判定為真**
（不是引用文獻：左側 R(G)、右側 K₀(ℂG)、跡泛函、特徵正交性、Wedderburn 全部精算對撞），
並把界外逐條登記成 `decides = false` + 兩個可能值——界外不得以綠燈冒充（A-K5）。

## 已得定理（全部由 `moon run cmd/main -- bc` 逐條執行，10/10）

| 編號 | 定理 | 落點 |
|---|---|---|
| T81 | 有限群 Baum–Connes：μ₀ : R(G) → K₀(ℂG) 是同構（ℤ/2、V₄、S₃、D₈、Q₈；#irr = #cc，秩 ℚ/F_p 一致，Σdim²=\|G\|） | `check_bc_finite` |
| T82 | 特徵正交性 Σ_C \|C\|χ_Vχ_W = \|G\|δ ⇒ μ 單射；**負控制**：無權重版本對 S₃(3≠6)、D₈(4≠8)、Q₈ 失敗 | `check_bc_orthogonality` |
| T83 | 循環群 ℤ/n：μ 矩陣 = DFT，Σ_k ζ^{km} = nδ_{m0} 精算（n=2..12）；**負控制**：ζ↦1 崩潰 | `check_bc_cyclic` |
| T84 | A₄（ℤ[ω] 特徵表）：2 倍展開秩 8 = 2·4、Gram = 12·I；**負控制**：只用 ℚ（共軛合併）掉到 6 | `check_bc_a4` |
| T85 | 接縫：S_n 的 #cc（暴力）= p(n) = rank K₀(C*(S_n))、Σd_λ² = n!；SL₂(𝔽₂) ≅ S₃ 兩路徑同秩 | `check_bc_seam_sym` |
| T86 | Kadison–Kaplansky 截面：ℂ[ℤ] 無非平凡冪等元（次數論證＋243 個窮舉）；**負控制** ℂ[ℤ/2] 有 (1+g)/2 | `check_bc_kadison` |
| T87 | 接縫 B0006：ℤ 的組裝兩側 (ℤ,ℤ)（C*_rℤ = C(S¹)，Toeplitz 六項正列＋指標／繞數） | `check_bc_seam_infinite_cyclic` |
| T88 | 界外清單 BC1–BC8 合規：status／evidence／界內截面／**兩值相異** | `check_bc_boundary` |
| T89 | 全局公理伽羅華對應：H ⊆ H′ ⟺ Fix(H) ⊇ Fix(H′)、H ↦ Fix(H) 單射、dim = [G:H]；**負控制**：只用維度在 V₄ 失效 | `check_bc_global_galois` |
| T90 | 局部公理由代理決定：8 條局部公理由引擎**當場重算**裁決；8 條全局公理 `decides = false` | `check_bc_local_axioms` |

## 已實作演算法

| 編號 | 演算法 | 位置 | 成本 |
|---|---|---|---|
| A65 | 組裝映射矩陣引擎：特徵表 → 加權 Gram、兩套秩演算法、Wedderburn 檢查、判準合成 | `assembly.mbt` | O(r³ + r²c) |
| A66 | ℤ[ω] 展開與 A₄：a+bω 乘／共軛、r×c → 2r×2c 區塊展開、有理特徵表合併 | `omega.mbt` | O(r²c²) |
| A67 | DFT 正交性（分圓）：Σ_{k<n} ζ^{km} 的精算累加（靠 Φ_n 降次），逐座標比較 nδ_{m0} | `cyclicbc.mbt` | O(n²·φ(n)) |
| A68 | 子群格與不動子空間：循環子群窮舉＋去重、Fix(H) 線性條件、堆疊秩判包含 | `subgroup_lattice.mbt` | O(s²·φ(n)³) |
| A69 | 公理裁決與界外清單：局部公理逐樣本重算、界外合規判定、Laurent 冪等元窮舉 | `localaxioms.mbt`／`laurent.mbt` | O(3^{2k+1}+k²) |

## 樣本（兩側算式並列）

| 群 | \|G\| | 左側 R(G) | 右側 K₀(ℂG) | rank(ℚ/F_p) | Σdim² | 判定 |
|---|---|---|---|---|---|---|
| ℤ/2 | 2 | ℤ² | ℤ² | 2 / 2 | 2 | 同構 |
| V₄ | 4 | ℤ⁴ | ℤ⁴ | 4 / 4 | 4 | 同構 |
| S₃ | 6 | ℤ³ | ℤ³ | 3 / 3 | 1+1+4=6 | 同構 |
| D₈ | 8 | ℤ⁵ | ℤ⁵ | 5 / 5 | 4+4=8 | 同構 |
| Q₈ | 8 | ℤ⁵ | ℤ⁵ | 5 / 5 | 4+4=8 | 同構 |
| ℤ/n（2..12） | n | ℤⁿ | ℤⁿ | DFT 正交 | — | 同構 |
| A₄ | 12 | ℤ⁴（ℤ[ω]） | ℤ⁴ | 8 = 2·4 | 1+1+1+9=12 | 同構 |
| ℤ | ∞ | (ℤ,ℤ) | (ℤ,ℤ) | — | — | 同構（μ = id） |

## 界外清單（BC1–BC8，全部不決定）

| 編號 | 命題 | 現況（2026-09 快照） |
|---|---|---|
| BC1 | 無係數 BC 對任意 locally compact 群 | 開放，無已知反例（arXiv:2610.01802） |
| BC2 | 有係數版 | **已否**（HLS02） |
| BC3 | μ 單射 ⇒ Novikov 高階簽名 | 已證（條件式） |
| BC4 | SL_n(ℤ), n ≥ 3 的滿射性 | 開放（單射已知） |
| BC5 | 粗 Baum–Connes | **已否（奇度）**（arXiv:2504.21811） |
| BC6 | a-T-menable／雙曲／almost connected | 已證 |
| BC7 | 2026-09 的 AI 反例宣稱 | 宣稱（未同儕審查），不採用 |
| BC8 | 無撓對 Kadison–Kaplansky 的必要性 | 已證（本引擎 T86 獨立核對代數截面） |

## 視角依賴關係圖

```
assembly.mbt（FinGroup、加權／無權重 Gram、mu_rank_rat／mu_rank_modp、bc_assembly_iso、5 樣本）
   ├──▶ omega.mbt（OmegaVal a+bω、A₄ 表、omega_expand r×c、a4_rational_rank 負控制）
   ├──▶ cyclicbc.mbt（cyclo_dft_sum、DFT 正交、ζ↦1 負控制）──▶ @cyclotomic（Φ_n 降次）
   ├──▶ subgroup_lattice.mbt（子群窮舉、fix_rows／fix_dim／fix_included、維度負控制）──▶ @cyclotomic、@analytic
   ├──▶ laurent.mbt（Laurent 多項式、冪等元窮舉、次數論證、ℂ[ℤ/2] 負控制）──▶ @analytic.Rat
   ├──▶ boundary.mbt（BcItem BC1–BC8、合規判定）
   ├──▶ localaxioms.mbt（AxiomRecord、decide_local 重算、local_axioms_verified）
   └──▶ checks.mbt（T81–T90、bc_report()、bc_table_render()）
接縫：@kk（六項正合列、指標／繞數、k_of_circle、k_of_symmetric_group）、
      @braid（S_n 置換暴力）、@modular（SL₂(𝔽₂)）、@cyclic.rank_q、@analytic.rmat_rank
```

## 動線（怎麼跑）

```bash
cd galois
moon run cmd/main -- bc        # T81–T90 全部檢核（10/10）
moon run cmd/main -- bctable   # 兩側算式並列表＋界外清單（含兩個可能值）
```

## 接入與輸出接口

* **接入**：`groups_int()`（自建有限群只要給 `FinGroup{name, order, class_sizes, table}`）、
  `a4_table()`／`omega()`、`bc_cyclic_iso(n)`、`subgroups_of_units(n)`、`bc_items()`。
* **輸出**：`bc_report() -> @galois.Report`、`bc_table_render() -> String`、
  `bc_assembly_iso(g) -> Bool`、`check_global_galois_correspondence(n)`、
  `local_axioms()`／`global_axioms()`（各為 `Array[AxiomRecord]`）。
* **下游**：目前無（B0010 是終點）；`docs/B0010` 的表全部由這裡的函式印出。

## 注意（陷阱）

1. 「μ 單射」的實質理由是**帶類大小權重**的正交性；把權重當 1 會讓 S₃ 的 ⟨triv,triv⟩ = 3 ≠ 6（T82）。
2. ℤ[ω] 的秩必須**展開成 2 倍**再算；只在 ℚ 上算會少一個不可約表示（T84）。
3. 伽羅華對應用**堆疊秩**判子空間包含；只用維度在 V₄ 的三個二階子群上會誤判（T89）。
4. 界外條目的兩個可能值**必須相異**，否則「不決定」退化成恆真（T88）。
5. 局部公理的裁決不許手寫：`local_axioms_verified()` 會當場重算（T90）。
