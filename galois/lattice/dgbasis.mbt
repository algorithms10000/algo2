///|
/// B0001 / lattice 套件：A3′ **增量式 Duquenne–Guiguès 典範基**
/// 對應 docs/B0001-定理體系.md：D7、D8、P6、T4、E9、E12；
/// 延伸條款見 docs/B0001-定理體系.md §A3′（n > 20 的可行性）。
///
/// ## 為什麼要改寫
/// A3 原版（`basis.mbt`）依基數遞增走訪 S 的**所有 2^n 個子集**，n = 24 時是 16,777,215 次，
/// 每次還要掃已找到的偽內涵。純量級問題，不是常數問題。
///
/// ## A3′ 的做法（偽內涵 + 偽閉包）
/// 記 𝔓 為已找到的偽內涵集，定義**偽閉包**（對當前 𝔓）
///   clp_𝔓(X) = X ∪ ⋃ { Q'' : Q ∈ 𝔓, Q ⊊ X }   （迭代到不動點）
/// 則 Gand 的判準「P 是偽內涵 ⟺ P ⊊ P'' 且 ∀ 偽內涵 Q ⊊ P 有 Q'' ⊆ P」化為
///   **P 是偽內涵 ⟺ clp_𝔓(P) = P 且 cl(P) ≠ P**。
/// 於是可以直接對閉包算子 clp_𝔓 跑 **NextClosure**：每一步只做 ≤ n 次「加一元素再取 clp 不動點」，
/// 因此總成本只與 |𝔓|、n、|Σ| 有關，**完全不出現 2^n 因子**。
///
/// ## 完備性的關鍵不變量（本檔實作時依賴、並由檢核器守住）
/// 1. 若 Q ⊊ P 則 Q 在 lectic 序中先於 P，故走訪到 P 時所有「P 內部的偽內涵」皆已找到；
/// 2. 𝔓 只增不減 ⇒ clp 只增不減 ⇒ 其不動點族只減不增 ⇒ 真正的偽內涵永遠是不動點（不會被跳過）；
/// 3. NextClosure 對**當前** clp 回傳「大於 current 的最小不動點」，故落點 ≤ 任何尚未枚舉的偽內涵，
///    不會越過它。
///
/// 三點合起來：走訪序列完整（不漏）且嚴格遞增（不重）。

///|
/// 一次 A3′ 執行的統計（**以運算量而非掛鐘時間**作為複雜度見證；
/// 工程約束禁止在沙盒做基準測試，故只報可重現的計數）。
pub struct DgRun {
  basis : Array[Implication]
  steps : Int32
  jumps : Int32
  closure_calls : Int32
  pc_iterations : Int32
}

///|
pub fn DgRun::basis(self : DgRun) -> Array[Implication] {
  self.basis
}

///|
/// NextClosure 步數（= 走訪的 clp-不動點數 = |ℭ_𝔓|）。
pub fn DgRun::steps(self : DgRun) -> Int32 {
  self.steps
}

///|
/// 嘗試過的「加一元素再閉包」次數（NextClosure 的跳躍搜尋）。
pub fn DgRun::jumps(self : DgRun) -> Int32 {
  self.jumps
}

///|
/// 呼叫 cl_S（真實上下文的閉包）的次數。
pub fn DgRun::closure_calls(self : DgRun) -> Int32 {
  self.closure_calls
}

///|
/// 偽閉包迭代的總輪數。
pub fn DgRun::pc_iterations(self : DgRun) -> Int32 {
  self.pc_iterations
}

///|
/// 原版 A3 需要檢查的候選數（2^n − 1，n ≥ 31 時回報上限值，避免溢位誤導）。
pub fn naive_candidate_count(n : Int32) -> Int64 {
  if n > 30 {
    return 2_147_483_647L
  }
  let mut p = 1L
  for _i = 0; _i < n; _i = _i + 1 {
    p = p * 2L
  }
  p - 1L
}

///|
/// P ⊊ Q（真子集）。
fn proper_subset(p : @bitset.BitSet, q : @bitset.BitSet) -> Bool {
  p.subset_of(q) && !p.equals(q)
}

///|
/// 偽閉包 clp_𝔓(X)：迭代 `X ∪ ⋃{Q'' : Q ∈ 𝔓, Q ⊊ X}` 至不動點。
/// 回傳 (不動點, 迭代輪數)。
fn pseudo_closure(
  found : Array[Implication],
  x : @bitset.BitSet,
) -> (@bitset.BitSet, Int32) {
  let mut cur = x.copy()
  let mut iters = 0
  let bound = found.length() + 2
  for _step = 0; _step < bound; _step = _step + 1 {
    let next = cur.copy()
    for j = 0; j < found.length(); j = j + 1 {
      if proper_subset(found[j].premise, cur) {
        next.union_inplace(found[j].conclusion)
      }
    }
    if next.equals(cur) {
      return (cur, iters)
    }
    cur = next
    iters = iters + 1
  }
  (cur, iters)
}

