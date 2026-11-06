# ci/ — 全局編譯測試

## 檔案

| 檔案 | 作用 |
|---|---|
| `bootstrap_toolchain.sh` | 安裝 MoonBit 最新穩定版到 `/tmp/moon`（沙盒快照外，避免 383MB 二進位進入工程快照） |
| `ci.sh` | 回合末必跑的全局編譯測試 |

## ci.sh 做了什麼（19 步；依工程約束：不做白箱/黑箱/冒煙測試，不做 release 編譯與基準測試）

| 步 | 內容 | 期望 |
|---|---|---|
| 1 | `moon check --target all`（wasm／wasm-gc／js／native 全目標） | 0 錯 |
| 2 | `moon build` | 成功 |
| 3 | `moon fmt --check` | 格式一致 |
| 4 | B0001：三份樣本上下文 A6 | 39/39 |
| 5 | B0002：四份擬陣 A12 ＋ 期望值核對 | 32/32 |
| 6 | B0002 負控制：`interval-4` **必須 FAIL** 交換公理 | 檢核器不得恆真 |
| 7 | B0002 繼承：`K_ℱ*` 上跑 B0001 A6（M(K3)） | 13/13 |
| 8 | A3′ 增量式 DG 基（`divisors-420` 的 n=24 情形明示未檢核） | 15 條 PASS ＋ 3+1 |
| 9 | B0002 延伸：`mextall`、7 份樣本、`mreg`、`mcensus 4` | 13/13、77、7/7、68/68/17/1 |
| 10 | B0003：同餘子群（T13、T14）＋ `congruence-12` 樣本 | 全通過 |
| 11 | B0004：撓群 E[n]（T15–T21）＋ Paley／Ramsey ＋ `paley-13` | 全通過 |
| 12 | B0005：辮群（T22–T24） | 27/27 |
| 13 | B0005：圖雅可比簇（T25–T31）＋ Arf 表 | 54/54 |
| 14 | B0006：真 KK-理論片段（T32–T40）＋ `kktable`、`kksix` | 46/46 |
| 15 | B0006 × B0001：理想格上下文 `kk-ideal`（A6＋A3′） | A6 8/8、A3′ 4/4 |
| 16 | **B0007：超立方體網絡群（T41–T47）＋ `hypertable`** | **29/29；窮舉＝預測、385 行結構表關鍵值** |
| 17 | **B0007：KK 界外部份（T48–T50）＋ O1–O6 清單** | **6/6；純界外 2 項、kind=0 兩值** |
| 18 | **B0008：循環同調／內部張量積／漸新態射（T51–T63）** | **59/59；`cyctable`／`xprod` 字串核對** |
| 19 | `python3 tools/make_registry.py` 重建 `algorithm.xlsx` | 31 個工作表一致 |

第 16–18 步的斷言一律**逐字對齊程式輸出**（R8-CI-ERR 的教訓：`O₃` 不是 `O_3`）。

## 依賴關係

```
ci/ci.sh ──▶ galois/（moon check/build/fmt、cmd/main）
        └──▶ tools/make_registry.py ──▶ algorithm.xlsx
```

## 接口

`bash ci/ci.sh`：退出碼 0 = 全部通過。無參數。可用環境變數 `MOON` 指定 moon 執行檔路徑。
