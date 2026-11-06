///|
/// B0006 / kk 套件：**真的 Hilbert 空間一側**（A41、A42）
/// 對應 docs/B0006-定理體系.md §6–§7。
///
/// 本檔做三件在 Hilbert 空間上**可精確計算**的事：
///   1. 精確有理數與有理矩陣的秩／零化度（rank 在 ℚ 上與在 ℂ 上相同：
///      對 ℚ 上的矩陣，其 ℂ-秩由某個子式不為零判定，而子式是有理數）；
///   2. **Hilbert C*-模** p·A^N 的 K₀ 類：區塊秩向量 (rank p_i)/n_i，及其可加性
///      （這正是 K₀(A) = ℤ^{r} 的具體實現，把「投影」與「K-類」連起來）；
///   3. **Fredholm 指標**：有限矩陣的 index = dim ker − dim coker（由秩算出），
///      Toeplitz 符號的繞數，以及 **index(T_f) = −wind(f)** 的兩條路徑與其界限。

// ---------------------------------------------------------------- 精確有理數

///|
/// 有理數 n/d（d > 0，已約分）。
pub struct Rat {
  n : Int64
  d : Int64
}

///|
/// 建構並約分（d = 0 視為 0/1，避免 panic；呼叫端不應傳 0）。
pub fn rat_make(n : Int64, d : Int64) -> Rat {
  if d == 0L {
    return { n: 0L, d: 1L, }
  }
  let mut nn = n
  let mut dd = d
  if dd < 0L {
    nn = -nn
    dd = -dd
  }
  let g = igcd(nn, dd)
  if g == 0L {
    { n: 0L, d: 1L, }
  } else {
    { n: nn / g, d: dd / g, }
  }
}

///|
/// 零。
pub fn rat_zero() -> Rat {
  { n: 0L, d: 1L, }
}

///|
/// 一。
pub fn rat_one() -> Rat {
  { n: 1L, d: 1L, }
}

///|
/// 整數。
pub fn rat_of_int(k : Int64) -> Rat {
  { n: k, d: 1L, }
}

///|
/// 零判定。
pub fn rat_is_zero(a : Rat) -> Bool {
  a.n == 0L
}

///|
/// 相等。
pub fn rat_eq(a : Rat, b : Rat) -> Bool {
  a.n == b.n && a.d == b.d
}

///|
/// 負。
pub fn rat_neg(a : Rat) -> Rat {
  { n: -a.n, d: a.d, }
}

///|
/// 加。
pub fn rat_add(a : Rat, b : Rat) -> Rat {
  rat_make(a.n * b.d + b.n * a.d, a.d * b.d)
}

///|
/// 減。
pub fn rat_sub(a : Rat, b : Rat) -> Rat {
  rat_add(a, rat_neg(b))
}

///|
/// 乘。
pub fn rat_mul(a : Rat, b : Rat) -> Rat {
  rat_make(a.n * b.n, a.d * b.d)
}

///|
/// 除（b = 0 時回 0）。
pub fn rat_div(a : Rat, b : Rat) -> Rat {
  if rat_is_zero(b) {
    rat_zero()
  } else {
    rat_make(a.n * b.d, a.d * b.n)
  }
}

///|
/// 顯示。
pub fn rat_render(a : Rat) -> String {
  if a.d == 1L {
    a.n.to_string()
  } else {
    a.n.to_string() + "/" + a.d.to_string()
  }
}

// ---------------------------------------------------------------- 有理矩陣

///|
/// 有理矩陣（列主序）。
pub struct QMat {
  rows : Int32
  cols : Int32
  e : Array[Array[Rat]]
}

///|
/// 由整數矩陣建構。
pub fn qmat_of(e : Array[Array[Int64]]) -> QMat {
  let rows = e.length()
  let cols = if rows == 0 { 0 } else { e[0].length() }
  let out : Array[Array[Rat]] = []
  for i = 0; i < rows; i = i + 1 {
    let row : Array[Rat] = []
    for j = 0; j < cols; j = j + 1 {
      row.push(rat_of_int(e[i][j]))
    }
    out.push(row)
  }
  { rows, cols, e: out, }
}

///|
/// 零矩陣。
pub fn qmat_zero(rows : Int32, cols : Int32) -> QMat {
  let out : Array[Array[Rat]] = []
  for _i = 0; _i < rows; _i = _i + 1 {
    let row : Array[Rat] = []
    for _j = 0; _j < cols; _j = _j + 1 {
      row.push(rat_zero())
    }
    out.push(row)
  }
  { rows, cols, e: out, }
}

