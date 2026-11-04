///|
/// B0001 / CLI：接入與輸出接口
///
/// 用法（於 galois/ 目錄）：
///   moon run cmd/main                     全部登記上下文的完整摘要（示範）
///   moon run cmd/main -- list             列出登記上下文（B0001）
///   moon run cmd/main -- matroids         列出擬陣樣本（B0002）
///   moon run cmd/main -- matroid <名稱>   擬陣摘要＋A12 檢核（B0002）
///   moon run cmd/main -- mcheck <名稱>    擬陣摘要＋A12＋B0001 繼承檢核（規模允許時）
///   moon run cmd/main -- mcircuits <名稱> 列出迴路系統（B0002）
///   moon run cmd/main -- dg <名稱>        A3′ 增量式典範基（統計＋檢核）
///   moon run cmd/main -- dgbasis <名稱>   列出每一條蘊含
///   moon run cmd/main -- mext <名稱>      B0002 延伸（二元性／正則性／對偶／Tutte）
///   moon run cmd/main -- modular          B0003 同餘子群檢核（T13、T14）
///   moon run cmd/main -- congruence       B0003 樣本上下文（A6＋DG 基）
///   moon run cmd/main -- genus            印出 X₀(N) 的 ψ/φ/ν₂/ν₃/ν_∞/g 並與古典表比對
///   moon run cmd/main -- elliptic         B0004 撓群 E[n] 檢核（T15–T21）
///   moon run cmd/main -- eptable          E[n] 的軌道計數與 B0003 同餘指數對照
///   moon run cmd/main -- paley            Paley 圖／競賽與團複形同調（T18、T19、T21）
///   moon run cmd/main -- paleyctx         paley-13 樣本上下文（A6＋A3′）
///   moon run cmd/main -- braid           【B0005】辮群檢核（T22–T24）
///   moon run cmd/main -- jacobian        【B0005】圖雅可比簇檢核（T25–T31）
///   moon run cmd/main -- jtable          圖雅可比簇的結構表（不變因子、階、生成樹）
///   moon run cmd/main -- arf             theta 特徵與 Arf 不變量
///   moon run cmd/main -- mreg             擬陣登記期望值核對（含延伸樣本）
///   moon run cmd/main -- mextall          B0002 延伸的全域定理檢核（T9–T12）
///   moon run cmd/main -- mcensus <n>      小型擬陣普查（n ≤ 5）
///   moon run cmd/main -- negctl           負控制：區間凸包必須 FAIL 交換公理（T8）
///   moon run cmd/main -- info <名稱>      單一上下文摘要 + A6 檢核
///   moon run cmd/main -- concepts <名稱>  列出全部概念（外延 ↔ 內涵）
///   moon run cmd/main -- basis <名稱>     列出 Duquenne–Guiguès 典範基
///   moon run cmd/main -- closure <名稱> <公理名稱>...   計算 cl_A(X) 與 Φ(X)
///   moon run cmd/main -- dump <名稱>      以文字格式匯出（與 parse 互逆）
///   moon run cmd/main -- parse "<文字格式上下文>"      解析外部上下文並摘要
///
/// 文字格式（亦可寫在 .ctx 檔後以 "$(cat xxx.ctx)" 傳入，見 contexts/ 目錄）：
///   context <名稱>
///   axiom   <公理名稱>
///   stmt    <陳述名稱>
///   edges   <公理名稱> <陳述名稱> ...

///|
fn print_banner() -> Unit {
  println(
    "B0001 全局公理伽羅瓦對應（Galois 對應 / 閉包系統 / 概念格 / 典範基）",
  )
  println(
    "定理體系見 docs/B0001-定理體系.md；登記表見 algorithm.xlsx",
  )
  println("")
}

///|
fn show_summary(reg : @registry.Registered) -> Unit {
  println(@registry.summarize(reg).render())
}

///|
fn show_all() -> Unit {
  let all = @registry.registered()
  for i = 0; i < all.length(); i = i + 1 {
    show_summary(all[i])
  }
}

///|
fn show_list() -> Unit {
  let all = @registry.registered()
  for i = 0; i < all.length(); i = i + 1 {
    println("  " + all[i].name + "  ←  " + all[i].source)
  }
}

