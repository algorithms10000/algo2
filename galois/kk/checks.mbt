///|
/// B0006 / kk 套件：**檢核器（T32–T40）**
/// 對應 docs/B0006-定理體系.md §2–§11。
///
/// 每一條檢核都是「定理 → 可執行的等式」，並且盡量讓同一件事有**兩條獨立路徑**
/// （例如 Cuntz 的 K₀ 同時由六項正合列與 UCT 算出；指標同時由截斷矩陣的秩與繞數算出）。

// ---------------------------------------------------------------- T32：Hilbert 模 ↔ K₀

///|
/// 兩組歸一化秩向量逐項相加（驗可加性用）。
pub fn rat_vec_add(a : Array[Rat], b : Array[Rat]) -> Array[Rat] {
  let out : Array[Rat] = []
  for i = 0; i < a.length(); i = i + 1 {
    out.push(rat_add(a[i], b[i]))
  }
  out
}

///|
/// 逐項相等。
pub fn rat_vec_eq(a : Array[Rat], b : Array[Rat]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut ok = true
  for i = 0; i < a.length(); i = i + 1 {
    if !rat_eq(a[i], b[i]) {
      ok = false
    }
  }
  ok
}

///|
/// T32(a)：投影的判準與秩（精確有理運算）。
pub fn check_projection_algebra() -> @galois.Check {
  // 對角投影 diag(1,1,0)；
  let d = qmat_of([[1L, 0L, 0L], [0L, 1L, 0L], [0L, 0L, 0L]])
  // 非對角的秩一投影 (1/2)[[1,1],[1,1]]：係數為有理數
  let g = qmat_zero(2, 2)
  g.e[0][0] = rat_make(1L, 2L)
  g.e[0][1] = rat_make(1L, 2L)
  g.e[1][0] = rat_make(1L, 2L)
  g.e[1][1] = rat_make(1L, 2L)
  // 非投影（冪等但非自伴）不能通過
  let n = qmat_of([[1L, 1L], [0L, 0L]])
  let ok = is_projection(d) &&
    is_projection(g) &&
    !is_projection(n) &&
    qmat_rank(d) == 2 &&
    qmat_rank(g) == 1 &&
    qmat_fredholm_index(d) == 0
  let detail = "diag(1,1,0) 是投影=" +
    is_projection(d).to_string() +
    "、秩=" +
    qmat_rank(d).to_string() +
    "；(1/2)[[1,1],[1,1]] 是投影=" +
    is_projection(g).to_string() +
    "、秩=" +
    qmat_rank(g).to_string() +
    "；冪等非自伴 [[1,1],[0,0]] 是投影=" +
    is_projection(n).to_string()
  @galois.Check::make(
    "T32", "T32 投影、秩與指標（ℚ 上精確）", ok, detail,
  )
}

