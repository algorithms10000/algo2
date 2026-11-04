///|
/// B0001 / context 套件：分量分解（X4、T3、A4）
/// 關聯二分圖 Γ(K) = (A ⊎ S, R) 的連通分量以並查集（DSU，路徑壓縮 + 按大小合併）求得。
/// 節點編號：0..m-1 為公理，m..m+n-1 為陳述。

///|
/// 一個連通分量：其公理側與陳述側索引。
pub struct Component {
  id : Int32
  axioms : Array[Int32]
  stmts : Array[Int32]
}

///|
/// 並查集（disjoint-set union）。
priv struct Dsu {
  parent : Array[Int32]
  size : Array[Int32]
}

///|
fn Dsu::new(n : Int32) -> Dsu {
  let parent : Array[Int32] = []
  let size : Array[Int32] = []
  for i = 0; i < n; i = i + 1 {
    parent.push(i)
    size.push(1)
  }
  { parent, size, }
}

///|
fn Dsu::find(self : Dsu, x : Int32) -> Int32 {
  let mut root = x
  while self.parent[root] != root {
    root = self.parent[root]
  }
  let mut cur = x
  while self.parent[cur] != root {
    let next = self.parent[cur]
    self.parent[cur] = root
    cur = next
  }
  root
}

///|
fn Dsu::union(self : Dsu, a : Int32, b : Int32) -> Unit {
  let ra = self.find(a)
  let rb = self.find(b)
  if ra == rb {
    return
  }
  let sa = self.size[ra]
  let sb = self.size[rb]
  if sa < sb {
    self.parent[ra] = rb
    self.size[rb] = sa + sb
  } else {
    self.parent[rb] = ra
    self.size[ra] = sa + sb
  }
}

///|
/// 將 DSU 的等價類整理為分量清單（依最小節點索引排序，結果具決定性）。
fn dsu_components(dsu : Dsu, m : Int32, n : Int32) -> Array[Component] {
  let total = m + n
  let root_to_id : Array[Int32] = []
  for i = 0; i < total; i = i + 1 {
    root_to_id.push(-1)
  }
  let order : Array[Int32] = []
  for i = 0; i < total; i = i + 1 {
    let r = dsu.find(i)
    if root_to_id[r] == -1 {
      root_to_id[r] = order.length()
      order.push(r)
    }
  }
  let out : Array[Component] = []
  for id = 0; id < order.length(); id = id + 1 {
    let axioms : Array[Int32] = []
    let stmts : Array[Int32] = []
    for i = 0; i < m; i = i + 1 {
      if dsu.find(i) == order[id] {
        axioms.push(i)
      }
    }
    for j = 0; j < n; j = j + 1 {
      if dsu.find(m + j) == order[id] {
        stmts.push(j)
      }
    }
    out.push({ id, axioms, stmts, })
  }
  out
}

///|
/// A4：Γ(K) 的連通分量清單。
pub fn components_of(ctx : FormalContext) -> Array[Component] {
  let m = ctx.num_axioms()
  let n = ctx.num_stmts()
  let dsu = Dsu::new(m + n)
  for a = 0; a < m; a = a + 1 {
    let row = ctx.rows[a]
    let ids = row.ones()
    for k = 0; k < ids.length(); k = k + 1 {
      dsu.union(a, m + ids[k])
    }
  }
  dsu_components(dsu, m, n)
}

///|
/// 每條公理所屬的分量編號（長度 m）。
pub fn component_id_of_axiom(ctx : FormalContext) -> Array[Int32] {
  let m = ctx.num_axioms()
  let id_of : Array[Int32] = []
  for i = 0; i < m; i = i + 1 {
    id_of.push(-1)
  }
  let comps = components_of(ctx)
  for c = 0; c < comps.length(); c = c + 1 {
    let ax = comps[c].axioms
    for k = 0; k < ax.length(); k = k + 1 {
      id_of[ax[k]] = comps[c].id
    }
  }
  id_of
}

///|
/// 每個陳述所屬的分量編號（長度 n）。
pub fn component_id_of_stmt(ctx : FormalContext) -> Array[Int32] {
  let n = ctx.num_stmts()
  let id_of : Array[Int32] = []
  for j = 0; j < n; j = j + 1 {
    id_of.push(-1)
  }
  let comps = components_of(ctx)
  for c = 0; c < comps.length(); c = c + 1 {
    let st = comps[c].stmts
    for k = 0; k < st.length(); k = k + 1 {
      id_of[st[k]] = comps[c].id
    }
  }
  id_of
}

///|
/// 由某個分量切出子上下文 K_C = (A_C, S_C, R|_{A_C×S_C})（索引重新編號，名稱保留）。
pub fn sub_context(ctx : FormalContext, comp : Component) -> FormalContext {
  let ax = comp.axioms
  let st = comp.stmts
  let axiom_names : Array[String] = []
  for i = 0; i < ax.length(); i = i + 1 {
    axiom_names.push(ctx.axiom_names[ax[i]])
  }
  let stmt_names : Array[String] = []
  for j = 0; j < st.length(); j = j + 1 {
    stmt_names.push(ctx.stmt_names[st[j]])
  }
  let edges : Array[(Int32, Int32)] = []
  for i = 0; i < ax.length(); i = i + 1 {
    let row = ctx.rows[ax[i]]
    for j = 0; j < st.length(); j = j + 1 {
      if row.get(st[j]) {
        edges.push((i, j))
      }
    }
  }
  FormalContext::new(axiom_names, stmt_names, edges)
}
