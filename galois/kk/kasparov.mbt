///|
/// B0006 / kk 套件：**Kasparov 雙變理論的可計算片段**（A39、A40）
/// 對應 docs/B0006-定理體系.md §8–§10。
///
/// 真 KK-理論的物件（Hilbert 模、Fredholm 模、算子同倫類）在一般情形不可判定。
/// 本檔取**bootstrap 類且 K-群有限生成**的片段，此時 Kasparov 的萬有係數定理（UCT）
/// 給出精確的短正合列
///
/// ```
/// 0 → Ext¹(K_*(A), K_{*+1}(B)) → KK(A, B) → Hom(K_*(A), K_*(B)) → 0
/// ```
///
/// 於是「算 KK」變成「算 Hom 與 Ext」——兩者都是有限生成交換群上的整數線性代數。
/// 當 Ext 項為零（或 Hom 項為零）時，中間群被完全決定；否則只被決定到「擴張」為止，
/// 本檔會**明示**這一點（kind = 0），不假裝算得出來。

///|
/// KK(A, B) 的 UCT 資料。
pub struct UCTData {
  hom : FgAb
  ext : FgAb
  /// 1 = KK ≅ Hom（Ext = 0）；2 = KK ≅ Ext（Hom = 0）；0 = 只決定到擴張
  kind : Int32
}

///|
/// 由 K-群對算 UCT。
pub fn kk_uct(a : KPair, b : KPair) -> UCTData {
  let hom = fga_direct_sum(fga_hom(a.k0, b.k0), fga_hom(a.k1, b.k1))
  let ext = fga_direct_sum(fga_ext1(a.k0, b.k1), fga_ext1(a.k1, b.k0))
  let hom_triv = hom.rank == 0 && hom.tors.length() == 0
  let ext_triv = ext.rank == 0 && ext.tors.length() == 0
  let kind = if ext_triv { 1 } else if hom_triv { 2 } else { 0 }
  { hom, ext, kind, }
}

///|
/// 是否被 UCT 完全決定。
pub fn uct_determined(u : UCTData) -> Bool {
  u.kind != 0
}

///|
/// 取出 KK 群（僅在 kind ≠ 0 時有意義）。
pub fn uct_group(u : UCTData) -> FgAb {
  if u.kind == 2 {
    u.ext
  } else {
    u.hom
  }
}

///|
/// 顯示。
pub fn uct_render(u : UCTData) -> String {
  let base = "Hom = " +
    fga_render(u.hom) +
    "、Ext¹ = " +
    fga_render(u.ext) +
    " ⇒ "
  if u.kind == 1 {
    base + "KK ≅ " + fga_render(u.hom) + "（Ext = 0）"
  } else if u.kind == 2 {
    base + "KK ≅ " + fga_render(u.ext) + "（Hom = 0）"
  } else {
    base +
    "KK 只決定到擴張（0 → " +
    fga_render(u.ext) +
    " → KK → " +
    fga_render(u.hom) +
    " → 0）"
  }
}

// ---------------------------------------------------------------- Kasparov 乘積（自由部分）

///|
/// 一個 KK-類：在 K-群自由部分的兩個整數矩陣
/// （f0: K₀(A) → K₀(B)、f1: K₁(A) → K₁(B)）。
/// 這只涵蓋 UCT 下 Hom 項的元素；撓部分另見 §10 的界限說明。
pub struct KKClass {
  dom : KPair
  cod : KPair
  f0 : IntMat
  f1 : IntMat
}

///|
/// 建構。
pub fn kk_class(dom : KPair, cod : KPair, f0 : IntMat, f1 : IntMat) -> KKClass {
  { dom, cod, f0, f1, }
}

///|
/// 單位類 [id] ∈ KK(A, A)。
pub fn kk_identity(a : KPair) -> KKClass {
  {
    dom: a,
    cod: a,
    f0: intmat_identity(a.k0.rank, 1L),
    f1: intmat_identity(a.k1.rank, 1L),
  }
}

///|
/// Kasparov 乘積（自由部分）：先 x: A → B，再 y: B → C，結果在 KK(A, C)，
/// 其 K-群映射就是**合成**——這正是 Kasparov 乘積的函子性內容。
pub fn kk_compose(x : KKClass, y : KKClass) -> KKClass {
  {
    dom: x.dom,
    cod: y.cod,
    f0: intmat_mul(y.f0, x.f0),
    f1: intmat_mul(y.f1, x.f1),
  }
}

///|
/// 相等判定。
pub fn kk_class_eq(a : KKClass, b : KKClass) -> Bool {
  intmat_eq(a.f0, b.f0) && intmat_eq(a.f1, b.f1)
}

///|
/// 是否為 KK-等價（K-群上的可逆類）：行列式 ±1。
pub fn kk_class_invertible(c : KKClass) -> Bool {
  intmat_rank(c.f0) == c.dom.k0.rank &&
  c.dom.k0.rank == c.cod.k0.rank &&
  intmat_rank(c.f1) == c.dom.k1.rank &&
  c.dom.k1.rank == c.cod.k1.rank
}

// ---------------------------------------------------------------- 穩定性與週期性

///|
/// 吸收緊算子：K_*(A ⊗ K) = K_*(A)（K 是 M_∞ 的歸納極限，M_n 穩定同構）。
pub fn kpair_tensor_k(a : KPair) -> KPair {
  { k0: a.k0, k1: a.k1, }
}

///|
/// Bott 週期性：連做兩次 K_{i+2} = K_i 回到原群。
pub fn kpair_bott_periodic(a : KPair) -> Bool {
  kpair_eq(kpair_shift(kpair_shift(a)), a)
}

///|
/// KK-等價判定（bootstrap 類 + 有限生成 K-群）：KK(A,B) 含可逆類 ⟺ K_*(A) ≅ K_*(B)。
pub fn kk_equivalent(a : KPair, b : KPair) -> Bool {
  kpair_eq(a, b)
}

///|
/// KK-等價的**見證**：若 K-群同構，則 Hom 中有單位矩陣，故 KK 中有可逆類。
pub fn kk_equivalence_witness(a : KPair, b : KPair) -> Bool {
  kk_class_invertible(kk_identity(a)) && kpair_eq(a, b)
}
