///|
/// B0003 / modular 套件：**整數算術與同餘子群的解析不變量**（D-C1–D-C4、T13、T14、A20）
/// 對應 docs/B0003-定理體系.md §2–§4。
///
/// 全部用**整數**運算（不做浮點），因為這些不變量都是整數：
///   Euler φ、Dedekind ψ、尖點數 ν_∞、橢圓點數 ν₂ / ν₃、虧格 g。
/// 虧格以 12g = 12 + ψ − 3ν₂ − 4ν₃ − 6ν_∞ 計算，並要求 12 | 右邊（否則中止，不靜默）。

///|
/// 因數分解（回傳 (質因數, 指數) 表；n ≥ 1）。
pub fn factorize(n : Int32) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  let mut m = n
  let mut d = 2
  while d * d <= m {
    if m % d == 0 {
      let mut e = 0
      while m % d == 0 {
        m = m / d
        e = e + 1
      }
      out.push((d, e))
    }
    d = d + 1
  }
  if m > 1 {
    out.push((m, 1))
  }
  out
}

///|
/// Euler φ（n ≥ 1）。
pub fn euler_phi(n : Int32) -> Int32 {
  let mut r = n
  let fs = factorize(n)
  for i = 0; i < fs.length(); i = i + 1 {
    let (p, _e) = fs[i]
    r = r / p * (p - 1)
  }
  r
}

///|
/// Dedekind ψ（n ≥ 1）：ψ(n) = n·∏_{p|n}(1 + 1/p) = [SL₂(ℤ) : Γ₀(n)]。
pub fn dedekind_psi(n : Int32) -> Int32 {
  let mut r = n
  let fs = factorize(n)
  for i = 0; i < fs.length(); i = i + 1 {
    let (p, _e) = fs[i]
    r = r / p * (p + 1)
  }
  r
}

///|
/// χ₋₄(p)（Legendre 符號 (p/·) 的實部版本）：p=2 ⇒ 0；p ≡ 1 (4) ⇒ 1；p ≡ 3 (4) ⇒ −1。
fn chi4(p : Int32) -> Int32 {
  if p == 2 {
    return 0
  }
  if p % 4 == 1 {
    1
  } else {
    -1
  }
}

///|
/// χ₋₃(p)：p=3 ⇒ 0；p ≡ 1 (3) ⇒ 1；p ≡ 2 (3) ⇒ −1。
fn chi3(p : Int32) -> Int32 {
  if p == 3 {
    return 0
  }
  if p % 3 == 1 {
    1
  } else {
    -1
  }
}

///|
/// 最大公因數。
pub fn gcd(a : Int32, b : Int32) -> Int32 {
  let mut x = if a < 0 { -a } else { a }
  let mut y = if b < 0 { -b } else { b }
  while y != 0 {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
/// X₀(N) 的橢圓點數 ν₂(N)：4 | N ⇒ 0；否則 ∏_{p|N}(1 + χ₋₄(p))。
pub fn elliptic_two_count(n : Int32) -> Int32 {
  if n % 4 == 0 {
    return 0
  }
  let mut r = 1
  let fs = factorize(n)
  for i = 0; i < fs.length(); i = i + 1 {
    let (p, _e) = fs[i]
    r = r * (1 + chi4(p))
  }
  r
}

///|
/// X₀(N) 的橢圓點數 ν₃(N)：9 | N ⇒ 0；否則 ∏_{p|N}(1 + χ₋₃(p))。
pub fn elliptic_three_count(n : Int32) -> Int32 {
  if n % 9 == 0 {
    return 0
  }
  let mut r = 1
  let fs = factorize(n)
  for i = 0; i < fs.length(); i = i + 1 {
    let (p, _e) = fs[i]
    r = r * (1 + chi3(p))
  }
  r
}

///|
/// X₀(N) 的尖點數 ν_∞(N) = Σ_{d | N} φ(gcd(d, N/d))。
pub fn cusp_count(n : Int32) -> Int32 {
  let mut s = 0
  for d = 1; d <= n; d = d + 1 {
    if n % d == 0 {
      s = s + euler_phi(gcd(d, n / d))
    }
  }
  s
}

///|
/// X₀(N) 的虧格：12g = 12 + ψ(N) − 3ν₂(N) − 4ν₃(N) − 6ν_∞(N)。
/// 若右邊不被 12 整除則中止（表示輸入或公式有誤，不可靜默給出錯答案）。
pub fn genus_x0(n : Int32) -> Int32 {
  let numerator = 12 +
    dedekind_psi(n) -
    3 * elliptic_two_count(n) -
    4 * elliptic_three_count(n) -
    6 * cusp_count(n)
  if numerator % 12 != 0 {
    abort(
      "genus_x0：12g 的分子不被 12 整除（n=" + n.to_string() + "）",
    )
  }
  numerator / 12
}

///|
/// T13：[SL₂(ℤ) : Γ₀(N)] = ψ(N)。
pub fn index_gamma0(n : Int32) -> Int32 {
  dedekind_psi(n)
}

///|
/// T13：[SL₂(ℤ) : Γ₁(N)] = ψ(N)·φ(N)。
pub fn index_gamma1(n : Int32) -> Int32 {
  dedekind_psi(n) * euler_phi(n)
}

///|
/// T13：[SL₂(ℤ) : Γ(N)] = ψ(N)·φ(N)·N = N³·∏_{p|N}(1 − 1/p²)。
pub fn index_gamma_level(n : Int32) -> Int32 {
  dedekind_psi(n) * euler_phi(n) * n
}

///|
/// T13：|SL₂(ℤ/N)| = N³·∏_{p|N}(1 − 1/p²)（= 主同餘子群的指數）。
pub fn order_sl2_mod(n : Int32) -> Int32 {
  index_gamma_level(n)
}

///|
/// T14：X₀(N) 的虧格表（古典結果；本專案只用它當**外部期望值**，不參與計算）。
/// 回傳 Some(虧格) 表示 N 在表內，None 表示無外部期望值（此時不假裝通過）。
pub fn classical_genus(n : Int32) -> Int32? {
  // 虧格 0 的 N（Ogg 的古典清單前段）
  let genus_zero : Array[Int32] = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 12, 13, 16, 18, 25,
  ]
  for i = 0; i < genus_zero.length(); i = i + 1 {
    if genus_zero[i] == n {
      return Some(0)
    }
  }
  // 虧格 1
  let genus_one : Array[Int32] = [
    11, 14, 15, 17, 19, 20, 21, 24, 27, 32, 36, 49,
  ]
  for i = 0; i < genus_one.length(); i = i + 1 {
    if genus_one[i] == n {
      return Some(1)
    }
  }
  // 已知虧格 2（X₀(22)、X₀(23)）
  if n == 22 || n == 23 {
    return Some(2)
  }
  None
}
