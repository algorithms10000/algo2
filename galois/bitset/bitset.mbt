///|
/// B0001 / bitset 套件
/// 稠密位元集（dense bit set），以 UInt64 字組為儲存單位。
/// 用途：把形式上下文 K=(A,S,R) 的 Φ/Ψ 交集成為「字組平行」運算，
/// 使複雜度帶 ⌈n/64⌉ 因子（見 docs/B0001-定理體系.md §6 設計要點 1）。
///
/// 不變量（invariant）：words.length() == (n + 63) / 64，且第 n 位以上恆為 0。
const WORD_BITS : Int32 = 64

///|
const ALL_ONES : UInt64 = 0xFFFF_FFFF_FFFF_FFFFUL

///|
pub struct BitSet {
  words : Array[UInt64]
  n : Int32
}

///|
/// 建立 n 位元全空集合。
pub fn BitSet::new(n : Int32) -> BitSet {
  let w = if n == 0 { 0 } else { (n + WORD_BITS - 1) / WORD_BITS }
  { words: Array::make(w, 0UL), n, }
}

///|
/// 建立 n 位元全滿集合。
pub fn BitSet::full(n : Int32) -> BitSet {
  let r = BitSet::new(n)
  for i = 0; i < r.words.length(); i = i + 1 {
    r.words[i] = ALL_ONES
  }
  r.mask_tail()
  r
}

///|
/// 建立只含第 i 位的集合。
pub fn BitSet::singleton(n : Int32, i : Int32) -> BitSet {
  let r = BitSet::new(n)
  r.set(i)
  r
}

///|
/// 由索引陣列建立集合（重複索引自動去重）。
pub fn BitSet::from_indices(n : Int32, xs : Array[Int32]) -> BitSet {
  let r = BitSet::new(n)
  for i = 0; i < xs.length(); i = i + 1 {
    r.set(xs[i])
  }
  r
}

///|
/// 遮掉最後一個字組中超出 n 的位元，維持不變量。
fn BitSet::mask_tail(self : BitSet) -> Unit {
  let rem = self.n % WORD_BITS
  if rem != 0 && self.words.length() > 0 {
    let last = self.words.length() - 1
    let keep : UInt64 = (1UL << rem) - 1UL
    self.words[last] = self.words[last] & keep
  }
}

///|
/// 位元數（= 集合大小 n 的定義域大小）。
pub fn BitSet::size(self : BitSet) -> Int32 {
  self.n
}

///|
/// 第 i 位是否為 1。
pub fn BitSet::get(self : BitSet, i : Int32) -> Bool {
  if i < 0 || i >= self.n {
    abort("BitSet::get 越界")
  }
  let word : UInt64 = self.words[i / WORD_BITS]
  let shifted : UInt64 = word >> (i % WORD_BITS)
  (shifted & 1UL) == 1UL
}

///|
/// 置位。
pub fn BitSet::set(self : BitSet, i : Int32) -> Unit {
  if i < 0 || i >= self.n {
    abort("BitSet::set 越界")
  }
  let word_index = i / WORD_BITS
  let bit = i % WORD_BITS
  let old : UInt64 = self.words[word_index]
  self.words[word_index] = old | (1UL << bit)
}

///|
/// 清位。
pub fn BitSet::unset(self : BitSet, i : Int32) -> Unit {
  if i < 0 || i >= self.n {
    abort("BitSet::unset 越界")
  }
  let word_index = i / WORD_BITS
  let bit = i % WORD_BITS
  let old : UInt64 = self.words[word_index]
  let mask : UInt64 = ALL_ONES ^ (1UL << bit)
  self.words[word_index] = old & mask
}

///|
/// 依 v 置位或清位。
pub fn BitSet::put(self : BitSet, i : Int32, v : Bool) -> Unit {
  if v {
    self.set(i)
  } else {
    self.unset(i)
  }
}

///|
/// 基數（popcount 總和）。
pub fn BitSet::count(self : BitSet) -> Int32 {
  let mut s = 0
  for i = 0; i < self.words.length(); i = i + 1 {
    s = s + self.words[i].popcnt()
  }
  s
}

///|
pub fn BitSet::is_empty(self : BitSet) -> Bool {
  self.count() == 0
}

