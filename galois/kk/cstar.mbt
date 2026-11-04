///|
/// B0006 / kk 套件：**C*-代數側的 K-群與六項正合列**（A37、A38）
/// 對應 docs/B0006-定理體系.md §3–§5。
///
/// 本檔的物件都是**真的代數**，但只取「K-群可精確計算」的那一類：
///   * 有限維 C*-代數 A ≅ ⊕ M_{n_i}(ℂ)（K₀ = ℤ^{塊數}、K₁ = 0）；
///   * Toeplitz 代數 𝒯_n（正交等距元 s_i^* s_j = δ_ij、Σ s_i s_i^* = 1 − p）；
///   * Cuntz 代數 O_n = 𝒯_n / K；
///   * 圓 C(S¹)（K₀ = K₁ = ℤ）。
/// 六項正合列在本檔是**可檢核的整數線性代數**：在自由群上「正合」等價於
/// 「後映射與前映射合成為 0，且兩秩相加等於節點群的秩」。

///|
/// K-群對 (K₀, K₁)。
pub struct KPair {
  k0 : FgAb
  k1 : FgAb
}

///|
/// 建構。
pub fn kpair(k0 : FgAb, k1 : FgAb) -> KPair {
  { k0, k1, }
}

///|
/// 顯示。
pub fn kpair_render(k : KPair) -> String {
  "(K₀ = " + fga_render(k.k0) + "、K₁ = " + fga_render(k.k1) + ")"
}

///|
/// Bott 週期性：K_{i+2} = K_i（交換 K₀ 與 K₁）。
pub fn kpair_shift(k : KPair) -> KPair {
  { k0: k.k1, k1: k.k0, }
}

///|
/// K-群同構判定。
pub fn kpair_eq(a : KPair, b : KPair) -> Bool {
  fga_eq(a.k0, b.k0) && fga_eq(a.k1, b.k1)
}

// ---------------------------------------------------------------- 有限維 C*-代數

///|
/// 有限維 C*-代數 A ≅ ⊕_i M_{n_i}(ℂ)：只記各簡單塊的大小。
pub struct FDA {
  blocks : Array[Int32]
}

///|
/// 建構。
pub fn fda(blocks : Array[Int32]) -> FDA {
  { blocks, }
}

///|
/// 複維數 Σ n_i²。
pub fn fda_dim(a : FDA) -> Int64 {
  let mut s = 0L
  for n in a.blocks {
    s = s + n.to_int64() * n.to_int64()
  }
  s
}

///|
/// 塊數（= 中心維數 = K₀ 的秩）。
pub fn fda_rank(a : FDA) -> Int32 {
  a.blocks.length()
}

///|
/// K₀(A) = ℤ^{塊數}、K₁(A) = 0（M_n(ℂ) 的 K₀ = ℤ、K₁ = 0，K₀ 對直和可加）。
pub fn fda_k(a : FDA) -> KPair {
  { k0: fga_free(a.blocks.length()), k1: fga_zero(), }
}

///|
/// 單位元 [1] 在 K₀ 的像：每個簡單塊貢獻一個 1。
pub fn fda_unit(a : FDA) -> Array[Int64] {
  let out : Array[Int64] = []
  for _n in a.blocks {
    out.push(1L)
  }
  out
}

///|
/// 商 A/I：遮罩為 true 的塊保留，其餘砍掉（理想 I 由 false 的塊給出）。
pub fn fda_quotient(a : FDA, mask : Array[Bool]) -> FDA {
  let bs : Array[Int32] = []
  for i = 0; i < a.blocks.length(); i = i + 1 {
    if mask[i] {
      bs.push(a.blocks[i])
    }
  }
  { blocks: bs, }
}

///|
/// 理想 I（遮罩為 true 的塊）。
pub fn fda_ideal(a : FDA, mask : Array[Bool]) -> FDA {
  fda_quotient(a, mask)
}

///|
/// 是否單（只有一個塊）。
pub fn fda_is_simple(a : FDA) -> Bool {
  a.blocks.length() == 1
}

// ---------------------------------------------------------------- 六項正合列

