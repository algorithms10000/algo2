///|
/// B0010 / bc 套件：**循環群 ℤ/n 的組裝映射 = 離散傅立葉矩陣**。
///
/// ℤ/n 的特徵表是 (ζ^{jk})_{j,k}（j 指標不可約表示、k 指標共軛類 = 元素），
/// 也就是 DFT 矩陣 F。**F 可逆 ⇔ μ 是同構**，而 F 可逆的實質理由是
///   Σ_{k=0}^{n−1} ζ^{k(j−j')} = n·δ_{j,j'}（單位根的和），
/// 這正是「圓周群的所有單位根群」與「圓體擴張」在本猜想上的作用點：
/// 一側是 R(ℤ/n) 的分圓基底，另一側是 μ_n 的加法結構。
///
/// 全部精算：值住在其 ℚ(ζ_n) 的整數基底座標裡（Φ_n 么正），用 B0009 的 `cyclotomic`。

///|
/// 在 ℚ(ζ_n) 中精算 Σ_{k=0}^{n−1} ζ^{k·m}（回傳 φ(n) 維整數座標）。
pub fn cyclo_dft_sum(n : Int32, m : Int32) -> Array[Int64] {
  let d = @cyclotomic.cyclo_dim(n)
  let acc : Array[Int64] = []
  for i = 0; i < d; i = i + 1 {
    acc.push(0L)
  }
  for k = 0; k < n; k = k + 1 {
    let v = @cyclotomic.reduce_mod_cyclo(n, @cyclotomic.x_power(k * m % n))
    for i = 0; i < d; i = i + 1 {
      acc[i] = acc[i] + v[i]
    }
  }
  acc
}

///|
/// **T83 的核心**：Σ_k ζ^{k·m} = n（m ≡ 0）或 0（m ≢ 0），逐座標精算比較。
pub fn check_dft_orthogonality(n : Int32) -> Bool {
  let d = @cyclotomic.cyclo_dim(n)
  let mut ok = true
  for m = 0; m < n; m = m + 1 {
    let v = cyclo_dft_sum(n, m)
    for i = 0; i < d; i = i + 1 {
      let want = if m == 0 && i == 0 { n.to_int64() } else { 0L }
      if v[i] != want {
        ok = false
      }
    }
  }
  ok
}

///|
/// 負控制：把 ζ 換成 1（「所有單位根都當成 1」，退化到么代數）時，
/// Σ_k ζ^{k·m} 對**每個** m 都等於 n ≠ 0，正交性立刻失敗。
/// 判準有內容 ⇔ 「正確的和在 m ≠ 0 時是 0」**且**「退化模型在那裡是 n ≠ 0」。
pub fn check_dft_collapse_fails(n : Int32) -> Bool {
  let mut ok = true
  for m = 1; m < n; m = m + 1 {
    // 正確模型：Σ_k ζ^{km} = 0（逐座標）
    for x in cyclo_dft_sum(n, m) {
      if x != 0L {
        ok = false
      }
    }
    // 退化（ζ ↦ 1）模型：Σ_k 1 = n，與 0 不符 ⇒ 判準分辨得出兩者
    if n.to_int64() == 0L {
      ok = false
    }
  }
  ok
}

///|
/// ℤ/n 的組裝映射資料：兩側的自由秩都 = n（n 個不可約表示 / n 個共軛類），
/// 且 DFT 正交 ⇒ 秩 = n ⇒ μ_0 是同構；K₁ 兩側皆 0（ℂ[ℤ/n] 半單）。
pub fn bc_cyclic_iso(n : Int32) -> Bool {
  check_dft_orthogonality(n)
}
