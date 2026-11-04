///|
/// B0003 / registry 套件：**同餘子群樣本上下文**（真數學物件）
/// 對應 docs/B0003-定理體系.md §6。
///
/// 物件 = 陳述 = 12 個同餘子群（位準 2、3、4、6，位準 1 的 SL₂(ℤ)）；
/// 關係 Γ ⊆ H **由有限群 SL₂(ℤ/12) 上的暴力包含判定**給出（不是查表、不是硬編碼）。
/// 因為同餘子群只依賴元素 mod 位準的行為，而所有位準都整除 12，此判定與在 SL₂(ℤ) 中完全相同。
///
/// 之所以排除 Γ₀(2) 與 Γ₁(2) 之一：φ(2) = 1 ⇒ Γ₀(2) = Γ₁(2)（這本身是 T13 的推論），
/// 兩者同時入表會造成重複列，破壞 B0001 的 X3（分離性）檢核。

///|
/// 樣本中的一列：子群 Γ_kind(level) 與其名稱。
priv struct CongruenceRow {
  name : String
  kind : @modular.SubgroupType
  level : Int32
}

///|
fn congruence_rows() -> Array[CongruenceRow] {
  [
    { name: "Γ₀(2)", kind: @modular.gamma_zero(), level: 2, },
    { name: "Γ(2)", kind: @modular.gamma_level(), level: 2, },
    { name: "Γ₀(3)", kind: @modular.gamma_zero(), level: 3, },
    { name: "Γ₁(3)", kind: @modular.gamma_one(), level: 3, },
    { name: "Γ(3)", kind: @modular.gamma_level(), level: 3, },
    { name: "Γ₀(4)", kind: @modular.gamma_zero(), level: 4, },
    { name: "Γ₁(4)", kind: @modular.gamma_one(), level: 4, },
    { name: "Γ(4)", kind: @modular.gamma_level(), level: 4, },
    { name: "Γ₀(6)", kind: @modular.gamma_zero(), level: 6, },
    { name: "Γ₁(6)", kind: @modular.gamma_one(), level: 6, },
    { name: "Γ(6)", kind: @modular.gamma_level(), level: 6, },
    { name: "SL₂(ℤ)", kind: @modular.full_sl2(), level: 1, },
  ]
}

///|
/// 建立樣本上下文（關係 = 包含，於 SL₂(ℤ/12) 上暴力判定）。
pub fn congruence_context() -> @context.FormalContext {
  let rows = congruence_rows()
  let n = rows.length()
  let names : Array[String] = []
  let names2 : Array[String] = []
  for i = 0; i < n; i = i + 1 {
    names.push(rows[i].name)
    names2.push(rows[i].name)
  }
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < n; i = i + 1 {
    for j = 0; j < n; j = j + 1 {
      if @modular.subset_by_bruteforce(
          rows[i].kind,
          rows[i].level,
          rows[j].kind,
          rows[j].level,
          12,
        ) {
        edges.push((i, j))
      }
    }
  }
  @context.FormalContext::new(names, names2, edges)
}

///|
/// 樣本摘要：規模、閉集／概念數、DG 基、B0001 的 A6 檢核、A3′ 檢核。
pub fn congruence_summary() -> String {
  let ctx = congruence_context()
  let sb = StringBuilder()
  sb.write_string(
    "上下文：congruence-12（同餘子群以包含關係構成）\n",
  )
  sb.write_string(
    "  來源：A = S = {" +
    "Γ₀(2), Γ(2), Γ₀(3), Γ₁(3), Γ(3), Γ₀(4), Γ₁(4), Γ(4), Γ₀(6), Γ₁(6), Γ(6), SL₂(ℤ)}；" +
    "R 由 SL₂(ℤ/12) 上的暴力包含判定給出\n",
  )
  sb.write_string(
    "  |A|=|S|=" +
    ctx.num_axioms().to_string() +
    "，|R|=" +
    ctx.edge_count().to_string() +
    "，|ℭ_S|=" +
    @lattice.all_closed_stmts(ctx).length().to_string() +
    "\n",
  )
  sb.write_string("  DG 基（A3′）：" + @lattice.dg_stats_line(ctx) + "\n")
  let a6 = @galois.structural_report(ctx)
  sb.write_string(
    "  B0001 A6 檢核：" +
    a6.passed_count().to_string() +
    "/" +
    a6.size().to_string() +
    " 通過\n",
  )
  sb.write_string(a6.render())
  let dgr = @lattice.dg_report(ctx)
  sb.write_string(
    "  A3′ 檢核：" +
    dgr.passed_count().to_string() +
    "/" +
    dgr.size().to_string() +
    " 通過\n",
  )
  sb.write_string(dgr.render())
  sb.to_string()
}
