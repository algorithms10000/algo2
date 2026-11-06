///|
/// B0007 / hyper 套件：**群的結構、可遷性、摺疊**（T42–T47 的計算側）
/// 對應 docs/B0007-定理體系.md §3–§7。
///
/// 本檔只放「純計算」：給定一組置換（自同構群）或 Q_n 的參數，算出
/// 軌道、穩定子、共軛類、摺疊同態、方向同態等。判定與否留給 checks.mbt。

// ---------------------------------------------------------------- 置換群基本

///|
/// 置換表的鍵索引：字串鍵 → 在表中的位置。
/// 為何不線性掃描：n = 4 時 |Aut| = 384，封閉性檢核要做 384² 次查表，
/// 線性掃描會退化成 O(|Aut|³·|V|)（實測 30 秒以上），索引後是 O(|Aut|²·|V|)。
pub fn perm_index(aut : Array[Array[Int32]]) -> Map[String, Int32] {
  let m : Map[String, Int32] = Map([])
  for i = 0; i < aut.length(); i = i + 1 {
    m.set(perm_key(aut[i]), i)
  }
  m
}

///|
/// p 是否屬於置換表 aut。
pub fn perm_member(aut : Array[Array[Int32]], p : Array[Int32]) -> Bool {
  perm_match(perm_index(aut), p) >= 0
}

///|
/// p 在置換表中的位置（不在則 −1）。
pub fn perm_match(index : Map[String, Int32], p : Array[Int32]) -> Int32 {
  match index.get(perm_key(p)) {
    Some(i) => i
    None => -1
  }
}

///|
/// 群公理（封閉性）：任意兩元素的合成仍在表中。
pub fn aut_closed(aut : Array[Array[Int32]]) -> Bool {
  let index = perm_index(aut)
  let mut ok = true
  for p in aut {
    for q in aut {
      if perm_match(index, perm_comp(p, q)) < 0 {
        ok = false
      }
    }
  }
  ok
}

///|
/// 群公理（單位元）：恆等置換在表中。
pub fn aut_has_identity(aut : Array[Array[Int32]]) -> Bool {
  if aut.length() == 0 {
    return false
  }
  perm_member(aut, perm_id(aut[0].length()))
}

///|
/// 群公理（反元素）：每個元素的反置換在表中。
pub fn aut_has_inverses(aut : Array[Array[Int32]]) -> Bool {
  let index = perm_index(aut)
  let mut ok = true
  for p in aut {
    if perm_match(index, perm_inv(p)) < 0 {
      ok = false
    }
  }
  ok
}

///|
/// 元素階數：最小的 k ≥ 1 使 σ^k = id（不可達時回 −1）。
pub fn elem_order(sigma : Array[Int32]) -> Int32 {
  let id = perm_id(sigma.length())
  let mut cur = sigma.copy()
  for k = 1; k <= 4096; k = k + 1 {
    if perm_eq(cur, id) {
      return k
    }
    cur = perm_comp(sigma, cur)
  }
  -1
}

///|
/// 階數分布：hist[j] = 階數為 j 的元素個數（j 從 1 起算，陣列長度 4097 太大，
/// 故改為回傳「(階數, 個數)」配對，已排序去重）。
pub fn order_histogram(aut : Array[Array[Int32]]) -> Array[(Int32, Int32)] {
  let orders : Array[Int32] = []
  for p in aut {
    orders.push(elem_order(p))
  }
  // 收集出現過的階數（由小到大）
  let distinct : Array[Int32] = []
  for o in orders {
    let mut seen = false
    for d in distinct {
      if d == o {
        seen = true
      }
    }
    if !seen {
      distinct.push(o)
    }
  }
  // 插入排序（階數種類很少）
  let sorted : Array[Int32] = []
  for o in distinct {
    let pos : Array[Int32] = []
    let mut idx = 0
    while idx < sorted.length() && sorted[idx] < o {
      idx = idx + 1
    }
    for i = 0; i < idx; i = i + 1 {
      pos.push(sorted[i])
    }
    pos.push(o)
    for i = idx; i < sorted.length(); i = i + 1 {
      pos.push(sorted[i])
    }
    sorted.clear()
    for x in pos {
      sorted.push(x)
    }
  }
  let out : Array[(Int32, Int32)] = []
  for o in sorted {
    let mut c = 0
    for x in orders {
      if x == o {
        c = c + 1
      }
    }
    out.push((o, c))
  }
  out
}