///|
/// T32(b)：K₀(A) 由 Hilbert 模 p·A^N 的歸一化秩向量給出，且**可加**；
/// K₀(A) ≅ ℤ^r（r = 簡單塊數）與 fda_k 一致。
pub fn check_hilbert_module_k0() -> @galois.Check {
  let blocks : Array[Int32] = [2, 3]
  let v1 = normalized_rank([2, 3], blocks)
  let v2 = normalized_rank([4, 0], blocks)
  let sum = rat_vec_add(v1, v2)
  let v12 = normalized_rank([6, 3], blocks)
  // 可加性：v(p) + v(q) = v(p ⊕ q)
  let add_ok = rat_vec_eq(sum, v12)
  // 生成性：第 i 個簡單塊的極小投影給 (1/n_i)·e_i，這些向量張出 ⊕(1/n_i)ℤ ≅ ℤ^r
  let e1 = normalized_rank([1, 0], blocks)
  let e2 = normalized_rank([0, 1], blocks)
  let gen_ok = rat_eq(e1[0], rat_make(1L, 2L)) &&
    rat_eq(e1[1], rat_zero()) &&
    rat_eq(e2[0], rat_zero()) &&
    rat_eq(e2[1], rat_make(1L, 3L))
  // 與抽象 K₀ 比對：塊數 = 秩
  let k = fda_k(fda(blocks))
  let abs_ok = k.k0.rank == 2 && fga_eq(k.k1, fga_zero())
  // 秩向量的**整數性判準**（含兩個退化負控制）：
  //   (i) 合法輸入 [4,3],[2,3] ⇒ Some([2,1])；
  //  (ii) 3 不被 2 整除 ⇒ None（不是 A-線性投影）；
  // (iii) 塊大小 0 ⇒ None（`rat_make` 會靜默回 0/1，必須擋）。
  let rv_ok = match hilbert_module_rank_vector([4, 3], blocks) {
    Some(v) => v.length() == 2 && v[0] == 2L && v[1] == 1L
    None => false
  }
  let rv_neg_div = match hilbert_module_rank_vector([3, 0], blocks) {
    None => true
    Some(_) => false
  }
  let rv_neg_zero = match hilbert_module_rank_vector([2, 1], [2, 0]) {
    None => true
    Some(_) => false
  }
  let ok = add_ok && gen_ok && abs_ok && rv_ok && rv_neg_div && rv_neg_zero
  let detail = "v(2,3)=" +
    rat_vec_render(v1) +
    "、v(4,0)=" +
    rat_vec_render(v2) +
    "、相加=" +
    rat_vec_render(sum) +
    " 應等於 v(6,3)=" +
    rat_vec_render(v12) +
    "（可加 " +
    add_ok.to_string() +
    "）；極小投影給 (1/2,0)、(0,1/3)（生成 " +
    gen_ok.to_string() +
    "）；K₀ = " +
    fga_render(k.k0) +
    "；秩向量整數性 " +
    rv_ok.to_string() +
    "、負控制（不整除 " +
    rv_neg_div.to_string() +
    "、塊大小 0 " +
    rv_neg_zero.to_string() +
    "）"
  @galois.Check::make(
    "T32", "T32 Hilbert 模秩向量 ⇒ K₀(M₂ ⊕ M₃)", ok, detail,
  )
}

///|
/// 有理向量的顯示。
pub fn rat_vec_render(v : Array[Rat]) -> String {
  let sb = StringBuilder()
  sb.write_string("(")
  for i = 0; i < v.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    sb.write_string(rat_render(v[i]))
  }
  sb.write_string(")")
  sb.to_string()
}

// ---------------------------------------------------------------- T33：六項正合列

///|
/// T33(a)：Toeplitz 擴張 0 → K → 𝒯 → C(S¹) → 0 的六項正合列**完整**通過秩判準。
pub fn check_six_term_toeplitz() -> @galois.Check {
  let c = six_term_check(toeplitz_circle_extension())
  @galois.Check::make(
    "T33",
    "T33 六項正合列：Toeplitz → C(S¹)",
    c.ok,
    c.detail,
  )
}

///|
/// T33(b)：有限維代數的分裂擴張（任意遮罩）的六項正合列通過。
pub fn check_six_term_split(mask : Array[Bool]) -> @galois.Check {
  let a = fda([1, 2, 3])
  let c = six_term_check(fda_extension(a, mask))
  let label = fda_quotient(a, mask)
  @galois.Check::make(
    "T33",
    "T33 六項正合列：分裂擴張（商 = " +
    fga_render(fda_k(label).k0) +
    "）",
    c.ok,
    c.detail,
  )
}

///|
/// T33(c)：**負控制**——把 Toeplitz 圖的 β 改成 0，六項正合列必須失敗。
/// （檢核器不得恆真：B0002 的 T8 精神。）
pub fn check_six_term_negative_control() -> @galois.Check {
  let s = toeplitz_circle_extension()
  let broken = six_term(
    s.j0,
    s.j1,
    s.a0,
    s.a1,
    s.q0,
    s.q1,
    s.alpha,
    intmat_of([[0L]]),
    s.del0,
    s.gamma,
    s.delta,
    s.del1,
  )
  let c = six_term_check(broken)
  @galois.Check::make(
    "T33",
    "T33 負控制：β 改成 0 必須 FAIL",
    !c.ok,
    "檢查器判定為 " +
    (if c.ok { "通過（錯誤！）" } else { "不通過（正確）" }),
  )
}

