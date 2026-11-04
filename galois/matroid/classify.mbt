///|
/// B0002 延伸 / matroid 套件：**二元判準（Tutte）與小型擬陣普查**（T9、T11、A19）
/// 對應 docs/B0002-定理體系.md §10、§13。
///
/// 兩條**互相獨立**的二元性判定：
///   (甲) 結構判準（Tutte 1958）：M 二元 ⟺ M 沒有 minor 同構於 U(2,4)、F7、F7*。
///   (乙) 顯式構造：取基 B，令 B 對應 GF(2)^r 的標準基；對 e ∉ B 取其**基本迴路** C(B,e)，
///        則在二元情況下必然有 col(e) = Σ_{b∈C∖{e}} col(b)（迴路上和為零，GF(2) 唯一最小相依）。
///        構造出的矩陣若與 M 有相同迴路族，即為 M 的 GF(2) 實現。
/// (乙) 是「有限制但完備」的判定：若 M 二元，則其 GF(2) 表示在同構意義下唯一，
/// 而基本迴路把它完全釘住；若 (乙) 失敗則 M 必非二元。兩條路徑必須給出同一答案。

///|
/// 取一個基（貪心，回傳基元素的索引表）。
pub fn Matroid::find_basis(self : Matroid) -> Array[Int32] {
  let out : Array[Int32] = []
  let cur = @bitset.BitSet::new(self.ground_size())
  for e = 0; e < self.ground_size(); e = e + 1 {
    let nxt = cur.copy()
    nxt.set(e)
    if self.rank(nxt) > self.rank(cur) {
      cur.set(e)
      out.push(e)
    }
  }
  out
}

///|
/// 對基 B 與 e ∉ B，找**基本迴路**（⊆ B ∪ {e} 且含 e 的迴路）；找不到回傳 None。
fn fundamental_circuit(
  m : Matroid,
  basis : Array[Int32],
  e : Int32,
) -> @bitset.BitSet? {
  let r = basis.length()
  // 在 B 的 2^r 個子集中找極小相依且含 e 的集合
  let mut best : @bitset.BitSet? = None
  let mut best_size = 1_000_000
  for mask = 0; mask < 1 << r; mask = mask + 1 {
    let cand = @bitset.BitSet::new(m.ground_size())
    cand.set(e)
    for j = 0; j < r; j = j + 1 {
      let bit = (mask >> j) & 1
      if bit == 1 {
        cand.set(basis[j])
      }
    }
    if m.rank(cand) < cand.count() {
      // 相依 → 檢查極小
      let mut minimal = true
      let ones = cand.ones()
      for k = 0; k < ones.length(); k = k + 1 {
        if ones[k] != e {
          let smaller = cand.copy()
          smaller.unset(ones[k])
          if m.rank(smaller) < smaller.count() {
            minimal = false
          }
        }
      }
      if minimal && cand.count() < best_size {
        best = Some(cand)
        best_size = cand.count()
      }
    }
  }
  best
}

///|
/// (乙) 由基本迴路顯式建構 GF(2) 表示，並驗證其迴路族與 M 相同。
pub fn Matroid::is_binary_by_construction(self : Matroid) -> Bool {
  let n = self.ground_size()
  let basis = self.find_basis()
  let r = basis.length()
  // 基元素 → 標準基向量
  let cols : Array[@bitset.BitSet] = []
  for i = 0; i < n; i = i + 1 {
    cols.push(@bitset.BitSet::new(if r == 0 { 1 } else { r }))
  }
  for j = 0; j < r; j = j + 1 {
    cols[basis[j]].set(j)
  }
  let in_basis : Array[Bool] = []
  for i = 0; i < n; i = i + 1 {
    in_basis.push(false)
  }
  for j = 0; j < r; j = j + 1 {
    in_basis[basis[j]] = true
  }
  for e = 0; e < n; e = e + 1 {
    if !in_basis[e] {
      match fundamental_circuit(self, basis, e) {
        None => return false
        Some(c) => {
          // col(e) = XOR of col(b), b ∈ C∖{e}
          let ones = c.ones()
          for k = 0; k < ones.length(); k = k + 1 {
            let b = ones[k]
            if b != e {
              let src = cols[b].copy()
              cols[e].union_inplace(cols[e].xor(src))
            }
          }
        }
      }
    }
  }
  // 用 GF(2) 迴路重建擬陣，比較迴路族
  let rebuilt = circuits_from_gf2(cols)
  if rebuilt.length() != self.circuit_count() {
    return false
  }
  for i = 0; i < rebuilt.length(); i = i + 1 {
    let mut hit = false
    for j = 0; j < self.circuit_count(); j = j + 1 {
      if rebuilt[i].equals(self.circuits()[j]) {
        hit = true
      }
    }
    if !hit {
      return false
    }
  }
  true
}

