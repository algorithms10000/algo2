///|
/// B0006 / kk 套件：**有限群的 K-群與對稱群接縫**（A43）
/// 對應 docs/B0006-定理體系.md §11（與 B0003／B0005 的接縫）。
///
/// 對有限群 G：C*(G) ≅ ⊕_{[π] ∈ Irr(G)} M_{d_π}(ℂ)（Artin–Wedderburn / Maschke），故
///   **K₀(C*(G)) = ℤ^{#Irr(G)} = ℤ^{#共軛類(G)}、K₁ = 0**。
/// 檔內提供兩條可計算的入口：
///   * 對稱群 S_n：用分割＋hook length 公式算全部 d_λ，並驗 Σ d_λ² = n!；
///   * 一般有限群（以 B0003 的 SL₂(ℤ/n) 為例）：暴力數共軛類。

///|
/// 遞迴輔助（頂層定義：巢狀函式對 `Array[Array[Int32]]` 參數有語法歧義）。
fn part_go(
  rem : Int32,
  maxp : Int32,
  cur : Array[Int32],
  out : Array[Array[Int32]],
) -> Unit {
  if rem == 0 {
    out.push(cur.copy())
    return
  }
  let mut p = if maxp < rem { maxp } else { rem }
  while p >= 1 {
    cur.push(p)
    part_go(rem - p, p, cur, out)
    ignore(cur.pop())
    p = p - 1
  }
}

///|
/// n 的全部分割（降序，如 [3,1]）。
pub fn partitions(n : Int32) -> Array[Array[Int32]] {
  let out : Array[Array[Int32]] = []
  let cur : Array[Int32] = []
  part_go(n, n, cur, out)
  out
}

///|
/// 分割的階（= n）。
pub fn partition_size(lambda : Array[Int32]) -> Int32 {
  let mut s = 0
  for x in lambda {
    s = s + x
  }
  s
}

///|
/// Young 圖的 hook length 乘積 Π hooks。
pub fn hook_product(lambda : Array[Int32]) -> Int64 {
  let rows = lambda.length()
  let mut prod = 1L
  for i = 0; i < rows; i = i + 1 {
    for j = 0; j < lambda[i]; j = j + 1 {
      // hook = (右側格數) + (下方格數) + 1
      let right = lambda[i] - j - 1
      let mut below = 0
      for k = i + 1; k < rows; k = k + 1 {
        if lambda[k] > j {
          below = below + 1
        }
      }
      prod = prod * (right + below + 1).to_int64()
    }
  }
  prod
}

///|
/// 不可約表示的維數 d_λ = n! / Π hooks（hook length formula）。
pub fn irrep_dim(lambda : Array[Int32]) -> Int64 {
  let n = partition_size(lambda)
  let mut fact = 1L
  for i = 2; i <= n; i = i + 1 {
    fact = fact * i.to_int64()
  }
  fact / hook_product(lambda)
}

///|
/// Σ_{λ ⊢ n} d_λ²（應等於 n!）。
pub fn sum_dim_squares(n : Int32) -> Int64 {
  let mut s = 0L
  for lambda in partitions(n) {
    let d = irrep_dim(lambda)
    s = s + d * d
  }
  s
}

///|
/// 對稱群 S_n 的 K-群：K₀ = ℤ^{p(n)}（p(n) = 分割數 = 共軛類數）、K₁ = 0。
pub fn k_of_symmetric_group(n : Int32) -> KPair {
  { k0: fga_free(partitions(n).length()), k1: fga_zero(), }
}

///|
/// 顯示分割。
pub fn partition_render(lambda : Array[Int32]) -> String {
  let sb = StringBuilder()
  sb.write_string("(")
  for i = 0; i < lambda.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string(lambda[i].to_string())
  }
  sb.write_string(")")
  sb.to_string()
}
