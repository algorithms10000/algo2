///|
/// B0008 / cyclic 套件：**有限維結合代數的模型**（循環同調的輸入）
/// 對應 docs/B0008-定理體系.md §2（D-CY1–D-CY6、A53）。
///
/// 為什麼用「結構常數」而不是抽像代數：
/// 循環同調只依賴代數的乘法常數（bar 複體是 A^{⊗(n+1)} 上的純組合構造），
/// 所以把代數寫成一張整數表就足夠**精確**地算出 HH/HC。所有樣本代數
/// （k[x]/(x^m)、ℂ[ℤ/n]、M_n、ℂ[S₃]、ℂ[D₈] 及其張量積）的結構常數都是 0/±1，整數封閉。

///|
/// 有限維結合代數：`mult[(i*dim + j)*dim + k]` = 基底元素 e_k 在 e_i·e_j 中的係數。
pub struct FdAlg {
  name : String
  dim : Int32
  /// 單位元的座標（一般不是單一基底元素：M_n 的單位是 Σ_i E_ii）
  unit_vec : Array[Int64]
  /// 增廣 ε 的座標（ε(e_k)）；無增廣時全零（如 M_n(ℂ)，n ≥ 2）
  aug : Array[Int64]
  mult : Array[Int64]
}

///|
/// 構造。
pub fn fd_alg(
  name : String,
  dim : Int32,
  unit_vec : Array[Int64],
  aug : Array[Int64],
  mult : Array[Int64],
) -> FdAlg {
  { name, dim, unit_vec, aug, mult, }
}

///|
/// 全零向量（輔助）。
pub fn zero_vec(n : Int32) -> Array[Int64] {
  let out : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    out.push(0L)
  }
  out
}

///|
/// 全一向量（群代數的增廣）。
pub fn ones_vec(n : Int32) -> Array[Int64] {
  let out : Array[Int64] = []
  for i = 0; i < n; i = i + 1 {
    out.push(1L)
  }
  out
}

///|
/// 單位向量：只有第 idx 個基底元素為 1。
pub fn unit_basis(dim : Int32, idx : Int32) -> Array[Int64] {
  let out : Array[Int64] = []
  for i = 0; i < dim; i = i + 1 {
    out.push(if i == idx { 1L } else { 0L })
  }
  out
}

///|
/// 零結構常數表。
pub fn fd_mult_zero(dim : Int32) -> Array[Int64] {
  let out : Array[Int64] = []
  for _i = 0; _i < dim * dim * dim; _i = _i + 1 {
    out.push(0L)
  }
  out
}

///|
/// 設一個結構常數。
pub fn fd_set(
  m : Array[Int64],
  dim : Int32,
  i : Int32,
  j : Int32,
  k : Int32,
  c : Int64,
) -> Unit {
  m[(i * dim + j) * dim + k] = c
}

///|
/// 讀一個結構常數。
pub fn fd_coeff(a : FdAlg, i : Int32, j : Int32, k : Int32) -> Int64 {
  a.mult[(i * a.dim + j) * a.dim + k]
}

// ---------------------------------------------------------------- 樣本代數

///|
/// k[x]/(x^m)：基底 1, x, …, x^{m−1}；e_i·e_j = e_{i+j}（若 i+j < m，否則 0）。
/// 這是「非光滑」的標準樣本：m = 2 是雙數 ℂ[ε]/ε²。
pub fn alg_polys(m : Int32) -> FdAlg {
  let mult = fd_mult_zero(m)
  for i = 0; i < m; i = i + 1 {
    for j = 0; j < m; j = j + 1 {
      let s = i + j
      if s < m {
        fd_set(mult, m, i, j, s, 1L)
      }
    }
  }
  fd_alg(
    "k[x]/(x^" + m.to_string() + ")",
    m,
    unit_basis(m, 0),
    unit_basis(m, 0),
    mult,
  )
}

///|
/// ℤ/n 的 Cayley 表：table[i*n + j] = (i + j) mod n。
pub fn cyclic_group_table(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      out.push((i + j) % n)
    }
  }
  out
}

///|
/// ℂ[ℤ/n] ≅ k[x]/(x^n − 1)：e_i·e_j = e_{(i+j) mod n}。
pub fn alg_cyclic_group(n : Int32) -> FdAlg {
  let mult = fd_mult_zero(n)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      fd_set(mult, n, i, j, (i + j) % n, 1L)
    }
  }
  fd_alg(
    "ℂ[ℤ/" + n.to_string() + "]",
    n,
    unit_basis(n, 0),
    ones_vec(n),
    mult,
  )
}

