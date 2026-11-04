///|
/// B0005 / jacobian 套件：**檢核器（T25–T31）**
/// 對應 docs/B0005-定理體系.md §5–§8。

///|
/// 常用樣本圖。
pub fn sample_graphs() -> Array[(String, Graph)] {
  let k3 : Graph = { n: 3, edges: [(0, 1), (1, 2), (0, 2)], }
  let k4 : Graph = {
    n: 4,
    edges: [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)],
  }
  let k5 : Graph = {
    n: 5,
    edges: [
      (0, 1),
      (0, 2),
      (0, 3),
      (0, 4),
      (1, 2),
      (1, 3),
      (1, 4),
      (2, 3),
      (2, 4),
      (3, 4),
    ],
  }
  let c4 : Graph = { n: 4, edges: [(0, 1), (1, 2), (2, 3), (3, 0)], }
  let c5 : Graph = { n: 5, edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)], }
  // θ 圖：兩點三條平行邊（g = 2）
  let theta : Graph = { n: 2, edges: [(0, 1), (0, 1), (0, 1)], }
  // 兩個三角形共用一點（g = 2）
  let bowtie : Graph = {
    n: 5,
    edges: [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)],
  }
  [
    ("K₃", k3),
    ("K₄", k4),
    ("K₅", k5),
    ("C₄", c4),
    ("C₅", c5),
    ("θ", theta),
    ("蝴蝶結", bowtie),
  ]
}

///|
/// T25：|J(G)| 的三條獨立路徑一致（不變因子乘積 / 約化 Laplacian 行列式 / 暴力生成樹數）。
pub fn check_jacobian_order(name : String, g : Graph) -> @galois.Check {
  let by_inv = jacobian_order(g)
  let by_det = spanning_trees_by_det(g)
  let by_bf = spanning_trees_bruteforce(g)
  let ok = by_inv == by_det && by_det == BigInt::from_int(by_bf)
  let detail = "不變因子乘積 " +
    by_inv.to_string() +
    "、Matrix–Tree 行列式 " +
    by_det.to_string() +
    "、暴力生成樹 " +
    by_bf.to_string() +
    "；g(J) = β₁ = " +
    g.cycle_rank().to_string()
  @galois.Check::make("T25", "T25 |J(G)| = τ(G)（" + name + "）", ok, detail)
}

///|
/// T26：K_n 的雅可比簇結構 J(K_n) ≅ (ℤ/n)^{n−2}（不變因子 = 1, n, …, n）。
pub fn check_complete_graph_jacobian(n : Int32) -> @galois.Check {
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      edges.push((i, j))
    }
  }
  let g : Graph = { n, edges, }
  let fs = invariant_factors(laplacian(g))
  // 期望：[1, n, n, …, n]（共 n−2 個 n）
  let mut ok = fs.length() == n - 1
  if ok {
    if fs[0] != BigInt::from_int(1) {
      ok = false
    }
    for i = 1; i < fs.length(); i = i + 1 {
      if fs[i] != BigInt::from_int(n) {
        ok = false
      }
    }
  }
  let sb = StringBuilder()
  for i = 0; i < fs.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(fs[i].to_string())
  }
  let detail = "不變因子 [" +
    sb.to_string() +
    "]（期望 [1," +
    n.to_string() +
    "×" +
    (n - 2).to_string() +
    "]）⇒ J(K_n) ≅ (ℤ/n)^{n−2}，|J| = " +
    jacobian_order(g).to_string() +
    " = n^{n−2} = " +
    pow_int(n, n - 2).to_string()
  @galois.Check::make(
    "T26",
    "T26 J(K_" + n.to_string() + ") ≅ (ℤ/" + n.to_string() + ")^{n−2}",
    ok,
    detail,
  )
}

///|
/// 整數次方。
pub fn pow_int(a : Int32, e : Int32) -> Int32 {
  let mut r = 1
  for _i = 0; _i < e; _i = _i + 1 {
    r = r * a
  }
  r
}

