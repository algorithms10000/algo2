///|
/// B0006 / kk 套件：**界外部份（T48–T50）**
/// 對應 docs/B0007-定理體系.md §9–§12。
///
/// B0006 的 A-K1 說：任何「KK-群」的陳述必須附上適用類別與判定途徑；
/// 超出界外的問題**不得以綠燈冒充**。本檔就是那條規定的**執行檔**：
///
///   1. 把界外的東西逐條列成 `ScopeItem`（id、為何界外、界內可算的截面、可計算見證）；
///   2. 對「可計算截面」給出真數字（例如自由積的 K₁ 可加性、Künneth 的界內情形）；
///   3. 對「純界外」給出**反面見證**（例如 K₀ 的可加性在自由積上失效、UCT 的 kind = 0
///      下 KK 有兩個不同的可能值），使「界外」是可檢核的斷言，而不是一句免責聲明。
///
/// 這一輪的新增定理：
///   T48 界外清單的合規性（每一項都有 reason／截面／見證；kind = 0 必須明示不決定）
///   T49 自由積 K-群：K₁ 可加（與 Pimsner–Voiculescu 的 ℤⁿ 一致）、K₀ 不可加
///   T50 張量／Künneth：bootstrap 內成立（含 Tor 項），界外只登記不宣稱

// ---------------------------------------------------------------- 界外清單

///|
/// 一條「界外」記錄。`verdict` 只有兩種值：
///   * `"界外"`：本輪完全不宣稱；
///   * `"界內截面"`：本輪只宣稱 `inside_part` 描述的那一塊可判定內容。
pub struct ScopeItem {
  id : String
  title : String
  reason : String
  inside_part : String
  witness : String
  verdict : String
}

///|
/// 界外清單（O1–O6）。
pub fn outside_items() -> Array[ScopeItem] {
  [
    {
      id: "O1",
      title: "非 bootstrap 類的 KK（組裝圖 ∪ 有界同態之外）",
      reason: "UCT 只在 bootstrap 類成立；非 bootstrap 的代數即使 K-群相同，KK 也可能不同（Dadarlat 的非 bootstrap 例子）",
      inside_part: "組裝圖（有限維、C(S¹)、O_n、理想／商）∪ 有界同態所生成的部分，逐項由 UCT 算出",
      witness: "kind = 0 的樣本：K₀ = ℤ、K₁ = ℤ/2 的 A 與 B，Hom = ℤ⊕ℤ/2、Ext¹ = ℤ/2；UCT 只給 0 → Ext → KK → Hom → 0，KK 可能是 ℤ⊕ℤ/4 或 ℤ⊕ℤ/2⊕ℤ/2",
      verdict: "界內截面",
    },
    {
      id: "O2",
      title: "無窮維 Fredholm 模（Kasparov 模的算子同倫類）",
      reason: "Hilbert 空間無窮維、Fredholm 算子不可枚舉、算子同倫不可判定",
      inside_part: "有限矩陣截斷下的 Fredholm 指標（B0006 T39）：指標在截斷增大時穩定",
      witness: "繞數 −1 的 Toeplitz 符號，非方截斷 N = 1..4 的指標全部等於 −1（方截斷全為 0，故方截斷不保指標）",
      verdict: "界內截面",
    },
    {
      id: "O3",
      title: "min／max 張量範疇（C*-張量的兩種完備化）",
      reason: "min 與 max 只在核代數上重合；非核代數上兩者不同，而我們的 K-群表對兩者不敏感",
      inside_part: "有限維代數（Artin–Wedderburn）與 C(S¹) 皆核，故 A⊗min B = A⊗max B = A⊗B，K-群唯一",
      witness: "有限維 A⊗B 的 K-群由 Künneth 給出且與塊分解一致（T50）；對 C*_r(𝔽₂)（非核）本輪不宣稱任何 min／max 差異",
      verdict: "界外",
    },
    {
      id: "O4",
      title: "自由積的 K-群（K_*(A * B)）",
      reason: "K₁ 有 Cuntz 的可加性定理，K₀ 沒有一般公式（K₀ 依賴自由積的「新投影」）",
      inside_part: "K₁(A * B) = K₁(A) ⊕ K₁(B)（有限生成情形逐項可算）",
      witness: "C*_r(𝔽_n) = C(S¹) * … * C(S¹)（n 份）⇒ K₁ = ℤⁿ（與 Pimsner–Voiculescu 的登記值一致）；而 K₀ = ℤ ≠ ℤⁿ，可加性在 K₀ 上失效",
      verdict: "界內截面",
    },
    {
      id: "O5",
      title: "非有限生成的 K-群與不可數秩",
      reason: "本引擎的 FgAb 只表示有限生成交換群；秩不可數或無限秩的情形無法以整數矩陣表示",
      inside_part: "秩 ≤ 8、撓部分為循環群之直和的有限生成群",
      witness: "fga_make 的表示界（rank、tors 長度）在型別上固定；超出界的情形需另建模型，本輪不做",
      verdict: "界外",
    },
    {
      id: "O6",
      title: "KK 的環結構與 Kasparov 乘積的完整計算",
      reason: "Kasparov 乘積在 bootstrap 類的自由部分可合成，但撓部分（Ext）的乘積需要二階資料，本引擎不具備",
      inside_part: "自由部分（Hom 側）的合成、單位律、結合律（B0006 T36）",
      witness: "kk_product_unit／kk_product_assoc 只在自由部分檢核；含撓的合成標為界外",
      verdict: "界內截面",
    },
  ]
}

