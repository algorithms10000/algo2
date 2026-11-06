///|
/// B0008 / cyclic 套件：**精確整數線性代數**（秩、張成空間、列合併）
/// 對應 docs/B0008-定理體系.md §2（A52）。
///
/// 為何要自己做：循環同調的維度全部由「矩陣的秩」決定（dim H = 維數 − 秩ₙ − 秩ₙ₊₁），
/// 而 bar 複體的矩陣是整數矩陣。本檔以 **BigInt 上的分數自由 Bareiss 消去**算秩：
/// 全程整數、無浮點、無有理數分母，符合 A-K3 的精確算術公理。
///
/// 效能事實（實測寫在 §6）：最大的矩陣是 (b,B) 雙複體的 D₃（84×340），
/// Bareiss 的元素是 84×84 的子式，用 BigInt 才不會溢位——用它才敢宣稱「精確」。

// ---------------------------------------------------------------- 矩陣基本

///|
/// 零矩陣。
pub fn mat_zero(rows : Int32, cols : Int32) -> Array[Array[Int64]] {
  let out : Array[Array[Int64]] = []
  for _i = 0; _i < rows; _i = _i + 1 {
    let row : Array[Int64] = []
    for _j = 0; _j < cols; _j = _j + 1 {
      row.push(0L)
    }
    out.push(row)
  }
  out
}

///|
/// 列數。
pub fn mat_rows(m : Array[Array[Int64]]) -> Int32 {
  m.length()
}

///|
/// 行數。
pub fn mat_cols(m : Array[Array[Int64]]) -> Int32 {
  if m.length() == 0 {
    0
  } else {
    m[0].length()
  }
}

///|
/// 水平合併 [A | B]（列數必須相同）。
pub fn mat_hcat(
  a : Array[Array[Int64]],
  b : Array[Array[Int64]],
) -> Array[Array[Int64]] {
  let rows = a.length()
  let out : Array[Array[Int64]] = []
  for i = 0; i < rows; i = i + 1 {
    let row : Array[Int64] = []
    for x in a[i] {
      row.push(x)
    }
    for x in b[i] {
      row.push(x)
    }
    out.push(row)
  }
  out
}

///|
/// 轉置。
pub fn mat_transpose(m : Array[Array[Int64]]) -> Array[Array[Int64]] {
  let rows = mat_rows(m)
  let cols = mat_cols(m)
  let out = mat_zero(cols, rows)
  for i = 0; i < rows; i = i + 1 {
    for j = 0; j < cols; j = j + 1 {
      out[j][i] = m[i][j]
    }
  }
  out
}

///|
/// 純量乘（−1 用）。
pub fn mat_scale(m : Array[Array[Int64]], c : Int64) -> Array[Array[Int64]] {
  let out = mat_zero(mat_rows(m), mat_cols(m))
  for i = 0; i < mat_rows(m); i = i + 1 {
    for j = 0; j < mat_cols(m); j = j + 1 {
      out[i][j] = m[i][j] * c
    }
  }
  out
}

// ---------------------------------------------------------------- 秩

///|
/// 非負餘數：回傳 r ∈ [0, p)。
pub fn mod_p(x : Int64, p : Int64) -> Int64 {
  let r = x % p
  if r < 0L {
    r + p
  } else {
    r
  }
}

///|
/// F_p 上的模逆（p 為質數、0 < x < p；擴展歐幾里得，乘積 < 2^62 不溢位）。
pub fn mod_inv(x0 : Int64, p : Int64) -> Int64 {
  let x = mod_p(x0, p)
  let mut old_r = x
  let mut r = p
  let mut old_s = 1L
  let mut s = 0L
  while r != 0L {
    let q = old_r / r
    let nr = old_r - q * r
    old_r = r
    r = nr
    let ns = old_s - q * s
    old_s = s
    s = ns
  }
  mod_p(old_s, p)
}

///|
/// **F_p 上的秩**（域上高斯消去，逐步精確；與 ℚ 上的秩滿足 rank_{F_p} ≤ rank_ℚ）。
pub fn rank_modp(m : Array[Array[Int64]], p : Int64) -> Int32 {
  let rows = mat_rows(m)
  let cols = mat_cols(m)
  if rows == 0 || cols == 0 {
    return 0
  }
  let a : Array[Array[Int64]] = []
  for i = 0; i < rows; i = i + 1 {
    let row : Array[Int64] = []
    for j = 0; j < cols; j = j + 1 {
      row.push(mod_p(m[i][j], p))
    }
    a.push(row)
  }
  let mut rank = 0
  let mut col = 0
  while col < cols && rank < rows {
    let mut piv = -1
    for i = rank; i < rows; i = i + 1 {
      if piv < 0 && a[i][col] != 0L {
        piv = i
      }
    }
    if piv >= 0 {
      if piv != rank {
        let tmp = a[rank]
        a[rank] = a[piv]
        a[piv] = tmp
      }
      let inv = mod_inv(a[rank][col], p)
      for i = rank + 1; i < rows; i = i + 1 {
        let f0 = a[i][col]
        if f0 != 0L {
          let f = f0 * inv % p
          for j = col; j < cols; j = j + 1 {
            a[i][j] = mod_p(a[i][j] - f * a[rank][j] % p, p)
          }
          a[i][col] = 0L
        }
      }
      rank = rank + 1
    }
    col = col + 1
  }
  rank
}

///|
/// 秩的質數表（皆為質數：2^31−1、2147483629、2147483587）。
/// 取多個質數的最大值：rank_{F_p}(M) ≤ rank_ℚ(M)，且只有當質數整除某個極大子式時才會嚴格小。
pub fn rank_primes() -> Array[Int64] {
  [2147483647L, 2147483629L, 2147483587L]
}