// ---------------------------------------------------------------- 圖距離

///|
/// Q_n 上 0..2ⁿ−1 的 BFS 距離（−1 表不連通）。
pub fn graph_dist(n : Int32, a : Int32) -> Array[Int32] {
  let v = pow2i(n)
  let dist : Array[Int32] = []
  for _i = 0; _i < v; _i = _i + 1 {
    dist.push(-1)
  }
  if a < 0 || a >= v {
    return dist
  }
  dist[a] = 0
  let queue : Array[Int32] = [a]
  let mut head = 0
  while head < queue.length() {
    let x = queue[head]
    head = head + 1
    for i = 0; i < n; i = i + 1 {
      let y = translate(x, pow2i(i))
      if dist[y] < 0 {
        dist[y] = dist[x] + 1
        queue.push(y)
      }
    }
  }
  dist
}

///|
/// 距離等於漢明距離（Q_n 的「圖距離 = 漢明距離」）。
pub fn dist_eq_hamming(n : Int32) -> Bool {
  let v = pow2i(n)
  let mut ok = true
  for a = 0; a < v; a = a + 1 {
    let d = graph_dist(n, a)
    for b = 0; b < v; b = b + 1 {
      if d[b] != hamming(a, b) {
        ok = false
      }
    }
  }
  ok
}

// ---------------------------------------------------------------- 軌道與可遷性

///|
/// 點 x 在群 aut 下的軌道（去重，升序）。
pub fn orbit(aut : Array[Array[Int32]], x : Int32) -> Array[Int32] {
  let seen : Array[Int32] = []
  for p in aut {
    let y = p[x]
    let mut hit = false
    for z in seen {
      if z == y {
        hit = true
      }
    }
    if !hit {
      seen.push(y)
    }
  }
  // 升序
  let out : Array[Int32] = []
  for y in seen {
    let idx : Array[Int32] = []
    let mut i = 0
    while i < out.length() && out[i] < y {
      i = i + 1
    }
    for j = 0; j < i; j = j + 1 {
      idx.push(out[j])
    }
    idx.push(y)
    for j = i; j < out.length(); j = j + 1 {
      idx.push(out[j])
    }
    out.clear()
    for z in idx {
      out.push(z)
    }
  }
  out
}

///|
/// 點 x 的穩定子大小（|Aut| / |軌道| 的實測值：直接數固定 x 的元素）。
pub fn stabilizer_size(aut : Array[Array[Int32]], x : Int32) -> Int32 {
  let mut c = 0
  for p in aut {
    if p[x] == x {
      c = c + 1
    }
  }
  c
}

///|
/// 是否在頂點上可遷。
pub fn is_vertex_transitive(aut : Array[Array[Int32]], n : Int32) -> Bool {
  let v = pow2i(n)
  orbit(aut, 0).length() == v
}

///|
/// 邊集在群下的軌道數（以邊索引 0 的軌道大小是否等於 |E| 判斷可遷）。
pub fn edge_orbit_size(
  n : Int32,
  aut : Array[Array[Int32]],
  edges : Array[(Int32, Int32)],
) -> Array[Int32] {
  let v = pow2i(n)
  let table = edge_index_table(n, edges)
  let seen : Array[Int32] = []
  for p in aut {
    let ep = edge_permutation_tbl(v, table, p, edges)
    let y = ep[0]
    let mut hit = false
    for z in seen {
      if z == y {
        hit = true
      }
    }
    if !hit {
      seen.push(y)
    }
  }
  seen
}