///|
/// M_n(ℂ)：基底 E_{pq}（索引 p*n+q），E_{pq}·E_{rs} = δ_{qr} E_{ps}。
pub fn alg_matrix(n : Int32) -> FdAlg {
  let d = n * n
  let mult = fd_mult_zero(d)
  for p = 0; p < n; p = p + 1 {
    for q = 0; q < n; q = q + 1 {
      for r = 0; r < n; r = r + 1 {
        for s = 0; s < n; s = s + 1 {
          if q == r {
            fd_set(mult, d, p * n + q, r * n + s, p * n + s, 1L)
          }
        }
      }
    }
  }
  let unit_vec : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    unit_vec.push(0L)
  }
  for i = 0; i < n; i = i + 1 {
    unit_vec[i * n + i] = 1L
  }
  fd_alg("M_" + n.to_string() + "(ℂ)", d, unit_vec, zero_vec(d), mult)
}

///|
/// 由 Cayley 表構造群代數 ℂ[G]：`table[i*n + j]` = e_i·e_j 的下標。
pub fn alg_group(name : String, n : Int32, table : Array[Int32]) -> FdAlg {
  let mult = fd_mult_zero(n)
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      fd_set(mult, n, i, j, table[i * n + j], 1L)
    }
  }
  fd_alg(name, n, unit_basis(n, 0), ones_vec(n), mult)
}

///|
/// S₃ 的 Cayley 表（元素按 [(), (12), (13), (23), (123), (132)] 排列，以 3 個點的置換合成）。
pub fn symmetric_group3_table() -> Array[Int32] {
  // 以「字串鍵 → 下標」查表，避免手寫 36 個格子出錯
  let elts : Array[Array[Int32]] = [
    [0, 1, 2],
    [1, 0, 2],
    [2, 1, 0],
    [0, 2, 1],
    [1, 2, 0],
    [2, 0, 1],
  ]
  let out : Array[Int32] = []
  for i = 0; i < 6; i = i + 1 {
    for j = 0; j < 6; j = j + 1 {
      // (p·q)(x) = p(q(x))
      let comp : Array[Int32] = [
        elts[i][elts[j][0]],
        elts[i][elts[j][1]],
        elts[i][elts[j][2]],
      ]
      let mut idx = -1
      for k = 0; k < 6; k = k + 1 {
        if elts[k][0] == comp[0] &&
          elts[k][1] == comp[1] &&
          elts[k][2] == comp[2] {
          idx = k
        }
      }
      out.push(idx)
    }
  }
  out
}

///|
/// ℂ[S₃]。
pub fn alg_symmetric_group3() -> FdAlg {
  alg_group("ℂ[S₃]", 6, symmetric_group3_table())
}

///|
/// D₈ 的 Cayley 表：元素為 (r^i, s^j)，i < 4、j < 2，索引 = i*2 + j；
/// 乘法 rs = sr³（即 s r = r³ s）。
pub fn dihedral8_table() -> Array[Int32] {
  // 以「(i,j) 對」計算： (i1,j1)·(i2,j2)：
  //   若 j1 = 0 → (i1+i2, j2)；若 j1 = 1 → r^i1 s · r^i2 s^j2 = r^(i1−i2) s^(1+j2)
  let out : Array[Int32] = []
  for a = 0; a < 8; a = a + 1 {
    for b = 0; b < 8; b = b + 1 {
      let i1 = a / 2
      let j1 = a % 2
      let i2 = b / 2
      let j2 = b % 2
      let idx = if j1 == 0 {
        (i1 + i2) % 4 * 2 + j2
      } else {
        (i1 - i2 + 8) % 4 * 2 + (1 + j2) % 2
      }
      out.push(idx)
    }
  }
  out
}

///|
/// ℂ[D₈]。
pub fn alg_dihedral8() -> FdAlg {
  alg_group("ℂ[D₈]", 8, dihedral8_table())
}

///|
/// 直和 A ⊕ B（乘法按分量）。
pub fn alg_direct_sum(a : FdAlg, b : FdAlg) -> FdAlg {
  let d = a.dim + b.dim
  let mult = fd_mult_zero(d)
  for i = 0; i < a.dim; i = i + 1 {
    for j = 0; j < a.dim; j = j + 1 {
      for k = 0; k < a.dim; k = k + 1 {
        fd_set(mult, d, i, j, k, fd_coeff(a, i, j, k))
      }
    }
  }
  for i = 0; i < b.dim; i = i + 1 {
    for j = 0; j < b.dim; j = j + 1 {
      for k = 0; k < b.dim; k = k + 1 {
        fd_set(mult, d, a.dim + i, a.dim + j, a.dim + k, fd_coeff(b, i, j, k))
      }
    }
  }
  let unit_vec : Array[Int64] = []
  for i = 0; i < a.dim; i = i + 1 {
    unit_vec.push(a.unit_vec[i])
  }
  for i = 0; i < b.dim; i = i + 1 {
    unit_vec.push(b.unit_vec[i])
  }
  let aug : Array[Int64] = []
  for i = 0; i < a.dim; i = i + 1 {
    aug.push(a.aug[i])
  }
  for i = 0; i < b.dim; i = i + 1 {
    aug.push(b.aug[i])
  }
  fd_alg(a.name + " ⊕ " + b.name, d, unit_vec, aug, mult)
}

