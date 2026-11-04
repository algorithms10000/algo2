///|
/// B0001 / galois 套件：閉包算子（A1）與局部閉包（A4）
/// 對應 docs/B0001-定理體系.md：D4、D5、L3、L4、T1(2)、T2、T3。

///|
/// A1：公理側閉包 cl_A(X) = Ψ(Φ(X))。
/// 由 L4（三角恆等），單次雙閉包即定點，故不需迭代。
/// 時間 O(|X|·⌈n/64⌉ + |Φ(X)|·⌈m/64⌉)。
pub fn closure_axioms(
  ctx : @context.FormalContext,
  extent : @bitset.BitSet,
) -> @bitset.BitSet {
  ctx.extent(ctx.intent(extent))
}

///|
/// A1：陳述側閉包 cl_S(Y) = Φ(Ψ(Y))。
pub fn closure_stmts(
  ctx : @context.FormalContext,
  intent : @bitset.BitSet,
) -> @bitset.BitSet {
  ctx.intent(ctx.extent(intent))
}

///|
/// D5：X 是否為公理閉包（閉集）。
pub fn is_closed_axioms(
  ctx : @context.FormalContext,
  extent : @bitset.BitSet,
) -> Bool {
  closure_axioms(ctx, extent).equals(extent)
}

///|
/// D5：Y 是否為陳述閉包（閉集）。
pub fn is_closed_stmts(
  ctx : @context.FormalContext,
  intent : @bitset.BitSet,
) -> Bool {
  closure_stmts(ctx, intent).equals(intent)
}

///|
/// T2 / E8：單點閉包 cl_A({a}) = { a′ | row(a) ⊆ row(a′) }。
pub fn singleton_closure(
  ctx : @context.FormalContext,
  a : Int32,
) -> @bitset.BitSet {
  let x = @bitset.BitSet::singleton(ctx.num_axioms(), a)
  closure_axioms(ctx, x)
}

///|
/// T2：回傳可被其他公理導出的公理（冗餘公理）索引；正常（X3 分離性）時為空。
pub fn redundant_axioms(ctx : @context.FormalContext) -> Array[Int32] {
  let out : Array[Int32] = []
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    let cl = singleton_closure(ctx, a)
    if cl.count() != 1 || !cl.get(a) {
      out.push(a)
    }
  }
  out
}

///|
/// T3 的判定結果。
pub struct LocalClosure {
  closure : @bitset.BitSet
  collapsed : Bool
  component : Int32
}

///|
pub fn LocalClosure::closure(self : LocalClosure) -> @bitset.BitSet {
  self.closure
}

///|
/// 是否發生跨分量坍縮（T3(1)(3)：cl = A）。
pub fn LocalClosure::collapsed(self : LocalClosure) -> Bool {
  self.collapsed
}

///|
/// 觸及的分量編號；多於一個時為 -1。
pub fn LocalClosure::component(self : LocalClosure) -> Int32 {
  self.component
}

///|
/// A4：預先算好的分量分解，避免每次閉包都重建子上下文。
pub struct Decomposition {
  comps : Array[@context.Component]
  subs : Array[@context.FormalContext]
  comp_of_axiom : Array[Int32]
}

///|
/// 以並查集切分量，並為每個分量建立子上下文（X4）。
pub fn decompose(ctx : @context.FormalContext) -> Decomposition {
  let comps = @context.components_of(ctx)
  let subs : Array[@context.FormalContext] = []
  for i = 0; i < comps.length(); i = i + 1 {
    subs.push(@context.sub_context(ctx, comps[i]))
  }
  let comp_of_axiom = @context.component_id_of_axiom(ctx)
  { comps, subs, comp_of_axiom, }
}

///|
pub fn Decomposition::component_count(self : Decomposition) -> Int32 {
  self.comps.length()
}

///|
pub fn Decomposition::component(
  self : Decomposition,
  i : Int32,
) -> @context.Component {
  self.comps[i]
}

///|
pub fn Decomposition::sub_context(
  self : Decomposition,
  i : Int32,
) -> @context.FormalContext {
  self.subs[i]
}

///|
/// A4：依 T3 計算閉包，並標記是否坍縮。
/// - X 為空：直接走全域雙閉包（T3 未涵蓋空集）。
/// - X 觸及 ≥2 分量：坍縮，cl = A（T3(1)）。
/// - X 只觸及分量 i：若 Φ(X) = ∅ 則坍縮（T3(3)），否則 cl = cl_{A_i}(X)（T3(2)），
///   在子上下文上計算後映射回全域索引。
pub fn local_closure(
  ctx : @context.FormalContext,
  dec : Decomposition,
  extent : @bitset.BitSet,
) -> LocalClosure {
  let ids = extent.ones()
  if ids.length() == 0 {
    return {
      closure: closure_axioms(ctx, extent),
      collapsed: false,
      component: -1,
    }
  }
  let first_comp = dec.comp_of_axiom[ids[0]]
  let mut single = true
  for k = 1; k < ids.length(); k = k + 1 {
    if dec.comp_of_axiom[ids[k]] != first_comp {
      single = false
    }
  }
  if !single {
    return {
      closure: @bitset.BitSet::full(ctx.num_axioms()),
      collapsed: true,
      component: -1,
    }
  }
  let comp = dec.comps[first_comp]
  let sub = dec.subs[first_comp]
  // 分量內座標
  let local_ids : Array[Int32] = []
  for k = 0; k < ids.length(); k = k + 1 {
    let want = ids[k]
    for j = 0; j < comp.axioms.length(); j = j + 1 {
      if comp.axioms[j] == want {
        local_ids.push(j)
      }
    }
  }
  let local_set = @bitset.BitSet::from_indices(sub.num_axioms(), local_ids)
  let local_intent = sub.intent(local_set)
  if local_intent.is_empty() {
    return {
      closure: @bitset.BitSet::full(ctx.num_axioms()),
      collapsed: true,
      component: first_comp,
    }
  }
  let local_cl = sub.extent(local_intent)
  let out = @bitset.BitSet::new(ctx.num_axioms())
  let kept = local_cl.ones()
  for k = 0; k < kept.length(); k = k + 1 {
    out.set(comp.axioms[kept[k]])
  }
  { closure: out, collapsed: false, component: first_comp, }
}
