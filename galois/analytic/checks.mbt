///|
/// B0009 / analytic 套件：**檢核器（T64–T72）**
/// 對應 docs/B0009-定理體系.md §C1–§C3。
///
/// 三組名詞各有一條「不可能恆真」的負控制：
///   * 近似單位元 —— 么代數上同一序列不收斂（T65）；
///   * 非交換投影 —— 非正交投影之和不是投影、pq 不是投影（T68）；
///   * 同倫不變性 —— A² = 0 拿掉後冪等性立即失效、不同秩不同類（T71）。
/// 另有 T72：ℚ 上高斯的秩與 B0008 的 `rank_q`（F_p 上高斯，三質數取最大）交叉驗證。

// ---------------------------------------------------------------- 秩的交叉驗證

///|
/// 把 ℚ-矩陣通分成整數矩陣（共同分母 = 所有分母的最小公倍數）。
pub fn rmat_to_int(m : RMat) -> Array[Array[Int64]] {
  let mut den : Int64 = 1L
  for x in m.e {
    den = den / gcd_i64(den, x.den) * x.den
  }
  let out : Array[Array[Int64]] = []
  for i = 0; i < m.rows; i = i + 1 {
    let row : Array[Int64] = []
    for j = 0; j < m.cols; j = j + 1 {
      let x = rmat_get(m, i, j)
      row.push(x.num * (den / x.den))
    }
    out.push(row)
  }
  out
}

///|
/// **T72**：`rmat_rank`（ℚ 上高斯）與 `@cyclic.rank_q`（F_p 上高斯、三質數取最大）
/// 在樣本矩陣上完全一致。
pub fn check_rank_cross() -> @galois.Check {
  let ts : Array[Rat] = [rat_of_int(0L), rat_new(1L, 2L), rat_of_int(3L)]
  let mats : Array[RMat] = [
    proj_e11(),
    proj_angled(),
    diag_proj(2, 5),
    shift_matrix(5),
    idem_sample(),
    idem_path(idem_sample(), nilpotent_12(), rat_new(1L, 3L)),
    cayley_orth(antisym_12(), rat_new(1L, 2L)),
    rmat_mul(proj_e11(), proj_angled()),
  ]
  let mut ok = true
  let mut tested = 0
  for m in mats {
    tested = tested + 1
    if rmat_rank(m) != @cyclic.rank_q(rmat_to_int(m)) {
      ok = false
    }
  }
  // 路徑上的矩陣一併驗
  for t in ts {
    let m = idem_path(idem_sample(), nilpotent_12(), t)
    tested = tested + 1
    if rmat_rank(m) != @cyclic.rank_q(rmat_to_int(m)) {
      ok = false
    }
  }
  @galois.Check::make(
    "T72",
    "T72 秩的兩套演算法（ℚ 高斯 vs F_p 高斯）交叉一致",
    ok,
    "共驗 " + tested.to_string() + " 個矩陣",
  )
}

// ---------------------------------------------------------------- T64 近似單位元

///|
/// **T64**：{e_n} 是遞增投影族，且對右移算子 S 有**閉式**收斂
/// ‖e_n S − S‖₂² = N − 1 − n；對秩 r 投影在 n ≥ r 後恰為 0。
pub fn check_approx_identity() -> @galois.Check {
  let inc = approx_increasing(5)
  let conv = check_approx_conv_shift(5)
  let convp = check_approx_conv_projection(2, 5)
  let compress = check_approx_compress(5)
  let rest = check_approx_rest(2, 5)
  let sb = StringBuilder()
  sb.write_string("遞增=" + inc.to_string())
  sb.write_string("、‖e_nS−S‖₂²= N−1−n：" + conv.to_string())
  sb.write_string("、投影收斂=" + convp.to_string())
  sb.write_string("、壓縮穩定=" + compress.to_string())
  sb.write_string("、面積 r−n：" + rest.to_string())
  let ok = inc && conv && convp && compress && rest
  @galois.Check::make(
    "T64",
    "T64 近似單位元（遞增、閉式收斂、壓縮）",
    ok,
    sb.to_string(),
  )
}

