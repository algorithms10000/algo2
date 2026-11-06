///|
/// B0002 延伸 / matroid 套件：**minor、對偶、同構**（D-B8、D-B9、T9、T10、A15、A16）
/// 對應 docs/B0002-定理體系.md §10（Tutte 二元判準）與 §11（對偶擬陣）。
///
/// 全部以**秩函數**為唯一真相來源：
///   minor M/D.C 的秩  r'(X) = r_M(X ∪ C) − r_M(C)     （X ⊆ E∖(D∪C)）
///   minor 的迴路     = 該秩函數下的極小相依集（暴力但可證）
///   M* 的秩          r*(X) = |X| − r_M(E) + r_M(E∖X)
/// 這樣就完全避開「迴路刪除／壓縮」的表示法陷阱：定理只談秩，程式也只算秩。

///|
/// 遮罩的位元數。
fn popcount_mask(k : Int32, mask : Int32) -> Int32 {
  let mut c = 0
  for j = 0; j < k; j = j + 1 {
    let bit = (mask >> j) & 1
    if bit == 1 {
      c = c + 1
    }
  }
  c
}

///|
/// minor 的秩（mask 是「保留元素」上的位元遮罩）。
fn minor_rank(
  base : Matroid,
  contracted : @bitset.BitSet,
  kept : Array[Int32],
  rank_contracted : Int32,
  mask : Int32,
) -> Int32 {
  let x = contracted.copy()
  for j = 0; j < kept.length(); j = j + 1 {
    let bit = (mask >> j) & 1
    if bit == 1 {
      x.set(kept[j])
    }
  }
  base.rank(x) - rank_contracted
}

///|
/// D-B8：刪除與壓縮。`deleted`、`contracted` 必須不交。
pub fn Matroid::minor_of(
  self : Matroid,
  deleted : @bitset.BitSet,
  contracted : @bitset.BitSet,
) -> Matroid {
  let n = self.n
  for i = 0; i < n; i = i + 1 {
    if deleted.get(i) && contracted.get(i) {
      abort("Matroid::minor_of：同一元素不可既刪除又壓縮")
    }
  }
  let keep = @bitset.BitSet::new(n)
  for i = 0; i < n; i = i + 1 {
    if !deleted.get(i) && !contracted.get(i) {
      keep.set(i)
    }
  }
  let kept = keep.ones()
  let k = kept.length()
  let rc = self.rank(contracted)
  let circuits : Array[@bitset.BitSet] = []
  for mask = 1; mask < 1 << k; mask = mask + 1 {
    if minor_rank(self, contracted, kept, rc, mask) < popcount_mask(k, mask) {
      // 相依 → 檢查是否極小
      let mut minimal = true
      for drop = 0; drop < k; drop = drop + 1 {
        let bit = (mask >> drop) & 1
        if bit == 1 {
          let without = mask - (1 << drop)
          if minor_rank(self, contracted, kept, rc, without) <
            popcount_mask(k, without) {
            minimal = false
          }
        }
      }
      if minimal {
        circuits.push(@bitset.BitSet::from_mask(k, mask))
      }
    }
  }
  let mut name = self.name + "/"
  if deleted.count() + contracted.count() > 0 {
    name = name + deleted.render() + contracted.render()
  }
  Matroid::from_circuits(name, k, circuits)
}

///|
/// A15：刪除元素 e。
pub fn Matroid::delete_at(self : Matroid, e : Int32) -> Matroid {
  let del = @bitset.BitSet::new(self.n)
  del.set(e)
  self.minor_of(del, @bitset.BitSet::new(self.n))
}

///|
/// A15：壓縮元素 e（收縮 M/e）。
pub fn Matroid::contract_at(self : Matroid, e : Int32) -> Matroid {
  let con = @bitset.BitSet::new(self.n)
  con.set(e)
  self.minor_of(@bitset.BitSet::new(self.n), con)
}

///|
/// A16：對偶擬陣 M*。用秩公理 r*(X) = |X| − r(E) + r(E∖X) 定義，再取極小相依集作迴路。
pub fn Matroid::dual(self : Matroid) -> Matroid {
  let n = self.n
  let full = @bitset.BitSet::full(n)
  let re = self.rank(full)
  let circuits : Array[@bitset.BitSet] = []
  for mask = 1; mask < 1 << n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(n, mask)
    let rx = x.count() - re + self.rank(full.minus(x))
    if rx < x.count() {
      let mut minimal = true
      for drop = 0; drop < n; drop = drop + 1 {
        let bit = (mask >> drop) & 1
        if bit == 1 {
          let without = mask - (1 << drop)
          let y = @bitset.BitSet::from_mask(n, without)
          let ry = y.count() - re + self.rank(full.minus(y))
          if ry < y.count() {
            minimal = false
          }
        }
      }
      if minimal {
        circuits.push(x)
      }
    }
  }
  Matroid::from_circuits(self.name + "*", n, circuits)
}