///|
/// 邊置換映射是否為同態：φ(σ∘τ) = φ(σ)∘φ(τ)，其中合成是「先 τ 後 σ」。
pub fn edge_perm_hom(
  n : Int32,
  aut : Array[Array[Int32]],
  edges : Array[(Int32, Int32)],
) -> Bool {
  let v = pow2i(n)
  let table = edge_index_table(n, edges)
  let mut ok = true
  for p in aut {
    let phi_p = edge_permutation_tbl(v, table, p, edges)
    for q in aut {
      let pq = perm_comp(p, q)
      let phi_pq = edge_permutation_tbl(v, table, pq, edges)
      let phi_q = edge_permutation_tbl(v, table, q, edges)
      let both = perm_comp(phi_p, phi_q)
      if !perm_eq(phi_pq, both) {
        ok = false
      }
    }
  }
  ok
}

///|
/// 邊 0 的穩定子大小（固定這條邊集合的自同構個數）。
pub fn edge_stabilizer_size(
  n : Int32,
  aut : Array[Array[Int32]],
  edges : Array[(Int32, Int32)],
) -> Int32 {
  let v = pow2i(n)
  let table = edge_index_table(n, edges)
  let mut c = 0
  for p in aut {
    if edge_permutation_tbl(v, table, p, edges)[0] == 0 {
      c = c + 1
    }
  }
  c
}

///|
/// 邊置換映射的核大小（φ(σ) = id 的元素個數）。
pub fn edge_perm_kernel_size(
  n : Int32,
  aut : Array[Array[Int32]],
  edges : Array[(Int32, Int32)],
) -> Int32 {
  let id = perm_id(edges.length())
  let v = pow2i(n)
  let table = edge_index_table(n, edges)
  let mut c = 0
  for p in aut {
    if perm_eq(edge_permutation_tbl(v, table, p, edges), id) {
      c = c + 1
    }
  }
  c
}

// ---------------------------------------------------------------- 摺疊 Q_n → Q_{n−1}

///|
/// 摺疊：丟掉最高位（第 n−1 位），得到 Q_{n−1} 的頂點。
pub fn fold_vertex(n : Int32, x : Int32) -> Int32 {
  if n <= 0 {
    return 0
  }
  x % pow2i(n - 1)
}

///|
/// 摺疊是否為圖同態：Q_n 的邊映到 Q_{n−1} 的邊或塌成一點（纖維內的那條邊）。
pub fn fold_is_hom(n : Int32) -> Bool {
  if n < 2 {
    return false
  }
  let mut ok = true
  for (a, b) in hyper_edges(n) {
    let fa = fold_vertex(n, a)
    let fb = fold_vertex(n, b)
    if fa != fb && !adj_qn(n - 1, fa, fb) {
      ok = false
    }
  }
  ok
}

///|
/// 摺疊的原像結構：對 Q_{n−1} 的每條邊，數它在 Q_n 中的原像邊數；
/// 回傳 (最小, 最大) 原像數。
pub fn fold_fiber_edge_range(n : Int32) -> (Int32, Int32) {
  let mut lo = 99
  let mut hi = 0
  let m = pow2i(n - 1)
  for (a, b) in hyper_edges(n - 1) {
    let mut c = 0
    for t = 0; t < 2; t = t + 1 {
      let x = a + t * m
      let y = b + t * m
      if adj_qn(n, x, y) {
        c = c + 1
      }
    }
    if c < lo {
      lo = c
    }
    if c > hi {
      hi = c
    }
  }
  (lo, hi)
}

///|
/// 摺疊纖維內部的邊數（每個纖維 {x, x+2^{n−1}} 恰為一條邊）：
/// 回傳纖維大小。
pub fn fold_fiber_size(n : Int32) -> Int32 {
  if n <= 0 {
    return 1
  }
  pow2i(n) / pow2i(n - 1)
}

