///|
/// B0001 / lattice 套件：A3 Duquenne–Guiguès 典範基
/// 對應 docs/B0001-定理體系.md：D7、D8、P6、T4、E9、E12。
///
/// 演算法（P6 的直譯）：依**基數遞增**次序走訪 S 的所有子集；
/// 處理 Q 時，所有真子集已判定完畢，故 D8 的定義可直接判定。
/// 時間 O(2^n·n·|Σ|)（輸出本質上可指數，故不宣稱多項式時間）。

///|
/// 一條蘊含 P → Q（P、Q ⊆ S）。
pub struct Implication {
  premise : @bitset.BitSet
  conclusion : @bitset.BitSet
}

///|
pub fn Implication::premise(self : Implication) -> @bitset.BitSet {
  self.premise
}

///|
pub fn Implication::conclusion(self : Implication) -> @bitset.BitSet {
  self.conclusion
}

///|
/// A3：偽內涵（D8）及其閉包，依基數遞增排列。
pub fn pseudo_intents(ctx : @context.FormalContext) -> Array[Implication] {
  let n = ctx.num_stmts()
  let subs = @bitset.subsets_by_cardinality(n)
  let found : Array[Implication] = []
  for i = 0; i < subs.length(); i = i + 1 {
    let q = subs[i]
    let cl_q = closure_stmts(ctx, q)
    if cl_q.equals(q) {
      continue
    }
    let mut ok = true
    for j = 0; j < found.length(); j = j + 1 {
      let p = found[j].premise
      // 只需考慮真子集 P ⊊ Q
      if p.subset_of(q) && !p.equals(q) && !found[j].conclusion.subset_of(q) {
        ok = false
      }
    }
    if ok {
      found.push({ premise: q, conclusion: cl_q, })
    }
  }
  found
}

///|
/// A3：Duquenne–Guiguès 典範基 Σ = { P → cl_S(P) | P 偽內涵 }。
pub fn canonical_basis(ctx : @context.FormalContext) -> Array[Implication] {
  pseudo_intents(ctx)
}

///|
/// 典範基的規模（供登記表記錄）。
pub fn basis_size(ctx : @context.FormalContext) -> Int32 {
  canonical_basis(ctx).length()
}

///|
/// 轉為 galois.closure_via_basis 所需的 (P, Q) 對。
fn to_pairs(
  basis : Array[Implication],
) -> Array[(@bitset.BitSet, @bitset.BitSet)] {
  let out : Array[(@bitset.BitSet, @bitset.BitSet)] = []
  for i = 0; i < basis.length(); i = i + 1 {
    out.push((basis[i].premise, basis[i].conclusion))
  }
  out
}

///|
/// 超額預算時的一致回報（**不以綠燈冒充**：pass=false 且明示「未檢核」）。
fn not_checked(name : String, why : String) -> Check {
  @galois.Check::make("T4", name, false, "未檢核：" + why)
}

