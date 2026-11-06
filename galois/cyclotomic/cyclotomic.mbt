///|
/// B0009 / cyclotomic 套件：**圓周群的所有單位根群**與**圓體擴張伽羅華群**。
///
/// 兩個名詞在這裡是同一件事的兩面：
///
///   圓周群 S¹ 的撓子群 μ = ∪_{n≥1} μ_n ≅ ℚ/ℤ （Prüfer 群），
///   Gal(ℚ(ζ_n)/ℚ) ≅ Aut(μ_n) = (ℤ/n)^×  ——  分圓特徵（cyclotomic character）。
///
/// 因此「圓體擴張伽羅華群」與「所有單位根群」不是兩個孤立的樣本：
/// 伽羅華群**就是** μ_n 的自同構群，而 ℚ(ζ_n) 的乘法算術以整數矩陣實現（Φ_n 么正）。

// ---------------------------------------------------------------- μ_n 與 ℚ/ℤ

///|
/// μ_n 的元素以 k ↦ ζ_n^k（k = 0..n−1）表示；μ_n ≅ ℤ/n 由 ζ^a·ζ^b = ζ^{(a+b) mod n} 給出。
pub fn mu_mult(n : Int32, a : Int32, b : Int32) -> Int32 {
  (a + b) % n
}

///|
/// μ_n 中元素的階：ord(ζ^k) = n / gcd(n, k)。
pub fn mu_order(n : Int32, k : Int32) -> Int32 {
  n / @analytic.gcd_i64(n.to_int64(), k.to_int64()).to_int()
}

///|
/// **R1**：μ_n ≅ ℤ/n——每個元素的階整除 n，且階為 d 的元素個數 = φ(d)。
pub fn check_mu_n_structure(n : Int32) -> Bool {
  let mut ok = true
  // 階為 d 的元素個數 = φ(d)，對每個 d | n 驗證
  for d in divisors(n) {
    let mut count = 0
    for k = 0; k < n; k = k + 1 {
      if mu_order(n, k) == d {
        count = count + 1
      }
    }
    if count != euler_phi(d) {
      ok = false
    }
  }
  // 恰有一個元素階為 n 的 φ(n) 個
  ok
}

///|
/// **R2（ℚ/ℤ）**：μ 的每個元素都是有限階；階整除 n 的元素恰是 μ_n。
/// 元素以「最簡分數 a/b（b ≥ 1）」表示，加法為 mod 1 的分數加法。
pub fn qz_add(a : Int64, b : Int64, c : Int64, d : Int64) -> (Int64, Int64) {
  let r = @analytic.rat_add(@analytic.rat_new(a, b), @analytic.rat_new(c, d))
  let mut num = r.num
  let den = r.den
  num = (num % den + den) % den
  let g = @analytic.gcd_i64(num, den)
  if g == 0L {
    (0L, 1L)
  } else {
    (num / g, den / g)
  }
}

///|
/// ℚ/ℤ 中元素的階 = 分母。
pub fn qz_order(a : Int64, b : Int64) -> Int64 {
  let g = @analytic.gcd_i64(a, b)
  if g == 0L {
    1L
  } else {
    b / g
  }
}

///|
/// R2 的檢核：ℚ/ℤ 的元素全為有限階；且對每個 n，階整除 n 的元素構成 μ_n（恰 n 個）。
pub fn check_qz_torsion(top : Int32) -> Bool {
  let mut ok = true
  for n = 1; n <= top; n = n + 1 {
    // 階整除 n 的元素恰為 μ_n（共 n 個），且每個元素的階有限
    let mut count = 0
    for k = 0; k < n; k = k + 1 {
      let ord = qz_order(k.to_int64(), n.to_int64())
      if n % ord.to_int() == 0 {
        count = count + 1
      }
    }
    if count != n {
      ok = false
    }
  }
  ok
}

///|
/// **R3（Prüfer 可除性）**：ℚ/ℤ 是可除群——對任意 x 與 m，方程 m·y = x 有解。
pub fn check_qz_divisible(top : Int32) -> Bool {
  let mut ok = true
  for n = 1; n <= top; n = n + 1 {
    for k = 0; k < n; k = k + 1 {
      for m = 1; m <= 6; m = m + 1 {
        // 取 y = k/(n·m)（候選解），驗 m·y = k/n（mod 1）
        let y = (k.to_int64(), (n * m).to_int64())
        let mut acc = (0L, 1L)
        for step = 0; step < m; step = step + 1 {
          acc = qz_add(acc.0, acc.1, y.0, y.1)
        }
        let want = qz_add(0L, 1L, k.to_int64(), n.to_int64())
        if !@analytic.rat_eq(
            @analytic.rat_new(acc.0, acc.1),
            @analytic.rat_new(want.0, want.1),
          ) {
          ok = false
        }
      }
    }
  }
  ok
}

