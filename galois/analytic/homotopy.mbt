///|
/// B0009 / analytic 套件：**自由同倫不變性**（free homotopy invariance）。
///
/// 「自由同倫」= 不固定基點的同倫。對 K-理論而言它給出兩件事：
///   * **K₀**：冪等元空間的路徑連通分量（同倫類）由秩決定；
///   * **K₁**：么正群的路徑連通分量由行列式（在 S¹ 上的繞數）決定。
/// 兩者在本套件都以**多項式族**實現（參數 t ∈ ℚ），因此整條路徑可精確驗證。
///
/// 核心族：冪等元 e ↦ e_t = (1 + tA)·e·(1 − tA)，只要 A² = 0 就是冪等元族
/// （(1 − tA)(1 + tA) = 1 − t²A² = 1），且秩沿族不變。
/// 投影族：p ↦ u_t p u_tᵀ，u_t = (1 − tA)(1 + tA)⁻¹ 為正交（A 反對稱），
/// 於是 p_t 全程是投影、秩不變——這是 K₀ 同倫不變性的顯式見證。

// ---------------------------------------------------------------- 冪等元族

///|
/// 反對稱矩陣（Cayley 型正交陣的來源；注意 A² = −1 ≠ 0，故不能用在冪等元族）。
pub fn antisym_12() -> RMat {
  rmat_of_int([[0L, 1L], [-1L, 0L]])
}

///|
/// 冪零矩陣 A² = 0（冪等元族的正確輸入）：A = [[0,1],[0,0]]。
pub fn nilpotent_12() -> RMat {
  rmat_of_int([[0L, 1L], [0L, 0L]])
}

///|
/// 冪等元（非投影）樣本：e = [[1,1],[0,0]]。
pub fn idem_sample() -> RMat {
  rmat_of_int([[1L, 1L], [0L, 0L]])
}

///|
/// 族 e_t = (1 + tA)·e·(1 − tA)。
pub fn idem_path(e : RMat, a : RMat, t : Rat) -> RMat {
  let n = e.rows
  let at = rmat_scale(a, t)
  let left = rmat_add(rmat_id(n), at)
  let right = rmat_sub(rmat_id(n), at)
  rmat_mul(rmat_mul(left, e), right)
}

///|
/// A² = 0 的判準。
pub fn square_zero(a : RMat) -> Bool {
  rmat_is_zero(rmat_mul(a, a))
}

///|
/// **H1（冪等元同倫）**：若 A² = 0，則 e_t 對所有 t ∈ ℚ 都是冪等元，且 rank(e_t) = rank(e)。
pub fn check_idem_path(e : RMat, a : RMat, ts : Array[Rat]) -> Bool {
  if !square_zero(a) {
    return false
  }
  let mut ok = true
  let r0 = rmat_rank(e)
  for t in ts {
    let et = idem_path(e, a, t)
    if !rmat_eq(rmat_mul(et, et), et) {
      ok = false
    }
    if rmat_rank(et) != r0 {
      ok = false
    }
  }
  ok
}

///|
/// **H1b（負控制）**：把 A² = 0 的假設拿掉，e_t 立刻不再是冪等元
/// （取 A = [[1,0],[0,0]]，A² = A ≠ 0）。這說明 H1 的假設是實質的。
pub fn check_idem_path_negative() -> Bool {
  let e = idem_sample()
  let a = rmat_of_int([[1L, 0L], [0L, 0L]])
  if square_zero(a) {
    return false
  }
  let et = idem_path(e, a, rat_new(1L, 2L))
  !rmat_eq(rmat_mul(et, et), et)
}

// ---------------------------------------------------------------- 投影族

///|
/// Cayley 型正交陣：A 反對稱 ⇒ u_t = (1 − tA)(1 + tA)⁻¹ 正交（t ∈ ℚ）。
pub fn cayley_orth(a : RMat, t : Rat) -> RMat {
  let n = a.rows
  let at = rmat_scale(a, t)
  rmat_mul(rmat_sub(rmat_id(n), at), rmat_inv(rmat_add(rmat_id(n), at)))
}

///|
/// **H2（投影同倫）**：A 反對稱 ⇒ u_t 正交、p_t = u_t p u_tᵀ 是投影、rank 不變、
/// 且 det(u_t) 在樣本點上恆定（K₁ 的同倫不變量）。
pub fn check_projection_path(p : RMat, a : RMat, ts : Array[Rat]) -> Bool {
  let mut ok = true
  let n = p.rows
  let r0 = rmat_rank(p)
  let d0 = rmat_det(cayley_orth(a, rat_of_int(0L)))
  for t in ts {
    let u = cayley_orth(a, t)
    // 正交：u uᵀ = 1
    if !rmat_eq(rmat_mul(u, rmat_transpose(u)), rmat_id(n)) {
      ok = false
    }
    let pt = rmat_conj(u, p)
    if !is_projection(pt) {
      ok = false
    }
    if rmat_rank(pt) != r0 {
      ok = false
    }
    if !rat_eq(rmat_det(u), d0) {
      ok = false
    }
  }
  ok
}

///|
/// H2 的推論：路徑的兩端 p_{t₀} 與 p_{t₁} 在 K₀ 上同類（秩相同），
/// 但可以是**不同的**投影——「同倫類 ≅ 秩」。
pub fn check_projection_path_endpoints() -> Bool {
  let p = proj_e11()
  let a = antisym_12()
  let p0 = rmat_conj(cayley_orth(a, rat_of_int(0L)), p)
  let p3 = rmat_conj(cayley_orth(a, rat_of_int(3L)), p)
  let same_class = rmat_rank(p0) == rmat_rank(p3)
  let different = !rmat_eq(p0, p3)
  same_class && different
}

// ---------------------------------------------------------------- 負控制

///|
/// **H3（負控制）**：不同秩的投影在 K₀ 上不同類，也不可能有冪等元路徑相連
/// （秩在冪等元簇上局部常數）。以跡給出不可能的證明：
/// tr(p) = rank 是不變量，故 1 ≠ 2。
pub fn check_homotopy_negative() -> Bool {
  let p = diag_proj(1, 3)
  let q = diag_proj(2, 3)
  let traces_differ = !rat_eq(rmat_trace(p), rmat_trace(q))
  // 任何冪等元路徑的秩都不變，故 rank(p) ≠ rank(q) ⇒ 不同類
  let ranks_differ = rmat_rank(p) != rmat_rank(q)
  traces_differ && ranks_differ
}

///|
/// **H4（自由 vs 定點）**：K₁ 的同倫不變量是 det；對本樣本（正交 2×2）det ∈ {±1}，
/// 兩條路徑 u_t（A = antisym_12）與 u_t² 的 det 分別是 1 與 1，
/// 但 v_t = diag(1,−1) 型（det = −1）與它們不同類——正交群的連通分量由 det 區分。
pub fn check_k1_det_invariant() -> Bool {
  let a = antisym_12()
  let u1 = cayley_orth(a, rat_of_int(1L))
  let flip = rmat_of_int([[-1L, 0L], [0L, 1L]])
  let det_u1 = rmat_det(u1)
  let det_flip = rmat_det(flip)
  // det(u1) = 1（旋轉）；det(flip) = −1（反射）⇒ 不同連通分量
  det_u1.num == 1L &&
  det_u1.den == 1L &&
  det_flip.num == -1L &&
  det_flip.den == 1L
}
