///|
/// B0010 / bc 套件：**全局公理伽羅瓦對應**（需求文件第 1 行）
///
/// 「全局」有兩層意思，本檔把兩層都做成可執行檢核：
///
///   1. **形式層**（B0001 的伽羅瓦連接）：物件 ↔ 屬性的 (·)′ 連接給出概念格；
///      它是「公理系統」的載體（本輪不重做，見 B0001 的 A1–A6 與 X1–X6）。
///   2. **數論層**（本檔）：分圓擴張的伽羅華對應
///        H ≤ G = (ℤ/n)^×  ⟼  ℚ(ζ_n)^H = Fix(H)
///      是**反序一一對應**：H ⊆ H' ⟺ Fix(H) ⊇ Fix(H')。
///
/// 這兩層在這裡真的接上了：Fix(H) 的計算是「把 H 的每個 σ_k 寫成 (σ_k − I) 的行，
/// 取核」，也就是形式層的「屬性集合被物件共同滿足」的線性版本。
///
/// 負控制（本例自帶）：只用**維度**比較會失真——V₄ = (ℤ/8)^× 的三個二階子群
/// 維度都是 2，維度相等不能區分三個不同的不動子空間。因此判準必須做子空間包含
/// （以堆疊後的秩判定），本檔就是這樣做的（`fix_included`）。

///|
/// (ℤ/n)^× 的全部循環子群（單位群在 n ≤ 12 的樣本裡都是循環群或 V₄，
/// 兩者的所有子群都是循環的，故窮舉循環子群 = 窮舉全部子群）。
pub fn subgroups_of_units(n : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let keys : Array[String] = []
  for g in @cyclotomic.units_mod(n) {
    let h : Array[Int32] = []
    let mut p = g % n
    h.push(p)
    while p != 1 {
      p = p * g % n
      h.push(p)
    }
    // 排序成規範形式後去重
    let sorted = sort_ints(h)
    let key = ints_key(sorted)
    let mut seen = false
    for k in keys {
      if k == key {
        seen = true
      }
    }
    if !seen {
      keys.push(key)
      out.push(sorted)
    }
  }
  out
}

///|
/// 升序排序（插入排序，小陣列）。
fn sort_ints(a : Array[Int32]) -> Array[Int32] {
  let b : Array[Int32] = []
  for x in a {
    b.push(x)
  }
  for i = 1; i < b.length(); i = i + 1 {
    let v = b[i]
    let mut j = i - 1
    while j >= 0 && b[j] > v {
      b[j + 1] = b[j]
      j = j - 1
    }
    b[j + 1] = v
  }
  b
}

///|
/// 陣列的規範鍵。
fn ints_key(a : Array[Int32]) -> String {
  let sb = StringBuilder()
  for x in a {
    sb.write_string(x.to_string() + ",")
  }
  sb.to_string()
}

///|
/// H 對應的線性條件：(σ_k − I) 的所有行（k ∈ H）。
pub fn fix_rows(n : Int32, h : Array[Int32]) -> Array[Array[Int64]] {
  let d = @cyclotomic.cyclo_dim(n)
  let rows : Array[Array[Int64]] = []
  for k in h {
    let sk = @cyclotomic.sigma_matrix(n, k)
    for r = 0; r < d; r = r + 1 {
      let row : Array[Int64] = []
      for c = 0; c < d; c = c + 1 {
        row.push(sk[r][c] - (if r == c { 1L } else { 0L }))
      }
      rows.push(row)
    }
  }
  rows
}

///|
/// Fix(H) 的維度 = φ(n) − rank(rows)。
pub fn fix_dim(n : Int32, h : Array[Int32]) -> Int32 {
  @cyclotomic.cyclo_dim(n) -
  @analytic.rmat_rank(@analytic.rmat_of_int(fix_rows(n, h)))
}

///|
/// 子空間包含判定：由 rowsA 定義的空間 ⊆ 由 rowsB 定義的空間
/// ⟺ rank([rowsA; rowsB]) = rank(rowsA)。
pub fn fix_included(n : Int32, h_a : Array[Int32], h_b : Array[Int32]) -> Bool {
  let ra = fix_rows(n, h_a)
  let rb = fix_rows(n, h_b)
  let stacked : Array[Array[Int64]] = []
  for r in ra {
    stacked.push(r)
  }
  for r in rb {
    stacked.push(r)
  }
  @analytic.rmat_rank(@analytic.rmat_of_int(stacked)) ==
  @analytic.rmat_rank(@analytic.rmat_of_int(ra))
}

///|
/// 群子集包含：H ⊆ H'（皆為已排序陣列）。
pub fn set_subset(a : Array[Int32], b : Array[Int32]) -> Bool {
  let mut ok = true
  for x in a {
    let mut found = false
    for y in b {
      if x == y {
        found = true
      }
    }
    if !found {
      ok = false
    }
  }
  ok
}

///|
/// **T89 的核心**：H ⊆ H' ⟺ Fix(H) ⊇ Fix(H')，且 H ≠ H' ⇒ Fix(H) ≠ Fix(H')。
/// 對 n ∈ {5,7,8,9,12} 的全部子群對驗證。
pub fn check_global_galois_correspondence(n : Int32) -> Bool {
  let subs = subgroups_of_units(n)
  let mut ok = true
  for i = 0; i < subs.length(); i = i + 1 {
    for j = 0; j < subs.length(); j = j + 1 {
      let h = subs[i]
      let hp = subs[j]
      let sub_ok = set_subset(h, hp) == fix_included(n, hp, h)
      if !sub_ok {
        ok = false
      }
      // 一一性：H ≠ H' ⇒ 不動子空間不同
      if i < j {
        let a_in_b = fix_included(n, subs[i], subs[j])
        let b_in_a = fix_included(n, subs[j], subs[i])
        if a_in_b && b_in_a {
          ok = false
        }
      }
    }
  }
  // 維度必須是 [G:H]
  for h in subs {
    if fix_dim(n, h) != @cyclotomic.units_mod(n).length() / h.length() {
      ok = false
    }
  }
  ok
}

///|
/// **負控制**：只用維度比較，在 V₄ = (ℤ/8)^× 的三個二階子群上會失效
/// （三個不同的不動子空間維度都是 2）。回傳「如預期地失效」。
pub fn check_dimension_only_fails() -> Bool {
  let subs = subgroups_of_units(8)
  let mut count_order2 = 0
  let mut distinct_but_equal_dim = false
  for i = 0; i < subs.length(); i = i + 1 {
    if subs[i].length() == 2 {
      count_order2 = count_order2 + 1
    }
  }
  // 三個二階子群中，兩兩維度相同但子空間不同
  for i = 0; i < subs.length(); i = i + 1 {
    for j = i + 1; j < subs.length(); j = j + 1 {
      if subs[i].length() == subs[j].length() &&
        fix_dim(8, subs[i]) == fix_dim(8, subs[j]) &&
        !fix_included(8, subs[i], subs[j]) {
        distinct_but_equal_dim = true
      }
    }
  }
  count_order2 == 3 && distinct_but_equal_dim
}
