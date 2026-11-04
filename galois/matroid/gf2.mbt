///|
/// B0002 / matroid 套件：GF(2) 線性擬陣（A13）
///
/// 把每個基元素表示為 F₂^m 的一個列向量（位元集，第 j 位 = 第 j 個座標），
/// 以位元字組做高斯消去求秩。線性擬陣的三個古典實例都由此產生：
///   - 圖擬陣 M(G)：列向量 = 邊的關聯向量（邊 uv ↔ 單位向量 e_u + e_v）；
///   - Fano 擬陣 = PG(2,2)：列向量 = F₂³ 的 7 個非零向量；
///   - 均勻擬陣 U(2,4) **不是**二元擬陣，故以迴路直接給出（見 matroid.mbt）。
///
/// 對應 docs/B0002-定理體系.md：T5（秩/迴路/閉包三路徑）、A13。

///|
/// GF(2) 上線性組合的秩（位元高斯消去）。
/// pivots[p] 存放「最高位為 p」的基向量。時間 O(k·⌈m/64⌉)（k = 列數）。
pub fn rank_gf2(columns : Array[@bitset.BitSet]) -> Int32 {
  let pivots : Array[@bitset.BitSet] = []
  let mut rank = 0
  if columns.length() == 0 {
    return 0
  }
  let width = columns[0].size()
  for p = 0; p < width; p = p + 1 {
    pivots.push(@bitset.BitSet::new(width))
  }
  let has_pivot : Array[Bool] = []
  for p = 0; p < width; p = p + 1 {
    has_pivot.push(false)
  }
  for i = 0; i < columns.length(); i = i + 1 {
    let mut v = columns[i].copy()
    while true {
      match v.highest_bit() {
        None => break
        Some(p) =>
          if has_pivot[p] {
            v = v.xor(pivots[p])
          } else {
            pivots[p] = v
            has_pivot[p] = true
            rank = rank + 1
            break
          }
      }
    }
  }
  rank
}

///|
/// 由索引集合（相對於 columns 的索引）取出對應列向量。
pub fn select_columns(
  columns : Array[@bitset.BitSet],
  ids : Array[Int32],
  width : Int32,
) -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  for i = 0; i < ids.length(); i = i + 1 {
    out.push(columns[ids[i]])
  }
  let _ = width
  out
}

///|
/// 以 GF(2) 列向量判定獨立：rank == 列數。
pub fn independent_gf2(columns : Array[@bitset.BitSet]) -> Bool {
  rank_gf2(columns) == columns.length()
}

///|
/// 由 GF(2) 列向量抽取**迴路**（極小相依集），並同時檢查 D-B1 的 (C1)(C2)。
/// 作法：依基數遞增走訪所有子集；若相依，檢查其所有「去掉一個元素」的子集皆獨立（極小性）。
/// 時間 O(2^n·n·r·⌈m/64⌉)；僅適用於 n ≤ 20（本登記樣本 n ≤ 7）。
pub fn circuits_from_gf2(
  columns : Array[@bitset.BitSet],
) -> Array[@bitset.BitSet] {
  let n = columns.length()
  if n > 20 {
    abort("circuits_from_gf2 僅支援 n ≤ 20")
  }
  let subs = @bitset.subsets_by_cardinality(n)
  let out : Array[@bitset.BitSet] = []
  for k = 0; k < subs.length(); k = k + 1 {
    let s = subs[k]
    if s.count() == 0 {
      continue
    }
    let ids = s.ones()
    let cols = select_columns(columns, ids, 0)
    if independent_gf2(cols) {
      continue
    }
    // 極小相依？
    let mut minimal = true
    for drop = 0; drop < ids.length(); drop = drop + 1 {
      let reduced : Array[Int32] = []
      for t = 0; t < ids.length(); t = t + 1 {
        if t != drop {
          reduced.push(ids[t])
        }
      }
      if !independent_gf2(select_columns(columns, reduced, 0)) {
        minimal = false
      }
    }
    if minimal {
      out.push(s)
    }
  }
  out
}

///|
/// 圖擬陣 M(G) 的 GF(2) 關聯列向量：邊 (u,v) ↦ e_u + e_v（F₂^|V|）。
pub fn graphic_columns(
  vertices : Int32,
  edges : Array[(Int32, Int32)],
) -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  for i = 0; i < edges.length(); i = i + 1 {
    let (u, v) = edges[i]
    if u < 0 || u >= vertices || v < 0 || v >= vertices {
      abort("graphic_columns 頂點越界")
    }
    let col = @bitset.BitSet::new(vertices)
    col.set(u)
    col.set(v)
    // 自環 u == v 時向量為 0（迴路 {e}），GF(2) 中 e_u + e_u = 0
    if u == v {
      col.unset(u)
    }
    out.push(col)
  }
  out
}

///|
/// PG(2,2) 的 7 個非零列向量（Fano 擬陣）。第 j 個元素取 j 的二進位（1..7）。
pub fn fano_columns() -> Array[@bitset.BitSet] {
  let out : Array[@bitset.BitSet] = []
  for v = 1; v <= 7; v = v + 1 {
    let col = @bitset.BitSet::new(3)
    for b = 0; b < 3; b = b + 1 {
      let shifted = v >> b
      if (shifted & 1) == 1 {
        col.set(b)
      }
    }
    out.push(col)
  }
  out
}
