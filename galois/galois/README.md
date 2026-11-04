# galois/galois — 閉包算子（A1）、局部閉包（A4）、檢核器（A6）

對應定理體系 **D4、D5、L1–L4、T1、T2、T3**。

## 已獲得的定理（本資料夾的落點）

| 編號 | 名稱 | 落點 |
|---|---|---|
| L1／X0 | 伴隨律 | `laws.mbt`（`check_adjunction`） |
| L3／L4 | 三角恆等、單次雙閉包即定點 | `closure.mbt` 與 `reference.mbt` 雙路徑對照 |
| P1–P5 | 反單調、閉包三性、Moore 族、反序同構、計數 | `laws.mbt` |
| T1 | GAGC | `closure.mbt`（構造）＋ `laws.mbt`（判準） |
| T2 | 重建定理 | `closure.mbt`（`singleton_closure`、`redundant_axioms`） |
| T3 | 局部性定理 | `closure.mbt`（`decompose`、`local_closure`） |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A1 | `closure_axioms` / `closure_stmts` | O((\|X\|·⌈n/64⌉ + \|Φ(X)\|·⌈m/64⌉)) |
| A4 | `decompose`（DSU ＋ 子上下文）／`local_closure`（含坍縮標記） | O((m+n+\|R\|)·α) |
| A6 | `check_*`（8 條結構檢核）＋ `structural_report` | 窮舉上限內 |
| 參考 | `naive_intent/naive_extent`、`closure_*_iterated`、`all_closed_bruteforce`、`closure_via_basis` | 逐元素慢速路徑 |

**檢核原則**：快速路徑（位元字組）與參考路徑（逐元素）**演算法上互相獨立**，
兩者不一致必有錯；`closure_via_basis` 另供 A3 檢查「Σ 誘導的閉包 == cl_S」。

## 依賴關係

```
galois ──▶ context ──▶ bitset
galois ◀── lattice ◀── registry ◀── cmd/main
```

## 接口

`closure_axioms / closure_stmts / is_closed_axioms / is_closed_stmts / singleton_closure /
redundant_axioms / decompose / local_closure / structural_report / check_*`
