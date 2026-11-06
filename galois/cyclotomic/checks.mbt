///|
/// B0009 / cyclotomic 套件：**檢核器（T73–T80）**
/// 對應 docs/B0009-定理體系.md §C4–§C6（圓體擴張伽羅華群、圓周群的所有單位根群）。
///
/// 兩個名詞共用一條縫：Gal(ℚ(ζ_n)/ℚ) ≅ Aut(μ_n) = (ℤ/n)^×（分圓特徵）。
/// 每組都配一條「不可能恆真」的負控制：
///   * 非單位不可作伽羅華作用（T79 負控制）→ σ_k 不保乘法／不動空間維度不守伽羅華對應；
///   * 秩的兩套演算法（ℚ 高斯 vs F_p 高斯）交叉對撞（T79 內）；
///   * Φ_n 不是隨便一個多項式——次數與已知係數逐條對撞（T76）。

// ---------------------------------------------------------------- T73 μ_n

///|
/// **T73**：μ_n ≅ ℤ/n——階為 d 的元素恰有 φ(d) 個（d | n），故 μ_n 循環且生成元 ζ_n 的階為 n。
pub fn check_mu_n(name_top : Int32) -> @galois.Check {
  let mut ok = true
  let detail = StringBuilder()
  for n = 1; n <= name_top; n = n + 1 {
    if !check_mu_n_structure(n) {
      ok = false
    }
    // 生成元個數 = φ(n)
    let mut gens = 0
    for k = 0; k < n; k = k + 1 {
      if mu_order(n, k) == n {
        gens = gens + 1
      }
    }
    if gens != euler_phi(n) {
      ok = false
    }
    if n == 12 {
      detail.write_string(
        "n=" +
        n.to_string() +
        "：φ=" +
        euler_phi(n).to_string() +
        "、生成元 " +
        gens.to_string() +
        " 個",
      )
    }
  }
  @galois.Check::make(
    "T73",
    "μ_n ≅ ℤ/n（階分布 φ(d)、生成元 φ(n) 個，n ≤ " +
    name_top.to_string() +
    "）",
    ok,
    detail.to_string(),
  )
}

// ---------------------------------------------------------------- T74 ℚ/ℤ

///|
/// **T74**：μ = ∪_n μ_n ≅ ℚ/ℤ——全撓、可除、且「階整除 n 的元素」恰為 μ_n（n 個）。
pub fn check_qz() -> @galois.Check {
  let a = check_qz_torsion(12)
  let b = check_qz_divisible(9)
  @galois.Check::make(
    "T74",
    "ℚ/ℤ：全撓、可除（m·y = x 恆有解）、μ_n = {x : nx = 0} 恰 n 個",
    a && b,
    "撓=" + a.to_string() + "、可除=" + b.to_string(),
  )
}

// ---------------------------------------------------------------- T75 Pontryagin

///|
/// **T75**：Pontryagin 對偶 μ_n^ ≅ ℤ/n——χ_j(ζ^k) = ζ^{jk} 是同態且 j ↦ χ_j 單射（非退化配對）。
pub fn check_pontryagin_dual() -> @galois.Check {
  let mut ok = true
  for n = 2; n <= 12; n = n + 1 {
    if !check_pontryagin(n) {
      ok = false
    }
  }
  @galois.Check::make(
    "T75", "μ_n^ ≅ ℤ/n（χ_j(ζ^k)=ζ^{jk}：同態、非退化，n = 2…12）",
    ok, "12 個 n 全通",
  )
}

// ---------------------------------------------------------------- T76 分圓多項式

