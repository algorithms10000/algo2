# galois/context — 形式上下文 K=(A,S,R)

對應定理體系 **D1（上下文）、D2（Φ）、D3（Ψ）、X4（分量）**。

## 已獲得的定理（本資料夾的落點）

| 編號 | 名稱 | 落點 |
|---|---|---|
| D1 | 形式上下文 | `context.mbt`（`FormalContext`） |
| D2 | Φ(X)=⋂row(a)，Φ(∅)=S | `FormalContext::intent` |
| D3 | Ψ(Y)=⋂col(s)，Ψ(∅)=A | `FormalContext::extent` |
| X4 | 分量局部性 | `components.mbt`（DSU ＋ `components_of`） |
| T3 | 局部性定理的最後一步（子上下文） | `sub_context` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A4 前半 | DSU 分量分解 `components_of`、`component_id_of_axiom/stmt`、`sub_context` | O((m+n+\|R\|)·α) |
| A7 | 文字格式解析 `parse_context` | O(行數×token + \|R\|) |

## 依賴關係

```
context ──▶ bitset            （本套件唯一依賴）
context ◀── galois ◀── lattice ◀── registry ◀── cmd/main
```

## 動線與接口

- 建構：`FormalContext::new(axiom_names, stmt_names, edges)`；
  或 `parse_context(text) -> ParsedContext`（文字格式見 `moon.pkg` 旁註解與 `../contexts/README.md`）。
- 查詢：`intent(extent)`、`extent(intent)`、`axioms_named/stmts_named`（名稱 → 位元集）、
  `render_axioms/render_stmts`（位元集 → 名稱字串）。
- 錯誤：`ContextError`（`UnknownAxiom`／`UnknownStatement`）、`ParseError`（`ParseAt`／`UndefinedNameAt`／`BadArity`）。
