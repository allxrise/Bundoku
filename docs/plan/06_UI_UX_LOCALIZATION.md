# Arayüz, UX ve Yerelleştirme

> **Özet:** Arayüz, tek kök sahne (`scenes/main.tscn`) dışında tamamen kodla kurulur (`scripts/ui/main_controller.gd`).
> Taban çözünürlük 540×960 dikey, `canvas_items` + `expand` ölçekleme. Yedi ekran/modal, 20 dilli kendi çeviri
> tablosu ve cihaz güvenli alanına göre yeniden hesaplanan kenar boşlukları vardır. Bu belge ekran envanterini,
> yerleşim kurallarını, görsel belirteçleri, erişilebilirlik boşluklarını ve çeviri mekaniğini tanımlar.

Durum etiketleri: **Mevcut**, **Planlanan**, **Açık**.

## 1. Ekran envanteri

| Ekran | Telemetri `screen` | Giriş | Ana eylemler (`telemetry_id`) | Kod |
|---|---|---|---|---|
| Ana ekran | `home` | Uygulama açılışı, oyundan dönüş | `play`, `daily`, `league`, `language`, `sound_toggle`, `level_N` | `_build_home_screen()` |
| Oyun | `game` | `play`, seviye kartı, günlük, sonraki bölüm | `undo`, `clear`, `draft`, `hint`, `carrot`, `mode_toggle`, `auto_x_toggle`, `pattern_toggle` | `_build_game_screen()` |
| Sonuç (kazanma) | `result` | Tahta çözüldüğünde | `win_home`, `win_next` | `_show_win_modal()` |
| Can bitti | `out_of_lives` | 3. hata | `revive`, `restart` | `_show_out_of_lives_modal()` |
| Lig | `league` | Ana ekran `league` | `league_close` | `_show_league_modal()` |
| Dil | `language` | Ana ekran `language` | 20 dil düğmesi, `privacy_options`, `language_close` | `_show_language_modal()` |
| Reklam | `ad` | Çözüm sonrası / booster / revive | `ad_close` | `_show_ad_modal()`, `_show_simulated_ad_modal()` |

Ekran geçişleri `Telemetry.set_screen()` ile işaretlenir (`screen_checkpoint`). Ayrı ayarlar ekranı yoktur;
ses, oto-X, desen ve dokunma modu oyun ekranındaki düğmelerden yönetilir ([`../analytics/EVENTS.md`](../analytics/EVENTS.md)).

## 2. Yerleşim ve güvenli alan

| Kural | Değer | Kaynak |
|---|---|---|
| Taban çözünürlük | 540×960, dikey (`orientation=1`) | `project.godot` |
| Ölçekleme | `canvas_items` + `expand` | `project.godot` |
| Varsayılan yazı boyutu | 15 (tema) | `_setup_fonts_and_theme()` |
| Ekran kenar boşluğu | ana: yatay 18, üst 14, alt 16; oyun: yatay 14, üst 12, alt 14 (+ güvenli alan) | `_build_home_screen()`, `_build_game_screen()` |
| Mobil güvenli alan | üst en az **88 px** (çentik/kamera), alt en az **28 px** (jest çubuğu) | `_apply_safe_area_margins()` |
| Banner payı | `banner_loaded(height_px)` → alt boşluk = banner yüksekliği + 8 (ana) / +6 (oyun) | `_on_banner_loaded()` |
| Yeniden hesaplama | `resized` sinyali + ertelenmiş çağrı + 0.15 sn sonra tekrar | `_ready()` |

Masaüstünde `get_display_safe_area()` ve çentik dikdörtgenleri **yok sayılır**; aksi hâlde görev çubuğu
540 px genişliğe sahte boşluk olarak yansıyordu. Banner yüksekliği viewport pikselidir; Pixel 9 / Android 17
cihazında ölçülen değer **84 px** ve bu alan arayüzden gerçekten ayrılıyor (`banner_loaded` telemetrisi).

Tahta yerleşimi: kenar boşluğu 12 px, hücre kenarı `floor(min(genişlik, yükseklik) / N)`; tahta ortalanır
(`BoardView._calculate_layout()`). 9×9 için hücre yaklaşık 50 px'e, 4×4 için 110 px'in üzerine çıkar.

## 3. Arayüzün kodla üretilmesi

