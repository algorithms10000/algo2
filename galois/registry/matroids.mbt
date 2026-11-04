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

///|
/// 【B0002 延伸】額外樣本：對偶與非圖擬陣，用於 T9/T10/T12。
/// - `Fano*`：Fano 的對偶（也是二元、非正則）。
/// - `U(3,5)`：均勻擬陣 U(3,5)（二元？由判準決定，不預設答案）。
/// - `M(K4)*`：K₄ 的餘圖擬陣（正則，且 T_{M*}(x,y) = T_M(y,x)）。
pub fn registered_matroids_ext() -> Array[RegisteredMatroid] {
  [
    {
      name: "Fano*",
      matroid: @matroid.Matroid::fano().dual(),
      source: "F7* = Fano 的對偶；二元但非正則；迴路 = 超平面（7 條線）的補集 = 7 個 4-子集（T10 判準）；平坦數無獨立公式",
      expected_flats: -1,
      expected_circuits: 7,
    },
    {
      name: "U(3,5)",
      matroid: @matroid.Matroid::uniform(3, 5),
      source: "均勻擬陣 U(3,5)：𝒞 = 所有 4-子集；|ℱ| = 2 + C(5,1) + C(5,2) = 17（T11）",
      expected_flats: 17,
      expected_circuits: 5,
    },
    {
      name: "M(K4)*",
      matroid: @matroid.Matroid::graphic("M(K4)", 4, k4_edges()).dual(),
      source: "餘圖擬陣 M(K4)*：6 元素、秩 3；正則；|ℱ(M*)|=|ℱ(M)|=15，迴路 = K₄ 的 7 個割（bond）",
      expected_flats: 15,
      expected_circuits: 7,
    },
  ]
}

///|
/// 【B0002 延伸】查找（先查基本樣本，再查延伸樣本）。
pub fn lookup_matroid_ext(name : String) -> RegisteredMatroid? {
  match lookup_matroid(name) {
    Some(reg) => Some(reg)
    None => {
      let all = registered_matroids_ext()
      let mut hit : RegisteredMatroid? = None
      for i = 0; i < all.length(); i = i + 1 {
        if all[i].name == name {
          hit = Some(all[i])
        }
      }
      hit
    }
  }
}

///|
/// 【B0002 延伸】全部樣本名稱（含延伸）。
pub fn all_matroid_names() -> Array[String] {
  let out = registered_matroid_names()
  let ext = registered_matroids_ext()
  for i = 0; i < ext.length(); i = i + 1 {
    out.push(ext[i].name)
  }
  out
}

///|
/// 【B0002 延伸】T9/T10/T12 摘要：二元性、正則性、對偶秩、Tutte 多項式、特徵多項式。
pub fn extension_summary(reg : RegisteredMatroid) -> String {
  let m = reg.matroid
  let sb = StringBuilder()
  sb.write_string("擬陣：" + reg.name + "（" + m.name() + "）\n")
  sb.write_string("  來源：" + reg.source + "\n")
  sb.write_string(
    "  |E|=" +
    m.ground_size().to_string() +
    "，r(E)=" +
    m.rank(@bitset.BitSet::full(m.ground_size())).to_string() +
    "，|𝒞|=" +
    m.circuit_count().to_string() +
    "，|ℱ|=" +
    m.flat_count().to_string() +
    "\n",
  )
  let binary = m.is_binary()
  let regular = m.is_regular()
  sb.write_string(
    "  二元=" +
    binary.to_string() +
    "（禁 minor：無 U(2,4)）　正則=" +
    regular.to_string() +
    "（禁 minor：U(2,4)/F7/F7*）\n",
  )
  sb.write_string("  Tutte：T(x,y) = " + m.tutte().render() + "\n")
  sb.write_string(
    "  特徵：χ(λ) = " + m.characteristic_definition().render() + "\n",
  )
  let ring = @matroid.extension_report(m)
  sb.write_string(
    "  延伸檢核（T9–T12）：" +
    ring.passed_count().to_string() +
    "/" +
    ring.size().to_string() +
    " 通過\n",
  )
  sb.write_string(ring.render())
  sb.to_string()
}

