///|
/// B0002 延伸 / matroid 套件：**Tutte 多項式、特徵多項式、色多項式**（D-B10、T12、A17、A18）
/// 對應 docs/B0002-定理體系.md §12。
///
/// 兩條**互相獨立**的路徑計算同一個多項式，再由檢核器要求逐係數相等：
///   (1) 刪除–壓縮遞迴  T(M) = T(M∖e) + T(M/e)；迴路 ⇒ ×y；橋（coloops）⇒ ×x
///   (2) 子集和公式      T(M) = Σ_{A⊆E} (x−1)^{r(E)−r(A)} (y−1)^{|A|−r(A)}
/// 這是本專案對「多項式層面」的等價性檢查方式（與 T5 的秩／迴路／閉包三路徑互比同一個思路）。

///|
/// 雙變數多項式：`c[i][j]` = x^i y^j 的係數。
pub struct Poly2 {
  size : Int32
  c : Array[Array[Int32]]
}

///|
pub fn Poly2::zero(size : Int32) -> Poly2 {
  let c : Array[Array[Int32]] = []
  for i = 0; i <= size; i = i + 1 {
    let row : Array[Int32] = []
    for j = 0; j <= size; j = j + 1 {
      row.push(0)
    }
    c.push(row)
  }
  { size, c, }
}

///|
pub fn Poly2::one(size : Int32) -> Poly2 {
  let p = Poly2::zero(size)
  p.c[0][0] = 1
  p
}

///|
pub fn Poly2::add(self : Poly2, other : Poly2) -> Poly2 {
  if self.size != other.size {
    abort("Poly2::add：維度不符")
  }
  let out = Poly2::zero(self.size)
  for i = 0; i <= self.size; i = i + 1 {
    for j = 0; j <= self.size; j = j + 1 {
      out.c[i][j] = self.c[i][j] + other.c[i][j]
    }
  }
  out
}

///|
/// 乘上 x（次數上移一格；先擴一格網格以免最高次項被截掉）。
pub fn Poly2::shift_x(self : Poly2) -> Poly2 {
  let base = self.resize(self.size + 1)
  let out = Poly2::zero(base.size)
  let self = base
  for i = 0; i < self.size; i = i + 1 {
    for j = 0; j <= self.size; j = j + 1 {
      out.c[i + 1][j] = self.c[i][j]
    }
  }
  out
}

///|
/// 乘上 y（先擴一格網格）。
pub fn Poly2::shift_y(self : Poly2) -> Poly2 {
  let base = self.resize(self.size + 1)
  let out = Poly2::zero(base.size)
  let self = base
  for i = 0; i <= self.size; i = i + 1 {
    for j = 0; j < self.size; j = j + 1 {
      out.c[i][j + 1] = self.c[i][j]
    }
  }
  out
}

///|
pub fn Poly2::equals(self : Poly2, other : Poly2) -> Bool {
  if self.size != other.size {
    return false
  }
  for i = 0; i <= self.size; i = i + 1 {
    for j = 0; j <= self.size; j = j + 1 {
      if self.c[i][j] != other.c[i][j] {
        return false
      }
    }
  }
  true
}

///|
/// 在 (x, y) 求值。
pub fn Poly2::eval(self : Poly2, x : Int32, y : Int32) -> Int32 {
  let mut sum = 0
  for i = 0; i <= self.size; i = i + 1 {
    for j = 0; j <= self.size; j = j + 1 {
      let mut term = self.c[i][j]
      for _a = 0; _a < i; _a = _a + 1 {
        term = term * x
      }
      for _b = 0; _b < j; _b = _b + 1 {
        term = term * y
      }
      sum = sum + term
    }
  }
  sum
}

///|
/// 化成可讀字串（只列非零項）。
pub fn Poly2::render(self : Poly2) -> String {
  let mut s = ""
  let mut first = true
  for i = 0; i <= self.size; i = i + 1 {
    for j = 0; j <= self.size; j = j + 1 {
      let k = self.c[i][j]
      if k != 0 {
        if !first {
          s = s + " + "
        }
        first = false
        if k != 1 {
          s = s + k.to_string()
        }
        if i > 0 {
          s = s + "x"
          if i > 1 {
            s = s + "^" + i.to_string()
          }
        }
        if j > 0 {
          s = s + "y"
          if j > 1 {
            s = s + "^" + j.to_string()
          }
        }
      }
    }
  }
  if first {
    "0"
  } else {
    s
  }
}

