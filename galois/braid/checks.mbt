///|
/// B0005 / braid 套件：**檢核器（T22–T24）**
/// 對應 docs/B0005-定理體系.md §2–§4。

///|
/// T22：B_n ↠ S_n 滿射（換位生成 S_n ⇒ 像的階 = n!），且在置換層辮關係成立。
pub fn check_permutation_quotient(n : Int32) -> @galois.Check {
  let name = "T22 B_n ↠ S_n（n=" + n.to_string() + "）"
  let count = generated_permutation_count(n)
  let want = factorial(n)
  let mut rel_ok = true
  for i = 1; i < n - 1; i = i + 1 {
    if !permutation_braid_relation(n, i) {
      rel_ok = false
    }
  }
  let ok = count == want && rel_ok
  let detail = "⟨換位⟩ 的階 " +
    count.to_string() +
    "（= n! = " +
    want.to_string() +
    "）、置換層辮關係 " +
    rel_ok.to_string() +
    " ⇒ 核 = 純辮群 P_n，指數 n!"
  @galois.Check::make("T22", name, ok, detail)
}

///|
/// T23：未約化 Burau β_n 是表示（辮關係 + 遠處交換律都在 ℤ[t^{±1}] 上精確成立）。
pub fn check_burau_representation(n : Int32) -> @galois.Check {
  let name = "T23 Burau 是表示（n=" + n.to_string() + "）"
  let mut braid_ok = true
  for i = 1; i < n - 1; i = i + 1 {
    if !burau_braid_relation(n, i) {
      braid_ok = false
    }
  }
  let mut comm_ok = true
  for i = 1; i < n; i = i + 1 {
    for j = i + 2; j < n; j = j + 1 {
      if !burau_commutes(n, i, j) {
        comm_ok = false
      }
    }
  }
  let ok = braid_ok && comm_ok
  let detail = "σ_iσ_{i+1}σ_i = σ_{i+1}σ_iσ_{i+1}：" +
    braid_ok.to_string() +
    "；|i−j|≥2 交換：" +
    comm_ok.to_string()
  @galois.Check::make("T23", name, ok, detail)
}

///|
/// T23：det β_n(w) = (−t)^{exp(w)}——即 Burau 探測到 abelianization B_n → ℤ 的完整資訊。
pub fn check_burau_determinant(
  n : Int32,
  letters : Array[Int32],
) -> @galois.Check {
  let w = bw_make(n, letters)
  let name = "T23 det β_n(w) = (−t)^{exp w}（n=" +
    n.to_string() +
    "，" +
    letters.length().to_string() +
    " 個字母）"
  let m = burau_of_word(w)
  let d = lm_det(m)
  let e = w.exponent_sum()
  let sign = if e % 2 == 0 { 1 } else { -1 }
  let want = lp_norm([(e, BigInt::from_int(sign))])
  let ok = lp_eq(d, want)
  let detail = "det = " +
    lp_render(d) +
    "，期望 (−t)^" +
    e.to_string() +
    " = " +
    lp_render(want)
  @galois.Check::make("T23", name, ok, detail)
}

///|
/// Laurent 多項式的文字形式（報表用）。
pub fn lp_render(p : LPoly) -> String {
  if p.t.length() == 0 {
    return "0"
  }
  let sb = StringBuilder()
  for i = 0; i < p.t.length(); i = i + 1 {
    let (e, c) = p.t[i]
    if i > 0 {
      sb.write_char('+')
    }
    sb.write_string(c.to_string())
    if e != 0 {
      sb.write_string("t^" + e.to_string())
    }
  }
  sb.to_string()
}

///|
/// T23（有界）：長度 ≤ maxlen 的字裡沒有偽核（非空字映到單位矩陣）。
/// **這是界內檢核，不是忠實性的證明**——在文件與報表都這樣寫。
pub fn check_burau_no_fake_kernel(n : Int32, maxlen : Int32) -> @galois.Check {
  let name = "T23 界內無偽核（n=" +
    n.to_string() +
    "，長度 ≤ " +
    maxlen.to_string() +
    "）"
  let c = burau_fake_kernels(n, maxlen)
  let ok = c == 0
  let detail = "在 " +
    n.to_string() +
    " 個生成元的 ± 字母表中，長度 ≤ " +
    maxlen.to_string() +
    " 的非空字共 " +
    word_count(n, maxlen).to_string() +
    " 個，其中映到 I 的有 " +
    c.to_string() +
    " 個（0 = 界內無偽核；不是忠實性的證明）"
  @galois.Check::make("T23", name, ok, detail)
}