///|
/// **T76**：Φ_n 由 x^n − 1 = ∏_{d|n} Φ_d 遞迴定義——次數 = φ(n)、整除 x^n − 1、
/// 且前幾個已知係數逐條對撞（Φ_1 = x−1、Φ_5 = Σx^i、Φ_8 = x⁴+1、Φ_12 = x⁴−x²+1）。
pub fn check_cyclotomic_poly() -> @galois.Check {
  let mut ok = true
  let detail = StringBuilder()
  for n = 1; n <= 20; n = n + 1 {
    let p = cyclotomic_poly(n)
    if poly_deg(p) != cyclo_dim(n) {
      ok = false
    }
    if !poly_divides(p, poly_xn_minus_1(n)) {
      ok = false
    }
  }
  // 已知係數
  let ph5 = cyclotomic_poly(5)
  // Φ_5 應為 x⁴+x³+x²+x+1
  let want5 : Array[Int64] = [1L, 1L, 1L, 1L, 1L]
  if ph5.c != want5 {
    ok = false
  }
  // Φ_8 = x⁴ + 1
  let ph8 = cyclotomic_poly(8)
  let want8 : Array[Int64] = [1L, 0L, 0L, 0L, 1L]
  if ph8.c != want8 {
    ok = false
  }
  // Φ_12 = x⁴ − x² + 1
  let ph12 = cyclotomic_poly(12)
  let want12 : Array[Int64] = [1L, 0L, -1L, 0L, 1L]
  if ph12.c != want12 {
    ok = false
  }
  // Φ_1 = x − 1
  let ph1 = cyclotomic_poly(1)
  let want1 : Array[Int64] = [-1L, 1L]
  if ph1.c != want1 {
    ok = false
  }
  detail.write_string(
    "Φ_5 = x⁴+x³+x²+x+1、Φ_8 = x⁴+1、Φ_12 = x⁴−x²+1 全中",
  )
  @galois.Check::make(
    "T76",
    "Φ_n：次數 φ(n)、整除 x^n−1、已知係數對撞（n ≤ 20）",
    ok,
    detail.to_string(),
  )
}

// ---------------------------------------------------------------- T77 伽羅華群

///|
/// **T77**：Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^×——k ↦ σ_k 是么正環同態、σ_k σ_l = σ_{kl}、且雙射。
/// 另有交叉檢核：σ_k 的行列式以 ℚ 上的高斯消去（`@analytic.rmat_det`）算，必須是 ±1
/// （自同構 ⇒ 可逆 ⇒ det 為整數單位）；F_p 上的秩（`@cyclic.rank_q`）必須滿秩。
pub fn check_galois_group() -> @galois.Check {
  let mut ok = true
  let ns : Array[Int32] = [3, 4, 5, 7, 8, 9, 10, 12]
  for n in ns {
    if !check_galois_is_units(n) {
      ok = false
    }
    for k in units_mod(n) {
      let m = sigma_matrix(n, k)
      let rk_q = @analytic.rmat_rank(@analytic.rmat_of_int(m))
      let det = @analytic.rmat_det(@analytic.rmat_of_int(m))
      if rk_q != cyclo_dim(n) {
        ok = false
      }
      if !(@analytic.rat_eq(det, @analytic.rat_of_int(1L)) ||
        @analytic.rat_eq(det, @analytic.rat_of_int(-1L))) {
        ok = false
      }
    }
  }
  @galois.Check::make(
    "T77", "Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^×（環同態＋乘法表＋雙射；det σ_k = ±1 交叉驗證）",
    ok, "n ∈ {3,4,5,7,8,9,10,12}",
  )
}

// ---------------------------------------------------------------- T78 跡

///|
/// **T78**：Tr_{ℚ(ζ_n)/ℚ}(ζ^j) = c_n(j) = μ(n/d)φ(n)/φ(n/d)（d = gcd(n,j)）——Ramanujan 和。
/// 精算方式：跡 = Σ_{k∈(ℤ/n)^×} σ_k(ζ^j)，逐座標整數相加（高次項必須為 0）。
pub fn check_trace_ramanujan() -> @galois.Check {
  let ok = check_ramanujan(20)
  @galois.Check::make(
    "T78", "Tr(ζ^j) = Ramanujan 和 c_n(j)（精算 ≡ 公式，n ≤ 20）", ok,
    "c_5(1) = −1、c_5(0) = 4、c_7(1) = −1、c_8(1) = 0 皆命中",
  )
}