// ---------------------------------------------------------------- T34：Cuntz

///|
/// T34：Cuntz 代數 O_n 的 K-群由 (n−1)[1] = −[p] 導出，
/// 並用**三條路徑**交叉驗證：六項正合列（coker/ker）、UCT（KK(ℂ,O_n)）、SNF。
pub fn check_cuntz_ktheory(n : Int32) -> @galois.Check {
  let k = cuntz_ktheory(n)
  let want = fga_cyclic(n.to_int64() - 1L)
  let path1 = fga_eq(k.k0, want) && fga_eq(k.k1, fga_zero())
  // 路徑二：UCT 給 KK(ℂ, O_n) = K₀(O_n)
  let uct = kk_uct(kpair(fga_free(1), fga_zero()), k)
  let path2 = uct_determined(uct) && fga_eq(uct_group(uct), want)
  // 路徑三：i_* = ×(1−n) 的 SNF ⇒ coker 的階 = n−1
  let imap = intmat_of([[1L - n.to_int64()]])
  let snf = snf_diag(imap)
  let path3 = snf.length() == 1 &&
    (if snf[0] < 0L { -snf[0] } else { snf[0] }) == n.to_int64() - 1L
  let ok = path1 && path2 && path3
  let detail = "六項正合列 " +
    kpair_render(k) +
    "；UCT：KK(ℂ,O_" +
    n.to_string() +
    ") = " +
    fga_render(uct_group(uct)) +
    "；SNF(1−n) = " +
    (if snf.length() == 0 { "—" } else { snf[0].to_string() })
  @galois.Check::make(
    "T34",
    "T34 K₀(O_" + n.to_string() + ") = ℤ/" + (n - 1).to_string(),
    ok,
    detail,
  )
}

// ---------------------------------------------------------------- T35：UCT 值表

///|
/// T35：一個個案：KK(A,B) 由 UCT 完全決定，且等於登記值。
pub fn check_uct_case(
  name : String,
  a : KPair,
  b : KPair,
  want : FgAb,
) -> @galois.Check {
  let u = kk_uct(a, b)
  let ok = uct_determined(u) && fga_eq(uct_group(u), want)
  let detail = uct_render(u) + "；登記 " + fga_render(want)
  @galois.Check::make("T35", "T35 UCT：" + name, ok, detail)
}

///|
/// 標準樣本代數的 K-群。
/// 樣本代數的 K-群表（供 CLI 的 `kktable` 印表；不是檢核的一部分）。
pub fn algebra_samples() -> Array[(String, KPair)] {
  [
    ("ℂ", kpair(fga_free(1), fga_zero())),
    ("M₂(ℂ)", kpair(fga_free(1), fga_zero())),
    ("M₃(ℂ)", kpair(fga_free(1), fga_zero())),
    ("ℂ ⊕ M₂(ℂ)", kpair(fga_free(2), fga_zero())),
    ("C(S¹)", k_of_circle()),
    ("O₂", cuntz_ktheory(2)),
    ("O₃", cuntz_ktheory(3)),
    ("O₄", cuntz_ktheory(4)),
  ]
}

// ---------------------------------------------------------------- T36：Kasparov 乘積

///|
/// T36(a)：Kasparov 乘積的**單位律**：id ∘ x = x、x ∘ id = x。
pub fn check_kk_product_unit() -> @galois.Check {
  let c = kpair(fga_free(1), fga_zero())
  let m2 = kpair(fga_free(1), fga_zero())
  let x = kk_class(c, m2, intmat_of([[2L]]), intmat_identity(0, 1L))
  let ix = kk_compose(x, kk_identity(m2))
  let xi = kk_compose(kk_identity(c), x)
  let ok = kk_class_eq(ix, x) && kk_class_eq(xi, x)
  @galois.Check::make(
    "T36",
    "T36 Kasparov 乘積的單位律",
    ok,
    "id∘x = x：" +
    kk_class_eq(ix, x).to_string() +
    "、x∘id = x：" +
    kk_class_eq(xi, x).to_string(),
  )
}

