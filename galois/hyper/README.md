# galois/hyper — 超立方體網絡群 Aut(Q_n) 的完整刻劃（B0007）

對應 `../../docs/B0007-定理體系.md`：**A-H1–A-H3、D-H1–D-H8、P-H1–P-H6、T41–T47、A44–A50**。
檢核：`moon run cmd/main -- hyper` ⇒ **29/29 通過**；另有一條輸出子命令 `hypertable`。

## 這一輪的「完整」在哪裡

B0005 只把 Q_n 當**圖**用（T31：生成樹數 τ、Laplacian 不變因子），群的部分沒做。
本套件給的是**完整刻劃**——兩側夾：

```
                   由上而下（候選）                      由下而上（窮舉）
Cand_n = { v ↦ π(v) ⊕ b : π ∈ S_n, b ∈ 𝔽₂ⁿ }        Aut_bfs(Q_n) = 回溯 + 鄰接一致性剪枝
                 |Cand_n| = 2ⁿ·n!                              |Aut_bfs| = ?
                        └──────────► 逐元素相等 ◄──────────────┘
                                        │
                          Aut(Q_n) ≅ 𝔽₂ⁿ ⋊ S_n ≅ C₂ ≀ S_n
```

只驗「候選 ⊆ Aut」是玩具（A-H1）；本套件對 n = 1..4 把兩側都算出來並比對**集合相等**，
再用第三條路徑（方向映射 + 平移，T43）給出半直積分解，三條路徑互指。

## 已獲得的定理

| 編號 | 內容 | 落點 |
|---|---|---|
| **T41** | **完整刻劃**：Aut(Q_n) = { v ↦ π(v) ⊕ b }（n = 1..4）；窮舉集與預測集逐元素相等，且 \|Aut\| = 2ⁿ·n!（2, 8, 48, 384）。負控制：Q₃ 上「交換 1↔2」是雙射但破壞鄰接 ⇒ 不在 Aut 中 | `checks.mbt`（`check_full_characterization`、`check_nonaffine_rejected`）、`hyper.mbt`（`automorphisms`、`predicted_automorphisms`、`perm_sets_equal`） |
| **T42** | 群階與軌道—穩定子：\|Aut\| = \|V\|·\|Stab(0)\| = 2ⁿ·n!（\|Stab(0)\| = n!）、\|Aut\| = \|E\|·\|Stab(邊)\| = n·2^{n−1}·2(n−1)! | `check_order_formula`、`edge_stabilizer_size` |
| **T43** | 方向映射 π: Aut → S_n **良定義**（每個自同構都給出座標雙射）、**是同態**、**核恰為平移群 𝔽₂ⁿ**（\|ker\| = 2ⁿ），故 Aut/T ≅ S_n、Aut = T ⋊ S_n | `check_direction_map`、`direction_map`、`direction_hom`、`direction_kernel` |
| **T44** | Cayley 刻劃 Q_n ≅ Cayley(𝔽₂ⁿ, {e_i})：x ~ y ⟺ x⊕y 為標準基向量；圖距離 = 漢明距離、n 正則、\|E\| = n·2^{n−1}、直徑 n、平移群正則 | `check_cayley`、`cayley_ok`、`dist_eq_hamming`、`translation_regular` |
| **T45** | (a) 摺疊 Q_n → Q_{n−1}：滿同態、纖維 = 一條邊、每條邊恰 2 原像。(b) 退化邊界：Q₁ = K₂（ℤ₂）、Q₂ = C₄（D₈：5 個共軛類、階數分布 1¹2⁵4²）、n = 1 的摺疊塌成一點（正面斷言） | `check_folding`、`check_degenerate_boundary`、`fold_is_hom`、`fold_fiber_edge_range` |
| **T46** | 邊置換 φ: Aut → Sym(E) 是同態、邊集可遷；\|ker φ\| = 1（n ≥ 2）但 = 2（n = 1：唯一一條邊被「交換兩端」的自同構固定） | `check_edge_action`、`edge_perm_hom`、`edge_perm_kernel_size`、`edge_orbit_size` |
| **T47** | 共軛類：Aut(Q_n) ≅ C₂ ≀ S_n 的共軛類 ↔ 一對無序分割 (α, β)，\|α\|+\|β\| = n ⇒ #Conj = Σ p(k)p(n−k) = 2, 5, 10, 20；各類大小之和 = 群階 | `check_conjugacy_formula`、`paired_partition_count`、`conjugacy_representatives` |

## 已實作的演算法

