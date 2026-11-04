# Çekirdek Oynanış

> **Özet:** Bundoku, N×N tahtada N tavşanın klasik Star Battle kısıtlarıyla yerleştirildiği bir mantık
> bulmacasıdır. Bu belge kuralları, tahta modelini, dokunma davranışını, ipucu hattını ve can/yıldız hesabını
> koddaki gerçek davranışa göre tanımlar. Kaynak: [`scripts/gameplay/board_view.gd`](../../scripts/gameplay/board_view.gd),
> [`scripts/gameplay/hint_solver.gd`](../../scripts/gameplay/hint_solver.gd),
> [`scripts/core/game_state.gd`](../../scripts/core/game_state.gd),
> [`scripts/ui/main_controller.gd`](../../scripts/ui/main_controller.gd).

Durum etiketleri: **Mevcut**, **Planlanan**, **Açık**.

## 1. Kurallar (Mevcut)

Tahta N×N'dir (N = 4…9, veritabanındaki `size`). Amaç N tavşanı şu üç kısıtla yerleştirmektir:

| # | Kural | Kodda karşılığı |
|---|---|---|
| 1 | Her **satırda** tam olarak 1 tavşan | `_find_conflicts_for_cell()` / `_recheck_conflicts_and_win()` `same_row` |
| 2 | Her **sütunda** tam olarak 1 tavşan | aynı fonksiyon `same_col` |
| 3 | Her **bölgede** (renk) tam olarak 1 tavşan | `same_reg` (`region_map[r][c]` kimliği) |
| 4 | Tavşanlar **temas etmez**: yatay, dikey ve çapraz komşuluk yasak | `touching = absi(Δr) <= 1 and absi(Δc) <= 1` |
| 5 | Ön yerleştirilmiş (kilitli) tavşanlar taşınamaz | `prefill_set.has(cell)` erken çıkışları |

Bölge haritası `regionMap` N×N tamsayı matrisidir; bölge kimlikleri 0…N-1 aralığındadır ve her bölge en az bir
hücre içerir. Kazanma koşulu: tavşan sayısı N'e eşit **ve** `conflict_cells` boş
(`_recheck_conflicts_and_win()`). Bu iki koşul, kural 1–4 birlikte sağlandığında tam çözümü garanti eder.

## 2. Tahta modeli

| Kavram | Değerler | Kaynak |
|---|---|---|
| Hücre durumu | `0` boş, `1` X, `2` tavşan | `board_view.gd` `STATE_EMPTY/STATE_CROSS/STATE_BUNNY` |
| Hücre kaynağı | `manual`, `auto`, `prefill`, `draft`, `hint` | `SOURCE_*` sabitleri |
| Otomatik X sahipliği | `auto_cross_owners[r][c]` = bu X'i üreten tavşan konumları | `_apply_auto_cross_for_bunny()` |
| Çakışma | `conflict_cells` + `conflict_pairs` (kırmızı çizgi) | `_recheck_conflicts_and_win()` |
| Geri alma yığını | En fazla **60** anlık görüntü | `_push_undo()` |
| Vurgu | İpucunun gösterdiği hücreler, nabız animasyonu | `highlight_cells` |

## 3. Etkileşim modeli

