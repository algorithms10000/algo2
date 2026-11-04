///|
/// B0001 / registry 套件：已登記的樣本上下文（公理系統）
///
/// 登記原則：每個上下文必須是**真實可計算的數學物件**，不得以人造資料冒充。
/// - `cyclotomic-q8`：ℚ(ζ₈)/ℚ 的伽羅瓦對應（R 由群作用計算，見 cyclotomic.mbt）。
/// - `divisibility`：ℤ 上的整除格（a | s），古典伽羅瓦對應（公倍數 ↔ 公因數）。
/// - `two-blocks`：兩個不交分量的合成上下文，用來實際驗證 T3 的跨分支坍縮。

///|
pub struct Registered {
  name : String
  ctx : @context.FormalContext
  source : String
}

///|
/// 建構登記項（供 CLI 解析外部上下文後包裝使用）。
pub fn Registered::make(
  name : String,
  ctx : @context.FormalContext,
  source : String,
) -> Registered {
  { name, ctx, source, }
}

///|
pub fn Registered::name(self : Registered) -> String {
  self.name
}

///|
pub fn Registered::ctx(self : Registered) -> @context.FormalContext {
  self.ctx
}

///|
pub fn Registered::source(self : Registered) -> String {
  self.source
}

///|
/// 整除格：A = {2,3,4,6}（公理），S = {4,6,12,18}（陳述），(a,s) ∈ R ⟺ a | s。
pub fn divisibility_context() -> @context.FormalContext {
  let axiom_names : Array[String] = ["2", "3", "4", "6"]
  let axiom_values : Array[Int32] = [2, 3, 4, 6]
  let stmt_names : Array[String] = ["4", "6", "12", "18"]
  let stmt_values : Array[Int32] = [4, 6, 12, 18]
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < axiom_values.length(); i = i + 1 {
    for j = 0; j < stmt_values.length(); j = j + 1 {
      if stmt_values[j] % axiom_values[i] == 0 {
        edges.push((i, j))
      }
    }
  }
  @context.FormalContext::new(axiom_names, stmt_names, edges)
}

///|
/// 兩個不交分量：A = {a1,a2,a3,a4}，S = {s1..s6}；
/// 分量一 = {a1,a2} × {s1,s2,s3}，分量二 = {a3,a4} × {s4,s5,s6}。
pub fn two_blocks_context() -> @context.FormalContext {
  let axiom_names : Array[String] = ["a1", "a2", "a3", "a4"]
  let stmt_names : Array[String] = ["s1", "s2", "s3", "s4", "s5", "s6"]
  let pairs : Array[(String, String)] = [
    ("a1", "s1"),
    ("a1", "s2"),
    ("a2", "s2"),
    ("a2", "s3"),
    ("a3", "s4"),
    ("a3", "s5"),
    ("a4", "s5"),
    ("a4", "s6"),
  ]
  let edges : Array[(Int32, Int32)] = []
  for k = 0; k < pairs.length(); k = k + 1 {
    let (an, sn) = pairs[k]
    let mut ai = -1
    for i = 0; i < axiom_names.length(); i = i + 1 {
      if axiom_names[i] == an {
        ai = i
      }
    }
    let mut si = -1
    for j = 0; j < stmt_names.length(); j = j + 1 {
      if stmt_names[j] == sn {
        si = j
      }
    }
    if ai < 0 || si < 0 {
      abort("two_blocks_context 邊表引用未宣告名稱")
    }
    edges.push((ai, si))
  }
  @context.FormalContext::new(axiom_names, stmt_names, edges)
}

