///|
/// B0004 / elliptic 套件：**由 Weil 配對的二次特徵造出的 Paley 圖／競賽，與 Ramsey 下界**（T18、T19、A26）
/// 對應 docs/B0004-定理體系.md §6。
///
/// 起點是**同一個**配對：在 ℙ¹(𝔽_q) 上，取 T=(1,t)、S=(1,s)，則
///   e_q(T,S) = ζ_q^{s−t}   ⇒   χ_q(e_q(T,S)) = χ_q(s−t)，
/// 這正是 Paley 著色。於是「橢圓曲線 q 等分點的配對」直接生出古典 Ramsey 構造：
///   q ≡ 1 (mod 4) → 對稱 → Paley 圖 P(q)；q ≡ 3 (mod 4) → 反對稱 → Paley 競賽 T(q)。
/// 鏡像對稱（T19）：乘以非平方元 λ 使 det 乘 λ²（保色）⇒ 自同構；而 det = 非平方的矩陣
///（如 diag(1,λ)）使 χ(det) 變號 ⇒ 圖自補、競賽反向同構。

///|
/// ℙ¹(𝔽_q) 的點：索引 0..q−1 為 ⟨(1,t)⟩，索引 q 為 ⟨(0,1)⟩（= 無窮遠點，對應 B0003 的尖點 ∞）。
pub fn projective_points(q : Int32) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for t = 0; t < q; t = t + 1 {
    out.push((1, t))
  }
  out.push((0, 1))
  out
}

///|
/// 有號配對矩陣：M[i][j] = χ_q(det(v_i, v_j))（q ≡ 1 mod 4 時對稱；q ≡ 3 mod 4 時反對稱）。
pub fn signature_matrix(q : Int32) -> Array[Array[Int32]] {
  let pts = projective_points(q)
  let n = pts.length()
  let m : Array[Array[Int32]] = []
  for i = 0; i < n; i = i + 1 {
    let row : Array[Int32] = []
    for j = 0; j < n; j = j + 1 {
      row.push(0)
    }
    m.push(row)
  }
  let sym = q % 4 == 1
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      if i != j {
        let (ax, ay) = pts[i]
        let (bx, by) = pts[j]
        let c = legendre(@modular.norm_mod(ax * by - ay * bx, q), q)
        if i < j || sym {
          m[i][j] = c
        } else {
          m[i][j] = -c
        }
      }
    }
  }
  m
}

///|
/// Paley 圖 P(q) 的鄰接矩陣（只取 𝔽_q 的 q 個點；q ≡ 1 mod 4）。
pub fn paley_adjacency(q : Int32) -> Array[Array[Bool]] {
  let out : Array[Array[Bool]] = []
  for i = 0; i < q; i = i + 1 {
    let row : Array[Bool] = []
    for j = 0; j < q; j = j + 1 {
      row.push(i != j && legendre(@modular.norm_mod(i - j, q), q) == 1)
    }
    out.push(row)
  }
  out
}

///|
/// Paley 競賽 T(q) 的出邊（i → j 若 χ_q(j−i) = 1；q ≡ 3 mod 4）。
pub fn paley_tournament(q : Int32) -> Array[Array[Bool]] {
  let out : Array[Array[Bool]] = []
  for i = 0; i < q; i = i + 1 {
    let row : Array[Bool] = []
    for j = 0; j < q; j = j + 1 {
      row.push(i != j && legendre(@modular.norm_mod(j - i, q), q) == 1)
    }
    out.push(row)
  }
  out
}

///|
/// 鄰接矩陣各點的度（出度）。
pub fn degrees(adj : Array[Array[Bool]]) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < adj.length(); i = i + 1 {
    let mut c = 0
    for j = 0; j < adj.length(); j = j + 1 {
      if adj[i][j] {
        c = c + 1
      }
    }
    out.push(c)
  }
  out
}

///|
/// 圖的團數 ω（回溯，取最大）。
pub fn clique_number(adj : Array[Array[Bool]]) -> Int32 {
  let n = adj.length()
  let best : Ref[Int32] = Ref(0)
  fn go(
    cand : Array[Int32],
    cur : Int32,
    adj : Array[Array[Bool]],
    best : Ref[Int32],
  ) -> Unit {
    if cur > best.val {
      best.val = cur
    }
    if cur + cand.length() <= best.val {
      return
    }
    for idx = 0; idx < cand.length(); idx = idx + 1 {
      let v = cand[idx]
      let next : Array[Int32] = []
      for k = idx + 1; k < cand.length(); k = k + 1 {
        if adj[v][cand[k]] {
          next.push(cand[k])
        }
      }
      go(next, cur + 1, adj, best)
    }
  }

  let all : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    all.push(i)
  }
  go(all, 0, adj, best)
  best.val
}

///|
/// 補圖。
pub fn complement(adj : Array[Array[Bool]]) -> Array[Array[Bool]] {
  let n = adj.length()
  let out : Array[Array[Bool]] = []
  for i = 0; i < n; i = i + 1 {
    let row : Array[Bool] = []
    for j = 0; j < n; j = j + 1 {
      row.push(i != j && !adj[i][j])
    }
    out.push(row)
  }
  out
}

