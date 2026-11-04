///|
/// B0001 / galois 套件：參考實作（獨立的第二種演算法路徑，供 A6 交叉檢核）
///
/// 這裡刻意**不用**位元字組交集，而是逐元素判定 (a,s) ∈ R，
/// 使「快速路徑（bitset）」與「參考路徑（逐元素）」在演算法上互相獨立：
/// 若兩者結果不一致，必有一方錯。這不是 mock／stub，而是正式交付的檢核能力（A6）。

///|
/// 逐元素內涵：Φ(X)，時間 O(|X|·n)。
pub fn naive_intent(
  ctx : @context.FormalContext,
  extent : @bitset.BitSet,
) -> @bitset.BitSet {
  let out = @bitset.BitSet::new(ctx.num_stmts())
  for s = 0; s < ctx.num_stmts(); s = s + 1 {
    let mut ok = true
    for k = 0; k < ctx.num_axioms(); k = k + 1 {
      if extent.get(k) && !ctx.rows[k].get(s) {
        ok = false
      }
    }
    if ok {
      out.set(s)
    }
  }
  out
}

///|
/// 逐元素外延：Ψ(Y)，時間 O(|Y|·m)。
pub fn naive_extent(
  ctx : @context.FormalContext,
  intent : @bitset.BitSet,
) -> @bitset.BitSet {
  let out = @bitset.BitSet::new(ctx.num_axioms())
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    let mut ok = true
    for k = 0; k < ctx.num_stmts(); k = k + 1 {
      if intent.get(k) && !ctx.cols[k].get(a) {
        ok = false
      }
    }
    if ok {
      out.set(a)
    }
  }
  out
}

///|
/// 參考閉包：**迭代到定點**求 cl_A(X)（不用 L4 的單次定點結論）。
/// 收斂判定：位元集不再變動；上界 min(m, n) + 1 次迭代。
pub fn closure_axioms_iterated(
  ctx : @context.FormalContext,
  extent : @bitset.BitSet,
) -> @bitset.BitSet {
  let mut cur = extent.copy()
  let bound = ctx.num_axioms() + ctx.num_stmts() + 2
  for _step = 0; _step < bound; _step = _step + 1 {
    let next = naive_extent(ctx, naive_intent(ctx, cur))
    if next.equals(cur) {
      return cur
    }
    cur = next
  }
  cur
}

///|
/// 參考閉包：迭代到定點求 cl_S(Y)。
pub fn closure_stmts_iterated(
  ctx : @context.FormalContext,
  intent : @bitset.BitSet,
) -> @bitset.BitSet {
  let mut cur = intent.copy()
  let bound = ctx.num_axioms() + ctx.num_stmts() + 2
  for _step = 0; _step < bound; _step = _step + 1 {
    let next = naive_intent(ctx, naive_extent(ctx, cur))
    if next.equals(cur) {
      return cur
    }
    cur = next
  }
  cur
}

///|
/// 參考枚舉：以逐元素閉包窮舉全部閉集（2^n）。需 n ≤ 20。
pub fn all_closed_bruteforce(
  ctx : @context.FormalContext,
  side : Side,
) -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  match side {
    AxiomSide => {
      let subs = @bitset.all_subsets(ctx.num_axioms())
      for i = 0; i < subs.length(); i = i + 1 {
        let cl = closure_axioms_iterated(ctx, subs[i])
        if cl.equals(subs[i]) {
          out.push(subs[i])
        }
      }
    }
    StmtSide => {
      let subs = @bitset.all_subsets(ctx.num_stmts())
      for i = 0; i < subs.length(); i = i + 1 {
        let cl = closure_stmts_iterated(ctx, subs[i])
        if cl.equals(subs[i]) {
          out.push(subs[i])
        }
      }
    }
  }
  out
}

///|
/// 兩側選擇子。
pub(all) enum Side {
  AxiomSide
  StmtSide
}

///|
/// 驅動一組蘊含（Horn 規則）的前向鏈推導閉包：反覆套用直到不再增長。
/// 用於檢核 A3 產出的典範基是否與 cl_S 產生同一個閉包（T4 的強檢核）。
pub fn closure_via_basis(
  n : Int32,
  basis : Array[(@bitset.BitSet, @bitset.BitSet)],
  seed : @bitset.BitSet,
) -> @bitset.BitSet {
  let cur = seed.copy()
  let bound = basis.length() + n + 2
  for _step = 0; _step < bound; _step = _step + 1 {
    let mut changed = false
    for i = 0; i < basis.length(); i = i + 1 {
      let (p, q) = basis[i]
      if p.subset_of(cur) && !q.subset_of(cur) {
        cur.union_inplace(q)
        changed = true
      }
    }
    if !changed {
      return cur
    }
  }
  cur
}
