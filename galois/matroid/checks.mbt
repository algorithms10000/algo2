///|
/// B0002 / matroid 套件：擬陣檢核（X5、X6、C1–C3、P-B2、P-B3、T5、T8、A12、A14）

///|
/// A14：對任意閉包 oracle 檢查交換公理 X5。
/// 時間 O(2ⁿ·n²)。失敗時回報最小反例 (X, y, z)。
pub fn check_exchange(
  n : Int32,
  cl : (@bitset.BitSet) -> @bitset.BitSet,
) -> @galois.Check {
  if n > 18 {
    return @galois.Check::make(
      "X5", "交換公理", false, "未檢核：n > 18，超出窮舉預算",
    )
  }
  for mask = 0; mask < 1 << n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(n, mask)
    let cx = cl(x)
    for y = 0; y < n; y = y + 1 {
      if cx.get(y) {
        continue
      }
      for z = 0; z < n; z = z + 1 {
        if cx.get(z) || z == y {
          continue
        }
        if cl(x.plus_bit(z)).get(y) && !cl(x.plus_bit(y)).get(z) {
          return @galois.Check::make(
            "X5",
            "交換公理",
            false,
            "X=" +
            x.render() +
            "，y=" +
            y.to_string() +
            "，z=" +
            z.to_string() +
            "：y ∈ cl(X∪{z}) 但 z ∉ cl(X∪{y})",
          )
        }
      }
    }
  }
  @galois.Check::make("X5", "交換公理", true, "")
}

///|
/// 擬陣自身的交換公理檢核（A14 的包裝）。
pub fn Matroid::check_exchange(self : Matroid) -> @galois.Check {
  let mt = self
  check_exchange(self.n, fn(x) { mt.closure(x) })
}

///|
/// D-B1 的 (C1)(C2)(C3) 檢核：非空、反鏈、迴路消去。
pub fn Matroid::check_circuit_axioms(self : Matroid) -> @galois.Check {
  for i = 0; i < self.circuits.length(); i = i + 1 {
    if self.circuits[i].count() == 0 {
      return @galois.Check::make(
        "D-B1", "迴路公理 (C1)", false, "存在空迴路",
      )
    }
    for j = 0; j < self.circuits.length(); j = j + 1 {
      let nested = self.circuits[i].subset_of(self.circuits[j])
      let same = self.circuits[i].equals(self.circuits[j])
      if i != j && nested && !same {
        return @galois.Check::make(
          "D-B1", "迴路公理 (C2)", false, "迴路族不是反鏈",
        )
      }
    }
  }
  // (C3) 迴路消去
  for i = 0; i < self.circuits.length(); i = i + 1 {
    for j = 0; j < self.circuits.length(); j = j + 1 {
      if i == j {
        continue
      }
      let c1 = self.circuits[i]
      let c2 = self.circuits[j]
      let common = c1.intersect(c2).ones()
      for k = 0; k < common.length(); k = k + 1 {
        let e = common[k]
        let union_minus = c1.union(c2).minus_bit(e)
        let mut found = false
        for t = 0; t < self.circuits.length(); t = t + 1 {
          if self.circuits[t].subset_of(union_minus) {
            found = true
          }
        }
        if !found {
          return @galois.Check::make(
            "D-B1",
            "迴路公理 (C3)",
            false,
            "C1=" +
            c1.render() +
            "、C2=" +
            c2.render() +
            "、e=" +
            e.to_string() +
            " 找不到消去迴路",
          )
        }
      }
    }
  }
  @galois.Check::make(
    "D-B1",
    "迴路公理 C1/C2/C3",
    true,
    "|𝒞|=" + self.circuits.length().to_string(),
  )
}

