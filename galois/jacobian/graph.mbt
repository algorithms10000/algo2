///|
/// B0005 / jacobian 套件：**圖的雅可比簇（沙堆群）、不變因子、Riemann–Roch**（T25–T27、T30、A31、A32、A33）
/// 對應 docs/B0005-定理體系.md §5–§7、§9。
///
/// 這裡的模型是**圖的雅可比簇** J(G) = ℤ^V / im(L)（L 為 Laplacian），它是曲線雅可比簇的
/// 熱帶化模型（Baker–Norine）：維度 g = |E| − |V| + 1、階 = 生成樹數、Riemann–Roch 逐字成立。
/// 全部用整數／BigInt 精確計算，三條獨立路徑互相印證（不變因子、行列式、暴力生成樹）。

///|
/// BigInt 矩陣。
pub struct BigMat {
  r : Int32
  c : Int32
  e : Array[Array[BigInt]]
}

///|
pub fn bigmat(r : Int32, c : Int32) -> BigMat {
  let rows : Array[Array[BigInt]] = []
  for _i = 0; _i < r; _i = _i + 1 {
    let row : Array[BigInt] = []
    for _j = 0; _j < c; _j = _j + 1 {
      row.push(BigInt::from_int(0))
    }
    rows.push(row)
  }
  { r, c, e: rows, }
}

///|
/// 由 Int32 二維陣列造 BigMat。
pub fn bigmat_of(a : Array[Array[Int32]]) -> BigMat {
  let rows : Array[Array[BigInt]] = []
  for i = 0; i < a.length(); i = i + 1 {
    let row : Array[BigInt] = []
    for j = 0; j < a[i].length(); j = j + 1 {
      row.push(BigInt::from_int(a[i][j]))
    }
    rows.push(row)
  }
  let r = if rows.length() == 0 { 0 } else { rows[0].length() }
  { r: rows.length(), c: r, e: rows, }
}

///|
/// Bareiss 無分數行列式（精確整數，中間量不會爆炸到有理數）。
pub fn det_bareiss(m : BigMat) -> BigInt {
  let n = m.r
  if n == 0 {
    return BigInt::from_int(1)
  }
  let a : Array[Array[BigInt]] = []
  for i = 0; i < n; i = i + 1 {
    a.push(m.e[i].copy())
  }
  let mut sign = 1
  let mut prev = BigInt::from_int(1)
  for k = 0; k < n; k = k + 1 {
    if a[k][k].is_zero() {
      let mut piv = -1
      for i = k + 1; i < n; i = i + 1 {
        if !a[i][k].is_zero() {
          piv = i
          break
        }
      }
      if piv < 0 {
        return BigInt::from_int(0)
      }
      let tmp = a[k]
      a[k] = a[piv]
      a[piv] = tmp
      sign = -sign
    }
    let piv = a[k][k]
    for i = k + 1; i < n; i = i + 1 {
      for j = k + 1; j < n; j = j + 1 {
        a[i][j] = (a[i][j] * piv - a[i][k] * a[k][j]) / prev
      }
    }
    prev = piv
  }
  if sign < 0 {
    -a[n - 1][n - 1]
  } else {
    a[n - 1][n - 1]
  }
}

///|
/// 子矩陣（指定行列索引）。
pub fn bigmat_minor(
  m : BigMat,
  rows : Array[Int32],
  cols : Array[Int32],
) -> BigMat {
  let out : Array[Array[BigInt]] = []
  for i = 0; i < rows.length(); i = i + 1 {
    let row : Array[BigInt] = []
    for j = 0; j < cols.length(); j = j + 1 {
      row.push(m.e[rows[i]][cols[j]])
    }
    out.push(row)
  }
  { r: rows.length(), c: cols.length(), e: out, }
}

///|
pub fn gcd_big(a : BigInt, b : BigInt) -> BigInt {
  let mut x = if a < BigInt::from_int(0) { -a } else { a }
  let mut y = if b < BigInt::from_int(0) { -b } else { b }
  while !y.is_zero() {
    let t = x % y
    x = y
    y = t
  }
  x
}

///|
/// 圖：頂點 0..n−1，邊以 (u,v) 列出。
pub struct Graph {
  n : Int32
  edges : Array[(Int32, Int32)]
}

///|
pub fn Graph::num_vertices(self : Graph) -> Int32 {
  self.n
}

///|
pub fn Graph::num_edges(self : Graph) -> Int32 {
  self.edges.length()
}

