///|
/// B0007 / hyper 套件：**檢核器（T41–T47）**
/// 對應 docs/B0007-定理體系.md §2–§8。
///
/// 每條定理都落成「可執行的等式」，並且刻意讓同一件事有兩條獨立路徑：
///   * 群階：窮舉出的元素個數 vs 公式 2ⁿ·n! vs |T|·|S|；
///   * 穩定子：直接數固定點 vs 軌道—穩定子定理 |Aut| = |軌道|·|穩定子|；
///   * 方向：方向映射的像 vs 座標置換群 S_n 的階；
///   * 邊數：邊表長度 vs 公式 n·2^{n−1}。
/// 另有**負控制**：明確構造「看起來像」但被排除的映射（非仿射雙射），
/// 保證 T41 不是恆真。

// ---------------------------------------------------------------- T41：完整刻劃

///|
/// T41：**Aut(Q_n) = { v ↦ π(v) ⊕ b }**（窮舉集合與預測集合逐元素相等）。
pub fn check_full_characterization(n : Int32) -> @galois.Check {
  let aut = automorphisms(n)
  let pred = predicted_automorphisms(n)
  let same = perm_sets_equal(aut, pred)
  let order_ok = aut.length() == predicted_order(n)
  let ok = same && order_ok && pred.length() == predicted_order(n)
  let detail = "n=" +
    n.to_string() +
    "：|窮舉|=" +
    aut.length().to_string() +
    "、|預測|=" +
    pred.length().to_string() +
    "、2ⁿ·n!=" +
    predicted_order(n).to_string() +
    "、集合相等=" +
    same.to_string()
  @galois.Check::make(
    "T41",
    "T41 Q_" + n.to_string() + " 的自同構 = 平移 ⋊ 座標置換",
    ok,
    detail,
  )
}

///|
/// T41（負控制）：非仿射的雙射不是自同構，且**不在**窮舉結果裡。
/// 具體取 Q_3 上「交換頂點 1 與 2、其餘固定」（1 = 001、2 = 010）。
pub fn check_nonaffine_rejected(n : Int32) -> @galois.Check {
  let v = pow2i(n)
  let sigma = perm_id(v)
  let a = 1
  let b = 2
  if n >= 2 {
    sigma[a] = b
    sigma[b] = a
  }
  // (1) 它是雙射；(2) 它破壞某條邊；(3) 它不在 Aut 裡
  let bijective = perm_eq(perm_inv(sigma) |> perm_comp(sigma), perm_id(v)) &&
    perm_eq(perm_comp(sigma, perm_inv(sigma)), perm_id(v))
  let mut breaks = false
  for x = 0; x < v; x = x + 1 {
    for y = 0; y < v; y = y + 1 {
      if adj_qn(n, x, y) != adj_qn(n, sigma[x], sigma[y]) {
        breaks = true
      }
    }
  }
  let in_aut = perm_member(automorphisms(n), sigma)
  let ok = bijective && breaks && !in_aut
  let detail = "n=" +
    n.to_string() +
    "：σ=交換 1↔2 為雙射=" +
    bijective.to_string() +
    "、破壞鄰接=" +
    breaks.to_string() +
    "、在 Aut 中=" +
    in_aut.to_string() +
    "（三項都必須「是／是／否」）"
  @galois.Check::make(
    "T41", "T41 負控制：非仿射雙射被排除", ok, detail,
  )
}

// ---------------------------------------------------------------- T42：群階

///|
/// T42：|Aut(Q_n)| = 2ⁿ·n!，並用軌道—穩定子定理交叉檢核：
/// |Aut| = |V|·|Stab(0)| = |E|·|Stab(邊)|。
pub fn check_order_formula(n : Int32) -> @galois.Check {
  let aut = automorphisms(n)
  let v = pow2i(n)
  let edges = hyper_edges(n)
  let order = aut.length()
  let formula = predicted_order(n)
  let stab_v = stabilizer_size(aut, 0)
  let stab_e = edge_stabilizer_size(n, aut, edges)
  let os_v = v * stab_v == order
  let os_e = edges.length() * stab_e == order
  let ok = order == formula && stab_v == fact(n) && os_v && os_e
  let detail = "n=" +
    n.to_string() +
    "：|Aut|=" +
    order.to_string() +
    "、2ⁿ·n!=" +
    formula.to_string() +
    "、|Stab(0)|=" +
    stab_v.to_string() +
    "（=n!）、|V|·|Stab|=" +
    (v * stab_v).to_string() +
    "、|E|·|Stab(邊)|=" +
    (edges.length() * stab_e).to_string()
  @galois.Check::make(
    "结合",
    "T42 |Aut(Q_" + n.to_string() + ")| = 2ⁿ·n! 與軌道—穩定子",
    ok,
    detail,
  )
}

