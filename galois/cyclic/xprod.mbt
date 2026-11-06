///|
/// B0008 / cyclic 套件：**內部張量積完整化**（internal tensor product）。
///
/// 這裡把「內部張量積」落成可算的線性代數：
///   * `Bimod`：有限維 A-雙模（左、右作用各以 A 的每個基底元素一個方陣給出）；
///   * `bimod_tensor_dim`：共端（coend）M₁ ⊗_A M₂ 的維度
///     = dim M₁ · dim M₂ − rank(關係矩陣)；
///   * `bimod_hom_dim`：雙模同態空間 Hom_{A,A}(M₁, M₂) 的維度
///     = dim M₁ · dim M₂ − rank(約束矩陣)；
///   * 三條**可反駁**的結構定理：
///     (X1) 單位：A ⊗_A M ≅ M（維度相等），且**要求 A 有單位**；
///     (X2) 內部張量積 = HH₀ 的共端描述：dim(A ⊗_{Aᵉ} A) = dim A/[A,A]；
///     (X3) Hom-張量伴隨的維度面向：Hom_A(A, M) = M^A（不變量）。
/// 另有外部張量積 A ⊗_k B 與循環同調的乘法性（見 checks.mbt T60）。

// ---------------------------------------------------------------- 反代數

///|
/// 反代數 A^op：乘法反向（a·_{op}b = b·a），單位與向量空間不變。
pub fn alg_op(a : FdAlg) -> FdAlg {
  let d = a.dim
  let mult = fd_mult_zero(d)
  for i = 0; i < d; i = i + 1 {
    for j = 0; j < d; j = j + 1 {
      for k = 0; k < d; k = k + 1 {
        fd_set(mult, d, i, j, k, fd_coeff(a, j, i, k))
      }
    }
  }
  fd_alg(a.name + "^op", d, a.unit_vec, a.aug, mult)
}

// ---------------------------------------------------------------- 雙模

///|
/// 有限維 A-雙模：`left[k*dim + i][p]` = 「e_k · m_i 的第 p 個座標」，
/// `right[k*dim + i][p]` = 「m_i · e_k 的第 p 個座標」。
pub struct Bimod {
  name : String
  alg : FdAlg
  dim : Int32
  left : Array[Array[Int64]]
  right : Array[Array[Int64]]
}

///|
/// 建立雙模（維度自洽性由 `bimod_ok` 檢查）。
pub fn bimod_make(
  name : String,
  alg : FdAlg,
  dim : Int32,
  left : Array[Array[Int64]],
  right : Array[Array[Int64]],
) -> Bimod {
  { name, alg, dim, left, right, }
}

///|
/// **正則雙模** A_A_A：左作用 = 左乘、右作用 = 右乘。
pub fn bimod_regular(a : FdAlg) -> Bimod {
  let d = a.dim
  let left = mat_zero(d * d, d)
  let right = mat_zero(d * d, d)
  for k = 0; k < d; k = k + 1 {
    for i = 0; i < d; i = i + 1 {
      for p = 0; p < d; p = p + 1 {
        left[k * d + i][p] = fd_coeff(a, k, i, p)
        right[k * d + i][p] = fd_coeff(a, i, k, p)
      }
    }
  }
  bimod_make("A（正則）", a, d, left, right)
}

///|
/// **零作用雙模**：維度 = dim A，左右作用全部為 0（⚠ 一般不是 A-雙模，用來做負控制）。
pub fn bimod_zero_act(a : FdAlg) -> Bimod {
  let d = a.dim
  bimod_make("A（零作用）", a, d, mat_zero(d * d, d), mat_zero(d * d, d))
}

///|
/// 增廣向量：ε(e_k) = 1 若 e_k 是單位、0 否則（僅當單位是單一基底元素時有定義）。
pub fn alg_aug(a : FdAlg) -> Array[Int64] {
  a.aug
}