///|
/// 短正合列 0 → J → A → Q → 0 的**循環六項正合列**：
///
/// ```
/// K₀(J) --α--> K₀(A) --β--> K₀(Q) --∂₀--> K₁(J)
///   ↑                                        │
///  ∂₁                                       γ
///   │                                        ↓
/// K₁(Q) <--δ--- K₁(A) <--γ-- K₁(J)
/// ```
/// 六個有限生成群 ＋ 六個整數矩陣。約定：映射 f: G → H（G、H 自由，秩 g、h）
/// 以 **h×g** 矩陣表示。
pub struct SixTerm {
  j0 : FgAb
  j1 : FgAb
  a0 : FgAb
  a1 : FgAb
  q0 : FgAb
  q1 : FgAb
  alpha : IntMat
  beta : IntMat
  del0 : IntMat
  gamma : IntMat
  delta : IntMat
  del1 : IntMat
}

///|
/// 直接建構（六個群 ＋ 六個矩陣）。
pub fn six_term(
  j0 : FgAb,
  j1 : FgAb,
  a0 : FgAb,
  a1 : FgAb,
  q0 : FgAb,
  q1 : FgAb,
  alpha : IntMat,
  beta : IntMat,
  del0 : IntMat,
  gamma : IntMat,
  delta : IntMat,
  del1 : IntMat,
) -> SixTerm {
  { j0, j1, a0, a1, q0, q1, alpha, beta, del0, gamma, delta, del1, }
}

///|
/// 六項正合列的檢核結果。
pub struct SixCheck {
  ok : Bool
  composes : Bool
  ranks : Bool
  detail : String
}

///|
/// 矩陣是否為零。
fn mat_is_zero(m : IntMat) -> Bool {
  let mut z = true
  for i = 0; i < m.rows; i = i + 1 {
    for j = 0; j < m.cols; j = j + 1 {
      if m.e[i][j] != 0L {
        z = false
      }
    }
  }
  z
}

///|
/// 六項正合列的**精確**檢核（六群全自由的情形）：
/// 對迴圈上每個節點 X --f--> Y --g--> Z 要求 g∘f = 0 且 rank f + rank g = rank Y。
/// 這正是 ℤ-模上「im f = ker g」的秩—零化度判準（過 g∘f = 0 保證 im f ⊆ ker g，
/// 秩相等再保證反向包含）。
pub fn six_term_check(s : SixTerm) -> SixCheck {
  let pairs : Array[(IntMat, IntMat, Int32)] = [
    (s.del1, s.alpha, s.j0.rank),
    (s.alpha, s.beta, s.a0.rank),
    (s.beta, s.del0, s.q0.rank),
    (s.del0, s.gamma, s.j1.rank),
    (s.gamma, s.delta, s.a1.rank),
    (s.delta, s.del1, s.q1.rank),
  ]
  let mut composes = true
  let mut ranks = true
  let sb = StringBuilder()
  for i = 0; i < 6; i = i + 1 {
    let (f, g, n) = pairs[i]
    let c = mat_is_zero(intmat_mul(g, f))
    let rf = intmat_rank(f)
    let rg = intmat_rank(g)
    let r = rf + rg == n
    if !c {
      composes = false
    }
    if !r {
      ranks = false
    }
    if i > 0 {
      sb.write_string("；")
    }
    sb.write_string(
      "節點" +
      i.to_string() +
      "：" +
      (if c { "g∘f=0 ✓" } else { "g∘f=0 ✗" }) +
      "、rank " +
      rf.to_string() +
      "+" +
      rg.to_string() +
      (if r { "=" } else { "≠" }) +
      n.to_string(),
    )
  }
  { ok: composes && ranks, composes, ranks, detail: sb.to_string(), }
}

// ---------------------------------------------------------------- 具體的代數

///|
/// 緊算子理想 K：K₀ = ℤ[p]（秩一投影）、K₁ = 0。
pub fn k_of_compact() -> KPair {
  { k0: fga_free(1), k1: fga_zero(), }
}

///|
/// 圓 C(S¹)：K₀ = ℤ[1]、K₁ = ℤ[z]。
pub fn k_of_circle() -> KPair {
  { k0: fga_free(1), k1: fga_free(1), }
}

///|
/// Toeplitz 代數 𝒯_n 的 K-群（古典輸入）：K₀ = ℤ[1]、K₁ = 0。
pub fn k_of_toeplitz(_n : Int32) -> KPair {
  { k0: fga_free(1), k1: fga_zero(), }
}

