///|
/// B0009 / analytic 套件：**精確有理數與有理矩陣**。
///
/// 近似單位元、投影、同倫這些概念本質上是分析性的（要取範數、要取 sup），
/// 但在**有限維**樣本上它們可以完全用 ℚ 上的精確算術驗證：
///   * 投影 p² = p = p* 是代數等式；
///   * 收斂 ‖e_n a − a‖ → 0 在有限維是「某個 n 之後恰為 0」；
///   * 同倫 e_t = (1+tA)e(1−tA)（A² = 0）在多項式參數 t 上是代數族。
/// 因此本套件不引入浮點：所有數字都是 ℚ 的既約分數，所有比較都是精確比較。

///|
/// 既約分數 num/den（den > 0、gcd(num, den) = 1）。
pub struct Rat {
  num : Int64
  den : Int64
}

///|
/// 最大公因數（非負）。
pub fn gcd_i64(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }
  while y != 0L {
    let r = x % y
    x = y
    y = r
  }
  x
}

///|
/// 建立既約分數（den = 0 視為 0/1；分母一律取正）。
pub fn rat_new(num : Int64, den : Int64) -> Rat {
  if den == 0L {
    return { num: 0L, den: 1L, }
  }
  let mut n = num
  let mut d = den
  if d < 0L {
    n = -n
    d = -d
  }
  let g = gcd_i64(n, d)
  if g == 0L {
    { num: 0L, den: 1L, }
  } else {
    { num: n / g, den: d / g, }
  }
}

///|
/// 由整數建立分數。
pub fn rat_of_int(n : Int64) -> Rat {
  rat_new(n, 1L)
}

///|
/// 加法。
pub fn rat_add(a : Rat, b : Rat) -> Rat {
  rat_new(a.num * b.den + b.num * a.den, a.den * b.den)
}

///|
/// 減法。
pub fn rat_sub(a : Rat, b : Rat) -> Rat {
  rat_new(a.num * b.den - b.num * a.den, a.den * b.den)
}

///|
/// 乘法。
pub fn rat_mul(a : Rat, b : Rat) -> Rat {
  rat_new(a.num * b.num, a.den * b.den)
}

///|
/// 除法（除數為 0 時回傳 0/1）。
pub fn rat_div(a : Rat, b : Rat) -> Rat {
  rat_new(a.num * b.den, a.den * b.num)
}

///|
/// 相反數。
pub fn rat_neg(a : Rat) -> Rat {
  { num: -a.num, den: a.den, }
}

///|
/// 是否為零。
pub fn rat_is_zero(a : Rat) -> Bool {
  a.num == 0L
}

///|
/// 相等。
pub fn rat_eq(a : Rat, b : Rat) -> Bool {
  a.num == b.num && a.den == b.den
}

///|
/// 轉成字串（既約分數）。
pub fn rat_to_string(a : Rat) -> String {
  if a.den == 1L {
    a.num.to_string()
  } else {
    a.num.to_string() + "/" + a.den.to_string()
  }
}

// ---------------------------------------------------------------- 有理矩陣

///|
/// 列主序的 ℚ-矩陣。
pub struct RMat {
  rows : Int32
  cols : Int32
  e : Array[Rat]
}

///|
/// 零矩陣。
pub fn rmat_zero(rows : Int32, cols : Int32) -> RMat {
  let e : Array[Rat] = []
  for i = 0; i < rows * cols; i = i + 1 {
    e.push(rat_of_int(0L))
  }
  { rows, cols, e, }
}

///|
/// 單位矩陣。
pub fn rmat_id(n : Int32) -> RMat {
  let m = rmat_zero(n, n)
  for i = 0; i < n; i = i + 1 {
    m.e[i * n + i] = rat_of_int(1L)
  }
  m
}

///|
/// 讀元素。
pub fn rmat_get(m : RMat, i : Int32, j : Int32) -> Rat {
  m.e[i * m.cols + j]
}

///|
/// 寫元素。
pub fn rmat_set(m : RMat, i : Int32, j : Int32, v : Rat) -> Unit {
  m.e[i * m.cols + j] = v
}

///|
/// 由整數列資料建構。
pub fn rmat_of_int(rows : Array[Array[Int64]]) -> RMat {
  let r = rows.length()
  let c = if r == 0 { 0 } else { rows[0].length() }
  let m = rmat_zero(r, c)
  for i = 0; i < r; i = i + 1 {
    for j = 0; j < c; j = j + 1 {
      rmat_set(m, i, j, rat_of_int(rows[i][j]))
    }
  }
  m
}