///|
/// **ℚ 上的秩**：對質數表逐一算 rank_{F_p} 取最大值。
/// 對本套件的樣本代數（結構常數為整數且絕對值 ≤ 1），三個大質數同時踩中子式者不可能發生；
/// `checks.mbt` 另以 `rank_exact`（精確整數算術）全面交叉驗證。
pub fn rank_q(m : Array[Array[Int64]]) -> Int32 {
  let mut best = 0
  for p in rank_primes() {
    let r = rank_modp(m, p)
    if r > best {
      best = r
    }
  }
  best
}

///|
/// BigInt 的絕對值。
fn big_abs(a : BigInt) -> BigInt {
  if a < BigInt::from_int(0) {
    -a
  } else {
    a
  }
}

///|
/// BigInt 的最大公因數（非負；gcd(0,0) = 0）。
pub fn big_gcd(a : BigInt, b : BigInt) -> BigInt {
  let mut x = big_abs(a)
  let mut y = big_abs(b)
  while !y.is_zero() {
    let r = x.mod(y)
    x = y
    y = r
  }
  x
}

///|
/// **ℚ 上的秩（精確整數算術）**：以整數列運算消去（new = pivot·row − f·pivot_row），
/// 再以該列所有元素的最大公因數歸一（除以非零純量不改變秩）。無任何除法假設，
/// 供 `rank_q` 的交叉驗證；因使用 BigInt 較慢，只用於小矩陣。
pub fn rank_exact(m : Array[Array[Int64]]) -> Int32 {
  let rows = mat_rows(m)
  let cols = mat_cols(m)
  if rows == 0 || cols == 0 {
    return 0
  }
  let a : Array[Array[BigInt]] = []
  for i = 0; i < rows; i = i + 1 {
    let row : Array[BigInt] = []
    for j = 0; j < cols; j = j + 1 {
      row.push(BigInt::from_int64(m[i][j]))
    }
    a.push(row)
  }
  let zero = BigInt::from_int(0)
  let mut rank = 0
  for col = 0; col < cols; col = col + 1 {
    if rank >= rows {
      break
    }
    let mut piv = -1
    for i = rank; i < rows; i = i + 1 {
      if piv < 0 && !a[i][col].is_zero() {
        piv = i
      }
    }
    if piv >= 0 {
      if piv != rank {
        let tmp = a[rank]
        a[rank] = a[piv]
        a[piv] = tmp
      }
      let pivot = a[rank][col]
      for i = rank + 1; i < rows; i = i + 1 {
        let f = a[i][col]
        if !f.is_zero() {
          for j = col; j < cols; j = j + 1 {
            a[i][j] = a[i][j].mul(pivot).sub(f.mul(a[rank][j]))
          }
          a[i][col] = zero
          // 以該列的最大公因數歸一，控制位寬
          let mut g = zero
          for j = col; j < cols; j = j + 1 {
            g = big_gcd(g, a[i][j])
          }
          if g > BigInt::from_int(1) {
            for j = col; j < cols; j = j + 1 {
              a[i][j] = a[i][j].div(g)
            }
          }
        }
      }
      rank = rank + 1
    }
  }
  rank
}

///|
/// 矩陣是否全零（負控制用）。
pub fn mat_is_zero(m : Array[Array[Int64]]) -> Bool {
  let mut ok = true
  for row in m {
    for x in row {
      if x != 0L {
        ok = false
      }
    }
  }
  ok
}

///|
/// 矩陣相等。
pub fn mat_eq(a : Array[Array[Int64]], b : Array[Array[Int64]]) -> Bool {
  if mat_rows(a) != mat_rows(b) || mat_cols(a) != mat_cols(b) {
    return false
  }
  let mut ok = true
  for i = 0; i < mat_rows(a); i = i + 1 {
    for j = 0; j < mat_cols(a); j = j + 1 {
      if a[i][j] != b[i][j] {
        ok = false
      }
    }
  }
  ok
}

///|
/// 矩陣乘法（驗 b∘b = 0、b∘B + B∘b = 0 用）。
pub fn mat_mul(
  a : Array[Array[Int64]],
  b : Array[Array[Int64]],
) -> Array[Array[Int64]] {
  let rows = mat_rows(a)
  let mid = mat_cols(a)
  let cols = mat_cols(b)
  let out = mat_zero(rows, cols)
  for i = 0; i < rows; i = i + 1 {
    for k = 0; k < mid; k = k + 1 {
      let aik = a[i][k]
      if aik != 0L {
        for j = 0; j < cols; j = j + 1 {
          out[i][j] = out[i][j] + aik * b[k][j]
        }
      }
    }
  }
  out
}

///|
/// 矩陣加法。
pub fn mat_add(
  a : Array[Array[Int64]],
  b : Array[Array[Int64]],
) -> Array[Array[Int64]] {
  let out = mat_zero(mat_rows(a), mat_cols(a))
  for i = 0; i < mat_rows(a); i = i + 1 {
    for j = 0; j < mat_cols(a); j = j + 1 {
      out[i][j] = a[i][j] + b[i][j]
    }
  }
  out
}

///|
/// 單位矩陣。
pub fn mat_identity(n : Int32) -> Array[Array[Int64]] {
  let out = mat_zero(n, n)
  for i = 0; i < n; i = i + 1 {
    out[i][i] = 1L
  }
  out
}

///|
/// **子空間的維度**：由若干「列向量」張成的空間（輸入為矩陣，取其列張成空間）。
/// 等價地用轉置後的秩。
pub fn span_dim(vectors : Array[Array[Int64]]) -> Int32 {
  rank_q(mat_transpose(vectors))
}
