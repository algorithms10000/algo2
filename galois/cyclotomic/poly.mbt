///|
/// B0010 / cyclotomic 套件：**整係數多項式**（分圓多項式 φ_n 的計算基礎）。
///
/// 分圓多項式 Φ_n ∈ ℤ[x] 是么正的，因此 ℚ(ζ_n) 的乘法與伽羅瓦作用
/// **全部是整數矩陣運算**——不需要浮點、不需要代數數型別。

///|
/// 整係數多項式（索引 = 次數，尾端零已去除）。
pub struct Poly {
  c : Array[Int64]
}

///|
/// 由係數建立（去掉尾端 0）。
pub fn poly_new(cs : Array[Int64]) -> Poly {
  let c : Array[Int64] = []
  for x in cs {
    c.push(x)
  }
  while c.length() > 1 && c[c.length() - 1] == 0L {
    ignore(c.pop())
  }
  if c.length() == 0 {
    c.push(0L)
  }
  { c, }
}

///|
/// 次數（零多項式回傳 0）。
pub fn poly_deg(p : Poly) -> Int32 {
  p.c.length() - 1
}

///|
/// 是否為零。
pub fn poly_is_zero(p : Poly) -> Bool {
  p.c.length() == 1 && p.c[0] == 0L
}

///|
/// 乘法。
pub fn poly_mul(a : Poly, b : Poly) -> Poly {
  let out : Array[Int64] = []
  for i = 0; i < a.c.length() + b.c.length() - 1; i = i + 1 {
    out.push(0L)
  }
  for i = 0; i < a.c.length(); i = i + 1 {
    for j = 0; j < b.c.length(); j = j + 1 {
      out[i + j] = out[i + j] + a.c[i] * b.c[j]
    }
  }
  poly_new(out)
}

///|
/// 精確除法（除式么正時必整除；不整除回傳零多項式）。
pub fn poly_div_exact(a : Poly, b : Poly) -> Poly {
  if poly_is_zero(b) {
    return poly_new([0L])
  }
  let rem : Array[Int64] = []
  for x in a.c {
    rem.push(x)
  }
  let db = poly_deg(b)
  let q : Array[Int64] = []
  for i = 0; i < a.c.length(); i = i + 1 {
    q.push(0L)
  }
  for i = poly_deg(a) - db; i >= 0; i = i - 1 {
    if rem[i + db] != 0L {
      let f = rem[i + db]
      q[i] = f
      for j = 0; j <= db; j = j + 1 {
        rem[i + j] = rem[i + j] - f * b.c[j]
      }
    }
  }
  poly_new(q)
}

///|
/// 多項式的整除判定（餘式為零）。
pub fn poly_divides(b : Poly, a : Poly) -> Bool {
  if poly_is_zero(b) {
    return false
  }
  let q = poly_div_exact(a, b)
  poly_is_zero(poly_new(sub_poly(poly_mul(q, b), a)))
}

///|
/// 輔助：多項式差（此處僅用於整除判定）。
fn sub_poly(a : Poly, b : Poly) -> Array[Int64] {
  let n = if a.c.length() > b.c.length() { a.c.length() } else { b.c.length() }
  let out : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    let x = if i < a.c.length() { a.c[i] } else { 0L }
    let y = if i < b.c.length() { b.c[i] } else { 0L }
    out.push(x - y)
  }
  out
}

///|
/// x^n − 1。
pub fn poly_xn_minus_1(n : Int32) -> Poly {
  let c : Array[Int64] = []
  for i = 0; i <= n; i = i + 1 {
    c.push(if i == 0 { -1L } else if i == n { 1L } else { 0L })
  }
  if n == 0 {
    return poly_new([0L])
  }
  poly_new(c)
}

///|
/// Euler φ：直接轉呼叫 `@modular.euler_phi`（B0003 的唯一實作；本套件不再另寫一份）。
pub fn euler_phi(n : Int32) -> Int32 {
  @modular.euler_phi(n)
}

///|
/// 正因數清單（升序）。
pub fn divisors(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for d = 1; d <= n; d = d + 1 {
    if n % d == 0 {
      out.push(d)
    }
  }
  out
}

///|
/// **分圓多項式 Φ_n**：用 x^n − 1 = ∏_{d|n} Φ_d 遞迴算出。
pub fn cyclotomic_poly(n : Int32) -> Poly {
  if n == 1 {
    return poly_new([-1L, 1L])
  }
  let mut acc = poly_xn_minus_1(n)
  for d in divisors(n) {
    if d < n {
      acc = poly_div_exact(acc, cyclotomic_poly(d))
    }
  }
  acc
}