///|
/// Laplacian。
pub fn laplacian(g : Graph) -> BigMat {
  let m = bigmat(g.n, g.n)
  for i = 0; i < g.edges.length(); i = i + 1 {
    let (u, v) = g.edges[i]
    m.e[u][u] = m.e[u][u] + BigInt::from_int(1)
    m.e[v][v] = m.e[v][v] + BigInt::from_int(1)
    m.e[u][v] = m.e[u][v] - BigInt::from_int(1)
    m.e[v][u] = m.e[v][u] - BigInt::from_int(1)
  }
  m
}

///|
/// 連通分量數（並查集）。
pub fn Graph::components(self : Graph) -> Int32 {
  let parent : Array[Int32] = []
  for i = 0; i < self.n; i = i + 1 {
    parent.push(i)
  }
  fn find(parent : Array[Int32], x : Int32) -> Int32 {
    let mut y = x
    while parent[y] != y {
      y = parent[y]
    }
    y
  }

  for i = 0; i < self.edges.length(); i = i + 1 {
    let (u, v) = self.edges[i]
    let a = find(parent, u)
    let b = find(parent, v)
    if a != b {
      parent[a] = b
    }
  }
  let mut c = 0
  for i = 0; i < self.n; i = i + 1 {
    if find(parent, i) == i {
      c = c + 1
    }
  }
  c
}

///|
/// 圈秩 β₁ = |E| − |V| + c（= 圖雅可比簇的維度 g）。
pub fn Graph::cycle_rank(self : Graph) -> Int32 {
  self.edges.length() - self.n + self.components()
}

///|
/// 生成樹數（矩陣–樹定理：任一主子式的行列式）。
pub fn spanning_trees_by_det(g : Graph) -> BigInt {
  if g.n <= 1 {
    return BigInt::from_int(1)
  }
  let l = laplacian(g)
  let rows : Array[Int32] = []
  let cols : Array[Int32] = []
  for i = 0; i < g.n - 1; i = i + 1 {
    rows.push(i)
    cols.push(i)
  }
  det_bareiss(bigmat_minor(l, rows, cols))
}

///|
/// 生成樹數（暴力：枚舉 n−1 條邊的子集並檢查連通無圈）——與上面完全獨立的路徑。
pub fn spanning_trees_bruteforce(g : Graph) -> Int32 {
  let m = g.edges.length()
  let need = g.n - 1
  if need == 0 {
    return 1
  }
  let total = 1 << m
  let mut count = 0
  for mask = 0; mask < total; mask = mask + 1 {
    // 位數必須恰為 need
    let mut bits = 0
    for i = 0; i < m; i = i + 1 {
      if ((mask >> i) & 1) == 1 {
        bits = bits + 1
      }
    }
    if bits != need {
      continue
    }
    let parent : Array[Int32] = []
    for i = 0; i < g.n; i = i + 1 {
      parent.push(i)
    }
    fn find2(parent : Array[Int32], x : Int32) -> Int32 {
      let mut y = x
      while parent[y] != y {
        y = parent[y]
      }
      y
    }

    let mut ok = true
    for i = 0; i < m; i = i + 1 {
      if ((mask >> i) & 1) == 1 {
        let (u, v) = g.edges[i]
        let a = find2(parent, u)
        let b = find2(parent, v)
        if a == b {
          ok = false
          break
        }
        parent[a] = b
      }
    }
    if ok {
      count = count + 1
    }
  }
  count
}

///|
/// gcd of all k×k minors（用於不變因子：d_k = g_k / g_{k−1}）。
/// ＊BUG-11＊：手寫的交換式 Smith 正規形在 Int32/BigInt 上會 ZeroDivision（主元可能 0 且無可換列），
/// 故改用「子式 gcd」版；代價是 O(Σ_k C(n,k)²·k³)，實用上限 n ≤ 8。
pub fn minor_gcd(m : BigMat, k : Int32) -> BigInt {
  let mut g = BigInt::from_int(0)
  let total = 1 << m.r
  let totalc = 1 << m.c
  for rm = 0; rm < total; rm = rm + 1 {
    let rows : Array[Int32] = []
    for i = 0; i < m.r; i = i + 1 {
      if ((rm >> i) & 1) == 1 {
        rows.push(i)
      }
    }
    if rows.length() != k {
      continue
    }
    for cm = 0; cm < totalc; cm = cm + 1 {
      let cols : Array[Int32] = []
      for j = 0; j < m.c; j = j + 1 {
        if ((cm >> j) & 1) == 1 {
          cols.push(j)
        }
      }
      if cols.length() != k {
        continue
      }
      let d = det_bareiss(bigmat_minor(m, rows, cols))
      g = gcd_big(g, d)
    }
  }
  g
}