| Özellik | Mevcut uygulama |
|---|---|
| Sahne dosyası | Yalnızca kök `scenes/main.tscn` (boş `Control` + script); ekranların tamamı `Control.new()` ile kurulur |
| Yeniden kurulum | Dil değişiminde ana/oyun ekranı düğümleri serbest bırakılıp yeniden inşa edilir (`_rebuild_all_ui_for_language()`) |
| Stil ve animasyon | `_make_card_style()`, `_make_recessed_style()`, `_style_tactile_button()`, 9-slice `_make_9slice_style()`, `_animate_cards_enter()`, `_animate_slot_pop()` |
| Metin | `_make_label()` (boyut, renk, gölge/kontur parametreleriyle) |
| Varlık yükleme | `res://assets/chatgpt_ui`, `res://assets/ui`; eksikse renkli yedek stil |

Yeniden kurulum maliyeti düşüktür; dil değişimi `_rebuild_all_ui_for_language()` ile ana ekrana döner
(`_show_home_screen()`). Dil düğmesi zaten yalnızca ana ekranda bulunur, oyun sırasında dil değiştirilemez.

## 4. Görsel belirteçler

| Belirteç | Değer / adet | Kaynak |
|---|---|---|
| Ana palet | `bg_oatmeal #F8F0DF`, `card_face #FFF9EC`, `text_main #60452F`, `carrot_face #FFAC48`, `berry_face #F58CA4`, `sage_face #DCE8CF` | `main_controller.PALETTE` |
| Bölge renkleri | 14 pastel fırın tonu | `GameState.REGION_COLORS` |
| Desen ikonları | 12 (renk körlüğü modu) | `BoardView.PATTERN_ICON_PATHS` |
| Desen karakterleri | 14 Unicode sembol tanımlı | `GameState.REGION_PATTERNS` — **Açık:** kullanılmıyor |
| Tahta çerçevesi | 5 katmanlı ahşap tepsi (gölge + 4 çizim) | `BoardView._draw()` |
| Kalpler / ilerleme | 3 kalp ikonu; N adet yuva, 26–36 px arası ölçeklenir | `_update_lives_label()`, `_rebuild_progress_slots()` |

Bir seviyede en fazla 9 bölge olduğu için 12 desen ikonu benzersiz eşleme sağlar; renk (14) ve ikon (12)
indeksleri farklı modüllere düştüğü için 9'dan büyük bölge sayısında çakışma olurdu.

## 5. Yerelleştirme mekaniği (Mevcut)

| Konu | Uygulama |
|---|---|
| Dil sayısı | 20: tr, en, es, de, fr, pt, it, ru, ar, zh, ja, ko, hi, bn, ur, id, vi, mr, te, sw |
| Tablo | `Loc.DATA` sözlüğü, anahtar bazlı; her dil aynı anahtar kümesini hedefler |
| Arama sırası | `current_lang` → `en` → `tr` → anahtarın kendisi (`Loc.t()`) |
| İlk açılış | `OS.get_locale_language()` ilk 2 harf; tabloda yoksa `tr` |
| Uygulama içi değişim | Dil modalı → `GameState.set_language()` → `settings/language` kaydı + `language_changed` olayı |
| Yazı tipi | `Baloo2.ttf` + `SystemFont` yedekleri (Noto Sans, CJK, Arabic, Devanagari, Bengali, Telugu) |
| Özdeyişler | `Loc.quotes()`; dilde yoksa Türkçe listeye düşer |

Yedek zinciri kısmi çevirileri tolere eder ama **sessizdir**: eksik anahtar İngilizce/Türkçe görünür, kullanıcı
bunu fark etmez. Hangi anahtarın hangi dilde eksik olduğunu ölçen bir kontrol yok (Açık).

### Bilinen metin sorunları

| Sorun | Örnek | Durum |
|---|---|---|
| Çoğul eki yok | `en`: `"%d Days"` → "1 Days" | **Açık** |
| Terim tutarsızlığı | `en`: `"%d Cups"` (kupa), ekranda "Trophies" de kullanılıyor | **Açık** |
| Sabit İngilizce metin | Dil modalındaki gizlilik düğmesi `"Privacy options"` olarak gömülü | **Açık** |
| Emoji/simge önekleri | Dil düğmesi ve modal başlığı küre simgesiyle, gizlilik düğmesi kilit simgesiyle başlıyor; `tool_first_bunny` metni tavşan simgesi içeriyor | **Mevcut** (simge desteği cihaza bağlı) |

`win_stats` tüm dillerde aynı `%02d:%02d` sırasını kullanır; tarih/sayı yerelleştirmesi yoktur.