///|
/// 增廣是否為**代數同態** ε(ab) = ε(a)ε(b)（A 是否為增廣代數）。
/// 群代數與 k[x]/(x^m) 為真；M_n(ℂ)（n ≥ 2）為假——因此那裡沒有「一維平凡模」。
pub fn alg_aug_ok(a : FdAlg) -> Bool {
  let e = alg_aug(a)
  // ε(1) = 1
  let mut one = 0L
  for k = 0; k < a.dim; k = k + 1 {
    one = one + e[k] * a.unit_vec[k]
  }
  let mut ok = one == 1L
  for i = 0; i < a.dim; i = i + 1 {
    for j = 0; j < a.dim; j = j + 1 {
      let mut s = 0L
      for k = 0; k < a.dim; k = k + 1 {
        s = s + fd_coeff(a, i, j, k) * e[k]
      }
      if s != e[i] * e[j] {
        ok = false
      }
    }
  }
  ok
}

///|
/// **一維增廣模** k_ε：e_k · n = ε(e_k)·n（A 必須是增廣代數，見 `alg_aug_ok`）。
pub fn bimod_aug(a : FdAlg) -> Bimod {
  let e = alg_aug(a)
  let left = mat_zero(a.dim, 1)
  let right = mat_zero(a.dim, 1)
  for k = 0; k < a.dim; k = k + 1 {
    left[k][0] = e[k]
    right[k][0] = e[k]
  }
  bimod_make("k_ε（增廣模）", a, 1, left, right)
}

///|
/// 雙模的結合律與單位性：e_1 作用為恆等、左右作用互相結合
/// （(e_k·m_i)·e_l = e_k·(m_i·e_l)）。這是「它真的是雙模」的判準。
pub fn bimod_ok(m : Bimod) -> Bool {
  let d = m.alg.dim
  let mut ok = true
  // 單位元素作用 = 恆等（用 unit_vec 展開）
  for i = 0; i < m.dim; i = i + 1 {
    let lv : Array[Int64] = []
    for p = 0; p < m.dim; p = p + 1 {
      lv.push(0L)
    }
    for k = 0; k < d; k = k + 1 {
      let c = m.alg.unit_vec[k]
      for p = 0; p < m.dim; p = p + 1 {
        lv[p] = lv[p] + c * m.left[k * m.dim + i][p]
      }
    }
    for p = 0; p < m.dim; p = p + 1 {
      let want = if p == i { 1L } else { 0L }
      if lv[p] != want {
        ok = false
      }
    }
  }
  // 左右作用可交換先後
  for k = 0; k < d; k = k + 1 {
    for l = 0; l < d; l = l + 1 {
      for i = 0; i < m.dim; i = i + 1 {
        for p = 0; p < m.dim; p = p + 1 {
          let mut a1 = 0L
          let mut a2 = 0L
          for q = 0; q < m.dim; q = q + 1 {
            a1 = a1 + m.left[k * m.dim + i][q] * m.right[l * m.dim + q][p]
            a2 = a2 + m.right[l * m.dim + i][q] * m.left[k * m.dim + q][p]
          }
          if a1 != a2 {
            ok = false
          }
        }
      }
    }
  }
  ok
}

// ---------------------------------------------------------------- 內部張量積

///|
/// M₁ ⊗_A M₂ 的關係矩陣：對每個 (k, i, j) 給出
///   (e_k · m_i) ⊗ n_j − m_i ⊗ (e_k · n_j) = 0
/// 在基底 (m_{i'} ⊗ n_{j'}) 下的座標向量。列數 = dim A · dim M₁ · dim M₂。
pub fn bimod_tensor_rel(m1 : Bimod, m2 : Bimod) -> Array[Array[Int64]] {
  let d = m1.alg.dim
  let out = mat_zero(d * m1.dim * m2.dim, m1.dim * m2.dim)
  for k = 0; k < d; k = k + 1 {
    for i = 0; i < m1.dim; i = i + 1 {
      for j = 0; j < m2.dim; j = j + 1 {
        let row = (k * m1.dim + i) * m2.dim + j
        for ip = 0; ip < m1.dim; ip = ip + 1 {
          out[row][ip * m2.dim + j] = out[row][ip * m2.dim + j] +
            m1.right[k * m1.dim + i][ip]
        }
        for jp = 0; jp < m2.dim; jp = jp + 1 {
          out[row][i * m2.dim + jp] = out[row][i * m2.dim + jp] -
            m2.left[k * m2.dim + j][jp]
        }
      }
    }
  }
  out
}

