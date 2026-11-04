///|
/// B0003 / modular 套件：**檢核器（T13、T14）**
/// 對應 docs/B0003-定理體系.md §3–§5。
///
/// 原則同前兩輪：每一條都用**兩條獨立路徑**互相對照——
///   封閉公式（ψ、φ、N³∏(1−1/p²) 等） vs 有限群 SL₂(ℤ/N) 上的暴力計數；
///   解析不變量（尖點、橢圓點、虧格） vs 古典虧格表（外部期望值）。

///|
/// T13：|SL₂(ℤ/N)| 的封閉公式 == 暴力列舉的元素數。
pub fn check_group_order(n : Int32) -> @galois.Check {
  let brute = sl2_group(n).length()
  let formula = order_sl2_mod(n)
  if brute != formula {
    return @galois.Check::make(
      "T13",
      "|SL₂(ℤ/N)| 公式",
      false,
      "N=" +
      n.to_string() +
      "：暴力 " +
      brute.to_string() +
      "，公式 " +
      formula.to_string(),
    )
  }
  @galois.Check::make(
    "T13",
    "|SL₂(ℤ/N)| 公式",
    true,
    "N=" + n.to_string() + "：" + brute.to_string() + " = N³∏(1−1/p²)",
  )
}

///|
/// T13：三種同餘子群的指數，封閉公式 == 暴力。
pub fn check_index_formulas(n : Int32) -> @galois.Check {
  let cases : Array[(SubgroupType, Int32, String)] = [
    (GammaZero, index_gamma0(n), "ψ(N)"),
    (GammaOne, index_gamma1(n), "ψ(N)φ(N)"),
    (GammaLevel, index_gamma_level(n), "ψ(N)φ(N)N"),
  ]
  for i = 0; i < cases.length(); i = i + 1 {
    let (kind, formula, label) = cases[i]
    let brute = index_by_bruteforce(kind, n)
    if brute != formula {
      return @galois.Check::make(
        "T13",
        "同餘子群指數公式",
        false,
        "N=" +
        n.to_string() +
        "、" +
        kind.label() +
        "：暴力 " +
        brute.to_string() +
        "，公式 " +
        formula.to_string() +
        "（" +
        label +
        "）",
      )
    }
  }
  @galois.Check::make(
    "T13",
    "同餘子群指數公式",
    true,
    "N=" +
    n.to_string() +
    "：Γ₀→ψ、Γ₁→ψφ、Γ→ψφN 全部相符",
  )
}

///|
/// T13：包含鏈 Γ(N) ⊆ Γ₁(N) ⊆ Γ₀(N) ⊆ SL₂(ℤ)（在 SL₂(ℤ/N) 上暴力驗證，並檢查嚴格性）。
pub fn check_containment_chain(n : Int32) -> @galois.Check {
  let g0 = subset_by_bruteforce(GammaLevel, n, GammaOne, n, n)
  let g1 = subset_by_bruteforce(GammaOne, n, GammaZero, n, n)
  if !g0 || !g1 {
    return @galois.Check::make(
      "T13",
      "包含鏈 Γ(N)⊆Γ₁(N)⊆Γ₀(N)",
      false,
      "N=" +
      n.to_string() +
      "：Γ(N)⊆Γ₁ " +
      g0.to_string() +
      "、Γ₁⊆Γ₀ " +
      g1.to_string(),
    )
  }
  // 嚴格性：N = 2 時 Γ₀(2) = Γ₁(2)（因 φ(2) = 1），其餘應嚴格
  let equal01 = subset_by_bruteforce(GammaZero, n, GammaOne, n, n)
  let expected_equal = euler_phi(n) == 1
  if equal01 != expected_equal {
    return @galois.Check::make(
      "T13",
      "包含鏈的嚴格性",
      false,
      "N=" +
      n.to_string() +
      "：Γ₀=Γ₁ 判定 " +
      equal01.to_string() +
      "，但 φ(N)=1 判定 " +
      expected_equal.to_string(),
    )
  }
  @galois.Check::make(
    "T13",
    "包含鏈 Γ(N)⊆Γ₁(N)⊆Γ₀(N)",
    true,
    "N=" +
    n.to_string() +
    "：Γ₀=Γ₁ ⟺ φ(N)=1（" +
    (if expected_equal { "此處相等" } else { "此處嚴格" }) +
    "）",
  )
}

