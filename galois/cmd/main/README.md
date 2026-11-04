# galois/cmd/main — CLI（接入與輸出接口）

## 已實作的演算法

- 參數派發（`main`）與文字輸出（`show_*`）。
- `dump_text`：把 K 匯出為文字格式（與 `@context.parse_context` **互逆**，已實測往返一致）。

## 指令

| 指令 | 作用 |
|---|---|
| （無參數） | 三份樣本的完整摘要（含逐條 A6 PASS/FAIL） |
| `list` | 列出樣本上下文 |
| `info <名稱>` | 單一摘要 |
| `concepts <名稱>` | 全部概念（外延 ↔ 內涵，lectic 序） |
| `basis <名稱>` | Duquenne–Guiguès 典範基 Σ |
| `check <名稱>` | 只跑 A6 檢核（13 條） |
| `closure <名稱> <公理名>...` | cl_A(X)、Φ(X)、A4 局部閉包與坍縮標記 |
| `dump <名稱>` | 以文字格式匯出 |
| `parse "<文字>"` | 解析外部上下文並摘要 |
| `dg <名稱>` | 【A3′】增量式 DG 基：統計＋四條檢核 |
| `dgbasis <名稱>` | 【A3′】列出每一條蘊含 |
| `modular` | 【B0003】同餘子群檢核（T13、T14，62 條） |
| `congruence` | 【B0003】同餘子群樣本上下文（A6＋DG 基） |
| `elliptic` | 【B0004】撓群 E[n] 檢核（T15–T21，69 條） |
| `eptable` | 【B0004】E[n] 的軌道計數並與 B0003 同餘指數對照（n=2..12） |
| `paley` | 【B0004】Paley 圖／競賽與團複形同調 |
| `paleyctx` | 【B0004】paley-13 樣本上下文（A6＋DG 基） |
| `braid` | 【B0005】辮群 B_n 檢核（T22–T24，27 條） |
| `jacobian` | 【B0005】圖雅可比簇檢核（T25–T31，54 條） |
| `jtable` | 【B0005】七個樣本圖的 g、不變因子、\|J\|、τ |
| `arf` | 【B0005】theta 特徵的 Arf 計數（g = 1,2,3） |
| `kk` | 【B0006】真 KK-理論片段檢核（T32–T40，46 條） |
| `kktable` | 【B0006】K-群與 UCT 的 KK 值表 |
| `kksix` | 【B0006】Toeplitz／Cuntz 的六項正合列 |
| `kkctx` | 【B0006】理想格上下文（B0001 A6＋A3′） |
| `genus` | 【B0003】X₀(N) 的 ψ/φ/ν₂/ν₃/ν_∞/g 並與古典表比對 |
| `mext <名稱>` | 【B0002 延伸】二元性、正則性、Tutte、特徵多項式＋11 條檢核 |
| `mextall` | 【B0002 延伸】全域定理檢核（13 條） |
| `mreg` | 【B0002 延伸】登記期望值核對（7 份樣本） |
| `mcensus <n>` | 【B0002 延伸】小型擬陣普查（n ≤ 5，兩條列舉路線） |
| `dg <名稱>` / `dgbasis <名稱>` | 【A3′】增量式 DG 基 |
| `matroids` | 【B0002】列出擬陣樣本 |
| `matroid <名稱>` | 【B0002】擬陣摘要＋A12 八條檢核（含期望值核對） |
| `mcheck <名稱>` | 【B0002】另跑 B0001 繼承檢核（K_ℱ* 上的 13 條） |
| `mcircuits <名稱>` | 【B0002】列出迴路系統 |
| `negctl` | 【B0002】負控制：區間凸包必須 FAIL 交換公理 |

## 依賴關係

```
cmd/main ──▶ registry ──▶ lattice ──▶ galois ──▶ context ──▶ bitset
        └──▶ context / galois / lattice（直接使用）
```

## 動線

`argv → 指令派發 → registry.lookup / parse_context → A1–A6 → stdout`

## 接口穩定性

CLI 是本專案的**對外接口**；輸出欄位為純文字，格式見 `../README.md` §7。