///|
/// **Toeplitz 擴張** 0 → K → 𝒯 → C(S¹) → 0（n = 1）的六項正合列。
/// 六個群全自由，可用秩—零化度判準**完整**檢核。
/// 映射：α = i_* = 0（見 toeplitz_extension 的 Murray–von Neumann 計算，n = 1 時
/// (n−1)[1] = −[p] 給 [p] = 0）；β = ×1；∂₀ = γ = δ = 0；
/// ∂₁: K₁(C(S¹)) → K₀(K) 為 ×1（Bott／指標映射，hilbert.mbt 獨立算出）。
pub fn toeplitz_circle_extension() -> SixTerm {
  {
    j0: fga_free(1),
    j1: fga_zero(),
    a0: fga_free(1),
    a1: fga_zero(),
    q0: fga_free(1),
    q1: fga_free(1),
    alpha: intmat_of([[0L]]),
    beta: intmat_of([[1L]]),
    del0: intmat_zero(0, 1),
    gamma: intmat_zero(0, 0),
    delta: intmat_zero(1, 0),
    del1: intmat_of([[1L]]),
  }
}

///|
/// **Toeplitz 擴張** 0 → K → 𝒯_n → O_n → 0（n ≥ 2）的六項正合列資料。
///
/// Murray–von Neumann 計算：正交等距元 s_1..s_n 滿足 s_i^* s_j = δ_ij、
/// Σ_i s_i s_i^* = 1 − p（p 為秩一投影，落在 K 裡）。於是
///   Σ_i [s_i s_i^*] = [1] − [p]（正交投影可直接相加），
///   且每個 [s_i s_i^*] = [s_i^* s_i] = [1]（isometry 的 MvN 等價），
///   ⇒ n[1] = [1] − [p] ⇒ **(n−1)[1] = −[p]**。
/// [1] 生成 K₀(𝒯_n) ≅ ℤ、[p] 生成 K₀(K) ≅ ℤ ⇒ i_* = 乘 (1−n)。
/// 六項正合列給 0 → coker(i_*) → K₀(O_n) → 0 與 K₁(O_n) = ker(i_*)，故
///   K₀(O_n) ≅ ℤ/(n−1)、K₁(O_n) = 0。
pub fn toeplitz_extension(n : Int32) -> SixTerm {
  let imap = intmat_of([[1L - n.to_int64()]])
  let q0 = coker_of(imap)
  {
    j0: fga_free(1),
    j1: fga_zero(),
    a0: fga_free(1),
    a1: fga_zero(),
    q0,
    q1: kernel_of(imap),
    alpha: imap,
    beta: intmat_zero(q0.rank, 1),
    del0: intmat_zero(0, q0.rank),
    gamma: intmat_zero(0, 0),
    delta: intmat_zero(0, 0),
    del1: intmat_zero(1, 0),
  }
}

///|
/// 由 Toeplitz 擴張**導出** Cuntz 代數 O_n 的 K-群。
pub fn cuntz_ktheory(n : Int32) -> KPair {
  let imap = intmat_of([[1L - n.to_int64()]])
  { k0: coker_of(imap), k1: kernel_of(imap), }
}

///|
/// 有限維代數的**分裂**擴張 0 → I → A → A/I → 0 的六項正合列。
/// A ≅ I ⊕ A/I ⇒ 群全自由、∂₀ = ∂₁ = 0、α = 座標嵌入、β = 座標投影。
pub fn fda_extension(a : FDA, mask : Array[Bool]) -> SixTerm {
  let r = a.blocks.length()
  let selected : Array[Int64] = []
  for i = 0; i < r; i = i + 1 {
    if mask[i] {
      selected.push(i.to_int64())
    }
  }
  let ri = selected.length()
  let rq = r - ri
  let alpha = intmat_zero(r, ri)
  for j = 0; j < ri; j = j + 1 {
    alpha.e[selected[j].to_int()][j] = 1L
  }
  let beta = intmat_zero(rq, r)
  let mut row = 0
  for i = 0; i < r; i = i + 1 {
    if !mask[i] {
      beta.e[row][i] = 1L
      row = row + 1
    }
  }
  {
    j0: fga_free(ri),
    j1: fga_zero(),
    a0: fga_free(r),
    a1: fga_zero(),
    q0: fga_free(rq),
    q1: fga_zero(),
    alpha,
    beta,
    del0: intmat_zero(0, rq),
    gamma: intmat_zero(0, 0),
    delta: intmat_zero(0, 0),
    del1: intmat_zero(ri, 0),
  }
}