| Girdi | Sonuç | Kod |
|---|---|---|
| Boş hücreye tek dokunuş | X koyar ve **sürükleme modunu başlatır**; parmak gezdirilen boş hücreler X olur | `_handle_single_tap_or_start_drag()`, `_handle_drag_over_cell()` |
| X'li hücreye tek dokunuş | X'i siler, sürükleme silme moduna geçer | aynı fonksiyon |
| Tavşana tek dokunuş | Tavşanı kaldırır (X'e çevirmez) | `_remove_bunny_at()` |
| Aynı hücreye 300 ms içinde ikinci dokunuş | Tavşan koyar; tavşan varsa kaldırır | `_handle_double_tap()`, `DOUBLE_TAP_MS = 300` |
| Kilitli (prefill) hücre | Hiçbir girdi kabul edilmez | tüm işleyicilerde erken çıkış |
| "Önce tavşan" modu | Tek dokunuş döngüsü: boş → tavşan → X → boş | `GameState.bunny_first_tap_mode` |
| Taslak modu açık | Tüm yeni işaretler `SOURCE_DRAFT` olarak yazılır; tahtaya uygulanmadan kalıcı olmaz | `toggle_draft_mode()` |

Sürükleme yalnızca X koyma/silme içindir; tavşan sürüklenmez (`_handle_drag_over_cell()` tavşan hücresini atlar).
Her hamle tek bir geri alma anlık görüntüsü üretir; taslak modunda ise tek bir "taslak öncesi" görüntü saklanır
(`_push_undo()` taslakta erken döner).

## 4. Otomatik X ve geri alma

- **Auto-X (Mevcut, varsayılan açık):** Bir tavşan yerleştiğinde aynı satır, sütun, bölge ve 8 komşuluktaki boş
  hücreler X olur; X'in sahibi tavşanın konumu kaydedilir (`_apply_auto_cross_for_bunny()`).
  Kullanıcı X'i elle silerse sahiplik temizlenir; tavşan kaldırıldığında yalnızca **o tavşana ait** ve kaynağı
  `auto`/`draft` olan X'ler silinir (`_remove_bunny_at()`). Elle konmuş X'ler ve ön yerleştirme X'leri korunur.
- **Geri al:** Son hamleyi geri yükler; otomatik X sahipliği de anlık görüntüyle birlikte döner
  (`_capture_snapshot()` / `_restore_snapshot()`). Taslak modunda "geri al" taslağı iptal eder
  (`undo_move()` → `cancel_draft()`).
- **Temizle:** Tahtayı boşaltır, prefill tavşanları geri koyar ve auto-X'i yeniden uygular (`clear_board()`).

## 5. Taslak modu (Mevcut)

| Davranış | Ayrıntı |
|---|---|
| Açma | Mevcut tahtanın anlık görüntüsü alınır, `draft_mode = true` |
| İşaretleme | X ve tavşanlar mavi taslak stiliyle çizilir (`SOURCE_DRAFT`) |
| Onaylama | Tüm taslak işaretleri `manual` kaynağına dönüşür, mod kapanır (`apply_draft()`) |
| İptal | Anlık görüntüye dönülür, taslak yığını temizlenir (`cancel_draft()`) |
| Çakışma | Taslak tavşan çakışsa bile **can ve yıldız kaybı yoktur**; yalnızca kırmızı vurgu görünür (`_place_bunny_at()` içinde `src != SOURCE_DRAFT` kontrolü) |
| Maliyet | **Açık:** taslak modu ücretsiz ve sınırsız; ekonomiye bağlı değil |

## 6. İpucu hattı (Mevcut)

`HintSolver.compute_hint(size, region_map, solution_set, board_state)` dokuz aşamayı sırayla dener, ilk
uygulanabilir adımı döndürür. Her adım bir açıklama metni (`title` + `message`) ve vurgu listesi taşır; oyuncuya
`_show_toast()` ile gösterilir. İpucu **1 ipucu** harcar; sonuç boşsa harcanmaz (`_on_hint_pressed()`).

| # | Adım | Ne yapar | Tip |
|---|---|---|---|
| 1 | Yanlış tavşan düzeltme | Çözümde olmayan tavşanı kaldırır | `remove_wrong_bunny` |
| 2 | Yanlış X düzeltme | Çözüm hücresindeki X'i siler | `clear_wrong_cross` |
| 3 | Temel işaretleme | Doğru tavşanın satır/sütun/bölge/komşuluğundaki boşlukları X yapar | `place_crosses` |
| 4 | Bölgede tek aday | Bölgede 1 boş hücre kaldıysa tavşan koyar | `place_bunny` |
| 5 | Satırda tek aday | Satırda 1 boş hücre kaldıysa tavşan koyar | `place_bunny` |
| 6 | Sütunda tek aday | Sütunda 1 boş hücre kaldıysa tavşan koyar | `place_bunny` |
| 7 | Bölge-satır/sütun hizası | Bölgenin tüm boşları tek satırda/sütunda ise o satır/sütunun dışını X yapar | `place_crosses` |
| 8 | Komşu bölge yok etme | Bir hücre, komşu küçük bölgenin tüm adaylarını yok ediyorsa o hücre X olur (bölgede ≤4 boş hücre şartı) | `place_crosses` |
| 9 | Doğrudan açığa çıkarma | Hiçbiri uymazsa çözümdeki sıradaki tavşanı koyar | `place_bunny` |

Not: 9. adım bir "mantık adımı" değil, çözümden doğrudan okumadır; ipucu her durumda ilerleme garanti eder.
Doğrulanmış sonuç: ipucu hattı 120/120 seviyeyi sıfır hatayla çözer (bkz.
[`13_QA_ACCEPTANCE.md`](13_QA_ACCEPTANCE.md)).

**Altın havuç (Mevcut):** `apply_carrot_booster()` çözümdeki tavşanlardan, içinde en çok boş hücre kalan bölgeyi
seçer, o bölgenin çözüm tavşanını açar ve çakışan tavşanları **hata saymadan** önce kaldırır. 1 havuç harcar.

## 7. Can, hata ve yıldız

| Kavram | Değer / kural | Kod |
|---|---|---|
| Başlangıç canı | 3 (her seviye başında sıfırlanır, kalıcı değil) | `start_level()` `_lives = 3` |
| Hata tetikleyicisi | Kural ihlali yapan tavşan yerleştirmek (taslak hariç) | `_place_bunny_at()` → `mistake_made` |
| Hata sonucu | -1 can, uyarı toast'ı, kalp animasyonu | `_on_mistake_made()` |
| Can bitince | `out_of_lives` ekranı: ödüllü reklamla can + otomatik ipucu ya da yeniden başlat | `_show_out_of_lives_modal()`, `_on_revive_ad_completed()` |
| Yıldız 1 | `mistakes >= 2` **veya** `elapsed_sec > 180` | `GameState.complete_level()` |
| Yıldız 2 | `mistakes == 1` **veya** `elapsed_sec > 90` | aynı |
| Yıldız 3 | Diğer tüm durumlar | aynı |
| Yıldız kaydı | Tekrar oynanınca **en iyi** yıldız ve **en iyi** süre korunur | `maxi` / `mini` |
| Süre | Reklam modalı açıkken durur (`_ad_is_active`) | `main_controller._process()` |

## 8. Uç durumlar

| Durum | Beklenen davranış | Doğrulandığı yer |
|---|---|---|
| Taslak tavşanı çakışıyor | Can gitmez, yıldız etkilenmez, yalnızca görsel uyarı | `_place_bunny_at()` |
| Tavşan kaldırılınca sahipli X'ler | Yalnızca o tavşanın ürettiği, kaynağı auto/draft olan X'ler silinir | `_remove_bunny_at()` |
| İpucu sonuç üretmezse | İpucu harcanmaz | `_on_hint_pressed()` `res.is_empty()` |
| Havuç çakışan tavşanı kaldırır | Hata sayılmaz (booster cezalandırmaz) | `apply_carrot_booster()` yorumu |
| Reklam sırasında süre | Sayaç durur; yıldız eşiği adil kalır | `_process()` |
| Prefill'li seviyede auto-X | Açılışta prefill tavşanları için X'ler uygulanır | `setup_level()` |
| Eski seviyeyi tekrar oynama | İlerleme atlamaz; yalnızca `idx == unlocked_level_index` bir sonrakini açar | `complete_level()` |
| Tüm hücreler X, tavşan eksik | Tahta çözülmemiş sayılır; ipucu 1/2/9. adımla ilerler | `compute_hint()` |
| 4×4 tahtada hata | Aynı kurallar; can sayısı seviye boyutundan bağımsız | `start_level()` |

## 9. Açık maddeler

| Madde | Durum | Not |
|---|---|---|
| `steps` alanı | **Açık** | Veritabanında var ama hiçbir kod okumuyor; 90/120 seviyede `steps != size` (bkz. [`04_CONTENT_AND_PROGRESSION.md`](04_CONTENT_AND_PROGRESSION.md)) |
| Zorluk göstergesi | **Açık** | Tahtada kalan satır/sütun/bölge sayacı yok; yalnızca "yerleşen / N" göstergesi var |
| İpucu maliyeti dengesi | **Açık** | İpucu her zaman 1; zor seviyede aynı maliyet |
| Taslak modu maliyeti | **Açık** | Ücretsiz ve sınırsız; ekonomik kaldıraç olarak kullanılmıyor |
| Hata geri bildirimi | **Mevcut** | Kırmızı çizgi + toast; ses ipucu `SoundManager.play("error")` |
| Erişilebilirlik (renk körlüğü) | **Mevcut (kısmi)** | Desen modu 12 ikon; kontrast ve dokunma hedefleri [`06_UI_UX_LOCALIZATION.md`](06_UI_UX_LOCALIZATION.md) |

## 10. İlgili belgeler

- Seviye üretimi ve ilerleme: [`04_CONTENT_AND_PROGRESSION.md`](04_CONTENT_AND_PROGRESSION.md)
- İpucu/havuç ekonomisi: [`05_ECONOMY_MONETIZATION.md`](05_ECONOMY_MONETIZATION.md)
- Arayüz akışı: [`06_UI_UX_LOCALIZATION.md`](06_UI_UX_LOCALIZATION.md)
- Kabul testleri: [`13_QA_ACCEPTANCE.md`](13_QA_ACCEPTANCE.md)
- Olay sözlüğü (`bunny_placed`, `mistake`, `booster_used`, `undo`): [`../analytics/EVENTS.md`](../analytics/EVENTS.md)