///|
/// **R4（Pontryagin 對偶）**：μ_n 的特徵群 ≅ ℤ/n。
/// 特徵 χ_j(ζ^k) = ζ^{jk}；χ_j 是特徵（χ(ab) = χ(a)χ(b)）且 j ↦ χ_j 是群同構。
pub fn check_pontryagin(n : Int32) -> Bool {
  let mut ok = true
  // 同態性：χ_j(ζ^a·ζ^b) = χ_j(ζ^a)χ_j(ζ^b)
  for j = 0; j < n; j = j + 1 {
    for a = 0; a < n; a = a + 1 {
      for b = 0; b < n; b = b + 1 {
        let left = j * mu_mult(n, a, b) % n
        let right = (j * a % n + j * b % n) % n
        if left != right {
          ok = false
        }
      }
    }
  }
  // 非退化：j ≠ j' ⇒ 存在 k 使 χ_j(ζ^k) ≠ χ_{j'}(ζ^k)
  for j = 0; j < n; j = j + 1 {
    for jp = 0; jp < n; jp = jp + 1 {
      if j != jp {
        let mut found = false
        for k = 0; k < n; k = k + 1 {
          if j * k % n != jp * k % n {
            found = true
          }
        }
        if !found {
          ok = false
        }
      }
    }
  }
  ok
}

// ---------------------------------------------------------------- ℚ(ζ_n) 的算術

///|
/// 分圓多項式的次數 = [ℚ(ζ_n):ℚ] = φ(n)。
pub fn cyclo_dim(n : Int32) -> Int32 {
  euler_phi(n)
}

///|
/// 把係數多項式對 Φ_n 取模（得到長度 φ(n) 的基底座標）。
pub fn reduce_mod_cyclo(n : Int32, c : Array[Int64]) -> Array[Int64] {
  let phi = cyclotomic_poly(n)
  let d = cyclo_dim(n)
  let rem : Array[Int64] = []
  for i = 0; i < d || i < c.length(); i = i + 1 {
    rem.push(if i < c.length() { c[i] } else { 0L })
  }
  // Φ_n = x^d + Σ_{i<d} phi.c[i] x^i
  for i = rem.length() - 1; i >= d; i = i - 1 {
    let coeff = rem[i]
    if coeff != 0L {
      rem[i] = 0L
      for j = 0; j < d; j = j + 1 {
        rem[i - d + j] = rem[i - d + j] - coeff * phi.c[j]
      }
    }
  }
  let out : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    out.push(rem[i])
  }
  out
}

///|
/// 兩個基底座標向量的乘法（在 ℚ(ζ_n) 中）。
pub fn cyclo_mul(n : Int32, x : Array[Int64], y : Array[Int64]) -> Array[Int64] {
  let d = cyclo_dim(n)
  let raw : Array[Int64] = []
  for i = 0; i < 2 * d; i = i + 1 {
    raw.push(0L)
  }
  for i = 0; i < d; i = i + 1 {
    for j = 0; j < d; j = j + 1 {
      raw[i + j] = raw[i + j] + x[i] * y[j]
    }
  }
  reduce_mod_cyclo(n, raw)
}

// ---------------------------------------------------------------- 伽羅華群

///|
/// (ℤ/n)^× 的元素清單（升序）。
pub fn units_mod(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for k = 1; k < n; k = k + 1 {
    if @analytic.gcd_i64(k.to_int64(), n.to_int64()) == 1L {
      out.push(k)
    }
  }
  out
}

///|
/// σ_k 的矩陣：ζ^i ↦ ζ^{ik}（基底座標下的整數矩陣，d×d，列主序拉平）。
pub fn sigma_matrix(n : Int32, k : Int32) -> Array[Array[Int64]] {
  let d = cyclo_dim(n)
  let out : Array[Array[Int64]] = []
  for i = 0; i < d; i = i + 1 {
    out.push(reduce_mod_cyclo(n, x_power(i * k % n)))
  }
  // 轉成「列 = 像、行 = 原像」
  let m : Array[Array[Int64]] = []
  for r = 0; r < d; r = r + 1 {
    let row : Array[Int64] = []
    for c = 0; c < d; c = c + 1 {
      row.push(out[c][r])
    }
    m.push(row)
  }
  m
}