///|
fn show_concepts(reg : @registry.Registered) -> Unit {
  let ctx = reg.ctx
  let concepts = @lattice.all_concepts(ctx)
  println(
    "概念數 |B(K)| = " + concepts.length().to_string() + "（lectic 序）",
  )
  for i = 0; i < concepts.length(); i = i + 1 {
    println(
      "  #" +
      i.to_string() +
      "  (" +
      ctx.render_axioms(concepts[i].extent()) +
      " , " +
      ctx.render_stmts(concepts[i].intent()) +
      ")",
    )
  }
}

///|
fn show_basis(reg : @registry.Registered) -> Unit {
  let ctx = reg.ctx
  let basis = @lattice.canonical_basis(ctx)
  println(
    "Duquenne–Guiguès 典範基 Σ：規模=" + basis.length().to_string(),
  )
  for i = 0; i < basis.length(); i = i + 1 {
    println("  " + @lattice.render_implication(ctx, basis[i]))
  }
}

///|
/// 小型整數解析（只接受 0..99 的十進位字串；CLI 的 n 參數用）。
fn census_arg(text : String) -> Int32? {
  if text == "1" {
    Some(1)
  } else if text == "2" {
    Some(2)
  } else if text == "3" {
    Some(3)
  } else if text == "4" {
    Some(4)
  } else if text == "5" {
    Some(5)
  } else {
    None
  }
}

///|
/// 匯出為文字格式（與 parse_context 互逆），供外部工具與 .ctx 檔使用。
pub fn dump_text(ctx : @context.FormalContext, name : String) -> String {
  let sb = StringBuilder()
  sb.write_string("# B0001 上下文匯出：" + name + "\n")
  sb.write_string("context " + name + "\n")
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    sb.write_string("axiom " + ctx.axiom_name(a) + "\n")
  }
  for s = 0; s < ctx.num_stmts(); s = s + 1 {
    sb.write_string("stmt " + ctx.stmt_name(s) + "\n")
  }
  for a = 0; a < ctx.num_axioms(); a = a + 1 {
    let ids = ctx.rows[a].ones()
    if ids.length() > 0 {
      sb.write_string("edges " + ctx.axiom_name(a))
      for k = 0; k < ids.length(); k = k + 1 {
        sb.write_string(" " + ctx.stmt_name(ids[k]))
      }
      sb.write_string("\n")
    }
  }
  sb.to_string()
}

///|
fn show_check(reg : @registry.Registered) -> Unit {
  let ctx = reg.ctx
  let report = @galois.structural_report(ctx)
  let basis_report = @lattice.basis_report(ctx)
  for i = 0; i < basis_report.size(); i = i + 1 {
    report.add(basis_report.get(i))
  }
  println("上下文：" + reg.name)
  println(
    "檢核（A6）：" +
    report.passed_count().to_string() +
    "/" +
    report.size().to_string() +
    " 通過",
  )
  println(report.render())
}

///|
fn show_closure(reg : @registry.Registered, names : Array[String]) -> Unit {
  let ctx = reg.ctx
  let x = ctx.axioms_named(names) catch {
    err => {
      println("輸入錯誤：" + err.message())
      return
    }
  }
  let phi = ctx.intent(x)
  let cl = @galois.closure_axioms(ctx, x)
  let dec = @galois.decompose(ctx)
  let lc = @galois.local_closure(ctx, dec, x)
  println("X        = " + ctx.render_axioms(x))
  println("Φ(X)     = " + ctx.render_stmts(phi))
  println(
    "cl_A(X)  = " +
    ctx.render_axioms(cl) +
    "（閉集？" +
    @galois.is_closed_axioms(ctx, cl).to_string() +
    "）",
  )
  println(
    "A4 局部閉包 = " +
    ctx.render_axioms(lc.closure()) +
    "（坍縮=" +
    lc.collapsed().to_string() +
    "，分量=" +
    lc.component().to_string() +
    "）",
  )
  println(
    "概念     = (" +
    ctx.render_axioms(cl) +
    " , " +
    ctx.render_stmts(phi) +
    ")",
  )
}

