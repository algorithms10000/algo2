///|
/// B0001 / galois 套件：A6 檢核器（反例搜尋）
///
/// 每個 check_* 對應 docs/B0001-定理體系.md 的一條公理／命題／定理，
/// 在**給定的有限上下文上窮舉**驗證；失敗時回報最小反例。
/// 檢核器不使用被檢核的同一個程式路徑：閉包相關檢核一律與 reference.mbt 的逐元素迭代路徑對照。

///|
/// 單條檢核結果。
pub struct Check {
  law : String
  name : String
  passed : Bool
  detail : String
}

///|
/// 建構檢核結果（供其他套件產生檢核項）。
pub fn Check::make(
  law : String,
  name : String,
  passed : Bool,
  detail : String,
) -> Check {
  { law, name, passed, detail, }
}

///|
pub fn Check::law(self : Check) -> String {
  self.law
}

///|
pub fn Check::name(self : Check) -> String {
  self.name
}

///|
pub fn Check::passed(self : Check) -> Bool {
  self.passed
}

///|
pub fn Check::detail(self : Check) -> String {
  self.detail
}

///|
/// 檢核報告。
pub struct Report {
  checks : Array[Check]
}

///|
pub fn Report::new() -> Report {
  { checks: [], }
}

///|
pub fn Report::add(self : Report, c : Check) -> Unit {
  self.checks.push(c)
}

///|
pub fn Report::size(self : Report) -> Int32 {
  self.checks.length()
}

///|
pub fn Report::all_passed(self : Report) -> Bool {
  for i = 0; i < self.checks.length(); i = i + 1 {
    if !self.checks[i].passed {
      return false
    }
  }
  true
}

///|
pub fn Report::passed_count(self : Report) -> Int32 {
  let mut k = 0
  for i = 0; i < self.checks.length(); i = i + 1 {
    if self.checks[i].passed {
      k = k + 1
    }
  }
  k
}

///|
pub fn Report::get(self : Report, i : Int32) -> Check {
  self.checks[i]
}

///|
/// 報告文字化（CLI 輸出格式）。
pub fn Report::render(self : Report) -> String {
  let sb = StringBuilder()
  for i = 0; i < self.checks.length(); i = i + 1 {
    let c = self.checks[i]
    let mark = if c.passed { "PASS" } else { "FAIL" }
    sb.write_string("  [" + mark + "] " + c.law + " " + c.name)
    if !c.passed {
      sb.write_string("  ← 反例／原因：" + c.detail)
    }
    sb.write_string("\n")
  }
  sb.to_string()
}

///|
/// X2：每條公理至少支撐一條陳述、每條陳述至少有一條見證公理。
pub fn check_support(ctx : @context.FormalContext) -> Check {
  let bad_axioms : Array[String] = []
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    if ctx.rows[a].is_empty() {
      bad_axioms.push(ctx.axiom_name(a))
    }
  }
  let bad_stmts : Array[String] = []
  for s = 0; s < ctx.num_stmts(); s = s + 1 {
    if ctx.cols[s].is_empty() {
      bad_stmts.push(ctx.stmt_name(s))
    }
  }
  let ok = bad_axioms.length() == 0 && bad_stmts.length() == 0
  let detail = if ok {
    ""
  } else {
    "空支撐公理=" +
    join_names(bad_axioms) +
    "；無見證陳述=" +
    join_names(bad_stmts)
  }
  { law: "X2", name: "支撐完全性", passed: ok, detail, }
}

///|
fn join_names(xs : Array[String]) -> String {
  let sb = StringBuilder()
  sb.write_string("{")
  for i = 0; i < xs.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    sb.write_string(xs[i])
  }
  sb.write_string("}")
  sb.to_string()
}

