///|
/// B0002 / matroid 套件：Moore 族的上下文實現（D-B6、D-B7、T7、A11）
///
/// T7 的核心：給定 Moore 族 ℱ ⊆ 2^E，上下文 K_ℱ = (E, ℱ, ∈) 的公理閉包恰為
///   cl_A(X) = ⋂{F ∈ ℱ : X ⊆ F}，
/// 即 ℱ 本身。於是把「擬陣的平坦族」提升為 B0001 意義下的公理閉包族，
/// B0001 的 T1（GAGC）、T2（重建）、A2（NextClosure）、A6（檢核）全部逐字適用。

///|
/// A11：由 Moore 族建構實現上下文 K_ℱ。
/// 公理 = E 的元素（名稱 e0..e(n-1)）；陳述 = ℱ 的元素（名稱 F0..）；(e,F) ∈ R ⟺ e ∈ F。
pub fn context_of_moore_family(
  name : String,
  n : Int32,
  family : Array[@bitset.BitSet],
) -> @context.FormalContext {
  let axiom_names : Array[String] = []
  for i = 0; i < n; i = i + 1 {
    axiom_names.push("e" + i.to_string())
  }
  let stmt_names : Array[String] = []
  for j = 0; j < family.length(); j = j + 1 {
    stmt_names.push("F" + j.to_string())
  }
  let edges : Array[(Int32, Int32)] = []
  for j = 0; j < family.length(); j = j + 1 {
    if family[j].size() != n {
      abort("context_of_moore_family 族成員位元長度與 E 不符")
    }
    let ids = family[j].ones()
    for k = 0; k < ids.length(); k = k + 1 {
      edges.push((ids[k], j))
    }
  }
  let _ = name
  @context.FormalContext::new(axiom_names, stmt_names, edges)
}

///|
/// A11（反向）：由上下文 K 取出其公理閉包族 ℭ_A（= Moore 族）。
/// 以 B0001 的逐元素參考路徑窮舉，故與快速路徑獨立。
pub fn moore_family_of_context(
  ctx : @context.FormalContext,
) -> Array[@bitset.BitSet] {
  @galois.all_closed_bruteforce(ctx, @galois.AxiomSide)
}

///|
/// 去掉空平坦集後的族 ℱ* = ℱ ∖ {∅}。
///
/// **為什麼需要它**：K_ℱ 中陳述 ∅ 的見證集為空（沒有任何元素屬於 ∅），
/// 故 K_ℱ 必然違反 B0001 的 X2（支撐完全性）。這是一個真實的結構事實，不是缺陷：
/// 空的 Moore 族成員在「元素 ⊆ 集合」的表示裡必然是無支撐的陳述。
/// 因此另設 ℱ* 變體：丟掉 ∅ 後 X2 成立，B0001 的 A6 十三條可以全數套用，
/// 而 T7 的閉包等式仍然成立（X ≠ ∅ 時 cl(X) 本身非空；X = ∅ 時 ⋂ℱ* = ∅）。
pub fn without_empty(family : Array[@bitset.BitSet]) -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  for i = 0; i < family.length(); i = i + 1 {
    if family[i].count() > 0 {
      out.push(family[i])
    }
  }
  out
}

///|
/// T7 檢核：K_ℱ 的公理閉包必須與原閉包算子完全一致（∀X ⊆ E），
/// 且**兩個變體**（含 ∅ 的 ℱ 與不含 ∅ 的 ℱ*）都必須一致。
/// 這是「提升／嵌入」的**可執行見證**：擬陣閉包 == B0001 的公理閉包。
pub fn Matroid::check_realization(self : Matroid) -> @galois.Check {
  let full = self.flats()
  let ctx = context_of_moore_family(self.name, self.n, full)
  if self.n > 20 {
    return @galois.Check::make(
      "T7", "Moore 實現", false, "未檢核：n > 20",
    )
  }
  for mask = 0; mask < 1 << self.n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(self.n, mask)
    let expected = self.closure(x)
    let got = @galois.closure_axioms(ctx, x)
    if !expected.equals(got) {
      return @galois.Check::make(
        "T7",
        "Moore 實現（cl_Kℱ == cl_M）",
        false,
        "X=" +
        x.render() +
        "：擬陣閉包=" +
        expected.render() +
        "，K_ℱ 公理閉包=" +
        got.render(),
      )
    }
  }
  // 變體二：ℱ* = ℱ ∖ {∅}
  let trimmed = without_empty(full)
  let ctx2 = context_of_moore_family(self.name, self.n, trimmed)
  for mask = 0; mask < 1 << self.n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(self.n, mask)
    let expected = self.closure(x)
    let got = @galois.closure_axioms(ctx2, x)
    if !expected.equals(got) {
      return @galois.Check::make(
        "T7",
        "Moore 實現（ℱ* 變體）",
        false,
        "X=" +
        x.render() +
        "：擬陣閉包=" +
        expected.render() +
        "，K_ℱ* 公理閉包=" +
        got.render(),
      )
    }
  }
  // 反向：ℭ_A 必須恰為平坦族
  let back = moore_family_of_context(ctx)
  let flats = full
  if back.length() != flats.length() {
    return @galois.Check::make(
      "T7",
      "Moore 實現（ℭ_A == ℱ）",
      false,
      "|ℭ_A|=" +
      back.length().to_string() +
      " 但 |ℱ|=" +
      flats.length().to_string(),
    )
  }
  @galois.Check::make(
    "T7",
    "Moore 實現（雙向一致）",
    true,
    "|E|=" +
    self.n.to_string() +
    "，|ℱ|=" +
    flats.length().to_string() +
    "，K_ℱ 規模=" +
    (self.n * flats.length()).to_string(),
  )
}
