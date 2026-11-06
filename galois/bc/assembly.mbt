///|
/// B0010 / bc 套件：**Baum–Connes 組裝映射的可計算片段**。
///
/// 猜想（無係數版，Baum–Connes–Kasparov）說：對可數離散群 G，組裝映射
///   μ_i^G : K_i^G(EG) → K_i(C*_r G)
/// 對 i = 0, 1 都是同構（EG = 真作用的分類空間）。
///
/// 本檔案處理**可完整算出兩側**的樣本：有限群。此時 EG = 點，
///   * 左邊（拓撲側）：K_0^G(pt) = R(G) = ℤ^{#不可約表示}（表示環，自由交換群）；
///   * 右邊（算子側）：C*_r G = ℂG ≅ ⊕_V M_{dim V}(ℂ)（Wedderburn），
///     故 K_0(ℂG) = ℤ^{#不可約表示}、K_1(ℂG) = 0（GL_d(ℂ) 連通）。
///   * μ_0 的複合 R(G) → K_0(ℂG) → ℤ^{#共軛類}（跡泛函 τ_g）**就是特徵表**。
///
/// 因此「μ 是同構」在本片段裡等價於「特徵表滿秩」，而特徵表滿秩的**實質理由**
/// 是帶類大小權重的特徵正交性 Σ_C |C| χ_V(C)·χ̄_W(C) = |G|·δ_VW。
/// 這條正交性不是恆真：把權重全設成 1 就立刻失敗（T82 負控制）。

// ---------------------------------------------------------------- 有限群樣本

///|
/// 有限群的可計算資料：階、共軛類大小、特徵表（列 = 不可約表示，行 = 共軛類，
/// 行 0 必須是單位元類）。表項為整數（D₈/Q₈ 的二維表示取實特徵）。
pub struct FinGroup {
  name : String
  order : Int64
  class_sizes : Array[Int64]
  table : Array[Array[Int64]]
}

///|
/// 不可約表示的個數 = 共軛類的個數。
pub fn n_irreps(g : FinGroup) -> Int32 {
  g.table.length()
}

///|
/// 共軛類的個數。
pub fn n_classes(g : FinGroup) -> Int32 {
  g.class_sizes.length()
}

///|
/// 表示維度 = χ_V(單位元) = 表的第 0 行。
pub fn irrep_dims(g : FinGroup) -> Array[Int64] {
  let out : Array[Int64] = []
  for v in g.table {
    out.push(v[0])
  }
  out
}

///|
/// Wedderburn 維度恆等式 Σ_V (dim V)² = |G|——它同時給出
/// ℂG ≅ ⊕_V M_{dim V}(ℂ) 的分塊結構，故 K_0(ℂG) = ℤ^{#irr}、K_1(ℂG) = 0。
pub fn wedderburn_sumsq(g : FinGroup) -> Int64 {
  let mut s = 0L
  for d in irrep_dims(g) {
    s = s + d * d
  }
  s
}

///|
/// 類大小總和 = |G|（共軛類確實做成分割）。
pub fn class_size_total(g : FinGroup) -> Int64 {
  let mut s = 0L
  for c in g.class_sizes {
    s = s + c
  }
  s
}

///|
/// **帶權重的 Gram 矩陣** G_{VW} = Σ_C |C|·χ_V(C)·χ_W(C)。
/// 特徵正交性說它等於 |G|·I。
pub fn gram_matrix(g : FinGroup) -> Array[Array[Int64]] {
  let out : Array[Array[Int64]] = []
  for v in g.table {
    let row : Array[Int64] = []
    for w in g.table {
      let mut s = 0L
      for c = 0; c < g.class_sizes.length(); c = c + 1 {
        s = s + g.class_sizes[c] * v[c] * w[c]
      }
      row.push(s)
    }
    out.push(row)
  }
  out
}

///|
/// Gram 矩陣是否等於 |G|·I。
pub fn gram_is_scalar(g : FinGroup) -> Bool {
  let m = gram_matrix(g)
  let mut ok = true
  for i = 0; i < m.length(); i = i + 1 {
    for j = 0; j < m.length(); j = j + 1 {
      let want = if i == j { g.order } else { 0L }
      if m[i][j] != want {
        ok = false
      }
    }
  }
  ok
}

///|
/// 負控制用的**無權重** Gram 矩陣：Σ_C χ_V(C)·χ_W(C)（把每個共軛類都當成大小 1）。
pub fn gram_matrix_unweighted(g : FinGroup) -> Array[Array[Int64]] {
  let out : Array[Array[Int64]] = []
  for v in g.table {
    let row : Array[Int64] = []
    for w in g.table {
      let mut s = 0L
      for c = 0; c < g.class_sizes.length(); c = c + 1 {
        s = s + v[c] * w[c]
      }
      row.push(s)
    }
    out.push(row)
  }
  out
}