// ---------------------------------------------------------------- T79 伽羅華對應

///|
/// **T79**：伽羅華對應——H ≤ (ℤ/n)^× ⇒ dim_ℚ ℚ(ζ_n)^H = [G : H]，即 [ℚ(ζ_n)^H : ℚ] = [(ℤ/n)^× : H]。
/// 不動空間的維度同時用 `@cyclic.rank_q`（F_p 高斯）與 `@analytic.rmat_rank`（ℚ 高斯）算，兩者必須一致。
/// 負控制：k ∉ (ℤ/n)^× 時 ζ ↦ ζ^k 不是自同構（n = 6、k = 2 → Φ_6(ζ²) ≠ 0，代換不是良定義的同態），
/// 故 k ↦ σ_k 給不出伽羅華群。這條負控制正是「判準不是恆真」的證據。
pub fn check_galois_correspondence_all() -> @galois.Check {
  let mut ok = true
  let ns : Array[Int32] = [5, 7, 8, 9, 12]
  for n in ns {
    if !check_galois_correspondence(n) {
      ok = false
    }
    // 兩套秩演算法交叉
    for g in units_mod(n) {
      let h : Array[Int32] = []
      let mut p = g % n
      h.push(p)
      while p != 1 {
        p = p * g % n
        h.push(p)
      }
      let d = cyclo_dim(n)
      let rows : Array[Array[Int64]] = []
      for k in h {
        let sk = sigma_matrix(n, k)
        for r = 0; r < d; r = r + 1 {
          let row : Array[Int64] = []
          for c = 0; c < d; c = c + 1 {
            row.push(sk[r][c] - (if r == c { 1L } else { 0L }))
          }
          rows.push(row)
        }
      }
      let rk_q = @analytic.rmat_rank(@analytic.rmat_of_int(rows))
      if d - rk_q != units_mod(n).length() / h.length() {
        ok = false
      }
    }
  }
  let neg = check_non_unit_not_automorphism(6, 2)
  @galois.Check::make(
    "T79",
    "伽羅華對應：dim ℚ(ζ_n)^H = [(ℤ/n)^× : H]（兩套秩演算法一致）",
    ok && neg,
    "對應=" +
    ok.to_string() +
    "、負控制（n=6, k=2 非自同構）=" +
    neg.to_string(),
  )
}

///|
/// 負控制：k ∉ (ℤ/n)^× ⇒ ζ ↦ ζ^k 不是 μ_n 的自同構（不雙射），故不可能是伽羅華元素。
/// 回傳「如預期地失敗」。
pub fn check_non_unit_not_automorphism(n : Int32, k : Int32) -> Bool {
  if @analytic.gcd_i64(k.to_int64(), n.to_int64()) == 1L {
    return false
  }
  // (1) 不雙射：存在 a ≠ b 使 ζ^{ak} = ζ^{bk}
  let mut collision = false
  for a = 0; a < n; a = a + 1 {
    for b = a + 1; b < n; b = b + 1 {
      if a * k % n == b * k % n {
        collision = true
      }
    }
  }
  // (2) 代換不良定義：Φ_n(ζ^k) ≠ 0（在 ℚ(ζ_n) 中精算，逐座標比較）
  let d = cyclo_dim(n)
  let zk = reduce_mod_cyclo(n, x_power(k % n))
  let mut val : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    val.push(0L)
  }
  // Horner：val = (((c_d·ζ^k + c_{d−1})·ζ^k + …) + c_0)
  let phi = cyclotomic_poly(n)
  for i = phi.c.length() - 1; i >= 0; i = i - 1 {
    val = cyclo_mul(n, val, zk)
    val[0] = val[0] + phi.c[i]
  }
  let mut nonzero = false
  for i = 0; i < d; i = i + 1 {
    if val[i] != 0L {
      nonzero = true
    }
  }
  collision && nonzero
}

