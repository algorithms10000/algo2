# galois/ — B0001 MoonBit 模組（arena/b0001）

本資料夾是 MoonBit 模組根（`moon.mod`）。下面 16 個套件構成 B0001–B0010 的全部實作（`contexts/` 為文件性目錄、`tmp_lab/` 不進交付）。

## 資料夾視角的依賴關係

```
cmd/main ──▶ registry ──▶ lattice ──▶ galois ──▶ context ──▶ bitset
    │             ├──▶ matroid ──▶ lattice/galois/context/bitset（B0002）
    │             ├──▶ modular  ──▶ galois（B0003）
    │             ├──▶ elliptic ──▶ modular, galois（B0004）
    │             ├──▶ braid    ──▶ modular, galois（B0005：辮群）
    │             ├──▶ jacobian ──▶ galois（B0005：圖雅可比簇）
    │             ├──▶ kk       ──▶ braid, modular, context, lattice, galois（B0006：KK）
    │             │              └─ outside.mbt：界外清單 O1–O6（B0007：T48–T50）
    │             ├──▶ hyper    ──▶ kk, galois（B0007：超立方體網絡群 T41–T47）
    │             ├──▶ cyclic   ──▶ galois（B0008：循環同調 T51–T63／內部張量積／漸新態射）
    │             ├──▶ analytic ──▶ galois, cyclic（B0009：近似單位元／投影／自由同倫 T64–T72）
    │             ├──▶ cyclotomic ─▶ galois, analytic, cyclic（B0009：分圓與單位根 T73–T80）
    │             └──▶ bc       ──▶ analytic, cyclic, cyclotomic, kk, braid, modular（B0010：Baum–Connes T81–T90）
    └──────────────────────▶ lattice/galois/modular/elliptic（直接使用）
```

## 本模組已獲得的定理（詳見 ../docs/B0001-定理體系.md）

| 編號 | 定理 | 主要落點 |
|---|---|---|
| X0、L1 | 伴隨律（伽羅瓦對應） | `galois/laws.mbt` |
| T1 | 全局公理伽羅瓦對應（閉包算子、Moore 族、反序格同構） | `galois/closure.mbt`、`galois/laws.mbt` |
| T2 | 重建定理（冗餘判準） | `galois/closure.mbt`（`redundant_axioms`） |
| T3 | 局部性定理（分量分解與坍縮） | `context/components.mbt`、`galois/closure.mbt` |
| T4 | Duquenne–Guiguès 典範基 | `lattice/basis.mbt` |

## B0002 追加（擬陣，見 `matroid/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| X5／X6 | 交換公理、秩公理 | `matroid/checks.mbt` |
| T5 | 三公理等價（閉包／迴路／秩） | `matroid/{matroid,gf2,checks}.mbt` |
| T6 | 平坦格 = 幾何格 | `matroid/flats.mbt` |
| T7 | Moore 實現／提升（ℱ → K_ℱ，B0001 逐字適用） | `matroid/realize.mbt` |
| T8 | 負控制（檢核器不得恆真） | `matroid/antimatroid.mbt` |
| A8–A14 | 迴路閉包、秩、平坦集、實現、檢核、GF(2)、交換反例搜尋 | `matroid/*.mbt` |

## B0003／B0004 追加

| 編號 | 名稱 | 落點 |
|---|---|---|
| T13／T14 | 同餘子群指數公式、X₀(N) 解析不變量 | `modular/`（見 `modular/README.md`） |
| T15–T21 | 撓群 E[n] ≅ (ℤ/n)²、軌道計數＝同餘指數、Galois 等變、Paley/Ramsey、鏡像對稱、撓群擬陣、團複形同調 | `elliptic/`（見 `elliptic/README.md`） |

## B0005 追加（辮群與雅可比簇，見 `braid/README.md`、`jacobian/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| T22 | B_n ↠ S_n（\|im π\| = n!，n = 2..6） | `braid/braid.mbt` |
| T23 | Burau β_n 是表示、det = (−t)^{exp}、界內無偽核 | `braid/burau.mbt` |
| T24 | B_3 → PSL₂(ℤ) → PSL₂(ℤ/n)（n = 2..12），Γ(n) 是這條滿射的核 | `braid/checks.mbt` |
| T25–T31 | \|J(G)\| = τ（三＋一路徑）、J(K_n) ≅ (ℤ/n)^{n−2}、圈秩、Riemann–Roch、Arf、刪縮、超立方體 Q_n | `jacobian/` |

**關鍵接縫**：T24 把 B0003 的 Γ(n) 說成「B_3 ↠ PSL₂(ℤ/n) 的核」，B0005 與 B0003／B0004 在同一條滿射鏈上對齊。

