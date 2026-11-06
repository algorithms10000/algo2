///|
/// B0004 / elliptic 套件：**除多項式 ψ_n 的精確計算**（T15 的可計算見證、A23）
/// 對應 docs/B0004-定理體系.md §3。
///
/// 為什麼需要它：E[n] ≅ (ℤ/n)² 的最「硬」的可計算證據是
///   φ_n(x) = ψ_n² 的根 = n 等分點的 x 座標，
/// 而 ψ_n 對 x 的次數是古典的 (n²−1)/2（n 奇）／(n²−4)/2（n 偶，此時 ψ_n 帶一個 y 因子）。
/// 這裡**不化簡** y² = x³+ax+b 就做乘法（否則「除以 2y」在商環裡無法判定整除性），
/// 只有最後才代入 y² = h(x) 讀次數——見 §3 的 D-E3 與 BUG-4。
///
/// 係數用 BigInt：ψ_12 的係數已達 10^20 量級，Int64 會溢位（這不是理論風險，是實測）。

///|
/// 稀疏雙變數多項式：項為 (x 次數, y 次數, 係數)，恆為**規範形**
///（依 (xd, yd) 字典序遞增、無重複鍵、無零係數）。
pub struct NPoly {
  t : Array[(Int32, Int32, BigInt)]
}

///|
/// 由任意項列表造規範形。
fn np_norm(terms : Array[(Int32, Int32, BigInt)]) -> NPoly {
  let arr = terms
  arr.sort_by(fn(p, q) {
    let (px, py, _) = p
    let (qx, qy, _) = q
    if px != qx {
      px - qx
    } else {
      py - qy
    }
  })
  let out : Array[(Int32, Int32, BigInt)] = []
  for i = 0; i < arr.length(); i = i + 1 {
    let (x, y, c) = arr[i]
    if out.length() > 0 {
      let (lx, ly, lc) = out[out.length() - 1]
      if lx == x && ly == y {
        out[out.length() - 1] = (lx, ly, lc + c)
        continue
      }
    }
    out.push((x, y, c))
  }
  let clean : Array[(Int32, Int32, BigInt)] = []
  for i = 0; i < out.length(); i = i + 1 {
    let (x, y, c) = out[i]
    if !c.is_zero() {
      clean.push((x, y, c))
    }
  }
  { t: clean, }
}

///|
/// 常數多項式。
pub fn np_const(c : Int32) -> NPoly {
  np_norm([(0, 0, BigInt::from_int(c))])
}

///|
/// 零多項式。
pub fn np_zero() -> NPoly {
  { t: [], }
}

///|
pub fn np_is_zero(p : NPoly) -> Bool {
  p.t.length() == 0
}

///|
/// y（ψ_2 = 2y 用得到）。
pub fn np_y() -> NPoly {
  np_norm([(0, 1, BigInt::from_int(1))])
}

///|
pub fn np_scale(p : NPoly, c : Int32) -> NPoly {
  let out : Array[(Int32, Int32, BigInt)] = []
  let bc = BigInt::from_int(c)
  for i = 0; i < p.t.length(); i = i + 1 {
    let (x, y, cc) = p.t[i]
    out.push((x, y, cc * bc))
  }
  np_norm(out)
}

///|
/// 乘法（**不**做 y² 化簡；化簡只在 np_reduce 做）。
pub fn np_mul(a : NPoly, b : NPoly) -> NPoly {
  if np_is_zero(a) || np_is_zero(b) {
    return np_zero()
  }
  let acc : Array[(Int32, Int32, BigInt)] = []
  for i = 0; i < a.t.length(); i = i + 1 {
    let (ax, ay, ac) = a.t[i]
    for j = 0; j < b.t.length(); j = j + 1 {
      let (bx, by, bc) = b.t[j]
      acc.push((ax + bx, ay + by, ac * bc))
    }
  }
  np_norm(acc)
}

///|
pub fn np_add(a : NPoly, b : NPoly) -> NPoly {
  np_norm(a.t.copy() + b.t.copy())
}

///|
pub fn np_sub(a : NPoly, b : NPoly) -> NPoly {
  np_add(a, np_scale(b, -1))
}

///|
pub fn np_pow(a : NPoly, k : Int32) -> NPoly {
  let mut r = np_const(1)
  for _i = 0; _i < k; _i = _i + 1 {
    r = np_mul(r, a)
  }
  r
}

///|
/// 除以 2y：要求每一項的 y 次數 ≥ 1 且係數為偶數（否則回報 `None`，不靜默通過）。
/// 這正是「ψ_n ∈ ℤ[x,y]」的整數性在這裡的可執行判準。
pub fn np_div_2y(p : NPoly) -> NPoly? {
  if np_is_zero(p) {
    return Some(np_zero())
  }
  let two = BigInt::from_int(2)
  let zero = BigInt::from_int(0)
  let out : Array[(Int32, Int32, BigInt)] = []
  for i = 0; i < p.t.length(); i = i + 1 {
    let (x, y, c) = p.t[i]
    if y < 1 {
      return None
    }
    if c % two != zero {
      return None
    }
    out.push((x, y - 1, c / two))
  }
  Some(np_norm(out))
}