///|
/// (甲) Tutte 禁 minor 判準。
pub fn Matroid::is_binary_by_minors(self : Matroid) -> Bool {
  let targets = forbidden_binary_minors()
  if self.has_minor_in(targets) {
    return false
  }
  true
}

///|
/// 二元（以 (甲) 判定；與 (乙) 的一致性由檢核器要求）。
pub fn Matroid::is_binary(self : Matroid) -> Bool {
  self.is_binary_by_minors()
}

///|
/// 正則（可在任意體上表，等價於 ℤ 上全么模）＝無 U(2,4)、F7、F7* minor（Tutte 1958）。
/// 必然蘊含二元；反之不然（Fano 是二元但非正則）。
pub fn Matroid::is_regular(self : Matroid) -> Bool {
  if self.has_minor_in(forbidden_regular_minors()) {
    return false
  }
  true
}

///|
/// T11：均勻擬陣的平坦集計數
///   |ℱ(U(r,n))| = 2 + Σ_{k=1}^{r−1} C(n,k)   （0 < r < n）
/// 理由：平坦集恰為 ∅、所有 1 ≤ k ≤ r−1 的 k-子集、以及 E（r-子集都被閉成 E）。
/// 邊界：r ≥ n ⇒ Boolean 格（2^n）；r = 0 ⇒ 只有 E 一個平坦集（全部是環，cl(∅) = E）。
pub fn uniform_flat_formula(r : Int32, n : Int32) -> Int32 {
  if r <= 0 {
    return 1
  }
  if r >= n {
    return pow2_int(n)
  }
  let mut s = 2
  for k = 1; k < r; k = k + 1 {
    s = s + binom(n, k)
  }
  s
}

///|
fn pow2_int(n : Int32) -> Int32 {
  let mut r = 1
  for _i = 0; _i < n; _i = _i + 1 {
    r = r * 2
  }
  r
}

///|
/// T11 檢核：均勻擬陣的平坦數與公式相符。
pub fn check_uniform_flats(r : Int32, n : Int32) -> @galois.Check {
  let m = Matroid::uniform(r, n)
  let got = m.flat_count()
  let want = uniform_flat_formula(r, n)
  if got != want {
    return @galois.Check::make(
      "T11",
      "均勻擬陣平坦計數",
      false,
      "U(" +
      r.to_string() +
      "," +
      n.to_string() +
      ")：|ℱ|=" +
      got.to_string() +
      "，公式=" +
      want.to_string(),
    )
  }
  @galois.Check::make(
    "T11",
    "均勻擬陣平坦計數",
    true,
    "U(" +
    r.to_string() +
    "," +
    n.to_string() +
    ")：" +
    got.to_string() +
    " = 2 + Σ_{1≤k<r} C(n,k)",
  )
}

///|
/// 由「獨立集族」建構擬陣（迴路 = 極小相依集）；用於**獨立集路線**的普查。
pub fn from_independent_sets(
  name : String,
  n : Int32,
  independent : Array[@bitset.BitSet],
) -> Matroid {
  let circuits : Array[@bitset.BitSet] = []
  for mask = 1; mask < 1 << n; mask = mask + 1 {
    let s = @bitset.BitSet::from_mask(n, mask)
    let mut indep = false
    for i = 0; i < independent.length(); i = i + 1 {
      if independent[i].equals(s) {
        indep = true
      }
    }
    if !indep {
      // 相依 → 檢查極小
      let mut minimal = true
      let ones = s.ones()
      for k = 0; k < ones.length(); k = k + 1 {
        let smaller = s.copy()
        smaller.unset(ones[k])
        let mut s_indep = false
        for i = 0; i < independent.length(); i = i + 1 {
          if independent[i].equals(smaller) {
            s_indep = true
          }
        }
        if !s_indep {
          minimal = false
        }
      }
      if minimal {
        circuits.push(s)
      }
    }
  }
  Matroid::from_circuits(name, n, circuits)
}

