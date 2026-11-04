///|
/// B0003 / modular 套件：**SL₂(ℤ/N) 的有限群模型**（D-C5、T13 的暴力核對、A21）
/// 對應 docs/B0003-定理體系.md §3。
///
/// 同餘子群 Γ ⊂ SL₂(ℤ) 只依賴元素 mod N 的行為（Γ(N) 是 SL₂(ℤ) → SL₂(ℤ/N) 的核），
/// 因此所有「包含、指數、正規性」都可以在**有限群** SL₂(ℤ/N) 上暴力判定——
/// 這是 T13 的封閉公式與群論事實之間的獨立對照。

///|
/// SL₂(ℤ/N) 的元素：4 個座標各取 0..N−1，且 ad − bc ≡ 1 (mod N)。
pub struct Sl2 {
  n : Int32
  a : Int32
  b : Int32
  c : Int32
  d : Int32
}

///|
pub fn Sl2::key(self : Sl2) -> String {
  self.a.to_string() +
  "," +
  self.b.to_string() +
  "," +
  self.c.to_string() +
  "," +
  self.d.to_string()
}

///|
/// 乘法（mod N）。
pub fn Sl2::mul(self : Sl2, other : Sl2) -> Sl2 {
  let n = self.n
  {
    n,
    a: norm_mod(self.a * other.a + self.b * other.c, n),
    b: norm_mod(self.a * other.b + self.b * other.d, n),
    c: norm_mod(self.c * other.a + self.d * other.c, n),
    d: norm_mod(self.c * other.b + self.d * other.d, n),
  }
}

///|
/// 逆元素：[[a,b],[c,d]]⁻¹ = [[d,−b],[−c,a]]（det = 1）。
pub fn Sl2::inverse(self : Sl2) -> Sl2 {
  let n = self.n
  {
    n,
    a: norm_mod(self.d, n),
    b: norm_mod(-self.b, n),
    c: norm_mod(-self.c, n),
    d: norm_mod(self.a, n),
  }
}

///|
/// 是否為 Γ₀(N) 的元素（c ≡ 0）。
pub fn Sl2::in_gamma0(self : Sl2) -> Bool {
  self.c % self.n == 0
}

///|
/// 是否為 Γ₁(N) 的元素（c ≡ 0、a ≡ d ≡ 1）。
pub fn Sl2::in_gamma1(self : Sl2) -> Bool {
  self.c % self.n == 0 && self.a % self.n == 1 && self.d % self.n == 1
}

///|
/// 是否為 Γ(N) 的元素（≡ I）。
pub fn Sl2::in_gamma_level(self : Sl2) -> Bool {
  self.a % self.n == 1 &&
  self.b % self.n == 0 &&
  self.c % self.n == 0 &&
  self.d % self.n == 1
}

///|
/// 取模到 [0, n)（MoonBit 的 `%` 對負數給負餘數，這裡一律歸一化）。
pub fn norm_mod(x : Int32, n : Int32) -> Int32 {
  let r = x % n
  if r < 0 {
    r + n
  } else {
    r
  }
}

///|
/// 建立 SL₂(ℤ/N) 的元素（座標自動歸一化）——供其他套件在有限群裡做 BFS／共軛。
pub fn sl2_make(n : Int32, a : Int32, b : Int32, c : Int32, d : Int32) -> Sl2 {
  {
    n,
    a: norm_mod(a, n),
    b: norm_mod(b, n),
    c: norm_mod(c, n),
    d: norm_mod(d, n),
  }
}

///|
/// 列舉 SL₂(ℤ/N) 的全部元素。
///
/// ＊開發期修正（BUG-3）＊ 首版寫 `(a*d - b*c) % n == 1`：當 `a*d - b*c` 為負時，
/// MoonBit 的 `%` 給出負餘數（例如 −1 % 2 = −1），於是 N = 2 只數到 3 個元素（正確是 6 個）。
/// 檢核器在**最小的例子**上就抓到，故改為 `norm_mod(a*d - b*c, n) == norm_mod(1, n)`。
pub fn sl2_group(n : Int32) -> Array[Sl2] {
  let out : Array[Sl2] = []
  let one = norm_mod(1, n)
  for a = 0; a < n; a = a + 1 {
    for b = 0; b < n; b = b + 1 {
      for c = 0; c < n; c = c + 1 {
        for d = 0; d < n; d = d + 1 {
          if norm_mod(a * d - b * c, n) == one {
            out.push({ n, a, b, c, d, })
          }
        }
      }
    }
  }
  out
}

///|
/// 子群的型別：Γ₀(N)、Γ₁(N)、Γ(N)，以及整個 SL₂(ℤ)。
pub enum SubgroupType {
  GammaZero
  GammaOne
  GammaLevel
  FullSl2
}