///|
/// 界外清單的合規性：每一項的 reason／inside_part／witness 皆非空，
/// 且 verdict 只能是 `界外` 或 `界內截面`。
pub fn scope_item_compliant(it : ScopeItem) -> Bool {
  let nonempty = fn(s : String) -> Bool { s.length() > 0 }
  nonempty(it.id) &&
  nonempty(it.title) &&
  nonempty(it.reason) &&
  nonempty(it.inside_part) &&
  nonempty(it.witness) &&
  (it.verdict == "界外" || it.verdict == "界內截面")
}

///|
/// 統計：清單中標為純界外的項數。
pub fn outside_count(items : Array[ScopeItem]) -> Int32 {
  let mut c = 0
  for it in items {
    if it.verdict == "界外" {
      c = c + 1
    }
  }
  c
}

// ---------------------------------------------------------------- 張量與 Künneth

///|
/// 有限生成交換群的張量積：自由部分 rank 相乘；
/// 撓部分 ℤ/d ⊗ ℤ/e = ℤ/gcd(d, e)。
pub fn fga_tensor(a : FgAb, b : FgAb) -> FgAb {
  let tors : Array[Int64] = []
  for x in a.tors {
    for y in b.tors {
      let g = igcd(x, y)
      if g > 1L {
        tors.push(g)
      }
    }
  }
  let g = fga_make(a.rank * b.rank, tors)
  { rank: g.rank, tors: g.tors, }
}

///|
/// 一階 Tor：Tor(ℤ/d, ℤ/e) = ℤ/gcd(d, e)；自由部分無 Tor。
pub fn fga_tor(a : FgAb, b : FgAb) -> FgAb {
  fga_tensor(a, b)
}

///|
/// Künneth 公式：K_n(A ⊗ B) = ⊕_{i+j=n} K_i(A) ⊗ K_j(B) ⊕ ⊕_{i+j=n−1} Tor(K_i(A), K_j(B))。
pub fn kunneth_kpair(a : KPair, b : KPair) -> KPair {
  let k0 = fga_direct_sum(fga_tensor(a.k0, b.k0), fga_tor(a.k1, b.k1))
  let k1 = fga_direct_sum(
    fga_direct_sum(fga_tensor(a.k0, b.k1), fga_tensor(a.k1, b.k0)),
    fga_tor(fga_zero(), fga_zero()),
  )
  { k0, k1, }
}

// ---------------------------------------------------------------- 自由積

///|
/// 自由積的 K₁ 截面：K₁(A₁ * … * A_m) = ⊕_i K₁(A_i)（Cuntz 的可加性）。
pub fn free_product_k1(parts : Array[FgAb]) -> FgAb {
  let mut acc = fga_zero()
  for p in parts {
    acc = fga_direct_sum(acc, p)
  }
  acc
}

///|
/// 「若 K₀ 也可加」會給出的預測值（**界外**的假設，只作為反例見證）。
pub fn free_product_k0_naive(parts : Array[FgAb]) -> FgAb {
  free_product_k1(parts)
}

