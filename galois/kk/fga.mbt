///|
/// B0006 / kk 套件：**有限生成交換群的精確引擎**（A36）
/// 對應 docs/B0006-定理體系.md §2。
///
/// KK-理論的所有可計算面（UCT、六項正合列、Kasparov 乘積的自由部分）最後都化約成
/// 「有限生成交換群 + 整數矩陣」的運算：Smith 正規形、Hom、Ext、coker、ker。
/// 本檔只做這一層，而且**全部用整數精確計算**（Int64 + 歐幾里得消去），不用浮點。

///|
/// 有限生成交換群 G ≅ ℤ^rank ⊕ ℤ/d₁ ⊕ … ⊕ ℤ/dₖ，其中 1 < d₁ | d₂ | … | dₖ。
/// 不變因子序列 1 一律省略（ℤ/1 = 0）。
pub struct FgAb {
  rank : Int32
  tors : Array[Int64]
}

///|
/// 零群。
pub fn fga_zero() -> FgAb {
  { rank: 0, tors: [], }
}

///|
/// 自由群 ℤ^r。
pub fn fga_free(r : Int32) -> FgAb {
  { rank: r, tors: [], }
}

///|
/// 循環群 ℤ/d（d = 0 時視為 ℤ；d = 1 時視為 0）。
pub fn fga_cyclic(d : Int64) -> FgAb {
  if d == 0L {
    { rank: 1, tors: [], }
  } else if d == 1L || d == -1L {
    { rank: 0, tors: [], }
  } else {
    let a = if d < 0L { -d } else { d }
    { rank: 0, tors: [a], }
  }
}

///|
/// 直接建構（呼叫端保證 1 < d₁ | d₂ | …；否則請先 fga_canonical）。
pub fn fga_make(rank : Int32, tors : Array[Int64]) -> FgAb {
  { rank, tors, }
}

///|
/// 非負餘數（＊BUG-8 的教訓：MoonBit 的 % 對負數給負餘數，這裡一律歸一化）。
pub fn imod(a : Int64, b : Int64) -> Int64 {
  let r = a % b
  if r < 0L {
    r + (if b < 0L { -b } else { b })
  } else {
    r
  }
}

///|
/// 最大公因數（非負）。
pub fn igcd(a : Int64, b : Int64) -> Int64 {
  let mut x = if a < 0L { -a } else { a }
  let mut y = if b < 0L { -b } else { b }
  while y != 0L {
    let t = imod(x, y)
    x = y
    y = t
  }
  x
}

///|
/// 最小公倍數（非負；0 的情形回 0）。
pub fn ilcm(a : Int64, b : Int64) -> Int64 {
  if a == 0L || b == 0L {
    0L
  } else {
    let g = igcd(a, b)
    let x = if a < 0L { -a } else { a }
    x / g * (if b < 0L { -b } else { b })
  }
}

///|
/// 顯示用字串：`ℤ^2 ⊕ ℤ/4 ⊕ ℤ/12`；零群顯示 `0`。
pub fn fga_render(g : FgAb) -> String {
  let parts : Array[String] = []
  if g.rank > 0 {
    if g.rank == 1 {
      parts.push("ℤ")
    } else {
      parts.push("ℤ^" + g.rank.to_string())
    }
  }
  for d in g.tors {
    parts.push("ℤ/" + d.to_string())
  }
  if parts.length() == 0 {
    "0"
  } else {
    let sb = StringBuilder()
    for i = 0; i < parts.length(); i = i + 1 {
      if i > 0 {
        sb.write_string(" ⊕ ")
      }
      sb.write_string(parts[i])
    }
    sb.to_string()
  }
}

///|
/// 群同構判定（正規化後逐項比較）。
pub fn fga_eq(a : FgAb, b : FgAb) -> Bool {
  let ca = fga_canonical(a)
  let cb = fga_canonical(b)
  if ca.rank != cb.rank || ca.tors.length() != cb.tors.length() {
    false
  } else {
    let mut ok = true
    for i = 0; i < ca.tors.length(); i = i + 1 {
      if ca.tors[i] != cb.tors[i] {
        ok = false
      }
    }
    ok
  }
}

///|
/// 規範化：把撓部分逐對合併（ℤ/a ⊕ ℤ/b ≅ ℤ/gcd ⊕ ℤ/lcm），直到兩兩整除，再排序。
/// 演算法：反覆掃描相鄰對直到不再改變（有限終止：不變因子的「總和」單調不增）。
pub fn fga_canonical(g : FgAb) -> FgAb {
  let ts : Array[Int64] = []
  for d in g.tors {
    if d != 1L && d != 0L {
      ts.push(if d < 0L { -d } else { d })
    }
  }
  let mut changed = true
  while changed {
    changed = false
    for i = 0; i < ts.length(); i = i + 1 {
      for j = i + 1; j < ts.length(); j = j + 1 {
        let a = ts[i]
        let b = ts[j]
        if imod(b, a) != 0L {
          let gg = igcd(a, b)
          let ll = ilcm(a, b)
          ts[i] = gg
          ts[j] = ll
          changed = true
        }
      }
    }
  }
  // 移除 1（若 gcd 出現 1）並排序
  let out : Array[Int64] = []
  for d in ts {
    if d != 1L {
      out.push(d)
    }
  }
  out.sort()
  { rank: g.rank, tors: out, }
}