///|
/// 秩（高斯消去，精確有理運算）。
pub fn qmat_rank(m : QMat) -> Int32 {
  let a : Array[Array[Rat]] = []
  for i = 0; i < m.rows; i = i + 1 {
    a.push(m.e[i].copy())
  }
  let mut rank = 0
  for col = 0; col < m.cols; col = col + 1 {
    let mut piv = -1
    for r = rank; r < m.rows; r = r + 1 {
      if piv < 0 && !rat_is_zero(a[r][col]) {
        piv = r
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = a[rank]
    a[rank] = a[piv]
    a[piv] = tmp
    let p = a[rank][col]
    for r = 0; r < m.rows; r = r + 1 {
      if r != rank && !rat_is_zero(a[r][col]) {
        let f = rat_div(a[r][col], p)
        for c = col; c < m.cols; c = c + 1 {
          a[r][c] = rat_sub(a[r][c], rat_mul(f, a[rank][c]))
        }
      }
    }
    rank = rank + 1
    if rank == m.rows {
      break
    }
  }
  rank
}

///|
/// 零化度 dim ker。
pub fn qmat_nullity(m : QMat) -> Int32 {
  m.cols - qmat_rank(m)
}

///|
/// **Fredholm 指標** index(F) = dim ker F − dim coker F = (n − r) − (m − r)。
pub fn qmat_fredholm_index(m : QMat) -> Int32 {
  qmat_nullity(m) - (m.rows - qmat_rank(m))
}

///|
/// 矩陣乘積（有理）。
pub fn qmat_mul(a : QMat, b : QMat) -> QMat {
  let out = qmat_zero(a.rows, b.cols)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < b.cols; j = j + 1 {
      let mut s = rat_zero()
      for k = 0; k < a.cols; k = k + 1 {
        s = rat_add(s, rat_mul(a.e[i][k], b.e[k][j]))
      }
      out.e[i][j] = s
    }
  }
  out
}

///|
/// 轉置（實矩陣 ⇒ 伴隨）。
pub fn qmat_transpose(a : QMat) -> QMat {
  let out = qmat_zero(a.cols, a.rows)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < a.cols; j = j + 1 {
      out.e[j][i] = a.e[i][j]
    }
  }
  out
}

///|
/// 是否為投影（p² = p 且 p* = p）。
pub fn is_projection(p : QMat) -> Bool {
  if p.rows != p.cols {
    return false
  }
  let sq = qmat_mul(p, p)
  let tr = qmat_transpose(p)
  let mut ok = true
  for i = 0; i < p.rows; i = i + 1 {
    for j = 0; j < p.cols; j = j + 1 {
      if !rat_eq(sq.e[i][j], p.e[i][j]) || !rat_eq(tr.e[i][j], p.e[i][j]) {
        ok = false
      }
    }
  }
  ok
}

///|
/// 一組分塊秩的**歸一化秩向量** (rank_i / n_i)——Hilbert A-模秩向量的唯一實作。
pub fn normalized_rank(
  block_ranks : Array[Int32],
  blocks : Array[Int32],
) -> Array[Rat] {
  let out : Array[Rat] = []
  for i = 0; i < blocks.length(); i = i + 1 {
    out.push(rat_make(block_ranks[i].to_int64(), blocks[i].to_int64()))
  }
  out
}

///|
/// 分塊投影（Hilbert A-模的投影）：`blocks` 給每個簡單塊的大小 n_i，
/// `sizes` 給每個塊的重數 N_i。回傳每個塊的秩（除以 n_i 之前的整數）。
/// 回傳 `None` 若某塊的秩不被 n_i 整除（即不是 A-線性投影）。
pub fn hilbert_module_rank_vector(
  block_ranks : Array[Int32],
  blocks : Array[Int32],
) -> Array[Int64]? {
  let v = normalized_rank(block_ranks, blocks)
  let out : Array[Int64] = []
  let mut ok = true
  for i = 0; i < blocks.length(); i = i + 1 {
    // 塊大小 0 無意義（`rat_make` 會靜默回 0/1，故必須在這裡先擋）
    if blocks[i] == 0 {
      ok = false
      continue
    }
    // 整數性判定：分母必須是 1（否則不是 A-線性投影）
    if v[i].d != 1L {
      ok = false
    } else {
      out.push(v[i].n)
    }
  }
  if ok {
    Some(out)
  } else {
    None
  }
}

// ---------------------------------------------------------------- Laurent 多項式與繞數

///|
/// Laurent 多項式 Σ c_k t^k（指數遞增、無零係數）。
pub struct Laur {
  c : Array[(Int32, Rat)]
}

///|
/// 由 (指數, 係數) 表建構（自動去零、排序）。
pub fn laur_of(c : Array[(Int32, Rat)]) -> Laur {
  // ＊BUG-14＊：必須把同指數的項**合併**（乘法會產生重複指數），
  // 否則 (t−1/2)(t−2) 會留下四個項、係數比對全錯。
  let keys : Array[Int32] = []
  let vals : Array[Rat] = []
  for (k, v) in c {
    let mut found = -1
    for i = 0; i < keys.length(); i = i + 1 {
      if keys[i] == k {
        found = i
      }
    }
    if found >= 0 {
      vals[found] = rat_add(vals[found], v)
    } else {
      keys.push(k)
      vals.push(v)
    }
  }
  let items : Array[(Int32, Rat)] = []
  for i = 0; i < keys.length(); i = i + 1 {
    if !rat_is_zero(vals[i]) {
      items.push((keys[i], vals[i]))
    }
  }
  items.sort_by(fn(a, b) { a.0 - b.0 })
  { c: items, }
}

