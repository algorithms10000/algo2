# galois/modular — 主同餘子群 Γ(n)/Γ₀(n)/Γ₁(n) 與 PSL₂(ℤ)（B0003）

對應 `../../docs/B0003-定理體系.md`：**D-C1–D-C5、P-Ca–P-C4、T13、T14、A20–A22**。

## 已獲得的定理

| 編號 | 內容 | 落點 |
|---|---|---|
| P-C1／P-C2 | Γ(N) ◁ SL₂(ℤ/N)；Γ₁(N) ◁ Γ₀(N)、Γ₀/Γ₁ ≅ (ℤ/N)^×，但 Γ₁ **不** ◁ SL₂（附共軛見證） | `sl2.mbt`、`check_normality` |
| P-C3 | −I ∈ Γ₀(N) 恆真；−I ∈ Γ₁(N)/Γ(N) ⟺ N\\|2 | `check_neg_one` |
| P-C4 | N ≥ 3：\\|PSL₂(ℤ/N)\\| = \\|SL₂\\|/2；N = 2：PSL₂ = SL₂ = S₃（6 階） | `check_psl2_order` |
| **T13** | [SL₂:Γ₀]=ψ(N)、[SL₂:Γ₁]=ψ(N)φ(N)、[SL₂:Γ]=ψ(N)φ(N)N | `arith.mbt`、`check_index_formulas` |
| **T14** | ν_∞、ν₂、ν₃、虧格公式；與古典虧格表 N = 1..24 全數相符 | `arith.mbt`、`check_genus` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A20 | `factorize`、`euler_phi`、`dedekind_psi`、`elliptic_two_count`、`elliptic_three_count`、`cusp_count`、`genus_x0` | 試除法 O(√N)，其餘 O(N) |
| A21 | `sl2_group`、`in_subgroup`、`index_by_bruteforce`、`subset_by_bruteforce`、`is_normal_by_bruteforce`、`conjugation_witness` | O(N⁴) 建群；指數 O(\\|G\\|)；正規 O(\\|G\\|²) |
| A22 | `congruence_context`（在 `registry/`） | O(12²·1152) |

## 依賴關係

```
modular ──▶ galois（檢核型別 Check/Report）
registry ──▶ modular, lattice, galois, context, bitset
cmd/main ──▶ registry, modular, lattice, galois, context
```

## 動線與接口

- 建立群與判定：`sl2_group(n)`、`in_subgroup(g, kind, level)`、`norm_mod`、`Sl2::mul/inverse`、
  `gamma_zero()/gamma_one()/gamma_level()/full_sl2()`（跨套件的 enum 建構入口）。
- 暴力核對：`index_by_bruteforce`、`subset_by_bruteforce`、`is_normal_by_bruteforce`、`conjugation_witness`。
- 解析不變量：`dedekind_psi`、`euler_phi`、`cusp_count`、`elliptic_two_count`、`elliptic_three_count`、
  `genus_x0`、`classical_genus`（外部期望值表）。
- 檢核：`modular_report(level_max)`（N = 2..6 的群論檢核 ＋ N = 1..25 的虧格檢核 ＋ 尖點與 level-1 特例）。

## 已知修正（保留在程式碼註解）

- **BUG-3**：MoonBit 的 `%` 對負數給負餘數 → `(a*d−b*c) % n == 1` 在 N = 2 少數一半元素；
  改為 `norm_mod(a*d−b*c, n) == norm_mod(1, n)`。
- **DOC-4**：−I 的歸屬與 |PSL₂| 必須分開處理（N = 2 時 −I ≡ I）。