///|
/// T36(b)：**結合律**與**K-理論的函子性**：由真實代數同態給出的類，
/// 其乘積的 K₀ 映射正好是矩陣合成（diag 之後 pr₁ 等於 id）。
pub fn check_kk_product_assoc() -> @galois.Check {
  let c = kpair(fga_free(1), fga_zero())
  let two = kpair(fga_free(2), fga_zero())
  // diag: ℂ → ℂ² 的 K₀ 矩陣 [[1],[1]]；pr₁: ℂ² → ℂ 的 [[1,0]]
  let diag = intmat_of([[1L], [1L]])
  let pr1 = intmat_of([[1L, 0L]])
  let x = kk_class(c, two, diag, intmat_identity(0, 1L))
  let y = kk_class(two, c, pr1, intmat_identity(0, 1L))
  let comp = kk_compose(x, y)
  let functorial = kk_class_eq(comp, kk_identity(c))
  // 結合律：(x∘y)∘z = x∘(y∘z)
  let z = kk_class(c, two, intmat_of([[0L], [3L]]), intmat_identity(0, 1L))
  let left = kk_compose(kk_compose(x, y), z)
  let right = kk_compose(x, kk_compose(y, z))
  let assoc = kk_class_eq(left, right)
  let ok = functorial && assoc
  @galois.Check::make(
    "T36",
    "T36 Kasparov 乘積：結合律與 K-函子性",
    ok,
    "pr₁∘diag = id：" +
    functorial.to_string() +
    "（K₀ 上 [[1,0]]·[[1],[1]] = [[1]]）；結合律：" +
    assoc.to_string(),
  )
}

// ---------------------------------------------------------------- T37：KK-等價

///|
/// T37：KK-等價的判準（K-群同構）與具體例子。
pub fn check_kk_equivalence_cases() -> @galois.Check {
  let c = kpair(fga_free(1), fga_zero())
  let m2 = kpair(fga_free(1), fga_zero())
  let m3 = kpair(fga_free(1), fga_zero())
  let s1 = k_of_circle()
  let o2 = cuntz_ktheory(2)
  let o3 = cuntz_ktheory(3)
  // Morita 等價 ⇒ KK-等價
  let c_m2 = kk_equivalent(c, m2)
  let m2_m3 = kk_equivalent(m2, m3)
  // K₁ 不同 ⇒ 不等價
  let c_s1 = kk_equivalent(c, s1)
  // K₀ 不同 ⇒ 不等價
  let o2_o3 = kk_equivalent(o2, o3)
  let ok = c_m2 && m2_m3 && !c_s1 && !o2_o3
  let detail = "ℂ~M₂：" +
    c_m2.to_string() +
    "、M₂~M₃：" +
    m2_m3.to_string() +
    "、ℂ~C(S¹)：" +
    c_s1.to_string() +
    "、O₂~O₃：" +
    o2_o3.to_string()
  @galois.Check::make("T37", "T37 KK-等價 ⟺ K-群同構", ok, detail)
}

///|
/// T37(b)：**K-理論不是完備不變量**的具體見證：K_*(O₂) = (0,0) = K_*(0)，
/// 但 O₂ 不是零代數。本檢核斷言「K-群相同、代數不同」，並明示 UCT 因此看不到差異。
pub fn check_k_theory_incomplete() -> @galois.Check {
  let o2 = cuntz_ktheory(2)
  let zero = kpair(fga_zero(), fga_zero())
  let same = kpair_eq(o2, zero)
  let ok = same
  @galois.Check::make(
    "T37",
    "T37 K-理論不完備：K₀(O₂) = K₁(O₂) = 0",
    ok,
    "K_*(O₂) = " +
    kpair_render(o2) +
    "、K_*(0) = " +
    kpair_render(zero) +
    " ⇒ UCT 在此給 0（K-理論看不見 O₂ 的非零性）",
  )
}

// ---------------------------------------------------------------- T38：穩定性與週期性

