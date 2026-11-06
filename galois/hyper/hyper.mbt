///|
/// B0007 / hyper 套件：**超立方體網絡群 Aut(Q_n) 的完整刻劃**（A44、A45）
/// 對應 docs/B0007-定理體系.md §2–§6。
///
/// Q_n 的頂點是 𝔽₂ⁿ 的位元串（0..2ⁿ−1），兩點相連 ⟺ 差一個位元。
/// 本檔要證/算的完整刻劃是
///
/// ```
/// Aut(Q_n) = { v ↦ π(v) ⊕ b : π ∈ S_n, b ∈ 𝔽₂ⁿ } ≅ 𝔽₂ⁿ ⋊ S_n ≅ ℤ₂ ≀ S_n，|Aut(Q_n)| = 2ⁿ·n!
/// ```
///
/// 做法是**兩條路徑**：
///   1. 由下而上：用回溯法（BFS 序 + 鄰接一致性剪枝）**窮舉**全部自同構；
///   2. 由上而下：直接寫出 2ⁿ·n! 個候選（平移 ⋊ 座標置換），再驗它**等於**窮舉結果。
/// 兩者相等才是完整刻劃，缺一不可（只驗「候選 ⊆ Aut」是玩具）。

///|
/// 2^k。
pub fn pow2i(k : Int32) -> Int32 {
  let mut p = 1
  for _i = 0; _i < k; _i = _i + 1 {
    p = p * 2
  }
  p
}

///|
/// 位元個數（漢明重量）。
pub fn popcnt(x : Int32) -> Int32 {
  let mut c = 0
  let mut y = x
  while y != 0 {
    c = c + y % 2
    y = y / 2
  }
  c
}

///|
/// 漢明距離。
pub fn hamming(a : Int32, b : Int32) -> Int32 {
  popcnt(a ^ b)
}

///|
/// Q_n 中 a、b 是否相鄰。
pub fn adj_qn(n : Int32, a : Int32, b : Int32) -> Bool {
  let v = pow2i(n)
  if a < 0 || a >= v || b < 0 || b >= v {
    false
  } else {
    hamming(a, b) == 1
  }
}

// ---------------------------------------------------------------- 置換

///|
/// 置換相等。
pub fn perm_eq(a : Array[Int32], b : Array[Int32]) -> Bool {
  if a.length() != b.length() {
    return false
  }
  let mut ok = true
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      ok = false
    }
  }
  ok
}

///|
/// 置換合成 (p∘q)(x) = p(q(x))。
pub fn perm_comp(p : Array[Int32], q : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < q.length(); i = i + 1 {
    out.push(p[q[i]])
  }
  out
}

///|
/// 反置換。
pub fn perm_inv(p : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < p.length(); i = i + 1 {
    out.push(0)
  }
  for i = 0; i < p.length(); i = i + 1 {
    out[p[i]] = i
  }
  out
}

///|
/// 單位置換。
pub fn perm_id(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    out.push(i)
  }
  out
}

///|
/// 字典序比較（用於取共軛類的規範代表）。
pub fn perm_lex_less(a : Array[Int32], b : Array[Int32]) -> Bool {
  for i = 0; i < a.length(); i = i + 1 {
    if a[i] != b[i] {
      return a[i] < b[i]
    }
  }
  false
}

///|
/// 置換的字串鍵。
pub fn perm_key(p : Array[Int32]) -> String {
  let sb = StringBuilder()
  for i = 0; i < p.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(p[i].to_string())
  }
  sb.to_string()
}

// ---------------------------------------------------------------- 由上而下：候選群

///|
/// n 個座標的全部置換（S_n 的元素，作用在位元位置上）。
pub fn coord_perms(n : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let cur : Array[Int32] = []
  let used : Array[Bool] = []
  for _i = 0; _i < n; _i = _i + 1 {
    used.push(false)
  }
  coord_go(n, cur, used, out)
  out
}

///|
/// 回溯輔助。
fn coord_go(
  n : Int32,
  cur : Array[Int32],
  used : Array[Bool],
  out : Array[Array[Int32]],
) -> Unit {
  if cur.length() == n {
    out.push(cur.copy())
    return
  }
  for i = 0; i < n; i = i + 1 {
    if !used[i] {
      used[i] = true
      cur.push(i)
      coord_go(n, cur, used, out)
      ignore(cur.pop())
      used[i] = false
    }
  }
}

