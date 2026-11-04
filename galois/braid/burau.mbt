///|
/// B0005 / braid 套件：**Burau 表示 β_n: B_n → GL_n(ℤ[t^{±1}])**（T23、A30）
/// 對應 docs/B0005-定理體系.md §3。
///
/// 未約化 Burau：σ_i ↦ I ⊕ [[1−t, t],[1, 0]] ⊕ I（2×2 區塊在 (i, i+1)）。
/// 係數用 BigInt、指數允許負（Laurent 多項式），因此「乘開來相等」是**精確**的判定，
/// 不是模某個多項式的近似。t = −1 的特化另行做（也是精確整數運算）。

///|
/// Laurent 多項式：項為 (指數, 係數)，恆為規範形（指數遞增、無零係數、無重複）。
pub struct LPoly {
  t : Array[(Int32, BigInt)]
}

///|
/// 規範化。
fn lp_norm(terms : Array[(Int32, BigInt)]) -> LPoly {
  let arr = terms
  arr.sort_by(fn(p, q) {
    let (a, _) = p
    let (b, _) = q
    a - b
  })
  let out : Array[(Int32, BigInt)] = []
  for i = 0; i < arr.length(); i = i + 1 {
    let (e, c) = arr[i]
    if out.length() > 0 {
      let (le, lc) = out[out.length() - 1]
      if le == e {
        out[out.length() - 1] = (le, lc + c)
        continue
      }
    }
    out.push((e, c))
  }
  let clean : Array[(Int32, BigInt)] = []
  for i = 0; i < out.length(); i = i + 1 {
    let (e, c) = out[i]
    if !c.is_zero() {
      clean.push((e, c))
    }
  }
  { t: clean, }
}

///|
pub fn lp_zero() -> LPoly {
  { t: [], }
}

///|
pub fn lp_one() -> LPoly {
  lp_norm([(0, BigInt::from_int(1))])
}

///|
pub fn lp_const(c : Int32) -> LPoly {
  lp_norm([(0, BigInt::from_int(c))])
}

///|
/// t（指數 1、係數 1）。
pub fn lp_t() -> LPoly {
  lp_norm([(1, BigInt::from_int(1))])
}

///|
pub fn lp_is_zero(p : LPoly) -> Bool {
  p.t.length() == 0
}

///|
/// 是否等於常數 1。
pub fn lp_is_one(p : LPoly) -> Bool {
  p.t.length() == 1 && p.t[0].0 == 0 && p.t[0].1 == BigInt::from_int(1)
}

///|
pub fn lp_neg(p : LPoly) -> LPoly {
  let out : Array[(Int32, BigInt)] = []
  for i = 0; i < p.t.length(); i = i + 1 {
    let (e, c) = p.t[i]
    out.push((e, -c))
  }
  lp_norm(out)
}

///|
pub fn lp_add(p : LPoly, q : LPoly) -> LPoly {
  lp_norm(p.t.copy() + q.t.copy())
}

///|
pub fn lp_sub(p : LPoly, q : LPoly) -> LPoly {
  lp_add(p, lp_neg(q))
}

///|
pub fn lp_mul(p : LPoly, q : LPoly) -> LPoly {
  let acc : Array[(Int32, BigInt)] = []
  for i = 0; i < p.t.length(); i = i + 1 {
    let (e1, c1) = p.t[i]
    for j = 0; j < q.t.length(); j = j + 1 {
      let (e2, c2) = q.t[j]
      acc.push((e1 + e2, c1 * c2))
    }
  }
  lp_norm(acc)
}

///|
pub fn lp_eq(p : LPoly, q : LPoly) -> Bool {
  if p.t.length() != q.t.length() {
    return false
  }
  for i = 0; i < p.t.length(); i = i + 1 {
    if p.t[i].0 != q.t[i].0 || p.t[i].1 != q.t[i].1 {
      return false
    }
  }
  true
}

///|
/// t = −1 特化。
pub fn lp_at_minus_one(p : LPoly) -> BigInt {
  let mut s = BigInt::from_int(0)
  for i = 0; i < p.t.length(); i = i + 1 {
    let (e, c) = p.t[i]
    let sign = if e % 2 == 0 { 1 } else { -1 }
    s = s + c * BigInt::from_int(sign)
  }
  s
}

// ---------------------------------------------------------------- 矩陣

///|
/// n×n 的 Laurent 矩陣。
pub struct LMat {
  n : Int32
  e : Array[Array[LPoly]]
}

///|
pub fn lm_identity(n : Int32) -> LMat {
  let rows : Array[Array[LPoly]] = []
  for i = 0; i < n; i = i + 1 {
    let row : Array[LPoly] = []
    for j = 0; j < n; j = j + 1 {
      row.push(if i == j { lp_one() } else { lp_zero() })
    }
    rows.push(row)
  }
  { n, e: rows, }
}

///|
/// 未約化 Burau 生成元 β_n(σ_i)（i = 1..n−1）。
pub fn burau_generator(n : Int32, i : Int32) -> LMat {
  let m = lm_identity(n)
  let a = i - 1
  let b = i
  // [[1−t, t],[1, 0]]
  m.e[a][a] = lp_sub(lp_one(), lp_t())
  m.e[a][b] = lp_t()
  m.e[b][a] = lp_one()
  m.e[b][b] = lp_zero()
  m
}

///|
pub fn lm_mul(x : LMat, y : LMat) -> LMat {
  let n = x.n
  let rows : Array[Array[LPoly]] = []
  for i = 0; i < n; i = i + 1 {
    let row : Array[LPoly] = []
    for j = 0; j < n; j = j + 1 {
      let mut acc = lp_zero()
      for k = 0; k < n; k = k + 1 {
        acc = lp_add(acc, lp_mul(x.e[i][k], y.e[k][j]))
      }
      row.push(acc)
    }
    rows.push(row)
  }
  { n, e: rows, }
}

