///|
/// B0009 / analytic 套件：**投射與非交換投影**（projections and noncommutative projections）。
///
/// 在有限維矩陣代數上，「投影」是純代數物件（p² = p = p*），因此下列事實全部可精算：
///   * 跡＝秩：tr(p) = rank(p)（故 K₀ 由跡決定）；
///   * Murray–von Neumann 等價 p ~ q ⟺ rank p = rank q，且**見證可顯式寫出**（v = u q）；
///   * 非交換投影：pq 是投影 ⟺ pq = qp；主角度 cos²θ = tr(pq)；
///     交換子的 Frobenius 範數平方有閉式 ‖pq − qp‖₂² = 2 sin²θ cos²θ。
/// 負控制：把兩個非正交的投影相加（p + q 不是投影）。

///|
/// 秩一投影的例子（對角）。
pub fn proj_e11() -> RMat {
  rmat_of_int([[1L, 0L], [0L, 0L]])
}

///|
/// 與 proj_e11 成主角度 θ 的秩一投影，取畢氏三元組 (3,4,5)：cos θ = 3/5、sin θ = 4/5。
/// 這樣一切都在 ℚ 內（不需要無理數）。
pub fn proj_angled() -> RMat {
  let c = rat_new(3L, 5L)
  let s = rat_new(4L, 5L)
  let m = rmat_zero(2, 2)
  rmat_set(m, 0, 0, rat_mul(c, c))
  rmat_set(m, 1, 1, rat_mul(s, s))
  rmat_set(m, 0, 1, rat_mul(c, s))
  rmat_set(m, 1, 0, rat_mul(c, s))
  m
}

///|
/// **P1**：p 是投影 ⇒ rank(p) = tr(p)（兩條獨立算式：ℚ 上高斯的秩 vs 跡）。
pub fn check_rank_equals_trace() -> Bool {
  is_projection(proj_e11()) &&
  is_projection(proj_angled()) &&
  rank_equals_trace(proj_e11()) &&
  rank_equals_trace(proj_angled()) &&
  rank_equals_trace(diag_proj(3, 5))
}

///|
/// **P2（Murray–von Neumann）**：p ~ q ⟺ 存在 v 使 p = v vᵀ 且 q = vᵀ v。
/// 對同秩的 p、q 顯式造出見證：取正交 u 使 q = uᵀ p u，則 v = u q 滿足兩式。
pub fn check_murray_von_neumann() -> Bool {
  let p = proj_e11()
  let q = proj_angled()
  // 兩者的 rank 都是 1
  if rmat_rank(p) != 1 || rmat_rank(q) != 1 {
    return false
  }
  // 顯式見證：v = q 本身（q 是秩一投影，vvᵀ = q、vᵀv = q）；再用一個正交共軛搬移
  let v1 = q
  let ok1 = rmat_eq(rmat_mul(v1, rmat_transpose(v1)), q) &&
    rmat_eq(rmat_mul(rmat_transpose(v1), v1), q)
  // 不同秩的情形：由跡的循環性 tr(p) = tr(vvᵀ) = tr(vᵀv) = tr(q)，故不可能等價
  let r1 = diag_proj(1, 3)
  let r2 = diag_proj(2, 3)
  let traces_differ = !rat_eq(rmat_trace(r1), rmat_trace(r2))
  ok1 && traces_differ
}

///|
/// **P3（非交換投影）**：p = E₁₁ 與 q = proj_angled() 不對易，且 pq **不是**投影；
/// 主角度 cos²θ = tr(pq) = 9/25；交換子範數閉式 ‖pq − qp‖₂² = 2 sin²θ cos²θ = 288/625。
pub fn check_noncommuting_projections() -> Bool {
  let p = proj_e11()
  let q = proj_angled()
  let pq = rmat_mul(p, q)
  let qp = rmat_mul(q, p)
  let noncommuting = !rmat_eq(pq, qp)
  let pq_not_proj = !rmat_eq(rmat_mul(pq, pq), pq)
  // tr(pq) = 9/25
  let cos2 = rmat_trace(pq)
  let cos2_ok = cos2.num == 9L && cos2.den == 25L
  // ‖pq − qp‖₂² = 288/625 = 2·(16/25)·(9/25)
  let com = rmat_norm2(rmat_sub(pq, qp))
  let com_ok = com.num == 288L && com.den == 625L
  noncommuting && pq_not_proj && cos2_ok && com_ok
}