///|
/// 依座標置換 π 重排位元：第 i 位（原座標）搬到第 π(i) 位。
pub fn permute_bits(v : Int32, pi : Array[Int32]) -> Int32 {
  let mut out = 0
  for i = 0; i < pi.length(); i = i + 1 {
    let bit = v / pow2i(i) % 2
    if bit == 1 {
      out = out + pow2i(pi[i])
    }
  }
  out
}

///|
/// 平移 v ↦ v ⊕ b。
pub fn translate(v : Int32, b : Int32) -> Int32 {
  // 位元 XOR：以位元拆解實作，避免移位運算子的優先級問題
  let mut out = 0
  let mut p = 1
  let mut x = v
  let mut y = b
  while x > 0 || y > 0 {
    let bx = x % 2
    let by = y % 2
    if bx != by {
      out = out + p
    }
    x = x / 2
    y = y / 2
    p = p * 2
  }
  out
}

///|
/// 由上而下預測的自同構群：{ v ↦ π(v) ⊕ b }，共 2ⁿ·n! 個（可能有重複，此處不除重）。
pub fn predicted_automorphisms(n : Int32) -> Array[Array[Int32]] {
  let v = pow2i(n)
  let out : Array[Array[Int32]] = []
  let pis = coord_perms(n)
  for b = 0; b < v; b = b + 1 {
    for pi in pis {
      let img : Array[Int32] = []
      for x = 0; x < v; x = x + 1 {
        img.push(translate(permute_bits(x, pi), b))
      }
      out.push(img)
    }
  }
  out
}

// ---------------------------------------------------------------- 由下而上：回溯窮舉

///|
/// BFS 序：按漢明重量、再按數值（Q_n 中距離 0 的點就是重量 0，故這正是 BFS 序）。
pub fn bfs_order(n : Int32) -> Array[Int32] {
  let v = pow2i(n)
  let out : Array[Int32] = []
  for w = 0; w <= n; w = w + 1 {
    for x = 0; x < v; x = x + 1 {
      if popcnt(x) == w {
        out.push(x)
      }
    }
  }
  out
}

///|
/// 回溯輔助：把 order[idx] 的像設為 cand 是否與已定的像一致。
fn consistent(
  n : Int32,
  x : Int32,
  cand : Int32,
  order : Array[Int32],
  idx : Int32,
  img : Array[Int32],
) -> Bool {
  let mut ok = true
  for j = 0; j < idx; j = j + 1 {
    let y = order[j]
    if adj_qn(n, x, y) != adj_qn(n, cand, img[y]) {
      ok = false
    }
  }
  ok
}

///|
/// 回溯主體。
fn aut_bt(
  n : Int32,
  v : Int32,
  order : Array[Int32],
  idx : Int32,
  img : Array[Int32],
  used : Array[Bool],
  out : Array[Array[Int32]],
) -> Unit {
  if idx == v {
    out.push(img.copy())
    return
  }
  let x = order[idx]
  for cand = 0; cand < v; cand = cand + 1 {
    if !used[cand] && consistent(n, x, cand, order, idx, img) {
      used[cand] = true
      img[x] = cand
      aut_bt(n, v, order, idx + 1, img, used, out)
      img[x] = -1
      used[cand] = false
    }
  }
}

///|
/// **窮舉** Q_n 的全部自同構（回溯 + 鄰接一致性剪枝）。
pub fn automorphisms(n : Int32) -> Array[Array[Int32]] {
  let v = pow2i(n)
  let order = bfs_order(n)
  let img : Array[Int32] = []
  let used : Array[Bool] = []
  for _i = 0; _i < v; _i = _i + 1 {
    img.push(-1)
    used.push(false)
  }
  let out : Array[Array[Int32]] = []
  aut_bt(n, v, order, 0, img, used, out)
  out
}