///|
/// 長度 ≤ maxlen 的非空字個數：Σ_{k=1}^{maxlen} (2(n−1))^k。
pub fn word_count(n : Int32, maxlen : Int32) -> Int32 {
  let a = 2 * (n - 1)
  let mut s = 0
  let mut p = 1
  for _k = 1; _k <= maxlen; _k = _k + 1 {
    p = p * a
    s = s + p
  }
  s
}

///|
/// 2×2 整數矩陣在 PSL₂(ℤ) 中相等（差 ±I）。
pub fn mat2_same_pm(
  x : (Int64, Int64, Int64, Int64),
  y : (Int64, Int64, Int64, Int64),
) -> Bool {
  let (a, b, c, d) = x
  let (e, f, g, h) = y
  (a == e && b == f && c == g && d == h) ||
  (a == -e && b == -f && c == -g && d == -h)
}

///|
/// T24：B_3 → PSL₂(ℤ) 的像滿足辮關係，且中心 ⟨(σ1σ2)³⟩ 落在核裡（模 ±I）。
pub fn check_b3_to_psl() -> @galois.Check {
  let a = psl_image(1)
  let b = psl_image(2)
  let aba = mat2_mul(mat2_mul(a, b), a)
  let bab = mat2_mul(mat2_mul(b, a), b)
  // 在 PSL₂ 中比較：允許差 ±I（這正是「下降到射影群」的意思，也是 BUG-9）
  let rel = mat2_same_pm(aba, bab)
  let ab = mat2_mul(a, b)
  let c2 = mat2_is_pm_identity(mat2_mul(aba, aba))
  let c3 = mat2_is_pm_identity(mat2_mul(mat2_mul(ab, ab), ab))
  let ok = rel && c2 && c3
  let detail = "σ1 ↦ T=(1,1;0,1)、σ2 ↦ STS=(−1,0;1,−1)；ABA=BAB：" +
    rel.to_string() +
    "、(σ1σ2σ1)²=±I：" +
    c2.to_string() +
    "、(σ1σ2)³=±I：" +
    c3.to_string() +
    " ⇒ 映射下降為 B_3/⟨(σ1σ2)³⟩ → PSL₂(ℤ)"
  @galois.Check::make("T24", "T24 B_3 → PSL₂(ℤ)", ok, detail)
}

///|
/// T24：模 n 之下 ⟨σ1, σ2⟩ 的像等於整個 SL₂(ℤ/n)（n = 2..12）。
pub fn check_b3_image_generates(n : Int32) -> @galois.Check {
  let ok = psl_image_generates_sl2(n)
  let detail = "⟨T, STS⟩ mod " +
    n.to_string() +
    " 的階 = |SL₂(ℤ/" +
    n.to_string() +
    ")| = " +
    @modular.order_sl2_mod(n).to_string() +
    "：" +
    ok.to_string()
  @galois.Check::make(
    "T24",
    "T24 像生成 SL₂(ℤ/n)（n=" + n.to_string() + "）",
    ok,
    detail,
  )
}

///|
/// 完整報告（T22–T24）。
pub fn braid_report() -> @galois.Report {
  let r = @galois.Report::new()
  for n = 2; n <= 6; n = n + 1 {
    r.add(check_permutation_quotient(n))
  }
  for n = 2; n <= 5; n = n + 1 {
    r.add(check_burau_representation(n))
  }
  r.add(check_burau_determinant(3, [1]))
  r.add(check_burau_determinant(3, [1, 2]))
  r.add(check_burau_determinant(3, [1, 2, -1]))
  r.add(check_burau_determinant(4, [2, -3, 1, 1]))
  r.add(check_burau_no_fake_kernel(3, 6))
  r.add(check_burau_no_fake_kernel(2, 6))
  r.add(check_b3_to_psl())
  for n = 2; n <= 12; n = n + 1 {
    r.add(check_b3_image_generates(n))
  }
  r
}