///|
/// **張量積 A ⊗ B**（本輪「內部張量積」的代數側）：基底 e_i⊗f_p（索引 i*b.dim + p），
/// (e_i⊗f_p)(e_j⊗f_q) = (e_i e_j)⊗(f_p f_q)。結構常數為整數（因兩邊都是）。
pub fn alg_tensor(a : FdAlg, b : FdAlg) -> FdAlg {
  let da = a.dim
  let db = b.dim
  let d = da * db
  let mult = fd_mult_zero(d)
  for i = 0; i < da; i = i + 1 {
    for p = 0; p < db; p = p + 1 {
      for j = 0; j < da; j = j + 1 {
        for q = 0; q < db; q = q + 1 {
          for k = 0; k < da; k = k + 1 {
            let ca = fd_coeff(a, i, j, k)
            if ca != 0L {
              for s = 0; s < db; s = s + 1 {
                let cb = fd_coeff(b, p, q, s)
                if cb != 0L {
                  fd_set(mult, d, i * db + p, j * db + q, k * db + s, ca * cb)
                }
              }
            }
          }
        }
      }
    }
  }
  let unit_vec : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    unit_vec.push(0L)
  }
  for i = 0; i < da; i = i + 1 {
    for p = 0; p < db; p = p + 1 {
      unit_vec[i * db + p] = a.unit_vec[i] * b.unit_vec[p]
    }
  }
  let aug : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    aug.push(0L)
  }
  for i = 0; i < da; i = i + 1 {
    for p = 0; p < db; p = p + 1 {
      aug[i * db + p] = a.aug[i] * b.aug[p]
    }
  }
  fd_alg(a.name + " ⊗ " + b.name, d, unit_vec, aug, mult)
}

///|
/// 單位的驗證：u·e_i = e_i = e_i·u（u = Σ_k u_k e_k，以結構常數展開）。
pub fn alg_unit_ok(a : FdAlg) -> Bool {
  let mut ok = true
  for i = 0; i < a.dim; i = i + 1 {
    for k = 0; k < a.dim; k = k + 1 {
      let want = if i == k { 1L } else { 0L }
      let mut left = 0L
      let mut right = 0L
      for m = 0; m < a.dim; m = m + 1 {
        left = left + a.unit_vec[m] * fd_coeff(a, m, i, k)
        right = right + a.unit_vec[m] * fd_coeff(a, i, m, k)
      }
      if left != want || right != want {
        ok = false
      }
    }
  }
  ok
}

///|
/// 結合律的驗證：(e_i e_j) e_k = e_i (e_j e_k)（逐步以結構常數展開）。
pub fn alg_assoc_ok(a : FdAlg) -> Bool {
  let mut ok = true
  for i = 0; i < a.dim; i = i + 1 {
    for j = 0; j < a.dim; j = j + 1 {
      for k = 0; k < a.dim; k = k + 1 {
        for s = 0; s < a.dim; s = s + 1 {
          // (e_i e_j) e_k 在 e_s 的係數
          let left = mul3_left(a, i, j, k, s)
          let right = mul3_right(a, i, j, k, s)
          if left != right {
            ok = false
          }
        }
      }
    }
  }
  ok
}

///|
/// (e_i e_j) e_k 的 e_s 係數。
fn mul3_left(a : FdAlg, i : Int32, j : Int32, k : Int32, s : Int32) -> Int64 {
  let mut acc = 0L
  for m = 0; m < a.dim; m = m + 1 {
    let c1 = fd_coeff(a, i, j, m)
    if c1 != 0L {
      acc = acc + c1 * fd_coeff(a, m, k, s)
    }
  }
  acc
}

///|
/// e_i (e_j e_k) 的 e_s 係數。
fn mul3_right(a : FdAlg, i : Int32, j : Int32, k : Int32, s : Int32) -> Int64 {
  let mut acc = 0L
  for m = 0; m < a.dim; m = m + 1 {
    let c1 = fd_coeff(a, j, k, m)
    if c1 != 0L {
      acc = acc + c1 * fd_coeff(a, i, m, s)
    }
  }
  acc
}

///|
/// 顯示。
pub fn alg_render(a : FdAlg) -> String {
  a.name + "（dim = " + a.dim.to_string() + "）"
}