///|
/// 直和。
pub fn fga_direct_sum(a : FgAb, b : FgAb) -> FgAb {
  let ts : Array[Int64] = []
  for d in a.tors {
    ts.push(d)
  }
  for d in b.tors {
    ts.push(d)
  }
  fga_canonical({ rank: a.rank + b.rank, tors: ts, })
}

///|
/// Hom(G, H) 的精確計算：
///   Hom(ℤ, H) = H（**含 H 的撓部分**）、Hom(ℤ/d, H) = H[d] = ⊕_j ℤ/gcd(d, e_j)。
/// 故 Hom(G, H) = H^{rank G} ⊕ ⊕_{i,j} ℤ/gcd(d_i, e_j)。
/// ＊BUG-13＊：首版漏了「自由 ℤ 因子映到 H 的撓部分」這一項，
/// 導致 KK(ℂ, O_n) 被算成 0（正確為 ℤ/(n−1)），見 docs/B0006 §12。
pub fn fga_hom(g : FgAb, h : FgAb) -> FgAb {
  let ts : Array[Int64] = []
  // 每個自由 ℤ 因子貢獻一整份 H（含撓部分）
  for _i = 0; _i < g.rank; _i = _i + 1 {
    for e in h.tors {
      ts.push(e)
    }
  }
  // 撓因子 ℤ/d 只能映到 H 的 d-撓部分
  for d in g.tors {
    for e in h.tors {
      let gg = igcd(d, e)
      if gg != 1L {
        ts.push(gg)
      }
    }
  }
  fga_canonical({ rank: g.rank * h.rank, tors: ts, })
}

///|
/// Ext¹(G, H) 的精確計算：
///   Ext¹(ℤ, H) = 0、Ext¹(ℤ/d, H) = H/dH = (ℤ/d)^{rank H} ⊕ ⊕_j ℤ/gcd(d, e_j)。
/// ＊BUG-13 的同一處修正＊：自由部分被 dH 吃掉，但**留下 (ℤ/d)^{rank H}**，
/// 例如 Ext¹(ℤ/2, ℤ) = ℤ/2。
pub fn fga_ext1(g : FgAb, h : FgAb) -> FgAb {
  let ts : Array[Int64] = []
  for d in g.tors {
    for _j = 0; _j < h.rank; _j = _j + 1 {
      if d != 1L {
        ts.push(d)
      }
    }
    for e in h.tors {
      let gg = igcd(d, e)
      if gg != 1L {
        ts.push(gg)
      }
    }
  }
  fga_canonical({ rank: 0, tors: ts, })
}

// ---------------------------------------------------------------- 整數矩陣

///|
/// 整數矩陣（列主序）：`rows × cols`，元素 Int64。
pub struct IntMat {
  rows : Int32
  cols : Int32
  e : Array[Array[Int64]]
}

///|
/// 由二維陣列建矩陣（檢查矩形）。
pub fn intmat_of(e : Array[Array[Int64]]) -> IntMat {
  let rows = e.length()
  let cols = if rows == 0 { 0 } else { e[0].length() }
  { rows, cols, e, }
}

///|
/// 零矩陣。
pub fn intmat_zero(rows : Int32, cols : Int32) -> IntMat {
  let e : Array[Array[Int64]] = []
  for _i = 0; _i < rows; _i = _i + 1 {
    let row : Array[Int64] = []
    for _j = 0; _j < cols; _j = _j + 1 {
      row.push(0L)
    }
    e.push(row)
  }
  { rows, cols, e, }
}

///|
/// 單位矩陣。
pub fn intmat_identity(n : Int32, scale : Int64) -> IntMat {
  let m = intmat_zero(n, n)
  for i = 0; i < n; i = i + 1 {
    m.e[i][i] = scale
  }
  m
}

///|
/// 矩陣乘法。
pub fn intmat_mul(a : IntMat, b : IntMat) -> IntMat {
  let out = intmat_zero(a.rows, b.cols)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < b.cols; j = j + 1 {
      let mut s = 0L
      for k = 0; k < a.cols; k = k + 1 {
        s = s + a.e[i][k] * b.e[k][j]
      }
      out.e[i][j] = s
    }
  }
  out
}

///|
/// 轉置。
pub fn intmat_transpose(a : IntMat) -> IntMat {
  let out = intmat_zero(a.cols, a.rows)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < a.cols; j = j + 1 {
      out.e[j][i] = a.e[i][j]
    }
  }
  out
}

///|
/// 矩陣乘法（單元素，供檢核／小工具使用）。
pub fn intmat_apply(a : IntMat, v : Array[Int64]) -> Array[Int64] {
  let out : Array[Int64] = []
  for i = 0; i < a.rows; i = i + 1 {
    let mut s = 0L
    for j = 0; j < a.cols; j = j + 1 {
      s = s + a.e[i][j] * v[j]
    }
    out.push(s)
  }
  out
}

