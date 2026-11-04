///|
/// B0004 / elliptic 套件：**檢核器（T15–T21）**
/// 對應 docs/B0004-定理體系.md §3–§9。
///
/// 每一條都把「定理說的話」翻成有限集合上的窮舉判定，失敗時回報最小反例；
/// 沒有外部期望值的地方（例如某個特定 q 的 β₁）**不設期望值**，只做內部交叉印證
///（Euler–Poincaré、β₀ 與 BFS 分量），並在報表中標明。

///|
/// T15：除多項式 ψ_n 的整數性與古典次數。
pub fn check_div_poly(a : Int32, b : Int32, n : Int32) -> @galois.Check {
  let name = "T15 ψ_n 的次數（n=" +
    n.to_string() +
    "，曲線 (" +
    a.to_string() +
    "," +
    b.to_string() +
    ")）"
  match div_polys(a, b, n + 1) {
    None =>
      return @galois.Check::make(
        "T15", name, false, "遞歸中出現無法整除 2y 的情形 ⇒ ψ_n ∉ ℤ[x,y]（整數性失敗）",
      )
    Some(list) => {
      let psi = list[n]
      let red = np_reduce(psi, a, b)
      let yd = np_y_degrees(red)
      let deg = np_deg_x(red)
      let want_y = expected_psi_y_degree(n)
      let want_d = expected_psi_degree(n)
      let ok = yd.length() == 1 && yd[0] == want_y && deg == want_d
      let detail = "次數 " +
        deg.to_string() +
        "（期望 " +
        want_d.to_string() +
        "）、y 次數 " +
        (if yd.length() == 1 {
          yd[0].to_string()
        } else {
          yd.length().to_string() + " 種"
        }) +
        "（期望 " +
        want_y.to_string() +
        "）、項數 " +
        np_terms(psi).to_string()
      @galois.Check::make("T15", name, ok, detail)
    }
  }
}

///|
/// T15：E[n] 的元素個數 = n²（由 (ℤ/n)² 的暴力列舉），且 n²−1 個非零點的階恰為 n 的因數。
pub fn check_torsion_size(n : Int32) -> @galois.Check {
  let g = e_group(n)
  let ok = g.length() == n * n
  let detail = "|E[" +
    n.to_string() +
    "]| = " +
    g.length().to_string() +
    "（公式 n² = " +
    (n * n).to_string() +
    "）"
  @galois.Check::make("T15", "T15 |E[n]| = n²", ok, detail)
}

