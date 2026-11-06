///|
/// B0008 / cyclic 套件：**檢核器（T51–T63）**
/// 對應 docs/B0008-定理體系.md §B1–§B9。
///
/// 每一條都是「可執行的等式」，且刻意讓同一件事由**兩條獨立路徑**得出：
///   * HH₀：交換子空間的餘維 vs (b,B) 混複體 vs 共端 A ⊗_{Aᵉ} A；
///   * HC  ：(b,B) 混複體的總同調 vs λ-複體 C_n/im(1−τ_n) 的同調；
///   * 秩  ：F_p 上高斯消去 vs 整數列運算（BigInt）精確消去；
///   * 不可約表示個數：Cayley 表暴力算共軛類 vs dim HH₀(ℂ[G])。
/// 另有三個**負控制**（T51b、T55、T61b），確保上面的等式不是恆真。

// ---------------------------------------------------------------- 樣本

///|
/// 樣本代數與其可用度數上限（上限由 chain_size 的成本決定，見 §B9 成本表）。
pub fn cyclic_samples() -> Array[(FdAlg, Int32)] {
  [
    (alg_polys(1), 5),
    (alg_direct_sum(alg_polys(1), alg_polys(1)), 4),
    (alg_polys(2), 4),
    (alg_polys(3), 3),
    (alg_matrix(2), 3),
    (alg_cyclic_group(3), 3),
    (alg_symmetric_group3(), 2),
    (alg_dihedral8(), 2),
  ]
}

// ---------------------------------------------------------------- T51：代數公理

///|
/// T51：單位與結合律（8 個樣本全部）。
pub fn check_axioms(a : FdAlg) -> @galois.Check {
  let unit = alg_unit_ok(a)
  let assoc = alg_assoc_ok(a)
  let ok = unit && assoc
  let detail = "dim=" +
    a.dim.to_string() +
    "、單位=" +
    unit.to_string() +
    "、結合=" +
    assoc.to_string()
  @galois.Check::make(
    "T51",
    "T51 " + a.name + " 是么結合代數",
    ok,
    detail,
  )
}

///|
/// T51b（負控制）：把 k[x]/(x²) 的乘積改壞（e₁·e₁ = e₁，破壞 x² = 0），
/// 結合律必須**失敗**——否則 T51 就是恆真。
pub fn check_axioms_negative() -> @galois.Check {
  let a = alg_polys(3)
  let d = a.dim
  let mult = fd_mult_zero(d)
  for i = 0; i < d; i = i + 1 {
    for j = 0; j < d; j = j + 1 {
      for k = 0; k < d; k = k + 1 {
        fd_set(mult, d, i, j, k, fd_coeff(a, i, j, k))
      }
    }
  }
  // 破壞：把 x·x² = x³ = 0 改成 x·x² = 1（而 x²·x 仍為 x³ = 0）
  fd_set(mult, d, 1, 2, 0, 1L)
  let bad = fd_alg("k[x]/(x³) 但 x·x²=1", d, a.unit_vec, a.aug, mult)
  let ok = !alg_assoc_ok(bad)
  @galois.Check::make(
    "T51b",
    "T51b 負控制：破壞 x·x²=0 後結合律失效",
    ok,
    "結合律=" + alg_assoc_ok(bad).to_string(),
  )
}

// ---------------------------------------------------------------- T52：HH₀

///|
/// T52：HH₀ 的兩條算式相等（dim A/[A,A] vs 混複體的度 0 同調）。
pub fn check_hh0_paths(a : FdAlg) -> @galois.Check {
  let by_comm = hh0_by_commutators(a)
  let by_complex = hh_dim(a, 0)
  let ok = by_comm == by_complex
  @galois.Check::make(
    "T52",
    "T52 " + a.name + " 的 HH₀（交換子 vs 複體）",
    ok,
    "交換子路徑=" +
    by_comm.to_string() +
    "、複體路徑=" +
    by_complex.to_string(),
  )
}