///|
/// P1：反單調性。由「單元素擴張」窮舉即可（配合 ⊆ 的遞移性涵蓋全部鏈）。
pub fn check_antitone(ctx : @context.FormalContext) -> Check {
  let m = ctx.num_axioms()
  let n = ctx.num_stmts()
  let subs_a = @bitset.all_subsets(m)
  for i = 0; i < subs_a.length(); i = i + 1 {
    let x = subs_a[i]
    let phi_x = ctx.intent(x)
    for a = 0; a < m; a = a + 1 {
      if !x.get(a) {
        let phi_xa = ctx.intent(x.plus_bit(a))
        if !phi_xa.subset_of(phi_x) {
          return {
            law: "P1",
            name: "反單調性",
            passed: false,
            detail: "Φ(" +
            ctx.render_axioms(x.plus_bit(a)) +
            ") ⊄ Φ(" +
            ctx.render_axioms(x) +
            ")",
          }
        }
      }
    }
  }
  let subs_s = @bitset.all_subsets(n)
  for i = 0; i < subs_s.length(); i = i + 1 {
    let y = subs_s[i]
    let psi_y = ctx.extent(y)
    for s = 0; s < n; s = s + 1 {
      if !y.get(s) {
        let psi_ys = ctx.extent(y.plus_bit(s))
        if !psi_ys.subset_of(psi_y) {
          return {
            law: "P1",
            name: "反單調性",
            passed: false,
            detail: "Ψ(" +
            ctx.render_stmts(y.plus_bit(s)) +
            ") ⊄ Ψ(" +
            ctx.render_stmts(y) +
            ")",
          }
        }
      }
    }
  }
  { law: "P1", name: "反單調性", passed: true, detail: "", }
}

///|
/// X0／L1：伴隨律 X ⊆ Ψ(Y) ⟺ Y ⊆ Φ(X)（窮舉 X、Y）。
pub fn check_adjunction(ctx : @context.FormalContext) -> Check {
  let subs_a = @bitset.all_subsets(ctx.num_axioms())
  let subs_s = @bitset.all_subsets(ctx.num_stmts())
  let phi : Array[@bitset.BitSet] = []
  for i = 0; i < subs_a.length(); i = i + 1 {
    phi.push(ctx.intent(subs_a[i]))
  }
  let psi : Array[@bitset.BitSet] = []
  for j = 0; j < subs_s.length(); j = j + 1 {
    psi.push(ctx.extent(subs_s[j]))
  }
  for i = 0; i < subs_a.length(); i = i + 1 {
    for j = 0; j < subs_s.length(); j = j + 1 {
      let left = subs_a[i].subset_of(psi[j])
      let right = subs_s[j].subset_of(phi[i])
      if left != right {
        return {
          law: "L1",
          name: "伴隨律（伽羅瓦對應）",
          passed: false,
          detail: "X=" +
          ctx.render_axioms(subs_a[i]) +
          "，Y=" +
          ctx.render_stmts(subs_s[j]) +
          "：" +
          "X⊆Ψ(Y)=" +
          left.to_string() +
          " 但 Y⊆Φ(X)=" +
          right.to_string(),
        }
      }
    }
  }
  {
    law: "L1",
    name: "伴隨律（伽羅瓦對應）",
    passed: true,
    detail: "",
  }
}

///|
/// P2／L4：閉包三性（擴張、單調、冪等），且單次雙閉包 == 迭代到定點（獨立的參考路徑）。
pub fn check_closure_laws(ctx : @context.FormalContext) -> Check {
  let subs_a = @bitset.all_subsets(ctx.num_axioms())
  for i = 0; i < subs_a.length(); i = i + 1 {
    let x = subs_a[i]
    let cl = closure_axioms(ctx, x)
    if !x.subset_of(cl) {
      return {
        law: "P2",
        name: "閉包三性（公理側）",
        passed: false,
        detail: "非擴張：X=" +
        ctx.render_axioms(x) +
        "，cl(X)=" +
        ctx.render_axioms(cl),
      }
    }
    let cl2 = closure_axioms(ctx, cl)
    if !cl2.equals(cl) {
      return {
        law: "P2",
        name: "閉包三性（公理側）",
        passed: false,
        detail: "非冪等：X=" +
        ctx.render_axioms(x) +
        "，cl=" +
        ctx.render_axioms(cl) +
        "，cl(cl)=" +
        ctx.render_axioms(cl2),
      }
    }
    let reference = closure_axioms_iterated(ctx, x)
    if !reference.equals(cl) {
      return {
        law: "L4",
        name: "單次雙閉包即定點",
        passed: false,
        detail: "X=" +
        ctx.render_axioms(x) +
        "：單次=" +
        ctx.render_axioms(cl) +
        "，迭代=" +
        ctx.render_axioms(reference),
      }
    }
  }
  let subs_s = @bitset.all_subsets(ctx.num_stmts())
  for j = 0; j < subs_s.length(); j = j + 1 {
    let y = subs_s[j]
    let cl = closure_stmts(ctx, y)
    if !y.subset_of(cl) {
      return {
        law: "P2",
        name: "閉包三性（陳述側）",
        passed: false,
        detail: "非擴張：Y=" +
        ctx.render_stmts(y) +
        "，cl(Y)=" +
        ctx.render_stmts(cl),
      }
    }
    let cl2 = closure_stmts(ctx, cl)
    if !cl2.equals(cl) {
      return {
        law: "P2",
        name: "閉包三性（陳述側）",
        passed: false,
        detail: "非冪等：Y=" + ctx.render_stmts(y),
      }
    }
    let reference = closure_stmts_iterated(ctx, y)
    if !reference.equals(cl) {
      return {
        law: "L4",
        name: "單次雙閉包即定點（陳述側）",
        passed: false,
        detail: "Y=" +
        ctx.render_stmts(y) +
        "：單次=" +
        ctx.render_stmts(cl) +
        "，迭代=" +
        ctx.render_stmts(reference),
      }
    }
  }
  {
    law: "P2+L4",
    name: "閉包三性與單次定點",
    passed: true,
    detail: "",
  }
}