///|
/// 不變因子 d_1 | d_2 | …（Smith 正規形的不零對角元），用「k×k 子式的 gcd」算。
pub fn invariant_factors(m : BigMat) -> Array[BigInt] {
  let out : Array[BigInt] = []
  let mut prev = BigInt::from_int(1)
  let limit = if m.r < m.c { m.r } else { m.c }
  for k = 1; k <= limit; k = k + 1 {
    let g = minor_gcd(m, k)
    if g.is_zero() {
      break
    }
    out.push(g / prev)
    prev = g
  }
  out
}

///|
/// |J(G)| = ∏（不變因子）= 生成樹數（T25）。
pub fn jacobian_order(g : Graph) -> BigInt {
  let fs = invariant_factors(laplacian(g))
  let mut p = BigInt::from_int(1)
  for i = 0; i < fs.length(); i = i + 1 {
    p = p * fs[i]
  }
  p
}

///|
/// Laplacian 在 𝔽₂ 上的秩（用 BigInt mod 2 做消去）。
pub fn laplacian_rank_mod2(g : Graph) -> Int32 {
  let l = laplacian(g)
  let n = l.r
  let a : Array[Array[Int32]] = []
  for i = 0; i < n; i = i + 1 {
    let row : Array[Int32] = []
    for j = 0; j < n; j = j + 1 {
      // ＊修正 BUG-8＊ MoonBit 的 % 對負數給負餘數（−1 % 2 = −1），必須先歸一化到 [0,2)
      let two = BigInt::from_int(2)
      let mut v = l.e[i][j] % two
      if v < BigInt::from_int(0) {
        v = v + two
      }
      row.push(v.to_int())
    }
    a.push(row)
  }
  let mut rank = 0
  for col = 0; col < n; col = col + 1 {
    let mut piv = -1
    for r = rank; r < n; r = r + 1 {
      if a[r][col] == 1 {
        piv = r
        break
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = a[rank]
    a[rank] = a[piv]
    a[piv] = tmp
    for r = 0; r < n; r = r + 1 {
      if r != rank && a[r][col] == 1 {
        for c = 0; c < n; c = c + 1 {
          a[r][c] = (a[r][c] - a[rank][c] + 2) % 2
        }
      }
    }
    rank = rank + 1
  }
  rank
}

///|
/// 有理數上的秩（無分數消去，只數主元）。
pub fn rank_over_q(m : BigMat) -> Int32 {
  let rows = m.r
  let cols = m.c
  let a : Array[Array[BigInt]] = []
  for i = 0; i < rows; i = i + 1 {
    a.push(m.e[i].copy())
  }
  let mut rank = 0
  for col = 0; col < cols; col = col + 1 {
    let mut piv = -1
    for r = rank; r < rows; r = r + 1 {
      if !a[r][col].is_zero() {
        piv = r
        break
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = a[rank]
    a[rank] = a[piv]
    a[piv] = tmp
    for r = rank + 1; r < rows; r = r + 1 {
      if !a[r][col].is_zero() {
        // 交叉相乘消去（保持整數）
        let f1 = a[r][col]
        let f2 = a[rank][col]
        for c = col; c < cols; c = c + 1 {
          a[r][c] = a[r][c] * f2 - a[rank][c] * f1
        }
        // 縮放（除以公因數，避免爆炸）
        let mut g = BigInt::from_int(0)
        for c = col; c < cols; c = c + 1 {
          g = gcd_big(g, a[r][c])
        }
        if !g.is_zero() && g != BigInt::from_int(1) {
          for c = col; c < cols; c = c + 1 {
            a[r][c] = a[r][c] / g
          }
        }
      }
    }
    rank = rank + 1
    if rank == rows {
      break
    }
  }
  rank
}

///|
/// 刪去第 k 條邊。
pub fn edge_delete(g : Graph, k : Int32) -> Graph {
  let es : Array[(Int32, Int32)] = []
  for i = 0; i < g.num_edges(); i = i + 1 {
    if i != k {
      es.push(g.edges[i])
    }
  }
  { n: g.n, edges: es, }
}

///|
/// 收縮第 k 條邊（端點合併；自環自然消失）。
pub fn edge_contract(g : Graph, k : Int32) -> Graph {
  let (u, v) = g.edges[k]
  let lo = if u < v { u } else { v }
  let hi = if u < v { v } else { u }
  // 把 hi 併入 lo，再把 > hi 的標號減一
  fn relabel(x : Int32) -> Int32 {
    if x == hi {
      lo
    } else if x > hi {
      x - 1
    } else {
      x
    }
  }

  let es : Array[(Int32, Int32)] = []
  for i = 0; i < g.num_edges(); i = i + 1 {
    if i != k {
      let (a, b) = g.edges[i]
      let a2 = relabel(a)
      let b2 = relabel(b)
      if a2 != b2 {
        es.push((a2, b2))
      }
    }
  }
  { n: g.n - 1, edges: es, }
}

///|
/// 生成樹計數的**刪縮遞迴**：τ(G) = τ(G−e) + τ(G/e)。
/// 與行列式、暴力枚舉是第三條獨立路徑（A34）。
pub fn tau_deletion_contraction(g : Graph) -> Int64 {
  if g.n <= 1 {
    return 1
  }
  if g.num_edges() == 0 || g.components() > 1 {
    return 0
  }
  if g.num_edges() == g.n - 1 {
    return 1
  }
  tau_deletion_contraction(edge_delete(g, 0)) +
  tau_deletion_contraction(edge_contract(g, 0))
}

// ---------------------------------------------------------------- 除法器與線性等價

///|
/// 把 deg 分成 n 個非負整數的所有方式。
pub fn compositions(d : Int32, n : Int32) -> Array[Array[Int32]] {
  if n == 1 {
    return [[d]]
  }
  let out : Array[Array[Int32]] = []
  for k = 0; k <= d; k = k + 1 {
    let rest = compositions(d - k, n - 1)
    for i = 0; i < rest.length(); i = i + 1 {
      let row : Array[Int32] = [k]
      out.push(row + rest[i])
    }
  }
  out
}

///|
/// x ∈ im(L) 嗎？（要求 Σx = 0，並解約化 Laplacian L̃ y = x̃ 判整數性）
///
/// ＊BUG-10＊：首版直接對約化系統判整數性，**漏了** Σx = 0 這個必要條件
/// ⇒ 對總和不為 0 的 x 給出錯誤答案（假反例）。正解：先判 Σx = 0，再用 Cramer 判全整數。
///
/// 為什麼只解 (n−1)×(n−1) 就夠：連通圖的 L 秩為 n−1，前 n−1 行線性獨立，
/// 故 x ∈ im(L) ⟺ L̃ y = x̃ 有整數解（殘量必為 c·e_n 且 Σ殘量 = 0 ⇒ c = 0）。
pub fn in_laplacian_image(g : Graph, x : Array[Int32]) -> Bool {
  let n = g.n
  let mut sum = 0
  for i = 0; i < n; i = i + 1 {
    sum = sum + x[i]
  }
  if sum != 0 {
    return false
  }
  if n == 1 {
    return true
  }
  let l = laplacian(g)
  let m = n - 1
  let rows : Array[Int32] = []
  let cols : Array[Int32] = []
  for i = 0; i < m; i = i + 1 {
    rows.push(i)
    cols.push(i)
  }
  let lt = bigmat_minor(l, rows, cols)
  let det = det_bareiss(lt)
  if det.is_zero() {
    return false
  }
  for i = 0; i < m; i = i + 1 {
    let sub : Array[Array[BigInt]] = []
    for r = 0; r < m; r = r + 1 {
      let row : Array[BigInt] = []
      for c = 0; c < m; c = c + 1 {
        if c == i {
          row.push(BigInt::from_int(x[r]))
        } else {
          row.push(lt.e[r][c])
        }
      }
      sub.push(row)
    }
    let num = det_bareiss({ r: m, c: m, e: sub, })
    if !(num % det).is_zero() {
      return false
    }
  }
  true
}

///|
/// r(D) ≥ 0 嗎？即 D 是否線性等價於某個有效除子。
pub fn is_effectively_equivalent(g : Graph, d : Array[Int32]) -> Bool {
  let mut deg = 0
  for i = 0; i < g.n; i = i + 1 {
    deg = deg + d[i]
  }
  if deg < 0 {
    return false
  }
  let es = compositions(deg, g.n)
  for idx = 0; idx < es.length(); idx = idx + 1 {
    let e = es[idx]
    let diff : Array[Int32] = []
    for i = 0; i < g.n; i = i + 1 {
      diff.push(d[i] - e[i])
    }
    if in_laplacian_image(g, diff) {
      return true
    }
  }
  false
}

///|
/// 除子的秩 r(D)（Baker–Norine 定義：r(D) ≥ k ⟺ 對所有 k 次有效除子 F，r(D−F) ≥ 0）。
pub fn divisor_rank(g : Graph, d : Array[Int32], maxk : Int32) -> Int32 {
  if !is_effectively_equivalent(g, d) {
    return -1
  }
  let mut k = 0
  while k < maxk {
    let fs = compositions(k + 1, g.n)
    let mut ok = true
    for idx = 0; idx < fs.length(); idx = idx + 1 {
      let f = fs[idx]
      let diff : Array[Int32] = []
      for i = 0; i < g.n; i = i + 1 {
        diff.push(d[i] - f[i])
      }
      if !is_effectively_equivalent(g, diff) {
        ok = false
        break
      }
    }
    if !ok {
      break
    }
    k = k + 1
  }
  k
}

///|
/// 標準除子 K（每點放 deg(v) − 2 個籌碼）。
pub fn canonical_divisor(g : Graph) -> Array[Int32] {
  let deg : Array[Int32] = []
  for i = 0; i < g.n; i = i + 1 {
    deg.push(0)
  }
  for i = 0; i < g.edges.length(); i = i + 1 {
    let (u, v) = g.edges[i]
    deg[u] = deg[u] + 1
    deg[v] = deg[v] + 1
  }
  let out : Array[Int32] = []
  for i = 0; i < g.n; i = i + 1 {
    out.push(deg[i] - 2)
  }
  out
}

///|
/// Riemann–Roch 的暴力檢核結果。
pub struct RRResult {
  tested : Int32
  violations : Int32
  witness : String
}

///|
pub fn RRResult::tested(self : RRResult) -> Int32 {
  self.tested
}

///|
pub fn RRResult::violations(self : RRResult) -> Int32 {
  self.violations
}

///|
pub fn RRResult::render(self : RRResult) -> String {
  "測 " +
  self.tested.to_string() +
  " 個除子，反例 " +
  self.violations.to_string() +
  (if self.violations == 0 {
    "（r(D) − r(K−D) = deg D − g + 1 全部成立）"
  } else {
    "（首個反例：" + self.witness + "）"
  })
}

///|
/// 對 deg D ≤ 2g−2 且 0 ≤ D_i ≤ degmax 的所有 D 檢核 r(D) − r(K−D) = deg D − g + 1。
pub fn riemann_roch(g : Graph, degmax : Int32) -> RRResult {
  let n = g.n
  let gen = g.cycle_rank()
  let k = canonical_divisor(g)
  let limit = 2 * gen - 2
  let mut tested = 0
  let mut bad = 0
  let mut witness = ""
  // 遞歸枚舉 D
  let mut stack : Array[Array[Int32]] = [[]]
  for _depth = 0; _depth < n; _depth = _depth + 1 {
    let next : Array[Array[Int32]] = []
    for si = 0; si < stack.length(); si = si + 1 {
      let cur = stack[si]
      for v = 0; v <= degmax; v = v + 1 {
        let nxt = cur.copy()
        nxt.push(v)
        next.push(nxt)
        if nxt.length() == n {
          let mut degd = 0
          for i = 0; i < n; i = i + 1 {
            degd = degd + nxt[i]
          }
          if degd <= limit {
            let kd : Array[Int32] = []
            for i = 0; i < n; i = i + 1 {
              kd.push(k[i] - nxt[i])
            }
            let r1 = divisor_rank(g, nxt, 4)
            let r2 = divisor_rank(g, kd, 4)
            tested = tested + 1
            if r1 - r2 != degd - gen + 1 {
              bad = bad + 1
              if witness == "" {
                witness = "D=" +
                  render_divisor(nxt) +
                  "、r(D)=" +
                  r1.to_string() +
                  "、r(K−D)=" +
                  r2.to_string()
              }
            }
          }
        }
      }
    }
    stack = next
  }
  { tested, violations: bad, witness, }
}

///|
/// 除子的文字形式。
pub fn render_divisor(d : Array[Int32]) -> String {
  let sb = StringBuilder()
  sb.write_char('(')
  for i = 0; i < d.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(d[i].to_string())
  }
  sb.write_char(')')
  sb.to_string()
}
