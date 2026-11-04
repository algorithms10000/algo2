///|
/// B0002 / registry 套件：擬陣樣本登記（全部為真數學物件）與摘要
///
/// - `U(2,4)`：均勻擬陣（非二元），以迴路直接給出：𝒞 = 所有 3-子集。
/// - `M(K3)`、`M(K4)`：圖擬陣，由 GF(2) 關聯矩陣算出迴路（三角形、4-環）。
///   平坦集個數 = 頂點集的分割數 = Bell 數：B₃ = 5、B₄ = 15（E-B8 的可執行見證）。
/// - `Fano`：PG(2,2)，由 F₂³ 的 7 個非零向量算出 7 條線（迴路），平坦集 16 個（E-B9）。
/// - `interval-4`：負控制（非擬陣），`check_exchange` 必須 FAIL（T8）。

///|
pub struct RegisteredMatroid {
  name : String
  matroid : @matroid.Matroid
  source : String
  expected_flats : Int32
  expected_circuits : Int32
}

///|
pub fn RegisteredMatroid::name(self : RegisteredMatroid) -> String {
  self.name
}

///|
pub fn RegisteredMatroid::matroid(self : RegisteredMatroid) -> @matroid.Matroid {
  self.matroid
}

///|
pub fn RegisteredMatroid::source(self : RegisteredMatroid) -> String {
  self.source
}

///|
/// 通過標記。
fn mark(ok : Bool) -> String {
  if ok {
    " ✓"
  } else {
    " ✗"
  }
}

///|
/// 名稱 → 頂點／邊，方便閱讀：K3、K4 的圖擬陣。
fn k3_edges() -> Array[(Int32, Int32)] {
  [(0, 1), (1, 2), (0, 2)]
}

///|
fn k4_edges() -> Array[(Int32, Int32)] {
  [(0, 1), (0, 2), (0, 3), (1, 2), (1, 3), (2, 3)]
}

///|
/// 全部擬陣樣本（具決定性次序）。
pub fn registered_matroids() -> Array[RegisteredMatroid] {
  [
    {
      name: "U24",
      matroid: @matroid.Matroid::uniform(2, 4),
      source: "均勻擬陣 U(2,4)：迴路 = 所有 3-子集（非二元擬陣）",
      expected_flats: 6,
      expected_circuits: 4,
    },
    {
      name: "M(K3)",
      matroid: @matroid.Matroid::graphic("M(K3)", 3, k3_edges()),
      source: "三角形圖擬陣：GF(2) 關聯矩陣 3 邊 × 3 頂點；平坦集 = 頂點分割數 = Bell(3)",
      expected_flats: 5,
      expected_circuits: 1,
    },
    {
      name: "M(K4)",
      matroid: @matroid.Matroid::graphic("M(K4)", 4, k4_edges()),
      source: "K₄ 圖擬陣：6 邊；迴路 = 4 個三角形 + 3 個四環 = 7；平坦集 = 頂點分割數 = Bell(4)",
      expected_flats: 15,
      expected_circuits: 7,
    },
    {
      name: "Fano",
      matroid: @matroid.Matroid::fano(),
      source: "Fano 擬陣 = PG(2,2)：F₂³ 的 7 個非零向量；迴路 = 7 條線 + 7 個線補集 = 14；平坦集 16",
      expected_flats: 16,
      expected_circuits: 14,
    },
  ]
}

///|
pub fn lookup_matroid(name : String) -> RegisteredMatroid? {
  let all = registered_matroids()
  for i = 0; i < all.length(); i = i + 1 {
    if all[i].name == name {
      return Some(all[i])
    }
  }
  None
}

///|
pub fn registered_matroid_names() -> Array[String] {
  let out : Array[String] = []
  let all = registered_matroids()
  for i = 0; i < all.length(); i = i + 1 {
    out.push(all[i].name)
  }
  out.push("interval-4")
  out
}

///|
/// 擬陣摘要（CLI 的 `matroid <名稱>` 輸出）：全部量都是算出來的，並與登記的期望值比對。
pub fn matroid_summary(reg : RegisteredMatroid, inherit_b0001 : Bool) -> String {
  let m = reg.matroid
  let sb = StringBuilder()
  sb.write_string("擬陣：" + reg.name + "（" + m.name() + "）\n")
  sb.write_string("  來源：" + reg.source + "\n")
  let flats = m.flats()
  let r_top = m.rank(@bitset.BitSet::full(m.ground_size()))
  sb.write_string(
    "  |E|=" +
    m.ground_size().to_string() +
    "，|𝒞|=" +
    m.circuit_count().to_string() +
    "，r(E)=" +
    r_top.to_string() +
    "，|ℱ|=" +
    flats.length().to_string() +
    "\n",
  )
  let flat_ok = flats.length() == reg.expected_flats
  let circ_ok = m.circuit_count() == reg.expected_circuits
  sb.write_string(
    "  期望值核對：|ℱ|=" +
    reg.expected_flats.to_string() +
    mark(flat_ok) +
    "，|𝒞|=" +
    reg.expected_circuits.to_string() +
    mark(circ_ok) +
    "\n",
  )
  let report = m.matroid_report()
  sb.write_string(
    "  擬陣檢核（A12）：" +
    report.passed_count().to_string() +
    "/" +
    report.size().to_string() +
    " 通過\n",
  )
  sb.write_string(report.render())
  if inherit_b0001 {
    let inherited = m.check_b0001_inheritance()
    sb.write_string(
      "  B0001 繼承檢核（K_ℱ 上的 A6）：" +
      inherited.passed_count().to_string() +
      "/" +
      inherited.size().to_string() +
      " 通過\n",
    )
    sb.write_string(inherited.render())
  }
  sb.to_string()
}

///|
/// 負控制摘要：必須出現 FAIL（交換公理），否則視為檢核器失效。
pub fn interval_summary(n : Int32) -> String {
  let sb = StringBuilder()
  sb.write_string(
    "負控制：區間凸包（antimatroid，非擬陣），n=" +
    n.to_string() +
    "\n",
  )
  let report = @matroid.interval_report(n)
  let failed = report.passed_count() < report.size()
  let verdict = if failed {
    "FAIL（正確：非擬陣）\n"
  } else {
    "PASS（錯誤：檢核器失效！）\n"
  }
  sb.write_string("  check_exchange 結果：" + verdict)
  sb.write_string(report.render())
  sb.to_string()
}