///|
/// 代入 y² = x³ + a x + b，回傳只剩 y 次數 0 或 1 的等價多項式。
pub fn np_reduce(p : NPoly, a : Int32, b : Int32) -> NPoly {
  let mut cur = p.t.copy()
  let mut round = 0
  while true {
    round = round + 1
    if round > 64 {
      break
    }
    let mut high = false
    for i = 0; i < cur.length(); i = i + 1 {
      let (_x, y, _c) = cur[i]
      if y >= 2 {
        high = true
      }
    }
    if !high {
      break
    }
    let next : Array[(Int32, Int32, BigInt)] = []
    for i = 0; i < cur.length(); i = i + 1 {
      let (x, y, c) = cur[i]
      if y >= 2 {
        // y^y = y^(y−2) · (x³ + a x + b)
        next.push((x + 3, y - 2, c))
        next.push((x + 1, y - 2, c * BigInt::from_int(a)))
        next.push((x, y - 2, c * BigInt::from_int(b)))
      } else {
        next.push((x, y, c))
      }
    }
    cur = np_norm(next).t
  }
  np_norm(cur)
}

///|
/// 化簡後的 x 次數（空多項式回 −1）。
pub fn np_deg_x(p : NPoly) -> Int32 {
  let mut d = -1
  for i = 0; i < p.t.length(); i = i + 1 {
    let (x, _y, _c) = p.t[i]
    if x > d {
      d = x
    }
  }
  d
}

///|
/// 化簡後出現的 y 次數集合（理論上恰為 {0}（n 奇）或 {1}（n 偶））。
pub fn np_y_degrees(p : NPoly) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < p.t.length(); i = i + 1 {
    let (_x, y, _c) = p.t[i]
    let mut seen = false
    for j = 0; j < out.length(); j = j + 1 {
      if out[j] == y {
        seen = true
      }
    }
    if !seen {
      out.push(y)
    }
  }
  out.sort()
  out
}

///|
/// 項數（文件與報表用）。
pub fn np_terms(p : NPoly) -> Int32 {
  p.t.length()
}

///|
/// 曲線 y² = x³ + a x + b 的前 `nmax` 個除多項式（索引 0..nmax−1，ψ_0 = 0）。
///
/// 遞歸（D-E3）：
///   ψ_0 = 0、ψ_1 = 1、ψ_2 = 2y、ψ_3 = 3x⁴+6ax²+12bx−a²、
///   ψ_4 = ψ_2·(2x⁶+10ax⁴+40bx³−10a²x²−8abx−2a³−16b²)、
///   ψ_{2m+1} = ψ_{m+2}ψ_m³ − ψ_{m−1}ψ_{m+1}³          (m ≥ 2)、
///   ψ_{2m}   = ψ_m(ψ_{m+2}ψ_{m−1}² − ψ_{m−2}ψ_{m+1}²)/(2y)  (m ≥ 3)。
/// 每一步的「除以 2y」都要求真的整除（np_div_2y 回 None 即中止），這是整數性檢核。
pub fn div_polys(a : Int32, b : Int32, nmax : Int32) -> Array[NPoly]? {
  if nmax < 1 {
    return Some([])
  }
  let cache : Array[NPoly] = [np_zero()]
  if nmax == 1 {
    return Some(cache)
  }
  cache.push(np_const(1))
  if nmax == 2 {
    return Some(cache)
  }
  cache.push(np_scale(np_y(), 2))
  if nmax == 3 {
    return Some(cache)
  }
  // ψ_3 = 3x⁴ + 6ax² + 12bx − a²
  cache.push(
    np_norm([
      (4, 0, BigInt::from_int(3)),
      (2, 0, BigInt::from_int(6 * a)),
      (1, 0, BigInt::from_int(12 * b)),
      (0, 0, BigInt::from_int(-a * a)),
    ]),
  )
  if nmax == 4 {
    return Some(cache)
  }
  // ψ_4 = ψ_2 · (2x⁶ + 10ax⁴ + 40bx³ − 10a²x² − 8abx − 2a³ − 16b²)
  let g4 = np_norm([
    (6, 0, BigInt::from_int(2)),
    (4, 0, BigInt::from_int(10 * a)),
    (3, 0, BigInt::from_int(40 * b)),
    (2, 0, BigInt::from_int(-10 * a * a)),
    (1, 0, BigInt::from_int(-8 * a * b)),
    (0, 0, BigInt::from_int(-2 * a * a * a - 16 * b * b)),
  ])
  cache.push(np_mul(np_scale(np_y(), 2), g4))
  let mut n = 5
  while n < nmax {
    let m = n / 2
    if n % 2 == 1 {
      // ψ_{2m+1} = ψ_{m+2}ψ_m³ − ψ_{m−1}ψ_{m+1}³
      let lhs = np_mul(cache[m + 2], np_pow(cache[m], 3))
      let rhs = np_mul(cache[m - 1], np_pow(cache[m + 1], 3))
      cache.push(np_sub(lhs, rhs))
    } else {
      // ψ_{2m} = ψ_m(ψ_{m+2}ψ_{m−1}² − ψ_{m−2}ψ_{m+1}²)/(2y)
      let lhs = np_mul(cache[m + 2], np_pow(cache[m - 1], 2))
      let rhs = np_mul(cache[m - 2], np_pow(cache[m + 1], 2))
      let inner = np_mul(cache[m], np_sub(lhs, rhs))
      match np_div_2y(inner) {
        None => return None
        Some(v) => cache.push(v)
      }
    }
    n = n + 1
  }
  Some(cache)
}

///|
/// ψ_n 的古典次數期望值：n 奇 → (n²−1)/2；n 偶 → (n²−4)/2（ψ_n 帶一個 y 因子）。
pub fn expected_psi_degree(n : Int32) -> Int32 {
  if n % 2 == 1 {
    (n * n - 1) / 2
  } else {
    (n * n - 4) / 2
  }
}

///|
/// ψ_n 化簡後應有的 y 次數：n = 1 → 0（ψ_1 = 1）；n ≥ 2 偶 → 1；n ≥ 3 奇 → 0。
pub fn expected_psi_y_degree(n : Int32) -> Int32 {
  if n >= 2 && n % 2 == 0 {
    1
  } else {
    0
  }
}