// ---------------------------------------------------------------- T43：方向映射

///|
/// T43：方向映射 π: Aut → S_n 良定義、是同態，且**核恰為平移群 𝔽₂ⁿ**。
pub fn check_direction_map(n : Int32) -> @galois.Check {
  let aut = automorphisms(n)
  let v = pow2i(n)
  let mut all_some = true
  for s in aut {
    match direction_map(s, n) {
      Some(pi) => {
        // π 必須是 0..n−1 的雙射
        let seen : Array[Bool] = []
        for _i = 0; _i < n; _i = _i + 1 {
          seen.push(false)
        }
        for d in pi {
          if d >= 0 && d < n {
            seen[d] = true
          }
        }
        for s2 in seen {
          if !s2 {
            all_some = false
          }
        }
      }
      None => all_some = false
    }
  }
  let hom = direction_hom(aut, n)
  let ker = direction_kernel(aut, n)
  let mut ker_all_translations = true
  for s in ker {
    if !is_translation(s) {
      ker_all_translations = false
    }
  }
  let mut all_translations_in_ker = true
  for t in translations(n) {
    if !is_translation(t) {
      all_translations_in_ker = false
    }
    // 平移的方向映射必須是恆等
    match direction_map(t, n) {
      Some(pi) =>
        if !perm_eq(pi, perm_id(n)) {
          all_translations_in_ker = false
        }
      None => all_translations_in_ker = false
    }
  }
  let ker_size_ok = ker.length() == v
  let quotient_ok = aut.length() / ker.length() == fact(n)
  let ok = all_some &&
    hom &&
    ker_all_translations &&
    all_translations_in_ker &&
    ker_size_ok &&
    quotient_ok
  let detail = "n=" +
    n.to_string() +
    "：良定義=" +
    all_some.to_string() +
    "、同態=" +
    hom.to_string() +
    "、|ker|=" +
    ker.length().to_string() +
    "（=2ⁿ）、Aut/T=" +
    (aut.length() / ker.length()).to_string() +
    "（=n!）、ker 全為平移=" +
    ker_all_translations.to_string()
  @galois.Check::make(
    "推论",
    "T43 Q_" +
    n.to_string() +
    " 的方向映射 Aut → S_n（核 = 𝔽₂ⁿ）",
    ok,
    detail,
  )
}

// ---------------------------------------------------------------- T44：Cayley 刻劃

///|
/// T44：Q_n ≅ Cayley(𝔽₂ⁿ, {e_1..e_n})：鄰接 ⟺ 差為標準基向量、
/// 圖距離 = 漢明距離、n 正則、|E| = n·2^{n−1}、直徑 n、平移群正則。
pub fn check_cayley(n : Int32) -> @galois.Check {
  let edges = hyper_edges(n)
  let cay = cayley_ok(n)
  let dh = dist_eq_hamming(n)
  let reg = is_n_regular(n)
  let ec = edges.length() == edge_count_formula(n)
  let dia = diameter(n) == n
  let treg = translation_regular(n)
  let ok = cay && dh && reg && ec && dia && treg
  let detail = "n=" +
    n.to_string() +
    "：Cayley=" +
    cay.to_string() +
    "、距離=漢明=" +
    dh.to_string() +
    "、n 正則=" +
    reg.to_string() +
    "、|E|=" +
    edges.length().to_string() +
    "（=n·2ⁿ⁻¹=" +
    edge_count_formula(n).to_string() +
    "）、直徑=" +
    diameter(n).to_string() +
    "、平移群正則=" +
    treg.to_string()
  @galois.Check::make(
    "共性",
    "T44 Q_" + n.to_string() + " ≅ Cayley(𝔽₂ⁿ, 標準基)",
    ok,
    detail,
  )
}