///|
/// 對閉包算子 clp_𝔓 跑 NextClosure 的單步：
/// lectic 序下大於 current 的**最小 clp-不動點**；None 表示 current 已最大。
fn next_pseudo_candidate(
  found : Array[Implication],
  n : Int32,
  current : @bitset.BitSet,
) -> (@bitset.BitSet, Int32, Int32)? {
  // 回傳 (候選, 嘗試次數, 偽閉包迭代輪數)
  let mut i = n - 1
  let mut jumps = 0
  let mut iters = 0
  while i >= 0 {
    if !current.get(i) {
      let masked = current.copy()
      for j = i; j < n; j = j + 1 {
        masked.unset(j)
      }
      masked.set(i)
      jumps = jumps + 1
      let (cand, it) = pseudo_closure(found, masked)
      iters = iters + it
      if cand.prefix_equal(masked, i) {
        return Some((cand, jumps, iters))
      }
    }
    i = i - 1
  }
  None
}

///|
/// A3′：增量式典範基（含統計）。
pub fn canonical_basis_incremental(ctx : @context.FormalContext) -> DgRun {
  let n = ctx.num_stmts()
  let found : Array[Implication] = []
  let mut steps = 0
  let mut jumps = 0
  let mut closure_calls = 0
  let mut pc_iterations = 0
  // 起點：最小 clp-不動點（= 偽閉包(∅)，不必是 ∅）
  let (start, it0) = pseudo_closure(found, @bitset.BitSet::new(n))
  pc_iterations = pc_iterations + it0
  let mut cur = start
  while true {
    steps = steps + 1
    let cl = closure_stmts(ctx, cur)
    closure_calls = closure_calls + 1
    if !cl.equals(cur) {
      // 驗收判準（D8）：所有真子集中的偽內涵 Q 都滿足 Q'' ⊆ cur。
      // 構造上由 clp 不動點保證；這裡仍顯式驗一次，避免「靠不變量默會」。
      let mut ok = true
      for j = 0; j < found.length(); j = j + 1 {
        if proper_subset(found[j].premise, cur) &&
          !found[j].conclusion.subset_of(cur) {
          ok = false
        }
      }
      if ok {
        found.push({ premise: cur, conclusion: cl, })
      }
    }
    match next_pseudo_candidate(found, n, cur) {
      None => break
      Some((nx, jp, it)) => {
        jumps = jumps + jp
        pc_iterations = pc_iterations + it
        cur = nx
      }
    }
  }
  { basis: found, steps, jumps, closure_calls, pc_iterations, }
}

///|
/// A3′ 的純粹輸出形式（與 A3 的 `canonical_basis` 可直接對照）。
pub fn canonical_basis_incremental_only(
  ctx : @context.FormalContext,
) -> Array[Implication] {
  canonical_basis_incremental(ctx).basis
}

///|
/// lectic 序的嚴格比較：A <_ℓ B ⟺ ∃i：i ∈ B∖A 且 A∩{0..i−1} = B∩{0..i−1}。
/// （結論可由前提唯一決定，故比較基時只需比前提。）
pub fn lectic_less(a : @bitset.BitSet, b : @bitset.BitSet) -> Bool {
  let n = a.size()
  if b.size() != n {
    abort("lectic_less：位元長度不一致")
  }
  for i = 0; i < n; i = i + 1 {
    if b.get(i) && !a.get(i) {
      if a.prefix_equal(b, i) {
        return true
      }
    }
  }
  false
}

///|
/// 兩份基是否為**同一族**蘊含（不看次序；次序另由 `check_basis_lectic` 檢核）。
/// 結論由前提唯一決定，故只比前提集合。
fn same_basis_set(a : Array[Implication], b : Array[Implication]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    let mut hit = false
    for j = 0; j < b.length(); j = j + 1 {
      if a[i].premise.equals(b[j].premise) &&
        a[i].conclusion.equals(b[j].conclusion) {
        hit = true
      }
    }
    if !hit {
      return false
    }
  }
  true
}

