///|
/// B0010 / bc 套件：**局部公理由本代理決定**（需求文件第 2 行）
///
/// 分工寫死在資料結構裡：
///
///   * **全局公理**（`global = true`）：Baum–Connes 猜想本身、有係數版、SL_n(ℤ) 等。
///     這些**不由本代理決定**——`decided` 一律 false，且必須附兩個可能值（BC1–BC8）。
///   * **局部公理**（`global = false`）：對每一個可算樣本 G，「μ_G 是同構」是一條
///     **局部公理**，由本代理用指定的可執行程序判定，`decided = true` 並附見證。
///
/// 關鍵檢核（`local_axioms_verified`）：局部公理的裁決**不是手寫的**——
/// 它必須與引擎當場重算的判定一致（`verdict` = 重算結果），否則整條公理失效。
/// 這使「由代理決定」不等於「由作者宣稱」。

///|
/// 一條公理記錄。
pub struct AxiomRecord {
  id : String
  statement : String
  global : Bool
  procedure : String
  verdict : Bool
  witness : String
}

///|
/// 由引擎當場判定一條局部公理：以樣本鍵（群名）選程序。
/// 回傳 (verdict, witness)。
pub fn decide_local(group_key : String) -> (Bool, String) {
  if group_key == "ℤ/n" {
    let mut ok = true
    for n = 2; n <= 12; n = n + 1 {
      if !bc_cyclic_iso(n) {
        ok = false
      }
    }
    (ok, "DFT 正交 Σ_k ζ^{km} = nδ_{m0} 對 n = 2…12 全部精算成立")
  } else if group_key == "A₄" {
    let ok = a4_mu_rank_rat() == 8 &&
      a4_mu_rank_modp() == 8 &&
      a4_gram_is_scalar()
    (ok, "ℤ[ω] 展開秩 8 = 2·4（只用 ℚ 則 6）")
  } else if group_key == "ℤ" {
    let six = @kk.check_six_term_toeplitz()
    let wind = @kk.check_index_winding()
    (
      six.passed() && wind.passed(),
      "C*_rℤ = C(S¹)，Toeplitz 六項正列＋指標＝繞數",
    )
  } else {
    // 有限群樣本：直接重算
    let mut ok = true
    let mut found = false
    for g in groups_int() {
      if g.name == group_key {
        found = true
        if !bc_assembly_iso(g) {
          ok = false
        }
      }
    }
    (ok && found, "特徵表滿秩＋正交性＋Σdim²=|G|")
  }
}

///|
/// 局部公理清單（每個樣本一條；全部由本代理判定）。
pub fn local_axioms() -> Array[AxiomRecord] {
  let keys : Array[String] = [
    "ℤ/2", "V₄ = ℤ/2×ℤ/2", "S₃", "D₈", "Q₈", "ℤ/n", "A₄", "ℤ",
  ]
  let out : Array[AxiomRecord] = []
  for k in keys {
    let (v, w) = decide_local(k)
    out.push({
      id: "L-" + k,
      statement: "μ_* : K_*^G(EG) → K_*(C*_r G) 對 G = " + k + " 是同構",
      global: false,
      procedure: "bc_assembly_iso／bc_cyclic_iso／a4_mu_rank_*／kk.six_term_check",
      verdict: v,
      witness: w,
    })
  }
  out
}

///|
/// 全局公理清單（不由本代理決定；與 BC1–BC8 對齊）。
pub fn global_axioms() -> Array[AxiomRecord] {
  let out : Array[AxiomRecord] = []
  for it in bc_items() {
    out.push({
      id: it.id,
      statement: it.title,
      global: true,
      procedure: "（無：界外，不由本代理決定）",
      verdict: false,
      witness: it.status +
      "；若真：" +
      it.value_if_true +
      "；若假：" +
      it.value_if_false,
    })
  }
  out
}

///|
/// **T90**：局部公理全部 `decided = true` 且裁決與引擎重算一致；
/// 全局公理全部 `decided = false` 且帶兩個可能值；兩類不得混同。
pub fn local_axioms_verified() -> Bool {
  let mut ok = true
  let locals = local_axioms()
  for a in locals {
    if a.global || !a.verdict || a.witness == "" || a.procedure == "" {
      ok = false
    }
    // 重算：裁決必須可重現
    let (v, _) = decide_local(strip_prefix(a.id))
    if v != a.verdict {
      ok = false
    }
  }
  let globals = global_axioms()
  for a in globals {
    if !a.global || a.verdict {
      ok = false
    }
    if a.witness == "" || a.procedure == "" {
      ok = false
    }
  }
  // 兩類總數 = 局部樣本數 + 界外條目數，且不重疊
  locals.length() == 8 && globals.length() == bc_items().length() && ok
}

///|
/// 從 "L-<key>" 取回 key。
fn strip_prefix(id : String) -> String {
  if id.length() > 2 {
    id[2:].to_owned()
  } else {
    ""
  }
}