///|
/// T27：圈秩的兩條路徑——拓撲定義 |E|−|V|+c 與線性代數 |E|−rank_ℚ(L)。
/// ＊修正 BUG-8＊ 原本寫成 rank_{𝔽₂}(L)，C₅ 立刻給反例（L mod 2 退化）；
/// 正確的是**有理數上的秩**（= |V| − c）。
pub fn check_cycle_rank(name : String, g : Graph) -> @galois.Check {
  let topo = g.cycle_rank()
  let lin = g.num_edges() - rank_over_q(laplacian(g))
  let r2 = laplacian_rank_mod2(g)
  let ok = topo == lin
  let detail = "|E|−|V|+c = " +
    topo.to_string() +
    "、|E|−rank_ℚ(L) = " +
    lin.to_string() +
    "（另記 rank_{𝔽₂}(L) = " +
    r2.to_string() +
    "，它**不等於** |V|−c，見 BUG-8）"
  @galois.Check::make(
    "T27",
    "T27 圈秩的兩條路徑（" + name + "）",
    ok,
    detail,
  )
}

///|
/// 超立方體 Q_n：頂點 = 𝔽₂ⁿ 的位元串（0..2ⁿ−1），邊 = 相差一個位元。
pub fn hypercube(n : Int32) -> Graph {
  let v = pow_int(2, n)
  let es : Array[(Int32, Int32)] = []
  for x = 0; x < v; x = x + 1 {
    for i = 0; i < n; i = i + 1 {
      let y = jump_bit(x, i)
      if x < y {
        es.push((x, y))
      }
    }
  }
  { n: v, edges: es, }
}

///|
/// 翻轉第 i 個位元（避免直接寫移位運算子的優先級問題）。
pub fn jump_bit(x : Int32, i : Int32) -> Int32 {
  let b = pow_int(2, i)
  let bit = x / b % 2
  if bit == 1 {
    x - b
  } else {
    x + b
  }
}

///|
/// T31：超立方體網絡 Q_n 的生成樹計數與**外部登記值**（行列式路徑）。
pub fn check_hypercube_tau(n : Int32, want : Int64) -> @galois.Check {
  let g = hypercube(n)
  let tau = spanning_trees_by_det(g)
  // ＊只走行列式路徑＊：Q_4 有 32 條邊，刪縮遞迴是 O(2^{|E|})，不適合；
  // 刪縮只在 n ≤ 3（|E| ≤ 12）另比一次，見 check_hypercube_tau_dc。
  // ＊不呼叫 jacobian_order＊：它走子式 gcd，Q_4 是 16×16 ⇒ C(32,16) 個子式，會爆。
  let ok = tau.to_int64() == want
  let detail = "τ(Q_" +
    n.to_string() +
    ") = " +
    tau.to_string() +
    "、|E| = " +
    g.num_edges().to_string() +
    "、登記 = " +
    want.to_string()
  @galois.Check::make(
    "T31",
    "T31 超立方體 τ(Q_" + n.to_string() + ")",
    ok,
    detail,
  )
}

///|
/// T31：Q_n（n ≤ 3）的刪縮遞迴與登記值比對（Q_4 的 32 條邊不適合此路徑）。
pub fn check_hypercube_tau_dc(n : Int32, want : Int64) -> @galois.Check {
  let got = tau_deletion_contraction(hypercube(n))
  let ok = got == want
  @galois.Check::make(
    "T31",
    "T31 超立方體刪縮 τ(Q_" + n.to_string() + ")",
    ok,
    "刪縮 = " + got.to_string() + "、登記 = " + want.to_string(),
  )
}

///|
/// T31：Q_n 的不變因子（與標準 Smith 正規形另算的值比對；n ≤ 3 才枚舉子式）。
pub fn check_hypercube_invariants(
  n : Int32,
  want : Array[Int32],
) -> @galois.Check {
  check_registered_invariants("Q_" + n.to_string(), hypercube(n), want)
}

///|
/// T30：生成樹計數的第三條路徑——刪縮遞迴 τ = τ(G−e) + τ(G/e)，
/// 必須與 |J(G)| = τ（T25）給出同一個數。
pub fn check_deletion_contraction(name : String, g : Graph) -> @galois.Check {
  let rec = tau_deletion_contraction(g)
  let det = spanning_trees_by_det(g)
  let ok = det.to_int64() == rec && jacobian_order(g) == BigInt::from_int64(rec)
  let detail = "刪縮 = " +
    rec.to_string() +
    "、行列式 = " +
    det.to_string() +
    "、|J| = " +
    jacobian_order(g).to_string()
  @galois.Check::make(
    "T30",
    "T30 刪縮遞迴 τ（" + name + "）",
    ok,
    detail,
  )
}