///|
pub fn BitSet::is_full(self : BitSet) -> Bool {
  self.count() == self.n
}

///|
/// 深拷貝。
pub fn BitSet::copy(self : BitSet) -> BitSet {
  let r = BitSet::new(self.n)
  for i = 0; i < self.words.length(); i = i + 1 {
    r.words[i] = self.words[i]
  }
  r
}

///|
pub fn BitSet::equals(self : BitSet, other : BitSet) -> Bool {
  if self.n != other.n {
    abort("BitSet::equals 位元長度不一致")
  }
  for i = 0; i < self.words.length(); i = i + 1 {
    if self.words[i] != other.words[i] {
      return false
    }
  }
  true
}

///|
/// self ⊆ other。
pub fn BitSet::subset_of(self : BitSet, other : BitSet) -> Bool {
  if self.n != other.n {
    abort("BitSet::subset_of 位元長度不一致")
  }
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    let extra : UInt64 = a & (ALL_ONES ^ b)
    if extra != 0UL {
      return false
    }
  }
  true
}

///|
/// 交集（新物件）。
pub fn BitSet::intersect(self : BitSet, other : BitSet) -> BitSet {
  if self.n != other.n {
    abort("BitSet::intersect 位元長度不一致")
  }
  let r = BitSet::new(self.n)
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    r.words[i] = a & b
  }
  r
}

///|
/// 聯集（新物件）。
pub fn BitSet::union(self : BitSet, other : BitSet) -> BitSet {
  if self.n != other.n {
    abort("BitSet::union 位元長度不一致")
  }
  let r = BitSet::new(self.n)
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    r.words[i] = a | b
  }
  r
}

///|
/// 差集 self \ other（新物件）。
pub fn BitSet::minus(self : BitSet, other : BitSet) -> BitSet {
  if self.n != other.n {
    abort("BitSet::minus 位元長度不一致")
  }
  let r = BitSet::new(self.n)
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    r.words[i] = a & (ALL_ONES ^ b)
  }
  r
}

///|
/// 補集（在 n 位元範圍內）。
pub fn BitSet::complement(self : BitSet) -> BitSet {
  let r = BitSet::new(self.n)
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    r.words[i] = a ^ ALL_ONES
  }
  r.mask_tail()
  r
}

///|
/// 就地聯集。
pub fn BitSet::union_inplace(self : BitSet, other : BitSet) -> Unit {
  if self.n != other.n {
    abort("BitSet::union_inplace 位元長度不一致")
  }
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    self.words[i] = a | b
  }
}

///|
/// 就地差集。
pub fn BitSet::minus_inplace(self : BitSet, other : BitSet) -> Unit {
  if self.n != other.n {
    abort("BitSet::minus_inplace 位元長度不一致")
  }
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    self.words[i] = a & (ALL_ONES ^ b)
  }
}

///|
/// 依遞增順序取出所有 1 的索引。
pub fn BitSet::ones(self : BitSet) -> Array[Int32] {
  let out : Array[Int32] = []
  for i = 0; i < self.n; i = i + 1 {
    if self.get(i) {
      out.push(i)
    }
  }
  out
}

///|
/// 前 k 位（索引 0..k-1）與 other 相同？
/// 供 A2（NextClosure）之 lectic 序比較使用。
pub fn BitSet::prefix_equal(self : BitSet, other : BitSet, k : Int32) -> Bool {
  if self.n != other.n {
    abort("BitSet::prefix_equal 位元長度不一致")
  }
  let mut i = 0
  while i < k {
    if self.get(i) != other.get(i) {
      return false
    }
    i = i + 1
  }
  true
}

///|
/// 前 k 位中所有 1 的索引。
pub fn BitSet::prefix_ones(self : BitSet, k : Int32) -> Array[Int32] {
  let out : Array[Int32] = []
  let mut i = 0
  while i < k && i < self.n {
    if self.get(i) {
      out.push(i)
    }
    i = i + 1
  }
  out
}

///|
/// 轉為索引陣列的字串表示，例如 "{0,2,5}"。
pub fn BitSet::render(self : BitSet) -> String {
  let sb = StringBuilder()
  sb.write_string("{")
  let ids = self.ones()
  for i = 0; i < ids.length(); i = i + 1 {
    if i > 0 {
      sb.write_string(",")
    }
    sb.write_string(ids[i].to_string())
  }
  sb.write_string("}")
  sb.to_string()
}

