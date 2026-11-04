///|
/// B0002 / matroid 套件：負控制樣本（T8）
///
/// 路徑圖 {0,…,n-1} 上的**區間凸包**（convex closure）是一個閉包算子
/// （擴張、單調、冪等），但**不是**擬陣閉包：它違反交換公理 X5。
/// 反例（n ≥ 4）：X = {0}、y = 1、z = 3：
///   cl(X ∪ {z}) = cl({0,3}) = {0,1,2,3} ∋ y，但 cl(X ∪ {y}) = cl({0,1}) = {0,1} ∌ z。
///
/// 這個樣本的作用是**證明檢核器不是恆真綠燈**（工程約束：嚴禁恆真永綠假象）：
/// `check_exchange` 必須在此 FAIL，`check_geometric` 也不得以擬陣身份通過。

///|
/// 區間凸包：取集合的最小值與最大值，填滿其間所有點。
pub fn interval_closure(n : Int32, x : @bitset.BitSet) -> @bitset.BitSet {
  if x.size() != n {
    abort("interval_closure 位元長度不一致")
  }
  let out = @bitset.BitSet::new(n)
  let ids = x.ones()
  if ids.length() == 0 {
    return out
  }
  let lo = ids[0]
  let hi = ids[ids.length() - 1]
  for i = lo; i <= hi; i = i + 1 {
    out.set(i)
  }
  out
}

///|
/// 負控制報告：交換公理必須 FAIL（若 PASS，代表檢核器失效）。
pub fn interval_report(n : Int32) -> @galois.Report {
  let r = @galois.Report::new()
  let check = check_exchange(n, fn(x) { interval_closure(n, x) })
  r.add(check)
  r
}