// ---------------------------------------------------------------- T45：摺疊與邊界

///|
/// T45(a)：摺疊 f: Q_n → Q_{n−1}（丟最高位）是滿同態，
/// 每個纖維恰為一條邊，且 Q_{n−1} 的每條邊恰有 2 條原像。
pub fn check_folding(n : Int32) -> @galois.Check {
  let hom = fold_is_hom(n)
  let fiber = fold_fiber_size(n)
  let range = fold_fiber_edge_range(n)
  let every_two = range.0 == 2 && range.1 == 2
  // 滿射：Q_{n−1} 的每個頂點都出現在像裡
  let img : Array[Bool] = []
  for _i = 0; _i < pow2i(n - 1); _i = _i + 1 {
    img.push(false)
  }
  for x = 0; x < pow2i(n); x = x + 1 {
    img[fold_vertex(n, x)] = true
  }
  let mut onto = true
  for b in img {
    if !b {
      onto = false
    }
  }
  let ok = hom && fiber == 2 && every_two && onto
  let detail = "n=" +
    n.to_string() +
    "：同態=" +
    hom.to_string() +
    "、纖維大小=" +
    fiber.to_string() +
    "、原像邊數=" +
    range.0.to_string() +
    ".." +
    range.1.to_string() +
    "、滿射=" +
    onto.to_string()
  @galois.Check::make(
    "衍生",
    "T45 Q_" + n.to_string() + " → Q_" + (n - 1).to_string() + " 的摺疊",
    ok,
    detail,
  )
}

///|
/// T45(b)：n ≤ 2 的退化邊界——Q_1 = K₂、Q_2 = C₄，公式 2ⁿ·n! 仍成立。
pub fn check_degenerate_boundary() -> @galois.Check {
  // Q_1
  let aut1 = automorphisms(1)
  let q1_ok = aut1.length() == 2 &&
    hyper_edges(1).length() == 1 &&
    diameter(1) == 1
  // Q_2：4 邊、每點度 2、無三角形、Aut 階 8 且 = D₈（5 個共軛類、階數分布 1:1、2:5、4:2）
  let aut2 = automorphisms(2)
  let e2 = hyper_edges(2)
  let mut triangles = 0
  for (a, b) in e2 {
    for c = 0; c < 4; c = c + 1 {
      if adj_qn(2, b, c) && adj_qn(2, a, c) {
        triangles = triangles + 1
      }
    }
  }
  let hist = order_histogram(aut2)
  let hist_ok = hist.length() == 3 &&
    hist[0] == (1, 1) &&
    hist[1] == (2, 5) &&
    hist[2] == (4, 2)
  let cls = conjugacy_representatives(aut2).length()
  let q2_ok = aut2.length() == 8 &&
    e2.length() == 4 &&
    triangles == 0 &&
    hist_ok &&
    cls == 5 &&
    is_n_regular(2)
  // 摺疊在 n = 1 退化：Q_1 → Q_0（單點），唯一的一條邊塌成一點
  let fold_ok = fold_is_hom(1) == false &&
    fold_vertex(1, 0) == 0 &&
    fold_vertex(1, 1) == 0
  let ok = q1_ok && q2_ok && fold_ok
  let detail = "Q₁=K₂：|Aut|=" +
    aut1.length().to_string() +
    "、|E|=" +
    hyper_edges(1).length().to_string() +
    "、直徑=" +
    diameter(1).to_string() +
    "；Q₂=C₄：|Aut|=" +
    aut2.length().to_string() +
    "、|E|=" +
    e2.length().to_string() +
    "、三角形=" +
    triangles.to_string() +
    "、共軛類=" +
    cls.to_string() +
    "、階數分布=" +
    order_histogram_render(aut2) +
    "；n=1 摺疊退化=" +
    fold_ok.to_string()
  @galois.Check::make(
    "相容", "T45(b) n ≤ 2 的退化邊界（Q₁=K₂、Q₂=C₄=D₈）", ok,
    detail,
  )
}

