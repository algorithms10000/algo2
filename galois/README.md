# galois/ — B0001 MoonBit 模組（arena/b0001）

本資料夾是 MoonBit 模組根（`moon.mod`）。下面 6 個套件構成 B0001 的全部實作。

## 資料夾視角的依賴關係

```
cmd/main ──▶ registry ──▶ lattice ──▶ galois ──▶ context ──▶ bitset
    └──────────────────────▶ lattice/galois（直接使用）
```

## 本模組已獲得的定理（詳見 ../docs/B0001-定理體系.md）

| 編號 | 定理 | 主要落點 |
|---|---|---|
| X0、L1 | 伴隨律（伽羅瓦對應） | `galois/laws.mbt` |
| T1 | 全局公理伽羅瓦對應（閉包算子、Moore 族、反序格同構） | `galois/closure.mbt`、`galois/laws.mbt` |
| T2 | 重建定理（冗餘判準） | `galois/closure.mbt`（`redundant_axioms`） |
| T3 | 局部性定理（分量分解與坍縮） | `context/components.mbt`、`galois/closure.mbt` |
| T4 | Duquenne–Guiguès 典範基 | `lattice/basis.mbt` |

## 本模組已實作的演算法

A1 雙閉包（`galois`）、A2 NextClosure（`lattice`）、A3 DG 典範基（`lattice`）、
A4 分量＋局部閉包（`context` ＋ `galois`）、A5 概念格＋上覆蓋（`lattice`）、A6 檢核器（`galois`/`lattice`）、
A7 parse/dump（`context` ＋ `cmd/main`）。

## 動線與接口

- 進入：`moon run cmd/main -- <指令>`；或以 `import { "arena/b0001/galois" @galois }` 直接呼叫。
- 輸出：stdout 文字；`contexts/*.ctx` 文字格式；`../algorithm.xlsx` 登記表。

## 建置

```bash
export PATH=/tmp/moon/bin:$PATH   # 或 bash ../ci/bootstrap_toolchain.sh
moon check --target all && moon build && moon fmt && moon info
```

`pkg.generated.mbti` 為 `moon info` 產生的公開介面檔，應與原始碼一同提交。