**關鍵接縫**：T16 證明 `[SL₂:Γ₁] = ψφ`、`[SL₂:Γ₀] = ψ`、`[SL₂:Γ] = ψφn` 恰好是
E[n] 上「階為 n 的點」「循環子群」「辛基」的**個數**——B0003 的算術恆等式因此有了軌道意義。

## B0006 追加（真 KK-理論片段，見 `kk/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| T32 | Hilbert 模秩向量 ⇒ K₀(A) = ℤ^r | `kk/hilbert.mbt` |
| T33 | 六項正合列的秩—零化度判準（Toeplitz／分裂擴張＋負控制） | `kk/cstar.mbt` |
| T34 | K₀(O_n) = ℤ/(n−1)（MvN 計算 → coker/ker，三路徑） | `kk/cstar.mbt` |
| T35–T38 | UCT 值表、Kasparov 乘積、KK-等價、穩定性與 Bott | `kk/kasparov.mbt` |
| T39 | index(T_f) = −wind(f)（精確有理＋幅角原理） | `kk/hilbert.mbt` |
| T40 | 與 B0001（理想格 A6/A3′）、B0003（SL₂(ℤ/n) 共軛類）、B0005（S_n）的接縫 | `kk/sym.mbt`、`kk/checks.mbt` |

## B0008 追加（循環同調、內部張量積、漸新態射，見 `cyclic/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| T51／T51b | 8 個樣本代數的單位與結合律 ＋ 負控制（破壞 x·x²=0） | `cyclic/alg.mbt`、`cyclic/checks.mbt` |
| T52 | HH₀ 的兩條算式相等（A/[A,A] 的餘維 = 混複體度 0 同調） | `cyclic/homology.mbt` |
| T53 | b² = 0、bB + Bb = 0、D² = 0（逐度） | `cyclic/homology.mbt` |
| T54 | **HC 兩條路徑**：混複體總同調 = λ-複體 C_n/im(1−τ_n) 的同調 | `cyclic/homology.mbt` |
| T55 | **負控制**：有符號 λ_n = (−1)^n t_n 的 HC 公式失效 | `cyclic/homology.mbt` |
| T56–T59 | 半單（HC_{2k} = 單模個數）、Morita、直和加法性、群代數 HH₀ = 共軛類 | `cyclic/checks.mbt` |
| T60 | 外部張量積乘法性：HH₀(A⊗B)、HC_{2k}(A⊗B) | `cyclic/xprod.mbt` |
| T61／T61b | 內部張量積：單位、**共端 = HH₀**、Hom(A,A) = Z(A) ＋ 么性負控制 | `cyclic/xprod.mbt` |
| T62 | 漸新態射：ASForget／ASIndex／ASBott／ASAssembly | `cyclic/assembly.mbt` |
| T63 | `rank_q`（F_p）與 `rank_exact`（BigInt）交叉一致 | `cyclic/linalg.mbt` |
| A52–A56 | 精確秩、桶複體／Connes 算子、HH-HC 引擎、雙模共端與內部 Hom、群表與裝配映射 | `cyclic/*.mbt` |

**關鍵接縫**：內部張量積對 Aᵉ 的共端維度 = HH₀（X2），外部張量積與 HC 的乘法性（T60），
裝配映射的秩 = 共軛類個數 = HC 的偶度數（T62b、T62d）——三處都是「兩個獨立算式對撞」。

## B0007 追加（超立方體網絡群＋KK 界外，見 `hyper/README.md`、`kk/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| T41 | **完整刻劃** Aut(Q_n) = { v ↦ π(v) ⊕ b }（窮舉集 = 預測集，n = 1..4；含負控制） | `hyper/hyper.mbt`、`hyper/checks.mbt` |
| T42 | \|Aut(Q_n)\| = 2ⁿ·n! 與軌道—穩定子（頂點／邊） | `hyper/group.mbt` |
| T43 | 方向映射 Aut → S_n 良定義、同態、核 = 𝔽₂ⁿ ⇒ Aut = 𝔽₂ⁿ ⋊ S_n | `hyper/group.mbt` |
| T44 | Q_n ≅ Cayley(𝔽₂ⁿ, 標準基)、距離 = 漢明、n 正則、\|E\| = n·2^{n−1} | `hyper/hyper.mbt` |
| T45 | 摺疊 Q_n → Q_{n−1} 與 n ≤ 2 退化（Q₁ = K₂、Q₂ = C₄ = D₈） | `hyper/group.mbt` |
| T46 | 邊置換群 φ: Aut → Sym(E)（n = 1 時核 = ℤ₂ 的例外） | `hyper/hyper.mbt`、`hyper/group.mbt` |
| T47 | 共軛類 = Σ p(k)p(n−k) = 2, 5, 10, 20（借 B0006 的 `partitions`） | `hyper/checks.mbt` |
| T48–T50 | KK 界外：清單合規＋kind = 0 的兩個值、自由積 K₁ 可加／K₀ 不可加、Künneth 界內截面 | `kk/outside.mbt` |

