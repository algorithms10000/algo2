///|
/// B0002 / matroid 套件：擬陣核心（D-B1、D-B2、D-B3、A8、A9）
/// 對應 docs/B0002-定理體系.md：X5、X6、P-B1–P-B3、T5。
///
/// 表示法：基集 E = {0..n-1}，迴路系統 𝒞 以位元集陣列給出（每個元素 ⊆ E）。
/// 閉包以「迴路消去」迭代計算：
///   反覆把「與 X 恰差一個元素」的迴路補齊，直到不動點。
/// 這正是 D-B2 的定義式，也是交換公理「生成」概念的演算法化。

///|
pub struct Matroid {
  name : String
  n : Int32
  circuits : Array[@bitset.BitSet]
}

///|
/// 由迴路系統建構擬陣。會檢查 (C1) 非空、(C2) 反鏈；違反則中止（資料錯誤不可靜默）。
pub fn Matroid::from_circuits(
  name : String,
  n : Int32,
  circuits : Array[@bitset.BitSet],
) -> Matroid {
  for i = 0; i < circuits.length(); i = i + 1 {
    let c = circuits[i]
    if c.count() == 0 {
      abort("Matroid::from_circuits 違反 C1：迴路不可為空")
    }
    if c.size() != n {
      abort("Matroid::from_circuits 迴路位元長度與 E 不符")
    }
    for j = 0; j < circuits.length(); j = j + 1 {
      if i != j && c.subset_of(circuits[j]) && !c.equals(circuits[j]) {
        abort("Matroid::from_circuits 違反 C2：迴路族必須是反鏈")
      }
    }
  }
  { name, n, circuits, }
}

///|
/// 由 GF(2) 列向量建構線性擬陣（A13＋A8 的入口）。
pub fn Matroid::from_gf2(
  name : String,
  columns : Array[@bitset.BitSet],
) -> Matroid {
  let circuits = circuits_from_gf2(columns)
  Matroid::from_circuits(name, columns.length(), circuits)
}

///|
/// 均勻擬陣 U(r, n)：獨立集 = 大小 ≤ r 的子集，迴路 = 所有 (r+1)-子集。
pub fn Matroid::uniform(r : Int32, n : Int32) -> Matroid {
  let all = @bitset.all_subsets(n)
  let circuits : Array[@bitset.BitSet] = []
  for i = 0; i < all.length(); i = i + 1 {
    if all[i].count() == r + 1 {
      circuits.push(all[i])
    }
  }
  Matroid::from_circuits(
    "U(" + r.to_string() + "," + n.to_string() + ")",
    n,
    circuits,
  )
}

///|
/// 圖擬陣 M(G)。
pub fn Matroid::graphic(
  name : String,
  vertices : Int32,
  edges : Array[(Int32, Int32)],
) -> Matroid {
  Matroid::from_gf2(name, graphic_columns(vertices, edges))
}

///|
/// Fano 擬陣 = PG(2,2)。
pub fn Matroid::fano() -> Matroid {
  Matroid::from_gf2("Fano", fano_columns())
}

///|
pub fn Matroid::name(self : Matroid) -> String {
  self.name
}

///|
pub fn Matroid::ground_size(self : Matroid) -> Int32 {
  self.n
}

///|
pub fn Matroid::circuits(self : Matroid) -> Array[@bitset.BitSet] {
  self.circuits
}

///|
pub fn Matroid::circuit_count(self : Matroid) -> Int32 {
  self.circuits.length()
}

///|
/// A8：迴路消去閉包 cl_𝒞(X)（D-B2）。
/// 單輪代價 O(|𝒞|·1) 位元運算；輪數 ≤ n，故 O(|𝒞|·n)。
pub fn Matroid::closure(self : Matroid, x : @bitset.BitSet) -> @bitset.BitSet {
  if x.size() != self.n {
    abort("Matroid::closure 位元長度與 E 不符")
  }
  let cur = x.copy()
  let mut changed = true
  let mut rounds = 0
  while changed && rounds <= self.n + 1 {
    changed = false
    rounds = rounds + 1
    for i = 0; i < self.circuits.length(); i = i + 1 {
      // 若 C ∖ cur 恰為一個元素，則該元素被生成
      let outside = self.circuits[i].minus(cur)
      if outside.count() == 1 {
        cur.union_inplace(self.circuits[i])
        changed = true
      }
    }
  }
  cur
}

///|
/// 獨立判定（D-B3）：不含任何迴路。
/// 等價於 |cl(X)| 的秩判準；此處用「迴路 ⊆ X」直判（P-B3）。
pub fn Matroid::independent(self : Matroid, x : @bitset.BitSet) -> Bool {
  for i = 0; i < self.circuits.length(); i = i + 1 {
    if self.circuits[i].subset_of(x) {
      return false
    }
  }
  true
}

///|
/// A9：秩 r(X) = X 中最大獨立子集大小（擬陣貪心：逐元素貪心加入即最優）。
pub fn Matroid::rank(self : Matroid, x : @bitset.BitSet) -> Int32 {
  let ids = x.ones()
  let chosen = @bitset.BitSet::new(self.n)
  for i = 0; i < ids.length(); i = i + 1 {
    let trial = chosen.plus_bit(ids[i])
    if self.independent(trial) {
      chosen.union_inplace(trial)
    }
  }
  chosen.count()
}

///|
/// P-B2：以秩反推閉包 cl_r(X) = { e : r(X∪{e}) = r(X) }（與 A8 的迴路路徑獨立）。
pub fn Matroid::closure_by_rank(
  self : Matroid,
  x : @bitset.BitSet,
) -> @bitset.BitSet {
  let base = self.rank(x)
  let out = @bitset.BitSet::new(self.n)
  for e = 0; e < self.n; e = e + 1 {
    if !x.get(e) {
      if self.rank(x.plus_bit(e)) == base {
        out.set(e)
      }
    }
  }
  x.union(out)
}