///|
/// 檢核 A3′ 與 A3（暴力版）在同一上下文上給出**逐條相同**的基。
/// 暴力版成本 O(2^n)，故 n > 20 時明示「未檢核」，不以綠燈冒充。
pub fn check_incremental_agrees_naive(ctx : @context.FormalContext) -> Check {
  let n = ctx.num_stmts()
  if n > 20 {
    return @galois.Check::make(
      "A3′",
      "增量基 == 暴力基",
      false,
      "未檢核：n=" +
      n.to_string() +
      " > 20，暴力版需 2^n 次候選判定",
    )
  }
  let naive = canonical_basis(ctx)
  let inc = canonical_basis_incremental(ctx)
  if !same_basis_set(naive, inc.basis) {
    let mut msg = "基不一致：暴力 " + naive.length().to_string()
    msg = msg + " 條、增量 " + inc.basis.length().to_string() + " 條"
    for i = 0; i < naive.length(); i = i + 1 {
      let mut hit = false
      for j = 0; j < inc.basis.length(); j = j + 1 {
        if naive[i].premise.equals(inc.basis[j].premise) {
          hit = true
        }
      }
      if !hit {
        msg = msg +
          "；只在暴力版出現：" +
          render_implication(ctx, naive[i])
        break
      }
    }
    return @galois.Check::make(
      "A3′", "增量基 == 暴力基（同一族）", false, msg,
    )
  }
  @galois.Check::make(
    "A3′",
    "增量基 == 暴力基（同一族）",
    true,
    "|Σ|=" +
    inc.basis.length().to_string() +
    "；增量走了 " +
    inc.steps.to_string() +
    " 步（暴力候選 2^n−1=" +
    naive_candidate_count(n).to_string() +
    "）",
  )
}

///|
/// 以 (P, Q) 對錶示一份基。
fn pairs_of(
  basis : Array[Implication],
) -> Array[(@bitset.BitSet, @bitset.BitSet)] {
  let out : Array[(@bitset.BitSet, @bitset.BitSet)] = []
  for i = 0; i < basis.length(); i = i + 1 {
    out.push((basis[i].premise, basis[i].conclusion))
  }
  out
}

///|
/// 對「Horn 理論本身」跑 NextClosure 的單步（閉包 = 由 Σ 前向推導）。
fn next_theory_closed(
  n : Int32,
  pairs : Array[(@bitset.BitSet, @bitset.BitSet)],
  current : @bitset.BitSet,
) -> @bitset.BitSet? {
  let mut i = n - 1
  while i >= 0 {
    if !current.get(i) {
      let masked = current.copy()
      for j = i; j < n; j = j + 1 {
        masked.unset(j)
      }
      masked.set(i)
      let cand = @galois.closure_via_basis(n, pairs, masked)
      if cand.prefix_equal(masked, i) {
        return Some(cand)
      }
    }
    i = i - 1
  }
  None
}

///|
/// 由基導出的全部閉集（lecic 序）。
pub fn theory_closed_sets(
  n : Int32,
  basis : Array[Implication],
  limit : Int32,
) -> Array[@bitset.BitSet] {
  let pairs = pairs_of(basis)
  let out : Array[@bitset.BitSet] = []
  let mut cur = @galois.closure_via_basis(n, pairs, @bitset.BitSet::new(n))
  let mut steps = 0
  while steps < limit {
    steps = steps + 1
    out.push(cur)
    match next_theory_closed(n, pairs, cur) {
      Some(nx) => cur = nx
      None => return out
    }
  }
  out
}

///|
/// 把兩個閉集族比較（逐元素，要求**同一族**；不看次序）。
fn same_family(a : Array[@bitset.BitSet], b : Array[@bitset.BitSet]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  for i = 0; i < a.length(); i = i + 1 {
    let mut hit = false
    for j = 0; j < b.length(); j = j + 1 {
      if a[i].equals(b[j]) {
        hit = true
      }
    }
    if !hit {
      return false
    }
  }
  true
}

///|
/// T4（完備＋可靠）在**任意 n** 的可判定版本：
/// 由 Σ 定義的 Horn 閉包系統，其閉集族必須與 K 的閉集族完全相同。
/// 兩側都用 NextClosure 枚舉（成本 ∝ 閉集數，不出現 2^n），故 n = 24 仍可判定。
pub fn check_theory_equivalent(
  ctx : @context.FormalContext,
  basis : Array[Implication],
) -> Check {
  let n = ctx.num_stmts()
  let from_ctx = all_closed_stmts(ctx)
  let from_basis = theory_closed_sets(n, basis, 1_000_000)
  if !same_family(from_ctx, from_basis) {
    let mut msg = "閉集族不同：K 有 " + from_ctx.length().to_string()
    msg = msg + " 個、Σ 有 " + from_basis.length().to_string() + " 個"
    for i = 0; i < from_ctx.length(); i = i + 1 {
      let mut hit = false
      for j = 0; j < from_basis.length(); j = j + 1 {
        if from_ctx[i].equals(from_basis[j]) {
          hit = true
        }
      }
      if !hit {
        msg = msg + "；K 有而 Σ 缺：" + ctx.render_stmts(from_ctx[i])
        break
      }
    }
    return @galois.Check::make("T4", "Σ 與 K 閉集族相同", false, msg)
  }
  @galois.Check::make(
    "T4",
    "Σ 與 K 閉集族相同",
    true,
    "|ℭ|=" +
    from_ctx.length().to_string() +
    "，|Σ|=" +
    basis.length().to_string(),
  )
}