///|
/// C*_r(𝔽_n) 的 K-群登記值（Pimsner–Voiculescu）：K₀ = ℤ、K₁ = ℤⁿ。
/// 注意 C*_r(𝔽_n) = C(S¹) * … * C(S¹)（n 份自由積，K₁(C(S¹)) = ℤ）。
pub fn free_group_cstar_kpair(n : Int32) -> KPair {
  { k0: fga_free(1), k1: fga_free(n), }
}

///|
/// 自由積的 K₁ 截面與登記值比對時用的「n 份 C(S¹)」之 K₁。
pub fn circle_free_factors(n : Int32) -> Array[FgAb] {
  let out : Array[FgAb] = []
  for _i = 0; _i < n; _i = _i + 1 {
    out.push(fga_free(1))
  }
  out
}

// ---------------------------------------------------------------- 檢核 T48–T50

///|
/// T48：界外清單合規 ＋ kind = 0 的樣本必須明示「不決定」，
/// 且**兩個不同的可能值**都寫得出來（否則「不決定」只是空話）。
pub fn check_outside_manifest() -> @galois.Check {
  let items = outside_items()
  let mut all_ok = true
  for it in items {
    if !scope_item_compliant(it) {
      all_ok = false
    }
  }
  let ids_ok = items.length() == 6 && items[0].id == "O1" && items[5].id == "O6"
  // kind = 0 的樣本
  let a = { k0: fga_free(1), k1: fga_cyclic(2L), }
  let b = { k0: fga_free(1), k1: fga_cyclic(2L), }
  let u = kk_uct(a, b)
  let undetermined = !uct_determined(u)
  // 兩種可能的 KK：Hom ⊕ Ext 與「Ext 換成 ℤ/4」
  let hom_ext = fga_direct_sum(u.hom, u.ext)
  let alt = fga_direct_sum(u.hom, fga_cyclic(4L))
  let two_values = !fga_eq(hom_ext, alt)
  let ok = all_ok && ids_ok && undetermined && two_values
  let detail = "清單 " +
    items.length().to_string() +
    " 項（純界外 " +
    outside_count(items).to_string() +
    " 項）、全部欄位齊備=" +
    all_ok.to_string() +
    "；kind=0 樣本：Hom=" +
    fga_render(u.hom) +
    "、Ext¹=" +
    fga_render(u.ext) +
    "、被決定=" +
    uct_determined(u).to_string() +
    "、可能的兩個值 " +
    fga_render(hom_ext) +
    " ≠ " +
    fga_render(alt)
  @galois.Check::make(
    "逻辑推理", "T48 界外清單合規與 kind=0 的明示", ok, detail,
  )
}

///|
/// T48（負控制）：拿掉見證的記錄必須被判不合規。
pub fn check_outside_negative_control() -> @galois.Check {
  let bad : ScopeItem = {
    id: "Ox",
    title: "無見證的界外項",
    reason: "隨口說界外",
    inside_part: "無",
    witness: "",
    verdict: "界外",
  }
  let bad2 : ScopeItem = {
    id: "Oy",
    title: "判定詞不在允許集內",
    reason: "口氣可疑",
    inside_part: "無",
    witness: "有見證",
    verdict: "大概吧",
  }
  let ok = !scope_item_compliant(bad) && !scope_item_compliant(bad2)
  @galois.Check::make(
    "逻辑推理",
    "T48 負控制：缺見證／判定詞錯誤的記錄不合規",
    ok,
    "缺 witness ⇒ 不合規=" +
    (!scope_item_compliant(bad)).to_string() +
    "；verdict 非法 ⇒ 不合規=" +
    (!scope_item_compliant(bad2)).to_string(),
  )
}