///|
/// **內部張量積的維度**：dim(M₁ ⊗_A M₂) = dim M₁·dim M₂ − rank(關係矩陣)。
pub fn bimod_tensor_dim(m1 : Bimod, m2 : Bimod) -> Int32 {
  m1.dim * m2.dim - rank_q(bimod_tensor_rel(m1, m2))
}

// ---------------------------------------------------------------- 內部 Hom

///|
/// **雙模同態空間的維度**：Hom_{A,A}(M₁, M₂) = dim M₁·dim M₂ − rank(約束矩陣)。
/// 約束：f(e_k · m_i · e_l) = e_k · f(m_i) · e_l（對所有 k,l,i）。
pub fn bimod_hom_dim(m1 : Bimod, m2 : Bimod) -> Int32 {
  let d = m1.alg.dim
  let n1 = m1.dim
  let n2 = m2.dim
  let rows = d * d * n1 * n2
  let out = mat_zero(rows, n1 * n2)
  for k = 0; k < d; k = k + 1 {
    for l = 0; l < d; l = l + 1 {
      for i = 0; i < n1; i = i + 1 {
        for j = 0; j < n2; j = j + 1 {
          let row = ((k * d + l) * n1 + i) * n2 + j
          // 左邊：f(e_k·m_i·e_l) 的係數
          for q = 0; q < n1; q = q + 1 {
            let c = m1.left[k * n1 + i][q]
            if c != 0L {
              for p = 0; p < n1; p = p + 1 {
                let c2 = m1.right[l * n1 + q][p]
                if c2 != 0L {
                  out[row][p * n2 + j] = out[row][p * n2 + j] + c * c2
                }
              }
            }
          }
          // 右邊：e_k · f(m_i) · e_l 的係數
          for jp = 0; jp < n2; jp = jp + 1 {
            // e_k·(m_{jp})·e_l 在第 j 個座標的係數
            let mut c = 0L
            for r = 0; r < n2; r = r + 1 {
              c = c + m2.right[l * n2 + jp][r] * m2.left[k * n2 + r][j]
            }
            if c != 0L {
              out[row][i * n2 + jp] = out[row][i * n2 + jp] - c
            }
          }
        }
      }
    }
  }
  n1 * n2 - rank_q(out)
}

///|
/// 不變量空間的維度：M^A = {m ∈ M : e_k·m = m·e_k 對所有 k}。
pub fn bimod_invariant_dim(m : Bimod) -> Int32 {
  let d = m.alg.dim
  let out = mat_zero(d * m.dim, m.dim)
  for k = 0; k < d; k = k + 1 {
    for i = 0; i < m.dim; i = i + 1 {
      for p = 0; p < m.dim; p = p + 1 {
        out[k * m.dim + i][p] = m.left[k * m.dim + i][p] -
          m.right[k * m.dim + i][p]
      }
    }
  }
  m.dim - rank_q(out)
}

// ---------------------------------------------------------------- HH₀ 的共端描述

///|
/// 把 A 看成 Aᵉ = A ⊗ A^op 雙模的兩個版本：
///   左版本：α = a ⊗ b^op 作用為 α·m = a·m·b；
///   右版本：m·α = b·m·a。
/// dim(A ⊗_{Aᵉ} A) 應等於 HH₀(A) = dim A/[A,A]（定理 X2）。
pub fn bimod_hh_pair(a : FdAlg) -> Array[Bimod] {
  let d = a.dim
  let ae = alg_tensor(a, alg_op(a))
  let da = ae.dim
  let left = mat_zero(da * d, d)
  let right = mat_zero(da * d, d)
  for p = 0; p < d; p = p + 1 {
    for q = 0; q < d; q = q + 1 {
      let k = p * d + q
      for i = 0; i < d; i = i + 1 {
        for s = 0; s < d; s = s + 1 {
          let c = fd_coeff(a, p, i, s)
          if c != 0L {
            for r = 0; r < d; r = r + 1 {
              let c2 = fd_coeff(a, s, q, r)
              if c2 != 0L {
                left[k * d + i][r] = left[k * d + i][r] + c * c2
              }
            }
          }
        }
      }
      for i = 0; i < d; i = i + 1 {
        // 右作用 m·α = b·m·a：先 q 後 p
        for s = 0; s < d; s = s + 1 {
          let c = fd_coeff(a, q, i, s)
          if c != 0L {
            for r = 0; r < d; r = r + 1 {
              let c2 = fd_coeff(a, s, p, r)
              if c2 != 0L {
                // m·α = b·m·a
                right[k * d + i][r] = right[k * d + i][r] + c * c2
              }
            }
          }
        }
      }
    }
  }
  [
    bimod_make("A（Aᵉ-左）", ae, d, left, right),
    bimod_make("A（Aᵉ-右）", ae, d, left, right),
  ]
}

