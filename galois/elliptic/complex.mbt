///|
/// B0004 / elliptic 套件：**團複形與 GF(2) 同調**（T21、A27）
/// 對應 docs/B0004-定理體系.md §8。
///
/// 為什麼是這個複形：Paley 圖 P(q) 的**團複形**（flag complex）是「兩兩相容 ⇒ 整體相容」的
/// 單純複形實現，正是 B0001 的 Horn 邏輯（二元蘊含閉包）的幾何側面。
/// 同調一律在 GF(2) 上以顯式邊界矩陣 ＋ 消去法計算，並用**兩條獨立路徑**互相印證：
///   (1) Euler–Poincaré：Σ(−1)^d f_d = Σ(−1)^d β_d（面計數 vs Betti 數）；
///   (2) β₀ 與 1-骨架的連通分量數（BFS/並查集）必須相同。

///|
/// 列出鄰接矩陣的全部團（含大小 1）。
pub fn all_cliques(adj : Array[Array[Bool]]) -> Array[Array[Int32]] {
  let n = adj.length()
  let out : Array[Array[Int32]] = []
  let mut cur : Array[Array[Int32]] = []
  for v = 0; v < n; v = v + 1 {
    let c : Array[Int32] = [v]
    out.push(c)
    cur.push(c)
  }
  while cur.length() > 0 {
    let next : Array[Array[Int32]] = []
    for ci = 0; ci < cur.length(); ci = ci + 1 {
      let c = cur[ci]
      let last = c[c.length() - 1]
      for u = last + 1; u < n; u = u + 1 {
        let mut ok = true
        for k = 0; k < c.length(); k = k + 1 {
          if !adj[u][c[k]] {
            ok = false
          }
        }
        if ok {
          let nc = c.copy()
          nc.push(u)
          next.push(nc)
          out.push(nc)
        }
      }
    }
    cur = next
  }
  out
}

///|
/// 依大小分組（索引 = 頂點數 − 1，即維度）。
pub fn faces_by_dim(
  cliques : Array[Array[Int32]],
) -> Array[Array[Array[Int32]]] {
  let mut maxd = 0
  for i = 0; i < cliques.length(); i = i + 1 {
    if cliques[i].length() - 1 > maxd {
      maxd = cliques[i].length() - 1
    }
  }
  let out : Array[Array[Array[Int32]]] = []
  for d = 0; d <= maxd; d = d + 1 {
    let layer : Array[Array[Int32]] = []
    for i = 0; i < cliques.length(); i = i + 1 {
      if cliques[i].length() - 1 == d {
        layer.push(cliques[i])
      }
    }
    out.push(layer)
  }
  out
}

///|
/// 把 d-單形（頂點表）編碼成鍵，供邊界矩陣定位。
pub fn simplex_key(s : Array[Int32]) -> String {
  let sb = StringBuilder()
  for i = 0; i < s.length(); i = i + 1 {
    if i > 0 {
      sb.write_char(',')
    }
    sb.write_string(s[i].to_string())
  }
  sb.to_string()
}

///|
/// 邊界矩陣 ∂_d 的秩（GF(2)）：列 = d-單形，行 = (d−1)-單形。
pub fn boundary_rank(
  lower : Array[Array[Int32]],
  upper : Array[Array[Int32]],
) -> Int32 {
  if lower.length() == 0 || upper.length() == 0 {
    return 0
  }
  let cols = upper.length()
  let words = (cols + 63) / 64
  // 行索引
  let index : Array[String] = []
  for i = 0; i < upper.length(); i = i + 1 {
    index.push(simplex_key(upper[i]))
  }
  // 建立列位元組
  let rows : Array[Array[UInt64]] = []
  for i = 0; i < lower.length(); i = i + 1 {
    let s = lower[i]
    let row : Array[UInt64] = []
    for w = 0; w < words; w = w + 1 {
      row.push(0UL)
    }
    for k = 0; k < s.length(); k = k + 1 {
      // 去掉第 k 個頂點
      let f : Array[Int32] = []
      for m = 0; m < s.length(); m = m + 1 {
        if m != k {
          f.push(s[m])
        }
      }
      let key = simplex_key(f)
      let mut pos = -1
      for t = 0; t < index.length(); t = t + 1 {
        if index[t] == key {
          pos = t
        }
      }
      if pos >= 0 {
        let w = pos / 64
        let b = pos % 64
        row[w] = row[w] | (1UL << b)
      }
    }
    rows.push(row)
  }
  // GF(2) 消去
  let mut rank = 0
  for c = 0; c < cols; c = c + 1 {
    let w = c / 64
    let b = c % 64
    let mut piv = -1
    for r = rank; r < rows.length(); r = r + 1 {
      if ((rows[r][w] >> b) & 1UL) == 1UL {
        piv = r
        break
      }
    }
    if piv < 0 {
      continue
    }
    let tmp = rows[rank]
    rows[rank] = rows[piv]
    rows[piv] = tmp
    for r = 0; r < rows.length(); r = r + 1 {
      if r != rank && ((rows[r][w] >> b) & 1UL) == 1UL {
        for t = 0; t < words; t = t + 1 {
          rows[r][t] = rows[r][t] ^ rows[rank][t]
        }
      }
    }
    rank = rank + 1
    if rank == rows.length() {
      break
    }
  }
  rank
}