///|
pub fn SubgroupType::label(self : SubgroupType) -> String {
  match self {
    GammaZero => "Γ₀"
    GammaOne => "Γ₁"
    GammaLevel => "Γ"
    FullSl2 => "SL₂(ℤ)"
  }
}

///|
/// 同餘子群 Γ_type(level) 的成員判定（元素須在 SL₂(ℤ/N) 中，N 為其位準的倍數）。
pub fn in_subgroup(g : Sl2, kind : SubgroupType, level : Int32) -> Bool {
  match kind {
    GammaZero => g.c % level == 0
    GammaOne => g.c % level == 0 && g.a % level == 1 && g.d % level == 1
    GammaLevel =>
      g.a % level == 1 &&
      g.b % level == 0 &&
      g.c % level == 0 &&
      g.d % level == 1
    FullSl2 => true
  }
}

///|
/// 以暴力計算指數 [SL₂(ℤ) : Γ_type(level)]：
///   |SL₂(ℤ/N)| / #{g ∈ SL₂(ℤ/N) : g 滿足條件}，其中 N = level。
pub fn index_by_bruteforce(kind : SubgroupType, level : Int32) -> Int32 {
  let group = sl2_group(level)
  let mut count = 0
  for i = 0; i < group.length(); i = i + 1 {
    if in_subgroup(group[i], kind, level) {
      count = count + 1
    }
  }
  if count == 0 {
    abort("index_by_bruteforce：同餘子群模 N 的元素數為 0")
  }
  group.length() / count
}

///|
/// 包含判定 Γ_type1(l1) ⊆ Γ_type2(l2)：在 SL₂(ℤ/L) 上暴力檢查（L = lcm(l1,l2) 的倍數）。
/// 這裡要求 L 同時是兩者位準的倍數，且 L 不超過預算（呼叫端負責）。
pub fn subset_by_bruteforce(
  kind1 : SubgroupType,
  l1 : Int32,
  kind2 : SubgroupType,
  l2 : Int32,
  l : Int32,
) -> Bool {
  if l % l1 != 0 || l % l2 != 0 {
    abort("subset_by_bruteforce：位準 L 必須同時是 l1、l2 的倍數")
  }
  let group = sl2_group(l)
  for i = 0; i < group.length(); i = i + 1 {
    let g = group[i]
    if in_subgroup(g, kind1, l1) && !in_subgroup(g, kind2, l2) {
      return false
    }
  }
  true
}

///|
/// 正規性：Γ_type(level) 是否在 SL₂(ℤ/N) 中正規（有限群上暴力共軛檢驗，O(|G|²)）。
pub fn is_normal_by_bruteforce(
  kind : SubgroupType,
  level : Int32,
  n : Int32,
) -> Bool {
  if n % level != 0 {
    abort("is_normal_by_bruteforce：N 必須是 level 的倍數")
  }
  let group = sl2_group(n)
  for i = 0; i < group.length(); i = i + 1 {
    let g = group[i]
    if !in_subgroup(g, kind, level) {
      continue
    }
    for j = 0; j < group.length(); j = j + 1 {
      let x = group[j]
      let conj = x.mul(g).mul(x.inverse())
      if !in_subgroup(conj, kind, level) {
        return false
      }
    }
  }
  true
}

///|
/// 共軛見證：找出 g ∈ Γ_type(level) 與 x ∈ SL₂(ℤ/N) 使 x g x⁻¹ ∉ Γ_type(level)。
/// 回傳 None 表示找不到（即在該有限群中正規）。
pub fn conjugation_witness(
  kind : SubgroupType,
  level : Int32,
  n : Int32,
) -> (Sl2, Sl2, Sl2)? {
  let group = sl2_group(n)
  for i = 0; i < group.length(); i = i + 1 {
    let g = group[i]
    if !in_subgroup(g, kind, level) {
      continue
    }
    for j = 0; j < group.length(); j = j + 1 {
      let x = group[j]
      let conj = x.mul(g).mul(x.inverse())
      if !in_subgroup(conj, kind, level) {
        return Some((g, x, conj))
      }
    }
  }
  None
}

///|
/// 跨套件建構子（MoonBit 的 enum 值不可在他套件直接建構，故提供函式入口）。
pub fn gamma_zero() -> SubgroupType {
  GammaZero
}

///|
pub fn gamma_one() -> SubgroupType {
  GammaOne
}

///|
pub fn gamma_level() -> SubgroupType {
  GammaLevel
}

///|
pub fn full_sl2() -> SubgroupType {
  FullSl2
}