| 編號 | 名稱 | 複雜度 |
|---|---|---|
| A44 | 超立方體圖引擎：位元運算（`pow2i`／`popcnt`／`hamming`／`translate`）、鄰接、BFS 序、BFS 距離 | O(2ⁿ·n) |
| A45 | 回溯自同構窮舉（BFS 序 + 對所有已定像的鄰接一致性剪枝） | O(\|Aut\|·2ⁿ·n)（含剪枝） |
| A46 | 由上而下候選生成（座標置換回溯 × 2ⁿ 個平移）、位元重排 | O(2ⁿ·n!·2ⁿ) |
| A47 | 置換群工具箱：字串鍵 `Map` 索引、群公理（封閉／單位／反元）、元素階數、階數分布、共軛類代表與類大小 | 索引 O(\|G\|·\|V\|)；封閉性 O(\|G\|²·\|V\|) |
| A48 | 方向映射與同態檢核（先為每個元素算一次 π，再驗 π(στ) = π(σ)π(τ)） | O(\|G\|·\|V\|·n² + \|G\|²·n) |
| A49 | 邊索引表（`v×v` 查表）與邊置換；邊軌道、邊穩定子、核大小 | 建表 O(\|V\|²)；每次置換 O(\|E\|) |
| A50 | 摺疊同態、纖維結構與退化邊界檢核 | O(\|E\|) |

## 視角依賴關係圖

```
hyper ──▶ galois（Check / Report 插槽）
hyper ──▶ kk（T47 借用 B0006 的無序分割計數 partitions(k)，算 Σp(k)p(n−k)）
cmd/main ──▶ hyper（-- hyper、-- hypertable）
docs/B0007-定理體系.md §2–§8 ──▶ 本套件

B0005 的 T31（Q_n 的 τ、Laplacian 不變因子）──▶ 本套件的「群側」刻劃（圖側在 jacobian）
B0006 的 T38／T50（A⊗K ~ A、Künneth）──▶ 與本套件同期落地的 kk/outside.mbt（界外清單）
```

## 動線與接口

- **圖**：`pow2i`、`popcnt`、`hamming`、`adj_qn`、`hyper_edges`、`edge_key`、`edge_index_table`、`bfs_order`、`graph_dist`、`diameter`、`is_n_regular`、`cayley_ok`。
- **置換**：`perm_eq`、`perm_comp`、`perm_inv`、`perm_id`、`perm_key`、`perm_lex_less`、`perm_index`、`perm_match`、`perm_member`、`elem_order`、`order_histogram`（含 `order_histogram_render`）。
- **位元**：`permute_bits`、`translate`、`coord_perms`、`coord_subgroup`、`translations`。
- **兩側刻劃**：`predicted_automorphisms`（由上而下）、`automorphisms`（由下而上）、`perm_sets_equal`。
- **群結構**：`aut_closed`、`aut_has_identity`、`aut_has_inverses`、`direction_map`、`direction_hom`、`direction_kernel`、`is_translation`、`orbit`、`stabilizer_size`、`is_vertex_transitive`、`edge_orbit_size`、`edge_stabilizer_size`、`edge_perm_hom`、`edge_perm_kernel_size`、`edge_permutation`、`edge_permutation_tbl`、`conjugacy_representatives`、`conjugacy_class_sizes`、`conjugacy_sizes_sum`。
- **摺疊與公式**：`fold_vertex`、`fold_is_hom`、`fold_fiber_edge_range`、`fold_fiber_size`、`fact`、`predicted_order`、`edge_count_formula`。
- **檢核**：`hyper_report()`（29 條：T41×5、T42×4、T43×4、T44×4、T45×4、T46×4、T47×4）。

## 已知修正（保留在程式碼註解）

- **BUG-17**：型別應用一律用方括號 `Array[Int32]`（首版的 `Array<Int32>` 造成 70 個編譯錯誤）。
- **BUG-18**：`edge_key`（識別鍵）不可當作 `v×v` 查表的索引；查表用 `lo·v + hi`。
- **BUG-19**：穩定子的作用域要指名——「固定頂點 0」≠「固定邊 {0,1}」（A-H3）。
- **BUG-20**：`direction_map` 與 `edge_index_table` 必須提到雙迴圈外（15.7 秒 → 0.3 秒）。
- **BUG-21**：群論演算法的成本全在查表：字串鍵 `Map` 索引取代線性掃描。

## 規模上限（實測）

| 操作 | 上限 | 實測耗時（wasm） |
|---|---|---|
| `automorphisms(4)`（窮舉 384 個） | n ≤ 4（n = 5 時 \|Aut\| = 3840，回溯仍可行但檢核時間 ×10） | < 0.1 秒 |
| 群公理／同態／共軛類（\|G\|² 級） | \|G\| ≤ 500 | 全報告 1.5 秒 |
| 邊索引表 | \|V\|² ≤ 256（n ≤ 4） | O(\|V\|²) 一次性 |