///|
/// T13：正規性——Γ(N) 在 SL₂(ℤ/N) 中正規；Γ₁(N) 在 Γ₀(N) 中正規但（N ≥ 2）不在 SL₂ 中正規。
pub fn check_normality(n : Int32) -> @galois.Check {
  let level_normal = is_normal_by_bruteforce(GammaLevel, n, n)
  if !level_normal {
    return @galois.Check::make(
      "T13",
      "正規性 Γ(N) ◁ SL₂",
      false,
      "N=" +
      n.to_string() +
      "：Γ(N) 竟非正規（它是歸約映射的核，必正規）",
    )
  }
  if n == 1 {
    return @galois.Check::make(
      "T13", "正規性 Γ(N) ◁ SL₂", true, "N=1：Γ(1)=SL₂(ℤ)",
    )
  }
  let one_normal_in_sl2 = is_normal_by_bruteforce(GammaOne, n, n)
  if one_normal_in_sl2 {
    return @galois.Check::make(
      "T13",
      "正規性 Γ₁(N) 不 ◁ SL₂",
      false,
      "N=" +
      n.to_string() +
      "：Γ₁(N) 竟在 SL₂(ℤ/N) 中正規（N ≥ 2 時應否）",
    )
  }
  let witness = conjugation_witness(GammaOne, n, n)
  let mut detail = "N=" +
    n.to_string() +
    "：Γ(N) ◁ SL₂ ✓；Γ₁(N) 不 ◁ SL₂"
  match witness {
    Some((g, x, conj)) =>
      detail = detail +
        "；見證 g=" +
        g.key() +
        "、x=" +
        x.key() +
        " ⇒ xgx⁻¹=" +
        conj.key() +
        " ∉ Γ₁"
    None => detail = detail + "；（未取見證）"
  }
  @galois.Check::make("T13", "正規性 Γ₁ 不 ◁ SL₂", true, detail)
}

///|
/// T13：商群的階 [Γ₀:Γ₁] = φ(N)、[Γ₁:Γ] = N（在有限群上數元素）。
pub fn check_quotient_orders(n : Int32) -> @galois.Check {
  let group = sl2_group(n)
  let mut c0 = 0
  let mut c1 = 0
  let mut cl = 0
  for i = 0; i < group.length(); i = i + 1 {
    if in_subgroup(group[i], GammaZero, n) {
      c0 = c0 + 1
    }
    if in_subgroup(group[i], GammaOne, n) {
      c1 = c1 + 1
    }
    if in_subgroup(group[i], GammaLevel, n) {
      cl = cl + 1
    }
  }
  let q01 = c0 / c1
  let q1l = c1 / cl
  if q01 != euler_phi(n) || q1l != n {
    return @galois.Check::make(
      "T13",
      "商群階 [Γ₀:Γ₁]=φ(N)、[Γ₁:Γ]=N",
      false,
      "N=" +
      n.to_string() +
      "：[Γ₀:Γ₁]=" +
      q01.to_string() +
      "（應 " +
      euler_phi(n).to_string() +
      "）、[Γ₁:Γ]=" +
      q1l.to_string() +
      "（應 " +
      n.to_string() +
      "）",
    )
  }
  @galois.Check::make(
    "T13",
    "商群階 [Γ₀:Γ₁]=φ(N)、[Γ₁:Γ]=N",
    true,
    "N=" +
    n.to_string() +
    "：Γ₀/Γ₁ ≅ (ℤ/N)^×（階 φ(N)）、Γ₁/Γ ≅ ℤ/N",
  )
}