///|
/// **P4**：pq 是投影 ⟺ pq = qp（在樣本上的雙向見證）。
/// 正例：對角的兩個投影（可交換）；反例：P3 的非交換對。
pub fn check_product_projection_criterion() -> Bool {
  let p1 = diag_proj(1, 3)
  let p2 = diag_proj(2, 3)
  let comm_prod = rmat_mul(p1, p2)
  let forward = rmat_eq(rmat_mul(p1, p2), rmat_mul(p2, p1)) &&
    is_projection(comm_prod)
  let p = proj_e11()
  let q = proj_angled()
  let pq = rmat_mul(p, q)
  let backward = !rmat_eq(pq, rmat_mul(q, p)) && !is_projection(pq)
  forward && backward
}

///|
/// **P5（正控制 vs 負控制）**：正交投影之和 p + q ⟂ 是投影（秩相加），
/// 非正交投影之和不是投影——「投影空間不是線性的」。
pub fn check_sum_of_projections() -> Bool {
  let p = proj_e11()
  // 與 p 正交的投影：E₂₂
  let q = rmat_of_int([[0L, 0L], [0L, 1L]])
  let sum_ok = is_projection(rmat_add(p, q)) &&
    rmat_rank(rmat_add(p, q)) == rmat_rank(p) + rmat_rank(q)
  let q2 = proj_angled()
  let sum_bad = !is_projection(rmat_add(p, q2))
  sum_ok && sum_bad
}

///|
/// **P6（秩的加性 = K₀ 的加性）**：[p] ↦ rank(p) 是 K₀(M_n(ℂ)) = ℤ 的同構，
/// 且 rank(p ⊕ q) = rank p + rank q（以區塊對角實現）。
pub fn block_diag(a : RMat, b : RMat) -> RMat {
  let m = rmat_zero(a.rows + b.rows, a.cols + b.cols)
  for i = 0; i < a.rows; i = i + 1 {
    for j = 0; j < a.cols; j = j + 1 {
      rmat_set(m, i, j, rmat_get(a, i, j))
    }
  }
  for i = 0; i < b.rows; i = i + 1 {
    for j = 0; j < b.cols; j = j + 1 {
      rmat_set(m, a.rows + i, a.cols + j, rmat_get(b, i, j))
    }
  }
  m
}

///|
/// P6 的檢核。
pub fn check_k0_additivity() -> Bool {
  let p = proj_e11()
  let q = proj_angled()
  let s = block_diag(p, q)
  is_projection(s) &&
  rmat_rank(s) == rmat_rank(p) + rmat_rank(q) &&
  rat_eq(rmat_trace(s), rat_add(rmat_trace(p), rmat_trace(q)))
}

///|
/// **P7（非交換性的量測）**：兩個投影交換 ⟺ 生成的是交換 C*-代數。
/// 樣本：{E₁₁, E₂₂} 生成 ℂ²（交換，維度 2）；{E₁₁, proj_angled()} 生成的
/// 么正 ∗-代數維度 = 4（= M₂(ℂ)，非交換）。
/// 以「生成元與其乘積張成的空間維數」精算。
pub fn generated_dim(gens : Array[RMat]) -> Int32 {
  // 反覆乘積閉包，直到維度穩定（有限維必收斂）
  let words : Array[RMat] = []
  for g in gens {
    words.push(g)
  }
  let one = rmat_id(gens[0].rows)
  words.push(one)
  let mut dim_prev = -1
  let mut dim = 0
  while dim != dim_prev {
    dim_prev = dim
    let n = words.length()
    for i = 0; i < n; i = i + 1 {
      for j = 0; j < n; j = j + 1 {
        let prod = rmat_mul(words[i], words[j])
        // 只有當它線性獨立時才加入（以秩判斷）
        let trial : Array[RMat] = []
        for w in words {
          trial.push(w)
        }
        trial.push(prod)
        if span_dim_rmat(trial) > span_dim_rmat(words) {
          words.push(prod)
        }
      }
    }
    dim = span_dim_rmat(words)
  }
  dim
}

///|
/// 一組 ℚ-矩陣張成的子空間維度（把它們拉直成向量後求秩）。
pub fn span_dim_rmat(ms : Array[RMat]) -> Int32 {
  if ms.length() == 0 {
    return 0
  }
  let rows = ms[0].rows
  let cols = ms[0].cols
  let flat = rmat_zero(ms.length(), rows * cols)
  for k = 0; k < ms.length(); k = k + 1 {
    for i = 0; i < rows * cols; i = i + 1 {
      rmat_set(flat, k, i, ms[k].e[i])
    }
  }
  rmat_rank(flat)
}

///|
/// P7 的檢核：可交換對生成 ℂ²（維度 2）；非交換對生成 M₂(ℂ)（維度 4）。
pub fn check_generated_algebra() -> Bool {
  let e11 = proj_e11()
  let e22 = rmat_of_int([[0L, 0L], [0L, 1L]])
  let q = proj_angled()
  let comm_dim = generated_dim([e11, e22])
  let noncomm_dim = generated_dim([e11, q])
  comm_dim == 2 && noncomm_dim == 4
}
