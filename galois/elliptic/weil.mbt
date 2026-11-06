///|
/// B0004 / elliptic 套件：**撓群 E[n] ≅ (ℤ/n)²、Weil 配對、軌道計數**（T15–T17、A24）
/// 對應 docs/B0004-定理體系.md §2–§5。
///
/// 模型：E[n] 抽象為 (ℤ/n)²（D-E2），元素為 EPt{n, x, y}，x/y 是 ζ_n 指數形式的「座標」。
/// 群律是加法；Weil 配對 e_n(T,S) = ζ_n^{x_T y_S − y_T x_S}（行列式），值域 μ_n 以**指數**表示
///（μ_n ≅ ℤ/n，故乘法 ↔ 指數相加）。
///
/// 這不只是「定義好就能算」：e_n 的公理（交錯、雙線性、非退化、Galois 等變）全部在有限集合上
/// 窮舉驗證，而且在 n = 2 這種「−1 ≡ 1」的病態情形也會被檢核器照出來（見 BUG-5）。

///|
/// E[n] 的一個點。
pub struct EPt {
  n : Int32
  x : Int32
  y : Int32
}

///|
pub fn ept_make(n : Int32, x : Int32, y : Int32) -> EPt {
  { n, x: @modular.norm_mod(x, n), y: @modular.norm_mod(y, n), }
}

///|
pub fn EPt::key(self : EPt) -> String {
  self.x.to_string() + "," + self.y.to_string()
}

///|
pub fn EPt::is_zero(self : EPt) -> Bool {
  self.x == 0 && self.y == 0
}

///|
pub fn EPt::add(self : EPt, other : EPt) -> EPt {
  ept_make(self.n, self.x + other.x, self.y + other.y)
}

///|
pub fn EPt::neg(self : EPt) -> EPt {
  ept_make(self.n, -self.x, -self.y)
}

///|
pub fn EPt::scale(self : EPt, k : Int32) -> EPt {
  ept_make(self.n, self.x * k, self.y * k)
}

///|
/// 點的秩：最小的 k ≥ 1 使 k·P = O（n 有限，必存在）。
pub fn EPt::order(self : EPt) -> Int32 {
  if self.is_zero() {
    return 1
  }
  let mut k = 1
  let mut p = self
  while !p.is_zero() {
    p = p.add(self)
    k = k + 1
  }
  k
}

///|
/// 整個 E[n] = (ℤ/n)²（n² 個點）。
pub fn e_group(n : Int32) -> Array[EPt] {
  let out : Array[EPt] = []
  for x = 0; x < n; x = x + 1 {
    for y = 0; y < n; y = y + 1 {
      out.push(ept_make(n, x, y))
    }
  }
  out
}

///|
/// Weil 配對的**指數**：e_n(T,S) = ζ_n^exp，exp = det(T,S) mod n。
pub fn weil_exp(t : EPt, s : EPt) -> Int32 {
  let n = t.n
  @modular.norm_mod(t.x * s.y - t.y * s.x, n)
}

///|
/// 是否為基（(P,Q) 的行列式為單位 ⇒ 生成 E[n]）。
pub fn is_basis(p : EPt, q : EPt) -> Bool {
  let d = @modular.norm_mod(p.x * q.y - p.y * q.x, p.n)
  @modular.gcd(d, p.n) == 1
}

///|
/// 循環子群 L = ⟨P⟩ 的規範代表：生成元集合中的字典序最小者（用來把 n²−1 個非零點壓成 φ(n) 個生成元的類）。
pub fn cyclic_subgroup_key(p : EPt) -> String {
  let ord = p.order()
  let mut best = p
  // 只走**生成元** k·P（gcd(k, ord) = 1）：若把非生成元的倍數也算進來，
  // 兩個不同的循環子群會因為共用同一個「低階元素」（例如 3P 的階是 2）而塌成同一個鍵（BUG-5）。
  for k = 1; k < ord; k = k + 1 {
    if @modular.gcd(k, ord) == 1 {
      let q = p.scale(k)
      if q.key() < best.key() {
        best = q
      }
    }
  }
  best.key()
}