///|
/// 集合比較：兩組置換（皆無重複）是否完全相同。
pub fn perm_sets_equal(
  a : Array[Array[Int32]],
  b : Array[Array[Int32]],
) -> Bool {
  if a.length() != b.length() {
    return false
  }
  // 以字串鍵建索引
  let keys : Array[String] = []
  for x in a {
    keys.push(perm_key(x))
  }
  let mut ok = true
  for y in b {
    let k = perm_key(y)
    let mut found = false
    for kk in keys {
      if kk == k {
        found = true
      }
    }
    if !found {
      ok = false
    }
  }
  ok
}

// ---------------------------------------------------------------- 群的結構

///|
/// 平移子群 𝔽₂ⁿ（在頂點上的作用）。
pub fn translations(n : Int32) -> Array[Array[Int32]] {
  let v = pow2i(n)
  let out : Array[Array[Int32]] = []
  for b = 0; b < v; b = b + 1 {
    let img : Array[Int32] = []
    for x = 0; x < v; x = x + 1 {
      img.push(translate(x, b))
    }
    out.push(img)
  }
  out
}

///|
/// 座標置換子群 S_n（在頂點上的作用）。
pub fn coord_subgroup(n : Int32) -> Array[Array[Int32]] {
  let v = pow2i(n)
  let out : Array[Array[Int32]] = []
  for pi in coord_perms(n) {
    let img : Array[Int32] = []
    for x = 0; x < v; x = x + 1 {
      img.push(permute_bits(x, pi))
    }
    out.push(img)
  }
  out
}

///|
/// 把 σ 誘導的**方向置換**（n 個座標方向的排列）算出來；若非良定義則回 None。
/// 定義：對每個座標 i，取頂點 0 與 e_i，σ 把這條邊送到某一條邊，
/// 其方向即 π(i)。因為 σ 保距離，這個方向與「取哪個頂點」無關——這正是要驗的事。
pub fn direction_map(sigma : Array[Int32], n : Int32) -> Array[Int32]? {
  let pi : Array[Int32] = []
  let mut ok = true
  let base = sigma[0]
  for i = 0; i < n; i = i + 1 {
    let nb = translate(0, pow2i(i))
    let img = sigma[nb]
    let d = hamming(base, img)
    if d != 1 {
      ok = false
    } else {
      // 找出方向：img 與 base 相差的位元
      let diff = translate(base, img)
      let mut dir = 0
      for j = 0; j < n; j = j + 1 {
        if diff / pow2i(j) % 2 == 1 {
          dir = j
        }
      }
      pi.push(dir)
    }
  }
  if !ok {
    None
  } else {
    // 檢查 π 是雙射且與頂點無關
    let seen : Array[Bool] = []
    for _j = 0; _j < n; _j = _j + 1 {
      seen.push(false)
    }
    for d in pi {
      if d >= 0 && d < n {
        seen[d] = true
      }
    }
    let mut bijective = true
    for s in seen {
      if !s {
        bijective = false
      }
    }
    let v = pow2i(n)
    for x = 0; x < v && ok; x = x + 1 {
      for i = 0; i < n; i = i + 1 {
        let nb = translate(x, pow2i(i))
        let diff = translate(sigma[x], sigma[nb])
        let mut dir = 0
        for j = 0; j < n; j = j + 1 {
          if diff / pow2i(j) % 2 == 1 {
            dir = j
          }
        }
        if dir != pi[i] {
          ok = false
        }
      }
    }
    if ok && bijective {
      Some(pi)
    } else {
      None
    }
  }
}

// ---------------------------------------------------------------- 邊上的作用

///|
/// Q_n 的邊表（每條邊取 (小, 大)）。
pub fn hyper_edges(n : Int32) -> Array[(Int32, Int32)] {
  let v = pow2i(n)
  let out : Array[(Int32, Int32)] = []
  for x = 0; x < v; x = x + 1 {
    for i = 0; i < n; i = i + 1 {
      let y = translate(x, pow2i(i))
      if x < y {
        out.push((x, y))
      }
    }
  }
  out
}

///|
/// 邊的鍵（小端在前；n ≤ 15 時 lo、hi < 2¹⁵，故用 2¹⁵ 進位打包）。
pub fn edge_key(a : Int32, b : Int32) -> Int32 {
  let lo = if a < b { a } else { b }
  let hi = if a < b { b } else { a }
  lo * 32768 + hi
}