///|
/// P3：Moore 族——閉集族對任意交封閉（以兩兩交窮舉代表，因二交封閉 ⇒ 任意有限交封閉）。
pub fn check_moore(ctx : @context.FormalContext) -> Check {
  let closed_a = all_closed_bruteforce(ctx, AxiomSide)
  for i = 0; i < closed_a.length(); i = i + 1 {
    for j = i; j < closed_a.length(); j = j + 1 {
      let meet = closed_a[i].intersect(closed_a[j])
      if !is_closed_axioms(ctx, meet) {
        return {
          law: "P3",
          name: "Moore 族（公理側）",
          passed: false,
          detail: "交不閉：" +
          ctx.render_axioms(closed_a[i]) +
          " ∩ " +
          ctx.render_axioms(closed_a[j]) +
          " = " +
          ctx.render_axioms(meet),
        }
      }
    }
  }
  let full_a = @bitset.BitSet::full(ctx.num_axioms())
  if !is_closed_axioms(ctx, full_a) {
    return {
      law: "P3",
      name: "Moore 族（公理側）",
      passed: false,
      detail: "A 不是閉集",
    }
  }
  let closed_s = all_closed_bruteforce(ctx, StmtSide)
  for i = 0; i < closed_s.length(); i = i + 1 {
    for j = i; j < closed_s.length(); j = j + 1 {
      let meet = closed_s[i].intersect(closed_s[j])
      if !is_closed_stmts(ctx, meet) {
        return {
          law: "P3",
          name: "Moore 族（陳述側）",
          passed: false,
          detail: "交不閉：" +
          ctx.render_stmts(closed_s[i]) +
          " ∩ " +
          ctx.render_stmts(closed_s[j]),
        }
      }
    }
  }
  { law: "P3", name: "Moore 族（兩側）", passed: true, detail: "", }
}

///|
/// P4／P5：兩側閉集族的反序雙射與計數相等。
pub fn check_duality(ctx : @context.FormalContext) -> Check {
  let closed_a = all_closed_bruteforce(ctx, AxiomSide)
  let closed_s = all_closed_bruteforce(ctx, StmtSide)
  for i = 0; i < closed_a.length(); i = i + 1 {
    let x = closed_a[i]
    let phi = ctx.intent(x)
    if !is_closed_stmts(ctx, phi) {
      return {
        law: "P4",
        name: "反序雙射（Φ 像閉）",
        passed: false,
        detail: "Φ(" +
        ctx.render_axioms(x) +
        ")=" +
        ctx.render_stmts(phi) +
        " 不閉",
      }
    }
    let back = ctx.extent(phi)
    if !back.equals(x) {
      return {
        law: "P4",
        name: "反序雙射（Ψ∘Φ=id）",
        passed: false,
        detail: "ΨΦ(" + ctx.render_axioms(x) + ")=" + ctx.render_axioms(back),
      }
    }
  }
  for j = 0; j < closed_s.length(); j = j + 1 {
    let y = closed_s[j]
    let back = ctx.intent(ctx.extent(y))
    if !back.equals(y) {
      return {
        law: "P4",
        name: "反序雙射（Φ∘Ψ=id）",
        passed: false,
        detail: "ΦΨ(" + ctx.render_stmts(y) + ")=" + ctx.render_stmts(back),
      }
    }
  }
  if closed_a.length() != closed_s.length() {
    return {
      law: "P5",
      name: "計數相等",
      passed: false,
      detail: "|ℭ_A|=" +
      closed_a.length().to_string() +
      " 但 |ℭ_S|=" +
      closed_s.length().to_string(),
    }
  }
  {
    law: "P4+P5",
    name: "反序雙射與計數相等",
    passed: true,
    detail: "|ℭ_A|=|ℭ_S|=" + closed_a.length().to_string(),
  }
}

