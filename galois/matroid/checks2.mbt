///|
/// B0002 延伸 / matroid 套件：**檢核器（T9–T12）**
/// 對應 docs/B0002-定理體系.md §10–§13。
///
/// 檢核策略一律是「兩條獨立路徑互相對照」，而不是拿程式跟自己比：
///   T9  禁 minor 判準（Tutte） vs 基本迴路顯式 GF(2) 構造
///   T10 對偶秩公式 vs 對偶擬陣的迴路；T_{M*}(x,y) = T_M(y,x)
///   T11 均勻擬陣平坦數 vs 二項式公式
///   T12 刪除–壓縮遞迴 vs 子集和公式；Tutte 特化值 vs 計數；
///       特徵多項式（定義式） vs (−1)^r T(1−λ,0)；圖擬陣的 χ vs 正常著色數

///|
/// T9：兩條二元性判定必須一致。
pub fn check_binary_two_routes(m : Matroid) -> @galois.Check {
  let by_minors = m.is_binary_by_minors()
  let by_construction = m.is_binary_by_construction()
  if by_minors != by_construction {
    return @galois.Check::make(
      "T9",
      "二元性兩路徑一致",
      false,
      m.name() +
      "：禁 minor 判準=" +
      by_minors.to_string() +
      "，基本迴路構造=" +
      by_construction.to_string(),
    )
  }
  @galois.Check::make(
    "T9",
    "二元性兩路徑一致",
    true,
    m.name() + "：" + (if by_minors { "二元" } else { "非二元" }),
  )
}

///|
/// T9：若非二元，指出實際出現的禁 minor（U(2,4)、F7、F7*）。
pub fn check_forbidden_minor_witness(m : Matroid) -> @galois.Check {
  let u = Matroid::uniform(2, 4)
  let fano = Matroid::fano()
  let fdual = fano.dual()
  let hits : Array[String] = []
  let regular_hits : Array[String] = []
  if m.has_minor_in([u]) {
    hits.push("U(2,4)")
    regular_hits.push("U(2,4)")
  }
  if m.has_minor_in([fano]) {
    regular_hits.push("F7")
  }
  if m.has_minor_in([fdual]) {
    regular_hits.push("F7*")
  }
  let binary = hits.length() == 0
  let by_construction = m.is_binary_by_construction()
  if binary != by_construction {
    return @galois.Check::make(
      "T9",
      "禁 minor 見證",
      false,
      m.name() + "：禁 minor 清單為空但構造判定非二元",
    )
  }
  let mut detail = m.name() + "："
  if binary {
    detail = detail + "無 U(2,4) minor ⇒ 二元"
  } else {
    for i = 0; i < hits.length(); i = i + 1 {
      if i > 0 {
        detail = detail + "、"
      }
      detail = detail + hits[i]
    }
    detail = detail + " ⇒ 非二元"
  }
  if regular_hits.length() == 0 {
    detail = detail + "；無 {U(2,4),F7,F7*} minor ⇒ 正則"
  } else {
    detail = detail + "；正則禁集命中："
    for i = 0; i < regular_hits.length(); i = i + 1 {
      if i > 0 {
        detail = detail + "、"
      }
      detail = detail + regular_hits[i]
    }
  }
  @galois.Check::make("T9", "禁 minor 見證", true, detail)
}

