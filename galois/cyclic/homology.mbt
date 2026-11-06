///|
/// B0008 / cyclic 套件：**Hochschild 與循環同調的維度**（三條路徑）
/// 對應 docs/B0008-定理體系.md §3（T51–T54、A55–A57）。
///
/// 每一條同調維度都用 `dim = 維數 − 秩(d_n) − 秩(d_{n+1})`，
/// 其中「秩」是 linalg.mbt 的 BigInt-Bareiss 精確秩（ℚ 上）。
///
/// 三條路徑：
///   1. HH：bar 複體（D-CY3）；
///   2. HC（雙複體路徑）：X_n = ⊕_{q≤n} C_q，D_n|_{C_q} = b_q + B_{q−1}；
///   3. HC（λ-複體路徑）：C^λ_n = C_n/im(1−λ_n)，b̄ 為誘導微分。
/// 路徑 2 與 3 是**兩條獨立路徑**，它們必須給出同一個 HC（T53）。

// ---------------------------------------------------------------- HH

///|
/// dim ker b_n − rank b_{n+1}（= dim HH_n）。
pub fn hh_dim(a : FdAlg, n : Int32) -> Int32 {
  let cn = chain_size(a, n)
  let rn = rank_q(bar_matrix(a, n))
  let rn1 = rank_q(bar_matrix(a, n + 1))
  cn - rn - rn1
}

///|
/// HH_0 的第二條路徑：HH_0 = A/[A,A]，維度 = dim A − dim(交換子張成空間)。
/// 這一條完全不碰 bar 複體（只碰結構常數），是 T51 的獨立檢核。
pub fn hh0_by_commutators(a : FdAlg) -> Int32 {
  let rows : Array[Array[Int64]] = []
  for i = 0; i < a.dim; i = i + 1 {
    for j = 0; j < a.dim; j = j + 1 {
      let v : Array[Int64] = []
      for k = 0; k < a.dim; k = k + 1 {
        v.push(fd_coeff(a, i, j, k) - fd_coeff(a, j, i, k))
      }
      rows.push(v)
    }
  }
  a.dim - span_dim(rows)
}

// ---------------------------------------------------------------- HC：雙複體路徑

///|
/// Tot_n = ⊕_{m ≤ n，m ≡ n (mod 2)} C_m 中，C_m 的起始行偏移（不在 Tot_n 中則回 −1）。
/// 為何是這個形狀：b: C_m → C_{m−1} 與 B: C_m → C_{m+1} 都必須落在 Tot_{n−1} 裡，
/// 而兩者都會把「m 的奇偶」翻轉一次，故 Tot_n 只收同奇偶的 m（D-CY6）。
pub fn total_offset(a : FdAlg, n : Int32, m : Int32) -> Int32 {
  if m < 0 || m > n || (n - m) % 2 != 0 {
    return -1
  }
  let mut off = 0
  let mut cur = n
  while cur > m {
    off = off + chain_size(a, cur)
    cur = cur - 2
  }
  off
}

///|
/// dim Tot_n。
pub fn total_dim(a : FdAlg, n : Int32) -> Int32 {
  let mut s = 0
  let mut m = n
  while m >= 0 {
    s = s + chain_size(a, m)
    m = m - 2
  }
  s
}

///|
/// 雙複體的總微分 D_n : Tot_n → Tot_{n−1}（列 = dim Tot_{n−1}、行 = dim Tot_n）。
/// 塊結構：C_m 的像 = b_m（落在 C_{m−1}）+ B_m（落在 C_{m+1}）。
pub fn total_diff(a : FdAlg, n : Int32) -> Array[Array[Int64]] {
  if n == 0 {
    return mat_zero(0, chain_size(a, 0))
  }
  let out = mat_zero(total_dim(a, n - 1), total_dim(a, n))
  let mut m = n
  while m >= 0 {
    let col_off = total_offset(a, n, m)
    // b_m : C_m → C_{m−1}
    let row_b = total_offset(a, n - 1, m - 1)
    if row_b >= 0 {
      let bm = bar_matrix(a, m)
      for i = 0; i < mat_rows(bm); i = i + 1 {
        for j = 0; j < mat_cols(bm); j = j + 1 {
          out[row_b + i][col_off + j] = out[row_b + i][col_off + j] + bm[i][j]
        }
      }
    }
    // B_m : C_m → C_{m+1}
    let row_B = total_offset(a, n - 1, m + 1)
    if row_B >= 0 {
      let bmat_up = connes_B(a, m)
      for i = 0; i < mat_rows(bmat_up); i = i + 1 {
        for j = 0; j < mat_cols(bmat_up); j = j + 1 {
          out[row_B + i][col_off + j] = out[row_B + i][col_off + j] +
            bmat_up[i][j]
        }
      }
    }
    m = m - 2
  }
  out
}