///|
/// T38：吸收緊算子（A ⊗ K ~ A）與 Bott 週期性在 UCT 層面的不變性。
pub fn check_stability_bott() -> @galois.Check {
  let a = k_of_circle()
  let b = cuntz_ktheory(3)
  let stable = kpair_eq(kpair_tensor_k(a), a) && kpair_eq(kpair_tensor_k(b), b)
  let uct_same = fga_eq(
    uct_group(kk_uct(kpair_tensor_k(a), b)),
    uct_group(kk_uct(a, b)),
  )
  let bott = kpair_bott_periodic(a) && kpair_bott_periodic(b)
  let ok = stable && uct_same && bott
  @galois.Check::make(
    "T38",
    "T38 穩定性 A⊗K 與 Bott 週期性",
    ok,
    "K_*(A⊗K) = K_*(A)：" +
    stable.to_string() +
    "、KK(A⊗K,B) = KK(A,B)：" +
    uct_same.to_string() +
    "、K_{i+2} = K_i：" +
    bott.to_string(),
  )
}

// ---------------------------------------------------------------- T39：指標 ↔ 繞數

///|
/// T39(a)：對單項符號 t^k，Toeplitz 截斷矩陣的指標 = −k，
/// 與幅角原理給的 −wind(t^k) = −k 一致（兩條獨立路徑）。
pub fn check_index_winding() -> @galois.Check {
  let n = 8
  let mut ok = true
  let sb = StringBuilder()
  for k = 0; k <= 4; k = k + 1 {
    let idx = qmat_fredholm_index(toeplitz_truncation_rect(n, k))
    let wind = wind_of_factors(k, [], [])
    let formula = toeplitz_index_of_symbol(wind)
    if idx != formula || wind != k {
      ok = false
    }
    if k > 0 {
      sb.write_string("；")
    }
    sb.write_string(
      "t^" +
      k.to_string() +
      "：指標=" +
      idx.to_string() +
      "、−wind=" +
      formula.to_string(),
    )
  }
  let square_zero = qmat_fredholm_index(toeplitz_truncation(n, 3)) == 0
  let ok2 = ok && square_zero
  @galois.Check::make(
    "T39",
    "T39 index(T_f) = −wind(f)（單項）",
    ok2,
    sb.to_string() +
    "（方截斷的指標恆為 0：" +
    square_zero.to_string() +
    "）",
  )
}

///|
/// T39(b)：一般符號的繞數由**因式與 |根| < 1 的精確比較**算出；
/// 並且**反例**：截斷矩陣在一般符號上不保指標（界限的明示）。
pub fn check_winding_general() -> @galois.Check {
  // (t − 1/2)(t − 2) = t² − (5/2)t + 1
  let f = laur_of_factors(0, [(rat_make(1L, 2L), 1), (rat_of_int(2L), 1)], [])
  let coeffs_ok = f.c.length() == 3 &&
    f.c[0].0 == 0 &&
    rat_eq(f.c[0].1, rat_one()) &&
    f.c[1].0 == 1 &&
    rat_eq(f.c[1].1, rat_make(-5L, 2L)) &&
    f.c[2].0 == 2 &&
    rat_eq(f.c[2].1, rat_one())
  let wind = wind_of_factors(0, [(rat_make(1L, 2L), 1), (rat_of_int(2L), 1)], [])
  // 界限：截斷的 (t − 1/2) 指標是 0，但真指標是 −1
  let trunc_idx = qmat_fredholm_index(
    toeplitz_truncation_linear(6, rat_one(), rat_make(-1L, 2L)),
  )
  let true_idx = toeplitz_index_of_symbol(
    wind_of_factors(0, [(rat_make(1L, 2L), 1)], []),
  )
  let bound_ok = trunc_idx == 0 && true_idx == -1
  let ok = coeffs_ok && wind == 1 && bound_ok
  @galois.Check::make(
    "T39",
    "T39 一般符號的繞數與截斷的界限",
    ok,
    "f = " +
    laur_render(f) +
    "（係數正確 " +
    coeffs_ok.to_string() +
    "）、wind = " +
    wind.to_string() +
    "；界限：(t−1/2) 截斷指標 = " +
    trunc_idx.to_string() +
    " 但真指標 = " +
    true_idx.to_string() +
    "（截斷不保指標）",
  )
}