///|
/// T14：X₀(N) 的虧格公式 vs 古典虧格表（表外則明示「無外部期望值」）。
pub fn check_genus(n : Int32) -> @galois.Check {
  let computed = genus_x0(n)
  match classical_genus(n) {
    None =>
      @galois.Check::make(
        "T14",
        "X₀(N) 虧格",
        false,
        "未檢核：N=" +
        n.to_string() +
        " 不在古典期望表內（算出 g=" +
        computed.to_string() +
        "）",
      )
    Some(want) =>
      if computed != want {
        @galois.Check::make(
          "T14",
          "X₀(N) 虧格",
          false,
          "N=" +
          n.to_string() +
          "：公式 " +
          computed.to_string() +
          "，古典 " +
          want.to_string(),
        )
      } else {
        @galois.Check::make(
          "T14",
          "X₀(N) 虧格",
          true,
          "N=" +
          n.to_string() +
          "：g=" +
          computed.to_string() +
          "（σ₂=" +
          elliptic_two_count(n).to_string() +
          "、σ₃=" +
          elliptic_three_count(n).to_string() +
          "、ν_∞=" +
          cusp_count(n).to_string() +
          "）",
        )
      }
  }
}

///|
/// T14：尖點數的封閉性質——質數 p 為 2，p² 為 p+1（古典事實）。
pub fn check_cusp_special_values() -> @galois.Check {
  for p in [2, 3, 5, 7, 11, 13] {
    if cusp_count(p) != 2 {
      return @galois.Check::make(
        "T14",
        "尖點數 ν_∞(p)=2、ν_∞(p²)=p+1",
        false,
        "p=" +
        p.to_string() +
        "：ν_∞(p)=" +
        cusp_count(p).to_string() +
        "（應 2）",
      )
    }
    if cusp_count(p * p) != p + 1 {
      return @galois.Check::make(
        "T14",
        "尖點數 ν_∞(p)=2、ν_∞(p²)=p+1",
        false,
        "p=" +
        p.to_string() +
        "：ν_∞(p²)=" +
        cusp_count(p * p).to_string() +
        "（應 " +
        (p + 1).to_string() +
        "）",
      )
    }
  }
  @galois.Check::make(
    "T14", "尖點數 ν_∞(p)=2、ν_∞(p²)=p+1", true, "p ∈ {2,3,5,7,11,13} 全部相符",
  )
}

///|
/// T14：X₀(1) 的橢圓點（i 與 ρ）⇒ ν₂(1) = ν₃(1) = 1，且 g = 0。
pub fn check_level_one() -> @galois.Check {
  let ok = elliptic_two_count(1) == 1 &&
    elliptic_three_count(1) == 1 &&
    cusp_count(1) == 1 &&
    genus_x0(1) == 0
  if !ok {
    return @galois.Check::make(
      "T14",
      "X₀(1) 的橢圓點與虧格",
      false,
      "ν₂=" +
      elliptic_two_count(1).to_string() +
      "、ν₃=" +
      elliptic_three_count(1).to_string() +
      "、ν_∞=" +
      cusp_count(1).to_string() +
      "、g=" +
      genus_x0(1).to_string(),
    )
  }
  @galois.Check::make(
    "T14", "X₀(1) 的橢圓點與虧格", true, "ν₂=ν₃=ν_∞=1、g=0（橢圓點為 i 與 ρ）",
  )
}

///|
/// B0003 的完整檢核報告（T13、T14）。
pub fn modular_report(level_max : Int32) -> @galois.Report {
  let r = @galois.Report::new()
  for n = 2; n <= level_max; n = n + 1 {
    r.add(check_group_order(n))
    r.add(check_index_formulas(n))
    r.add(check_containment_chain(n))
    r.add(check_normality(n))
    r.add(check_quotient_orders(n))
    r.add(check_neg_one(n))
    r.add(check_psl2_order(n))
  }
  for n = 1; n <= 25; n = n + 1 {
    r.add(check_genus(n))
  }
  r.add(check_cusp_special_values())
  r.add(check_level_one())
  r
}

