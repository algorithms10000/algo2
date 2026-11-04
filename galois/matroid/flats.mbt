///|
/// B0002 / matroid 套件：平坦集與幾何格檢核（D-B4、D-B5、P-B4、T6、A10）
/// 對應 docs/B0002-定理體系.md：E-B1、E-B5、E-B6。

///|
/// D-B4：F 平坦 ⟺ cl(F) = F。
pub fn Matroid::is_flat(self : Matroid, f : @bitset.BitSet) -> Bool {
  self.closure(f).equals(f)
}

///|
/// A10：全部平坦集（依遮蔽整數遞增，具決定性）。需 n ≤ 20。
/// 注意：平坦集含 ∅ 與 E（P-B4）。
pub fn Matroid::flats(self : Matroid) -> Array[@bitset.BitSet] {
  if self.n > 20 {
    abort("Matroid::flats 僅支援 n ≤ 20")
  }
  let out : Array[@bitset.BitSet] = []
  let subs = @bitset.all_subsets(self.n)
  for i = 0; i < subs.length(); i = i + 1 {
    if self.is_flat(subs[i]) {
      out.push(subs[i])
    }
  }
  out
}

///|
/// 平坦集個數（圖擬陣 = 頂點集分割數 = Bell 數，見 E-B8）。
pub fn Matroid::flat_count(self : Matroid) -> Int32 {
  self.flats().length()
}

///|
/// 原子（atom）= 秩 1 的平坦集。
pub fn Matroid::atoms(self : Matroid) -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  let flats = self.flats()
  for i = 0; i < flats.length(); i = i + 1 {
    if self.rank(flats[i]) == 1 {
      out.push(flats[i])
    }
  }
  out
}

///|
/// 覆蓋關係判定（以定義直判，不預設分級性）：
/// d ⋖ u ⟺ d ⊊ u 且不存在平坦集 w 使 d ⊊ w ⊊ u。
fn covers(
  flats : Array[@bitset.BitSet],
  d : @bitset.BitSet,
  u : @bitset.BitSet,
) -> Bool {
  if !d.subset_of(u) || d.equals(u) {
    return false
  }
  for i = 0; i < flats.length(); i = i + 1 {
    let w = flats[i]
    if d.subset_of(w) && w.subset_of(u) && !w.equals(d) && !w.equals(u) {
      return false
    }
  }
  true
}

///|
/// A10＋T6：幾何格四項檢核（分級、半模、原子生成、Jordan–Dedekind）。
/// 任何一項失敗都回報最小反例；T8 要求本檢核在負控制（非擬陣）上必須 FAIL。
pub fn Matroid::check_geometric(self : Matroid) -> @galois.Check {
  let flats = self.flats()
  let top = @bitset.BitSet::full(self.n)
  // 平坦格的**底元**是 cl(∅)（= 環集），不一定是 ∅：有環時 ∅ 不是平坦集。
  // 分級性只需在底元以上成立，故底元不要求下覆蓋。
  let bottom = self.closure(@bitset.BitSet::new(self.n))
  // (1) 分級：每個 F ≠ E 有覆蓋它的平坦集；每個 F ≠ ∅ 被某平坦集覆蓋；且秩差恰為 1
  for i = 0; i < flats.length(); i = i + 1 {
    let f = flats[i]
    let rf = self.rank(f)
    if !f.equals(top) {
      let mut up = false
      for j = 0; j < flats.length(); j = j + 1 {
        if covers(flats, f, flats[j]) {
          up = true
          if self.rank(flats[j]) != rf + 1 {
            return @galois.Check::make(
              "T6",
              "幾何格：分級",
              false,
              "覆蓋 " +
              f.render() +
              " ⋖ " +
              flats[j].render() +
              " 但秩差 ≠ 1",
            )
          }
        }
      }
      if !up {
        return @galois.Check::make(
          "T6",
          "幾何格：分級",
          false,
          "平坦集 " + f.render() + " 無上覆蓋",
        )
      }
    }
    if !f.equals(bottom) {
      let mut down = false
      for j = 0; j < flats.length(); j = j + 1 {
        if covers(flats, flats[j], f) {
          down = true
        }
      }
      if !down {
        return @galois.Check::make(
          "T6",
          "幾何格：分級",
          false,
          "平坦集 " + f.render() + " 無下覆蓋",
        )
      }
    }
  }
  // (2) 半模：r(F)+r(G) ≥ r(F∨G)+r(F∧G)
  for i = 0; i < flats.length(); i = i + 1 {
    for j = 0; j < flats.length(); j = j + 1 {
      let f = flats[i]
      let g = flats[j]
      let join = self.closure(f.union(g))
      let meet = f.intersect(g)
      let lhs = self.rank(f) + self.rank(g)
      let rhs = self.rank(join) + self.rank(meet)
      if lhs < rhs {
        return @galois.Check::make(
          "T6",
          "幾何格：半模",
          false,
          "F=" +
          f.render() +
          " G=" +
          g.render() +
          "：r(F)+r(G)=" +
          lhs.to_string() +
          " < r(F∨G)+r(F∧G)=" +
          rhs.to_string(),
        )
      }
      if !self.is_flat(meet) {
        return @galois.Check::make(
          "T6", "幾何格：半模", false, "F∩G 不是平坦集",
        )
      }
    }
  }
  // (3) 原子生成：F = cl(⋃ 原子 ⊆ F)
  let atoms = self.atoms()
  for i = 0; i < flats.length(); i = i + 1 {
    let f = flats[i]
    let gen = @bitset.BitSet::new(self.n)
    for j = 0; j < atoms.length(); j = j + 1 {
      if atoms[j].subset_of(f) {
        gen.union_inplace(atoms[j])
      }
    }
    if !self.closure(gen).equals(f) {
      return @galois.Check::make(
        "T6",
        "幾何格：原子生成",
        false,
        "平坦集 " + f.render() + " 不是其下原子的閉包",
      )
    }
  }
  // (4) Jordan–Dedekind：F、G 同時覆蓋 H ⟹ F∨G 覆蓋 F 與 G
  for i = 0; i < flats.length(); i = i + 1 {
    for j = 0; j < flats.length(); j = j + 1 {
      let f = flats[i]
      let g = flats[j]
      for k = 0; k < flats.length(); k = k + 1 {
        let h = flats[k]
        if covers(flats, h, f) && covers(flats, h, g) && !f.equals(g) {
          let join = self.closure(f.union(g))
          if !covers(flats, f, join) || !covers(flats, g, join) {
            return @galois.Check::make(
              "T6",
              "幾何格：Jordan–Dedekind",
              false,
              "H=" +
              h.render() +
              " 被 " +
              f.render() +
              "、" +
              g.render() +
              " 覆蓋，但 F∨G=" +
              join.render() +
              " 不是兩者的共同上覆蓋",
            )
          }
        }
      }
    }
  }
  @galois.Check::make(
    "T6",
    "幾何格（分級／半模／原子生成／Jordan–Dedekind）",
    true,
    "|ℱ|=" +
    flats.length().to_string() +
    "，r(E)=" +
    self.rank(top).to_string(),
  )
}

///|
/// 超平面（hyperplanes）= 秩 r(E)−1 的平坦集。T10 的餘迴路判準要用到。
pub fn Matroid::hyperplanes(self : Matroid) -> Array[@bitset.BitSet] {
  let rtop = self.rank(@bitset.BitSet::full(self.n))
  let all = self.flats()
  let out : Array[@bitset.BitSet] = []
  for i = 0; i < all.length(); i = i + 1 {
    if self.rank(all[i]) == rtop - 1 {
      out.push(all[i])
    }
  }
  out
}