///|
/// 二項式係數（小整數）。
pub fn binom(n : Int32, k : Int32) -> Int32 {
  if k < 0 || k > n {
    return 0
  }
  let mut r = 1
  for i = 0; i < k; i = i + 1 {
    r = r * (n - i) / (i + 1)
  }
  r
}

///|
/// 元素 e 是否為迴路（r({e}) = 0）。
fn is_loop(m : Matroid, e : Int32) -> Bool {
  single_rank(m, e) == 0
}

///|
fn single_rank(m : Matroid, e : Int32) -> Int32 {
  let s = @bitset.BitSet::new(m.ground_size())
  s.set(e)
  m.rank(s)
}

///|
/// 元素 e 是否為橋（coloops）：r(E∖e) = r(E) − 1。
fn is_coloop(m : Matroid, e : Int32) -> Bool {
  let full = @bitset.BitSet::full(m.ground_size())
  let without = @bitset.BitSet::new(m.ground_size())
  for i = 0; i < m.ground_size(); i = i + 1 {
    if i != e {
      without.set(i)
    }
  }
  m.rank(without) == m.rank(full) - 1
}

///|
/// A17 路徑 (1)：刪除–壓縮遞迴。
pub fn tutte_deletion_contraction(m : Matroid) -> Poly2 {
  let size = m.ground_size()
  if size == 0 {
    return Poly2::one(0)
  }
  // 先處理迴路與橋
  for e = 0; e < size; e = e + 1 {
    if is_loop(m, e) {
      return tutte_deletion_contraction(m.delete_at(e)).shift_y()
    }
    if is_coloop(m, e) {
      return tutte_deletion_contraction(m.delete_at(e)).shift_x()
    }
  }
  // 一般元素：T(M) = T(M∖e) + T(M/e)
  let del = tutte_deletion_contraction(m.delete_at(0))
  let con = tutte_deletion_contraction(m.contract_at(0))
  let sum = del.add(con)
  // 維度對齊
  Poly2::resize(sum, size)
}

///|
/// 把多項式嵌到較大的網格（次數上限不同時使用）。
pub fn Poly2::resize(self : Poly2, size : Int32) -> Poly2 {
  if self.size >= size {
    return self
  }
  let out = Poly2::zero(size)
  for i = 0; i <= self.size; i = i + 1 {
    for j = 0; j <= self.size; j = j + 1 {
      out.c[i][j] = self.c[i][j]
    }
  }
  out
}

///|
/// A17 路徑 (2)：子集和公式 Σ_{A⊆E} (x−1)^{r(E)−r(A)} (y−1)^{|A|−r(A)}。
pub fn tutte_subsets(m : Matroid) -> Poly2 {
  let n = m.ground_size()
  let size = n
  let full = @bitset.BitSet::full(n)
  let re = m.rank(full)
  let out = Poly2::zero(size)
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let a = @bitset.BitSet::from_mask(n, mask)
    let ra = m.rank(a)
    let dx = re - ra
    let dy = a.count() - ra
    // (x−1)^dx = Σ_i C(dx,i) x^i (−1)^{dx−i}
    for i = 0; i <= dx; i = i + 1 {
      let cx = binom(dx, i) * (if (dx - i) % 2 == 0 { 1 } else { -1 })
      for j = 0; j <= dy; j = j + 1 {
        let cy = binom(dy, j) * (if (dy - j) % 2 == 0 { 1 } else { -1 })
        out.c[i][j] = out.c[i][j] + cx * cy
      }
    }
  }
  out
}

///|
/// A17：Tutte 多項式（預設走刪除–壓縮；兩條路徑由檢核器要求一致）。
pub fn Matroid::tutte(self : Matroid) -> Poly2 {
  tutte_deletion_contraction(self)
}

///|
/// 基（bases）數目：|A| = r(E) 且獨立的子集數。
pub fn Matroid::basis_count(self : Matroid) -> Int32 {
  let n = self.ground_size()
  let re = self.rank(@bitset.BitSet::full(n))
  let mut c = 0
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let a = @bitset.BitSet::from_mask(n, mask)
    if a.count() == re && self.rank(a) == re {
      c = c + 1
    }
  }
  c
}

///|
/// 獨立集數目。
pub fn Matroid::independent_count(self : Matroid) -> Int32 {
  let n = self.ground_size()
  let mut c = 0
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let a = @bitset.BitSet::from_mask(n, mask)
    if self.rank(a) == a.count() {
      c = c + 1
    }
  }
  c
}