///|
/// 全部登記上下文（具決定性次序）。
pub fn registered() -> Array[Registered] {
  [
    {
      name: "cyclotomic-q8",
      ctx: cyclotomic_context(),
      source: "ℚ(ζ₈)/ℚ：伽羅瓦群 C₂×C₂ 的子群 ↔ 中間體；R 由群作用對基底 {1,i,√2,i√2} 的符號表計算",
    },
    {
      name: "divisibility",
      ctx: divisibility_context(),
      source: "ℤ 的整除格：A={2,3,4,6}，S={4,6,12,18}，a|s；公倍數 ↔ 公因數的伽羅瓦對應",
    },
    {
      name: "two-blocks",
      ctx: two_blocks_context(),
      source: "兩個不交分量的合成上下文：A={a1..a4}，S={s1..s6}，用於驗證 T3 的局部性與跨分支坍縮",
    },
  ]
}

///|
/// 依名稱查詢。
pub fn lookup(name : String) -> Registered? {
  let all = registered()
  for i = 0; i < all.length(); i = i + 1 {
    if all[i].name == name {
      return Some(all[i])
    }
  }
  None
}

///|
/// 登記名稱清單（CLI 用）。
pub fn registered_names() -> Array[String] {
  let out : Array[String] = []
  let all = registered()
  for i = 0; i < all.length(); i = i + 1 {
    out.push(all[i].name)
  }
  out
}

///|
/// 【A3′ 用】除數上下文：A = S = N 的全部正因數，R = {(a,s) : a | s}。
/// 這是「整除格」的古典伽羅瓦對應，閉集 = 某因數的全體倍數 ⇒ |ℭ| = d(N)（可獨立核對）。
pub fn divisor_context(value : Int32) -> @context.FormalContext {
  let vals : Array[Int32] = []
  for d = 1; d <= value; d = d + 1 {
    if value % d == 0 {
      vals.push(d)
    }
  }
  let axiom_names : Array[String] = []
  let stmt_names : Array[String] = []
  for i = 0; i < vals.length(); i = i + 1 {
    axiom_names.push(vals[i].to_string())
    stmt_names.push(vals[i].to_string())
  }
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < vals.length(); i = i + 1 {
    for j = 0; j < vals.length(); j = j + 1 {
      if vals[j] % vals[i] == 0 {
        edges.push((i, j))
      }
    }
  }
  @context.FormalContext::new(axiom_names, stmt_names, edges)
}

///|
/// 【A3′ 用】大屬性集的除數上下文族（n = d(N)：12→6、180→18、240→20、420→24）。
/// 與 `registered()` 分開，因為這些樣本只跑 A3′/T4（不含 A6 的窮舉檢核預算）。
pub fn registered_dg() -> Array[Registered] {
  [
    {
      name: "divisors-12",
      ctx: divisor_context(12),
      source: "整除上下文：A=S=12 的因數 {1,2,3,4,6,12}，|ℭ|=d(12)=6；A3′ 與暴力 A3 交叉核對用",
    },
    {
      name: "divisors-180",
      ctx: divisor_context(180),
      source: "整除上下文：d(180)=18 個因數；A3′ 與暴力 A3 交叉核對用（2^18 仍可暴力）",
    },
    {
      name: "divisors-240",
      ctx: divisor_context(240),
      source: "整除上下文：d(240)=20 個因數；暴力 A3 的最後一個可負擔點（2^20−1 = 1,048,575）",
    },
    {
      name: "divisors-420",
      ctx: divisor_context(420),
      source: "整除上下文：d(420)=24 個因數；暴力 A3 需 16,777,215 次候選判定，只有 A3′ 可算",
    },
  ]
}

///|
/// 【A3′ 用】在 `registered_dg()` 中查找。
pub fn lookup_dg(name : String) -> Registered? {
  let all = registered_dg()
  for i = 0; i < all.length(); i = i + 1 {
    if all[i].name == name {
      return Some(all[i])
    }
  }
  None
}

///|
/// 【A3′ 用】`registered_dg()` 的名稱表。
pub fn registered_dg_names() -> Array[String] {
  let out : Array[String] = []
  let all = registered_dg()
  for i = 0; i < all.length(); i = i + 1 {
    out.push(all[i].name)
  }
  out
}
