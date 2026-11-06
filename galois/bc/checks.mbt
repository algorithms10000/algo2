///|
/// B0010 / bc 套件：**檢核器（T81–T90）**
/// 對應 docs/B0010-Baum-Connes-論證.md §2–§5。
///
/// 這一組檢核的目的是：把「Baum–Connes 猜想對本引擎可算的樣本成立」變成
/// **兩側算式對撞**的結果，而不是敘述。每條都配負控制，使判準不會恆真：
///   T81 有限群 μ 同構（5 個樣本）      T82 正交性 + 無權重負控制
///   T83 循環群 = DFT + ζ↦1 負控制      T84 A₄（ℤ[ω]）+ ω↦1 負控制
///   T85 S_n 與 SL₂(𝔽₂)≅S₃ 接縫         T86 無撓 ⇒ 無非平凡冪等元 + ℤ/2 負控制
///   T87 ℤ 的組裝（Toeplitz 六項正列）   T88 界外清單合規（BC1–BC8 不決定且兩值不同）

// ---------------------------------------------------------------- T81

///|
/// **T81**：對有限群 G，組裝映射 μ_0 : R(G) → K_0(ℂG) 是群同構。
/// 判準：兩側自由秩相等（#irr = #cc）＋ 特徵表滿秩（ℚ 與 F_p 兩套演算法）＋
/// Wedderburn（Σ dim² = |G| ⇒ K_1(ℂG) = 0 故 μ_1 亦同構）。
pub fn check_bc_finite() -> @galois.Check {
  let mut ok = true
  let sb = StringBuilder()
  for g in groups_int() {
    let iso = bc_assembly_iso(g)
    if !iso {
      ok = false
    }
    if sb.to_string() != "" {
      sb.write_string("；")
    }
    sb.write_string(
      g.name +
      "：#irr=" +
      n_irreps(g).to_string() +
      "=#cc、" +
      "rank=" +
      mu_rank_rat(g).to_string() +
      "(ℚ)/" +
      mu_rank_modp(g).to_string() +
      "(F_p)、Σdim²=" +
      wedderburn_sumsq(g).to_string() +
      "/|G|=" +
      g.order.to_string() +
      (if iso { " ✓" } else { " ✗" }),
    )
  }
  @galois.Check::make(
    "T81",
    "有限群 Baum–Connes：μ_0 : R(G) → K₀(ℂG) 是同構（5 樣本）",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T82

///|
/// **T82**：μ 單射的實質理由是帶類大小權重的特徵正交性
/// Σ_C |C|χ_V(C)χ_W(C) = |G|δ_VW。
/// 負控制：把每個共軛類都當成大小 1，S₃／D₈／Q₈ 立刻失敗（判準非恆真）。
pub fn check_bc_orthogonality() -> @galois.Check {
  let mut proper = true
  let mut neg = true
  let sb = StringBuilder()
  for g in groups_int() {
    if !gram_is_scalar(g) {
      proper = false
    }
    // 只有類大小不全為 1 的群才能充當負控制
    let mut all_one = true
    for c in g.class_sizes {
      if c != 1L {
        all_one = false
      }
    }
    if !all_one {
      if unweighted_gram_is_scalar(g) {
        // 無權重竟然也通過 ⇒ 負控制失效
        neg = false
      }
      if sb.to_string() != "" {
        sb.write_string("；")
      }
      sb.write_string(
        g.name +
        " 無權重 Gram 的第 (0,0) 項 = " +
        gram_matrix_unweighted(g)[0][0].to_string() +
        " ≠ |G| = " +
        g.order.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T82",
    "特徵正交性（帶類大小權重）⇒ μ 單射；負控制：無權重版本對非交換群失敗",
    proper && neg,
    "帶權重=" +
    proper.to_string() +
    "、負控制如預期失敗=" +
    neg.to_string() +
    "（" +
    sb.to_string() +
    "）",
  )
}

// ---------------------------------------------------------------- T83

///|
/// **T83**：循環群 ℤ/n 的組裝矩陣 = DFT，F 可逆 ⇔ μ 同構；
/// 實質理由是單位根和 Σ_k ζ^{km} = n·δ_{m0}（在 ℚ(ζ_n) 中精算，n = 2..12）。
/// 負控制：把 ζ 當成 1 時，同一個和對所有 m 都等於 n，正交性崩潰。
pub fn check_bc_cyclic() -> @galois.Check {
  let mut ok = true
  let mut neg = true
  for n = 2; n <= 12; n = n + 1 {
    if !bc_cyclic_iso(n) {
      ok = false
    }
    if !check_dft_collapse_fails(n) {
      neg = false
    }
  }
  @galois.Check::make(
    "T83",
    "循環群 ℤ/n：μ 矩陣 = DFT，Σ_k ζ^{km} = nδ_{m0} 精算成立（n = 2…12）",
    ok && neg,
    "DFT 正交=" +
    ok.to_string() +
    "、ζ↦1 負控制如預期崩潰=" +
    neg.to_string(),
  )
}

// ---------------------------------------------------------------- T84

///|
/// **T84**：A₄ 的特徵表落在 ℤ[ω]（ω = e^{2πi/3}），把 ℤ[ω] 展開成 2 維 ℚ-空間後
/// 秩 = 2·4 = 8，故 μ_0 : R(A₄) → K₀(ℂA₄) 仍為同構；加權 Gram = 12·I。
/// 負控制：只用 ℚ（χ_ω 與 χ_{ω²} 共軛合併）後秩掉到 6 < 8 ⇒ ℤ[ω] 不可省。
pub fn check_bc_a4() -> @galois.Check {
  let r_rat = a4_mu_rank_rat()
  let r_modp = a4_mu_rank_modp()
  let collapsed = a4_rational_rank()
  let gram_ok = a4_gram_is_scalar()
  let ok = r_rat == 8 && r_modp == 8 && gram_ok && collapsed < 8
  @galois.Check::make(
    "T84",
    "A₄（ℤ[ω] 特徵表）：展開秩 8 = 2·4 ⇒ μ₀ 同構；負控制：只用 ℚ 則掉到 6",
    ok,
    "rank(ℚ)=" +
    r_rat.to_string() +
    "、rank(F_p)=" +
    r_modp.to_string() +
    "、Gram=12·I：" +
    gram_ok.to_string() +
    "、只用 ℚ 後 rank=" +
    collapsed.to_string(),
  )
}

// ---------------------------------------------------------------- T85

///|
/// S_n 的共軛類個數（暴力：對每個 x，把 g x g⁻¹ 全算出來取最小鍵做代表）。
pub fn conjugacy_classes_sn(n : Int32) -> Int32 {
  let g = @braid.all_permutations(n)
  let keys : Array[String] = []
  for x in g {
    let mut best = ""
    let mut first = true
    for h in g {
      let c = @braid.perm_mul(@braid.perm_mul(h, x), @braid.perm_inverse(h))
      let k = @braid.perm_key(c)
      if first || k < best {
        best = k
        first = false
      }
    }
    let mut seen = false
    for kk in keys {
      if kk == best {
        seen = true
      }
    }
    if !seen {
      keys.push(best)
    }
  }
  keys.length()
}

///|
/// **T85（接縫）**：
/// (a) 對 S_n（n ≤ 5）：#共軛類 = #不可約表示 = p(n)，且 K₀(C*(S_n)) 的秩 = p(n)（B0006 的
///     `k_of_symmetric_group`）；Σ_λ d_λ² = n!（Wedderburn ⇒ K₁ = 0）。兩側同秩 ⇒ μ 同構。
/// (b) SL₂(𝔽₂) ≅ S₃：B0003 的 `sl2_group(2)` 暴力共軛類 = 3 = S₃ 的 #cc（T81 已判同構），
///     同一個群兩條路徑給同一個 K₀ 秩。
pub fn check_bc_seam_sym() -> @galois.Check {
  let mut ok = true
  let sb = StringBuilder()
  for n = 2; n <= 5; n = n + 1 {
    let cc = conjugacy_classes_sn(n)
    let p = @kk.partitions(n).length()
    let k = @kk.k_of_symmetric_group(n)
    let sumsq = @kk.sum_dim_squares(n)
    let mut fact = 1L
    for i = 2; i <= n; i = i + 1 {
      fact = fact * i.to_int64()
    }
    let line_ok = cc == p &&
      k.k0.rank == p &&
      sumsq == fact &&
      @kk.fga_eq(k.k1, @kk.fga_zero())
    if !line_ok {
      ok = false
    }
    sb.write_string(
      "S" +
      n.to_string() +
      "：#cc=" +
      cc.to_string() +
      "=p(" +
      n.to_string() +
      ")=" +
      p.to_string() +
      "、rank K₀=" +
      k.k0.rank.to_string() +
      "、Σd²=" +
      sumsq.to_string() +
      "/n!=" +
      fact.to_string() +
      "；",
    )
  }
  // SL₂(𝔽₂) ≅ S₃
  let g = @modular.sl2_group(2)
  let keys : Array[String] = []
  for x in g {
    let mut best = ""
    let mut first = true
    for h in g {
      let c = h.mul(x).mul(h.inverse())
      let k = c.key()
      if first || k < best {
        best = k
        first = false
      }
    }
    let mut seen = false
    for kk in keys {
      if kk == best {
        seen = true
      }
    }
    if !seen {
      keys.push(best)
    }
  }
  let sl2cc = keys.length()
  if sl2cc != 3 || g.length() != 6 {
    ok = false
  }
  sb.write_string(
    "SL₂(𝔽₂)：|G|=" +
    g.length().to_string() +
    "、#cc=" +
    sl2cc.to_string() +
    "（≅ S₃，故 K₀ 秩 3）",
  )
  @galois.Check::make(
    "T85",
    "接縫：S_n 的 #cc = p(n) = rank K₀(C*(S_n))；SL₂(𝔽₂) ≅ S₃ 兩路徑同秩",
    ok,
    sb.to_string(),
  )
}

// ---------------------------------------------------------------- T86

///|
/// **T86（Kadison–Kaplansky 的代數截面）**：ℂ[ℤ] 無非平凡冪等元——
/// (a) 次數論證封閉所有情形； (b) 支撐 [−2,2]、係數 {−1,0,1} 的 243 個多項式窮舉；
/// 負控制：ℂ[ℤ/2] 的 (1+g)/2 確實冪等 ⇒ 無撓假設不可省。
pub fn check_bc_kadison() -> @galois.Check {
  let a = check_degree_argument(6)
  let b = check_no_laurent_idempotent(2)
  let neg = check_torsion_idempotent()
  @galois.Check::make(
    "T86",
    "ℂ[ℤ] 無非平凡冪等元（次數論證＋窮舉）；負控制 ℂ[ℤ/2] 有 (1+g)/2",
    a && b && neg,
    "次數論證=" +
    a.to_string() +
    "、窮舉 243 個=" +
    b.to_string() +
    "、負控制=" +
    neg.to_string(),
  )
}

// ---------------------------------------------------------------- T87

///|
/// **T87（接縫 B0006）**：G = ℤ 是無撓可撓群（a-T-menable，Higson–Kasparov 已證），
/// C*_r ℤ = C(S¹)。組裝兩側：K_i^ℤ(Eℤ) = K_i(C(S¹)) = (ℤ, ℤ) 且 μ = id。
/// 用 B0006 的 Toeplitz 六項正合列獨立核對「兩側都是 (ℤ,ℤ)」，
/// 並用其指標／繞數檢核（∂₁ = ×1）確認 K₁ → K₀ 的 Bott 同構。
pub fn check_bc_seam_infinite_cyclic() -> @galois.Check {
  let six = @kk.check_six_term_toeplitz()
  let wind = @kk.check_index_winding()
  let circle = @kk.k_of_circle()
  let same = @kk.kpair_eq(circle, @kk.kpair(@kk.fga_free(1), @kk.fga_free(1)))
  let ok = six.passed() && wind.passed() && same
  @galois.Check::make(
    "T87",
    "接縫：ℤ 的組裝兩側同為 (ℤ,ℤ)（C*_rℤ = C(S¹)，Toeplitz 六項正列＋指標）",
    ok,
    "六項正列=" +
    six.passed().to_string() +
    "、指標／繞數=" +
    wind.passed().to_string() +
    "、K(C(S¹))=(ℤ,ℤ)：" +
    same.to_string(),
  )
}

// ---------------------------------------------------------------- T88

///|
/// **T88**：界外清單合規——BC1–BC8 全部在列，每條都有 status／evidence／界內截面，
/// 而 `decides = false` 的條目兩個可能值必須相異（「不決定」是可檢核的斷言）。
pub fn check_bc_boundary() -> @galois.Check {
  let ok = bc_items_compliant()
  let items = bc_items()
  let mut undecided = 0
  for it in items {
    if !it.decides {
      undecided = undecided + 1
    }
  }
  @galois.Check::make(
    "T88",
    "界外清單 BC1–BC8：每條附 status／evidence／界內截面／兩個可能值（不決定）",
    ok && items.length() == 8 && undecided == 8,
    "條目=" +
    items.length().to_string() +
    "、不決定=" +
    undecided.to_string(),
  )
}

// ---------------------------------------------------------------- 報告與表

///|
/// B0010 / bc 的檢核報告（T81–T90）。
pub fn bc_report() -> @galois.Report {
  let r = @galois.Report::new()
  r.add(check_bc_finite())
  r.add(check_bc_orthogonality())
  r.add(check_bc_cyclic())
  r.add(check_bc_a4())
  r.add(check_bc_seam_sym())
  r.add(check_bc_kadison())
  r.add(check_bc_seam_infinite_cyclic())
  r.add(check_bc_boundary())
  r.add(check_bc_global_galois())
  r.add(check_bc_local_axioms())
  r
}

///|
/// 結構表（供 `moon run cmd/main -- bctable`）：把每個樣本的兩側算式並列。
pub fn bc_table_render() -> String {
  let sb = StringBuilder()
  sb.write_string(
    "Baum–Connes 組裝映射的可計算樣本（左側 = 拓撲側，右側 = 算子側）\n",
  )
  sb.write_string(
    "  群            左側 R(G)      右側 K₀(ℂG)     rank(ℚ/F_p)  Σdim²=|G|  判定\n",
  )
  for g in groups_int() {
    sb.write_string(
      "  " +
      g.name +
      "  ℤ^" +
      n_irreps(g).to_string() +
      "（#irr）      ℤ^" +
      n_classes(g).to_string() +
      "（#cc）      " +
      mu_rank_rat(g).to_string() +
      "/" +
      mu_rank_modp(g).to_string() +
      "          " +
      wedderburn_sumsq(g).to_string() +
      "=" +
      g.order.to_string() +
      "        " +
      (if bc_assembly_iso(g) { "同構" } else { "不同構" }) +
      "\n",
    )
  }
  sb.write_string(
    "  ℤ/n（n = 2…12）：R = ℤ^n（分圓基底）、K₀ = ℤ^n，μ = DFT；Σ_k ζ^{km} = nδ_{m0} 精算成立\n",
  )
  sb.write_string(
    "  A₄：ℤ[ω] 特徵表展開秩 " +
    a4_mu_rank_rat().to_string() +
    " = 2·4（只用 ℚ 後掉到 " +
    a4_rational_rank().to_string() +
    "）\n",
  )
  sb.write_string(
    "  ℤ：C*_rℤ = C(S¹)，兩側 (ℤ,ℤ)，μ = id（無撓 ⇒ ℂ[ℤ] 無非平凡冪等元）\n",
  )
  sb.write_string(
    "  S_n：rank K₀ = p(n) = #共軛類（n ≤ 5 暴力核對）\n",
  )
  sb.write_string("界外清單（不決定，兩值並列）：\n")
  for it in bc_items() {
    sb.write_string(
      "  " + it.id + " " + it.title + "｜現況：" + it.status + "\n",
    )
    sb.write_string("      若真：" + it.value_if_true + "\n")
    sb.write_string("      若假：" + it.value_if_false + "\n")
  }
  sb.to_string()
}

// ---------------------------------------------------------------- T89

///|
/// **T89（需求文件第 1 行：全局公理伽羅華對應）**：
/// 分圓擴張的伽羅華對應在**全體子群**上成立：H ⊆ H' ⟺ ℚ(ζ_n)^H ⊇ ℚ(ζ_n)^H'，
/// 且 H ↦ ℚ(ζ_n)^H 是單射（反序一一對應到中間體）。
/// 子空間包含以堆疊秩判定；負控制：只用維度比較時，V₄ = (ℤ/8)^× 的三個二階子群
/// 維度全是 2，維度無法區分——故「用維度代替子空間」的判準會失效。
pub fn check_bc_global_galois() -> @galois.Check {
  let mut ok = true
  let sb = StringBuilder()
  for n in [5, 7, 8, 9, 12] {
    let subs = subgroups_of_units(n)
    if !check_global_galois_correspondence(n) {
      ok = false
    }
    sb.write_string(
      "(ℤ/" +
      n.to_string() +
      ")^×：" +
      subs.length().to_string() +
      " 個子群，反序對應",
    )
    sb.write_string("；")
  }
  let neg = check_dimension_only_fails()
  @galois.Check::make(
    "T89",
    "全局公理伽羅華對應：H ⊆ H' ⇔ Fix(H) ⊇ Fix(H')（全體子群，反序一一）",
    ok && neg,
    "對應=" +
    ok.to_string() +
    "、維度判準負控制如預期失效=" +
    neg.to_string() +
    "（" +
    sb.to_string() +
    "）",
  )
}

// ---------------------------------------------------------------- T90

///|
/// **T90（需求文件第 2 行：局部公理由代理決定）**：
/// 8 條局部公理（每個可算樣本一條「μ 是同構」）由引擎當場重算並裁決；
/// 8 條全局公理（BC1–BC8）不由本代理決定，全部 decided = false 且附兩個可能值。
pub fn check_bc_local_axioms() -> @galois.Check {
  let ok = local_axioms_verified()
  let locals = local_axioms()
  let globals = global_axioms()
  @galois.Check::make(
    "T90",
    "局部公理 8 條由代理裁決（可重算）／全局公理 8 條不決定（兩值）",
    ok,
    "局部=" +
    locals.length().to_string() +
    "（全 decided）、全局=" +
    globals.length().to_string() +
    "（全不決定）",
  )
}