///|
/// 階數分布的字串形式（如「1^1 2^5 4^2」）。
pub fn order_histogram_render(aut : Array[Array[Int32]]) -> String {
  let sb = StringBuilder()
  for (o, c) in order_histogram(aut) {
    sb.write_string(o.to_string() + "^" + c.to_string() + " ")
  }
  sb.to_string()
}

// ---------------------------------------------------------------- T46：邊置換群

///|
/// T46：σ ↦ σ 在邊集上的置換 φ(σ) 是同態；
/// 邊集可遷；φ 的核在 n ≥ 2 時平凡、n = 1 時為 ℤ₂（唯一一條邊被翻轉固定）。
pub fn check_edge_action(n : Int32) -> @galois.Check {
  let aut = automorphisms(n)
  let edges = hyper_edges(n)
  let hom = edge_perm_hom(n, aut, edges)
  let orb = edge_orbit_size(n, aut, edges).length()
  let transitive = orb == edges.length()
  let kern = edge_perm_kernel_size(n, aut, edges)
  let expected = if n == 1 { 2 } else { 1 }
  let kern_ok = kern == expected
  let ok = hom &&
    transitive &&
    kern_ok &&
    edges.length() == edge_count_formula(n)
  let detail = "n=" +
    n.to_string() +
    "：邊數=" +
    edges.length().to_string() +
    "、同態=" +
    hom.to_string() +
    "、邊軌道=" +
    orb.to_string() +
    "（可遷）、|ker φ|=" +
    kern.to_string() +
    "（期望 " +
    expected.to_string() +
    "）"
  @galois.Check::make(
    "镜像对称",
    "T46 Q_" + n.to_string() + " 的邊置換群",
    ok,
    detail,
  )
}

// ---------------------------------------------------------------- T47：共軛類

///|
/// 配對分割的個數 Σ_{k=0}^{n} p(k)·p(n−k)（p 借用 B0006 的無序分割計數）。
pub fn paired_partition_count(n : Int32) -> Int32 {
  let mut s = 0
  for k = 0; k <= n; k = k + 1 {
    s = s + @kk.partitions(k).length() * @kk.partitions(n - k).length()
  }
  s
}

///|
/// T47：Aut(Q_n) ≅ C₂ ≀ S_n 的共軛類個數 = Σ p(k)p(n−k)，
/// 且各類大小之和 = 群階（Burnside 覆蓋檢核）。
pub fn check_conjugacy_formula(n : Int32) -> @galois.Check {
  let aut = automorphisms(n)
  let reps = conjugacy_representatives(aut).length()
  let formula = paired_partition_count(n)
  let sum = conjugacy_sizes_sum(aut)
  let ok = reps == formula && sum == aut.length()
  let detail = "n=" +
    n.to_string() +
    "：共軛類=" +
    reps.to_string() +
    "、Σp(k)p(n−k)=" +
    formula.to_string() +
    "、Σ|類|=" +
    sum.to_string() +
    "（=群階 " +
    aut.length().to_string() +
    "）"
  @galois.Check::make(
    "计算",
    "T47 Aut(Q_" + n.to_string() + ") 的共軛類個數",
    ok,
    detail,
  )
}

// ---------------------------------------------------------------- 報告

///|
/// 全部檢核（T41–T47）。
pub fn hyper_report() -> @galois.Report {
  let r = @galois.Report::new()
  for n = 1; n <= 4; n = n + 1 {
    r.add(check_full_characterization(n))
  }
  r.add(check_nonaffine_rejected(3))
  for n = 1; n <= 4; n = n + 1 {
    r.add(check_order_formula(n))
  }
  for n = 1; n <= 4; n = n + 1 {
    r.add(check_direction_map(n))
  }
  for n = 1; n <= 4; n = n + 1 {
    r.add(check_cayley(n))
  }
  for n = 2; n <= 4; n = n + 1 {
    r.add(check_folding(n))
  }
  r.add(check_degenerate_boundary())
  for n = 1; n <= 4; n = n + 1 {
    r.add(check_edge_action(n))
  }
  for n = 1; n <= 4; n = n + 1 {
    r.add(check_conjugacy_formula(n))
  }
  r
}