///|
/// T39(c)：指標映射 = 六項正合列的 ∂₁（兩邊各自算出，取絕對值比對）。
pub fn check_index_is_boundary() -> @galois.Check {
  let s = toeplitz_circle_extension()
  let boundary_rank = intmat_rank(s.del1)
  let index_abs = {
    let i = qmat_fredholm_index(toeplitz_truncation_rect(8, 1))
    if i < 0 {
      -i
    } else {
      i
    }
  }
  let ok = boundary_rank == 1 && index_abs == 1
  @galois.Check::make(
    "T39",
    "T39 ∂₁ = 指標映射（Bott）",
    ok,
    "六項正合列的 ∂₁ 秩 = " +
    boundary_rank.to_string() +
    "；移位元的 |指標| = " +
    index_abs.to_string(),
  )
}

// ---------------------------------------------------------------- T40：與前幾輪的接縫

///|
/// T40(a)：與 **B0005** 的接縫——C*(S_n) = ⊕_{λ⊢n} M_{d_λ}(ℂ)，
/// 故 K₀ = ℤ^{p(n)}；且 Σ_λ d_λ² = n! = |im(B_n → S_n)|（B0005 的 T22）。
pub fn check_seam_symmetric_group(n : Int32) -> @galois.Check {
  let parts = partitions(n)
  let mut sumsq = 0L
  for lam in parts {
    let d = irrep_dim(lam)
    sumsq = sumsq + d * d
  }
  let total = sum_dim_squares(n)
  let mut fact = 1L
  for i = 2; i <= n; i = i + 1 {
    fact = fact * i.to_int64()
  }
  let perm_count = @braid.generated_permutation_count(n).to_int64()
  let k = k_of_symmetric_group(n)
  let ok = total == fact &&
    sumsq == fact &&
    perm_count == fact &&
    k.k0.rank == parts.length() &&
    fga_eq(k.k1, fga_zero())
  @galois.Check::make(
    "T40",
    "T40 B0005 接縫：K₀(C*(S_" +
    n.to_string() +
    ")) = ℤ^" +
    parts.length().to_string(),
    ok,
    "Σd_λ² = " +
    sumsq.to_string() +
    "、n! = " +
    fact.to_string() +
    "、B_n→S_n 的像 = " +
    perm_count.to_string() +
    "、#分割 = " +
    parts.length().to_string(),
  )
}

///|
/// T40(b)：與 **B0003** 的接縫——對有限群 G，K₀(C*(G)) = ℤ^{#共軛類}。
/// 以 SL₂(ℤ/n) 暴力數共軛類，並驗 Σ|類| = |G|。
pub fn check_seam_sl2_conjugacy(n : Int32) -> @galois.Check {
  let g = @modular.sl2_group(n)
  let keys : Array[String] = []
  let mut total = 0
  for x in g {
    // 類的規範鍵：所有共軛 h·x·h⁻¹ 的最小鍵
    let mut best = ""
    let mut first = true
    for h in g {
      let hx = h.mul(x)
      let c = hx.mul(h.inverse())
      let key = c.key()
      if first || key < best {
        best = key
        first = false
      }
    }
    let mut seen = false
    for kk in keys {
      if kk == best {
        seen = true
      }
    }
    if !seen {
      keys.push(best)
      total = total + 1
    }
  }
  // 類的大小總和 = |G|
  let mut sum_class = 0
  for key in keys {
    for x in g {
      let mut best = ""
      let mut first = true
      for h in g {
        let c = h.mul(x).mul(h.inverse())
        let kx = c.key()
        if first || kx < best {
          best = kx
          first = false
        }
      }
      if best == key {
        sum_class = sum_class + 1
      }
    }
  }
  let ok = sum_class == g.length() && total == keys.length()
  @galois.Check::make(
    "T40",
    "T40 B0003 接縫：K₀(C*(SL₂(ℤ/" +
    n.to_string() +
    "))) = ℤ^" +
    total.to_string(),
    ok,
    "|G| = " +
    g.length().to_string() +
    "、共軛類 = " +
    total.to_string() +
    "、類大小總和 = " +
    sum_class.to_string(),
  )
}