///|
/// 加法。
pub fn rmat_add(a : RMat, b : RMat) -> RMat {
  let m = rmat_zero(a.rows, a.cols)
  for i = 0; i < a.rows * a.cols; i = i + 1 {
    m.e[i] = rat_add(a.e[i], b.e[i])
  }
  m
}

///|
/// 減法。
pub fn rmat_sub(a : RMat, b : RMat) -> RMat {
  let m = rmat_zero(a.rows, a.cols)
  for i = 0; i < a.rows * a.cols; i = i + 1 {
    m.e[i] = rat_sub(a.e[i], b.e[i])
  }
  m
}

///|
/// 純量乘法。
pub fn rmat_scale(a : RMat, c : Rat) -> RMat {
  let m = rmat_zero(a.rows, a.cols)
  for i = 0; i < a.rows * a.cols; i = i + 1 {
    m.e[i] = rat_mul(a.e[i], c)
  }
  m
}

///|
/// 乘法。
pub fn rmat_mul(a : RMat, b : RMat) -> RMat {
  let m = rmat_zero(a.rows, b.cols)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < b.cols; j = j + 1 {
      let mut s = rat_of_int(0L)
      for k = 0; k < a.cols; k = k + 1 {
        s = rat_add(s, rat_mul(rmat_get(a, i, k), rmat_get(b, k, j)))
      }
      rmat_set(m, i, j, s)
    }
  }
  m
}

///|
/// 轉置。
pub fn rmat_transpose(a : RMat) -> RMat {
  let m = rmat_zero(a.cols, a.rows)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < a.cols; j = j + 1 {
      rmat_set(m, j, i, rmat_get(a, i, j))
    }
  }
  m
}

///|
/// 跡。
pub fn rmat_trace(a : RMat) -> Rat {
  let mut s = rat_of_int(0L)
  let n = if a.rows < a.cols { a.rows } else { a.cols }
  for i = 0; i < n; i = i + 1 {
    s = rat_add(s, rmat_get(a, i, i))
  }
  s
}

///|
/// 是否相等。
pub fn rmat_eq(a : RMat, b : RMat) -> Bool {
  if a.rows != b.rows || a.cols != b.cols {
    return false
  }
  let mut ok = true
  for i = 0; i < a.rows * a.cols; i = i + 1 {
    if !rat_eq(a.e[i], b.e[i]) {
      ok = false
    }
  }
  ok
}

///|
/// 是否全零。
pub fn rmat_is_zero(a : RMat) -> Bool {
  rmat_eq(a, rmat_zero(a.rows, a.cols))
}

///|
/// ℚ 上的秩（有理高斯消去，精確）。
pub fn rmat_rank(a : RMat) -> Int32 {
  let m = rmat_zero(a.rows, a.cols)
  for i = 0; i < a.rows * a.cols; i = i + 1 {
    m.e[i] = a.e[i]
  }
  let mut rank = 0
  let mut col = 0
  while col < m.cols && rank < m.rows {
    let mut piv = -1
    for i = rank; i < m.rows; i = i + 1 {
      if piv < 0 && !rat_is_zero(rmat_get(m, i, col)) {
        piv = i
      }
    }
    if piv >= 0 {
      if piv != rank {
        for j = 0; j < m.cols; j = j + 1 {
          let t = rmat_get(m, rank, j)
          rmat_set(m, rank, j, rmat_get(m, piv, j))
          rmat_set(m, piv, j, t)
        }
      }
      let p = rmat_get(m, rank, col)
      for i = rank + 1; i < m.rows; i = i + 1 {
        let f = rmat_get(m, i, col)
        if !rat_is_zero(f) {
          let r = rat_div(f, p)
          for j = col; j < m.cols; j = j + 1 {
            rmat_set(
              m,
              i,
              j,
              rat_sub(rmat_get(m, i, j), rat_mul(r, rmat_get(m, rank, j))),
            )
          }
        }
      }
      rank = rank + 1
    }
    col = col + 1
  }
  rank
}

///|
/// Frobenius 範數的平方 ‖A‖₂² = tr(A Aᵀ)（精確有理數）。
/// 有限維時它與算子範數等價，故「‖·‖₂ → 0」與「算子範數 → 0」同義。
pub fn rmat_norm2(a : RMat) -> Rat {
  rmat_trace(rmat_mul(a, rmat_transpose(a)))
}