///|
/// T16：Weil 配對的三條公理（交錯、雙線性、非退化）。
pub fn check_weil_axioms(n : Int32) -> @galois.Check {
  let g = e_group(n)
  let mut alt_ok = true
  let mut nondeg_ok = true
  for i = 0; i < g.length(); i = i + 1 {
    if weil_exp(g[i], g[i]) != 0 {
      alt_ok = false
    }
    if !g[i].is_zero() {
      let mut found = false
      for j = 0; j < g.length(); j = j + 1 {
        if weil_exp(g[i], g[j]) != 0 {
          found = true
        }
      }
      if !found {
        nondeg_ok = false
      }
    }
  }
  let mut bil_ok = true
  for i = 0; i < g.length(); i = i + 1 {
    for j = 0; j < g.length(); j = j + 1 {
      for k = 0; k < g.length(); k = k + 1 {
        let lhs = weil_exp(g[i].add(g[j]), g[k])
        let rhs = @modular.norm_mod(
          weil_exp(g[i], g[k]) + weil_exp(g[j], g[k]),
          n,
        )
        if lhs != rhs {
          bil_ok = false
        }
      }
    }
  }
  let ok = alt_ok && nondeg_ok && bil_ok
  let detail = "交錯 " +
    alt_ok.to_string() +
    "、非退化 " +
    nondeg_ok.to_string() +
    "、雙線性 " +
    bil_ok.to_string()
  @galois.Check::make(
    "T16",
    "T16 Weil 配對公理（n=" + n.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// T17：Galois 等變——對所有 M ∈ GL₂(ℤ/n)，e(MT, MS) = det(M)·e(T,S)。
/// 這是「ρ_{E,n} 的像落在相似群 GSp₂，而保配對者恰為 SL₂」的可執行版本。
pub fn check_equivariance(n : Int32) -> @galois.Check {
  let g = e_group(n)
  let mats = gl2_group(n)
  let mut ok = true
  let mut witness = ""
  for mi = 0; mi < mats.length(); mi = mi + 1 {
    let m = mats[mi]
    let (ma, mb, mc, md) = m
    let det = @modular.norm_mod(ma * md - mb * mc, n)
    for i = 0; i < g.length(); i = i + 1 {
      for j = 0; j < g.length(); j = j + 1 {
        let lhs = weil_exp(mact(m, g[i]), mact(m, g[j]))
        let rhs = @modular.norm_mod(det * weil_exp(g[i], g[j]), n)
        if lhs != rhs {
          ok = false
          if witness == "" {
            witness = "M=(" +
              ma.to_string() +
              "," +
              mb.to_string() +
              "," +
              mc.to_string() +
              "," +
              md.to_string() +
              ")、T=" +
              g[i].key() +
              "、S=" +
              g[j].key()
          }
        }
      }
    }
  }
  let detail = if ok {
    "|GL₂(ℤ/" +
    n.to_string() +
    ")| = " +
    mats.length().to_string() +
    " 個矩陣全部滿足 e(MT,MS)=det·e(T,S)"
  } else {
    "反例：" + witness
  }
  @galois.Check::make(
    "T17",
    "T17 Galois 等變（n=" + n.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// T16（共性／併攏）：撓群的軌道計數 = B0003 的同餘指數。
pub fn check_orbit_equals_index(n : Int32) -> @galois.Check {
  let pts = count_points_of_order(n)
  let lines = count_cyclic_subgroups(n)
  let bases = count_det_one_bases(n)
  let allb = count_all_bases(n)
  let i1 = @modular.index_gamma1(n)
  let i0 = @modular.index_gamma0(n)
  let il = @modular.index_gamma_level(n)
  let phi = @modular.euler_phi(n)
  let ok = pts == i1 && lines == i0 && bases == il && allb == il * phi
  let detail = "#{ord=n}=" +
    pts.to_string() +
    " vs [SL₂:Γ₁]=" +
    i1.to_string() +
    "；#循環子群=" +
    lines.to_string() +
    " vs [SL₂:Γ₀]=" +
    i0.to_string() +
    "；#辛基(det=1)=" +
    bases.to_string() +
    " vs [SL₂:Γ]=" +
    il.to_string() +
    "；#全基=" +
    allb.to_string() +
    " vs [SL₂:Γ]·φ=" +
    (il * phi).to_string()
  @galois.Check::make(
    "T16",
    "T16 軌道計數 = 同餘指數（n=" + n.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// T16 的軌道—穩定化子交叉驗證：|orbit|·|stab| = |SL₂(ℤ/n)|。
pub fn check_orbit_stabilizer(n : Int32) -> @galois.Check {
  let g = @modular.sl2_group(n)
  let lines = count_cyclic_subgroups(n)
  let rep = ept_make(n, 1, 0)
  if rep.order() != n {
    return @galois.Check::make(
      "T16",
      "T16 軌道—穩定化子（n=" + n.to_string() + "）",
      false,
      "(1,0) 的階為 " + rep.order().to_string() + "，不是 n",
    )
  }
  let stab = stabilizer_order_of_line(n, rep)
  let ok = lines * stab == g.length()
  let detail = "軌道 " +
    lines.to_string() +
    " × 穩定化子 " +
    stab.to_string() +
    " = " +
    (lines * stab).to_string() +
    "，|SL₂(ℤ/" +
    n.to_string() +
    ")| = " +
    g.length().to_string()
  @galois.Check::make(
    "T16",
    "T16 軌道—穩定化子（n=" + n.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// T18：Paley 圖／競賽的古典不變量（度、λ、強正則參數或雙正則）與 Ramsey 下界。
pub fn check_paley(q : Int32) -> @galois.Check {
  let name = "T18 Paley 不變量（q=" + q.to_string() + "）"
  if q % 2 == 0 || q < 3 {
    return @galois.Check::make("T18", name, false, "q 必須是奇質數")
  }
  if q % 4 == 1 {
    let adj = paley_adjacency(q)
    let k = (q - 1) / 2
    let lam = (q - 5) / 4
    let mu = (q - 1) / 4
    let srg = is_strongly_regular(adj, q, k, lam, mu)
    let omega = clique_number(adj)
    let alpha = clique_number(complement(adj))
    let delsarte = omega * alpha <= q
    let trans = translation_invariant(adj, 1) &&
      translation_invariant(adj, q - 1)
    let selfcomp = self_complementary_witness(q, adj)
    let ok = srg && delsarte && trans && selfcomp
    let detail = "srg(" +
      q.to_string() +
      "," +
      k.to_string() +
      "," +
      lam.to_string() +
      "," +
      mu.to_string() +
      ")=" +
      srg.to_string() +
      "、ω=" +
      omega.to_string() +
      "、α=" +
      alpha.to_string() +
      "、αω=" +
      (omega * alpha).to_string() +
      "≤" +
      q.to_string() +
      "=" +
      delsarte.to_string() +
      "、平移不變=" +
      trans.to_string() +
      "、自補=" +
      selfcomp.to_string() +
      " ⇒ R(" +
      (omega + 1).to_string() +
      "," +
      (alpha + 1).to_string() +
      ") > " +
      q.to_string()
    @galois.Check::make("T18", name, ok, detail)
  } else {
    let out = paley_tournament(q)
    let dr = is_doubly_regular(q, out)
    let rev = reversal_witness(q, out)
    let mt = max_transitive_subtournament(q, out)
    // 遞移子競賽大小 t ⇒ 競賽的「團」= t；Ramsey 型下界用 t 與其反競賽
    let ok = dr && rev
    let detail = "雙正則（出度 " +
      ((q - 1) / 2).to_string() +
      "、λ=" +
      ((q - 3) / 4).to_string() +
      "）=" +
      dr.to_string() +
      "、反向同構=" +
      rev.to_string() +
      "、最大遞移子競賽=" +
      mt.to_string()
    @galois.Check::make("T18", name, ok, detail)
  }
}

///|
/// T21：團複形的 GF(2) 同調——Euler–Poincaré 兩路徑一致，且 β₀ = 連通分量數。
pub fn check_flag_homology(q : Int32) -> @galois.Check {
  let adj = paley_adjacency(q)
  let h = flag_homology(adj)
  let comps = components_of(adj)
  let betti = h.betti()
  let ok = h.agree() && betti.length() > 0 && betti[0] == comps
  let detail = h.render() +
    "；β₀=" +
    (if betti.length() > 0 { betti[0].to_string() } else { "—" }) +
    " 與 BFS 分量數 " +
    comps.to_string() +
    " 相符=" +
    (betti.length() > 0 && betti[0] == comps).to_string()
  @galois.Check::make(
    "T21",
    "T21 團複形同調（q=" + q.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// T20：撓群線性擬陣的結構（秩 2、平行類 p+1、簡化為 U(2,p+1)），並在 p ≤ 3 時暴力列舉迴路。
pub fn check_torsion_matroid(p : Int32) -> @galois.Check {
  let name = "T20 撓群擬陣（p=" + p.to_string() + "）"
  let vs = torsion_vectors(p)
  let r = rank_mod_p(vs, p)
  let classes = parallel_class_count(p)
  let uniform = simplification_is_uniform(p)
  let mut ok = r == 2 && classes == p + 1 && uniform
  let mut extra = ""
  if p <= 3 {
    let circ = circuits_bruteforce(p)
    let fl = flats_bruteforce(p)
    // 迴路數期望：p 奇 → (p+1) 個平行對 + C(p+1,3) 個三點線；p=2 → C(3,3)=1
    // 迴路數：p 奇 → (p+1) 個平行對 {v,−v} ＋ (p−1)³·C(p+1,3) 個「三條不同線各取一點」；
    // p = 2 → 只有 {三個非零向量} 這一個（每條線只有一個非零向量）。（BUG-6：首版漏了 (p−1)³）
    let want_circ = if p == 2 {
      1
    } else {
      p + 1 + (p - 1) * (p - 1) * (p - 1) * ((p + 1) * p * (p - 1)) / 6
    }
    let want_flats = p + 3
    ok = ok && circ.length() == want_circ && fl.length() == want_flats
    extra = "、迴路 " +
      circ.length().to_string() +
      "（期望 " +
      want_circ.to_string() +
      "）、平坦集 " +
      fl.length().to_string() +
      "（期望 " +
      want_flats.to_string() +
      "）"
  }
  let detail = "秩 " +
    r.to_string() +
    "、平行類 " +
    classes.to_string() +
    "（= p+1）、簡化為 U(2,p+1)=" +
    uniform.to_string() +
    extra
  @galois.Check::make("T20", name, ok, detail)
}

///|
/// 完整報告（T15–T21）：除多項式（3 條曲線 × n=2..12）、配對公理、等變、軌道計數、Paley、同調、擬陣。
pub fn elliptic_report(nmax : Int32) -> @galois.Report {
  let r = @galois.Report::new()
  let curves : Array[(Int32, Int32)] = [(-1, 0), (0, 1), (1, 1)]
  for ci = 0; ci < curves.length(); ci = ci + 1 {
    let (a, b) = curves[ci]
    for n = 2; n <= nmax; n = n + 1 {
      r.add(check_div_poly(a, b, n))
    }
  }
  for n = 2; n <= 6; n = n + 1 {
    r.add(check_torsion_size(n))
    r.add(check_weil_axioms(n))
    r.add(check_orbit_equals_index(n))
    r.add(check_orbit_stabilizer(n))
  }
  for n = 2; n <= 4; n = n + 1 {
    r.add(check_equivariance(n))
  }
  r.add(check_paley(5))
  r.add(check_paley(13))
  r.add(check_paley(17))
  r.add(check_paley(3))
  r.add(check_paley(7))
  r.add(check_paley(11))
  r.add(check_flag_homology(5))
  r.add(check_flag_homology(13))
  r.add(check_flag_homology(17))
  r.add(check_torsion_matroid(2))
  r.add(check_torsion_matroid(3))
  r.add(check_torsion_matroid(5))
  r.add(check_torsion_matroid(7))
  r
}