///|
/// 邊的查表：key → 邊索引（−1 表不在邊表中）。大小 |V|²。
/// 為何要表：邊置換在 n = 4 時要被呼叫 |Aut|² = 147456 次，
/// 逐條掃描邊表會變成 O(|Aut|²·|E|²)。
pub fn edge_index_table(
  n : Int32,
  edges : Array[(Int32, Int32)],
) -> Array[Int32] {
  let v = pow2i(n)
  let table : Array[Int32] = []
  for _i = 0; _i < v * v; _i = _i + 1 {
    table.push(-1)
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (a, b) = edges[i]
    table[a * v + b] = i
  }
  table
}

///|
/// σ 誘導的邊置換（回傳每條邊的新索引；用查表 O(|E|)）。
pub fn edge_permutation(
  n : Int32,
  sigma : Array[Int32],
  edges : Array[(Int32, Int32)],
) -> Array[Int32] {
  edge_permutation_tbl(pow2i(n), edge_index_table(n, edges), sigma, edges)
}

///|
/// 同上，但查表由呼叫端建立（大批量比較時只建一次）。
pub fn edge_permutation_tbl(
  v : Int32,
  table : Array[Int32],
  sigma : Array[Int32],
  edges : Array[(Int32, Int32)],
) -> Array[Int32] {
  let out : Array[Int32] = []
  for (a, b) in edges {
    let x = sigma[a]
    let y = sigma[b]
    let lo = if x < y { x } else { y }
    let hi = if x < y { y } else { x }
    out.push(table[lo * v + hi])
  }
  out
}

// ---------------------------------------------------------------- 階乘與基本量

///|
/// 階乘。
pub fn fact(n : Int32) -> Int32 {
  let mut f = 1
  for i = 2; i <= n; i = i + 1 {
    f = f * i
  }
  f
}

///|
/// 預測的群階 2ⁿ·n!。
pub fn predicted_order(n : Int32) -> Int32 {
  pow2i(n) * fact(n)
}

///|
/// 邊數公式 n·2^{n−1}（n ≥ 1）。
pub fn edge_count_formula(n : Int32) -> Int32 {
  n * pow2i(n - 1)
}

///|
/// 正則度：每個頂點的度是否都等於 n。
pub fn is_n_regular(n : Int32) -> Bool {
  let v = pow2i(n)
  let mut ok = true
  for x = 0; x < v; x = x + 1 {
    let mut d = 0
    for y = 0; y < v; y = y + 1 {
      if adj_qn(n, x, y) {
        d = d + 1
      }
    }
    if d != n {
      ok = false
    }
  }
  ok
}

///|
/// 直徑（= 最大 BFS 距離）。
pub fn diameter(n : Int32) -> Int32 {
  let d = graph_dist(n, 0)
  let mut m = 0
  for x in d {
    if x > m {
      m = x
    }
  }
  m
}

///|
/// Cayley 判準：Q_n 的邊 ⟺ 兩點的差是標準基向量 e_i。
pub fn cayley_ok(n : Int32) -> Bool {
  let v = pow2i(n)
  let mut ok = true
  for x = 0; x < v; x = x + 1 {
    for y = 0; y < v; y = y + 1 {
      let diff = translate(x, y)
      let mut is_gen = false
      for i = 0; i < n; i = i + 1 {
        if diff == pow2i(i) {
          is_gen = true
        }
      }
      if x != y && adj_qn(n, x, y) != is_gen {
        ok = false
      }
    }
  }
  ok
}

///|
/// 平移群 𝔽₂ⁿ 的正則性：|T| = |V|、自由（只有 id 固定 0）、可遷（0 的軌道是全部）。
pub fn translation_regular(n : Int32) -> Bool {
  let v = pow2i(n)
  let tr = translations(n)
  if tr.length() != v {
    return false
  }
  let mut free = true
  for t in tr {
    if t[0] == 0 && !perm_eq(t, perm_id(v)) {
      free = false
    }
  }
  orbit(tr, 0).length() == v && free
}