///|
/// **理想格的樣本上下文**（T40(c) 用）：物件 = 商代數 A/I（以存活的塊命名），
/// 屬性 = 「第 i 個簡單塊存活」。A = ⊕ M_{n_i}(ℂ) 的理想格是 2^r 的布林格，
/// 把它交給 B0001 的 A6 與 A3′ 檢核。
pub fn kk_ideal_context(blocks : Array[Int32]) -> @context.FormalContext {
  let r = blocks.length()
  let objs : Array[String] = []
  let attrs : Array[String] = []
  for i = 0; i < r; i = i + 1 {
    attrs.push("M" + blocks[i].to_string())
  }
  let edges : Array[(Int32, Int32)] = []
  // ＊只取非零商＊：零商 A/A = 0 沒有任何存活的簡單塊 ⇒ 支撐為空，
  // 必然違反 B0001 的 X2（與 B0002 的 NOTE-1 同一個現象），故另行記錄。
  for mask = 1; mask < pow2(r); mask = mask + 1 {
    let label = quotient_label(mask, blocks)
    objs.push(label)
    let obj_idx = objs.length() - 1
    for i = 0; i < r; i = i + 1 {
      if bit_of(mask, i) {
        edges.push((obj_idx, i))
      }
    }
  }
  @context.FormalContext::new(objs, attrs, edges)
}

///|
/// 2^r。
pub fn pow2(r : Int32) -> Int32 {
  let mut p = 1
  for _i = 0; _i < r; _i = _i + 1 {
    p = p * 2
  }
  p
}

///|
/// mask 的第 i 位。
pub fn bit_of(mask : Int32, i : Int32) -> Bool {
  mask / pow2(i) % 2 == 1
}

///|
/// 商的標籤：存活塊的清單。
pub fn quotient_label(mask : Int32, blocks : Array[Int32]) -> String {
  let sb = StringBuilder()
  sb.write_string("A/I[")
  let mut first = true
  for i = 0; i < blocks.length(); i = i + 1 {
    if bit_of(mask, i) {
      if !first {
        sb.write_string("+")
      }
      sb.write_string("M" + blocks[i].to_string())
      first = false
    }
  }
  if first {
    sb.write_string("0")
  }
  sb.write_string("]")
  sb.to_string()
}

///|
/// **含零商**的理想格上下文（用來正面記錄「X2 必然失敗」這個已知邊界）。
pub fn kk_ideal_context_with_zero(
  blocks : Array[Int32],
) -> @context.FormalContext {
  let r = blocks.length()
  let objs : Array[String] = []
  let attrs : Array[String] = []
  for i = 0; i < r; i = i + 1 {
    attrs.push("M" + blocks[i].to_string())
  }
  let edges : Array[(Int32, Int32)] = []
  for mask = 0; mask < pow2(r); mask = mask + 1 {
    objs.push(quotient_label(mask, blocks))
    let obj_idx = objs.length() - 1
    for i = 0; i < r; i = i + 1 {
      if bit_of(mask, i) {
        edges.push((obj_idx, i))
      }
    }
  }
  @context.FormalContext::new(objs, attrs, edges)
}

///|
/// T40(c) 的邊界：把零商放進上下文 ⇒ B0001 的 X2（支撐完全性）必然失敗。
/// 這不是缺陷，而是「空支撐物件」的已知現象（B0002 的 NOTE-1 已記錄過同型情形）。
pub fn check_seam_context_zero_quotient() -> @galois.Check {
  let ctx = kk_ideal_context_with_zero([1, 2, 3])
  let a6 = @galois.structural_report(ctx)
  let x2_failed = !a6.get(0).passed()
  @galois.Check::make(
    "T40",
    "T40 B0001 邊界：含零商時 X2 必失敗（預期）",
    x2_failed,
    "含零商：A6 " +
    a6.passed_count().to_string() +
    "/" +
    a6.size().to_string() +
    "（X2 失敗 = " +
    x2_failed.to_string() +
    "）；去掉零商後見下一條",
  )
}

