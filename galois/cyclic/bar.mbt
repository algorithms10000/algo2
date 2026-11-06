///|
/// B0008 / cyclic 套件：**Hochschild 複體、Connes 算子 B、λ-算子**
/// 對應 docs/B0008-定理體系.md §2（D-CY3–D-CY7、A54）。
///
/// 定義（D-CY3）：C_n(A) = A^{⊗(n+1)}，微分
///   b(a₀⊗…⊗a_n) = Σ_{i<n} (−1)^i (a₀⊗…⊗a_i a_{i+1}⊗…⊗a_n) + (−1)^n (a_n a₀⊗a₁⊗…⊗a_{n−1})
/// Hochschild 同調 HH_n = ker b_n / im b_{n+1}。
///
/// 定義（D-CY4）：t(a₀⊗…⊗a_n) = (−1)^n (a_n⊗a₀⊗…⊗a_{n−1})，N = 1 + t + … + tⁿ，
///   s(a₀⊗…⊗a_n) = 1⊗a₀⊗…⊗a_n，**B = (1 − t) s N**：C_n → C_{n+1}。
///   （B 的符號慣例不靠記憶決定：程式裡直接驗 bB + Bb = 0。）
/// 定義（D-CY5）：λ_n = (−1)^n t_n；λ-複體 C^λ_n = C_n / im(1 − λ_n)。

// ---------------------------------------------------------------- 組合索引

///|
/// 整數冪。
pub fn pow_int(d : Int32, n : Int32) -> Int32 {
  let mut p = 1
  for _i = 0; _i < n; _i = _i + 1 {
    p = p * d
  }
  p
}

///|
/// dim C_n = d^{n+1}。
pub fn chain_size(a : FdAlg, n : Int32) -> Int32 {
  pow_int(a.dim, n + 1)
}

///|
/// 把 C_n 的基底下標展開成 n+1 個代數基底下標（base-d 展開，低位在前）。
pub fn tuple_of(d : Int32, n : Int32, idx : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut x = idx
  for _i = 0; _i < n + 1; _i = _i + 1 {
    out.push(x % d)
    x = x / d
  }
  out
}

///|
/// 反函數：由 n+1 個下標算回線性下標。
pub fn tuple_index(d : Int32, t : Array[Int32]) -> Int32 {
  let mut idx = 0
  let mut p = 1
  for i = 0; i < t.length(); i = i + 1 {
    idx = idx + t[i] * p
    p = p * d
  }
  idx
}

// ---------------------------------------------------------------- b 算子

///|
/// **Hochschild 微分** b_n : C_n → C_{n−1}（列 = dim C_{n−1}，行 = dim C_n）。
pub fn bar_matrix(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  if n == 0 {
    return mat_zero(0, chain_size(a, 0))
  }
  let d = a.dim
  let out = mat_zero(chain_size(a, n - 1), chain_size(a, n))
  let sign_n : Int64 = if n % 2 == 0 { 1L } else { -1L }
  for src = 0; src < chain_size(a, n); src = src + 1 {
    let t = tuple_of(d, n, src)
    for i = 0; i < n; i = i + 1 {
      let sg : Int64 = if i % 2 == 0 { 1L } else { -1L }
      for k = 0; k < d; k = k + 1 {
        let c = fd_coeff(a, t[i], t[i + 1], k)
        if c != 0L {
          let tgt : Array[Int32] = []
          for j = 0; j < i; j = j + 1 {
            tgt.push(t[j])
          }
          tgt.push(k)
          for j = i + 2; j < n + 1; j = j + 1 {
            tgt.push(t[j])
          }
          let row = tuple_index(d, tgt)
          out[row][src] = out[row][src] + sg * c
        }
      }
    }
    for k = 0; k < d; k = k + 1 {
      let c = fd_coeff(a, t[n], t[0], k)
      if c != 0L {
        let tgt : Array[Int32] = [k]
        for j = 1; j < n; j = j + 1 {
          tgt.push(t[j])
        }
        let row = tuple_index(d, tgt)
        out[row][src] = out[row][src] + sign_n * c
      }
    }
  }
  out
}