// ---------------------------------------------------------------- T53：混複體公理

///|
/// 每種樣本的公理檢核度數上限（b²、bB+Bb、D²），由矩陣成本決定（§B9）。
pub fn axiom_bounds(dim : Int32) -> Array[Int32] {
  if dim <= 1 {
    [5, 4, 4]
  } else if dim == 2 {
    [4, 4, 3]
  } else if dim <= 4 {
    [3, 3, 3]
  } else if dim <= 6 {
    [2, 1, 2]
  } else {
    [1, 1, 1]
  }
}

///|
/// T53：b² = 0、bB + Bb = 0、D² = 0（度數上限見 `axiom_bounds`）。
pub fn check_complex_axioms(a : FdAlg) -> @galois.Check {
  let bounds = axiom_bounds(a.dim)
  let b2 = check_b_squared_zero(a, bounds[0])
  let anti = check_bB_anticommute(a, bounds[1])
  let d2 = check_total_squared_zero(a, bounds[2])
  let ok = b2 && anti && d2
  @galois.Check::make(
    "T53",
    "T53 " + a.name + " 的 (b,B) 混複體公理",
    ok,
    "度數≤(" +
    bounds[0].to_string() +
    "," +
    bounds[1].to_string() +
    "," +
    bounds[2].to_string() +
    ")、b²=0：" +
    b2.to_string() +
    "、bB+Bb=0：" +
    anti.to_string() +
    "、D²=0：" +
    d2.to_string(),
  )
}

// ---------------------------------------------------------------- T54：HC 兩條路徑

///|
/// T54：HC_n 的混複體路徑與 λ-複體路徑在 0..top 度數上逐度相等。
pub fn check_hc_paths(a : FdAlg, top : Int32) -> @galois.Check {
  let sb = StringBuilder()
  let mut ok = true
  for n = 0; n <= top; n = n + 1 {
    let c = hc_dim_bicomplex(a, n)
    let l = hc_dim_lambda(a, n)
    if c != l {
      ok = false
    }
    sb.write_string(
      "HC" + n.to_string() + "=" + c.to_string() + "/" + l.to_string() + " ",
    )
  }
  @galois.Check::make(
    "T54",
    "T54 " +
    a.name +
    " 的 HC（混複體 vs λ-複體，0.." +
    top.to_string() +
    "）",
    ok,
    sb.to_string(),
  )
}

///|
/// T55（負控制）：把循環算子取成有符號的 λ_n = (−1)^n τ_n，
/// 同一個 HC 公式在 k 的 n=2 上給 0，而真正的 HC₂(k) = 1。故「商掉 1 − (−1)^n t_n」是錯模型。
pub fn check_lambda_signed_negative() -> @galois.Check {
  let a = alg_polys(1)
  let wrong = hc_dim_lambda_signed(a, 2)
  let right = hc_dim_bicomplex(a, 2)
  let ok = right == 1 && wrong != right
  @galois.Check::make(
    "T55",
    "T55 負控制：有符號 λ 的 HC 公式在 k 上失效",
    ok,
    "有符號路徑 HC₂=" +
    wrong.to_string() +
    "、正確 HC₂=" +
    right.to_string(),
  )
}

// ---------------------------------------------------------------- T56：半單