///|
/// 無權重版本是否仍然「等於 |G|·I」——負控制：S₃、D₈、Q₈ 都必然失敗。
pub fn unweighted_gram_is_scalar(g : FinGroup) -> Bool {
  let m = gram_matrix_unweighted(g)
  let mut ok = true
  for i = 0; i < m.length(); i = i + 1 {
    for j = 0; j < m.length(); j = j + 1 {
      let want = if i == j { g.order } else { 0L }
      if m[i][j] != want {
        ok = false
      }
    }
  }
  ok
}

// ---------------------------------------------------------------- 組裝映射

///|
/// μ 的矩陣 = 特徵表本身（見檔案頭：複合 R(G) → K₀(ℂG) → ℤ^{#cc} 是 χ_{V}(C)）。
pub fn mu_matrix(g : FinGroup) -> Array[Array[Int64]] {
  g.table
}

///|
/// μ 在 ℚ 上的秩（用 `@analytic.rmat_rank`：有理高斯消去）。
pub fn mu_rank_rat(g : FinGroup) -> Int32 {
  @analytic.rmat_rank(@analytic.rmat_of_int(mu_matrix(g)))
}

///|
/// μ 在 F_p 上的秩（用 `@cyclic.rank_q`：三個質數取最大）。兩套演算法必須一致。
pub fn mu_rank_modp(g : FinGroup) -> Int32 {
  @cyclic.rank_q(mu_matrix(g))
}

///|
/// **組裝映射 μ 是群同構**的完整判準（本片段）：
///   (1) 兩側同秩：#irr = #cc（R(G) 與 K₀(ℂG) 的自由秩都是不可約表示個數）；
///   (2) 跡複合 = 特徵表滿秩（μ_0 單射）；
///   (3) 兩套秩演算法（ℚ 與 F_p）一致；
///   (4) Wedderburn：Σ_V dim²V = |G| ⇒ K₁(ℂG) = 0，故 μ_1: 0 → 0 同構；
///   (5) 特徵正交性成立（這是 (2) 的實質理由，不是重複計數）。
pub fn bc_assembly_iso(g : FinGroup) -> Bool {
  let n_irr = n_irreps(g)
  let n_cc = n_classes(g)
  let r_rat = mu_rank_rat(g)
  let r_modp = mu_rank_modp(g)
  n_irr == n_cc &&
  r_rat == n_irr &&
  r_modp == n_irr &&
  wedderburn_sumsq(g) == g.order &&
  class_size_total(g) == g.order &&
  gram_is_scalar(g)
}

///|
/// 樣本群（特徵表為整數或實整數的那一類；ℤ/n 走 `cyclicbc.mbt` 的分圓路線，
/// A₄ 走 `omega.mbt` 的 ℤ[ω] 路線）。
pub fn groups_int() -> Array[FinGroup] {
  [
    {
      name: "ℤ/2",
      order: 2L,
      class_sizes: [1L, 1L],
      table: [[1L, 1L], [1L, -1L]],
    },
    {
      name: "V₄ = ℤ/2×ℤ/2",
      order: 4L,
      class_sizes: [1L, 1L, 1L, 1L],
      table: [
        [1L, 1L, 1L, 1L],
        [1L, -1L, 1L, -1L],
        [1L, 1L, -1L, -1L],
        [1L, -1L, -1L, 1L],
      ],
    },
    {
      name: "S₃",
      order: 6L,
      class_sizes: [1L, 3L, 2L],
      table: [[1L, 1L, 1L], [1L, -1L, 1L], [2L, 0L, -1L]],
    },
    {
      name: "D₈",
      order: 8L,
      class_sizes: [1L, 1L, 2L, 2L, 2L],
      table: [
        [1L, 1L, 1L, 1L, 1L],
        [1L, 1L, 1L, -1L, -1L],
        [1L, 1L, -1L, 1L, -1L],
        [1L, 1L, -1L, -1L, 1L],
        [2L, -2L, 0L, 0L, 0L],
      ],
    },
    {
      name: "Q₈",
      order: 8L,
      class_sizes: [1L, 1L, 2L, 2L, 2L],
      table: [
        [1L, 1L, 1L, 1L, 1L],
        [1L, 1L, 1L, -1L, -1L],
        [1L, 1L, -1L, 1L, -1L],
        [1L, 1L, -1L, -1L, 1L],
        [2L, -2L, 0L, 0L, 0L],
      ],
    },
  ]
}
