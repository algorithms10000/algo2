///|
/// B0009 / analytic 套件：**近似單位元**（approximate identity）。
///
/// 非么 C*-代數 A 沒有 1，但有**近似單位元**：遞增的正收縮 {e_λ} 且 ‖e_λ a − a‖ → 0。
/// 有限維樣本上這件事完全可精算：取 A 的有限模型（K(ℓ²) 的截斷 M_N(ℚ)），
/// e_n = diag(1,…,1,0,…,0)（前 n 個 1），則對固定 a
///
///     ‖e_n a − a‖₂² 是**精確有理數**，且在某個 n 之後恰為 0。
///
/// 本檔案把「收斂」落成三條可反駁的等式（`approx_conv_shift_sq` 給出**閉式**），
/// 並附兩個負控制（么代數、非遞增族）。

///|
/// 有限模型：e_n = diag(1,…,1,0,…,0)（前 n 個 1），尺寸 N。
pub fn diag_proj(n : Int32, n_size : Int32) -> RMat {
  let m = rmat_zero(n_size, n_size)
  for i = 0; i < n && i < n_size; i = i + 1 {
    rmat_set(m, i, i, rat_of_int(1L))
  }
  m
}

///|
/// 有限模型：右移算子 S = Σ_{j=1}^{N−1} E_{j,j+1}（K(ℓ²) 的緊算子樣本）。
pub fn shift_matrix(n_size : Int32) -> RMat {
  let m = rmat_zero(n_size, n_size)
  for j = 0; j + 1 < n_size; j = j + 1 {
    rmat_set(m, j, j + 1, rat_of_int(1L))
  }
  m
}

///|
/// 是不是投影：p² = p 且 pᵀ = p。
pub fn is_projection(p : RMat) -> Bool {
  rmat_eq(rmat_mul(p, p), p) && rmat_eq(rmat_transpose(p), p)
}

///|
/// 投影的秩＝跡（定理 P1 的算式；回傳兩者是否相等）。
pub fn rank_equals_trace(p : RMat) -> Bool {
  rmat_rank(p).to_int64() == rmat_trace(p).num && rmat_trace(p).den == 1L
}

// ---------------------------------------------------------------- A1 遞增與正性

///|
/// **A1**：{e_n} 是遞增投影族——e_n 是投影、（e_{n+1} 壓縮 e_n）e_{n+1} e_n = e_n、
/// 且 0 ≤ e_n ≤ 1（由投影性與跡在 [0, N] 內給出）。
pub fn approx_increasing(top : Int32) -> Bool {
  let mut ok = true
  for n = 0; n < top; n = n + 1 {
    let e = diag_proj(n, top)
    let e2 = diag_proj(n + 1, top)
    if !is_projection(e) {
      ok = false
    }
    if !rmat_eq(rmat_mul(e2, e), e) || !rmat_eq(rmat_mul(e, e2), e) {
      ok = false
    }
  }
  ok
}

// ---------------------------------------------------------------- A2 收斂（閉式）

///|
/// **A2（閉式收斂）**：對右移算子 S，‖e_n S − S‖₂² = N − 1 − n（n = 0..N−1），
/// 恰在 n = N−1 時歸零。這是一條可反駁的等式（不是「觀察到在變小」）。
pub fn approx_conv_shift_sq(n : Int32, n_size : Int32) -> Int64 {
  let e = diag_proj(n, n_size)
  let s = shift_matrix(n_size)
  let diff = rmat_sub(rmat_mul(e, s), s)
  let v = rmat_norm2(diff)
  v.num / v.den
}

///|
/// A2 的檢核：n = 0..N−1 全部命中閉式 N − 1 − n，且 n = N−1 時為 0。
pub fn check_approx_conv_shift(n_size : Int32) -> Bool {
  let mut ok = true
  for n = 0; n < n_size; n = n + 1 {
    let want : Int64 = (n_size - 1 - n).to_int64()
    if approx_conv_shift_sq(n, n_size) != want {
      ok = false
    }
  }
  ok
}

///|
/// **A3**：對有限秩投影 P（取 rank r 的對角投影），‖e_n P − P‖₂² = 0 ⟺ n ≥ r。
pub fn check_approx_conv_projection(r : Int32, n_size : Int32) -> Bool {
  let p = diag_proj(r, n_size)
  let mut ok = true
  for n = 0; n < n_size; n = n + 1 {
    let e = diag_proj(n, n_size)
    let v = rmat_norm2(rmat_sub(rmat_mul(e, p), p))
    let zero = rat_is_zero(v)
    if n >= r && !zero {
      ok = false
    }
    if n < r && zero {
      ok = false
    }
  }
  ok
}

///|
/// **A4（負控制）**：在**么**代數上，同一個序列 {e_n} 不是近似單位元：
/// 對 a = 1 有 ‖e_n·1 − 1‖₂² = N − n，永不為 0（直到 n = N）。
/// 這說明「近似單位元存在」是非么代數的特徵現象，不是恆真。
pub fn approx_negative_unital(n_size : Int32) -> Bool {
  let mut ok = true
  for n = 0; n < n_size; n = n + 1 {
    let e = diag_proj(n, n_size)
    let one = rmat_id(n_size)
    let v = rmat_norm2(rmat_sub(rmat_mul(e, one), one))
    let want : Int64 = (n_size - n).to_int64()
    if v.num != want || v.den != 1L {
      ok = false
    }
  }
  ok
}

// ---------------------------------------------------------------- A5 與 K-理論的接縫

///|
/// **A5（壓縮穩定）**：對有限支撐的投影 p（秩一），e_n p e_n = p 對所有 n ≥ 1 成立，
/// 故壓縮映射 a ↦ e_n a e_n 在 K₀ 上是恆等；且未壓縮的「面積」
/// ‖(1 − e_n)p‖₂² = tr(p) − tr(e_n p) 精確可算。
pub fn check_approx_compress(n_size : Int32) -> Bool {
  let p = diag_proj(1, n_size)
  let mut ok = true
  for n = 1; n < n_size; n = n + 1 {
    let e = diag_proj(n, n_size)
    if !rmat_eq(rmat_mul(rmat_mul(e, p), e), p) {
      ok = false
    }
    let one_minus = rmat_sub(rmat_id(n_size), e)
    let rest = rmat_norm2(rmat_mul(one_minus, p))
    // tr(p) − tr(e_n p) = 1 − 1 = 0
    if !rat_is_zero(rest) {
      ok = false
    }
  }
  ok
}

///|
/// A5 的一般式：對秩 r 投影與 n ≤ r，‖(1 − e_n)p‖₂² = r − n（整數）。
pub fn approx_rest_sq(n : Int32, r : Int32, n_size : Int32) -> Int64 {
  let p = diag_proj(r, n_size)
  let e = diag_proj(n, n_size)
  let v = rmat_norm2(rmat_mul(rmat_sub(rmat_id(n_size), e), p))
  v.num / v.den
}

///|
/// A5 檢核：approx_rest_sq = max(r − n, 0)。
pub fn check_approx_rest(r : Int32, n_size : Int32) -> Bool {
  let mut ok = true
  for n = 0; n < n_size; n = n + 1 {
    let want : Int64 = if n < r { (r - n).to_int64() } else { 0L }
    if approx_rest_sq(n, r, n_size) != want {
      ok = false
    }
  }
  ok
}