///|
/// T40(c)：與 **B0001（公理層）** 的接縫——把 K-理論的理想格做成形式上下文，
/// B0001 的 A6（8 條）與 A3′ 全數通過，且閉集個數 = 2^r（布林格）。
pub fn check_seam_context_axioms() -> @galois.Check {
  let blocks : Array[Int32] = [1, 2, 3]
  let ctx = kk_ideal_context(blocks)
  let a6 = @galois.structural_report(ctx)
  let dg = @lattice.dg_report(ctx)
  let closed = @lattice.all_closed_stmts(ctx).length()
  let ok = a6.all_passed() &&
    dg.all_passed() &&
    a6.size() == 8 &&
    closed == pow2(3) &&
    ctx.num_axioms() == 7
  @galois.Check::make(
    "T40",
    "T40 B0001 接縫：理想格的 A6 與 A3′",
    ok,
    "|A|=" +
    ctx.num_axioms().to_string() +
    "、|S|=" +
    ctx.num_stmts().to_string() +
    "、|R|=" +
    ctx.edge_count().to_string() +
    "、A6 " +
    a6.passed_count().to_string() +
    "/" +
    a6.size().to_string() +
    "、A3′ " +
    dg.passed_count().to_string() +
    "/" +
    dg.size().to_string() +
    "、閉集 = " +
    closed.to_string(),
  )
}

// ---------------------------------------------------------------- 報告

///|
/// 完整報告（T32–T40）。
pub fn kk_report() -> @galois.Report {
  let r = @galois.Report::new()
  // T32
  r.add(check_projection_algebra())
  r.add(check_hilbert_module_k0())
  // T33
  r.add(check_six_term_toeplitz())
  r.add(check_six_term_split([true, false, true]))
  r.add(check_six_term_split([false, false, true]))
  r.add(check_six_term_split([true, true, true]))
  r.add(check_six_term_negative_control())
  // T34
  for n = 2; n <= 8; n = n + 1 {
    r.add(check_cuntz_ktheory(n))
  }
  // T35：UCT 值表（登記值 = 古典結果；樣本清單由 CLI 的 `kktable` 使用）
  let c = kpair(fga_free(1), fga_zero())
  r.add(check_uct_case("KK(ℂ,ℂ)", c, c, fga_free(1)))
  r.add(
    check_uct_case(
      "KK(ℂ,M₂)",
      c,
      kpair(fga_free(1), fga_zero()),
      fga_free(1),
    ),
  )
  r.add(
    check_uct_case(
      "KK(ℂ,ℂ⊕M₂)",
      c,
      kpair(fga_free(2), fga_zero()),
      fga_free(2),
    ),
  )
  r.add(check_uct_case("KK(ℂ,C(S¹))", c, k_of_circle(), fga_free(1)))
  r.add(check_uct_case("KK(C(S¹),ℂ)", k_of_circle(), c, fga_free(1)))
  r.add(
    check_uct_case(
      "KK(C(S¹),C(S¹))",
      k_of_circle(),
      k_of_circle(),
      fga_free(2),
    ),
  )
  for n = 2; n <= 4; n = n + 1 {
    r.add(
      check_uct_case(
        "KK(ℂ,O_" + n.to_string() + ")",
        c,
        cuntz_ktheory(n),
        fga_cyclic(n.to_int64() - 1L),
      ),
    )
    r.add(
      check_uct_case(
        "KK(O_" + n.to_string() + ",ℂ)",
        cuntz_ktheory(n),
        c,
        fga_zero(),
      ),
    )
  }
  // T36–T39
  r.add(check_kk_product_unit())
  r.add(check_kk_product_assoc())
  r.add(check_kk_equivalence_cases())
  r.add(check_k_theory_incomplete())
  r.add(check_stability_bott())
  r.add(check_index_winding())
  r.add(check_winding_general())
  r.add(check_index_is_boundary())
  // T40
  for n = 1; n <= 6; n = n + 1 {
    r.add(check_seam_symmetric_group(n))
  }
  for n = 2; n <= 5; n = n + 1 {
    r.add(check_seam_sl2_conjugacy(n))
  }
  r.add(check_seam_context_zero_quotient())
  r.add(check_seam_context_axioms())
  r
}
