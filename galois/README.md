# galois/ — B0001 MoonBit 模組（arena/b0001）

本資料夾是 MoonBit 模組根（`moon.mod`）。下面 12 個套件構成 B0001–B0007 的全部實作。

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
    │             └──▶ hyper    ──▶ kk, galois（B0007：超立方體網絡群 T41–T47）
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

B0005 的 CLI 追加：`braid`、`jacobian`、`jtable`、`arf`。

B0002 的 CLI 追加：`matroids`、`matroid <名稱>`、`mcheck <名稱>`、`mcircuits <名稱>`、`negctl`。
