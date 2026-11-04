# galois/lattice — 閉集枚舉（A2）、典範基（A3）、概念格（A5）

對應定理體系 **D6、D7、D8、P5、P6、T1(3)(4)、T4**。

## 已獲得的定理（本資料夾的落點）

| 編號 | 名稱 | 落點 |
|---|---|---|
| D6／D7／D8 | 概念、蘊含與完備基、偽內涵 | `next_closure.mbt`、`basis.mbt` |
| P5 | \|ℭ_A\|=\|ℭ_S\|=\|B(K)\| | `closed_stmt_count`（與 `galois.all_closed_bruteforce` 交叉） |
| P6 | 偽內涵按基數遞增的可判定性 | `pseudo_intents` |
| T1(3)(4) | 閉集族完備格、反序同構 | `all_closed_stmts`、`upper_covers_stmts` |
| T4 | DG 典範基完備且非冗餘 | `check_basis_completeness/nonredundant/agreement` |

## A3′（增量式 DG 基，`dgbasis.mbt`）

| 項目 | 內容 |
|---|---|
| 定理 | **P6′**（偽閉包判定等價）、**T4′**（lectic 枚舉不重不漏）、**E14–E16** |
| 演算法 | `canonical_basis_incremental`：**偽閉包 clp_𝔓** 迭代至不動點 + 對 clp 跑 NextClosure；走訪步數 = \|𝔓\|+1 |
| 複雜度 | O((\|𝔓\|+1)·n·(\|𝔓\|+1)·\|𝔓\|·⌈n/64⌉) 位元運算，**無 2^n 因子**（原版 O(2^n·n·\|Σ\|)） |
| 檢核 | 與暴力版同族（n≤20）、輸出嚴格 lectic 遞增、E16 閉集族相同（**任意 n**）、非冗餘（任意 n） |

實測：`divisors-12`（n=6）12 步 vs 63；`divisors-180`（n=18）45 步 vs 262,143；
`divisors-240`（n=20）50 步 vs 1,048,575（三者皆與暴力版同族 PASS）；
`divisors-420`（n=24）62 步 vs 16,777,215——暴力不可行，改由 **E16**（Horn 理論閉集族 = K 的閉集族）
與「刪一條即失去結論」的非冗餘判準判定，兩者皆 PASS。

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A2 | `next_closed_stmts`、`all_closed_stmts` | 延遲 O(n·(⌈m/64⌉+⌈n/64⌉))，總量 O(\|ℭ\|·n·closure) |
| A3 | `pseudo_intents`、`canonical_basis` | O(2ⁿ·n·\|Σ\|) |
| A5 | `all_concepts`、`concept_of`、`upper_covers_stmts`、`hasse_edge_count` | O(\|ℭ\|·n·closure + \|ℭ\|·n²) |
| A6 | `check_nextclosure`（枚舉 vs 窮舉）、`check_covers`、`basis_report` | 窮舉上限內 |

## 兩個實測反例（保留在程式碼註解中）

1. **NextClosure 必須丟棄索引 ≥ i 的元素**：若只做 `cl(A∪{i})`，cyclotomic 上下文只枚舉出 3/5 個閉集。
2. **下覆蓋不可用 `cl(Y∖{s})` 取極大者**：divisibility 的 `Y={6,12,18}` 之真閉子集 `{12}` 永遠取不到；
   上覆蓋 `min{cl(Y∪{s}) | s∉Y}` 才正確。

## 依賴關係

```
lattice ──▶ galois ──▶ context ──▶ bitset
lattice ◀── registry ◀── cmd/main
```

## 接口

`all_closed_stmts / closed_stmt_count / all_concepts / concept_count / upper_covers_stmts /
hasse_edge_count / pseudo_intents / canonical_basis / basis_size / render_implication /
check_basis_completeness / check_basis_nonredundant / check_basis_agreement / check_nextclosure /
check_covers / basis_report`