///|
/// 定理 X2 的算式：dim(A ⊗_{Aᵉ} A)。
pub fn hh0_by_coend(a : FdAlg) -> Int32 {
  let pair = bimod_hh_pair(a)
  bimod_tensor_dim(pair[0], pair[1])
}

// ---------------------------------------------------------------- 外部張量積與乘法性

///|
/// 外部張量積代數 A ⊗_k B 的 HH₀ **乘法性預測**：dim HH₀(A⊗B) 應等於 dim HH₀(A)·dim HH₀(B)。
pub fn xprod_hh0_product(a : FdAlg, b : FdAlg) -> Int32 {
  let ab = alg_tensor(a, b)
  hh_dim(ab, 0)
}

///|
/// 外部張量積代數的循環同調乘法性預測。
/// 當 A、B 皆半單時 A⊗B 半單，HC_n(A⊗B) = HC_n(A)·HC_n(B)（n 偶），n 奇時為 0。
pub fn xprod_hc_even(a : FdAlg, b : FdAlg, k : Int32) -> Int32 {
  let ab = alg_tensor(a, b)
  hc_dim_bicomplex(ab, 2 * k)
}

///|
/// 內部張量積的結構表（供 `moon run cmd/main -- xprod`）。
pub fn xprod_render() -> String {
  let sb = StringBuilder()
  for (a, _) in cyclic_samples() {
    if a.dim > 6 {
      continue
    }
    let reg = bimod_regular(a)
    sb.write_string(a.name)
    sb.write_string("：dim=" + a.dim.to_string())
    sb.write_string("、A⊗_A A=" + bimod_tensor_dim(reg, reg).to_string())
    if alg_aug_ok(a) {
      let triv = bimod_aug(a)
      sb.write_string("、A⊗_A k=" + bimod_tensor_dim(reg, triv).to_string())
      sb.write_string("、k⊗_A A=" + bimod_tensor_dim(triv, reg).to_string())
    } else {
      sb.write_string("、無增廣")
    }
    sb.write_string("、共端(Aᵉ)=" + hh0_by_coend(a).to_string())
    sb.write_string("、HH₀=" + hh0_by_commutators(a).to_string())
    sb.write_string("、Hom(A,A)=" + bimod_hom_dim(reg, reg).to_string())
    sb.write_string("、Z(A)=" + bimod_invariant_dim(reg).to_string())
    sb.write_string("\n")
  }
  sb.to_string()
}

///|
/// 外部張量積的乘法性表（A ⊗_k B）。
pub fn xprod_tensor_render() -> String {
  let sb = StringBuilder()
  let pairs : Array[(FdAlg, FdAlg)] = [
    (alg_polys(1), alg_polys(2)),
    (
      alg_direct_sum(alg_polys(1), alg_polys(1)),
      alg_direct_sum(alg_polys(1), alg_polys(1)),
    ),
    (alg_matrix(2), alg_polys(1)),
    (alg_cyclic_group(3), alg_polys(1)),
    (alg_cyclic_group(3), alg_cyclic_group(2)),
  ]
  for (a, b) in pairs {
    let ab = alg_tensor(a, b)
    sb.write_string("(" + a.name + ") ⊗ (" + b.name + ")")
    sb.write_string("：dim=" + ab.dim.to_string())
    sb.write_string("、HH₀=" + hh_dim(ab, 0).to_string())
    sb.write_string(
      "（預測 " + (hh_dim(a, 0) * hh_dim(b, 0)).to_string() + "）",
    )
    sb.write_string("、HC₂=" + hc_dim_bicomplex(ab, 2).to_string())
    sb.write_string(
      "（預測 " +
      (hc_dim_bicomplex(a, 2) * hc_dim_bicomplex(b, 2)).to_string() +
      "）\n",
    )
  }
  sb.to_string()
}