///|
/// 共軛 u A uᵀ（u 正交時即么正共軛）。
pub fn rmat_conj(u : RMat, a : RMat) -> RMat {
  rmat_mul(rmat_mul(u, a), rmat_transpose(u))
}

///|
/// 矩陣轉字串（列／行）。
pub fn rmat_to_string(a : RMat) -> String {
  let sb = StringBuilder()
  for i = 0; i < a.rows; i = i + 1 {
    if i > 0 {
      sb.write_string("; ")
    }
    for j = 0; j < a.cols; j = j + 1 {
      if j > 0 {
        sb.write_string(" ")
      }
      sb.write_string(rat_to_string(rmat_get(a, i, j)))
    }
  }
  sb.to_string()
}

///|
/// 行列式（ℚ 上高斯消去，精確；非方陣回傳 0）。
pub fn rmat_det(a : RMat) -> Rat {
  if a.rows != a.cols {
    return rat_of_int(0L)
  }
  let n = a.rows
  let m = rmat_zero(n, n)
  for i = 0; i < n * n; i = i + 1 {
    m.e[i] = a.e[i]
  }
  let mut det = rat_of_int(1L)
  let mut sign = 1L
  for col = 0; col < n; col = col + 1 {
    let mut piv = -1
    for i = col; i < n; i = i + 1 {
      if piv < 0 && !rat_is_zero(rmat_get(m, i, col)) {
        piv = i
      }
    }
    if piv < 0 {
      return rat_of_int(0L)
    }
    if piv != col {
      for j = 0; j < n; j = j + 1 {
        let t = rmat_get(m, col, j)
        rmat_set(m, col, j, rmat_get(m, piv, j))
        rmat_set(m, piv, j, t)
      }
      sign = -sign
    }
    let p = rmat_get(m, col, col)
    det = rat_mul(det, p)
    for i = col + 1; i < n; i = i + 1 {
      let f = rat_get_div(rmat_get(m, i, col), p)
      for j = col; j < n; j = j + 1 {
        rmat_set(
          m,
          i,
          j,
          rat_sub(rmat_get(m, i, j), rat_mul(f, rmat_get(m, col, j))),
        )
      }
    }
  }
  rmat_scale_det(det, sign)
}

///|
/// 分數除以分數（輔助，避免名稱衝突）。
pub fn rat_get_div(a : Rat, b : Rat) -> Rat {
  rat_div(a, b)
}

///|
/// 把行列式乘上符號（輔助）。
pub fn rmat_scale_det(d : Rat, sign : Int64) -> Rat {
  rat_mul(d, rat_of_int(sign))
}

///|
/// 逆矩陣（Gauss–Jordan，精確；奇異時回傳零矩陣）。
pub fn rmat_inv(a : RMat) -> RMat {
  let n = a.rows
  if n != a.cols {
    return rmat_zero(n, n)
  }
  let m = rmat_zero(n, 2 * n)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      rmat_set(m, i, j, rmat_get(a, i, j))
    }
    rmat_set(m, i, n + i, rat_of_int(1L))
  }
  for col = 0; col < n; col = col + 1 {
    let mut piv = -1
    for i = col; i < n; i = i + 1 {
      if piv < 0 && !rat_is_zero(rmat_get(m, i, col)) {
        piv = i
      }
    }
    if piv < 0 {
      return rmat_zero(n, n)
    }
    if piv != col {
      for j = 0; j < 2 * n; j = j + 1 {
        let t = rmat_get(m, col, j)
        rmat_set(m, col, j, rmat_get(m, piv, j))
        rmat_set(m, piv, j, t)
      }
    }
    let p = rmat_get(m, col, col)
    for j = 0; j < 2 * n; j = j + 1 {
      rmat_set(m, col, j, rat_div(rmat_get(m, col, j), p))
    }
    for i = 0; i < n; i = i + 1 {
      if i != col {
        let f = rmat_get(m, i, col)
        if !rat_is_zero(f) {
          for j = 0; j < 2 * n; j = j + 1 {
            rmat_set(
              m,
              i,
              j,
              rat_sub(rmat_get(m, i, j), rat_mul(f, rmat_get(m, col, j))),
            )
          }
        }
      }
    }
  }
  let out = rmat_zero(n, n)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      rmat_set(out, i, j, rmat_get(m, i, n + j))
    }
  }
  out
}