///|
/// **T65（負控制）**：在么代數上同一個 {e_n} 不是近似單位元
/// （‖e_n·1 − 1‖₂² = N − n 永不為 0）。
pub fn check_approx_negative() -> @galois.Check {
  let ok = approx_negative_unital(4)
  let sb = StringBuilder()
  for n = 0; n < 4; n = n + 1 {
    let e = diag_proj(n, 4)
    let v = rmat_norm2(rmat_sub(rmat_mul(e, rmat_id(4)), rmat_id(4)))
    sb.write_string("n=" + n.to_string() + ":" + rat_to_string(v) + " ")
  }
  @galois.Check::make(
    "T65",
    "T65 負控制：么代數上 {e_n} 不是近似單位元",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T66 投影與 K₀

///|
/// **T66**：投影的 K₀ 面——rank = tr(p)（兩條算式）、投影和的正交判準、K₀ 加性。
pub fn check_projection_k0() -> @galois.Check {
  let a = check_rank_equals_trace()
  let b = check_sum_of_projections()
  let c = check_k0_additivity()
  let sb = StringBuilder()
  sb.write_string("秩=跡：" + a.to_string())
  sb.write_string("、正交和才是投影：" + b.to_string())
  sb.write_string("、rank(p⊕q)=rank p+rank q：" + c.to_string())
  @galois.Check::make(
    "T66",
    "T66 投影與 K₀（跡、正交和、加性）",
    a && b && c,
    sb.to_string(),
  )
}

///|
/// **T67**：Murray–von Neumann 等價 ⟺ 秩相等；可交換對生成 ℂ²、非交換對生成 M₂(ℂ)。
pub fn check_mvn() -> @galois.Check {
  let a = check_murray_von_neumann()
  let b = check_generated_algebra()
  let sb = StringBuilder()
  sb.write_string("MvN 見證（vvᵀ = p、vᵀv = q）：" + a.to_string())
  sb.write_string("、生成代數維度（2 / 4）：" + b.to_string())
  @galois.Check::make(
    "T67",
    "T67 Murray–von Neumann 等價與生成的代數",
    a && b,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T68 非交換投影

///|
/// **T68**：非交換投影的量化——pq 不是投影、主角度 cos²θ = tr(pq) = 9/25、
/// 交換子範數閉式 ‖pq − qp‖₂² = 2 sin²θcos²θ = 288/625、pq 是投影 ⟺ 對易。
pub fn check_noncommutative() -> @galois.Check {
  let a = check_noncommuting_projections()
  let b = check_product_projection_criterion()
  let p = proj_e11()
  let q = proj_angled()
  let cos2 = rmat_trace(rmat_mul(p, q))
  let com = rmat_norm2(rmat_sub(rmat_mul(p, q), rmat_mul(q, p)))
  let sb = StringBuilder()
  sb.write_string("非交換=" + a.to_string())
  sb.write_string("、pq 判準=" + b.to_string())
  sb.write_string("、cos²θ=tr(pq)=" + rat_to_string(cos2))
  sb.write_string("、‖[p,q]‖₂²=" + rat_to_string(com))
  @galois.Check::make(
    "T68",
    "T68 非交換投影（主角度與交換子閉式）",
    a && b,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T69–T71 同倫

///|
/// **T69**：冪等元同倫族 e_t = (1+tA)e(1−tA)（A² = 0）：全程冪等、秩不變，
/// 且可以把「非投影冪等元」[[1,1],[0,0]] 連到投影 [[1,0],[0,0]]。
pub fn check_idempotent_homotopy() -> @galois.Check {
  let ts : Array[Rat] = [
    rat_of_int(0L),
    rat_new(1L, 2L),
    rat_of_int(1L),
    rat_of_int(3L),
  ]
  let ok = check_idem_path(idem_sample(), nilpotent_12(), ts)
  let sb = StringBuilder()
  for t in ts {
    let et = idem_path(idem_sample(), nilpotent_12(), t)
    sb.write_string(
      "t=" + rat_to_string(t) + "→[" + rmat_to_string(et) + "] ",
    )
  }
  @galois.Check::make(
    "T69",
    "T69 冪等元同倫（A²=0 的顯式族，秩不變）",
    ok,
    sb.to_string(),
  )
}

///|
/// **T70**：投影同倫族 p_t = u_t p u_tᵀ（u_t 為 Cayley 正交陣）＋ K₁ 的 det 不變量。
pub fn check_projection_homotopy() -> @galois.Check {
  let ts : Array[Rat] = [
    rat_of_int(0L),
    rat_new(1L, 2L),
    rat_of_int(1L),
    rat_of_int(3L),
  ]
  let a = check_projection_path(proj_e11(), antisym_12(), ts)
  let b = check_projection_path_endpoints()
  let c = check_k1_det_invariant()
  let sb = StringBuilder()
  sb.write_string(
    "投影路徑（正交、秩不變、det 恆定）：" + a.to_string(),
  )
  sb.write_string("、端點不同類同秩：" + b.to_string())
  sb.write_string("、K₁ det 分量：" + c.to_string())
  @galois.Check::make(
    "T70",
    "T70 自由同倫不變性（K₀ 秩、K₁ det）",
    a && b && c,
    sb.to_string(),
  )
}

///|
/// **T71（負控制）**：①A² ≠ 0 時 e_t 不再是冪等元；②不同秩不可能同倫（跡是不變量）。
pub fn check_homotopy_negative_controls() -> @galois.Check {
  let a = check_idem_path_negative()
  let b = check_homotopy_negative()
  @galois.Check::make(
    "T71",
    "T71 負控制：A²=0 不可省、不同秩不同類",
    a && b,
    "冪等性失效=" + a.to_string() + "、秩不變量=" + b.to_string(),
  )
}

// ---------------------------------------------------------------- 報告

///|
/// 全部檢核（T64–T72）。
pub fn analytic_report() -> @galois.Report {
  let r = @galois.Report::new()
  r.add(check_approx_identity())
  r.add(check_approx_negative())
  r.add(check_projection_k0())
  r.add(check_mvn())
  r.add(check_noncommutative())
  r.add(check_idempotent_homotopy())
  r.add(check_projection_homotopy())
  r.add(check_homotopy_negative_controls())
  r.add(check_rank_cross())
  r
}

///|
/// 結構表（供 `moon run cmd/main -- analytic`）。
pub fn analytic_table_render() -> String {
  let sb = StringBuilder()
  sb.write_string("近似單位元 e_n = diag(1…1,0…0)（N = 5）\n")
  for n = 0; n < 5; n = n + 1 {
    sb.write_string(
      "  n=" +
      n.to_string() +
      "：‖e_nS − S‖₂² = " +
      approx_conv_shift_sq(n, 5).to_string() +
      "、‖(1−e_n)P₂‖₂² = " +
      approx_rest_sq(n, 2, 5).to_string() +
      "\n",
    )
  }
  sb.write_string(
    "非交換投影 p = E₁₁、q = [[9/25,12/25],[12/25,16/25]]：\n",
  )
  sb.write_string(
    "  cos²θ = tr(pq) = " +
    rat_to_string(rmat_trace(rmat_mul(proj_e11(), proj_angled()))) +
    "\n",
  )
  sb.write_string(
    "  ‖pq − qp‖₂² = " +
    rat_to_string(
      rmat_norm2(
        rmat_sub(
          rmat_mul(proj_e11(), proj_angled()),
          rmat_mul(proj_angled(), proj_e11()),
        ),
      ),
    ) +
    "\n",
  )
  sb.write_string("同倫族（冪等元，A²=0）：")
  for t in [rat_of_int(0L), rat_of_int(1L), rat_of_int(2L)] {
    sb.write_string(
      "[" + rmat_to_string(idem_path(idem_sample(), nilpotent_12(), t)) + "] ",
    )
  }
  sb.write_string("\n")
  sb.to_string()
}