// ---------------------------------------------------------------- 方向同態

///|
/// σ 是否為平移（σ(x) = x ⊕ σ(0)）。
pub fn is_translation(sigma : Array[Int32]) -> Bool {
  let b = sigma[0]
  let mut ok = true
  for x = 0; x < sigma.length(); x = x + 1 {
    if sigma[x] != translate(x, b) {
      ok = false
    }
  }
  ok
}

///|
/// 方向映射的核（direction_map 給出恆等座標置換的元素）。
pub fn direction_kernel(
  aut : Array[Array[Int32]],
  n : Int32,
) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  for s in aut {
    match direction_map(s, n) {
      Some(pi) => if perm_eq(pi, perm_id(n)) { out.push(s) }
      None => ()
    }
  }
  out
}

///|
/// 方向映射是否為群同態 Aut → S_n（先 τ 後 σ 對應 π(σ)∘π(τ)）。
/// 為何先算一次 π：direction_map 每次都是 O(|V|·n²)，直接塞進雙迴圈會是
/// O(|Aut|²·|V|·n²)（n = 4 實測 15 秒），先算 π 後只做 O(|Aut|²·n)。
pub fn direction_hom(aut : Array[Array[Int32]], n : Int32) -> Bool {
  let direct : Array[Array[Int32]] = []
  let mut all_some = true
  for p in aut {
    match direction_map(p, n) {
      Some(pi) => direct.push(pi)
      None => {
        all_some = false
        direct.push(perm_id(n))
      }
    }
  }
  if !all_some {
    return false
  }
  let index = perm_index(aut)
  let mut ok = true
  for i = 0; i < aut.length(); i = i + 1 {
    for j = 0; j < aut.length(); j = j + 1 {
      let k = perm_match(index, perm_comp(aut[i], aut[j]))
      if k < 0 || !perm_eq(direct[k], perm_comp(direct[i], direct[j])) {
        ok = false
      }
    }
  }
  ok
}

// ---------------------------------------------------------------- 共軛類

///|
/// 共軛類代表：回傳每個共軛類的一個代表（依 aut 的順序）。
/// 判等用字串鍵（置換表本身不便比較）。
pub fn conjugacy_representatives(
  aut : Array[Array[Int32]],
) -> Array[Array[Int32]] {
  let used : Array[Bool] = []
  for _i = 0; _i < aut.length(); _i = _i + 1 {
    used.push(false)
  }
  let index = perm_index(aut)
  let out : Array[Array[Int32]] = []
  for i = 0; i < aut.length(); i = i + 1 {
    if !used[i] {
      let r = aut[i]
      used[i] = true
      for g in aut {
        let ginv = perm_inv(g)
        let j = perm_match(index, perm_comp(perm_comp(g, r), ginv))
        if j >= 0 {
          used[j] = true
        }
      }
      out.push(r)
    }
  }
  out
}

///|
/// 共軛類大小表：對每個代表 r，數 { g r g⁻¹ : g ∈ Aut } 的不同值。
pub fn conjugacy_class_sizes(aut : Array[Array[Int32]]) -> Array[Int32] {
  let out : Array[Int32] = []
  for r in conjugacy_representatives(aut) {
    let keys : Array[String] = []
    for g in aut {
      let ginv = perm_inv(g)
      let k = perm_key(perm_comp(perm_comp(g, r), ginv))
      let mut hit = false
      for z in keys {
        if z == k {
          hit = true
        }
      }
      if !hit {
        keys.push(k)
      }
    }
    out.push(keys.length())
  }
  out
}

///|
/// 共軛類大小的總和（應等於群階，否則代表集的劃分有誤）。
pub fn conjugacy_sizes_sum(aut : Array[Array[Int32]]) -> Int32 {
  let mut s = 0
  for x in conjugacy_class_sizes(aut) {
    s = s + x
  }
  s
}