///|
/// T2：分離性 ⟺ 所有單點閉包為單點 ⟺ row 互不包含。
pub fn check_separation(ctx : @context.FormalContext) -> Check {
  let mut separation_holds = true
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    for b = 0; b < ctx.num_axioms(); b = b + 1 {
      if a != b && ctx.rows[b].subset_of(ctx.rows[a]) {
        separation_holds = false
      }
    }
  }
  let mut all_singleton = true
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    let cl = singleton_closure(ctx, a)
    if cl.count() != 1 || !cl.get(a) {
      all_singleton = false
    }
  }
  if separation_holds != all_singleton {
    return {
      law: "T2",
      name: "分離性 ⟺ 閉單點",
      passed: false,
      detail: "X3=" +
      separation_holds.to_string() +
      "，閉單點=" +
      all_singleton.to_string() +
      "（定理被違反）",
    }
  }
  let redundant = redundant_axioms(ctx)
  let detail = if redundant.length() == 0 {
    "X3 成立：無冗餘公理"
  } else {
    "X3 不成立：冗餘公理 " +
    ctx.render_axioms(@bitset.BitSet::from_indices(ctx.num_axioms(), redundant))
  }
  {
    law: "T2",
    name: "分離性 ⟺ 閉單點（等價性成立）",
    passed: true,
    detail,
  }
}

///|
/// T3：局部性——以分量分解算出的閉包必須與全域雙閉包完全一致，且坍縮判定符合定理。
pub fn check_locality(ctx : @context.FormalContext) -> Check {
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    if ctx.rows[a].is_empty() {
      return {
        law: "T3",
        name: "局部性",
        passed: false,
        detail: "前提 X2 不成立（公理 " +
        ctx.axiom_name(a) +
        " 無支撐），定理不適用",
      }
    }
  }
  let dec = decompose(ctx)
  let subs_a = @bitset.all_subsets(ctx.num_axioms())
  for i = 0; i < subs_a.length(); i = i + 1 {
    let x = subs_a[i]
    let actual = closure_axioms(ctx, x)
    let pred = local_closure(ctx, dec, x)
    if !pred.closure.equals(actual) {
      return {
        law: "T3",
        name: "局部性（分量閉包=全域閉包）",
        passed: false,
        detail: "X=" +
        ctx.render_axioms(x) +
        "：局部=" +
        ctx.render_axioms(pred.closure) +
        "，全域=" +
        ctx.render_axioms(actual),
      }
    }
    if pred.collapsed && !actual.equals(@bitset.BitSet::full(ctx.num_axioms())) {
      return {
        law: "T3",
        name: "跨分量坍縮",
        passed: false,
        detail: "X=" +
        ctx.render_axioms(x) +
        " 被判為坍縮，但 cl=" +
        ctx.render_axioms(actual),
      }
    }
    if !pred.collapsed && pred.component >= 0 {
      let comp = dec.component(pred.component)
      let ids = actual.ones()
      for k = 0; k < ids.length(); k = k + 1 {
        let mut inside = false
        for j = 0; j < comp.axioms.length(); j = j + 1 {
          if comp.axioms[j] == ids[k] {
            inside = true
          }
        }
        if !inside {
          return {
            law: "T3",
            name: "局部封閉性",
            passed: false,
            detail: "X=" +
            ctx.render_axioms(x) +
            " 的閉包越出分量：" +
            ctx.render_axioms(actual),
          }
        }
      }
    }
  }
  {
    law: "T3",
    name: "局部性（分量分解）",
    passed: true,
    detail: "分量數=" + dec.component_count().to_string(),
  }
}

///|
/// A6：一次跑完結構性檢核（不含需要 A2/A3 產物的檢核，那些在 lattice 套件）。
pub fn structural_report(ctx : @context.FormalContext) -> Report {
  let r = Report::new()
  r.add(check_support(ctx))
  r.add(check_antitone(ctx))
  r.add(check_adjunction(ctx))
  r.add(check_closure_laws(ctx))
  r.add(check_moore(ctx))
  r.add(check_duality(ctx))
  r.add(check_separation(ctx))
  r.add(check_locality(ctx))
  r
}
