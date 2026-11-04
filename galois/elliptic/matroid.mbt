///|
/// B0004 / elliptic 套件：**撓群的線性擬陣與其簡化**（T20、A25）
/// 對應 docs/B0004-定理體系.md §7。
///
/// E[p]\{O} = 𝔽_p² 的全部 p²−1 個非零向量，取「線性相依」為相依關係：
///   - 秩 2；
///   - 迴路 = p+1 條「平行對」{v, −v}（p 奇）＋ 任三個來自**不同線**的向量（因 dim = 2）；
///   - 平行類 = 射影直線 ℙ¹(𝔽_p) 的 p+1 個點；
///   - 簡化（每類壓成一點）= 均勻擬陣 U(2, p+1)。
/// p = 2 時非零向量只有 3 個（互不平行的 3 點）⇒ 擬陣 ≅ U(2,3) = M(K₃)，即 B0002 的樣本。
/// 這條把「橢圓曲線撓群」（B0004）與「擬陣」（B0002）真的接起來，而不是比喻。

///|
/// 𝔽_p 上的秩（高斯消去），向量以 (x, y) 表示。
pub fn rank_mod_p(vecs : Array[(Int32, Int32)], p : Int32) -> Int32 {
  let rows : Array[Array[Int32]] = []
  for i = 0; i < vecs.length(); i = i + 1 {
    let (x, y) = vecs[i]
    let v : Array[Int32] = [@modular.norm_mod(x, p), @modular.norm_mod(y, p)]
    rows.push(v)
  }
  let mut rank = 0
  for col = 0; col < 2; col = col + 1 {
    let mut piv = -1
    for r = rank; r < rows.length(); r = r + 1 {
      if rows[r][col] != 0 {
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
    // 以乘法反元素歸一化，再消去其他列
    let inv = mod_inverse(rows[rank][col], p)
    for c = 0; c < 2; c = c + 1 {
      rows[rank][c] = @modular.norm_mod(rows[rank][c] * inv, p)
    }
    for r = 0; r < rows.length(); r = r + 1 {
      if r != rank && rows[r][col] != 0 {
        let f = rows[r][col]
        for c = 0; c < 2; c = c + 1 {
          rows[r][c] = @modular.norm_mod(rows[r][c] - f * rows[rank][c], p)
        }
      }
    }
    rank = rank + 1
  }
  rank
}

///|
/// 模 p 的乘法反元素（p 質數、a ≠ 0）——用費馬小定理的指數反覆平方法。
pub fn mod_inverse(a : Int32, p : Int32) -> Int32 {
  let mut r = 1
  let mut base = @modular.norm_mod(a, p)
  let mut e = p - 2
  while e > 0 {
    if e % 2 == 1 {
      r = @modular.norm_mod(r * base, p)
    }
    base = @modular.norm_mod(base * base, p)
    e = e / 2
  }
  r
}

///|
/// E[p]\{O} 的全部非零向量。
pub fn torsion_vectors(p : Int32) -> Array[(Int32, Int32)] {
  let out : Array[(Int32, Int32)] = []
  for x = 0; x < p; x = x + 1 {
    for y = 0; y < p; y = y + 1 {
      if x != 0 || y != 0 {
        out.push((x, y))
      }
    }
  }
  out
}

///|
/// 兩向量是否平行（同一個射影類）。
pub fn parallel_pair(a : (Int32, Int32), b : (Int32, Int32), p : Int32) -> Bool {
  let (ax, ay) = a
  let (bx, by) = b
  @modular.norm_mod(ax * by - ay * bx, p) == 0
}

///|
/// 平行類（射影直線的點）個數——應等於 p+1（T20 的「p+1 條線」）。
pub fn parallel_class_count(p : Int32) -> Int32 {
  let vs = torsion_vectors(p)
  let reps : Array[(Int32, Int32)] = []
  for i = 0; i < vs.length(); i = i + 1 {
    let mut hit = false
    for j = 0; j < reps.length(); j = j + 1 {
      if parallel_pair(vs[i], reps[j], p) {
        hit = true
      }
    }
    if !hit {
      reps.push(vs[i])
    }
  }
  reps.length()
}

///|
/// 迴路（極小相依集）：暴力列舉子集（僅 p ≤ 3 可行：p=3 時 2⁸ = 256 個子集）。
pub fn circuits_bruteforce(p : Int32) -> Array[Array[(Int32, Int32)]] {
  let vs = torsion_vectors(p)
  let m = vs.length()
  let out : Array[Array[(Int32, Int32)]] = []
  let total = 1 << m
  for mask = 1; mask < total; mask = mask + 1 {
    let sub : Array[(Int32, Int32)] = []
    for i = 0; i < m; i = i + 1 {
      if ((mask >> i) & 1) == 1 {
        sub.push(vs[i])
      }
    }
    if rank_mod_p(sub, p) < sub.length() {
      // 相依：檢查極小
      let mut minimal = true
      for k = 0; k < sub.length(); k = k + 1 {
        let rest : Array[(Int32, Int32)] = []
        for j = 0; j < sub.length(); j = j + 1 {
          if j != k {
            rest.push(sub[j])
          }
        }
        if rank_mod_p(rest, p) < rest.length() {
          minimal = false
        }
      }
      if minimal {
        out.push(sub)
      }
    }
  }
  out
}

///|
/// 平坦集（暴力）：F 平坦 ⟺ 每個 F 外的向量加入後秩都增加。
pub fn flats_bruteforce(p : Int32) -> Array[Array[(Int32, Int32)]] {
  let vs = torsion_vectors(p)
  let m = vs.length()
  let out : Array[Array[(Int32, Int32)]] = []
  let total = 1 << m
  for mask = 0; mask < total; mask = mask + 1 {
    let sub : Array[(Int32, Int32)] = []
    for i = 0; i < m; i = i + 1 {
      if ((mask >> i) & 1) == 1 {
        sub.push(vs[i])
      }
    }
    let r = rank_mod_p(sub, p)
    let mut flat = true
    for i = 0; i < m; i = i + 1 {
      if ((mask >> i) & 1) == 0 {
        let bigger : Array[(Int32, Int32)] = sub.copy()
        bigger.push(vs[i])
        if rank_mod_p(bigger, p) == r {
          flat = false
        }
      }
    }
    if flat {
      out.push(sub)
    }
  }
  out
}

///|
/// 簡化是否為均勻擬陣 U(2, p+1)：任兩平行類代表都獨立，任三類（各取一代表）都相依。
pub fn simplification_is_uniform(p : Int32) -> Bool {
  let vs = torsion_vectors(p)
  // 取每類一個代表
  let reps : Array[(Int32, Int32)] = []
  for i = 0; i < vs.length(); i = i + 1 {
    let mut hit = false
    for j = 0; j < reps.length(); j = j + 1 {
      if parallel_pair(vs[i], reps[j], p) {
        hit = true
      }
    }
    if !hit {
      reps.push(vs[i])
    }
  }
  let n = reps.length()
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      let pair : Array[(Int32, Int32)] = [reps[i], reps[j]]
      if rank_mod_p(pair, p) != 2 {
        return false
      }
    }
  }
  for i = 0; i < n; i = i + 1 {
    for j = i + 1; j < n; j = j + 1 {
      for k = j + 1; k < n; k = k + 1 {
        let trip : Array[(Int32, Int32)] = [reps[i], reps[j], reps[k]]
        if rank_mod_p(trip, p) != 2 {
          return false
        }
      }
    }
  }
  true
}