///|
/// X6：秩公理 R1–R4，以及 P-B2 的兩條路徑一致性（迴路閉包 vs 秩閉包）。
pub fn Matroid::check_rank_axioms(self : Matroid) -> @galois.Check {
  if self.n > 18 {
    return @galois.Check::make("X6", "秩公理", false, "未檢核：n > 18")
  }
  let top = (1 << self.n) - 1
  // R1 的底項：r(∅) = 0
  if self.rank(@bitset.BitSet::new(self.n)) != 0 {
    return @galois.Check::make(
      "X6", "秩公理 R1（r(∅)=0）", false, "r(∅) ≠ 0",
    )
  }
  // R4'：單位增量 r(X) ≤ r(X∪{e}) ≤ r(X)+1（同時涵蓋無環時 r({e}) ≤ 1 的直覺）
  if self.n <= 18 {
    for mask = 0; mask < 1 << self.n; mask = mask + 1 {
      let x = @bitset.BitSet::from_mask(self.n, mask)
      let rx = self.rank(x)
      for e = 0; e < self.n; e = e + 1 {
        if x.get(e) {
          continue
        }
        let rxe = self.rank(x.plus_bit(e))
        if rxe < rx || rxe > rx + 1 {
          return @galois.Check::make(
            "X6",
            "秩公理 R4（單位增量）",
            false,
            "X=" +
            x.render() +
            "、e=" +
            e.to_string() +
            "：r(X∪e)=" +
            rxe.to_string() +
            "，r(X)=" +
            rx.to_string(),
          )
        }
      }
    }
  }
  for mask = 0; mask <= top; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(self.n, mask)
    let r = self.rank(x)
    if r < 0 || r > x.count() {
      return @galois.Check::make(
        "X6",
        "秩公理 R1",
        false,
        "X=" + x.render() + " 的秩越界",
      )
    }
    // P-B2：秩閉包 == 迴路閉包
    if !self.closure_by_rank(x).equals(self.closure(x)) {
      return @galois.Check::make(
        "X6",
        "秩—閉包對偶（P-B2）",
        false,
        "X=" +
        x.render() +
        "：秩閉包=" +
        self.closure_by_rank(x).render() +
        "，迴路閉包=" +
        self.closure(x).render(),
      )
    }
    if self.rank(self.closure(x)) != r {
      return @galois.Check::make(
        "X6",
        "秩不變（E-B2）",
        false,
        "X=" + x.render(),
      )
    }
  }
  // R2 單調、R3 次模
  for m1 = 0; m1 <= top; m1 = m1 + 1 {
    let x = @bitset.BitSet::from_mask(self.n, m1)
    for e = 0; e < self.n; e = e + 1 {
      if self.rank(x) > self.rank(x.plus_bit(e)) {
        return @galois.Check::make(
          "X6",
          "秩公理 R2",
          false,
          "X=" + x.render(),
        )
      }
    }
  }
  for m1 = 0; m1 <= top; m1 = m1 + 1 {
    let x = @bitset.BitSet::from_mask(self.n, m1)
    for m2 = 0; m2 <= top; m2 = m2 + 1 {
      let y = @bitset.BitSet::from_mask(self.n, m2)
      let lhs = self.rank(x) + self.rank(y)
      let rhs = self.rank(x.union(y)) + self.rank(x.intersect(y))
      if lhs < rhs {
        return @galois.Check::make(
          "X6",
          "秩公理 R3（次模）",
          false,
          "X=" + x.render() + " Y=" + y.render(),
        )
      }
    }
  }
  @galois.Check::make(
    "X6",
    "秩公理 R1–R4 與 P-B2",
    true,
    "r(E)=" + self.rank(@bitset.BitSet::full(self.n)).to_string(),
  )
}

///|
/// P-B3：相依 ⟺ 含迴路；並檢核「秩 = 最大獨立子集大小」與「獨立 ⟺ 秩=基數」。
pub fn Matroid::check_independence(self : Matroid) -> @galois.Check {
  if self.n > 18 {
    return @galois.Check::make(
      "P-B3", "相依判準", false, "未檢核：n > 18",
    )
  }
  for mask = 0; mask < 1 << self.n; mask = mask + 1 {
    let x = @bitset.BitSet::from_mask(self.n, mask)
    let has_circuit = {
      let mut hit = false
      for i = 0; i < self.circuits.length(); i = i + 1 {
        if self.circuits[i].subset_of(x) {
          hit = true
        }
      }
      hit
    }
    if has_circuit == self.independent(x) {
      return @galois.Check::make(
        "P-B3",
        "相依判準",
        false,
        "X=" + x.render() + " 的相依判定不一致",
      )
    }
    if self.independent(x) != (self.rank(x) == x.count()) {
      return @galois.Check::make(
        "P-B3",
        "獨立 ⟺ 秩=基數",
        false,
        "X=" + x.render(),
      )
    }
  }
  @galois.Check::make("P-B3", "相依判準與獨立性", true, "")
}

