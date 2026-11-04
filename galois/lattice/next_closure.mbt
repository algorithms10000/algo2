///|
/// B0001 / lattice 套件：A2 NextClosure（Ganter）與 A5 概念格
/// 對應 docs/B0001-定理體系.md：P2、T1(3)(4)、P4、P5。
///
/// lectic 序（字典序的集合序）：A <_i B ⟺ 存在 i 使 i ∈ B∖A 且 A∩{0..i-1} = B∩{0..i-1}。
/// NextClosure 的多項式延遲性質：每一步最多 1 + n 次「加一元素再閉包」，
/// 故單步延遲 O(n·(⌈m/64⌉+⌈n/64⌉))，與已枚舉的概念數無關。

///|
/// 形式概念（D6）：外延 ⊆ A、內涵 ⊆ S 且 Φ(外延)=內涵、Ψ(內涵)=外延。
pub struct Concept {
  extent : @bitset.BitSet
  intent : @bitset.BitSet
}

///|
pub fn Concept::extent(self : Concept) -> @bitset.BitSet {
  self.extent
}

///|
pub fn Concept::intent(self : Concept) -> @bitset.BitSet {
  self.intent
}

///|
/// 由陳述子集 Y 造出概念 (Ψ(Y), ΦΨ(Y))。
pub fn concept_of(
  ctx : @context.FormalContext,
  intent : @bitset.BitSet,
) -> Concept {
  let closed_intent = closure_stmts(ctx, intent)
  let extent = ctx.extent(closed_intent)
  { extent, intent: closed_intent, }
}

///|
/// A2：lectic 序下，大於 current 的**最小閉集**；若 current 已是最大閉集則回傳 None。
/// 這是 NextClosure 的單步（多項式延遲）。
pub fn next_closed_stmts(
  ctx : @context.FormalContext,
  current : @bitset.BitSet,
) -> @bitset.BitSet? {
  let n = ctx.num_stmts()
  let mut i = n - 1
  while i >= 0 {
    if !current.get(i) {
      // Ganter 的 A^{×i}：(A ∩ {0..i-1}) ∪ {i}，即**丟棄**索引 ≥ i 的元素後再加 i。
      // 若只做 A ∪ {i}（不丟棄），後繼會跳過合法的閉集（B0001 開發期已實測）。
      let masked = current.copy()
      for j = i; j < n; j = j + 1 {
        masked.unset(j)
      }
      masked.set(i)
      let candidate = closure_stmts(ctx, masked)
      if candidate.prefix_equal(current, i) {
        return Some(candidate)
      }
    }
    i = i - 1
  }
  None
}

///|
/// A2：枚舉全部閉集（= 全部概念內涵），依 lectic 序。
/// 由 cl_S(∅) 起，逐步取 lectic 後繼；總時間 O(|ℭ|·n·closure)。
pub fn all_closed_stmts(ctx : @context.FormalContext) -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  let n = ctx.num_stmts()
  let start = closure_stmts(ctx, @bitset.BitSet::new(n))
  out.push(start)
  let mut cur = start
  let limit = 1 << (n + 1)
  let mut steps = 0
  while steps < limit {
    steps = steps + 1
    match next_closed_stmts(ctx, cur) {
      Some(next) => {
        out.push(next)
        cur = next
      }
      None => return out
    }
  }
  out
}

///|
/// A2：閉集計數（= |ℭ_S| = |ℭ_A| = |B(K)|，P5）。
pub fn closed_stmt_count(ctx : @context.FormalContext) -> Int32 {
  all_closed_stmts(ctx).length()
}

///|
/// A5：全部概念（以內涵的 lectic 序排列）。
pub fn all_concepts(ctx : @context.FormalContext) -> Array[Concept] {
  let intents = all_closed_stmts(ctx)
  let out : Array[Concept] = []
  for i = 0; i < intents.length(); i = i + 1 {
    out.push({ extent: ctx.extent(intents[i]), intent: intents[i], })
  }
  out
}

///|
/// A5：概念數。
pub fn concept_count(ctx : @context.FormalContext) -> Int32 {
  all_closed_stmts(ctx).length()
}

///|
/// A5：閉集 Y 的**上覆蓋**（minimal proper closed supersets）。
///
/// 定理依據：任一極小真閉超集必形如 cl(Y ∪ {s})，故只需看 n 個候選再取極小者。
/// **反例警告**（B0001 開發期由 A6 實測得到）：對偶的「下覆蓋 = cl(Y∖{s}) 取極大者」是**錯的**。
/// 於 divisibility 上下文，Y={6,12,18} 的真閉子集 {12} 滿足 cl(Y∖{s}) = Y（∀s ∈ Y），
/// 因而永遠不會被下覆蓋公式捕捉。上覆蓋公式則無此問題。
/// 時間 O(n·closure + n²) 位元比較。
pub fn upper_covers_stmts(
  ctx : @context.FormalContext,
  closed : @bitset.BitSet,
) -> Array[@bitset.BitSet] {
  let candidates : Array[@bitset.BitSet] = []
  let n = ctx.num_stmts()
  for s = 0; s < n; s = s + 1 {
    if closed.get(s) {
      continue
    }
    let cl = closure_stmts(ctx, closed.plus_bit(s))
    if cl.equals(closed) {
      continue
    }
    let mut seen = false
    for j = 0; j < candidates.length(); j = j + 1 {
      if candidates[j].equals(cl) {
        seen = true
      }
    }
    if !seen {
      candidates.push(cl)
    }
  }
  let covers : Array[@bitset.BitSet] = []
  for i = 0; i < candidates.length(); i = i + 1 {
    let mut minimal = true
    for j = 0; j < candidates.length(); j = j + 1 {
      if i != j &&
        candidates[j].subset_of(candidates[i]) &&
        !candidates[j].equals(candidates[i]) {
        minimal = false
      }
    }
    if minimal {
      covers.push(candidates[i])
    }
  }
  covers
}