///|
/// x^e 的係數向量。
pub fn x_power(e : Int32) -> Array[Int64] {
  let out : Array[Int64] = []
  for i = 0; i <= e; i = i + 1 {
    out.push(if i == e { 1L } else { 0L })
  }
  out
}

///|
/// 矩陣乘（整數）。
pub fn mat_mul_i(
  a : Array[Array[Int64]],
  b : Array[Array[Int64]],
) -> Array[Array[Int64]] {
  let n = a.length()
  let out : Array[Array[Int64]] = []
  for i = 0; i < n; i = i + 1 {
    let row : Array[Int64] = []
    for j = 0; j < n; j = j + 1 {
      let mut s = 0L
      for k = 0; k < n; k = k + 1 {
        s = s + a[i][k] * b[k][j]
      }
      row.push(s)
    }
    out.push(row)
  }
  out
}

///|
/// 矩陣相等（整數）。
pub fn mat_eq_i(a : Array[Array[Int64]], b : Array[Array[Int64]]) -> Bool {
  let n = a.length()
  let mut ok = true
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      if a[i][j] != b[i][j] {
        ok = false
      }
    }
  }
  ok
}

///|
/// 由 g 生成的**循環子群** ⟨g⟩ ≤ (ℤ/n)^×（升序，含 g 的連乘直到回到 1）。
pub fn cyclic_subgroup(n : Int32, g : Int32) -> Array[Int32] {
  let h : Array[Int32] = []
  let mut p = g % n
  h.push(p)
  while p != 1 {
    p = p * g % n
    h.push(p)
  }
  h
}

///|
/// k 在 (ℤ/n)^× 中的階（= σ_k 在 Gal 中的階；單一實作，勿另寫第二份）。
pub fn unit_order(n : Int32, k : Int32) -> Int32 {
  cyclic_subgroup(n, k).length()
}

///|
/// **G1**：k ↦ σ_k 是 (ℤ/n)^× → Aut(ℚ(ζ_n)) 的群同構：
/// σ_k 是么正環同態（保乘法）、σ_k σ_l = σ_{kl}、且 k ↦ σ_k 是雙射。
pub fn check_galois_is_units(n : Int32) -> Bool {
  let us = units_mod(n)
  let d = cyclo_dim(n)
  let mut ok = true
  // 保乘法：σ_k(ζ^a · ζ^b) = σ_k(ζ^a) · σ_k(ζ^b)
  for k in us {
    for a = 0; a < d; a = a + 1 {
      for b = 0; b < d; b = b + 1 {
        let prod = cyclo_mul(
          n,
          reduce_mod_cyclo(n, x_power(a)),
          reduce_mod_cyclo(n, x_power(b)),
        )
        // σ_k 作用：把座標向量用 σ_k 的矩陣搬移
        let sk = sigma_matrix(n, k)
        let left : Array[Int64] = []
        for r = 0; r < d; r = r + 1 {
          let mut s = 0L
          for c = 0; c < d; c = c + 1 {
            s = s + sk[r][c] * prod[c]
          }
          left.push(s)
        }
        let sa = reduce_mod_cyclo(n, x_power(a * k % n))
        let sb = reduce_mod_cyclo(n, x_power(b * k % n))
        let right = cyclo_mul(n, sa, sb)
        if left != right {
          ok = false
        }
      }
    }
  }
  // 乘法表同構：σ_k σ_l = σ_{kl mod n}
  for k in us {
    for l in us {
      let prod = mat_mul_i(sigma_matrix(n, k), sigma_matrix(n, l))
      if !mat_eq_i(prod, sigma_matrix(n, k * l % n)) {
        ok = false
      }
    }
  }
  // 雙射：不同的 k 給不同的矩陣
  for i = 0; i < us.length(); i = i + 1 {
    for j = i + 1; j < us.length(); j = j + 1 {
      if mat_eq_i(sigma_matrix(n, us[i]), sigma_matrix(n, us[j])) {
        ok = false
      }
    }
  }
  ok
}