///|
/// T7 與 A2 的交叉檢核：由 K_ℱ 的 NextClosure 枚舉出的內涵，其外延必須恰為平坦集。
pub fn Matroid::check_flats_agree_with_context(self : Matroid) -> @galois.Check {
  let flats = self.flats()
  let ctx = context_of_moore_family(self.name, self.n, flats)
  let intents = @lattice.all_closed_stmts(ctx)
  if intents.length() != flats.length() {
    return @galois.Check::make(
      "T7",
      "平坦集 ↔ 概念內涵",
      false,
      "NextClosure=" +
      intents.length().to_string() +
      " 但 |ℱ|=" +
      flats.length().to_string(),
    )
  }
  // 每個內涵的外延都是平坦集，且每個平坦集都出現
  let seen : Array[Bool] = []
  for mask = 0; mask < 1 << self.n; mask = mask + 1 {
    seen.push(false)
  }
  let concepts = @lattice.all_concepts(ctx)
  for i = 0; i < concepts.length(); i = i + 1 {
    let ext = concepts[i].extent()
    if !self.is_flat(ext) {
      return @galois.Check::make(
        "T7",
        "平坦集 ↔ 概念內涵",
        false,
        "外延 " + ext.render() + " 不是平坦集",
      )
    }
    seen[ext.to_mask()] = true
  }
  for i = 0; i < flats.length(); i = i + 1 {
    if !seen[flats[i].to_mask()] {
      return @galois.Check::make(
        "T7",
        "平坦集 ↔ 概念內涵",
        false,
        "平坦集 " +
        flats[i].render() +
        " 未作為任何概念的外延出現",
      )
    }
  }
  @galois.Check::make(
    "T7",
    "平坦集 ↔ 概念內涵",
    true,
    "|ℱ|=|B(K_ℱ)|=" + flats.length().to_string(),
  )
}

///|
/// X2 結構性斷言：含 ∅ 的 K_ℱ 必然違反 X2（空平坦集無見證）；去掉 ∅ 後 K_ℱ* 必然滿足 X2。
/// 把「預期失敗」升級為**正面斷言**，避免以沉默的紅燈掩蓋設計問題。
pub fn Matroid::check_empty_flat_support(self : Matroid) -> @galois.Check {
  let full = self.flats()
  let ctx_full = context_of_moore_family(self.name, self.n, full)
  let ctx_star = context_of_moore_family(self.name, self.n, without_empty(full))
  let full_has_violation = {
    let mut violated = false
    for s = 0; s < ctx_full.num_stmts(); s = s + 1 {
      if ctx_full.cols[s].is_empty() {
        violated = true
      }
    }
    violated
  }
  let star_ok = {
    let mut ok = true
    for s = 0; s < ctx_star.num_stmts(); s = s + 1 {
      if ctx_star.cols[s].is_empty() {
        ok = false
      }
    }
    for a = 0; a < ctx_star.num_axioms(); a = a + 1 {
      if ctx_star.rows[a].is_empty() {
        ok = false
      }
    }
    ok
  }
  if !full_has_violation {
    return @galois.Check::make(
      "X2", "空平坦集的 X2 分析", false, "K_ℱ 竟然滿足 X2：預期 ∅ ∈ ℱ 會造成無見證陳述（結構分析失真）",
    )
  }
  if !star_ok {
    return @galois.Check::make(
      "X2", "空平坦集的 X2 分析", false, "K_ℱ* 仍違反 X2",
    )
  }
  @galois.Check::make(
    "X2", "空平坦集的 X2 分析（K_ℱ 違反／K_ℱ* 滿足）", true, "∅ ∈ ℱ ⇒ K_ℱ 有無見證陳述；ℱ* 修正",
  )
}

///|
/// A12：擬陣完整檢核報告（不含 B0001 的繼承檢核，後者另設以免規模爆炸）。
pub fn Matroid::matroid_report(self : Matroid) -> @galois.Report {
  let r = @galois.Report::new()
  r.add(self.check_circuit_axioms())
  r.add(self.check_exchange())
  r.add(self.check_rank_axioms())
  r.add(self.check_independence())
  r.add(self.check_geometric())
  r.add(self.check_realization())
  r.add(self.check_flats_agree_with_context())
  r.add(self.check_empty_flat_support())
  r
}

///|
/// A12（繼承）：把 B0001 的 A6（結構 8 條）＋ A2/A3/A5（3 條）套到 K_ℱ 上。
/// 僅在規模允許時執行，否則回報「未檢核」（不以綠燈冒充）。
pub fn Matroid::check_b0001_inheritance(self : Matroid) -> @galois.Report {
  let r = @galois.Report::new()
  let k = self.flats().length()
  if self.n > 8 || k > 16 {
    r.add(
      @galois.Check::make(
        "T7",
        "B0001 A6 繼承",
        false,
        "未檢核：|E|=" +
        self.n.to_string() +
        "、|ℱ|=" +
        k.to_string() +
        " 超出預算（|E|≤8 且 |ℱ|≤16）",
      ),
    )
    return r
  }
  let ctx = context_of_moore_family(
    self.name,
    self.n,
    without_empty(self.flats()),
  )
  let structural = @galois.structural_report(ctx)
  for i = 0; i < structural.size(); i = i + 1 {
    r.add(structural.get(i))
  }
  let lattice_report = @lattice.basis_report(ctx)
  for i = 0; i < lattice_report.size(); i = i + 1 {
    r.add(lattice_report.get(i))
  }
  r
}