///|
/// 階恰為 n 的點數。
pub fn count_points_of_order(n : Int32) -> Int32 {
  let g = e_group(n)
  let mut c = 0
  for i = 0; i < g.length(); i = i + 1 {
    if g[i].order() == n {
      c = c + 1
    }
  }
  c
}

///|
/// 階為 n 的循環子群個數（= 射影直線 ℙ¹(ℤ/n) 的點數）。
pub fn count_cyclic_subgroups(n : Int32) -> Int32 {
  let g = e_group(n)
  let seen : Array[String] = []
  for i = 0; i < g.length(); i = i + 1 {
    if g[i].order() == n {
      let k = cyclic_subgroup_key(g[i])
      let mut hit = false
      for j = 0; j < seen.length(); j = j + 1 {
        if seen[j] == k {
          hit = true
        }
      }
      if !hit {
        seen.push(k)
      }
    }
  }
  seen.length()
}

///|
/// 行列式 = 1 的**辛基** (P,Q) 個數 = |SL₂(ℤ/n)| = [SL₂(ℤ):Γ(n)]（T16 的正確對應，見 BUG-5）。
pub fn count_det_one_bases(n : Int32) -> Int32 {
  let g = e_group(n)
  let mut c = 0
  for i = 0; i < g.length(); i = i + 1 {
    for j = 0; j < g.length(); j = j + 1 {
      if @modular.norm_mod(g[i].x * g[j].y - g[i].y * g[j].x, n) ==
        @modular.norm_mod(1, n) {
        c = c + 1
      }
    }
  }
  c
}

///|
/// 全部有序基（行列式為單位）= |GL₂(ℤ/n)| = [SL₂:Γ(n)]·φ(n)。
pub fn count_all_bases(n : Int32) -> Int32 {
  let g = e_group(n)
  let mut c = 0
  for i = 0; i < g.length(); i = i + 1 {
    for j = 0; j < g.length(); j = j + 1 {
      if is_basis(g[i], g[j]) {
        c = c + 1
      }
    }
  }
  c
}

///|
/// M = [[a,b],[c,d]] 作用在點上。
pub fn mact(m : (Int32, Int32, Int32, Int32), p : EPt) -> EPt {
  let (a, b, c, d) = m
  let n = p.n
  ept_make(n, a * p.x + b * p.y, c * p.x + d * p.y)
}

///|
/// 全部 GL₂(ℤ/n) 的元素（行列式為單位）。
pub fn gl2_group(n : Int32) -> Array[(Int32, Int32, Int32, Int32)] {
  let out : Array[(Int32, Int32, Int32, Int32)] = []
  for a = 0; a < n; a = a + 1 {
    for b = 0; b < n; b = b + 1 {
      for c = 0; c < n; c = c + 1 {
        for d = 0; d < n; d = d + 1 {
          let det = @modular.norm_mod(a * d - b * c, n)
          if @modular.gcd(det, n) == 1 {
            out.push((a, b, c, d))
          }
        }
      }
    }
  }
  out
}

///|
/// 固定循環子群 L 的穩定化子（在 SL₂(ℤ/n) 中）的階。
pub fn stabilizer_order_of_line(n : Int32, rep : EPt) -> Int32 {
  let g = @modular.sl2_group(n)
  let target = cyclic_subgroup_key(rep)
  let mut c = 0
  for i = 0; i < g.length(); i = i + 1 {
    let s = g[i]
    let p = ept_make(n, s.a * rep.x + s.b * rep.y, s.c * rep.x + s.d * rep.y)
    if !p.is_zero() && cyclic_subgroup_key(p) == target {
      c = c + 1
    }
  }
  c
}

///|
/// 二次特徵 χ_n(x)：x 是否為模 n 的平方（n 質數時；要求 gcd(x,n=1) 的情形另計）。
pub fn legendre(x : Int32, q : Int32) -> Int32 {
  let v = @modular.norm_mod(x, q)
  if v == 0 {
    return 0
  }
  let mut is_sq = false
  for i = 1; i < q; i = i + 1 {
    if @modular.norm_mod(i * i, q) == v {
      is_sq = true
    }
  }
  if is_sq {
    1
  } else {
    -1
  }
}