///|
/// T10：對偶擬陣的秩 == 公式 r*(X) = |X| − r(E) + r(E∖X)（全部子集）。
pub fn check_dual_rank(m : Matroid) -> @galois.Check {
  let dual = m.dual()
  let n = m.ground_size()
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(n, mask)
    let want = m.dual_rank(x)
    let got = dual.rank(x)
    if want != got {
      return @galois.Check::make(
        "T10",
        "對偶秩公式",
        false,
        m.name() +
        "：X=" +
        x.render() +
        "，公式=" +
        want.to_string() +
        "，實得=" +
        got.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T10",
    "對偶秩公式",
    true,
    m.name() + "：r*=|X|−r(E)+r(E∖X)",
  )
}

///|
/// T10：(M*)* ≅ M。
pub fn check_double_dual(m : Matroid) -> @galois.Check {
  let dd = m.dual().dual()
  if !isomorphic(m, dd) {
    return @galois.Check::make(
      "T10",
      "雙對偶",
      false,
      m.name() + "：(M*)* 不同構於 M",
    )
  }
  @galois.Check::make("T10", "雙對偶", true, m.name())
}

///|
/// T10：T_{M*}(x,y) = T_M(y,x)。
pub fn check_tutte_dual(m : Matroid) -> @galois.Check {
  let t = m.tutte()
  let ts = m.dual().tutte()
  let n = m.ground_size()
  let a = t.resize(n)
  let b = ts.resize(n)
  for i = 0; i <= n; i = i + 1 {
    for j = 0; j <= n; j = j + 1 {
      if a.c[i][j] != b.c[j][i] {
        return @galois.Check::make(
          "T10",
          "Tutte 對偶 T_{M*}(x,y)=T_M(y,x)",
          false,
          m.name() +
          "：係數 (" +
          i.to_string() +
          "," +
          j.to_string() +
          ") 不符",
        )
      }
    }
  }
  @galois.Check::make(
    "T10",
    "Tutte 對偶 T_{M*}(x,y)=T_M(y,x)",
    true,
    m.name(),
  )
}

///|
/// T12：刪除–壓縮遞迴與子集和公式必須逐係數相等。
pub fn check_tutte_two_routes(m : Matroid) -> @galois.Check {
  let n = m.ground_size()
  let dc = tutte_deletion_contraction(m).resize(n)
  let sub = tutte_subsets(m).resize(n)
  if !dc.equals(sub) {
    return @galois.Check::make(
      "T12",
      "Tutte 兩路徑一致",
      false,
      m.name() +
      "：刪除–壓縮=" +
      dc.render() +
      "；子集和=" +
      sub.render(),
    )
  }
  @galois.Check::make(
    "T12",
    "Tutte 兩路徑一致",
    true,
    m.name() + "：T=" + dc.render(),
  )
}

///|
/// T12：Tutte 的特化值 == 對應的組合計數。
pub fn check_tutte_specializations(m : Matroid) -> @galois.Check {
  let t = m.tutte()
  let n = m.ground_size()
  let pairs : Array[(Int32, Int32, Int32, String)] = [
    (1, 1, m.basis_count(), "T(1,1)=基數"),
    (2, 1, m.independent_count(), "T(2,1)=獨立集數"),
    (1, 2, m.spanning_count(), "T(1,2)=生成集數"),
    (2, 2, pow2_for(n), "T(2,2)=2^|E|"),
  ]
  for i = 0; i < pairs.length(); i = i + 1 {
    let (x, y, want, label) = pairs[i]
    let got = t.eval(x, y)
    if got != want {
      return @galois.Check::make(
        "T12",
        "Tutte 特化值",
        false,
        m.name() +
        "：" +
        label +
        " 為 " +
        got.to_string() +
        "，應為 " +
        want.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T12",
    "Tutte 特化值",
    true,
    m.name() + "：T(1,1)、T(2,1)、T(1,2)、T(2,2) 全對",
  )
}

///|
fn pow2_for(n : Int32) -> Int32 {
  let mut r = 1
  for _i = 0; _i < n; _i = _i + 1 {
    r = r * 2
  }
  r
}

///|
/// T12：特徵多項式的兩條路徑（定義式 vs (−1)^r T(1−λ,0)）在 λ = 0..r+2 上取值相同。
pub fn check_characteristic(m : Matroid) -> @galois.Check {
  let a = m.characteristic_definition()
  let b = m.characteristic_from_tutte()
  let r = m.rank(@bitset.BitSet::full(m.ground_size()))
  for lambda = 0; lambda <= r + 2; lambda = lambda + 1 {
    let va = a.eval(lambda)
    let vb = b.eval(lambda)
    if va != vb {
      return @galois.Check::make(
        "T12",
        "特徵多項式兩路徑",
        false,
        m.name() +
        "：λ=" +
        lambda.to_string() +
        "，定義=" +
        va.to_string() +
        "，Tutte=" +
        vb.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T12",
    "特徵多項式兩路徑",
    true,
    m.name() + "：χ(λ)=" + a.render(),
  )
}

///|
/// T12（Whitney）：著色多項式與特徵多項式的關係
///   P(G, λ) = λ^{c(G)} · χ_{M(G)}(λ)     （c(G) = 連通分量數）
/// ＊開發期修正＊：首版漏掉 λ^{c(G)} 這個因子，K₃ 在 λ=3 上得到 χ=2 但著色數 6，
/// 檢核器立刻紅燈——這正是「定理要附可執行判準」的價值（見 docs/B0002 §12 的 THM-2）。
pub fn check_chromatic(
  vertices : Int32,
  edges : Array[(Int32, Int32)],
  components : Int32,
) -> @galois.Check {
  let m = Matroid::graphic("M(G)", vertices, edges)
  let chi = m.characteristic_definition()
  for lambda = 1; lambda <= vertices + 1; lambda = lambda + 1 {
    let want = proper_coloring_count(vertices, edges, lambda)
    let mut got = chi.eval(lambda)
    for _c = 0; _c < components; _c = _c + 1 {
      got = got * lambda
    }
    if want != got {
      return @galois.Check::make(
        "T12",
        "圖擬陣 χ == 正常著色數",
        false,
        "v=" +
        vertices.to_string() +
        "、λ=" +
        lambda.to_string() +
        "：λ^c·χ=" +
        got.to_string() +
        "，著色數=" +
        want.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T12",
    "圖擬陣 χ == 正常著色數",
    true,
    "v=" +
    vertices.to_string() +
    "、c=" +
    components.to_string() +
    "：χ=" +
    chi.render() +
    "，P(G,λ)=λ^c·χ",
  )
}

///|
/// T10：均勻擬陣的對偶 U(r,n)* ≅ U(n−r,n)。
pub fn check_uniform_dual(r : Int32, n : Int32) -> @galois.Check {
  let dual = Matroid::uniform(r, n).dual()
  let target = Matroid::uniform(n - r, n)
  if !isomorphic(dual, target) {
    return @galois.Check::make(
      "T10",
      "均勻擬陣對偶",
      false,
      "U(" +
      r.to_string() +
      "," +
      n.to_string() +
      ")* 不同構於 U(" +
      (n - r).to_string() +
      "," +
      n.to_string() +
      ")",
    )
  }
  @galois.Check::make(
    "T10",
    "均勻擬陣對偶",
    true,
    "U(" +
    r.to_string() +
    "," +
    n.to_string() +
    ")* ≅ U(" +
    (n - r).to_string() +
    "," +
    n.to_string() +
    ")",
  )
}

///|
/// T9：正則 ⇒ 二元（逆不成立：Fano）。這是一條真蘊含，檢核器要求它在樣本上永不被違反。
pub fn check_regular_implies_binary(m : Matroid) -> @galois.Check {
  let regular = m.is_regular()
  let binary = m.is_binary()
  if regular && !binary {
    return @galois.Check::make(
      "T9",
      "正則 ⇒ 二元",
      false,
      m.name() + "：被判為正則卻非二元（判準自相矛盾）",
    )
  }
  let mut verdict = m.name() + "：正則=" + regular.to_string()
  verdict = verdict + "、二元=" + binary.to_string()
  @galois.Check::make("T9", "正則 ⇒ 二元", true, verdict)
}

///|
/// T9：圖擬陣與餘圖擬陣皆為正則（關聯矩陣在 ℤ 上全么模；正則性對偶封閉）。
pub fn check_graphic_regular(
  name : String,
  vertices : Int32,
  edges : Array[(Int32, Int32)],
) -> @galois.Check {
  let m = Matroid::graphic(name, vertices, edges)
  let dual = m.dual()
  if !m.is_regular() {
    return @galois.Check::make(
      "T9",
      "圖擬陣正則",
      false,
      name + "：圖擬陣竟被判為非正則",
    )
  }
  if !dual.is_regular() {
    return @galois.Check::make(
      "T9",
      "圖擬陣正則",
      false,
      name + "*：餘圖擬陣竟被判為非正則",
    )
  }
  if !m.is_binary() {
    return @galois.Check::make(
      "T9",
      "圖擬陣正則",
      false,
      name + "：圖擬陣竟被判為非二元",
    )
  }
  @galois.Check::make(
    "T9",
    "圖擬陣正則",
    true,
    name + " 與 " + name + "* 皆正則（亦皆二元）",
  )
}

///|
/// T9：Fano 標本——**二元但非正則**（把 F7 誤放進二元禁集的錯誤會被此檢核抓住）。
pub fn check_fano_binary_not_regular() -> @galois.Check {
  let f = Matroid::fano()
  let binary = f.is_binary()
  let regular = f.is_regular()
  if !binary {
    return @galois.Check::make(
      "T9", "Fano 二元但非正則", false, "F7 被判為非二元（錯：F7 即 PG(2,2)，是 GF(2)³ 的 7 個非零向量）",
    )
  }
  if regular {
    return @galois.Check::make(
      "T9", "Fano 二元但非正則", false, "F7 被判為正則（錯：F7 含自身 minor）",
    )
  }
  @galois.Check::make(
    "T9", "Fano 二元但非正則", true, "F7：二元=是、正則=否、對偶 F7* 亦然",
  )
}

///|
/// T10：餘迴路 = 超平面的補集（∀ 擬陣）。這給「對偶的迴路」一條完全獨立的刻畫。
pub fn check_cocircuit_hyperplane(m : Matroid) -> @galois.Check {
  let n = m.ground_size()
  let full = @bitset.BitSet::full(n)
  let cocircuits = m.cocircuits()
  let hypers = m.hyperplanes()
  if cocircuits.length() != hypers.length() {
    return @galois.Check::make(
      "T10",
      "餘迴路 = 超平面的補集",
      false,
      m.name() +
      "：餘迴路 " +
      cocircuits.length().to_string() +
      " 個、超平面 " +
      hypers.length().to_string() +
      " 個",
    )
  }
  for i = 0; i < hypers.length(); i = i + 1 {
    let comp = full.minus(hypers[i])
    let mut hit = false
    for j = 0; j < cocircuits.length(); j = j + 1 {
      if cocircuits[j].equals(comp) {
        hit = true
      }
    }
    if !hit {
      return @galois.Check::make(
        "T10",
        "餘迴路 = 超平面的補集",
        false,
        m.name() +
        "：超平面 " +
        hypers[i].render() +
        " 的補集不是餘迴路",
      )
    }
  }
  @galois.Check::make(
    "T10",
    "餘迴路 = 超平面的補集",
    true,
    m.name() + "：|餘迴路|=" + cocircuits.length().to_string(),
  )
}

///|
/// T12：Fano 的特徵多項式必須是 (λ−1)(λ−2)(λ−4) = λ³ − 7λ² + 14λ − 8。
/// 這是 F7 的經典結果（根為 2 的冪），與 Tutte 路徑無關，可直接核對係數。
pub fn check_fano_characteristic() -> @galois.Check {
  let chi = Matroid::fano().characteristic_definition()
  let want : Array[Int32] = [-8, 14, -7, 1]
  if chi.c.length() != want.length() {
    return @galois.Check::make(
      "T12", "χ(F7)=(λ−1)(λ−2)(λ−4)", false, "次數不符",
    )
  }
  for i = 0; i < want.length(); i = i + 1 {
    if chi.c[i] != want[i] {
      return @galois.Check::make(
        "T12",
        "χ(F7)=(λ−1)(λ−2)(λ−4)",
        false,
        "係數 λ^" +
        i.to_string() +
        " 為 " +
        chi.c[i].to_string() +
        "，應為 " +
        want[i].to_string(),
      )
    }
  }
  @galois.Check::make(
    "T12",
    "χ(F7)=(λ−1)(λ−2)(λ−4)",
    true,
    Matroid::fano().characteristic_definition().render(),
  )
}

///|
/// T10：對偶平坦集的**秩判準**（由 r*(X)=|X|−r(E)+r(E∖X) 直接推得）：
///   X 是 M* 的平坦集 ⟺ ∀ e ∈ E∖X：r_M(E∖X) = r_M(E∖X∖{e})。
/// 這條判準同時提醒：**|ℱ(M*)| 一般不等於 |ℱ(M)|**（反例見 docs/B0002 §11：U(2,3) 為 5，其對偶 U(1,3) 為 2）。
pub fn check_dual_flat_criterion(m : Matroid) -> @galois.Check {
  let n = m.ground_size()
  let full = @bitset.BitSet::full(n)
  let dual = m.dual()
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(n, mask)
    let is_flat_dual = dual.closure(x).equals(x)
    let complement = full.minus(x)
    let mut criterion = true
    for e = 0; e < n; e = e + 1 {
      if !x.get(e) {
        let without = complement.minus_bit(e)
        if m.rank(complement) != m.rank(without) {
          criterion = false
        }
      }
    }
    if is_flat_dual != criterion {
      return @galois.Check::make(
        "T10",
        "對偶平坦集秩判準",
        false,
        m.name() +
        "：X=" +
        x.render() +
        "，對偶閉=" +
        is_flat_dual.to_string() +
        "，判準=" +
        criterion.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T10",
    "對偶平坦集秩判準",
    true,
    m.name() + "：∀X 判準與閉包一致",
  )
}

///|
/// T10：K₄ 是自對偶平面圖 ⇒ M(K₄)* ≅ M(K₄)（故兩者平坦數同為 15、迴路數同為 7）。
pub fn check_self_dual_k4() -> @galois.Check {
  let edges : Array[(Int32, Int32)] = [
    (0, 1),
    (0, 2),
    (0, 3),
    (1, 2),
    (1, 3),
    (2, 3),
  ]
  let m = Matroid::graphic("M(K4)", 4, edges)
  let d = m.dual()
  if !isomorphic(m, d) {
    return @galois.Check::make(
      "T10", "M(K₄) 自對偶", false, "M(K₄)* 不同構於 M(K₄)",
    )
  }
  @galois.Check::make(
    "T10",
    "M(K₄) 自對偶",
    true,
    "|ℱ|=" +
    m.flat_count().to_string() +
    "、|𝒞|=" +
    m.circuit_count().to_string() +
    "（兩者相同）",
  )
}

///|
/// B0002 延伸的完整檢核報告（T9–T12）。
pub fn extension_report(m : Matroid) -> @galois.Report {
  let r = @galois.Report::new()
  r.add(check_binary_two_routes(m))
  r.add(check_forbidden_minor_witness(m))
  r.add(check_dual_rank(m))
  r.add(check_double_dual(m))
  r.add(check_tutte_two_routes(m))
  r.add(check_tutte_specializations(m))
  r.add(check_tutte_dual(m))
  r.add(check_characteristic(m))
  r.add(check_regular_implies_binary(m))
  r.add(check_cocircuit_hyperplane(m))
  r.add(check_dual_flat_criterion(m))
  r
}