///|
/// 單項 t^k。
pub fn laur_monomial(k : Int32) -> Laur {
  laur_of([(k, rat_one())])
}

///|
/// 乘法。
pub fn laur_mul(a : Laur, b : Laur) -> Laur {
  let items : Array[(Int32, Rat)] = []
  for (k1, v1) in a.c {
    for (k2, v2) in b.c {
      items.push((k1 + k2, rat_mul(v1, v2)))
    }
  }
  laur_of(items)
}

///|
/// 顯示。
pub fn laur_render(a : Laur) -> String {
  if a.c.length() == 0 {
    return "0"
  }
  let sb = StringBuilder()
  for i = 0; i < a.c.length(); i = i + 1 {
    let (k, v) = a.c[i]
    if i > 0 {
      sb.write_string(" + ")
    }
    sb.write_string(rat_render(v))
    sb.write_string("·t^")
    sb.write_string(k.to_string())
  }
  sb.to_string()
}

///|
/// 實有理數 a 是否落在單位圓內（|a| < 1，精確比較 n² < d²）。
pub fn rat_inside_unit(a : Rat) -> Bool {
  a.n * a.n < a.d * a.d
}

///|
/// 由**因式分解**計算繞數：f(t) = t^shift · Π (t − z_j)^{m_j} / Π (t − p_j)^{k_j}，
/// wind(f) = shift + Σ_{|z_j|<1} m_j − Σ_{|p_j|<1} k_j（幅角原理）。
/// 這是精確計算：只用「|根| < 1」的整數比較。
pub fn wind_of_factors(
  shift : Int32,
  zeros : Array[(Rat, Int32)],
  poles : Array[(Rat, Int32)],
) -> Int32 {
  let mut w = shift
  for (z, m) in zeros {
    if rat_inside_unit(z) {
      w = w + m
    }
  }
  for (p, k) in poles {
    if rat_inside_unit(p) {
      w = w - k
    }
  }
  w
}

///|
/// 由因式造出實際的 Laurent 多項式（用於交叉驗證：例如計算 t − z 的係數）。
pub fn laur_of_factors(
  shift : Int32,
  zeros : Array[(Rat, Int32)],
  poles : Array[(Rat, Int32)],
) -> Laur {
  let mut num = laur_monomial(shift)
  for (z, m) in zeros {
    for _j = 0; _j < m; _j = _j + 1 {
      // 乘 (t − z)
      num = laur_mul(num, laur_of([(1, rat_one()), (0, rat_neg(z))]))
    }
  }
  for (p, k) in poles {
    for _j = 0; _j < k; _j = _j + 1 {
      num = laur_mul(num, laur_of([(1, rat_one()), (0, rat_neg(p))]))
    }
  }
  num
}

// ---------------------------------------------------------------- Toeplitz 算子

///|
/// 乘法算子「乘 t^k」在 Hardy 空間 span{1, t, …, t^{N−1}} 上的壓縮矩陣（N×N）。
/// ＊注意＊：**方矩陣的 Fredholm 指標恆為 0**（nullity 與 coker 維數都等於 N − rank）。
/// 要看見指標必須用「非方」截斷，見 toeplitz_truncation_rect。
pub fn toeplitz_truncation(n : Int32, k : Int32) -> QMat {
  let m = qmat_zero(n, n)
  // ＊乘法算子乘 t^k：t^i ↦ t^{i+k}，故第 (i+k) 列第 i 行為 1（列 = 像、行 = 源）
  for i = 0; i < n; i = i + 1 {
    let j = i + k
    if j >= 0 && j < n {
      m.e[j][i] = rat_one()
    }
  }
  m
}

///|
/// **非方截斷**：把 ℂ^N（span{1..t^{N−1}}）送到 ℂ^{N+k}（span{1..t^{N+k−1}}）的壓縮矩陣，
/// 這是乘 t^k 在「截斷之後」的真正有限模型：秩 N、coker 維數 k，故 index = −k。
pub fn toeplitz_truncation_rect(n : Int32, k : Int32) -> QMat {
  let rows = n + k
  let m = qmat_zero(rows, n)
  for i = 0; i < n; i = i + 1 {
    m.e[i + k][i] = rat_one()
  }
  m
}

///|
/// 乘法算子「乘 (a·t + b)」的壓縮矩陣（N×N）。
pub fn toeplitz_truncation_linear(n : Int32, a : Rat, b : Rat) -> QMat {
  let m = qmat_zero(n, n)
  for i = 0; i < n; i = i + 1 {
    m.e[i][i] = b
    if i + 1 < n {
      m.e[i + 1][i] = a
    }
  }
  m
}

///|
/// Toeplitz 指標的**符號公式**：index(T_f) = −wind(f)。
pub fn toeplitz_index_of_symbol(wind : Int32) -> Int32 {
  -wind
}
