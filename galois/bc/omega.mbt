///|
/// B0010 / bc 套件：**A₄ 的組裝映射**——特徵表落在 ℤ[ω]（ω = e^{2πi/3}）而非 ℤ，
/// 因此需要把 ℤ[ω] 當成 2 維 ℚ-向量空間，秩才可精算。
///
/// 手法：a + bω ↦ 2×2 整數區塊 [[a, −b], [b, a − b]]（ω² = −1 − ω 的乘法矩陣），
/// 於是「ℤ[ω] 上的 r×r 矩陣滿秩（在 ℂ 上）」⇔「展開後的 2r×2r 整數矩陣秩 = 2r」。
/// 這讓 `@analytic.rmat_rank`（ℚ 高斯消去）與 `@cyclic.rank_q`（F_p 高斯）都能用。

///|
/// ℤ[ω] 的元素 a + bω，ω² + ω + 1 = 0。
pub struct OmegaVal {
  a : Int64
  b : Int64
}

///|
/// 建構。
pub fn omega(a : Int64, b : Int64) -> OmegaVal {
  { a, b, }
}

///|
/// 0、1、ω。
pub fn omega_zero() -> OmegaVal {
  { a: 0L, b: 0L, }
}

///|
/// 1。
pub fn omega_one() -> OmegaVal {
  { a: 1L, b: 0L, }
}

///|
/// ω。
pub fn omega_gen() -> OmegaVal {
  { a: 0L, b: 1L, }
}

///|
/// 加法。
pub fn omega_add(x : OmegaVal, y : OmegaVal) -> OmegaVal {
  { a: x.a + y.a, b: x.b + y.b, }
}

///|
/// 乘法：ω² = −1 − ω。
pub fn omega_mul(x : OmegaVal, y : OmegaVal) -> OmegaVal {
  // (a + bω)(c + dω) = ac + (ad + bc)ω + bd·ω² = (ac − bd) + (ad + bc − bd)ω
  { a: x.a * y.a - x.b * y.b, b: x.a * y.b + x.b * y.a - x.b * y.b, }
}

///|
/// 共軛：ω ↦ ω̄ = ω² = −1 − ω。
pub fn omega_conj(x : OmegaVal) -> OmegaVal {
  { a: x.a - x.b, b: -x.b, }
}

// ---------------------------------------------------------------- A₄

///|
/// A₄ 共軛類大小：{e} = 1、雙對換 = 3、兩類三元循環 = 4 + 4。
pub fn a4_class_sizes() -> Array[Int64] {
  [1L, 3L, 4L, 4L]
}

///|
/// A₄ 的特徵表（列 = 不可約表示，行 = 共軛類）：
///   χ₁ = (1, 1, 1, 1)、χ_ω = (1, 1, ω, ω²)、χ_{ω²} = (1, 1, ω², ω)、χ₃ = (3, −1, 0, 0)。
pub fn a4_table() -> Array[Array[OmegaVal]] {
  let o1 = omega_one()
  [
    [o1, o1, o1, o1],
    [o1, o1, omega_gen(), omega(-1L, -1L)],
    [o1, o1, omega(-1L, -1L), omega_gen()],
    [omega(3L, 0L), omega(-1L, 0L), omega_zero(), omega_zero()],
  ]
}

///|
/// 把 ℤ[ω] 上的 r×c 矩陣展開成 2r×2c 整數矩陣（每個元素換成 2×2 區塊）。
pub fn omega_expand(m : Array[Array[OmegaVal]]) -> Array[Array[Int64]] {
  let r = m.length()
  let c = if r > 0 { m[0].length() } else { 0 }
  let out : Array[Array[Int64]] = []
  for i = 0; i < 2 * r; i = i + 1 {
    let row : Array[Int64] = []
    for j = 0; j < 2 * c; j = j + 1 {
      row.push(0L)
    }
    out.push(row)
  }
  for i = 0; i < r; i = i + 1 {
    for j = 0; j < c; j = j + 1 {
      let v = m[i][j]
      // [[a, −b], [b, a − b]]
      out[2 * i][2 * j] = v.a
      out[2 * i][2 * j + 1] = -v.b
      out[2 * i + 1][2 * j] = v.b
      out[2 * i + 1][2 * j + 1] = v.a - v.b
    }
  }
  out
}

///|
/// A₄ 的帶權重 Gram：Σ_C |C|·χ_V(C)·χ̄_W(C) 是否等於 12·I。
pub fn a4_gram_is_scalar() -> Bool {
  let t = a4_table()
  let cs = a4_class_sizes()
  let mut ok = true
  for i = 0; i < t.length(); i = i + 1 {
    for j = 0; j < t.length(); j = j + 1 {
      let mut s = omega_zero()
      for c = 0; c < cs.length(); c = c + 1 {
        let prod = omega_mul(t[i][c], omega_conj(t[j][c]))
        for _k = 0; _k < cs[c].to_int(); _k = _k + 1 {
          s = omega_add(s, prod)
        }
      }
      let want = if i == j { omega(12L, 0L) } else { omega_zero() }
      if s.a != want.a || s.b != want.b {
        ok = false
      }
    }
  }
  ok
}

///|
/// A₄ 組裝映射的秩（展開後 2r×2r，兩套演算法）。
pub fn a4_mu_rank_rat() -> Int32 {
  @analytic.rmat_rank(@analytic.rmat_of_int(omega_expand(a4_table())))
}

///|
/// A₄ 組裝映射的秩（F_p 高斯）。
pub fn a4_mu_rank_modp() -> Int32 {
  @cyclic.rank_q(omega_expand(a4_table()))
}

///|
/// 負控制：**只用 ℚ 而不用 ℤ[ω]** 時會失真——χ_ω 與 χ_{ω²} 在 Gal 下共軛，
/// 有理特徵理論只能看到它們的和 χ_ω + χ_{ω²} = (2, 2, −1, −1)。
/// 於是「有理特徵表」只有 3 列，展開後秩 = 6 < 8：ℚ 上數出來的不可約表示會少一個。
/// 這正是在 ℤ[ω] 上做秩計算（而不是在 ℚ 上）的必要性。
pub fn a4_rational_rank() -> Int32 {
  let t = a4_table()
  let merged : Array[Array[OmegaVal]] = []
  // triv
  merged.push(t[0])
  // χ_ω + χ_{ω²}
  let sum : Array[OmegaVal] = []
  for c = 0; c < t[0].length(); c = c + 1 {
    sum.push(omega_add(t[1][c], t[2][c]))
  }
  merged.push(sum)
  // χ₃
  merged.push(t[3])
  @analytic.rmat_rank(@analytic.rmat_of_int(omega_expand(merged)))
}