///|
/// 非平方元（q 奇質數時必存在）。
pub fn non_square(q : Int32) -> Int32 {
  for i = 2; i < q; i = i + 1 {
    if legendre(i, q) == -1 {
      return i
    }
  }
  return -1
}

///|
/// 平移自同構檢核：adj(i,j) = adj(i+k, j+k)（Paley 圖頂點可遷的來源）。
pub fn translation_invariant(adj : Array[Array[Bool]], k : Int32) -> Bool {
  let n = adj.length()
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      let ii = @modular.norm_mod(i + k, n)
      let jj = @modular.norm_mod(j + k, n)
      if adj[i][j] != adj[ii][jj] {
        return false
      }
    }
  }
  true
}

///|
/// 自補檢核：存在 λ ≠ 0 使 adj(λi, λj) = ¬adj(i,j)（λ 為非平方元）。
pub fn self_complementary_witness(q : Int32, adj : Array[Array[Bool]]) -> Bool {
  let lam = non_square(q)
  if lam < 0 {
    return false
  }
  let n = adj.length()
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      if i != j {
        let a = adj[i][j]
        let ii = @modular.norm_mod(lam * i, q)
        let jj = @modular.norm_mod(lam * j, q)
        let b = adj[ii][jj]
        if a == b {
          return false
        }
      }
    }
  }
  true
}

///|
/// 反向同構檢核：出邊全被翻轉（競賽的情形，λ 為非平方元使 χ(det) 變號）。
pub fn reversal_witness(q : Int32, out : Array[Array[Bool]]) -> Bool {
  let lam = non_square(q)
  if lam < 0 {
    return false
  }
  for i = 0; i < q; i = i + 1 {
    for j = 0; j < q; j = j + 1 {
      if i != j {
        let a = out[i][j]
        let ii = @modular.norm_mod(lam * i, q)
        let jj = @modular.norm_mod(lam * j, q)
        let b = out[ii][jj]
        if a == b {
          return false
        }
      }
    }
  }
  true
}

///|
/// 競賽是否雙正則（每個點出度 = (q−1)/2，且每條邊的共同出鄰數 = (q−3)/4）。
pub fn is_doubly_regular(q : Int32, out : Array[Array[Bool]]) -> Bool {
  let k = (q - 1) / 2
  let lam = (q - 3) / 4
  let deg = degrees(out)
  for i = 0; i < q; i = i + 1 {
    if deg[i] != k {
      return false
    }
  }
  for i = 0; i < q; i = i + 1 {
    for j = 0; j < q; j = j + 1 {
      if i != j && out[i][j] {
        let mut c = 0
        for w = 0; w < q; w = w + 1 {
          if out[i][w] && out[j][w] {
            c = c + 1
          }
        }
        if c != lam {
          return false
        }
      }
    }
  }
  true
}

///|
/// 強正則參數檢核（v, k, λ, μ）：用於 Paley 圖 P(q) ⇒ srg(q, (q−1)/2, (q−5)/4, (q−1)/4)。
pub fn is_strongly_regular(
  adj : Array[Array[Bool]],
  v : Int32,
  k : Int32,
  lam : Int32,
  mu : Int32,
) -> Bool {
  let deg = degrees(adj)
  for i = 0; i < v; i = i + 1 {
    if deg[i] != k {
      return false
    }
  }
  for i = 0; i < v; i = i + 1 {
    for j = 0; j < v; j = j + 1 {
      if i != j {
        let mut c = 0
        for w = 0; w < v; w = w + 1 {
          if adj[i][w] && adj[j][w] {
            c = c + 1
          }
        }
        if adj[i][j] && c != lam {
          return false
        }
        if !adj[i][j] && c != mu {
          return false
        }
      }
    }
  }
  true
}

///|
/// 最大遞移子競賽大小：子集 S 遞移 ⟺ S 內的得分序列恰為 {0,1,…,|S|−1}（競賽的古典判準）。
pub fn max_transitive_subtournament(
  q : Int32,
  out : Array[Array[Bool]],
) -> Int32 {
  let mut best = 0
  let total = 1 << q
  for mask = 1; mask < total; mask = mask + 1 {
    let mut size = 0
    for v = 0; v < q; v = v + 1 {
      if ((mask >> v) & 1) == 1 {
        size = size + 1
      }
    }
    if size <= best {
      continue
    }
    // 得分序列
    let scores : Array[Int32] = []
    for v = 0; v < q; v = v + 1 {
      if ((mask >> v) & 1) == 1 {
        let mut s = 0
        for w = 0; w < q; w = w + 1 {
          if w != v && ((mask >> w) & 1) == 1 && out[v][w] {
            s = s + 1
          }
        }
        scores.push(s)
      }
    }
    scores.sort()
    let mut ok = true
    for idx = 0; idx < scores.length(); idx = idx + 1 {
      if scores[idx] != idx {
        ok = false
      }
    }
    if ok {
      best = size
    }
  }
  best
}