///|
pub fn lm_eq(x : LMat, y : LMat) -> Bool {
  for i = 0; i < x.n; i = i + 1 {
    for j = 0; j < x.n; j = j + 1 {
      if !lp_eq(x.e[i][j], y.e[i][j]) {
        return false
      }
    }
  }
  true
}

///|
/// 行列式（餘因子展開；n ≤ 5 時足夠）。
pub fn lm_det(m : LMat) -> LPoly {
  let n = m.n
  if n == 1 {
    return m.e[0][0]
  }
  let mut acc = lp_zero()
  for j = 0; j < n; j = j + 1 {
    if lp_is_zero(m.e[0][j]) {
      continue
    }
    // 子矩陣
    let sub : Array[Array[LPoly]] = []
    for i = 1; i < n; i = i + 1 {
      let row : Array[LPoly] = []
      for k = 0; k < n; k = k + 1 {
        if k != j {
          row.push(m.e[i][k])
        }
      }
      sub.push(row)
    }
    let d = lm_det({ n: n - 1, e: sub, })
    let term = lp_mul(m.e[0][j], d)
    acc = lp_add(acc, if j % 2 == 0 { term } else { lp_neg(term) })
  }
  acc
}

///|
/// 字的 Burau 像。
pub fn burau_of_word(w : BraidWord) -> LMat {
  let mut m = lm_identity(w.n)
  for idx = 0; idx < w.letters.length(); idx = idx + 1 {
    let l = w.letters[idx]
    let i = if l > 0 { l } else { -l }
    let g = burau_generator(w.n, i)
    if l > 0 {
      m = lm_mul(m, g)
    } else {
      m = lm_mul(m, burau_inverse(n_of(g), i))
    }
  }
  m
}

///|
/// 生成元矩陣的大小。
pub fn n_of(m : LMat) -> Int32 {
  m.n
}

///|
/// β_n(σ_i)^{-1}：對 2×2 區塊直接求逆（[[0, 1],[t^{-1}, (1−t)t^{-1}]]）。
pub fn burau_inverse(n : Int32, i : Int32) -> LMat {
  let m = lm_identity(n)
  let a = i - 1
  let b = i
  let t_inv = lp_norm([(-1, BigInt::from_int(1))])
  m.e[a][a] = lp_zero()
  m.e[a][b] = lp_one()
  m.e[b][a] = t_inv
  m.e[b][b] = lp_mul(lp_sub(lp_one(), lp_t()), t_inv)
  m
}

///|
/// 辮關係在 Burau 層是否成立（n 給定，i = 1..n−2）。
pub fn burau_braid_relation(n : Int32, i : Int32) -> Bool {
  let a = lm_mul(
    lm_mul(burau_generator(n, i), burau_generator(n, i + 1)),
    burau_generator(n, i),
  )
  let b = lm_mul(
    lm_mul(burau_generator(n, i + 1), burau_generator(n, i)),
    burau_generator(n, i + 1),
  )
  lm_eq(a, b)
}

///|
/// 遠處生成元的交換律在 Burau 層是否成立（|i−j| ≥ 2）。
pub fn burau_commutes(n : Int32, i : Int32, j : Int32) -> Bool {
  let a = lm_mul(burau_generator(n, i), burau_generator(n, j))
  let b = lm_mul(burau_generator(n, j), burau_generator(n, i))
  lm_eq(a, b)
}

///|
/// t = −1 特化後的整數矩陣（n ≤ 5，元素小，BigInt 足夠）。
pub fn burau_specialize_minus_one(w : BraidWord) -> Array[Array[BigInt]] {
  let m = burau_of_word(w)
  let rows : Array[Array[BigInt]] = []
  for i = 0; i < m.n; i = i + 1 {
    let row : Array[BigInt] = []
    for j = 0; j < m.n; j = j + 1 {
      row.push(lp_at_minus_one(m.e[i][j]))
    }
    rows.push(row)
  }
  rows
}

///|
/// 長度 ≤ maxlen 的全部字（字母表 {σ1^±1, …, σ_{n−1}^±1}）中，有多少個非空字的 Burau 像為單位矩陣。
/// 這是**有界**檢核：0 表示在該長度範圍內沒有僞核，不代表忠實（文件與報表明示界限）。
pub fn burau_fake_kernels(n : Int32, maxlen : Int32) -> Int32 {
  let mut count = 0
  let mut stack : Array[Array[Int32]] = [[]]
  for _depth = 1; _depth <= maxlen; _depth = _depth + 1 {
    let next : Array[Array[Int32]] = []
    for wi = 0; wi < stack.length(); wi = wi + 1 {
      let w = stack[wi]
      for i = 1; i < n; i = i + 1 {
        for sgn = 0; sgn < 2; sgn = sgn + 1 {
          let l = if sgn == 0 { i } else { -i }
          let nw = w.copy()
          nw.push(l)
          next.push(nw)
          let m = burau_of_word(bw_make(n, nw))
          let mut is_id = true
          for r = 0; r < m.n; r = r + 1 {
            for c = 0; c < m.n; c = c + 1 {
              let want_one = r == c
              if want_one && !lp_is_one(m.e[r][c]) {
                is_id = false
              }
              if !want_one && !lp_is_zero(m.e[r][c]) {
                is_id = false
              }
            }
          }
          if is_id {
            count = count + 1
          }
        }
      }
    }
    stack = next
  }
  count
}