///|
/// 遞迴列舉所有**反鏈**（不含空集）；`cand` 是所有非空子集。
fn antichain_helper(
  all_sets : Array[@bitset.BitSet],
  idx : Int32,
  chosen : Array[@bitset.BitSet],
  out : Array[Array[@bitset.BitSet]],
) -> Unit {
  if idx == all_sets.length() {
    out.push(chosen.copy())
    return
  }
  // 分支 1：不選
  antichain_helper(all_sets, idx + 1, chosen, out)
  // 分支 2：選（要求與已選者皆不可比）
  let mut comparable = false
  for i = 0; i < chosen.length(); i = i + 1 {
    if chosen[i].subset_of(all_sets[idx]) || all_sets[idx].subset_of(chosen[i]) {
      comparable = true
    }
  }
  if !comparable {
    chosen.push(all_sets[idx])
    antichain_helper(all_sets, idx + 1, chosen, out)
    let _ = chosen.pop()
  }
}

///|
/// 路線 (1)：以**迴路系統**列舉 n 元素上的所有擬陣。
pub fn all_matroids_by_circuits(n : Int32) -> Array[Matroid] {
  let all_sets : Array[@bitset.BitSet] = []
  let raw = @bitset.all_subsets(n)
  for i = 0; i < raw.length(); i = i + 1 {
    if raw[i].count() > 0 {
      all_sets.push(raw[i])
    }
  }
  let antichains : Array[Array[@bitset.BitSet]] = []
  antichain_helper(all_sets, 0, [], antichains)
  let out : Array[Matroid] = []
  for i = 0; i < antichains.length(); i = i + 1 {
    let fam = antichains[i]
    let m = Matroid::from_circuits("cand", n, fam)
    if m.check_circuit_axioms().passed() && m.check_exchange().passed() {
      out.push(m)
    }
  }
  out
}

///|
/// 路線 (2)：以**獨立集族**列舉 n 元素上的所有擬陣（I1–I3）。
/// 下閉族由其**極大元反鏈**唯一決定，故沿用反鏈列舉：族 = { X : X ⊆ 某個極大元 }。
pub fn all_matroids_by_independent_sets(n : Int32) -> Array[Matroid] {
  let all_sets : Array[@bitset.BitSet] = []
  let raw = @bitset.all_subsets(n)
  for i = 0; i < raw.length(); i = i + 1 {
    if raw[i].count() > 0 {
      all_sets.push(raw[i])
    }
  }
  let antichains : Array[Array[@bitset.BitSet]] = []
  antichain_helper(all_sets, 0, [], antichains)
  let out : Array[Matroid] = []
  for i = 0; i < antichains.length(); i = i + 1 {
    let maxima = antichains[i]
    let fam : Array[@bitset.BitSet] = [@bitset.BitSet::new(n)]
    for mask = 1; mask < 1 << n; mask = mask + 1 {
      let s = @bitset.BitSet::from_mask(n, mask)
      let mut inside = false
      for k = 0; k < maxima.length(); k = k + 1 {
        if s.subset_of(maxima[k]) {
          inside = true
        }
      }
      if inside {
        fam.push(s)
      }
    }
    // I3（增廣公理）：|A| < |B| ⇒ ∃ e ∈ B∖A 使 A∪{e} 仍在族中
    let mut ok = true
    for a = 0; a < fam.length(); a = a + 1 {
      for b = 0; b < fam.length(); b = b + 1 {
        if fam[a].count() < fam[b].count() {
          let mut extendable = false
          let ones = fam[b].ones()
          for k = 0; k < ones.length(); k = k + 1 {
            if !fam[a].get(ones[k]) {
              let bigger = fam[a].copy()
              bigger.set(ones[k])
              for c = 0; c < fam.length(); c = c + 1 {
                if fam[c].equals(bigger) {
                  extendable = true
                }
              }
            }
          }
          if !extendable {
            ok = false
          }
        }
      }
    }
    if ok {
      out.push(from_independent_sets("cand", n, fam))
    }
  }
  out
}

///|
/// 同構類的代表（依出現次序去重）。
pub fn isomorphism_classes(ms : Array[Matroid]) -> Array[Matroid] {
  let reps : Array[Matroid] = []
  for i = 0; i < ms.length(); i = i + 1 {
    let mut known = false
    for j = 0; j < reps.length(); j = j + 1 {
      if isomorphic(ms[i], reps[j]) {
        known = true
      }
    }
    if !known {
      reps.push(ms[i])
    }
  }
  reps
}
