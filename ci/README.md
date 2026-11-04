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
4. 跑 `cmd/main`，檢查三份樣本上下文 **13/13 PASS**（A6 常設檢核），並核對 |ℭ_A|=|ℭ_S|。
5. `python3 tools/make_registry.py` 重建 `algorithm.xlsx`（若與提交版本不一致，CI 失敗）。

## 依賴關係

```
ci/ci.sh ──▶ galois/（moon check/build/fmt、cmd/main）
        └──▶ tools/make_registry.py ──▶ algorithm.xlsx
```

## 接口

`bash ci/ci.sh`：退出碼 0 = 全部通過。無參數。可用環境變數 `MOON` 指定 moon 執行檔路徑。