///|
/// 同調報告：面計數、各維 Betti 數、Euler 特徵（面 vs Betti）。
pub struct Homology {
  face_counts : Array[Int32]
  betti : Array[Int32]
  euler_faces : Int32
  euler_betti : Int32
}

///|
pub fn Homology::face_counts(self : Homology) -> Array[Int32] {
  self.face_counts
}

///|
pub fn Homology::betti(self : Homology) -> Array[Int32] {
  self.betti
}

///|
pub fn Homology::agree(self : Homology) -> Bool {
  self.euler_faces == self.euler_betti
}

///|
pub fn Homology::render(self : Homology) -> String {
  let fc = StringBuilder()
  let bt = StringBuilder()
  for d = 0; d < self.face_counts.length(); d = d + 1 {
    if d > 0 {
      fc.write_char('+')
      bt.write_char('+')
    }
    fc.write_string("f" + d.to_string() + "=" + self.face_counts[d].to_string())
    bt.write_string("β" + d.to_string() + "=" + self.betti[d].to_string())
  }
  fc.to_string() +
  "；" +
  bt.to_string() +
  "；χ(面)=" +
  self.euler_faces.to_string() +
  "，χ(β)=" +
  self.euler_betti.to_string()
}

///|
/// 由鄰接矩陣計算團複形（flag complex）的 GF(2) 同調。
pub fn flag_homology(adj : Array[Array[Bool]]) -> Homology {
  let cliques = all_cliques(adj)
  let layers = faces_by_dim(cliques)
  let ndim = layers.length()
  let face_counts : Array[Int32] = []
  for d = 0; d < ndim; d = d + 1 {
    face_counts.push(layers[d].length())
  }
  // rank ∂_d for d = 1..ndim−1
  let ranks : Array[Int32] = []
  for d = 0; d < ndim; d = d + 1 {
    ranks.push(0)
  }
  for d = 1; d < ndim; d = d + 1 {
    ranks[d] = boundary_rank(layers[d], layers[d - 1])
  }
  let betti : Array[Int32] = []
  for d = 0; d < ndim; d = d + 1 {
    let next_rank = if d + 1 < ndim { ranks[d + 1] } else { 0 }
    betti.push(face_counts[d] - ranks[d] - next_rank)
  }
  let mut ef = 0
  let mut eb = 0
  for d = 0; d < ndim; d = d + 1 {
    if d % 2 == 0 {
      ef = ef + face_counts[d]
      eb = eb + betti[d]
    } else {
      ef = ef - face_counts[d]
      eb = eb - betti[d]
    }
  }
  { face_counts, betti, euler_faces: ef, euler_betti: eb, }
}

///|
/// 1-骨架的連通分量數（BFS）——用於獨立印證 β₀。
pub fn components_of(adj : Array[Array[Bool]]) -> Int32 {
  let n = adj.length()
  let seen : Array[Bool] = []
  for _i = 0; _i < n; _i = _i + 1 {
    seen.push(false)
  }
  let mut comps = 0
  for s = 0; s < n; s = s + 1 {
    if !seen[s] {
      comps = comps + 1
      let queue : Array[Int32] = [s]
      seen[s] = true
      while queue.length() > 0 {
        let v = queue[queue.length() - 1]
        let _ = queue.pop()
        for u = 0; u < n; u = u + 1 {
          if adj[v][u] && !seen[u] {
            seen[u] = true
            queue.push(u)
          }
        }
      }
    }
  }
  comps
}