///|
fn show_parse(text : String) -> Unit {
  let outcome = Ok(@context.parse_context(text)) catch { err => Err(err) }
  match outcome {
    Ok(parsed) => {
      let reg = @registry.Registered::make(
        parsed.name(),
        parsed.ctx(),
        "由 --parse 傳入的文字格式上下文",
      )
      show_summary(reg)
    }
    Err(err) => println("解析失敗：" + err.message())
  }
}

///|
fn main {
  let argv = @env.args()
  let args : Array[String] = []
  for i = 0; i < argv.length(); i = i + 1 {
    args.push(argv[i])
  }
  let mut offset = 0
  if args.length() > 0 {
    offset = 1
  }
  if args.length() <= offset {
    print_banner()
    show_all()
    return
  }
  let cmd = args[offset]
  let rest : Array[String] = []
  for i = offset + 1; i < args.length(); i = i + 1 {
    rest.push(args[i])
  }
  if cmd == "matroids" {
    let all = @registry.registered_matroids()
    for i = 0; i < all.length(); i = i + 1 {
      println("  " + all[i].name + "  ←  " + all[i].source)
    }
    println(
      "  interval-4  ←  負控制：區間凸包（antimatroid，非擬陣）",
    )
  } else if cmd == "matroid" || cmd == "mcheck" {
    if rest.length() < 1 {
      println("用法：-- matroid <名稱>（可用名稱見 -- matroids）")
      return
    }
    match @registry.lookup_matroid(rest[0]) {
      None =>
        if rest[0] == "interval-4" {
          println(@registry.interval_summary(4))
        } else {
          println("找不到擬陣：" + rest[0])
        }
      Some(reg) => {
        let with_inherit = cmd == "mcheck"
        println(@registry.matroid_summary(reg, with_inherit))
      }
    }
  } else if cmd == "mcircuits" {
    if rest.length() < 1 {
      println("用法：-- mcircuits <名稱>")
    } else {
      match @registry.lookup_matroid(rest[0]) {
        None => println("找不到擬陣：" + rest[0])
        Some(reg) => {
          let m = reg.matroid()
          println(
            "迴路系統（|𝒞|=" + m.circuit_count().to_string() + "）：",
          )
          let cs = m.circuits()
          for i = 0; i < cs.length(); i = i + 1 {
            println("  C" + i.to_string() + " = " + cs[i].render())
          }
        }
      }
    }
  } else if cmd == "dg" {
    if rest.length() < 1 {
      println("用法：-- dg <名稱>（A3′ 增量式典範基）")
      println("樣本：" + @registry.registered_dg_names().join("、"))
    } else {
      match @registry.lookup_dg(rest[0]) {
        None => println("找不到 A3′ 樣本：" + rest[0])
        Some(reg) => {
          let ctx = reg.ctx()
          println("上下文：" + reg.name())
          println("  來源：" + reg.source())
          println(
            "  |A|=" +
            ctx.num_axioms().to_string() +
            "，|S|=" +
            ctx.num_stmts().to_string() +
            "，|R|=" +
            ctx.edge_count().to_string(),
          )
          println("  " + @lattice.dg_stats_line(ctx))
          println("  " + @lattice.dg_report(ctx).render())
        }
      }
    }
  } else if cmd == "dgbasis" {
    if rest.length() < 1 {
      println(
        "用法：-- dgbasis <名稱>（列出 A3′ 典範基的每一條蘊含）",
      )
    } else {
      match @registry.lookup_dg(rest[0]) {
        None => println("找不到 A3′ 樣本：" + rest[0])
        Some(reg) => {
          let ctx = reg.ctx()
          let run = @lattice.canonical_basis_incremental(ctx)
          println(
            "上下文：" +
            reg.name() +
            "　|Σ|=" +
            run.basis().length().to_string(),
          )
          println(@lattice.render_basis(ctx, run.basis()))
        }
      }
    }
  } else if cmd == "mext" {
    if rest.length() < 1 {
      println(
        "用法：-- mext <名稱>（B0002 延伸：二元性、正則性、對偶、Tutte）",
      )
      println("樣本：" + @registry.all_matroid_names().join("、"))
    } else {
      match @registry.lookup_matroid_ext(rest[0]) {
        None => println("找不到擬陣：" + rest[0])
        Some(reg) => println(@registry.extension_summary(reg))
      }
    }
  } else if cmd == "modular" {
    let r = @modular.modular_report(6)
    println(
      "B0003 同餘子群檢核（T13、T14）：" +
      r.passed_count().to_string() +
      "/" +
      r.size().to_string() +
      " 通過",
    )
    println(r.render())
  } else if cmd == "elliptic" {
    let r = @elliptic.elliptic_report(12)
    println(
      "B0004 撓群 E[n] 檢核（T15–T21）：" +
      r.passed_count().to_string() +
      "/" +
      r.size().to_string() +
      " 通過",
    )
    println(r.render())
  } else if cmd == "eptable" {
    println(
      "E[n] 的結構表（n = 2..12）：|E[n]|、#階恰為 n、#循環子群、#有序基，並與 B0003 的同餘指數對照",
    )
    for n = 2; n <= 12; n = n + 1 {
      let pts = @elliptic.count_points_of_order(n)
      let lines = @elliptic.count_cyclic_subgroups(n)
      let bases = @elliptic.count_det_one_bases(n)
      let i1 = @modular.index_gamma1(n)
      let i0 = @modular.index_gamma0(n)
      let il = @modular.index_gamma_level(n)
      let ok = pts == i1 && lines == i0 && bases == il
      println(
        "  n=" +
        n.to_string() +
        "\t|E[n]|=" +
        (n * n).to_string() +
        "\t#階=n：" +
        pts.to_string() +
        "（Γ₁ 指數 " +
        i1.to_string() +
        "）\t#循環子群：" +
        lines.to_string() +
        "（Γ₀ 指數 " +
        i0.to_string() +
        "）\t#基：" +
        bases.to_string() +
        "（Γ 指數 " +
        il.to_string() +
        "）\t" +
        (if ok { "✓" } else { "✗" }),
      )
    }
  } else if cmd == "paley" {
    println(
      "Paley 圖／競賽（由 Weil 配對的二次特徵給出；T18、T19）",
    )
    for qi = 0; qi < 6; qi = qi + 1 {
      let qs : Array[Int32] = [5, 13, 17, 3, 7, 11]
      let q = qs[qi]
      let c = @elliptic.check_paley(q)
      println(
        "  q=" +
        q.to_string() +
        "：" +
        (if c.passed() { "✓ " } else { "✗ " }) +
        c.detail(),
      )
    }
    println("團複形同調（T21，GF(2)）")
    let qs2 : Array[Int32] = [5, 13, 17]
    for qi = 0; qi < 3; qi = qi + 1 {
      let q = qs2[qi]
      let c = @elliptic.check_flag_homology(q)
      println(
        "  q=" +
        q.to_string() +
        "：" +
        (if c.passed() { "✓ " } else { "✗ " }) +
        c.detail(),
      )
    }
  } else if cmd == "braid" {
    let r = @braid.braid_report()
    println(
      "B0005 辮群 B_n 檢核（T22–T24）：" +
      r.passed_count().to_string() +
      "/" +
      r.size().to_string() +
      " 通過",
    )
    println(r.render())
  } else if cmd == "jacobian" {
    let r = @jacobian.jacobian_report()
    println(
      "B0005 圖雅可比簇檢核（T25–T31）：" +
      r.passed_count().to_string() +
      "/" +
      r.size().to_string() +
      " 通過",
    )
    println(r.render())
  } else if cmd == "jtable" {
    println("圖雅可比簇 J(G) 的結構表（T25、T26）")
    let gs = @jacobian.sample_graphs()
    for i = 0; i < gs.length(); i = i + 1 {
      let (name, g) = gs[i]
      let fs = @jacobian.invariant_factors(@jacobian.laplacian(g))
      let sb = StringBuilder()
      for k = 0; k < fs.length(); k = k + 1 {
        if k > 0 {
          sb.write_char(',')
        }
        sb.write_string(fs[k].to_string())
      }
      println(
        "  " +
        name +
        "\t|V|=" +
        g.num_vertices().to_string() +
        " |E|=" +
        g.num_edges().to_string() +
        "\tg=" +
        g.cycle_rank().to_string() +
        "\t不變因子 [" +
        sb.to_string() +
        "]\t|J(G)|=" +
        @jacobian.jacobian_order(g).to_string() +
        "\tτ=" +
        @jacobian.spanning_trees_bruteforce(g).to_string(),
      )
    }
  } else if cmd == "arf" {
    println("theta 特徵與 Arf 不變量（T29）")
    for g = 1; g <= 3; g = g + 1 {
      let c = @jacobian.count_refinements(g)
      println("  g=" + g.to_string() + "：" + c.render())
    }
  } else if cmd == "paleyctx" {
    println(@registry.paley_summary())
  } else if cmd == "congruence" {
    println(@registry.congruence_summary())
  } else if cmd == "genus" {
    println(
      "X₀(N) 的解析不變量（N = 1..24；g = (12 + ψ − 3ν₂ − 4ν₃ − 6ν_∞)/12）",
    )
    for n = 1; n <= 24; n = n + 1 {
      let g = @modular.genus_x0(n)
      let c = @modular.classical_genus(n)
      let tag = match c {
        None => "（無外部期望值）"
        Some(want) =>
          if want == g {
            " ✓古典"
          } else {
            " ✗古典=" + want.to_string()
          }
      }
      println(
        "  N=" +
        n.to_string() +
        "	ψ=" +
        @modular.dedekind_psi(n).to_string() +
        "	φ=" +
        @modular.euler_phi(n).to_string() +
        "	ν₂=" +
        @modular.elliptic_two_count(n).to_string() +
        "	ν₃=" +
        @modular.elliptic_three_count(n).to_string() +
        "	ν_∞=" +
        @modular.cusp_count(n).to_string() +
        "	g=" +
        g.to_string() +
        tag,
      )
    }
  } else if cmd == "mreg" {
    let r = @registry.check_registered_expectations()
    println(
      "擬陣登記期望值核對：" +
      r.passed_count().to_string() +
      "/" +
      r.size().to_string() +
      " 通過",
    )
    println(r.render())
  } else if cmd == "mextall" {
    println(@registry.extension_global_summary())
  } else if cmd == "mcensus" {
    if rest.length() < 1 {
      println(
        "用法：-- mcensus <n>（n ≤ 5：兩條列舉路線的擬陣普查）",
      )
    } else {
      let n = census_arg(rest[0])
      match n {
        None => println("n 必須是 1..5 之間的整數")
        Some(k) => println(@registry.census_summary(k))
      }
    }
  } else if cmd == "negctl" {
    println(@registry.interval_summary(4))
  } else if cmd == "list" {
    show_list()
  } else if cmd == "all" {
    show_all()
  } else if cmd == "parse" {
    if rest.length() < 1 {
      println("用法：-- parse \"<文字格式上下文>\"")
    } else {
      show_parse(rest[0])
    }
  } else if cmd == "dump" {
    if rest.length() < 1 {
      println("用法：-- dump <上下文名稱>")
    } else {
      match @registry.lookup(rest[0]) {
        None => println("找不到上下文：" + rest[0])
        Some(reg) => println(dump_text(reg.ctx, reg.name))
      }
    }
  } else if cmd == "info" ||
    cmd == "concepts" ||
    cmd == "basis" ||
    cmd == "check" ||
    cmd == "closure" {
    if rest.length() < 1 {
      println("用法：-- " + cmd + " <上下文名稱> [公理名稱...]")
      return
    }
    match @registry.lookup(rest[0]) {
      None => {
        println("找不到上下文：" + rest[0] + "；可用：")
        show_list()
      }
      Some(reg) =>
        if cmd == "info" {
          show_summary(reg)
        } else if cmd == "concepts" {
          show_concepts(reg)
        } else if cmd == "basis" {
          show_basis(reg)
        } else if cmd == "check" {
          show_check(reg)
        } else {
          let names : Array[String] = []
          for i = 1; i < rest.length(); i = i + 1 {
            names.push(rest[i])
          }
          show_closure(reg, names)
        }
    }
  } else {
    println("未知指令：" + cmd)
    show_list()
  }
}
