# galois/contexts — 文字格式樣本（.ctx）

每個檔案都是 `moon run cmd/main -- dump <名稱>` 的輸出，可用
`moon run cmd/main -- parse "$(cat contexts/<檔名>)"` 原樣讀回（往返一致，已實測）。

## 文字格式

```
# 註解行（# 開頭）
context <名稱>
axiom   <公理名稱>          # 可重複宣告，重複視為同一物件
stmt    <陳述名稱>
edge    <公理名稱> <陳述名稱>
edges   <公理名稱> <陳述名稱> <陳述名稱> ...
```

規則：
- `axiom`／`stmt` 必須先宣告再於 `edge(s)` 使用，否則 `ParseError::UndefinedNameAt`。
- `context`／`axiom`／`stmt` 的參數個數錯誤 → `ParseError::BadArity`；未知指令 → `ParseError::ParseAt`。
- 空白（空格、定位鍵）與空行任意；行序不影響結果（先收集名稱，再建邊）。

## 檔案

| 檔案 | 內容 |
|---|---|
| `cyclotomic-q8.ctx` | ℚ(ζ₈)/ℚ 的伽羅瓦對應（5 公理 × 5 陳述 × 12 邊） |
| `divisibility.ctx` | ℤ 整除格（4 × 4 × 12） |
| `two-blocks.ctx` | 兩不交分量（4 × 6 × 8） |

## 依賴關係與接口

本資料夾是**資料**，不是程式碼；它經由 `@context.parse_context` 進入系統，
經由 `cmd/main` 的 `dump` 離開系統。