## 6. RTL ve yazı yönü

Arapça ve Urduca çevrili, ancak kodda `text_direction`, `right_to_left` veya ayna düzeni ayarı **hiç yok**;
tüm yerleşimler sol-sağ mantığıyla sabit (HBox sıraları, kenar boşlukları, ilerleme yuvaları, tahta).

| Beklenen | Bugün |
|---|---|
| Başlık/düğme metinleri ve geri düğmesi sağda | Solda hizalı |
| İlerleme çubuğu sağdan sola | Soldan sağa |
| Tahta koordinatları değişmez | Doğru (tahta yön bağımsız) |

Bu **Açık** bir maddedir ve 20 dil iddiasının en zayıf halkasıdır; RTL oyuncular için okunabilirlik düşer.

## 7. Erişilebilirlik

| Konu | Mevcut | Boşluk |
|---|---|---|
| Renk körlüğü | Desen modu (12 ikon, düşük alfalı) | İkonlar küçük ve kontrastsız; varsayılan kapalı |
| Dokunma hedefi | Araç düğmeleri 78 px yüksek, üst düğmeler 40–44 px, seviye kartı 105×72 | Toast kapatma 34×34; 9×9 hücre ≈50 px (kabul edilebilir) |
| Yazı ölçeği | Sistem ölçeği yok sayılır, sabit 15 | Büyük yazı ayarı yok |
| Kontrast | Pastel zemin + koyu kahve metin | Ölçülmüş oran yok; `text_sec #987A5B` açık zeminde zayıf olabilir |
| Hareket azaltma | Tüm tween/nabız animasyonları koşulsuz | "Azaltılmış hareket" ayarı yok |
| Ekran okuyucu ve ses | Etiketlerde erişilebilirlik metni/rolü yok; tüm eylemlerde ses efekti var | Godot Android desteği sınırlı; ses kapatılınca toast + renk yeterli |

## 8. Telemetri

Her `BaseButton` otomatik bağlanır; `telemetry_id` meta'sı varsa o ad, yoksa düğüm adı/metni kullanılır.
Aynı düğmede 300 ms içindeki tekrarlar yutulur (`_on_button_pressed()`), böylece çift dokunuş iki `ui_tap`
üretmez. Olay: `ui_tap { screen, button, level }` ([`../analytics/EVENTS.md`](../analytics/EVENTS.md)).

| Örnek `button` değeri | Kaynak ekran |
|---|---|
| `play`, `daily`, `league`, `language`, `level_42`, `sound_toggle` | home |
| `undo`, `clear`, `draft`, `hint`, `carrot`, `mode_toggle`, `auto_x_toggle` | game |
| `win_home`, `win_next`, `revive`, `restart`, `league_close`, `ad_close`, `pattern_toggle` | modallar / game |

`setting_changed` olayı ses, oto-X, desen ve ilk dokunma modu için ayrıca yazılır; `ui_tap` tek başına ayar
değişimini kanıtlamaz.

## 9. Planlanan iyileştirmeler

| İş | Öncelik gerekçesi |
|---|---|
| RTL ayna düzeni (ar, ur) | 20 dil iddiasını gerçek kılar |
| Çoğul altyapısı + `%d Days` ve "Cups" düzeltmesi | Görünür kalite hatası |
| Gizlilik düğmesi metnini çeviriye taşıma + eksik anahtar raporu | Sessiz fallback'i görünür kılar |
| Kontrast denetimi, büyük yazı, azaltılmış hareket ve varsayılan desen modu seçenekleri | Erişilebilirlik |

## 10. İlgili belgeler

- Oynanış: [`02_CORE_GAMEPLAY.md`](02_CORE_GAMEPLAY.md); ürün: [`01_PRODUCT_STRATEGY.md`](01_PRODUCT_STRATEGY.md)
- Reklam/banner: [`05_ECONOMY_MONETIZATION.md`](05_ECONOMY_MONETIZATION.md), [`../ads/INTEGRATION.md`](../ads/INTEGRATION.md)
- Mağaza ve rıza: [`../store/DATA_SAFETY_AND_LISTING.md`](../store/DATA_SAFETY_AND_LISTING.md), [`../analytics/PRIVACY_AND_CONSENT.md`](../analytics/PRIVACY_AND_CONSENT.md)
- Kabul kriterleri: [`13_QA_ACCEPTANCE.md`](13_QA_ACCEPTANCE.md)
