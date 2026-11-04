///|
/// B0005 / jacobian 套件：**J[2] 上的交錯形式、二次細化與 Arf 不變量（theta 特徵）**（T29、A34）
/// 對應 docs/B0005-定理體系.md §8。
///
/// J[2] ≅ 𝔽₂^{2g}，Weil 配對 e_2 是**非退化交錯形式**（正是 B0003／B0004 的那個配對在 J[2] 上的樣子）。
/// 「theta 特徵」= 細化 e_2 的二次形式 q（q(x+y) + q(x) + q(y) = B(x,y)），
/// 古典計數：共 2^{2g} 個，其中 Arf = 0 有 2^{g−1}(2^g+1) 個、Arf = 1 有 2^{g−1}(2^g−1) 個。
/// g = 2 時就是「10 個偶 theta 特徵 + 6 個奇」。
///
/// 全部在 𝔽₂ 上以位元（Int32 的 0..2g−1 位）精確計算。

///|
/// 標準交錯形式：B(e_i, f_j) = δ_{ij}，其中 e_i = 位 i、f_j = 位 (g+j)。
pub fn symplectic_pair(g : Int32, x : Int32, y : Int32) -> Int32 {
  let mut s = 0
  for i = 0; i < g; i = i + 1 {
    s = s ^ ((x >> i) & 1 & ((y >> (g + i)) & 1))
    s = s ^ ((x >> (g + i)) & 1 & ((y >> i) & 1))
  }
  s
}

///|
/// 基礎二次形式 q₀(Σ a_i e_i + Σ b_j f_j) = Σ a_i b_i。
pub fn base_quadratic(g : Int32, x : Int32) -> Int32 {
  let mut s = 0
  for i = 0; i < g; i = i + 1 {
    s = s ^ ((x >> i) & 1 & ((x >> (g + i)) & 1))
  }
  s
}

///|
/// 以線性部分 ℓ（位元遮罩 ell）細化後的二次形式 q = q₀ + ℓ。
pub fn refined_quadratic(g : Int32, ell : Int32, x : Int32) -> Int32 {
  base_quadratic(g, x) ^ popcount_parity(x & ell)
}

///|
/// 位元遮罩的奇偶（popcount mod 2）。
pub fn popcount_parity(x : Int32) -> Int32 {
  let mut v = x
  let mut p = 0
  while v != 0 {
    p = p ^ (v & 1)
    v = v >> 1
  }
  p
}

///|
/// 某個細化是否真的滿足 q(x+y) + q(x) + q(y) = B(x,y)（對全部 x, y）。
pub fn is_quadratic_refinement(g : Int32, ell : Int32) -> Bool {
  let n = 1 << (2 * g)
  for x = 0; x < n; x = x + 1 {
    for y = 0; y < n; y = y + 1 {
      let lhs = refined_quadratic(g, ell, x ^ y) ^
        refined_quadratic(g, ell, x) ^
        refined_quadratic(g, ell, y)
      if lhs != symplectic_pair(g, x, y) {
        return false
      }
    }
  }
  true
}

///|
/// Arf 不變量：Σ_i q(e_i)q(f_i)。
pub fn arf_invariant(g : Int32, ell : Int32) -> Int32 {
  let mut s = 0
  for i = 0; i < g; i = i + 1 {
    s = s ^
      (
        refined_quadratic(g, ell, 1 << i) &
        refined_quadratic(g, ell, 1 << (g + i))
      )
  }
  s
}

///|
/// 計數結果：有效的細化個數，按 Arf 值分組，並回報是否全部有效。
pub struct ArfCount {
  arf0 : Int32
  arf1 : Int32
  invalid : Int32
}

///|
pub fn ArfCount::render(self : ArfCount) -> String {
  "Arf=0：" +
  self.arf0.to_string() +
  "、Arf=1：" +
  self.arf1.to_string() +
  "、無效細化：" +
  self.invalid.to_string()
}

///|
/// 枚舉全部 2^{2g} 個候選細化並分類。
pub fn count_refinements(g : Int32) -> ArfCount {
  let n = 1 << (2 * g)
  let mut a0 = 0
  let mut a1 = 0
  let mut bad = 0
  for ell = 0; ell < n; ell = ell + 1 {
    if !is_quadratic_refinement(g, ell) {
      bad = bad + 1
    } else if arf_invariant(g, ell) == 0 {
      a0 = a0 + 1
    } else {
      a1 = a1 + 1
    }
  }
  { arf0: a0, arf1: a1, invalid: bad, }
}

///|
/// 2^{g−1}(2^g + 1)（Arf = 0 的古典期望值）。
pub fn expected_arf0(g : Int32) -> Int32 {
  (1 << (g - 1)) * ((1 << g) + 1)
}

///|
/// 2^{g−1}(2^g − 1)（Arf = 1 的古典期望值）。
pub fn expected_arf1(g : Int32) -> Int32 {
  (1 << (g - 1)) * ((1 << g) - 1)
}

///|
/// 2g×2g 的 𝔽₂ 矩陣（以 Int32 列位元表示）。
pub struct F2Mat {
  n : Int32
  rows : Array[Int32]
}

///|
/// 矩陣乘向量。
pub fn F2Mat::act(self : F2Mat, v : Int32) -> Int32 {
  let mut out = 0
  for i = 0; i < self.n; i = i + 1 {
    out = out | (popcount_parity(self.rows[i] & v) << i)
  }
  out
}

///|
/// 是否保交錯形式：B(Ax, Ay) = B(x, y) 對所有 x,y——以「列對的配對矩陣」檢查。
pub fn is_symplectic(g : Int32, m : F2Mat) -> Bool {
  let n = 1 << (2 * g)
  for x = 0; x < n; x = x + 1 {
    for y = 0; y < n; y = y + 1 {
      if symplectic_pair(g, m.act(x), m.act(y)) != symplectic_pair(g, x, y) {
        return false
      }
    }
  }
  true
}

///|
/// 前拉（q ∘ A）：回傳新的細化遮罩對應……這裡直接回傳 q∘A 的「值表」，用於比對 Arf 是否不變。
pub fn arf_of_pullback(g : Int32, ell : Int32, m : F2Mat) -> Int32 {
  // Arf(q∘A) 以 q∘A 在標準基上的值計算；A 保形式 ⇒ q∘A 仍是細化
  let mut s = 0
  for i = 0; i < g; i = i + 1 {
    let a = refined_quadratic(g, ell, m.act(1 << i))
    let b = refined_quadratic(g, ell, m.act(1 << (g + i)))
    s = s ^ (a & b)
  }
  s
}

///|
/// F₂ 上 2g×2g 矩陣的全枚舉（僅 g = 1、2 可行：g = 2 時 2^16 = 65536 個）。
pub fn all_f2_matrices(n : Int32) -> Array[F2Mat] {
  let rows_total = 1 << n
  let out : Array[F2Mat] = []
  let mut idx = 0
  let total = 1 << (n * n)
  while idx < total {
    let rows : Array[Int32] = []
    for i = 0; i < n; i = i + 1 {
      rows.push((idx >> (i * n)) & (rows_total - 1))
    }
    out.push({ n, rows, })
    idx = idx + 1
  }
  out
}