///|
/// **G2（跡與 Ramanujan 和）**：Tr_{ℚ(ζ_n)/ℚ}(ζ_n^j) = c_n(j) = μ(n/d)·φ(n)/φ(n/d)，d = gcd(n, j)。
/// 用「跡 = 所有 σ_k 的像之和」精算，再與公式對撞。
pub fn ramanujan_formula(n : Int32, j : Int32) -> Int64 {
  let g = @analytic.gcd_i64(n.to_int64(), j.to_int64()).to_int()
  let d = g
  let nd = n / d
  // μ(nd)：nd 的質因數分解是否平方自由
  let mut mu : Int64 = 1L
  let mut m = nd
  let mut p = 2
  while p * p <= m {
    if m % p == 0 {
      m = m / p
      if m % p == 0 {
        mu = 0L
      } else {
        mu = -mu
      }
    }
    p = p + 1
  }
  if m > 1 {
    mu = -mu
  }
  if mu == 0L {
    0L
  } else {
    mu * (euler_phi(n) / euler_phi(nd)).to_int64()
  }
}

///|
/// 精算 Tr(ζ^j)：座標向量應是 (c, 0, …, 0)，回傳 c。
pub fn trace_of_basis(n : Int32, j : Int32) -> Int64 {
  let d = cyclo_dim(n)
  let acc : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    acc.push(0L)
  }
  for k in units_mod(n) {
    let v = reduce_mod_cyclo(n, x_power(j * k % n))
    for i = 0; i < d; i = i + 1 {
      acc[i] = acc[i] + v[i]
    }
  }
  // 檢查高次項為 0
  let mut nonzero_tail = false
  for i = 1; i < d; i = i + 1 {
    if acc[i] != 0L {
      nonzero_tail = true
    }
  }
  if nonzero_tail {
    999999L
  } else {
    acc[0]
  }
}

///|
/// G2 的檢核：對所有 n ≤ top、所有 j，精算的跡 = Ramanujan 公式。
pub fn check_ramanujan(top : Int32) -> Bool {
  let mut ok = true
  for n = 2; n <= top; n = n + 1 {
    for j = 0; j < n; j = j + 1 {
      if trace_of_basis(n, j) != ramanujan_formula(n, j) {
        ok = false
      }
    }
  }
  ok
}

///|
/// H 對應的**線性條件**：(σ_k − I) 的所有行（k ∈ H）。
/// Fix(H) 就是這組行的核——這是「全局公理伽羅華對應」在數論層的可算形式，
/// 也是 bc 套件（B0010 T89）與本套件（T79）**共用的唯一實作**。
pub fn fix_rows(n : Int32, h : Array[Int32]) -> Array[Array[Int64]] {
  let d = cyclo_dim(n)
  let rows : Array[Array[Int64]] = []
  for k in h {
    let sk = sigma_matrix(n, k)
    for r = 0; r < d; r = r + 1 {
      let row : Array[Int64] = []
      for c = 0; c < d; c = c + 1 {
        row.push(sk[r][c] - (if r == c { 1L } else { 0L }))
      }
      rows.push(row)
    }
  }
  rows
}

///|
/// **G3（伽羅華對應）**：H ≤ (ℤ/n)^× 的不動子空間維度 = [G : H]（G = (ℤ/n)^×）。
/// 這是基本定理「[ℚ(ζ_n)^H : ℚ] = [(ℤ/n)^× : H]」的線性代數版本。
pub fn fixed_subspace_dim(n : Int32, h : Array[Int32]) -> Int32 {
  cyclo_dim(n) - @cyclic.rank_q(fix_rows(n, h))
}

///|
/// G3 的檢核：對 (ℤ/n)^× 的所有循環子群，固定空間維度 = 指數 [G : H]。
/// 夾帶兩端：H = G ⇒ 維度 1（固定體 = ℚ）；H = {1} ⇒ 維度 φ(n)（固定體 = ℚ(ζ_n)）。
/// 這裡用「由 k 生成的循環子群」清單（(ℤ/n)^× 在這些 n 都是循環的）。
pub fn check_galois_correspondence(n : Int32) -> Bool {
  let us = units_mod(n)
  let mut ok = true
  for g in us {
    let h = cyclic_subgroup(n, g)
    if fixed_subspace_dim(n, h) != us.length() / h.length() {
      ok = false
    }
  }
  // 平凡子群：固定空間是全空間
  if fixed_subspace_dim(n, [1]) != cyclo_dim(n) {
    ok = false
  }
  ok
}

// ---------------------------------------------------------------- 二次子體