///|
/// A5：Hasse 圖的覆蓋邊數（對全部閉集求下覆蓋之和）。
pub fn hasse_edge_count(ctx : @context.FormalContext) -> Int32 {
  let closed = all_closed_stmts(ctx)
  let mut edges = 0
  for i = 0; i < closed.length(); i = i + 1 {
    edges = edges + upper_covers_stmts(ctx, closed[i]).length()
  }
  edges
}

///|
/// A6 檢核：A2 的 NextClosure 枚舉與逐元素窮舉（參考路徑）必須給出**同一個集合族**。
/// 這一條曾在開發期抓到真實缺陷（後繼演算法未丟棄索引 ≥ i 的元素，導致漏枚舉），
/// 因此保留為常設檢核，而非一次性測試。
pub fn check_nextclosure(ctx : @context.FormalContext) -> Check {
  let n = ctx.num_stmts()
  if n > 20 {
    return @galois.Check::make(
      "A2",
      "NextClosure 完整性",
      false,
      "未檢核：n=" + n.to_string() + " > 20，超出窮舉預算",
    )
  }
  let found = all_closed_stmts(ctx)
  let reference = closure_stmts_reference(ctx)
  let total = 1 << n
  let seen : Array[Bool] = []
  for i = 0; i < total; i = i + 1 {
    seen.push(false)
  }
  for i = 0; i < found.length(); i = i + 1 {
    if !closure_stmts(ctx, found[i]).equals(found[i]) {
      return @galois.Check::make(
        "A2",
        "NextClosure 完整性",
        false,
        "枚舉出非閉集：" + ctx.render_stmts(found[i]),
      )
    }
    let mask = found[i].to_mask()
    if seen[mask] {
      return @galois.Check::make(
        "A2",
        "NextClosure 完整性",
        false,
        "重複枚舉：" + ctx.render_stmts(found[i]),
      )
    }
    seen[mask] = true
  }
  for i = 0; i < reference.length(); i = i + 1 {
    if !seen[reference[i].to_mask()] {
      return @galois.Check::make(
        "A2",
        "NextClosure 完整性",
        false,
        "漏枚舉閉集：" + ctx.render_stmts(reference[i]),
      )
    }
  }
  if found.length() != reference.length() {
    return @galois.Check::make(
      "A2",
      "NextClosure 完整性",
      false,
      "數量不符：NextClosure=" +
      found.length().to_string() +
      "，窮舉=" +
      reference.length().to_string(),
    )
  }
  @galois.Check::make(
    "A2",
    "NextClosure 完整性",
    true,
    "|ℭ_S|=" + found.length().to_string(),
  )
}

///|
/// 參考枚舉的區域包裝（指向 galois 套件的逐元素路徑）。
fn closure_stmts_reference(
  ctx : @context.FormalContext,
) -> Array[@bitset.BitSet] {
  @galois.all_closed_bruteforce(ctx, @galois.StmtSide)
}

///|
/// A6 檢核：A5 的上覆蓋 == 逐元素求出的極小真閉超集（覆蓋關係正確性）。
pub fn check_covers(ctx : @context.FormalContext) -> Check {
  let n = ctx.num_stmts()
  if n > 20 {
    return @galois.Check::make(
      "A5",
      "覆蓋關係",
      false,
      "未檢核：n=" + n.to_string() + " > 20，超出窮舉預算",
    )
  }
  let closed = all_closed_stmts(ctx)
  for i = 0; i < closed.length(); i = i + 1 {
    let y = closed[i]
    let covers = upper_covers_stmts(ctx, y)
    // 1) 每個覆蓋都必須是閉的真超集
    for c = 0; c < covers.length(); c = c + 1 {
      if !closure_stmts(ctx, covers[c]).equals(covers[c]) {
        return @galois.Check::make(
          "A5",
          "覆蓋關係",
          false,
          "覆蓋非閉集：" + ctx.render_stmts(covers[c]),
        )
      }
      if !y.subset_of(covers[c]) || covers[c].equals(y) {
        return @galois.Check::make(
          "A5",
          "覆蓋關係",
          false,
          "覆蓋不是真超集：" + ctx.render_stmts(covers[c]),
        )
      }
    }
    // 2) 對每個真閉超集 z ⊋ y，必須存在覆蓋 c 使 y ⊊ c ⊆ z
    for j = 0; j < closed.length(); j = j + 1 {
      let z = closed[j]
      if y.subset_of(z) && !z.equals(y) {
        let mut covered = false
        for c = 0; c < covers.length(); c = c + 1 {
          if y.subset_of(covers[c]) &&
            covers[c].subset_of(z) &&
            !covers[c].equals(y) {
            covered = true
          }
        }
        if !covered {
          return @galois.Check::make(
            "A5",
            "覆蓋關係",
            false,
            "真閉超集 " +
            ctx.render_stmts(z) +
            " 未被任何覆蓋穿過（下層=" +
            ctx.render_stmts(y) +
            "）",
          )
        }
      }
    }
    // 3) 覆蓋彼此不可比
    for a = 0; a < covers.length(); a = a + 1 {
      for b = 0; b < covers.length(); b = b + 1 {
        if a != b && covers[a].subset_of(covers[b]) {
          return @galois.Check::make(
            "A5",
            "覆蓋關係",
            false,
            "覆蓋之間可比：" + ctx.render_stmts(covers[a]),
          )
        }
      }
    }
  }
  @galois.Check::make(
    "A5",
    "覆蓋關係",
    true,
    "|ℭ_S|=" + closed.length().to_string(),
  )
}
