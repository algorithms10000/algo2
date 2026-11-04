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