///|
/// 對偶擬陣的秩函數（直接由公式給出，供檢核器與 `dual()` 交叉比對）。
pub fn Matroid::dual_rank(self : Matroid, x : @bitset.BitSet) -> Int32 {
  let full = @bitset.BitSet::full(self.n)
  x.count() - self.rank(full) + self.rank(full.minus(x))
}

///|
/// M 的餘迴路（cocircuits）= M* 的迴路。
pub fn Matroid::cocircuits(self : Matroid) -> Array[@bitset.BitSet] {
  self.dual().circuits()
}

///|
/// 把遮罩依排列重標號。
fn relabel_mask(n : Int32, perm : Array[Int32], mask : Int32) -> Int32 {
  let mut out = 0
  for j = 0; j < n; j = j + 1 {
    let bit = (mask >> j) & 1
    if bit == 1 {
      out = out | (1 << perm[j])
    }
  }
  out
}

///|
/// 秩函數在全部子集上的表（2^n 項）。
pub fn Matroid::rank_table(self : Matroid) -> Array[Int32] {
  let out : Array[Int32] = []
  for mask = 0; mask < 1 << self.n; mask = mask + 1 {
    out.push(self.rank(@bitset.BitSet::from_mask(self.n, mask)))
  }
  out
}

///|
/// 同構判定（暴力排列；n ≤ 7 適用）。以**秩表**全等為判準（秩唯一決定擬陣，T5）。
pub fn isomorphic(a : Matroid, b : Matroid) -> Bool {
  if a.ground_size() != b.ground_size() {
    return false
  }
  let n = a.ground_size()
  let ra = a.rank_table()
  let rb = b.rank_table()
  let perms = @braid.all_permutations(n)
  for p = 0; p < perms.length(); p = p + 1 {
    let perm = perms[p]
    let mut same = true
    for mask = 0; mask < 1 << n; mask = mask + 1 {
      let moved = relabel_mask(n, perm, mask)
      if ra[mask] != rb[moved] {
        same = false
      }
    }
    if same {
      return true
    }
  }
  false
}

///|
/// 是否同構於給定的目標擬陣（用於 Tutte 禁 minor 判準）。
pub fn Matroid::isomorphic_to(self : Matroid, other : Matroid) -> Bool {
  isomorphic(self, other)
}

///|
/// T9／A16：是否存在同構於 `targets` 中任一者的 minor（3^n 個 D、C 分割）。
pub fn Matroid::has_minor_in(self : Matroid, targets : Array[Matroid]) -> Bool {
  let n = self.n
  let mut found = false
  // 每個元素三態：0 = 保留、1 = 刪除、2 = 壓縮
  let state : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    state.push(0)
  }
  found = minor_search(self, targets, state, 0, found)
  found
}

///|
fn minor_search(
  m : Matroid,
  targets : Array[Matroid],
  state : Array[Int32],
  idx : Int32,
  found : Bool,
) -> Bool {
  if found {
    return true
  }
  if idx == m.ground_size() {
    let del = @bitset.BitSet::new(m.ground_size())
    let con = @bitset.BitSet::new(m.ground_size())
    let mut nd = 0
    let mut nc = 0
    for i = 0; i < m.ground_size(); i = i + 1 {
      if state[i] == 1 {
        del.set(i)
        nd = nd + 1
      }
      if state[i] == 2 {
        con.set(i)
        nc = nc + 1
      }
    }
    let size = m.ground_size() - nd - nc
    let mut hit = false
    for t = 0; t < targets.length(); t = t + 1 {
      if targets[t].ground_size() == size {
        let minor = m.minor_of(del, con)
        if isomorphic(minor, targets[t]) {
          hit = true
        }
      }
    }
    return hit
  }
  for s = 0; s < 3; s = s + 1 {
    state[idx] = s
    if minor_search(m, targets, state, idx + 1, found) {
      return true
    }
  }
  state[idx] = 0
  false
}

///|
/// **二元**擬陣的禁 minor 集合：只有 { U(2,4) }（Tutte 1958）。
///
/// ＊重要區分（開發期由檢核器抓到，見 docs/B0002 §10）＊
///   **二元**（可在 GF(2) 上表）⟺ 無 U(2,4) minor。
///   **正則**（可在**任意**體上表，等價於在 ℤ 上全么模）⟺ 無 U(2,4)、F7、F7* minor。
/// Fano 擬陣 F7 = PG(2,2) **本身是二元擬陣**（它就是 GF(2)³ 的 7 個非零向量），
/// 但**不是正則擬陣**。把 F7 放進二元禁集會把 Fano 誤判成非二元。
pub fn forbidden_binary_minors() -> Array[Matroid] {
  [Matroid::uniform(2, 4)]
}

///|
/// **正則**擬陣的禁 minor 集合：{ U(2,4), F7, F7* }（Tutte 1958）。
pub fn forbidden_regular_minors() -> Array[Matroid] {
  let fano = Matroid::fano()
  [Matroid::uniform(2, 4), fano, fano.dual()]
}

///|
/// 某個 minor 是否同構於 U(2,4)。
pub fn Matroid::has_uniform24_minor(self : Matroid) -> Bool {
  self.has_minor_in([Matroid::uniform(2, 4)])
}