///|
/// 生成集（spanning sets）數目。
pub fn Matroid::spanning_count(self : Matroid) -> Int32 {
  let n = self.ground_size()
  let re = self.rank(@bitset.BitSet::full(n))
  let mut c = 0
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let a = @bitset.BitSet::from_mask(n, mask)
    if self.rank(a) == re {
      c = c + 1
    }
  }
  c
}

///|
/// 單變數多項式（係數由低次到高次）。
pub struct Poly1 {
  c : Array[Int32]
}

///|
pub fn Poly1::eval(self : Poly1, x : Int32) -> Int32 {
  let mut sum = 0
  for i = self.c.length() - 1; i >= 0; i = i - 1 {
    sum = sum * x + self.c[i]
  }
  sum
}

///|
pub fn Poly1::render(self : Poly1) -> String {
  let mut s = ""
  let mut first = true
  for i = self.c.length() - 1; i >= 0; i = i - 1 {
    if self.c[i] != 0 {
      if !first {
        s = s + " + "
      }
      first = false
      if self.c[i] != 1 || i == 0 {
        s = s + self.c[i].to_string()
      }
      if i > 0 {
        s = s + "λ"
        if i > 1 {
          s = s + "^" + i.to_string()
        }
      }
    }
  }
  if first {
    "0"
  } else {
    s
  }
}

///|
/// 特徵多項式（定義式）χ(λ) = Σ_{A⊆E} (−1)^{|A|} λ^{r(E)−r(A)}。
pub fn Matroid::characteristic_definition(self : Matroid) -> Poly1 {
  let n = self.ground_size()
  let re = self.rank(@bitset.BitSet::full(n))
  let c : Array[Int32] = []
  for i = 0; i <= re; i = i + 1 {
    c.push(0)
  }
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let a = @bitset.BitSet::from_mask(n, mask)
    let deg = re - self.rank(a)
    let sign = if a.count() % 2 == 0 { 1 } else { -1 }
    c[deg] = c[deg] + sign
  }
  { c, }
}

///|
/// 特徵多項式（Tutte 路徑）χ(λ) = (−1)^{r(E)} T(1−λ, 0)。
pub fn Matroid::characteristic_from_tutte(self : Matroid) -> Poly1 {
  let n = self.ground_size()
  let re = self.rank(@bitset.BitSet::full(n))
  let t = tutte_deletion_contraction(self).resize(n)
  // 代入 x = 1−λ、y = 0：(1−λ)^i 展開成 λ 的多項式
  let c : Array[Int32] = []
  for i = 0; i <= re; i = i + 1 {
    c.push(0)
  }
  for i = 0; i <= n; i = i + 1 {
    // 只取 y^0 項
    let coef = t.c[i][0]
    if coef != 0 {
      // (1−λ)^i = Σ_k C(i,k) (−λ)^k
      for k = 0; k <= i; k = k + 1 {
        let sign = if k % 2 == 0 { 1 } else { -1 }
        let term = coef * binom(i, k) * sign
        if k < c.length() {
          c[k] = c[k] + term
        }
      }
    }
  }
  // 乘上 (−1)^{r(E)}
  let s = if re % 2 == 0 { 1 } else { -1 }
  for k = 0; k < c.length(); k = k + 1 {
    c[k] = c[k] * s
  }
  { c, }
}

///|
/// 暴力計算圖 G 的**正常著色數**（λ 種顏色）。
pub fn proper_coloring_count(
  vertices : Int32,
  edges : Array[(Int32, Int32)],
  lambda : Int32,
) -> Int32 {
  let n = vertices
  let total = pow_int(lambda, n)
  let mut count = 0
  for code = 0; code < total; code = code + 1 {
    let colors : Array[Int32] = []
    let mut rest = code
    for _i = 0; _i < n; _i = _i + 1 {
      colors.push(rest % lambda)
      rest = rest / lambda
    }
    let mut ok = true
    for e = 0; e < edges.length(); e = e + 1 {
      let (u, v) = edges[e]
      if colors[u] == colors[v] {
        ok = false
      }
    }
    if ok {
      count = count + 1
    }
  }
  count
}

///|
fn pow_int(base : Int32, exp : Int32) -> Int32 {
  let mut r = 1
  for _i = 0; _i < exp; _i = _i + 1 {
    r = r * base
  }
  r
}
