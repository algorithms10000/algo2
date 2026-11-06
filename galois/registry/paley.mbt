///|
/// B0004 / registry 套件：**由撓群配對生成的樣本上下文 `paley-13`**（T21 的「多合一」落地）
/// 對應 docs/B0004-定理體系.md §9。
///
/// 物件 = 陳述 = 𝔽₁₃ 的 13 個點（Paley 圖 P(13) 的頂點，來源是 E[13] 配對值的二次特徵）；
/// 關係 = **閉鄰域**：i ~ j ⟺ i = j 或 χ₁₃(i−j) = 1。
/// 取閉鄰域而不是純鄰接，是為了讓每一列都唯一含有自己的索引 ⇒ B0001 的 X3（分離性）成立。
///
/// 這份上下文的意義：團複形是「兩兩相容 ⇒ 整體相容」的 Horn 閉包幾何實現，
/// 因此 B0001 的伽羅瓦對應、A3′ 典範基、A6 檢核器可以直接套在它上面——
/// 這就是「Ramsey 構造 → 團複形 → 形式上下文 → 蘊含基」的串接，而不是四段各自為政的展示。
///
/// Γ 一致性：P(13) 的 13 個點是 E[13] 的 168 條線的……不，這裡只用 𝔽₁₃ 這 13 個平移類；
/// 完整 ℙ¹(𝔽₁₃) 是 14 個點（多一個無窮遠點），它在 T18 的檢核裡有單獨處理。

///|
/// 樣本上下文：13 個點 × 三角形（關係 = 屬於）。
pub fn paley_context() -> @context.FormalContext {
  let q = 13
  let adj = @elliptic.paley_adjacency(q)
  let names : Array[String] = []
  for i = 0; i < q; i = i + 1 {
    names.push("P" + i.to_string())
  }
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < q; i = i + 1 {
    for j = 0; j < q; j = j + 1 {
      if i == j || adj[i][j] {
        edges.push((i, j))
      }
    }
  }
  @context.FormalContext::new(names, names, edges)
}

///|
/// 摘要：規模、閉集數、DG 基、B0001 的 A6 與 A3′ 檢核。
pub fn paley_summary() -> String {
  let ctx = paley_context()
  let sb = StringBuilder()
  sb.write_string(
    "上下文：paley-13（P(13) 的 13 個點 × 同 13 個點，關係 = 閉鄰域）\n",
  )
  sb.write_string(
    "  由 @elliptic.paley_adjacency(13) 直接讀出；鄰接關係來自 E[13] 的 Weil 配對二次特徵\n",
  )
  sb.write_string(
    "  |A|=" +
    ctx.num_axioms().to_string() +
    "，|S|=" +
    ctx.num_stmts().to_string() +
    "，|R|=" +
    ctx.edge_count().to_string() +
    "，|ℭ_S|=|ℭ_A|=" +
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