///|
/// T4（完備性檢核）：∀Y ⊆ S，Y 閉 ⟺ Y 對 Σ 封閉。
/// 「對 Σ 封閉」以 Horn 前向鏈推導（closure_via_basis）判定。
pub fn check_basis_completeness(
  ctx : @context.FormalContext,
  basis : Array[Implication],
) -> Check {
  let n = ctx.num_stmts()
  if n > 20 {
    return not_checked(
      "典範基完備性",
      "n=" + n.to_string() + " > 20，超出窮舉預算",
    )
  }
  let pairs = to_pairs(basis)
  let subs = @bitset.all_subsets(n)
  for i = 0; i < subs.length(); i = i + 1 {
    let y = subs[i]
    let closed = closure_stmts(ctx, y).equals(y)
    let respects = @galois.closure_via_basis(n, pairs, y).equals(y)
    if closed != respects {
      return @galois.Check::make(
        "T4",
        "典範基完備性",
        false,
        "Y=" +
        ctx.render_stmts(y) +
        "：cl_S 判定閉=" +
        closed.to_string() +
        "，對 Σ 封閉=" +
        respects.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T4",
    "典範基完備性",
    true,
    "Σ 規模=" + basis.length().to_string(),
  )
}

///|
/// T4（非冗餘檢核）：刪去任一條蘊含後，完備性必須失效。
pub fn check_basis_nonredundant(
  ctx : @context.FormalContext,
  basis : Array[Implication],
) -> Check {
  let n = ctx.num_stmts()
  if n > 20 {
    return not_checked(
      "典範基非冗餘",
      "n=" + n.to_string() + " > 20，超出窮舉預算",
    )
  }
  let budget = basis.length() * (1 << n)
  if budget > 4_000_000 {
    return not_checked(
      "典範基非冗餘",
      "預算 |Σ|·2^n=" + budget.to_string() + " 超出 4,000,000",
    )
  }
  let subs = @bitset.all_subsets(n)
  for drop = 0; drop < basis.length(); drop = drop + 1 {
    let reduced : Array[Implication] = []
    for k = 0; k < basis.length(); k = k + 1 {
      if k != drop {
        reduced.push(basis[k])
      }
    }
    let pairs = to_pairs(reduced)
    let mut still_complete = true
    for i = 0; i < subs.length(); i = i + 1 {
      let y = subs[i]
      let closed = closure_stmts(ctx, y).equals(y)
      let respects = @galois.closure_via_basis(n, pairs, y).equals(y)
      if closed != respects {
        still_complete = false
      }
    }
    if still_complete {
      return @galois.Check::make(
        "T4",
        "典範基非冗餘",
        false,
        "刪去第 " +
        drop.to_string() +
        " 條蘊含（" +
        render_implication(ctx, basis[drop]) +
        "）後仍完備 → 冗餘",
      )
    }
  }
  @galois.Check::make("T4", "典範基非冗餘", true, "")
}

///|
/// T4（一致性檢核）：對所有 Y，由 Σ 前向推導的閉包 == cl_S(Y)（比完備性更強）。
pub fn check_basis_agreement(
  ctx : @context.FormalContext,
  basis : Array[Implication],
) -> Check {
  let n = ctx.num_stmts()
  if n > 20 {
    return not_checked(
      "基誘導閉包一致",
      "n=" + n.to_string() + " > 20，超出窮舉預算",
    )
  }
  let pairs = to_pairs(basis)
  let subs = @bitset.all_subsets(n)
  for i = 0; i < subs.length(); i = i + 1 {
    let y = subs[i]
    let expected = closure_stmts(ctx, y)
    let got = @galois.closure_via_basis(n, pairs, y)
    if !expected.equals(got) {
      return @galois.Check::make(
        "T4",
        "基誘導閉包一致",
        false,
        "Y=" +
        ctx.render_stmts(y) +
        "：cl_S=" +
        ctx.render_stmts(expected) +
        "，Σ 推導=" +
        ctx.render_stmts(got),
      )
    }
  }
  @galois.Check::make("T4", "基誘導閉包一致", true, "")
}

///|
/// 一條蘊含的文字形式：P → Q。
pub fn render_implication(
  ctx : @context.FormalContext,
  imp : Implication,
) -> String {
  ctx.render_stmts(imp.premise) + " → " + ctx.render_stmts(imp.conclusion)
}

///|
/// lattice 套件的完整檢核報告（A2、A3、A5）。
pub fn basis_report(ctx : @context.FormalContext) -> Report {
  let basis = canonical_basis(ctx)
  let r = Report::new()
  r.add(check_basis_completeness(ctx, basis))
  r.add(check_basis_nonredundant(ctx, basis))
  r.add(check_basis_agreement(ctx, basis))
  r.add(check_nextclosure(ctx))
  r.add(check_covers(ctx))
  r
}