///|
/// HC_n（雙複體路徑）：dim Tot_n − rank D_n − rank D_{n+1}。
pub fn hc_dim_bicomplex(a : FdAlg, n : Int32) -> Int32 {
  let xn = total_dim(a, n)
  let rn = rank_q(total_diff(a, n))
  let rn1 = rank_q(total_diff(a, n + 1))
  xn - rn - rn1
}

// ---------------------------------------------------------------- HC：λ-複體路徑

///|
/// dim C^λ_n = dim C_n − rank(1 − τ_n)，其中 **τ_n 是無符號循環置換**。
/// 這是 λ-複體的項（商掉 im(1−τ_n)）。
pub fn lambda_chain_dim(a : FdAlg, n : Int32) -> Int32 {
  chain_size(a, n) - rank_q(id_minus_tau(a, n))
}

///|
/// 誘導微分 b̄_n : C^λ_n → C^λ_{n−1} 的秩。
/// b 把 im(1−τ_n) 送進 im(1−τ_{n−1})（因 b(1−τ) = (1−τ)b′），故誘導良定義；
/// 其在商上的秩 = rank(K_{n−1} + im b_n) − rank(K_{n−1})，K_m = im(1−τ_m)。
pub fn lambda_bar_rank(a : FdAlg, n : Int32) -> Int32 {
  if n == 0 {
    return 0
  }
  let k = id_minus_tau(a, n - 1)
  let b = bar_matrix(a, n)
  rank_q(mat_hcat(k, b)) - rank_q(k)
}

///|
/// **HC_n（λ-複體路徑）**：C^λ_n = C_n/im(1−τ_n)，微分 b̄_n。
/// HC_n = dim C^λ_n − rank b̄_n − rank b̄_{n+1}。
pub fn hc_dim_lambda(a : FdAlg, n : Int32) -> Int32 {
  lambda_chain_dim(a, n) - lambda_bar_rank(a, n) - lambda_bar_rank(a, n + 1)
}

///|
/// **負控制**：把循環算子換成有符號的 λ_n = (−1)^n τ_n 的同一個公式。
/// 它在 k、k[x]/x² 等樣本上給出與 HC 不同的值（甚至負值），
/// 證明「商掉 im(1 − (−1)^n t_n)」不是 HC 的正確模型（BUG-22）。
pub fn hc_dim_lambda_signed(a : FdAlg, n : Int32) -> Int32 {
  let chain = chain_size(a, n) - rank_q(id_minus_lambda(a, n))
  let bar0 = if n == 0 {
    0
  } else {
    let k = id_minus_lambda(a, n - 1)
    rank_q(mat_hcat(k, bar_matrix(a, n))) - rank_q(k)
  }
  let k2 = id_minus_lambda(a, n)
  let bar1 = rank_q(mat_hcat(k2, bar_matrix(a, n + 1))) - rank_q(k2)
  chain - bar0 - bar1
}

// ---------------------------------------------------------------- 結構性檢核

///|
/// b∘b = 0：逐度驗 b_n ∘ b_{n+1} = 0（n = 1..top）。
/// 度數上限由 chain_size 的記憶體成本決定（見 docs/B0008 §B9）。
pub fn check_b_squared_zero(a : FdAlg, top : Int32) -> Bool {
  let mut ok = true
  for n = 1; n <= top; n = n + 1 {
    if !mat_is_zero(mat_mul(bar_matrix(a, n), bar_matrix(a, n + 1))) {
      ok = false
    }
  }
  ok
}

///|
/// bB + Bb = 0：逐度驗 b_{n+1} ∘ B_n + B_{n−1} ∘ b_n = 0（n = 0..top，n = 0 時第二項為 0）。
/// 這一條固定 Connes 算子 B 的符號慣例。
pub fn check_bB_anticommute(a : FdAlg, top : Int32) -> Bool {
  let mut ok = true
  for n = 0; n <= top; n = n + 1 {
    let mut m = mat_mul(bar_matrix(a, n + 1), connes_B(a, n))
    if n >= 1 {
      m = mat_add(m, mat_mul(connes_B(a, n - 1), bar_matrix(a, n)))
    }
    if !mat_is_zero(m) {
      ok = false
    }
  }
  ok
}

///|
/// 總微分的平方 = 0：逐度驗 D_n ∘ D_{n+1} = 0（n = 1..top）。
pub fn check_total_squared_zero(a : FdAlg, top : Int32) -> Bool {
  let mut ok = true
  for n = 1; n <= top; n = n + 1 {
    if !mat_is_zero(mat_mul(total_diff(a, n), total_diff(a, n + 1))) {
      ok = false
    }
  }
  ok
}