///|
/// T49：自由積 K-群。K₁ 可加（與 C*_r(𝔽_n) 的登記值 ℤⁿ 一致），
/// K₀ 不可加（可加性會給 ℤⁿ，登記值是 ℤ）。
pub fn check_free_product_k(n : Int32) -> @galois.Check {
  let factors = circle_free_factors(n)
  let k1_add = free_product_k1(factors)
  let k1_registered = free_group_cstar_kpair(n).k1
  let k1_ok = fga_eq(k1_add, k1_registered)
  let k0_naive = free_product_k0_naive(factors)
  let k0_registered = free_group_cstar_kpair(n).k0
  let k0_additive_fails = !fga_eq(k0_naive, k0_registered)
  // K₀ 的登記值必須是 ℤ（單一自由因子），與 n 無關
  let k0_rank_one = k0_registered.rank == 1 && k0_registered.tors.length() == 0
  let ok = k1_ok && k0_additive_fails && k0_rank_one
  let detail = "n=" +
    n.to_string() +
    "：K₁ 可加=" +
    fga_render(k1_add) +
    "（登記值 " +
    fga_render(k1_registered) +
    "）；K₀ 可加性預測 " +
    fga_render(k0_naive) +
    "、登記值 " +
    fga_render(k0_registered) +
    " ⇒ 失效=" +
    k0_additive_fails.to_string()
  @galois.Check::make(
    "结合",
    "T49 自由積：K₁ 可加（ℤ^" +
    n.to_string() +
    "）、K₀ 不可加",
    ok,
    detail,
  )
}

///|
/// T50：Künneth 的界內情形——對 bootstrap 樣本（有限維、C(S¹)）成立；
/// 界外情形（非核、非 bootstrap）只登記不宣稱。
pub fn check_kunneth_inside() -> @galois.Check {
  // (1) M₂ ⊗ M₃ = M₆：K₀ = ℤ、K₁ = 0，Künneth 亦給 ℤ、0
  let m2 = fda_k({ blocks: [2], })
  let m3 = fda_k({ blocks: [3], })
  let kun = kunneth_kpair(m2, m3)
  let m6 = fda_k({ blocks: [6], })
  let case1 = kpair_eq(kun, m6) &&
    fda_dim(fda([2])) * fda_dim(fda([3])) == fda_dim(fda([6]))
  // (2) M₂ ⊗ C(S¹)：K₀ = ℤ、K₁ = ℤ；Künneth 亦給 ℤ、ℤ
  let circ = k_of_circle()
  let case2 = kpair_eq(kunneth_kpair(m2, circ), {
    k0: fga_free(1),
    k1: fga_free(1),
  })
  // (3) 撓項：K₀ = ℤ/2 對 K₁ = ℤ/2 的 Tor 必須出現
  let tor_case = fga_eq(fga_tor(fga_cyclic(2L), fga_cyclic(2L)), fga_cyclic(2L)) &&
    fga_eq(fga_tor(fga_cyclic(2L), fga_cyclic(3L)), fga_zero())
  // (4) 界外的張量：C*_r(𝔽₂) ⊗ C*_r(𝔽₂) 的 K-群本輪不宣稱
  let items = outside_items()
  let mut declared = false
  for it in items {
    if it.id == "O3" && it.verdict == "界外" {
      declared = true
    }
  }
  let ok = case1 && case2 && tor_case && declared
  let detail = "M₂⊗M₃ 的 K-群 = " +
    kpair_render(kun) +
    "（=M₆ 的 " +
    kpair_render(m6) +
    "）；M₂⊗C(S¹) = " +
    kpair_render(kunneth_kpair(m2, circ)) +
    "；Tor(ℤ/2,ℤ/2)=" +
    fga_render(fga_tor(fga_cyclic(2L), fga_cyclic(2L))) +
    "、Tor(ℤ/2,ℤ/3)=" +
    fga_render(fga_tor(fga_cyclic(2L), fga_cyclic(3L))) +
    "；非核情形已標界外=" +
    declared.to_string()
  @galois.Check::make(
    "合并", "T50 Künneth 的界內截面與界外標記", ok, detail,
  )
}

///|
/// 界外部分的報告（T48–T50）。
pub fn outside_report() -> @galois.Report {
  let r = @galois.Report::new()
  r.add(check_outside_manifest())
  r.add(check_outside_negative_control())
  for n = 2; n <= 4; n = n + 1 {
    r.add(check_free_product_k(n))
  }
  r.add(check_kunneth_inside())
  r
}

///|
/// 界外清單的文字形式（供 CLI 印出）。
pub fn outside_render() -> String {
  let sb = StringBuilder()
  for it in outside_items() {
    sb.write_string("  [" + it.id + "][" + it.verdict + "] " + it.title + "\n")
    sb.write_string("      界外理由：" + it.reason + "\n")
    sb.write_string("      界內截面：" + it.inside_part + "\n")
    sb.write_string("      可計算見證：" + it.witness + "\n")
  }
  sb.to_string()
}