///|
/// 【B0002 延伸】小型擬陣普查（兩條列舉路線必須一致）。
pub fn census_summary(n : Int32) -> String {
  let by_circuits = @matroid.all_matroids_by_circuits(n)
  let by_indep = @matroid.all_matroids_by_independent_sets(n)
  let reps = @matroid.isomorphism_classes(by_circuits)
  let sb = StringBuilder()
  sb.write_string("普查：n = " + n.to_string() + "\n")
  sb.write_string(
    "  迴路系統路線（C1–C3）：" +
    by_circuits.length().to_string() +
    " 個擬陣\n",
  )
  sb.write_string(
    "  獨立集路線（I1–I3）：" +
    by_indep.length().to_string() +
    " 個擬陣\n",
  )
  let same = by_circuits.length() == by_indep.length()
  sb.write_string(
    "  兩條路線一致：" +
    (if same { "✓" } else { "✗（T5 的計算版被違反）" }) +
    "\n",
  )
  sb.write_string("  同構類數：" + reps.length().to_string() + "\n")
  let mut nonbin = 0
  let mut nonreg = 0
  for i = 0; i < by_circuits.length(); i = i + 1 {
    if !by_circuits[i].is_binary() {
      nonbin = nonbin + 1
    }
    if !by_circuits[i].is_regular() {
      nonreg = nonreg + 1
    }
  }
  let mut nonbin_reps = 0
  let mut nonreg_reps = 0
  for i = 0; i < reps.length(); i = i + 1 {
    if !reps[i].is_binary() {
      nonbin_reps = nonbin_reps + 1
    }
    if !reps[i].is_regular() {
      nonreg_reps = nonreg_reps + 1
    }
  }
  sb.write_string(
    "  非二元：" +
    nonbin.to_string() +
    "（同構類 " +
    nonbin_reps.to_string() +
    "）\n",
  )
  sb.write_string(
    "  非正則：" +
    nonreg.to_string() +
    "（同構類 " +
    nonreg_reps.to_string() +
    "）\n",
  )
  sb.to_string()
}

///|
/// 【B0002 延伸】全域報告：與樣本無關、但屬於 T9–T12 的定理級檢核。
pub fn extension_global_report() -> @galois.Report {
  let r = @galois.Report::new()
  r.add(@matroid.check_fano_binary_not_regular())
  r.add(@matroid.check_fano_characteristic())
  r.add(@matroid.check_self_dual_k4())
  r.add(@matroid.check_graphic_regular("M(K3)", 3, k3_edges()))
  r.add(@matroid.check_graphic_regular("M(K4)", 4, k4_edges()))
  r.add(@matroid.check_uniform_flats(1, 2))
  r.add(@matroid.check_uniform_flats(2, 4))
  r.add(@matroid.check_uniform_flats(3, 5))
  r.add(@matroid.check_uniform_flats(2, 6))
  r.add(@matroid.check_uniform_dual(2, 4))
  r.add(@matroid.check_uniform_dual(3, 5))
  r.add(@matroid.check_chromatic(3, k3_edges(), 1))
  r.add(@matroid.check_chromatic(4, k4_edges(), 1))
  r
}

///|
/// 【B0002 延伸】全域報告的文字形式。
pub fn extension_global_summary() -> String {
  let r = extension_global_report()
  let sb = StringBuilder()
  sb.write_string(
    "B0002 延伸全域檢核（T9–T12）：" +
    r.passed_count().to_string() +
    "/" +
    r.size().to_string() +
    " 通過\n",
  )
  sb.write_string(r.render())
  sb.to_string()
}

///|
/// 【B0002 延伸】登記期望值核對：把「登記表上寫的數字」變成可執行判準。
/// `expected_flats = -1` 表示**無獨立期望值**（例如 F7* 的平坦數），此時明示「未設期望」而不假裝通過。
pub fn check_registered_expectations() -> @galois.Report {
  let r = @galois.Report::new()
  let base = registered_matroids()
  let ext = registered_matroids_ext()
  let all : Array[RegisteredMatroid] = []
  for i = 0; i < base.length(); i = i + 1 {
    all.push(base[i])
  }
  for i = 0; i < ext.length(); i = i + 1 {
    all.push(ext[i])
  }
  for i = 0; i < all.length(); i = i + 1 {
    let reg = all[i]
    let m = reg.matroid
    let flats = m.flat_count()
    let circuits = m.circuit_count()
    let flats_ok = reg.expected_flats < 0 || flats == reg.expected_flats
    let circ_ok = reg.expected_circuits < 0 || circuits == reg.expected_circuits
    let mut detail = "|ℱ|=" + flats.to_string()
    detail = detail +
      "（期望 " +
      (if reg.expected_flats < 0 {
        "未設"
      } else {
        reg.expected_flats.to_string()
      }) +
      "）"
    detail = detail + "，|𝒞|=" + circuits.to_string()
    detail = detail +
      "（期望 " +
      (if reg.expected_circuits < 0 {
        "未設"
      } else {
        reg.expected_circuits.to_string()
      }) +
      "）"
    r.add(@galois.Check::make("登記", reg.name, flats_ok && circ_ok, detail))
  }
  r
}
