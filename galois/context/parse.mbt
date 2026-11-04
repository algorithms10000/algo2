///|
/// B0001 / context 套件：上下文文字格式的解析器（接入接口）
///
/// 格式（每行一條指令，`#` 開頭為註解，空白行忽略）：
/// ```
/// context <名稱>
/// axiom   <公理名稱>
/// stmt    <陳述名稱>
/// edge    <公理名稱> <陳述名稱>
/// edges   <公理名稱> <陳述名稱> <陳述名稱> ...
/// ```
/// 公理／陳述必須先以 axiom/stmt 宣告再使用；重複宣告視為同一物件（不報錯）。

///|
/// 解析錯誤。
pub suberror ParseError {
  ParseAt(Int32, String)
  UndefinedNameAt(Int32, String)
  BadArity(Int32, String)
}

///|
pub fn ParseError::message(self : ParseError) -> String {
  match self {
    ParseAt(line, why) => "第 " + line.to_string() + " 行：" + why
    UndefinedNameAt(line, name) =>
      "第 " + line.to_string() + " 行：未宣告的名稱 " + name
    BadArity(line, what) =>
      "第 " + line.to_string() + " 行：參數個數不符（" + what + "）"
  }
}

///|
/// 解析結果。
pub struct ParsedContext {
  name : String
  ctx : FormalContext
}

///|
pub fn ParsedContext::name(self : ParsedContext) -> String {
  self.name
}

///|
pub fn ParsedContext::ctx(self : ParsedContext) -> FormalContext {
  self.ctx
}

///|
/// 以空白（空格／定位鍵）切分為 token。
fn split_tokens(line : String) -> Array[String] {
  let out : Array[String] = []
  let sb = StringBuilder()
  for c in line {
    if c == ' ' || c == '\t' || c == '\r' {
      if !sb.is_empty() {
        out.push(sb.to_string())
        sb.reset()
      }
    } else {
      sb.write_char(c)
    }
  }
  if !sb.is_empty() {
    out.push(sb.to_string())
  }
  out
}

///|
/// 解析上下文文字。時間 O(行數 × token 數 + 邊數)。
pub fn parse_context(text : String) -> ParsedContext raise ParseError {
  let axiom_names : Array[String] = []
  let stmt_names : Array[String] = []
  let edge_axioms : Array[Int32] = []
  let edge_stmts : Array[Int32] = []
  let mut ctx_name = "unnamed"
  let mut line_no = 0
  for raw_line in text.split("\n") {
    line_no = line_no + 1
    let line = raw_line.trim().to_owned()
    if line.length() == 0 {
      continue
    }
    let mut is_comment = false
    match line.get_char(0) {
      Some('#') => is_comment = true
      _ => ()
    }
    if is_comment {
      continue
    }
    let tok = split_tokens(line)
    if tok.length() == 0 {
      continue
    }
    let head = tok[0]
    if head == "context" {
      if tok.length() != 2 {
        raise BadArity(line_no, "context 需 1 個名稱")
      }
      ctx_name = tok[1]
    } else if head == "axiom" {
      if tok.length() != 2 {
        raise BadArity(line_no, "axiom 需 1 個名稱")
      }
      let mut exists = false
      for i = 0; i < axiom_names.length(); i = i + 1 {
        if axiom_names[i] == tok[1] {
          exists = true
        }
      }
      if !exists {
        axiom_names.push(tok[1])
      }
    } else if head == "stmt" {
      if tok.length() != 2 {
        raise BadArity(line_no, "stmt 需 1 個名稱")
      }
      let mut exists = false
      for i = 0; i < stmt_names.length(); i = i + 1 {
        if stmt_names[i] == tok[1] {
          exists = true
        }
      }
      if !exists {
        stmt_names.push(tok[1])
      }
    } else if head == "edge" || head == "edges" {
      if head == "edge" && tok.length() != 3 {
        raise BadArity(line_no, "edge 需 2 個名稱")
      }
      if head == "edges" && tok.length() < 3 {
        raise BadArity(line_no, "edges 需 ≥ 2 個名稱")
      }
      let mut a_idx = -1
      for i = 0; i < axiom_names.length(); i = i + 1 {
        if axiom_names[i] == tok[1] {
          a_idx = i
        }
      }
      if a_idx < 0 {
        raise UndefinedNameAt(line_no, tok[1])
      }
      for k = 2; k < tok.length(); k = k + 1 {
        let mut s_idx = -1
        for j = 0; j < stmt_names.length(); j = j + 1 {
          if stmt_names[j] == tok[k] {
            s_idx = j
          }
        }
        if s_idx < 0 {
          raise UndefinedNameAt(line_no, tok[k])
        }
        edge_axioms.push(a_idx)
        edge_stmts.push(s_idx)
      }
    } else {
      raise ParseAt(line_no, "未知指令 " + head)
    }
  }
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < edge_axioms.length(); i = i + 1 {
    edges.push((edge_axioms[i], edge_stmts[i]))
  }
  { name: ctx_name, ctx: FormalContext::new(axiom_names, stmt_names, edges), }
}