///|
/// **G4（二次子體）**：p 為奇質數時，ℚ(ζ_p) 的唯一二次子體是 ℚ(√((−1)^{(p−1)/2} p))。
/// 用「平方剩餘類的高斯週期 η = Σ_{k∈QR} ζ^k」實現：η 滿足 η² + η + (1 − (−1)^{(p−1)/2}p)/4 = 0。
pub fn gauss_period_quadratic(p : Int32) -> Array[Int64] {
  let d = cyclo_dim(p)
  let eta : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    eta.push(0L)
  }
  for k = 1; k < p; k = k + 1 {
    // k 是平方剩餘？
    let mut is_qr = false
    for a = 1; a < p; a = a + 1 {
      if a * a % p == k {
        is_qr = true
      }
    }
    if is_qr {
      let v = reduce_mod_cyclo(p, x_power(k))
      for i = 0; i < d; i = i + 1 {
        eta[i] = eta[i] + v[i]
      }
    }
  }
  eta
}

///|
/// 二次子體的元素向量是否滿足 x² + x + c = 0（c = (1 − (−1)^{(p−1)/2} p)/4）。
pub fn check_quadratic_subfield(p : Int32) -> Bool {
  let eta = gauss_period_quadratic(p)
  let sq = cyclo_mul(p, eta, eta)
  let d = cyclo_dim(p)
  // 判斷 (−1)^{(p−1)/2}
  let sign : Int64 = if (p - 1) / 2 % 2 == 0 { 1L } else { -1L }
  // c = (1 − sign·p)/4
  let num = 1L - sign * p.to_int64()
  if num % 4L != 0L {
    return false
  }
  let c = num / 4L
  // 檢查 sq + eta + c·1 = 0
  let mut ok = true
  for i = 0; i < d; i = i + 1 {
    let want = if i == 0 { c } else { 0L }
    if sq[i] + eta[i] + want != 0L {
      ok = false
    }
  }
  ok
}

///|
/// G4 的檢核：p = 5, 7, 11, 13 全部命中（5 ≡ 1、7,11 ≡ 3、13 ≡ 1 mod 4）。
pub fn check_quadratic_subfields() -> Bool {
  check_quadratic_subfield(5) &&
  check_quadratic_subfield(7) &&
  check_quadratic_subfield(11) &&
  check_quadratic_subfield(13)
}

// ---------------------------------------------------------------- 分圓特徵（接縫）

///|
/// **G5（分圓特徵 = μ_n 的自同構）**：Gal(ℚ(ζ_n)/ℚ) ≅ (ℤ/n)^× ≅ Aut(μ_n)。
/// 兩個群的乘法表由 k ↦ (σ_k, k) 逐項對撞：σ_k σ_l = σ_{kl} 且 ζ ↦ ζ^k 是 μ_n 的自同構。
pub fn check_cyclotomic_character(n : Int32) -> Bool {
  let us = units_mod(n)
  let mut ok = true
  // ζ ↦ ζ^k 是 μ_n 的自同構：雙射且保乘法
  for k in us {
    // 雙射
    let seen : Array[Bool] = []
    for i = 0; i < n; i = i + 1 {
      seen.push(false)
    }
    for a = 0; a < n; a = a + 1 {
      let img = a * k % n
      if seen[img] {
        ok = false
      }
      seen[img] = true
    }
    // 保乘法
    for a = 0; a < n; a = a + 1 {
      for b = 0; b < n; b = b + 1 {
        if (a * k % n + b * k % n) % n != (a + b) % n * k % n {
          ok = false
        }
      }
    }
  }
  // **矩陣階 = 算術階**：σ_k 的矩陣階（反覆自乘到 I）必須等於 k 在 (ℤ/n)^× 的階。
  // 這是兩套獨立計算的對撞（矩陣乘法 vs 模算術），不是同一個函式呼叫兩次。
  for k in us {
    if sigma_matrix_order(n, k) != unit_order(n, k) {
      ok = false
    }
  }
  ok
}

///|
/// σ_k 的**矩陣階**：最小的 t ≥ 1 使 σ_k^t = I（整數矩陣連乘）。
pub fn sigma_matrix_order(n : Int32, k : Int32) -> Int32 {
  let d = cyclo_dim(n)
  let mut acc = sigma_matrix(n, k)
  let id = mat_id_of(n)
  let mut t = 1
  while !mat_eq_i(acc, id) && t <= d * d + 1 {
    acc = mat_mul_i(acc, sigma_matrix(n, k))
    t = t + 1
  }
  t
}

///|
/// 單位矩陣（整數，φ(n)×φ(n)）。
fn mat_id_of(n : Int32) -> Array[Array[Int64]] {
  let d = cyclo_dim(n)
  let out : Array[Array[Int64]] = []
  for i = 0; i < d; i = i + 1 {
    let row : Array[Int64] = []
    for j = 0; j < d; j = j + 1 {
      row.push(if i == j { 1L } else { 0L })
    }
    out.push(row)
  }
  out
}
