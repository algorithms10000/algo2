///|
/// B0010 / bc 套件：**Baum–Connes 的界外清單（BC1–BC8）**
///
/// 沿用 B0006 的 A-K5（界外不得以綠燈冒充）。每一條記錄必須帶：
///   * `status`：文獻現況（已證／已否／開放／未同儕審查的宣稱）；
///   * `evidence`：來源（arXiv 編號、年份）；
///   * `inside_part`：本引擎**真的算得出**的那一塊；
///   * `decides`：本引擎是否對整條命題下判斷（界外者一律 false）；
///   * `value_if_true` / `value_if_false`：界外且不決定時，**兩個可能的答案**都要寫出來，
///     使「不決定」成為可檢核的斷言（兩值皆與我們所有可執行檢核相容）。
///
/// 狀態是 2026 年 9 月的快照；本套件不隨文獻更新，`Dev.txt` 記錄快照日期。

///|
/// 一條 Baum–Connes 界外記錄。
pub struct BcItem {
  id : String
  title : String
  status : String
  evidence : String
  inside_part : String
  decides : Bool
  value_if_true : String
  value_if_false : String
}

///|
/// 界外清單本體。
pub fn bc_items() -> Array[BcItem] {
  [
    {
      id: "BC1",
      title: "無係數 Baum–Connes 對任意 second-countable locally compact 群",
      status: "開放（截至 2026-09 無已知反例）",
      evidence: "arXiv:2610.01802《The Baum-Connes conjecture: a concise course》(2026)：as of September 2026 no counter-example is known（無係數版）",
      inside_part: "有限群（T81）與循環群 ℤ/n（T83）的 μ_0 已判為同構；無撓可算樣本 ℤ 的 μ_i 兩側同為 (ℤ,ℤ)（T87 接縫）",
      decides: false,
      value_if_true: "猜想成立：對所有 G，μ_i^G 皆為同構",
      value_if_false: "存在 G 使 μ_i^G 不同構；且不影響本引擎已判定的有限群／循環群樣本（它們的秩計算與 μ 是否全域滿射無關）",
    },
    {
      id: "BC2",
      title: "有係數 Baum–Connes（係數在任意 G-代數 A 中）",
      status: "已否",
      evidence: "HLS02 反例（Higson–Lafforgue–Skandalis）；arXiv:2610.01802 指出有係數版（Conjecture 7.18）已被推翻",
      inside_part: "本引擎的樣本全部是係數 A = ℂ 的情形；T81–T85 的判定不觸及係數推廣",
      decides: false,
      value_if_true: "（不適用：已被反例否證）",
      value_if_false: "有係數版不成立；無係數版是否成立仍獨立開放（BC1）",
    },
    {
      id: "BC3",
      title: "μ 單射 ⇒ Novikov 高階簽名不變量（有撓群的同倫不變性）",
      status: "已證（條件式蘊含）",
      evidence: "單射性 ⇒ 高階簽名同倫不變（Baum–Connes 的標準推論，見 Lück《Assembly Maps》arXiv:1805.00226 的敘述）",
      inside_part: "本引擎只能檢核單射性的**代數截面**：特徵表滿秩（T81–T85）。L-理論與簽名算子不在界內",
      decides: false,
      value_if_true: "單射成立 ⇒ Novikov 猜想對該群成立",
      value_if_false: "若某群單射失效，高階簽名可能不再是同倫不變量（本引擎無 L-理論，無法給出見證）",
    },
    {
      id: "BC4",
      title: "SL_n(ℤ), n ≥ 3 的滿射性",
      status: "開放（單射性已知）",
      evidence: "Lück–Reich 綜述：SL_n(ℤ), n ≥ 3 的 μ 單射已知，滿射性仍開放",
      inside_part: "有限商 SL₂(ℤ/2) ≅ S₃ 已在 T85 判同構（整群 SL₂(ℤ) 是無限群，本引擎的 ℂG 只在有限群上可算）",
      decides: false,
      value_if_true: "μ 滿射（則 SL_n(ℤ) 滿足完整 Baum–Connes）",
      value_if_false: "μ 不滿射：K_0(C*_r SL_n(ℤ)) 有不在像中的類；兩值都與 T85 的有限商結果相容",
    },
    {
      id: "BC5",
      title: "粗 Baum–Connes（coarse assembly，度量空間版）",
      status: "已否（奇度）",
      evidence: "Kitsios–Schick–Vigolo 2025, arXiv:2504.21811：unified warped cones 上粗組裝映射在奇度不滿射（Theorem C）",
      inside_part: "本引擎只處理離散群的群代數與其 K-群；粗版是**不同命題**（warped cone 的粗結構），界內沒有任何截面",
      decides: false,
      value_if_true: "（不適用：奇度已被否）",
      value_if_false: "粗版奇度不滿射；群版 Baum–Connes 不因此被否（兩者不可互相推出）",
    },
    {
      id: "BC6",
      title: "a-T-menable（Higson–Kasparov）與雙曲群、almost connected 群",
      status: "已證",
      evidence: "Higson–Kasparov（a-T-menable）；Connes–Kasparov、Chabert–Echterhoff–Nest（almost connected）；雙曲群（MV98）",
      inside_part: "ℤ 屬 a-T-menable：T87 用 C*_r ℤ = C(S¹) 與 Toeplitz 六項正合列獨立核對了兩側 K-群 (ℤ,ℤ)",
      decides: false,
      value_if_true: "這些類別的 μ 是同構",
      value_if_false: "（若文獻結論被推翻，本引擎的有限樣本仍獨立成立，故不受影響）",
    },
    {
      id: "BC7",
      title: "2026-09 的 AI 輔助「三個反例」宣稱（無理 trace 投影、reduced assembly 殺無限階類）",
      status: "宣稱（未同儕審查，不可當事實）",
      evidence: "VibeMathed 條目（2026-09，review pending）",
      inside_part: "本引擎不採用該宣稱；T81–T85 的同構判定與「是否存在反例」邏輯獨立",
      decides: false,
      value_if_true: "若宣稱被證實：無係數版 Baum–Connes 被否，則 BC1 的值取「存在反例」",
      value_if_false: "若宣稱被駁回：BC1 維持「開放、無已知反例」",
    },
    {
      id: "BC8",
      title: "無撓假設對 Kadison–Kaplansky 的必要性",
      status: "已證（本引擎可檢核其代數截面）",
      evidence: "BC 滿射 + 無撓 ⇒ 群代數無非平凡冪等元（Kadison–Kaplansky）；反向：有撓群必有非平凡冪等元",
      inside_part: "T86：ℂ[ℤ] 在支撐 [−2,2]、係數 {−1,0,1} 內窮舉無非平凡冪等元（並以次數論證封閉）；負控制 ℂ[ℤ/2] 的 (1+g)/2 確實冪等",
      decides: false,
      value_if_true: "無撓是必要條件：有撓即有非平凡冪等元（T86 負控制）",
      value_if_false: "（此條已在界內被本引擎獨立檢核到代數層面，不屬不決定）",
    },
  ]
}

///|
/// 界外清單的合規性檢核：每條都有 status／evidence／inside_part／兩值，
/// 且 `decides` 為 false 的條目不得同時宣稱已判定。
pub fn bc_items_compliant() -> Bool {
  let mut ok = true
  for it in bc_items() {
    if it.title == "" ||
      it.status == "" ||
      it.evidence == "" ||
      it.inside_part == "" {
      ok = false
    }
    if it.value_if_true == "" || it.value_if_false == "" {
      ok = false
    }
    if !it.decides && it.value_if_true == it.value_if_false {
      ok = false
    }
  }
  // 覆蓋率：BC1–BC8 都在（不得偷偷合併或刪除）
  let want : Array[String] = [
    "BC1", "BC2", "BC3", "BC4", "BC5", "BC6", "BC7", "BC8",
  ]
  for id in want {
    let mut found = false
    for it in bc_items() {
      if it.id == id {
        found = true
      }
    }
    if !found {
      ok = false
    }
  }
  ok
}
