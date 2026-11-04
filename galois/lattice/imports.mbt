///|
/// lattice 套件對 galois 套件的符號別名（集中一處，避免各檔重複 using）。
/// 型別須以 `type` 形式別名；方法呼叫一律寫 `@galois.Check::make(...)`。
using @galois {type Check, type Report, closure_stmts}