///|
/// T4（非冗餘，適用任意 n）：刪去任一條 P → Q 後，P 的閉包必須**真的變小**。
/// 這是典範基最小性的直接判準，成本 O(|Σ|²·n)，不含 2^n。
pub fn check_theory_irredundant(
  ctx : @context.FormalContext,
  basis : Array[Implication],
) -> Check {
  let n = ctx.num_stmts()
  for drop = 0; drop < basis.length(); drop = drop + 1 {
    let reduced : Array[Implication] = []
    for k = 0; k < basis.length(); k = k + 1 {
      if k != drop {
        reduced.push(basis[k])
      }
    }
    let pairs = pairs_of(reduced)
    let p = basis[drop].premise
    let got = @galois.closure_via_basis(n, pairs, p)
    if basis[drop].conclusion.subset_of(got) {
      return @galois.Check::make(
        "T4",
        "典範基非冗餘（任意 n）",
        false,
        "刪去 " +
        render_implication(ctx, basis[drop]) +
        " 後仍可推得結論 → 冗餘",
      )
    }
  }
  @galois.Check::make(
    "T4",
    "典範基非冗餘（任意 n）",
    true,
    "|Σ|=" + basis.length().to_string(),
  )
}

///|
/// A3′ 的**輸出次序**性質：走訪序列本身必須是嚴格 lectic 遞增（NextClosure 的延遲保證）。
pub fn check_basis_lectic(basis : Array[Implication]) -> Check {
  for i = 0; i + 1 < basis.length(); i = i + 1 {
    if !lectic_less(basis[i].premise, basis[i + 1].premise) {
      return @galois.Check::make(
        "A3′",
        "輸出為 lectic 遞增",
        false,
        "第 " +
        i.to_string() +
        " 與 " +
        (i + 1).to_string() +
        " 條不呈 lectic 遞增",
      )
    }
  }
  @galois.Check::make(
    "A3′",
    "輸出為 lectic 遞增",
    true,
    "|Σ|=" + basis.length().to_string(),
  )
}

///|
/// A3′ 的完整檢核報告：與暴力版一致（有預算時）＋ lectic 次序＋ Horn 理論等價＋非冗餘。
pub fn dg_report(ctx : @context.FormalContext) -> Report {
  let r = Report::new()
  let run = canonical_basis_incremental(ctx)
  r.add(check_incremental_agrees_naive(ctx))
  r.add(check_basis_lectic(run.basis))
  r.add(check_theory_equivalent(ctx, run.basis))
  r.add(check_theory_irredundant(ctx, run.basis))
  r
}

///|
/// 一行統計摘要：|Σ|、走訪步數、跳躍次數、cl_S 呼叫次數、偽閉包輪數、暴力候選數。
pub fn dg_stats_line(ctx : @context.FormalContext) -> String {
  let run = canonical_basis_incremental(ctx)
  let n = ctx.num_stmts()
  let naive = naive_candidate_count(n)
  let mut s = "|Σ|=" + run.basis.length().to_string()
  s = s + "；A3′ 走訪 " + run.steps.to_string() + " 步"
  s = s +
    "（跳躍 " +
    run.jumps.to_string() +
    " 次、cl_S 呼叫 " +
    run.closure_calls.to_string()
  s = s + " 次、偽閉包迭代 " + run.pc_iterations.to_string() + " 輪）"
  s = s + "；A3 暴力需 2^n−1=" + naive.to_string() + " 次候選判定"
  s
}

///|
/// 整份基的文字形式（每行一條）。
pub fn render_basis(
  ctx : @context.FormalContext,
  basis : Array[Implication],
) -> String {
  let mut s = ""
  for i = 0; i < basis.length(); i = i + 1 {
    s = s +
      "  Σ" +
      i.to_string() +
      "： " +
      render_implication(ctx, basis[i]) +
      "\n"
  }
  s
}
