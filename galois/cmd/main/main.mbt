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