///|
/// T56：半單代數 A ≅ ⊕_{i=1}^{c} M_{d_i}(ℂ) 的循環同調：
/// HH_n = 0（n ≥ 1）、HC_{2k} = c、HC_{2k+1} = 0（Morita 不變性 + 半單性）。
pub fn check_semisimple(
  name : String,
  a : FdAlg,
  comps : Int32,
  top : Int32,
) -> @galois.Check {
  let sb = StringBuilder()
  let mut ok = true
  if hh_dim(a, 0) != comps {
    ok = false
  }
  for n = 1; n <= top; n = n + 1 {
    let h = hh_dim(a, n)
    if h != 0 {
      ok = false
    }
    sb.write_string("HH" + n.to_string() + "=" + h.to_string() + " ")
  }
  for n = 0; n <= top; n = n + 1 {
    let want = if n % 2 == 0 { comps } else { 0 }
    let got = hc_dim_bicomplex(a, n)
    if got != want {
      ok = false
    }
    sb.write_string("HC" + n.to_string() + "=" + got.to_string() + " ")
  }
  @galois.Check::make(
    "T56",
    "T56 " +
    name +
    " 是半單（" +
    comps.to_string() +
    " 個單模）的 HH/HC",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T57：Morita 不變性

///|
/// T57：Morita 不變性——HH_n(M_d(ℂ)) = HH_n(ℂ)、HC_n(M_d(ℂ)) = HC_n(ℂ)。
pub fn check_morita(top : Int32) -> @galois.Check {
  let c = alg_polys(1)
  let m = alg_matrix(2)
  let sb = StringBuilder()
  let mut ok = true
  for n = 0; n <= top; n = n + 1 {
    let hh_same = hh_dim(m, n) == hh_dim(c, n)
    let hc_same = hc_dim_bicomplex(m, n) == hc_dim_bicomplex(c, n)
    if !hh_same || !hc_same {
      ok = false
    }
    sb.write_string(
      "n=" +
      n.to_string() +
      " HH=" +
      hh_dim(m, n).to_string() +
      "/" +
      hh_dim(c, n).to_string() +
      " HC=" +
      hc_dim_bicomplex(m, n).to_string() +
      "/" +
      hc_dim_bicomplex(c, n).to_string() +
      " ",
    )
  }
  @galois.Check::make(
    "T57",
    "T57 Morita：M₂(ℂ) 與 ℂ 的 HH/HC 相同",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T58：加法性

///|
/// T58：加法性——HH_n(A ⊕ B) = HH_n(A) + HH_n(B)、HC_n(A ⊕ B) = HC_n(A) + HC_n(B)。
pub fn check_additivity(top : Int32) -> @galois.Check {
  let a = alg_polys(1)
  let b = alg_polys(2)
  let s = alg_direct_sum(a, b)
  let sb = StringBuilder()
  let mut ok = true
  for n = 0; n <= top; n = n + 1 {
    let want_hh = hh_dim(a, n) + hh_dim(b, n)
    let want_hc = hc_dim_bicomplex(a, n) + hc_dim_bicomplex(b, n)
    if hh_dim(s, n) != want_hh || hc_dim_bicomplex(s, n) != want_hc {
      ok = false
    }
    sb.write_string(
      "n=" +
      n.to_string() +
      " HH=" +
      hh_dim(s, n).to_string() +
      "/" +
      want_hh.to_string() +
      " HC=" +
      hc_dim_bicomplex(s, n).to_string() +
      "/" +
      want_hc.to_string() +
      " ",
    )
  }
  @galois.Check::make(
    "T58",
    "T58 直和（ℂ ⊕ k[x]/x²）的 HH/HC 加法性",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T59：群代數

///|
/// T59：ℂ[G] 的循環同調由群決定——
/// dim HH₀(ℂ[G]) = 共軛類個數（Cayley 表暴力算），且 HH_n = 0（n ≥ 1）。
pub fn check_group_algebra(
  name : String,
  n : Int32,
  table : Array[Int32],
  top : Int32,
) -> @galois.Check {
  let a = alg_group(name, n, table)
  let classes = group_conjugacy_classes(n, table)
  let hh0 = hh_dim(a, 0)
  let mut ok = hh0 == classes && group_table_ok(n, table)
  let sb = StringBuilder()
  sb.write_string(
    "群階=" +
    n.to_string() +
    "、共軛類=" +
    classes.to_string() +
    "、HH₀=" +
    hh0.to_string(),
  )
  for k = 1; k <= top; k = k + 1 {
    if hh_dim(a, k) != 0 {
      ok = false
    }
    sb.write_string("、HH" + k.to_string() + "=" + hh_dim(a, k).to_string())
  }
  @galois.Check::make(
    "T59",
    "T59 " + name + "：HH₀ = 共軛類、HH_n = 0",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T60：外部張量積

///|
/// T60：外部張量積代數 A ⊗_k B 的乘法性：
/// dim HH₀(A⊗B) = dim HH₀(A)·dim HH₀(B)，
/// 且當 A、B 半單時 HC_{2k}(A⊗B) = HC_{2k}(A)·HC_{2k}(B)（k = 0,1）。
pub fn check_tensor_multiplicative(
  a : FdAlg,
  b : FdAlg,
  top : Int32,
) -> @galois.Check {
  let ab = alg_tensor(a, b)
  let sb = StringBuilder()
  let want0 = hh_dim(a, 0) * hh_dim(b, 0)
  let got0 = xprod_hh0_product(a, b)
  let mut ok = got0 == want0
  sb.write_string(
    "dim=" +
    ab.dim.to_string() +
    "、HH₀=" +
    got0.to_string() +
    "/" +
    want0.to_string(),
  )
  for k = 0; k <= top; k = k + 1 {
    let want = hc_dim_bicomplex(a, 2 * k) * hc_dim_bicomplex(b, 2 * k)
    let got = xprod_hc_even(a, b, k)
    if got != want {
      ok = false
    }
    sb.write_string(
      "、HC" +
      (2 * k).to_string() +
      "=" +
      got.to_string() +
      "/" +
      want.to_string(),
    )
  }
  @galois.Check::make(
    "T60",
    "T60 (" + a.name + ") ⊗ (" + b.name + ") 的 HH₀/HC 乘法性",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T61：內部張量積

///|
/// T61：內部張量積的結構定理（維度級，皆由關係矩陣的秩算出）：
///   X1 單位：dim(A ⊗_A A) = dim A、dim(A ⊗_A k_ε) = dim(k_ε ⊗_A A) = 1（A 增廣）；
///   X2 共端：dim(A ⊗_{Aᵉ} A) = dim A/[A,A] = HH₀；
///   X3 伴隨：dim Hom_{A,A}(A, A) = dim Z(A)（A 的雙模不變量）。
pub fn check_internal_tensor(a : FdAlg) -> @galois.Check {
  let reg = bimod_regular(a)
  let sb = StringBuilder()
  let mut ok = bimod_ok(reg)
  let unit_dim = bimod_tensor_dim(reg, reg)
  if unit_dim != a.dim {
    ok = false
  }
  sb.write_string(
    "dim(A⊗_A A)=" + unit_dim.to_string() + "/" + a.dim.to_string(),
  )
  if alg_aug_ok(a) {
    let triv = bimod_aug(a)
    let d1 = bimod_tensor_dim(reg, triv)
    let d2 = bimod_tensor_dim(triv, reg)
    if d1 != 1 || d2 != 1 {
      ok = false
    }
    sb.write_string(
      "、A⊗_A k=" + d1.to_string() + "、k⊗_A A=" + d2.to_string(),
    )
  } else {
    sb.write_string("、無增廣（略 k_ε）")
  }
  let coend = hh0_by_coend(a)
  let comm = hh0_by_commutators(a)
  if coend != comm {
    ok = false
  }
  sb.write_string(
    "、共端=" + coend.to_string() + "/HH₀=" + comm.to_string(),
  )
  let hom = bimod_hom_dim(reg, reg)
  let inv = bimod_invariant_dim(reg)
  if hom != inv {
    ok = false
  }
  sb.write_string("、Hom=" + hom.to_string() + "/Z(A)=" + inv.to_string())
  @galois.Check::make(
    "T61",
    "T61 " + a.name + " 的內部張量積（單位/共端/伴隨）",
    ok,
    sb.to_string(),
  )
}

///|
/// T61b（負控制）：零作用「雙模」不是雙模（單位元不作用為恆等），
/// 且 A ⊗_A M₀ = 0 ≠ dim M₀——說明 X1 的成立**依賴么性**。
pub fn check_internal_tensor_negative() -> @galois.Check {
  let a = alg_polys(2)
  let reg = bimod_regular(a)
  let zero = bimod_zero_act(a)
  let not_bimod = !bimod_ok(zero)
  let dim = bimod_tensor_dim(reg, zero)
  let ok = not_bimod && dim != zero.dim
  @galois.Check::make(
    "T61b",
    "T61b 負控制：零作用模不是雙模，單位定理失效",
    ok,
    "bimod_ok=" +
    bimod_ok(zero).to_string() +
    "、dim(A⊗_A M₀)=" +
    dim.to_string() +
    "（而 dim M₀=" +
    zero.dim.to_string() +
    "）",
  )
}

// ---------------------------------------------------------------- T62：漸新態射

///|
/// T62：漸新態射（assembly maps）四支映射的樣本檢核。
pub fn check_assembly() -> Array[@galois.Check] {
  let out : Array[@galois.Check] = []
  let s3 = symmetric_group3_table()
  let d8 = dihedral8_table()
  let c3 = cyclic_group_table(3)
  // ASForget：HH₀ → HC₀ 同構
  let sb = StringBuilder()
  let mut forget_ok = true
  for (a, _) in cyclic_samples() {
    if !as_forget_ok(a) {
      forget_ok = false
    }
    sb.write_string(a.name + "=" + hh_dim(a, 0).to_string() + " ")
  }
  out.push(
    @galois.Check::make(
      "T62a",
      "T62a ASForget：HH₀ → HC₀ 是同構",
      forget_ok,
      sb.to_string(),
    ),
  )
  // ASIndex：指數映射的秩 = 共軛類
  let idx_ok = as_index_matches_classes(6, s3) &&
    as_index_matches_classes(8, d8) &&
    as_index_matches_classes(3, c3)
  out.push(
    @galois.Check::make(
      "T62b",
      "T62b ASIndex：ℂ[S₃]、ℂ[D₈]、ℂ[ℤ/3] 的秩 = 共軛類個數",
      idx_ok,
      "共軛類 = " +
      group_conjugacy_classes(6, s3).to_string() +
      "、" +
      group_conjugacy_classes(8, d8).to_string() +
      "、" +
      group_conjugacy_classes(3, c3).to_string(),
    ),
  )
  // ASBott：HC_n = HC_{n−2}
  let bott_ok = as_bott_periodic(alg_polys(1), 4) &&
    as_bott_periodic(alg_polys(2), 4) &&
    as_bott_periodic(alg_matrix(2), 3) &&
    as_bott_periodic(alg_cyclic_group(3), 3) &&
    as_bott_periodic(alg_symmetric_group3(), 2) &&
    as_bott_periodic(alg_dihedral8(), 2)
  out.push(
    @galois.Check::make(
      "T62c", "T62c ASBott：HC_n = HC_{n−2}（6 個樣本）", bott_ok, "k/k[x]/x²/M₂/ℂ[ℤ/3]/ℂ[S₃]/ℂ[D₈] 皆 2-週期",
    ),
  )
  // ASAssembly：正度數消失 + 偶數度秩 = 共軛類
  let asm_ok = as_assembly_vanishing(alg_symmetric_group3(), 2) &&
    as_assembly_vanishing(alg_dihedral8(), 2) &&
    as_assembly_even_rank(6, s3, 1) &&
    as_assembly_even_rank(8, d8, 1) &&
    as_assembly_even_rank(3, c3, 1) &&
    as_assembly_odd_vanishes(6, s3, 0) &&
    as_assembly_odd_vanishes(8, d8, 0) &&
    as_assembly_odd_vanishes(3, c3, 1)
  out.push(
    @galois.Check::make(
      "T62d", "T62d ASAssembly：正度數 HH_n = 0、HC_{2k} = 共軛類、HC_{2k+1} = 0",
      asm_ok, "ℂ[S₃]（3）、ℂ[D₈]（5）、ℂ[ℤ/3]（3）",
    ),
  )
  out
}

// ---------------------------------------------------------------- T63：秩的交叉驗證

///|
/// T63：`rank_q`（F_p 上高斯消去，多質數取最大）與 `rank_exact`（BigInt 整數消去）
/// 在樣本的小矩陣上完全一致；並驗證 rank 不超過 min(列, 欄)。
pub fn check_rank_cross() -> @galois.Check {
  let sb = StringBuilder()
  let mut ok = true
  let mut tested = 0
  for (a, _) in cyclic_samples() {
    for n = 1; n <= 2; n = n + 1 {
      if chain_size(a, n + 1) <= 216 {
        let b = bar_matrix(a, n)
        let r1 = rank_q(b)
        let r2 = rank_exact(b)
        tested = tested + 1
        if r1 != r2 || r1 > chain_size(a, n) {
          ok = false
          sb.write_string(
            "✗" +
            a.name +
            "/b" +
            n.to_string() +
            "：" +
            r1.to_string() +
            "≠" +
            r2.to_string() +
            " ",
          )
        }
      }
    }
  }
  sb.write_string("共驗 " + tested.to_string() + " 個條邊矩陣")
  @galois.Check::make(
    "T63",
    "T63 rank_q 與 rank_exact 交叉一致",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- 報告

///|
/// 全部檢核（T51–T63）。
pub fn cyclic_report() -> @galois.Report {
  let r = @galois.Report::new()
  for (a, top) in cyclic_samples() {
    r.add(check_axioms(a))
    r.add(check_hh0_paths(a))
    r.add(check_complex_axioms(a))
    r.add(check_hc_paths(a, top))
    r.add(check_internal_tensor(a))
  }
  r.add(check_axioms_negative())
  r.add(check_lambda_signed_negative())
  r.add(check_internal_tensor_negative())
  r.add(check_semisimple("M₂(ℂ)", alg_matrix(2), 1, 3))
  r.add(check_semisimple("ℂ[ℤ/3]", alg_cyclic_group(3), 3, 3))
  r.add(check_semisimple("ℂ[S₃]", alg_symmetric_group3(), 3, 2))
  r.add(check_semisimple("ℂ[D₈]", alg_dihedral8(), 5, 2))
  r.add(check_morita(3))
  r.add(check_additivity(4))
  r.add(check_group_algebra("ℂ[ℤ/3]", 3, cyclic_group_table(3), 3))
  r.add(check_group_algebra("ℂ[S₃]", 6, symmetric_group3_table(), 2))
  r.add(check_group_algebra("ℂ[D₈]", 8, dihedral8_table(), 2))
  r.add(
    check_tensor_multiplicative(
      alg_direct_sum(alg_polys(1), alg_polys(1)),
      alg_direct_sum(alg_polys(1), alg_polys(1)),
      1,
    ),
  )
  r.add(check_tensor_multiplicative(alg_matrix(2), alg_polys(1), 1))
  for c in check_assembly() {
    r.add(c)
  }
  r.add(check_rank_cross())
  r
}

// ---------------------------------------------------------------- 結構表

///|
/// HH/HC 結構表（供 `moon run cmd/main -- cyctable`）。
pub fn cyc_table_render() -> String {
  let sb = StringBuilder()
  for (a, top) in cyclic_samples() {
    sb.write_string(a.name + "（dim " + a.dim.to_string() + "）")
    for n = 0; n <= top; n = n + 1 {
      sb.write_string(
        "  n" +
        n.to_string() +
        ":" +
        hh_dim(a, n).to_string() +
        "/" +
        hc_dim_bicomplex(a, n).to_string(),
      )
    }
    sb.write_string("\n")
  }
  sb.to_string()
}
