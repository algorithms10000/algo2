# ci/ — 全局編譯測試

## 檔案

| 檔案 | 作用 |
|---|---|
| `bootstrap_toolchain.sh` | 安裝 MoonBit 最新穩定版到 `/tmp/moon`（沙盒快照外，避免 383MB 二進位進入工程快照） |
| `ci.sh` | 回合末必跑的全局編譯測試 |

## ci.sh 做了什麼（依工程約束：不做白箱/黑箱/冒煙測試，不做 release 編譯與基準測試）

1. `moon check --target all`：wasm／wasm-gc／js／native 全目標型別檢查。
2. `moon build`：產出 executable。
3. `moon fmt --check`：格式一致性。
4. B0001：跑 `cmd/main`，三份樣本上下文 **39/39 PASS**，並核對 |ℭ_A|=|ℭ_S|。
5. B0002：四份擬陣各 **8/8 PASS**（合計 32），且期望值核對欄不得出現 ✗。
6. B0002 負控制：`interval-4` **必須 FAIL** 交換公理（否則判定檢核器失效）。
7. B0002 繼承：`M(K3)` 的 `K_ℱ*` 上 B0001 A6 **13/13 PASS**（提升／嵌入的可執行見證）。
8. A3′（增量式 DG 基）：四份整除上下文；`divisors-12/180/240` 必須與暴力 A3 **同族**（15 條 PASS），
   `divisors-420`（n=24）必須「3 PASS + 1 條明示未檢核」——未檢核不得算成綠燈。
9. B0002 延伸：`mextall` 13/13（Fano 二元非正則、χ(F7)=(λ−1)(λ−2)(λ−4)、M(K₄) 自對偶、圖擬陣正則、
   均勻平坦公式、均勻對偶、著色多項式）；7 份樣本各 11/11（共 77）；`mreg` 7/7；`mcensus 4` 須為 68/68/17/1。
10. `python3 tools/make_registry.py` 重建 `algorithm.xlsx`（17 個工作表；與提交版本不一致則失敗）。

## 依賴關係

```
ci/ci.sh ──▶ galois/（moon check/build/fmt、cmd/main）
        └──▶ tools/make_registry.py ──▶ algorithm.xlsx
```

## 接口

`bash ci/ci.sh`：退出碼 0 = 全部通過。無參數。可用環境變數 `MOON` 指定 moon 執行檔路徑。