///|
/// T26：與**外部登記的** Smith 正規形比對（以標準 SNF 算法另算一次的結果）。
pub fn check_registered_invariants(
  name : String,
  g : Graph,
  want : Array[Int32],
) -> @galois.Check {
  let fs = invariant_factors(laplacian(g))
  let mut ok = fs.length() == want.length()
  let sb = StringBuilder()
  for i = 0; i < fs.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(fs[i].to_string())
    if i < want.length() && fs[i] != BigInt::from_int(want[i]) {
      ok = false
    }
  }
  let wb = StringBuilder()
  for i = 0; i < want.length(); i = i + 1 {
    if i > 0 {
      wb.write_char(',')
    }
    wb.write_string(want[i].to_string())
  }
  let detail = "實算 [" +
    sb.to_string() +
    "]，登記 [" +
    wb.to_string() +
    "]"
  @galois.Check::make(
    "T26",
    "T26 不變因子對照（" + name + "）",
    ok,
    detail,
  )
}

///|
/// T26′(修正)：J(G)[2] 的階 = ∏ gcd(d_i, 2)；**不**等於 2^{β₁} 的一般陳述是錯的（BUG-7）。
/// 這條檢核驗的是**正確的** SNF 公式，並把兩者並列印出來。
pub fn check_two_torsion(name : String, g : Graph) -> @galois.Check {
  let fs = invariant_factors(laplacian(g))
  let mut order = 1
  for i = 0; i < fs.length(); i = i + 1 {
    if (fs[i] % BigInt::from_int(2)).is_zero() {
      order = order * 2
    }
  }
  let b1 = g.cycle_rank()
  let naive = pow_int(2, b1)
  // 正確性判準：order = 2^{#{i : d_i 偶}}，且 order | 2^{β₁}
  let ok = order <= naive && naive % order == 0
  let detail = "不變因子 " +
    fs.length().to_string() +
    " 個，其中偶數 " +
    count_even(fs).to_string() +
    " 個 ⇒ |J[2]| = " +
    order.to_string() +
    "；β₁ = " +
    b1.to_string() +
    " 給的 2^{β₁} = " +
    naive.to_string() +
    (if order == naive {
      "（此圖恰好相等）"
    } else {
      "（此圖嚴格小於 ⇒ 「|J[2]| = 2^{β₁}」不是普遍定理，見 BUG-7）"
    })
  @galois.Check::make(
    "T26",
    "T26 |J[2]| 的 SNF 公式（" + name + "）",
    ok,
    detail,
  )
}

///|
fn count_even(fs : Array[BigInt]) -> Int32 {
  let mut c = 0
  for i = 0; i < fs.length(); i = i + 1 {
    if (fs[i] % BigInt::from_int(2)).is_zero() {
      c = c + 1
    }
    if fs[i].is_zero() {
      c = c - 1
    }
  }
  c
}

///|
/// T28：Baker–Norine Riemann–Roch 的暴力檢核。
pub fn check_riemann_roch(
  name : String,
  g : Graph,
  degmax : Int32,
) -> @galois.Check {
  let r = riemann_roch(g, degmax)
  let ok = r.violations() == 0 && r.tested() > 0
  let detail = "g = " + g.cycle_rank().to_string() + "、" + r.render()
  @galois.Check::make("T28", "T28 Riemann–Roch（" + name + "）", ok, detail)
}

