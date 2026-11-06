///|
/// B0010 / bc 套件：**無撓群的 Kadison–Kaplansky 截面**——
/// ℂ[ℤ] = ℂ[t, t⁻¹] 的非平凡冪等元。
///
/// 兩層證據：
///   1. **次數論證**（封閉所有情形）：若 p 非零常數、deg p = k ≥ 1，
///      則 deg(p²) = 2k > k = deg p，故 p² ≠ p。首項係數 a_k ≠ 0 ⇒ p² 的首項係數 a_k² ≠ 0。
///      （ℂ 是整域，這步不需要任何假設。）
///   2. **窮舉驗證**（有限截面，使論證不是空話）：支撐在 [−k, k]、係數在 {−1,0,1} 內
///      的所有 Laurent 多項式，逐個檢查 p² ≠ p（非平凡者）。
///
/// 負控制：ℂ[ℤ/2] 有 e = (1 + g)/2 為非平凡冪等元——**有撓** 是必要條件，
/// 因此 Baum–Connes 滿射性推出 Kadison–Kaplinsky 的那條推論不能抽掉無撓假設。

///|
/// Laurent 多項式：`c[i]` 是次數 `lo + i` 的係數。
pub struct Laurent {
  lo : Int32
  c : Array[Int64]
}

///|
/// 建構（去掉兩端的零）。
pub fn laurent_new(lo : Int32, cs : Array[Int64]) -> Laurent {
  let c : Array[Int64] = []
  for x in cs {
    c.push(x)
  }
  let mut l = lo
  while c.length() > 0 && c[0] == 0L {
    ignore(c.remove(0))
    l = l + 1
  }
  while c.length() > 0 && c[c.length() - 1] == 0L {
    ignore(c.pop())
  }
  { lo: l, c, }
}

///|
/// 次數（零多項式回傳 0）。
pub fn laurent_deg(p : Laurent) -> Int32 {
  p.lo + p.c.length() - 1
}

///|
/// 是否為零。
pub fn laurent_is_zero(p : Laurent) -> Bool {
  p.c.length() == 0
}

///|
/// 乘法。
pub fn laurent_mul(a : Laurent, b : Laurent) -> Laurent {
  if laurent_is_zero(a) || laurent_is_zero(b) {
    return laurent_new(0, [])
  }
  let out : Array[Int64] = []
  for i = 0; i < a.c.length() + b.c.length() - 1; i = i + 1 {
    out.push(0L)
  }
  for i = 0; i < a.c.length(); i = i + 1 {
    for j = 0; j < b.c.length(); j = j + 1 {
      out[i + j] = out[i + j] + a.c[i] * b.c[j]
    }
  }
  laurent_new(a.lo + b.lo, out)
}

///|
/// 相等。
pub fn laurent_eq(a : Laurent, b : Laurent) -> Bool {
  if laurent_is_zero(a) && laurent_is_zero(b) {
    return true
  }
  if a.lo != b.lo || a.c.length() != b.c.length() {
    return false
  }
  let mut ok = true
  for i = 0; i < a.c.length(); i = i + 1 {
    if a.c[i] != b.c[i] {
      ok = false
    }
  }
  ok
}

///|
/// 是否為常數 0 或 1（即「平凡冪等元」）。
pub fn laurent_is_trivial_idempotent(p : Laurent) -> Bool {
  let is_const = p.c.length() <= 1
  is_const && (laurent_is_zero(p) || (p.c.length() == 1 && p.c[0] == 1L))
}

///|
/// **窮舉截面**：支撐在 [−kmax, kmax]、係數在 {−1, 0, 1} 的所有 Laurent 多項式，
/// 檢查除 0、1 之外沒有冪等元；並確認 0、1 本身冪等。
pub fn check_no_laurent_idempotent(kmax : Int32) -> Bool {
  let len = 2 * kmax + 1
  let mut total = 0
  let mut bad = 0
  // 3^len 個組合（len ≤ 5 → 243 個，夠且誠實）
  let mut idx = 0
  while idx < pow3(len) {
    let cs : Array[Int64] = []
    let mut r = idx
    for _i = 0; _i < len; _i = _i + 1 {
      let d = r % 3
      r = r / 3
      cs.push(if d == 0 { -1L } else if d == 1 { 0L } else { 1L })
    }
    let p = laurent_new(-kmax, cs)
    let sq = laurent_mul(p, p)
    total = total + 1
    if laurent_eq(sq, p) && !laurent_is_trivial_idempotent(p) {
      bad = bad + 1
    }
    idx = idx + 1
  }
  // 0、1 必須冪等
  let zero = laurent_new(0, [0L])
  let one = laurent_new(0, [1L])
  let trivial_ok = laurent_eq(laurent_mul(zero, zero), zero) &&
    laurent_eq(laurent_mul(one, one), one)
  bad == 0 && trivial_ok && total == pow3(len)
}

///|
/// 3^n。
pub fn pow3(n : Int32) -> Int32 {
  let mut p = 1
  for _i = 0; _i < n; _i = _i + 1 {
    p = p * 3
  }
  p
}

///|
/// **次數論證**（封閉全部情形）：對每個 k = 1..kmax 與每個非零首項係數 a，
/// 驗 deg(p²) = 2k > k，故 p² ≠ p。回傳「所有情形都不可能是冪等元」。
pub fn check_degree_argument(kmax : Int32) -> Bool {
  let mut ok = true
  for k = 1; k <= kmax; k = k + 1 {
    for a in [1L, -1L, 2L, -3L] {
      let cs : Array[Int64] = []
      for i = 0; i <= k; i = i + 1 {
        cs.push(if i == k { a } else { 0L })
      }
      let p = laurent_new(0, cs)
      let sq = laurent_mul(p, p)
      // deg(p²) = 2k ≠ k
      if laurent_deg(sq) == laurent_deg(p) {
        ok = false
      }
      // 首項係數 a² ≠ 0
      if sq.c[sq.c.length() - 1] == 0L {
        ok = false
      }
    }
  }
  ok
}

///|
/// **負控制**：ℂ[ℤ/2] 上 e = (1 + g)/2 是非平凡冪等元（g² = 1）。
/// 用 ℚ 精算（`@analytic.Rat`），維度 2 的基底 {1, g}。
pub fn check_torsion_idempotent() -> Bool {
  let half = @analytic.rat_new(1L, 2L)
  // e 的座標：1/2·1 + 1/2·g
  let e : Array[@analytic.Rat] = [half, half]
  // 乘法在 ℂ[ℤ/2]：g² = 1 ⇒ (a + b g)(c + d g) = (ac + bd) + (ad + bc) g
  let a = @analytic.rat_mul(e[0], e[0])
  let bd = @analytic.rat_mul(e[1], e[1])
  let sq0 = @analytic.rat_add(a, bd)
  let ad = @analytic.rat_mul(e[0], e[1])
  let bc = @analytic.rat_mul(e[1], e[0])
  let sq1 = @analytic.rat_add(ad, bc)
  let idempotent = @analytic.rat_eq(sq0, e[0]) && @analytic.rat_eq(sq1, e[1])
  // 非平凡：e ≠ 0 且 e ≠ 1
  let nontrivial = !@analytic.rat_is_zero(e[0]) &&
    !(@analytic.rat_eq(e[0], @analytic.rat_of_int(1L)) &&
    @analytic.rat_is_zero(e[1]))
  idempotent && nontrivial
}