///|
/// −I 的同餘歸屬（＊開發期修正 DOC-4＊ 首版把三種子群混為一談）：
///   Γ₀(N)：−I = [[−1,0],[0,−1]] 的 c = 0 ⇒ **−I ∈ Γ₀(N) 恆成立**；
///   Γ₁(N)、Γ(N)：需要 −1 ≡ 1 (mod N) ⇒ 僅當 **N | 2**。
/// 這正是「Γ₀(N) 在 PSL₂ 化時不會自動減半」的來源。
pub fn check_neg_one(n : Int32) -> @galois.Check {
  let minus_i : Sl2 = { n, a: norm_mod(-1, n), b: 0, c: 0, d: norm_mod(-1, n), }
  let in_gamma0 = in_subgroup(minus_i, gamma_zero(), n)
  if !in_gamma0 {
    return @galois.Check::make(
      "T13",
      "−I 的同餘歸屬",
      false,
      "N=" +
      n.to_string() +
      "：−I 竟不屬於 Γ₀(N)（其 c = 0，必然屬於）",
    )
  }
  let expect = 2 % n == 0
  let kinds : Array[(SubgroupType, String)] = [
    (gamma_one(), "Γ₁"),
    (gamma_level(), "Γ"),
  ]
  for i = 0; i < kinds.length(); i = i + 1 {
    let (kind, label) = kinds[i]
    let got = in_subgroup(minus_i, kind, n)
    if got != expect {
      return @galois.Check::make(
        "T13",
        "−I 的同餘歸屬",
        false,
        "N=" +
        n.to_string() +
        "、" +
        label +
        "：−I ∈ Γ 判定 " +
        got.to_string() +
        "，但 N|2 判定 " +
        expect.to_string(),
      )
    }
  }
  @galois.Check::make(
    "T13",
    "−I 的同餘歸屬",
    true,
    "N=" +
    n.to_string() +
    "：−I ∈ Γ₀（恆真）；−I ∈ Γ₁、Γ ⟺ N|2（此處 " +
    (if expect { "成立" } else { "不成立" }) +
    "）",
  )
}

///|
/// |PSL₂(ℤ/N)| = |SL₂(ℤ/N)| / 2（N ≥ 2 時 −I ≠ I，映射為 2 對 1；以「±成對」暴力計數）。
pub fn check_psl2_order(n : Int32) -> @galois.Check {
  if n < 2 {
    return @galois.Check::make(
      "T13", "|PSL₂(ℤ/N)|", true, "N=1：PSL₂(ℤ) 無限，不適用",
    )
  }
  let group = sl2_group(n)
  let seen : Array[String] = []
  for i = 0; i < group.length(); i = i + 1 {
    let g = group[i]
    let neg : Sl2 = {
      n,
      a: norm_mod(-g.a, n),
      b: norm_mod(-g.b, n),
      c: norm_mod(-g.c, n),
      d: norm_mod(-g.d, n),
    }
    let k1 = g.key()
    let k2 = neg.key()
    let smaller = if k1 < k2 { k1 } else { k2 }
    let mut hit = false
    for j = 0; j < seen.length(); j = j + 1 {
      if seen[j] == smaller {
        hit = true
      }
    }
    if !hit {
      seen.push(smaller)
    }
  }
  // ＊修正 DOC-4＊ N=2 時 −I ≡ I（因 −1 ≡ 1 mod 2），故 |PSL₂(ℤ/2)| = |SL₂(ℤ/2)| = |S₃| = 6。
  let want = if 2 % n == 0 { group.length() } else { group.length() / 2 }
  if seen.length() != want {
    return @galois.Check::make(
      "T13",
      "|PSL₂(ℤ/N)|",
      false,
      "N=" +
      n.to_string() +
      "：±成對後 " +
      seen.length().to_string() +
      " 個，|SL₂|/2=" +
      want.to_string(),
    )
  }
  @galois.Check::make(
    "T13",
    "|PSL₂(ℤ/N)|",
    true,
    "N=" +
    n.to_string() +
    "：|PSL₂|=" +
    seen.length().to_string() +
    (if 2 % n == 0 { " = |SL₂|（因 −I ≡ I）" } else { " = |SL₂|/2" }),
  )
}