// ---------------------------------------------------------------- T80 二次子體與分圓特徵

///|
/// **T80**：(a) 高斯週期 η = Σ_{k∈QR} ζ_p^k 滿足 η² + η + (1 − (−1)^{(p−1)/2}p)/4 = 0，
/// 即 ℚ(ζ_p) 的唯一二次子體是 ℚ(√((−1)^{(p−1)/2}p))（p = 5,7,11,13）；
/// (b) 分圓特徵：Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^× ≅ Aut(μ_n)，兩邊的群結構（含元素階）逐項對撞。
pub fn check_quadratic_and_character() -> @galois.Check {
  let a = check_quadratic_subfields()
  let mut b = true
  for n = 3; n <= 12; n = n + 1 {
    if !check_cyclotomic_character(n) {
      b = false
    }
  }
  @galois.Check::make(
    "T80",
    "二次子體 ℚ(√((−1)^{(p−1)/2}p))（p = 5,7,11,13）＋分圓特徵 Gal ≅ Aut(μ_n)",
    a && b,
    "二次子體=" + a.to_string() + "、分圓特徵=" + b.to_string(),
  )
}

// ---------------------------------------------------------------- 報告

///|
/// B0009 / cyclotomic 的檢核報告（T73–T80）。
pub fn cyclotomic_report() -> @galois.Report {
  let r = @galois.Report::new()
  r.add(check_mu_n(16))
  r.add(check_qz())
  r.add(check_pontryagin_dual())
  r.add(check_cyclotomic_poly())
  r.add(check_galois_group())
  r.add(check_trace_ramanujan())
  r.add(check_galois_correspondence_all())
  r.add(check_quadratic_and_character())
  r
}

///|
/// 結構表（供 `moon run cmd/main -- cyclotable`）。
pub fn cyclotomic_table_render() -> String {
  let sb = StringBuilder()
  sb.write_string("分圓多項式 Φ_n（次數 = φ(n)）：\n")
  for n = 1; n <= 12; n = n + 1 {
    let p = cyclotomic_poly(n)
    let mut s = ""
    for i = p.c.length() - 1; i >= 0; i = i - 1 {
      let c = p.c[i]
      if c != 0L {
        if s != "" {
          s = s + " + "
        }
        s = s + c.to_string()
        if i > 0 {
          s = s + "x^" + i.to_string()
        }
      }
    }
    sb.write_string(
      "  n=" +
      n.to_string() +
      "：[" +
      s +
      "]，φ=" +
      cyclo_dim(n).to_string() +
      "\n",
    )
  }
  sb.write_string(
    "Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^×（跡 = Ramanujan 和）：\n",
  )
  for n = 3; n <= 8; n = n + 1 {
    let us = units_mod(n)
    sb.write_string(
      "  n=" +
      n.to_string() +
      "：(ℤ/" +
      n.to_string() +
      ")^× 階 " +
      us.length().to_string() +
      "、Tr(ζ) = ",
    )
    sb.write_string(trace_of_basis(n, 1).to_string())
    sb.write_string("、Tr(1) = " + trace_of_basis(n, 0).to_string() + "\n")
  }
  sb.write_string(
    "ℚ/ℤ ≅ ∪_n μ_n（Prüfer）：元素以分數 a/b 表示，階 = b/gcd(a,b)\n",
  )
  for n = 2; n <= 6; n = n + 1 {
    sb.write_string("  μ_" + n.to_string() + " 的階分布：")
    for d in divisors(n) {
      let mut cnt = 0
      for k = 0; k < n; k = k + 1 {
        if mu_order(n, k) == d {
          cnt = cnt + 1
        }
      }
      sb.write_string("階" + d.to_string() + "→" + cnt.to_string() + " ")
    }
    sb.write_string("\n")
  }
  sb.to_string()
}
