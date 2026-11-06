///|
/// B0008 / cyclic 套件：**漸新態射**（assembly maps）。
///
/// 這裡把 Baum–Connes / 裝配映射（assembly map）在**有限維樣本**上的內容落成可執行的等式。
/// 對有限群 G，裝配映射 μ: K_*^G(EG) → K_*(C*_r G) 是同構，等價的度 0 敘述是
/// 「K₀(C*_r G) ⊗ ℂ 的維度 = 不可約表示個數 = 共軛類個數」，
/// 而 ℂ[G] 半單給出 HH_n(ℂ[G]) = 0（n ≥ 1）與 HC_{2k}(ℂ[G]) = 共軛類個數。
///
/// 四支映射（皆可反駁，數值來自不同路徑）：
///   * `ASForget`   忘記映射：HH₀ → HC₀ 為同構（維度相等，兩條獨立算式）；
///   * `ASIndex`    指數映射的秩 = 共軛類個數（由 Cayley 表暴力算 vs 由 HH₀ 算）；
///   * `ASBott`     Bott 週期性：HC_n = HC_{n−2}（n ≥ 2）；
///   * `ASAssembly` 裝配映射在正度數為同構：HH_n = 0（n ≥ 1）且 HC_{2k} = 秩、HC_{2k+1} = 0。

// ---------------------------------------------------------------- 群的基本運算

///|
/// 由 Cayley 表求單位元素的位置（列 e 使得 table[e*n + x] = x 對所有 x 成立）。
pub fn group_identity(n : Int32, table : Array[Int32]) -> Int32 {
  let mut id = -1
  for e = 0; e < n; e = e + 1 {
    let mut ok = true
    for x = 0; x < n; x = x + 1 {
      if table[e * n + x] != x {
        ok = false
      }
    }
    if ok && id < 0 {
      id = e
    }
  }
  id
}

///|
/// 由 Cayley 表求元素 a 的逆（table[a*n + b] = e = table[b*n + a]）。
pub fn group_inverse(n : Int32, table : Array[Int32], a : Int32) -> Int32 {
  let e = group_identity(n, table)
  let mut inv = -1
  for b = 0; b < n; b = b + 1 {
    if table[a * n + b] == e && table[b * n + a] == e && inv < 0 {
      inv = b
    }
  }
  inv
}

///|
/// 共軛類的個數：在 g ↦ x·g·x⁻¹ 的作用下把 {0,…,n−1} 分成軌道。
pub fn group_conjugacy_classes(n : Int32, table : Array[Int32]) -> Int32 {
  let seen : Array[Bool] = []
  for i = 0; i < n; i = i + 1 {
    seen.push(false)
  }
  let mut classes = 0
  for a = 0; a < n; a = a + 1 {
    if !seen[a] {
      classes = classes + 1
      seen[a] = true
      // 由 a 出發做閉包
      let mut changed = true
      while changed {
        changed = false
        for x = 0; x < n; x = x + 1 {
          let xi = group_inverse(n, table, x)
          for g = 0; g < n; g = g + 1 {
            if seen[g] {
              let conj = table[table[x * n + g] * n + xi]
              if !seen[conj] {
                seen[conj] = true
                changed = true
              }
            }
          }
        }
      }
    }
  }
  classes
}

///|
/// 群階驗證：Cayley 表是否真的是群（封閉、結合、有單位、有逆）。
pub fn group_table_ok(n : Int32, table : Array[Int32]) -> Bool {
  let e = group_identity(n, table)
  let mut ok = e >= 0
  for a = 0; a < n; a = a + 1 {
    if group_inverse(n, table, a) < 0 {
      ok = false
    }
    for b = 0; b < n; b = b + 1 {
      for c = 0; c < n; c = c + 1 {
        if table[table[a * n + b] * n + c] != table[a * n + table[b * n + c]] {
          ok = false
        }
      }
    }
  }
  ok
}

// ---------------------------------------------------------------- ASForget

///|
/// **ASForget**：忘記映射 HH₀(A) → HC₀(A) 是同構（SBI 序列的度 0 段）。
/// 兩邊各自由不同算式得出：左邊 dim A/[A,A]（交換子空間的餘維），右邊由 (b,B) 混複體的度 0 同調。
pub fn as_forget_ok(a : FdAlg) -> Bool {
  hh_dim(a, 0) == hc_dim_bicomplex(a, 0)
}

// ---------------------------------------------------------------- ASIndex

///|
/// **ASIndex**：裝配/指數映射的秩 = 不可約表示個數。
/// 對有限群，這兩者都等於共軛類個數；這裡讓「Cayley 表暴力算出的共軛類個數」
/// 與「代數算出的 dim HH₀(ℂ[G])」直接對撞。
pub fn as_index_matches_classes(n : Int32, table : Array[Int32]) -> Bool {
  let a = alg_group("ℂ[G]", n, table)
  group_conjugacy_classes(n, table) == hh_dim(a, 0)
}

// ---------------------------------------------------------------- ASBott

///|
/// **ASBott**：Bott 週期性 HC_n = HC_{n−2}（n ≥ 2）。
/// 對半單代數與截斷多項式代數都成立（見 docs/B0008 §B7 的實測表）。
pub fn as_bott_periodic(a : FdAlg, top : Int32) -> Bool {
  let mut ok = true
  for n = 2; n <= top; n = n + 1 {
    if hc_dim_bicomplex(a, n) != hc_dim_bicomplex(a, n - 2) {
      ok = false
    }
  }
  ok
}

// ---------------------------------------------------------------- ASAssembly

///|
/// **ASAssembly（正度數）**：HH_n(ℂ[G]) = 0（n ≥ 1）——即群同調 H_n(G;ℂ) = 0，
/// 對應「裝配映射在正度數上是同構」在樣本上的可見部分。
pub fn as_assembly_vanishing(a : FdAlg, n : Int32) -> Bool {
  hh_dim(a, n) == 0
}

///|
/// **ASAssembly（偶度數）**：HC_{2k}(ℂ[G]) = 共軛類個數（k ≥ 0）。
pub fn as_assembly_even_rank(
  n : Int32,
  table : Array[Int32],
  k : Int32,
) -> Bool {
  let a = alg_group("ℂ[G]", n, table)
  hc_dim_bicomplex(a, 2 * k) == group_conjugacy_classes(n, table)
}

///|
/// **ASAssembly（奇度數）**：HC_{2k+1}(ℂ[G]) = 0。
pub fn as_assembly_odd_vanishes(
  n : Int32,
  table : Array[Int32],
  k : Int32,
) -> Bool {
  let a = alg_group("ℂ[G]", n, table)
  hc_dim_bicomplex(a, 2 * k + 1) == 0
}
