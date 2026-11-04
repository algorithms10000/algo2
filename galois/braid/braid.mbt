///|
/// B0005 / braid 套件：**辮群 B_n 的置換商、純辮群、與模群的接縫**（T22、T24、A29）
/// 對應 docs/B0005-定理體系.md §2–§4。
///
/// 辮以**字**表示：正整數 i 代表 σ_i，負整數 −i 代表 σ_i^{-1}（i = 1..n−1）。
/// 所有檢核都在有限物件上窮舉：置換群 S_n（n! 個元素）、SL₂(ℤ/n)（有限群）、
/// 或長度受限的字集合（明示界限，不假裝是證明）。

///|
/// 字：元素的絕對值 = 生成元編號，正負 = 正/逆。
pub struct BraidWord {
  n : Int32
  letters : Array[Int32]
}

///|
pub fn bw_make(n : Int32, letters : Array[Int32]) -> BraidWord {
  { n, letters, }
}

///|
pub fn bw_empty(n : Int32) -> BraidWord {
  { n, letters: [], }
}

///|
pub fn BraidWord::length(self : BraidWord) -> Int32 {
  self.letters.length()
}

///|
/// 指數和（abelianization B_n → ℤ 的值）。
pub fn BraidWord::exponent_sum(self : BraidWord) -> Int32 {
  let mut s = 0
  for i = 0; i < self.letters.length(); i = i + 1 {
    let l = self.letters[i]
    if l > 0 {
      s = s + 1
    } else {
      s = s - 1
    }
  }
  s
}

///|
/// 逆字。
pub fn BraidWord::inverse(self : BraidWord) -> BraidWord {
  let out : Array[Int32] = []
  for i = self.letters.length() - 1; i >= 0; i = i - 1 {
    out.push(-self.letters[i])
  }
  { n: self.n, letters: out, }
}

///|
/// 串接。
pub fn BraidWord::concat(self : BraidWord, other : BraidWord) -> BraidWord {
  { n: self.n, letters: self.letters.copy() + other.letters.copy(), }
}

///|
/// 單一生成元的字（σ_i 或 σ_i^{-1}）。
pub fn bw_gen(n : Int32, i : Int32, inverse : Bool) -> BraidWord {
  if inverse {
    { n, letters: [-i], }
  } else {
    { n, letters: [i], }
  }
}

///|
/// 置換（0-indexed 陣列，perm[i] = 第 i 點的去向）。
pub fn perm_identity(n : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    out.push(i)
  }
  out
}

///|
/// 置換乘法：(p ∘ q)(i) = p(q(i))。
pub fn perm_mul(p : Array[Int32], q : Array[Int32]) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < q.length(); i = i + 1 {
    out.push(p[q[i]])
  }
  out
}

///|
/// 換位 (i, i+1)（1-indexed 的 i）。
pub fn transposition(n : Int32, i : Int32) -> Array[Int32] {
  let out = perm_identity(n)
  let a = i - 1
  let b = i
  out[a] = b
  out[b] = a
  out
}

///|
/// 字的置換像（T22 的群同態 B_n → S_n）。
pub fn word_permutation(w : BraidWord) -> Array[Int32] {
  let mut p = perm_identity(w.n)
  for idx = 0; idx < w.letters.length(); idx = idx + 1 {
    let l = w.letters[idx]
    let i = if l > 0 { l } else { -l }
    let t = transposition(w.n, i)
    p = if l > 0 { perm_mul(t, p) } else { perm_mul(t, p) }
  }
  p
}

///|
/// 置換的鍵（供去重）。
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

///|
/// 以換位為生成元生成整個 S_n，回傳元素個數（應為 n!）。
/// 這是 T22「B_n ↠ S_n 滿射」的可計算部分：換位生成 S_n。
pub fn generated_permutation_count(n : Int32) -> Int32 {
  let start = perm_identity(n)
  let seen : Array[String] = [perm_key(start)]
  let queue : Array[Array[Int32]] = [start]
  while queue.length() > 0 {
    let p = queue[0]
    let _ = queue.remove(0)
    for i = 1; i < n; i = i + 1 {
      let q = perm_mul(transposition(n, i), p)
      let k = perm_key(q)
      let mut hit = false
      for j = 0; j < seen.length(); j = j + 1 {
        if seen[j] == k {
          hit = true
        }
      }
      if !hit {
        seen.push(k)
        queue.push(q)
      }
    }
  }
  seen.length()
}

///|
/// 階乘（n ≤ 10）。
pub fn factorial(n : Int32) -> Int32 {
  let mut r = 1
  for i = 2; i <= n; i = i + 1 {
    r = r * i
  }
  r
}