///|
/// T29：J[2] 上二次細化的 Arf 計數 = 古典公式。
pub fn check_arf_counts(g : Int32) -> @galois.Check {
  let c = count_refinements(g)
  let e0 = expected_arf0(g)
  let e1 = expected_arf1(g)
  let ok = c.arf0 == e0 && c.arf1 == e1 && c.invalid == 0
  let detail = c.render() +
    "；期望 2^{g−1}(2^g+1)=" +
    e0.to_string() +
    "、2^{g−1}(2^g−1)=" +
    e1.to_string() +
    "、總數 2^{2g}=" +
    pow_int(4, g).to_string()
  @galois.Check::make(
    "T29",
    "T29 theta 特徵／Arf 計數（g=" + g.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// T29：Arf 不變量在 Sp_{2g}(𝔽₂) 下不變（僅 g ≤ 2 可全枚舉矩陣）。
pub fn check_arf_invariance(g : Int32) -> @galois.Check {
  let n = 2 * g
  let mats = all_f2_matrices(n)
  let mut symplectic_count = 0
  let mut ok = true
  let mut witness = ""
  for mi = 0; mi < mats.length(); mi = mi + 1 {
    let m = mats[mi]
    if !is_symplectic(g, m) {
      continue
    }
    symplectic_count = symplectic_count + 1
    for ell = 0; ell < 1 << n; ell = ell + 1 {
      if !is_quadratic_refinement(g, ell) {
        continue
      }
      if arf_of_pullback(g, ell, m) != arf_invariant(g, ell) {
        ok = false
        if witness == "" {
          witness = "矩陣 #" + mi.to_string() + "、細化 " + ell.to_string()
        }
      }
    }
  }
  let detail = "|Sp_{2g}(𝔽₂)| = " +
    symplectic_count.to_string() +
    "（g=" +
    g.to_string() +
    "）個保形式矩陣，Arf 全部不變：" +
    ok.to_string() +
    (if ok { "" } else { "，反例 " + witness })
  @galois.Check::make(
    "T29",
    "T29 Arf 在 Sp 下不變（g=" + g.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// 完整報告（T25–T31）。
pub fn jacobian_report() -> @galois.Report {
  let r = @galois.Report::new()
  let gs = sample_graphs()
  for i = 0; i < gs.length(); i = i + 1 {
    let (name, g) = gs[i]
    r.add(check_jacobian_order(name, g))
    r.add(check_cycle_rank(name, g))
    r.add(check_deletion_contraction(name, g))
    r.add(check_two_torsion(name, g))
  }
  for n = 3; n <= 5; n = n + 1 {
    r.add(check_complete_graph_jacobian(n))
  }
  // 超立方體網絡（超立方體網絡群 Q_n 的可計算面）
  r.add(check_hypercube_tau(2, 4))
  r.add(check_hypercube_tau(3, 384))
  r.add(check_hypercube_tau(4, 42467328))
  r.add(check_hypercube_tau_dc(2, 4))
  r.add(check_hypercube_tau_dc(3, 384))
  r.add(check_hypercube_invariants(2, [1, 1, 4]))
  r.add(check_hypercube_invariants(3, [1, 1, 1, 1, 2, 8, 24]))
  // 外部登記的 SNF（以標準 Smith 正規形算法另算）
  r.add(
    check_registered_invariants(
      "K₃",
      { n: 3, edges: [(0, 1), (1, 2), (0, 2)], },
      [1, 3],
    ),
  )
  r.add(
    check_registered_invariants(
      "K₄",
      { n: 4, edges: [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)], },
      [1, 4, 4],
    ),
  )
  r.add(
    check_registered_invariants(
      "K₅",
      {
        n: 5,
        edges: [
          (0, 1),
          (0, 2),
          (0, 3),
          (0, 4),
          (1, 2),
          (1, 3),
          (1, 4),
          (2, 3),
          (2, 4),
          (3, 4),
        ],
      },
      [1, 5, 5, 5],
    ),
  )
  r.add(
    check_registered_invariants(
      "C₄",
      { n: 4, edges: [(0, 1), (1, 2), (2, 3), (3, 0)], },
      [1, 1, 4],
    ),
  )
  r.add(
    check_registered_invariants(
      "C₅",
      { n: 5, edges: [(0, 1), (1, 2), (2, 3), (3, 4), (4, 0)], },
      [1, 1, 1, 5],
    ),
  )
  r.add(
    check_registered_invariants(
      "θ",
      { n: 2, edges: [(0, 1), (0, 1), (0, 1)], },
      [3],
    ),
  )
  r.add(
    check_registered_invariants(
      "蝴蝶結",
      { n: 5, edges: [(0, 1), (1, 2), (0, 2), (2, 3), (3, 4), (2, 4)], },
      [1, 1, 3, 3],
    ),
  )
  r.add(
    check_riemann_roch("K₃", { n: 3, edges: [(0, 1), (1, 2), (0, 2)], }, 3),
  )
  r.add(
    check_riemann_roch(
      "C₄",
      { n: 4, edges: [(0, 1), (1, 2), (2, 3), (3, 0)], },
      3,
    ),
  )
  r.add(check_riemann_roch("θ", { n: 2, edges: [(0, 1), (0, 1), (0, 1)], }, 3))
  r.add(
    check_riemann_roch(
      "K₄",
      { n: 4, edges: [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)], },
      3,
    ),
  )
  for g = 1; g <= 3; g = g + 1 {
    r.add(check_arf_counts(g))
  }
  for g = 1; g <= 2; g = g + 1 {
    r.add(check_arf_invariance(g))
  }
  r
}
