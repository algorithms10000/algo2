///|
/// B0001 / registry 套件：圓分體 ℚ(ζ₈)/ℚ 的伽羅瓦對應實例
///
/// 這是「全局公理伽羅瓦對應」（X0/T1）在真實數學物件上的實例，不是人造資料：
/// 令 ζ₈ 為 8 次原根。ℚ(ζ₈) = ℚ(√2, i√2)，其伽羅瓦群
/// 　G = { id, σ, τ, στ } ≅ C₂ × C₂，
/// 其中 σ(i) = −i、τ(√2) = −√2（故 σ(√2)=√2、τ(i)=i）。
///
/// 取 ℤ-基底 B = {1, i, √2, i√2}。由於 G 對 B 的每個元素只做「變號」，
/// 「群元素 g 固定基底元素 b」可由純符號表判定（下方 sign 表），
/// 於是 R 的每一個元素都是**由群作用計算得出**，而非手寫：
/// 　(H, F) ∈ R  ⟺  ∀b ∈ gen(F), ∀g ∈ H:  g 固定 b
/// 　            ⟺  F ⊆ Fix(H)（等價於 H ⊆ Gal(L/F)）
///
/// 依伽羅瓦基本定理，閉公理集（子群）與閉陳述集（中間體）之間應為反序雙射，
/// 兩側皆為 5 個元素；這正是 T1 在本實例上的斷言，並由 A6 檢核。

///|
/// 建立 ℚ(ζ₈)/ℚ 的伽羅瓦對應上下文。
/// A = 5 個子群，S = 5 個中間體，R 由群作用計算。
pub fn cyclotomic_context() -> @context.FormalContext {
  // 群元素對基底 {1, i, √2, i√2} 的作用：true = 固定（+），false = 變號（−）
  // id、σ: i↦−i、τ: √2↦−√2、στ。
  let group : Array[Array[Bool]] = [
    [true, true, true, true],
    [true, false, true, false],
    [true, true, false, false],
    [true, false, false, true],
  ]
  // 子群：以群元素索引集合表示
  let subgroups : Array[Array[Int32]] = [
    [0],
    [0, 1],
    [0, 2],
    [0, 3],
    [0, 1, 2, 3],
  ]
  let axiom_names : Array[String] = [
    "1", "⟨σ⟩", "⟨τ⟩", "⟨στ⟩", "G",
  ]
  // 中間體：以其生成元在基底 B 中的索引集合表示
  let fields : Array[Array[Int32]] = [[0], [0, 2], [0, 1], [0, 3], [2, 3]]
  let stmt_names : Array[String] = [
    "Q", "Q(√2)", "Q(i)", "Q(i√2)", "Q(ζ8)",
  ]
  let edges : Array[(Int32, Int32)] = []
  for hi = 0; hi < subgroups.length(); hi = hi + 1 {
    for fi = 0; fi < fields.length(); fi = fi + 1 {
      let mut fixed = true
      for k = 0; k < fields[fi].length(); k = k + 1 {
        let basis_index = fields[fi][k]
        for j = 0; j < subgroups[hi].length(); j = j + 1 {
          let g = subgroups[hi][j]
          if !group[g][basis_index] {
            fixed = false
          }
        }
      }
      if fixed {
        edges.push((hi, fi))
      }
    }
  }
  @context.FormalContext::new(axiom_names, stmt_names, edges)
}