// ---------------------------------------------------------------- t、s、N、B

///|
/// t 作用在基元組上：回傳 (符號, 新元組)。
fn act_t(n : Int32, t : Array[Int32]) -> (Int64, Array[Int32]) {
  let sg : Int64 = if n % 2 == 0 { 1L } else { -1L }
  let out : Array[Int32] = [t[n]]
  for j = 0; j < n; j = j + 1 {
    out.push(t[j])
  }
  (sg, out)
}

///|
/// **Connes 算子 B_n** : C_n → C_{n+1}，B = (1 − t) s N（列 = dim C_{n+1}，行 = dim C_n）。
pub fn connes_B(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  let d = a.dim
  let out = mat_zero(chain_size(a, n + 1), chain_size(a, n))
  for src = 0; src < chain_size(a, n); src = src + 1 {
    // N = Σ_{i=0}^{n} t^i
    let mut cur = tuple_of(d, n, src)
    let mut sg : Int64 = 1L
    for _i = 0; _i <= n; _i = _i + 1 {
      // s：前插單位 u = Σ_k u_k e_k（一般不是單一基底元素！M_n 的單位是 Σ E_ii）
      for k = 0; k < d; k = k + 1 {
        let uk = a.unit_vec[k]
        if uk != 0L {
          let s_vec : Array[Int32] = [k]
          for x in cur {
            s_vec.push(x)
          }
          let row1 = tuple_index(d, s_vec)
          out[row1][src] = out[row1][src] + sg * uk
          let (st, tvec) = act_t(n + 1, s_vec)
          let row2 = tuple_index(d, tvec)
          out[row2][src] = out[row2][src] - sg * st * uk
        }
      }
      // 下一次迭代：t 作用在 cur 上
      let (sc, nxt) = act_t(n, cur)
      cur = nxt
      sg = sg * sc
    }
  }
  out
}

///|
/// 循環置換算子 t_n 的矩陣（C_n → C_n）：t_n(a_0⊗…⊗a_n) = a_n⊗a_0⊗…⊗a_{n−1}。
/// 它是 (ℤ/(n+1))-作用，滿足 t_n^{n+1} = id（`check_tau_order` 檢核）。
pub fn tau_matrix(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  let d = a.dim
  let out = mat_zero(chain_size(a, n), chain_size(a, n))
  for src = 0; src < chain_size(a, n); src = src + 1 {
    let (sg, tvec) = act_t(n, tuple_of(d, n, src))
    out[tuple_index(d, tvec)][src] = sg
  }
  out
}

///|
/// 標準有符號循環算子 λ_n = (−1)^n t_n。
pub fn lambda_matrix(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  let sg : Int64 = if n % 2 == 0 { 1L } else { -1L }
  mat_scale(tau_matrix(a, n), sg)
}

///|
/// (1 − λ_n)：其像 K_n ⊂ C_n 就是 λ-商掉的子空間。
pub fn id_minus_lambda(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  mat_add(mat_identity(chain_size(a, n)), mat_scale(lambda_matrix(a, n), -1L))
}

///|
/// (1 − t_n)：無符號版本的商，用於負控制（見 `lambda_quotient_*` 的說明）。
pub fn id_minus_tau(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  mat_add(mat_identity(chain_size(a, n)), mat_scale(tau_matrix(a, n), -1L))
}

///|
/// t_n 的 (n+1) 次方是否為恆等（循環算子的階為 n+1）。
pub fn check_tau_order(a : FdAlg) -> Bool {
  let mut ok = true
  for n = 0; n <= 3; n = n + 1 {
    let t = tau_matrix(a, n)
    let mut acc = mat_identity(chain_size(a, n))
    for k = 0; k < n + 1; k = k + 1 {
      acc = mat_mul(acc, t)
    }
    if !mat_eq(acc, mat_identity(chain_size(a, n))) {
      ok = false
    }
  }
  ok
}