///|
/// 矩陣相等。
pub fn intmat_eq(a : IntMat, b : IntMat) -> Bool {
  if a.rows != b.rows || a.cols != b.cols {
    return false
  }
  let mut ok = true
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < a.cols; j = j + 1 {
      if a.e[i][j] != b.e[i][j] {
        ok = false
      }
    }
  }
  ok
}

///|
/// Smith 正規形的對角元（只回非零者，含重數；1 也保留以便計算秩）。
///
/// 算法：歐幾里得主元消去 + 「若不整除則加列」的除法修正。每一步都是
/// 可逆的整數列／行運算（換列、倍加、乘 −1），故對角元即不變因子（乘上符號）。
pub fn snf_diag(m : IntMat) -> Array[Int64] {
  let a : Array[Array[Int64]] = []
  for i = 0; i < m.rows; i = i + 1 {
    a.push(m.e[i].copy())
  }
  let rows = m.rows
  let cols = m.cols
  let mut r = 0
  let mut c = 0
  while r < rows && c < cols {
    // 找子矩陣中的非零元
    let mut pr = -1
    let mut pc = -1
    for i = r; i < rows; i = i + 1 {
      for j = c; j < cols; j = j + 1 {
        if pr < 0 && a[i][j] != 0L {
          pr = i
          pc = j
        }
      }
    }
    if pr < 0 {
      break
    }
    if pr != r {
      let t = a[r]
      a[r] = a[pr]
      a[pr] = t
    }
    if pc != c {
      for i = 0; i < rows; i = i + 1 {
        let t = a[i][c]
        a[i][c] = a[i][pc]
        a[i][pc] = t
      }
    }
    let mut changed = true
    while changed {
      changed = false
      // 清第 c 行（列運算）
      for i = r + 1; i < rows; i = i + 1 {
        if a[i][c] != 0L {
          let q = a[i][c] / a[r][c]
          for j = c; j < cols; j = j + 1 {
            a[i][j] = a[i][j] - q * a[r][j]
          }
          if a[i][c] != 0L {
            let t = a[r]
            a[r] = a[i]
            a[i] = t
            changed = true
            break
          }
        }
      }
      if changed {
        continue
      }
      // 清第 r 列（行運算）
      for j = c + 1; j < cols; j = j + 1 {
        if a[r][j] != 0L {
          let q = a[r][j] / a[r][c]
          for i = 0; i < rows; i = i + 1 {
            a[i][j] = a[i][j] - q * a[i][c]
          }
          if a[r][j] != 0L {
            for i = 0; i < rows; i = i + 1 {
              let t = a[i][c]
              a[i][c] = a[i][j]
              a[i][j] = t
            }
            changed = true
            break
          }
        }
      }
    }
    // 除法修正：若有元素不被主元整除，把該列加到主元列後重做
    let p = a[r][c]
    let mut bad_row = -1
    for i = r + 1; i < rows; i = i + 1 {
      for j = c + 1; j < cols; j = j + 1 {
        if bad_row < 0 && imod(a[i][j], p) != 0L {
          bad_row = i
        }
      }
    }
    if bad_row >= 0 {
      for j = c; j < cols; j = j + 1 {
        a[r][j] = a[r][j] + a[bad_row][j]
      }
      continue
    }
    if a[r][c] < 0L {
      for j = c; j < cols; j = j + 1 {
        a[r][j] = -a[r][j]
      }
    }
    r = r + 1
    c = c + 1
  }
  let out : Array[Int64] = []
  for i = 0; i < rows && i < cols; i = i + 1 {
    if a[i][i] != 0L {
      out.push(if a[i][i] < 0L { -a[i][i] } else { a[i][i] })
    }
  }
  out
}

///|
/// 整數矩陣的秩。
pub fn intmat_rank(m : IntMat) -> Int32 {
  snf_diag(m).length()
}

///|
/// coker(M: ℤ^cols → ℤ^rows) ≅ ℤ^{rows−r} ⊕ ⊕_i ℤ/d_i（d_i 為 SNF 的非 1 對角元）。
pub fn coker_of(m : IntMat) -> FgAb {
  let d = snf_diag(m)
  let r = d.length()
  let ts : Array[Int64] = []
  for x in d {
    if x != 1L {
      ts.push(x)
    }
  }
  fga_canonical({ rank: m.rows - r, tors: ts, })
}

///|
/// ker(M: ℤ^cols → ℤ^rows) ≅ ℤ^{cols−r}（ℤ^n 的子群恆自由）。
pub fn kernel_of(m : IntMat) -> FgAb {
  let r = intmat_rank(m)
  fga_free(m.cols - r)
}

///|
/// ℤ 上的線性映射是否單射（kernel = 0）。
pub fn is_injective(m : IntMat) -> Bool {
  intmat_rank(m) == m.cols
}

///|
/// ℤ 上的線性映射是否滿射（coker = 0）。
pub fn is_surjective(m : IntMat) -> Bool {
  intmat_rank(m) == m.rows
}
