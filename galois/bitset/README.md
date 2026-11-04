# galois/bitset — 稠密位元集（B0001 的底層）

以 `UInt64` 字組實作稠密位元集，讓 Φ/Ψ 的交集成為**字組平行**運算
（複雜度帶 ⌈n/64⌉ 因子，而非 n）。

## 已實作的演算法

| 名稱 | 用途 | 複雜度 |
|---|---|---|
| `BitSet::intersect / union / minus / complement` | 集合基本運算 | O(⌈n/64⌉) |
| `BitSet::count` | popcount 基數 | O(⌈n/64⌉) |
| `BitSet::subset_of` | 包含判定 | O(⌈n/64⌉) |
| `BitSet::ones / prefix_ones` | 逐一取出 1 的索引 | O(n) |
| `BitSet::prefix_equal` | lectic 序比較（A2 用） | O(k) |
| `all_subsets` | 冪集（n ≤ 20） | O(2ⁿ) |
| `subsets_by_cardinality` | 按基數遞增的冪集（A3 正確性依據，P6） | O(n·2ⁿ) |

## 定理

本套件不含數學定理，只承載 B0001 定理體系的**表示層**；
它支撐的定理是 A1 的複雜度界（docs §6 設計要點 1）與 P6 的列舉次序。

## 依賴關係

```
bitset ◀── context ◀── galois ◀── lattice ◀── registry ◀── cmd/main
```

## 接口

`BitSet::new/full/singleton/from_indices/from_mask/to_mask/set/unset/get/put/copy/equals/subset_of/
intersect/union/minus/complement/union_inplace/minus_inplace/ones/prefix_ones/prefix_equal/plus_bit/minus_bit/render`

不變量：`words.length() == (n+63)/64`，且第 n 位以上恆為 0（由 `mask_tail` 維持）。