## 本模組已實作的演算法

A1 雙閉包（`galois`）、A2 NextClosure（`lattice`）、A3 DG 典範基（`lattice`）、
A4 分量＋局部閉包（`context` ＋ `galois`）、A5 概念格＋上覆蓋（`lattice`）、A6 檢核器（`galois`/`lattice`）、
A7 parse/dump（`context` ＋ `cmd/main`）。
B0007：A44 超立方體圖引擎、A45 回溯自同構窮舉、A46 由上而下候選生成、A47 置換群工具箱、
A48 方向映射與同態檢核、A49 邊索引表與邊置換、A50 摺疊與退化邊界、A51 界外清單引擎＋自由積／Künneth（`hyper/`、`kk/outside.mbt`）。

## 動線與接口

- 進入：`moon run cmd/main -- <指令>`；或以 `import { "arena/b0001/galois" @galois }` 直接呼叫。
- 輸出：stdout 文字；`contexts/*.ctx` 文字格式；`../algorithm.xlsx` 登記表。

## 建置

```bash
export PATH=/tmp/moon/bin:$PATH   # 或 bash ../ci/bootstrap_toolchain.sh
moon check --target all && moon build && moon fmt && moon info
```

`pkg.generated.mbti` 為 `moon info` 產生的公開介面檔，應與原始碼一同提交。

B0006 的 CLI 追加：`kk`、`kktable`、`kksix`、`kkctx`。

B0007 的 CLI 追加：`hyper`（T41–T47，29 條）、`hypertable`（Q_n 群結構表）、`kkout`（T48–T50，6 條＋界外清單）。
B0008 的 CLI 追加：`cyclic`（T51–T63，59 條）、`cyctable`（HH/HC 結構表）、`xprod`（內部／外部張量積表）。
B0009 的 CLI 追加：`analytic`（T64–T72，9 條）、`anatable`（近似單位元與非交換投影表）、
`cyclo`（T73–T80，8 條）、`cyclotable`（Φ_n／(ℤ/n)^× 結構表）。
B0010 的 CLI 追加：`bc`（T81–T90，10 條）、`bctable`（Baum–Connes 兩側算式並列＋界外清單）。

B0005 的 CLI 追加：`braid`、`jacobian`、`jtable`、`arf`。

B0002 的 CLI 追加：`matroids`、`matroid <名稱>`、`mcheck <名稱>`、`mcircuits <名稱>`、`negctl`。

## B0009 追加（16 名詞的最後三項＋分圓／單位根，見 `analytic/README.md`、`cyclotomic/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| T64–T65 | 近似單位元（閉式 N−1−n）＋么代數負控制 | `analytic/approx.mbt`、`check_approx_*` |
| T66–T68 | 投影、Murray–von Neumann、非交換投影（cos²θ=9/25、‖[p,q]‖₂²=288/625） | `analytic/projection.mbt` |
| T69–T71 | 冪等元同倫（A²=0）、自由同倫不變性（K₀ 秩／K₁ det）＋負控制 | `analytic/homotopy.mbt` |
| T72 | 秩的兩套演算法（ℚ 高斯 × F_p 高斯）交叉 | `analytic/checks.mbt` |
| T73–T75 | μ_n ≅ ℤ/n、ℚ/ℤ 撓＋可除、Pontryagin 對偶 | `cyclotomic/cyclotomic.mbt` |
| T76–T77 | Φ_n（n ≤ 20）、Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^× | `cyclotomic/{poly,cyclotomic}.mbt` |
| T78–T80 | 跡＝Ramanujan 和、伽羅華對應 dim=[G:H]、二次子體＋分圓特徵 | `cyclotomic/cyclotomic.mbt` |

## B0010 追加（Baum–Connes 論證，見 `bc/README.md`）

| 編號 | 名稱 | 落點 |
|---|---|---|
| T81–T82 | 有限群 μ₀ : R(G) → K₀(ℂG) 同構（5 樣本）＋正交性負控制 | `bc/assembly.mbt` |
| T83–T84 | ℤ/n 的 μ = DFT；A₄ 的 ℤ[ω] 展開秩 8 | `bc/{cyclicbc,omega}.mbt` |
| T85–T87 | S_n／SL₂(𝔽₂) 接縫、ℂ[ℤ] 無冪等元、ℤ 的組裝兩側 (ℤ,ℤ) | `bc/{checks,laurent}.mbt` |
| T88 | 界外清單 BC1–BC8（不決定，兩值並列） | `bc/boundary.mbt` |
| T89–T90 | 全局公理伽羅華對應、局部公理由代理決定 | `bc/{subgroup_lattice,localaxioms}.mbt` |
