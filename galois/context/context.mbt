///|
/// B0001 / context 套件：形式上下文 K = (A, S, R)
/// 對應 docs/B0001-定理體系.md 的 D1（形式上下文）、D2（Φ）、D3（Ψ）、X4（分量）。
/// 資料結構：rows[a] = row(a) ⊆ S、cols[s] = col(s) ⊆ A，皆為稠密位元集。

///|
/// 派生關係的建構錯誤。
pub suberror ContextError {
  UnknownAxiom(String)
  UnknownStatement(String)
}

///|
/// 錯誤訊息（人讀）。
pub fn ContextError::message(self : ContextError) -> String {
  match self {
    UnknownAxiom(name) => "公理未登記：" + name
    UnknownStatement(name) => "陳述未登記：" + name
  }
}

///|
pub struct FormalContext {
  axiom_names : Array[String]
  stmt_names : Array[String]
  rows : Array[@bitset.BitSet]
  cols : Array[@bitset.BitSet]
  edge_count : Int32
}

///|
/// 由名稱表與邊表建構上下文。邊以 (公理索引, 陳述索引) 給出。
pub fn FormalContext::new(
  axiom_names : Array[String],
  stmt_names : Array[String],
  edges : Array[(Int32, Int32)],
) -> FormalContext {
  let m = axiom_names.length()
  let n = stmt_names.length()
  let rows : Array[@bitset.BitSet] = []
  for j = 0; j < m; j = j + 1 {
    rows.push(@bitset.BitSet::new(n))
  }
  let cols : Array[@bitset.BitSet] = []
  for j = 0; j < n; j = j + 1 {
    cols.push(@bitset.BitSet::new(m))
  }
  for i = 0; i < edges.length(); i = i + 1 {
    let (a, s) = edges[i]
    if a < 0 || a >= m || s < 0 || s >= n {
      abort("FormalContext::new 邊索引越界")
    }
    rows[a].set(s)
    cols[s].set(a)
  }
  { axiom_names, stmt_names, rows, cols, edge_count: edges.length(), }
}

///|
pub fn FormalContext::num_axioms(self : FormalContext) -> Int32 {
  self.axiom_names.length()
}

///|
pub fn FormalContext::num_stmts(self : FormalContext) -> Int32 {
  self.stmt_names.length()
}

///|
pub fn FormalContext::edge_count(self : FormalContext) -> Int32 {
  self.edge_count
}

///|
pub fn FormalContext::axiom_name(self : FormalContext, i : Int32) -> String {
  self.axiom_names[i]
}

///|
pub fn FormalContext::stmt_name(self : FormalContext, i : Int32) -> String {
  self.stmt_names[i]
}

///|
pub fn FormalContext::axiom_index(
  self : FormalContext,
  name : String,
) -> Int32? {
  for i = 0; i < self.axiom_names.length(); i = i + 1 {
    if self.axiom_names[i] == name {
      return Some(i)
    }
  }
  None
}

///|
pub fn FormalContext::stmt_index(self : FormalContext, name : String) -> Int32? {
  for i = 0; i < self.stmt_names.length(); i = i + 1 {
    if self.stmt_names[i] == name {
      return Some(i)
    }
  }
  None
}

///|
/// D2：內涵映射 Φ(X) = ⋂_{a∈X} row(a)，Φ(∅) = S。
/// 以位元交集鏈實作：O(|X|·⌈n/64⌉)。
pub fn FormalContext::intent(
  self : FormalContext,
  extent : @bitset.BitSet,
) -> @bitset.BitSet {
  if extent.size() != self.num_axioms() {
    abort("FormalContext::intent 位元長度與 A 不符")
  }
  let mut acc = @bitset.BitSet::full(self.num_stmts())
  for a = 0; a < self.num_axioms(); a = a + 1 {
    if extent.get(a) {
      acc = acc.intersect(self.rows[a])
      if acc.is_empty() {
        return acc
      }
    }
  }
  acc
}

///|
/// D3：外延映射 Ψ(Y) = ⋂_{s∈Y} col(s)，Ψ(∅) = A。
pub fn FormalContext::extent(
  self : FormalContext,
  intent : @bitset.BitSet,
) -> @bitset.BitSet {
  if intent.size() != self.num_stmts() {
    abort("FormalContext::extent 位元長度與 S 不符")
  }
  let mut acc = @bitset.BitSet::full(self.num_axioms())
  for s = 0; s < self.num_stmts(); s = s + 1 {
    if intent.get(s) {
      acc = acc.intersect(self.cols[s])
      if acc.is_empty() {
        return acc
      }
    }
  }
  acc
}

///|
/// 公理子集的空集合物件（輔助建構子）。
pub fn FormalContext::axiom_set(
  self : FormalContext,
  ids : Array[Int32],
) -> @bitset.BitSet {
  @bitset.BitSet::from_indices(self.num_axioms(), ids)
}

///|
/// 陳述子集的空集合物件（輔助建構子）。
pub fn FormalContext::stmt_set(
  self : FormalContext,
  ids : Array[Int32],
) -> @bitset.BitSet {
  @bitset.BitSet::from_indices(self.num_stmts(), ids)
}

///|
/// 以名稱為公理集合。
pub fn FormalContext::axioms_named(
  self : FormalContext,
  names : Array[String],
) -> @bitset.BitSet raise ContextError {
  let ids : Array[Int32] = []
  for i = 0; i < names.length(); i = i + 1 {
    match self.axiom_index(names[i]) {
      Some(k) => ids.push(k)
      None => raise UnknownAxiom(names[i])
    }
  }
  self.axiom_set(ids)
}

///|
/// 以名稱為陳述集合。
pub fn FormalContext::stmts_named(
  self : FormalContext,
  names : Array[String],
) -> @bitset.BitSet raise ContextError {
  let ids : Array[Int32] = []
  for i = 0; i < names.length(); i = i + 1 {
    match self.stmt_index(names[i]) {
      Some(k) => ids.push(k)
      None => raise UnknownStatement(names[i])
    }
  }
  self.stmt_set(ids)
}

///|
/// 將 A 側位元集渲染為名稱。
pub fn FormalContext::render_axioms(
  self : FormalContext,
  s : @bitset.BitSet,
) -> String {
  let sb = StringBuilder()
  sb.write_string("{")
  let ids = s.ones()
  for i = 0; i < ids.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    sb.write_string(self.axiom_names[ids[i]])
  }
  sb.write_string("}")
  sb.to_string()
}

///|
/// 將 S 側位元集渲染為名稱。
pub fn FormalContext::render_stmts(
  self : FormalContext,
  s : @bitset.BitSet,
) -> String {
  let sb = StringBuilder()
  sb.write_string("{")
  let ids = s.ones()
  for i = 0; i < ids.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(", ")
    }
    sb.write_string(self.stmt_names[ids[i]])
  }
  sb.write_string("}")
  sb.to_string()
}
