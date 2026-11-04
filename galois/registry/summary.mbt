///|
/// B0001 / registry 套件：上下文摘要（CLI 的 `info` 輸出）
/// 每一欄都對應 docs/B0001-定理體系.md 的一個量：
/// 閉集數（P5）、概念數（P5）、覆蓋邊數（A5）、典範基規模（T4）、冗餘公理（T2）、分量數（T3）、檢核報告（A6）。

///|
pub struct ContextSummary {
  name : String
  source : String
  axioms : Int32
  stmts : Int32
  edges : Int32
  components : Int32
  closed_axiom_count : Int32
  closed_stmt_count : Int32
  concept_count : Int32
  hasse_edges : Int32
  basis_size : Int32
  redundant : Array[String]
  basis : Array[String]
  report : @galois.Report
}

///|
pub fn ContextSummary::render(self : ContextSummary) -> String {
  let sb = StringBuilder()
  sb.write_string("上下文：" + self.name + "\n")
  sb.write_string("  來源：" + self.source + "\n")
  sb.write_string(
    "  |A|=" +
    self.axioms.to_string() +
    "，|S|=" +
    self.stmts.to_string() +
    "，|R|=" +
    self.edges.to_string() +
    "，分量數=" +
    self.components.to_string() +
    "\n",
  )
  sb.write_string(
    "  |ℭ_A|=" +
    self.closed_axiom_count.to_string() +
    "，|ℭ_S|=" +
    self.closed_stmt_count.to_string() +
    "，概念數|B(K)|=" +
    self.concept_count.to_string() +
    "，Hasse 覆蓋邊=" +
    self.hasse_edges.to_string() +
    "\n",
  )
  sb.write_string(
    "  典範基 Σ（Duquenne–Guiguès）：規模=" +
    self.basis_size.to_string() +
    "\n",
  )
  for i = 0; i < self.basis.length(); i = i + 1 {
    sb.write_string("    " + self.basis[i] + "\n")
  }
  if self.redundant.length() > 0 {
    sb.write_string("  冗餘公理（T2 判定）：{")
    for i = 0; i < self.redundant.length(); i = i + 1 {
      if i > 0 {
        sb.write_string(", ")
      }
      sb.write_string(self.redundant[i])
    }
    sb.write_string("}\n")
  } else {
    sb.write_string(
      "  冗餘公理（T2 判定）：無（X3 分離性成立）\n",
    )
  }
  sb.write_string(
    "  檢核（A6）：" +
    self.report.passed_count().to_string() +
    "/" +
    self.report.size().to_string() +
    " 通過\n",
  )
  sb.write_string(self.report.render())
  sb.to_string()
}

///|
/// 對單一登記上下文做完整摘要（含 A6 結構檢核與 A3 基檢核）。
pub fn summarize(reg : Registered) -> ContextSummary {
  let ctx = reg.ctx
  let dec = @galois.decompose(ctx)
  let closed_axioms = @galois.all_closed_bruteforce(ctx, @galois.AxiomSide)
  let closed_stmts = @lattice.all_closed_stmts(ctx)
  let basis = @lattice.canonical_basis(ctx)
  let basis_lines : Array[String] = []
  for i = 0; i < basis.length(); i = i + 1 {
    basis_lines.push(@lattice.render_implication(ctx, basis[i]))
  }
  let redundant_ids = @galois.redundant_axioms(ctx)
  let redundant_names : Array[String] = []
  for i = 0; i < redundant_ids.length(); i = i + 1 {
    redundant_names.push(ctx.axiom_name(redundant_ids[i]))
  }
  let report = @galois.structural_report(ctx)
  let basis_report = @lattice.basis_report(ctx)
  for i = 0; i < basis_report.size(); i = i + 1 {
    report.add(basis_report.get(i))
  }
  {
    name: reg.name,
    source: reg.source,
    axioms: ctx.num_axioms(),
    stmts: ctx.num_stmts(),
    edges: ctx.edge_count(),
    components: dec.component_count(),
    closed_axiom_count: closed_axioms.length(),
    closed_stmt_count: closed_stmts.length(),
    concept_count: closed_stmts.length(),
    hasse_edges: @lattice.hasse_edge_count(ctx),
    basis_size: basis.length(),
    redundant: redundant_names,
    basis: basis_lines,
    report,
  }
}