///|
/// 便捷：回傳自身與第 i 位的聯集（新物件）。
pub fn BitSet::plus_bit(self : BitSet, i : Int32) -> BitSet {
  let r = self.copy()
  r.set(i)
  r
}

///|
/// 便捷：回傳自身去掉第 i 位的集合（新物件）。
pub fn BitSet::minus_bit(self : BitSet, i : Int32) -> BitSet {
  let r = self.copy()
  r.unset(i)
  r
}

///|
/// 由 n 位元遮罩整數建構集合（第 i 位 ⇔ 索引 i），僅供 n ≤ 20 的子集枚舉使用。
pub fn BitSet::from_mask(n : Int32, mask : Int32) -> BitSet {
  let r = BitSet::new(n)
  for i = 0; i < n; i = i + 1 {
    let shifted = mask >> i
    if (shifted & 1) == 1 {
      r.set(i)
    }
  }
  r
}

///|
/// 以遮罩整數表示集合（索引 i → 第 i 位），僅供 n ≤ 20 的子集枚舉使用。
pub fn BitSet::to_mask(self : BitSet) -> Int32 {
  if self.n > 20 {
    abort("BitSet::to_mask 僅支援 n ≤ 20")
  }
  let mut acc = 0
  for i = 0; i < self.n; i = i + 1 {
    if self.get(i) {
      acc = acc + (1 << i)
    }
  }
  acc
}

///|
/// 冪集 2^{0..n-1} 的全部子集，依遮罩整數遞增。需 n ≤ 20。
pub fn all_subsets(n : Int32) -> Array[BitSet] {
  if n > 20 {
    abort("all_subsets 僅支援 n ≤ 20")
  }
  let total = 1 << n
  let out : Array[BitSet] = []
  for mask = 0; mask < total; mask = mask + 1 {
    out.push(BitSet::from_mask(n, mask))
  }
  out
}

///|
/// 冪集全部子集，依**基數遞增**、同基數時遮罩遞增。需 n ≤ 20。
/// 此順序使 A3（偽內涵枚舉，P6）的正確性成立：處理 P 時所有真子集已判定。
pub fn subsets_by_cardinality(n : Int32) -> Array[BitSet] {
  if n > 20 {
    abort("subsets_by_cardinality 僅支援 n ≤ 20")
  }
  let total = 1 << n
  let buckets : Array[Array[Int32]] = []
  for k = 0; k <= n; k = k + 1 {
    buckets.push([])
  }
  for mask = 0; mask < total; mask = mask + 1 {
    let mut bits = 0
    let mut cur = mask
    while cur != 0 {
      cur = cur & (cur - 1)
      bits = bits + 1
    }
    buckets[bits].push(mask)
  }
  let out : Array[BitSet] = []
  for k = 0; k <= n; k = k + 1 {
    let b = buckets[k]
    for i = 0; i < b.length(); i = i + 1 {
      out.push(BitSet::from_mask(n, b[i]))
    }
  }
  out
}

///|
/// 對稱差（xor）：self △ other。GF(2) 高斯消去的基本運算（B0002 A13）。
pub fn BitSet::xor(self : BitSet, other : BitSet) -> BitSet {
  if self.n != other.n {
    abort("BitSet::xor 位元長度不一致")
  }
  let r = BitSet::new(self.n)
  for i = 0; i < self.words.length(); i = i + 1 {
    let a : UInt64 = self.words[i]
    let b : UInt64 = other.words[i]
    r.words[i] = a ^ b
  }
  r
}

///|
/// 最高位 1 的索引；全空回傳 None。
pub fn BitSet::highest_bit(self : BitSet) -> Int32? {
  let mut i = self.words.length() - 1
  while i >= 0 {
    let w : UInt64 = self.words[i]
    if w != 0UL {
      let mut bit = WORD_BITS - 1
      while bit >= 0 {
        let shifted : UInt64 = w >> bit
        if (shifted & 1UL) == 1UL {
          let idx = i * WORD_BITS + bit
          return Some(idx)
        }
        bit = bit - 1
      }
    }
    i = i - 1
  }
  None
}