///|
/// 辮關係在置換層的檢核（必須恆成立，因 S_n 的換位滿足辮關係）。
pub fn permutation_braid_relation(n : Int32, i : Int32) -> Bool {
  let a = bw_gen(n, i, false)
    .concat(bw_gen(n, i + 1, false))
    .concat(bw_gen(n, i, false))
  let b = bw_gen(n, i + 1, false)
    .concat(bw_gen(n, i, false))
    .concat(bw_gen(n, i + 1, false))
  perm_key(word_permutation(a)) == perm_key(word_permutation(b))
}

// ---------------------------------------------------------------- T24：B_3 → PSL₂(ℤ)

///|
/// B_3 → PSL₂(ℤ) 的像：σ_1 ↦ T = [[1,1],[0,1]]，σ_2 ↦ S T S = [[−1,0],[1,−1]]。
/// （以 T = (1,1,0,1) 為第一生成元搜尋出來的：需要 (σ1σ2σ1)² = ±I 與 (σ1σ2)³ = ±I，
///  即中心 ⟨(σ1σ2)³⟩ 落在核裡，於是映射下降為 B_3/中心 → PSL₂(ℤ)。）
pub fn psl_image(letter : Int32) -> (Int64, Int64, Int64, Int64) {
  // 回傳 (a,b,c,d) 代表 [[a,b],[c,d]]
  let t : (Int64, Int64, Int64, Int64) = (1L, 1L, 0L, 1L)
  let sts : (Int64, Int64, Int64, Int64) = (-1L, 0L, 1L, -1L)
  let base = if letter > 0 { letter } else { -letter }
  let m = if base == 1 { t } else { sts }
  if letter > 0 {
    m
  } else {
    // 逆矩陣 [[d,−b],[−c,a]]
    let (a, b, c, d) = m
    (d, -b, -c, a)
  }
}

///|
/// 2×2 整數矩陣乘法（Int64；B_3 的像元素很小，不會溢位）。
pub fn mat2_mul(
  x : (Int64, Int64, Int64, Int64),
  y : (Int64, Int64, Int64, Int64),
) -> (Int64, Int64, Int64, Int64) {
  let (a, b, c, d) = x
  let (e, f, g, h) = y
  (a * e + b * g, a * f + b * h, c * e + d * g, c * f + d * h)
}

///|
/// 辮字在 PSL₂(ℤ) 中的像（整數矩陣）。
pub fn psl_image_of_word(w : BraidWord) -> (Int64, Int64, Int64, Int64) {
  let mut m : (Int64, Int64, Int64, Int64) = (1L, 0L, 0L, 1L)
  for i = 0; i < w.letters.length(); i = i + 1 {
    m = mat2_mul(m, psl_image(w.letters[i]))
  }
  m
}

///|
/// 是否為 ±I。
pub fn mat2_is_pm_identity(m : (Int64, Int64, Int64, Int64)) -> Bool {
  let (a, b, c, d) = m
  (a == 1L && b == 0L && c == 0L && d == 1L) ||
  (a == -1L && b == 0L && c == 0L && d == -1L)
}

///|
/// 模 n 之下由 {(T), (STS)} 生成的子群是否等於整個 SL₂(ℤ/n)（BFS 閉包）。
/// 這是 T24 的「像足夠大」的可執行版本。
pub fn psl_image_generates_sl2(n : Int32) -> Bool {
  let all = @modular.sl2_group(n)
  let total = all.length()
  let keys : Array[String] = []
  for i = 0; i < total; i = i + 1 {
    keys.push(all[i].key())
  }
  // 生成元：T = [[1,1],[0,1]] 與 STS = [[−1,0],[1,−1]]
  let t = @modular.sl2_make(n, 1, 1, 0, 1)
  let s = @modular.sl2_make(n, 0, -1, 1, 0)
  let sts = t.mul(s).mul(t)
  let seeds : Array[@modular.Sl2] = [t, sts, t.inverse(), sts.inverse()]
  let id = @modular.sl2_make(n, 1, 0, 0, 1)
  let seen : Array[String] = [id.key()]
  let queue : Array[@modular.Sl2] = [id]
  while queue.length() > 0 {
    let g = queue[0]
    let _ = queue.remove(0)
    for gi = 0; gi < seeds.length(); gi = gi + 1 {
      let h = g.mul(seeds[gi])
      let k = h.key()
      let mut hit = false
      for j = 0; j < seen.length(); j = j + 1 {
        if seen[j] == k {
          hit = true
        }
      }
      if !hit {
        seen.push(k)
        queue.push(h)
      }
    }
  }
  seen.length() == total
}
