# Ürün Stratejisi

> **Özet:** Bundoku (`com.bundoku.puzzle`), tek elle oynanan, 120 hazır seviyeli, 20 dilli bir mantık bulmacasıdır
> (Star Battle / Queens türevi). Bu belge kimin için, hangi farkla, neyi ölçerek ilerleyeceğimizi ve kapsam
> sınırlarını tanımlar. Sayısal hedefler **kasıtlı olarak yoktur**: henüz ölçüm altyapısı yerelde birikim
> yapıyor, sunucu tarafı ve mağaza verisi bulunmuyor ([`../analytics/BIGQUERY.md`](../analytics/BIGQUERY.md)).

Durum etiketleri: **Mevcut** = kodda çalışıyor, **Planlanan** = yol haritası, **Açık** = bilinen eksik/risk.

## 1. Hedef kitle

| Segment | Neden uygun | Mevcut kanıt |
|---|---|---|
| Sakin (cozy) bulmaca oyuncuları | Süre baskısı yok: sayaç yalnızca yıldız hesabında kullanılır, süre dolunca oyun bitmez; yanlış hamle sadece can götürür | `GameState.complete_level()` yıldız eşikleri, `main_controller._process()` `_elapsed_sec` |
| Kısa mola oyuncuları (mobil, tek el) | 540×960 dikey, tüm eylemler alt araç çubuğunda, tek dokunuş + sürükleme | `project.godot` (`window/size/viewport_width=540`, `viewport_height=960`, portrait) |
| Yerel dilde oynamak isteyen geniş coğrafya | 20 dil, uygulama içi dil modalı, ilk açılışta sistem dili algılama | `scripts/core/loc.gd:7` (`LANGUAGES`), `GameState._init_default_language()` |
| Bulmaca türüne yeni başlayanlar | 4×4'ten 9×9'a kademeli boyut, ilk 10 seviyede ön yerleştirilmiş tavşan, ipucu motoru | `assets/levels/levels_database.json`, `scripts/gameplay/hint_solver.gd` |

Hedef dışı: rekabetçi/hız odaklı oyuncular (canlı rakip yok, lig simülasyonu), hikâye anlatımı bekleyenler
(metin sadece kısa özdeyişler: `Loc.quotes()`), çok oyunculu ve sosyal özellik isteyenler.

## 2. Farklılaştırıcılar

| Fark | Mevcut durum | Dayanak |
|---|---|---|
| Tavşan/fırın teması (pastel bölge paleti, ahşap tepsi çerçevesi) | Mevcut | `GameState.REGION_COLORS` (14 renk), `board_view.gd` `_draw()` tepsi çerçevesi |
| 120 elle hazırlanmış seviye, tek veritabanı | Mevcut | `assets/levels/levels_database.json` (120 kayıt) |
| 20 dilli arayüz + oyun içi dil değiştirme | Mevcut | `scripts/core/loc.gd`, `main_controller._show_language_modal()` |
| Düşük sürtünmeli oturum: kayıt, giriş, çevrimiçi zorunluluğu yok | Mevcut | `user://bundoku_save.cfg` düz `ConfigFile`; sunucu yok |
| Mantık zinciri gösteren ipucu (cevabı basmak yerine adım açıklaması) | Mevcut | `hint_solver.gd` 9 aşamalı hat, `_show_toast()` |
| Taslak modu (deneme güvenliği) | Mevcut ama ücretlendirilmemiş | `board_view.toggle_draft_mode()`, `apply_draft()`, `cancel_draft()` |
| Reklam yükü kademeye göre azalan aralık | Mevcut (test kimlikleriyle) | `GameState.AD_INTERVAL_BY_TIER` |

Bu farkların hiçbiri teknik hendek değildir; kopyalanabilir. Savunulabilirlik seviye kalitesi, dil kapsaması ve
reklam dengesiyle ilgilidir, teknolojiyle değil.

## 3. Meowdoku referansına göre konum

Statik analiz: [`../../REA/README.md`](../../REA/README.md). Referans uygulama `com.oakever.meowdoku` v1.23.0,
Godot 4.6.1, 801 global GDScript sınıfı, 17 dil paketi, AppLovin/Pangle dahil çok kanallı reklam yığını.

| Boyut | Meowdoku (referans) | Bundoku (biz) |
|---|---|---|
| Kapsam | Çok sayıda mod + küme/lig + robot puan simülasyonu | Tek mod, 120 seviye, doğrusal ilerleme |
| Motor | Godot 4.6.1, asset-pack ile ~349 MB paket | Godot 4.7.2 ile derleniyor, debug APK ≈185 MB |
| Reklam | AppLovin MAX + Pangle + mediation | AdMob (Poing v5.1.0), Meta mediation, UMP |
| Dil | Android sistem yerelleştirmesi + 17 paket | Kendi `Loc.DATA` tablosu, 20 dil |
| Ekonomi | Mağaza/etkinlik odaklı | Sadece ipucu/havuç, IAP yok |

**Açık risk:** Arayüz dokuları ve bazı varlık adları referans oyundan alınmış görünüyor
(`scripts/gameplay/board_view.gd` başlığı "original extracted Meowdoku UI/board textures" diyor;
`assets/ui/game_icon_mark_white.png`, `assets/ui/game_rule_diagram_*.png` gibi dosyalar). Tema ve metin
özgünleşse bile görsel varlıkların lisansı ayrı bir hukuki inceleme konusudur; yayın öncesi değiştirilmeli veya
lisansı belgelenmelidir. Bu, ürün stratejisinin en yüksek öncelikli açık maddesidir; ayrıntı ve öneri:
[`../research/MEOWDOKU_REFERENCE.md`](../research/MEOWDOKU_REFERENCE.md), yayın kapısı:
[`../release/SHIP_CHECKLIST.md`](../release/SHIP_CHECKLIST.md).

## 4. Başarı kriterleri (hedef sayı değil, ölçüm tanımı)

Bugün hiçbir metrik üretimde toplanmıyor: telemetri yerel JSONL'e yazıyor, yükleme yolu manuel
([`../analytics/BIGQUERY.md`](../analytics/BIGQUERY.md)). Aşağıdaki tablo, ölçüm başladığında hangi soruyu
hangi olayla yanıtlayacağımızı sabitler; olay adları [`../analytics/EVENTS.md`](../analytics/EVENTS.md) ile
birebir aynıdır.

| Karar sorusu | Metrik tanımı | Olay kaynağı | Bugünkü durum |
|---|---|---|---|
| Oyuncu geri dönüyor mu? | D1/D7: ilk `first_open` sonrası 1. ve 7. gün `session_start` | `first_open`, `session_start` | Açık: sunucu yok, kohort hesaplanamıyor |
| İlk oturumda takılıyor mu? | Seviye 1→2 dönüşümü (`level_start` → `level_complete`) | `level_start`, `level_complete` | Mevcut (yerel), rapor yok |
| Nerede bırakıyor? | Seviye bazlı huni: başlatma, tamamlama, `level_fail`, `level_abandon` | aynı üç olay + `level_abandon` | Mevcut (yerel) |
| İpucu ekonomisi çalışıyor mu? | `booster_used` (hint/carrot) / tamamlanan seviye | `booster_used`, `level_complete` | Mevcut (yerel) |
| Reklam geliri sağlıklı mı? | eCPM = `ad_impression.value` / gösterim × 1000, placement bazında | `ad_impression` | Açık: test kimlikleri, gerçek gelir yok |
| Reklam deneyimi bozuyor mu? | Oturum başına `ad_shown` sayısı, `ad_closed` sonrası `level_start` | `ad_shown`, `ad_closed`, `level_start` | Mevcut (yerel, yalnızca simüle=1) |
| Dil dağılımı doğru mu? | `language_changed` + `user_properties.language` | `language_changed` | Mevcut (yerel) |

Kural: yukarıdaki metrikler için **hedef eşik yazılmaz**. Eşikler ancak en az bir haftalık gerçek kohort
verisinden sonra, [`09_ANALYTICS_EXPERIMENTS.md`](09_ANALYTICS_EXPERIMENTS.md) içinde tanımlanır.

## 5. Kapsam sınırları

| Kapsam içi (bu sürüm) | Kapsam dışı (bilinçli) |
|---|---|
| 120 seviyelik tek kampanya, doğrusal açılım | Yeni mod (günlük bulmaca dışında), seviye editörü |
| 3 can, 3 yıldız, ipucu + havuç | Para birimi, mağaza, sezonluk etkinlik |
| Alt banner + interstitial + rewarded (AdMob) | Ödüllü video SSV doğrulaması (sunucu gerektirir) |
| 20 dil, RTL hariç ayna düzeni | Seslendirme, altyazı |
| Yerel telemetri + BigQuery şeması | Gerçek zamanlı dashboard, A/B altyapısı |
| Android (Gradle) | iOS derlemesi |

iOS, web ve masaüstü mağaza hedefleri bu sürümün kapsamı dışındadır; `project.godot` içinde tanımlı olsalar da
yalnızca Android export preseti doğrulanmıştır.

## 6. Riskler

| Risk | Etki | Olasılık | Azaltım |
|---|---|---|---|
| Referans oyundan alınan görsel varlıklar (IP) | Mağaza reddi / kaldırma | Orta | Varlıkları özgün setle değiştir; lisans kaydı tut ([`../release/SHIP_CHECKLIST.md`](../release/SHIP_CHECKLIST.md)) |
| Reklam yükü oyuncuyu kaçırır | D1/D7 düşüşü | Orta | Kademeye göre aralık zaten var; ölçüm sonrası aralık ayarı ([`05_ECONOMY_MONETIZATION.md`](05_ECONOMY_MONETIZATION.md)) |
| Sunucu yok → gelir/olay analizi manuel | Karar gecikmesi | Yüksek | BigQuery yükleme betiği + haftalık manuel iş akışı |
| Test reklam kimlikleriyle yayın | Gelir sıfır / politika ihlali | Yüksek (şu an) | Yayın öncesi kimlik değişimi ([`../ads/INTEGRATION.md`](../ads/INTEGRATION.md)) |
| IAP yok → "reklamsız" isteği karşılanamıyor | Gelir ve memnuniyet kaybı | Orta | `no_ads_purchased` bayrağı hazır ama satın alma yok ([`05_ECONOMY_MONETIZATION.md`](05_ECONOMY_MONETIZATION.md)) |
| 20 dilde metin kalitesi eşit değil | Yerel mağaza puanı | Orta | Dil bazlı gözden geçirme listesi ([`06_UI_UX_LOCALIZATION.md`](06_UI_UX_LOCALIZATION.md)) |
| Sürüm numarası tutarsızlığı (1.0.0 / 1.0.4) | Mağaza/analiz karışıklığı | Yüksek | Tek kaynak kuralı ([`08_TECHNICAL_ARCHITECTURE.md`](08_TECHNICAL_ARCHITECTURE.md)) |

## 7. İlgili belgeler

- Oynanış kuralları: [`02_CORE_GAMEPLAY.md`](02_CORE_GAMEPLAY.md)
- İçerik ve ilerleme: [`04_CONTENT_AND_PROGRESSION.md`](04_CONTENT_AND_PROGRESSION.md)
- Ekonomi ve reklam: [`05_ECONOMY_MONETIZATION.md`](05_ECONOMY_MONETIZATION.md)
- Arayüz ve yerelleştirme: [`06_UI_UX_LOCALIZATION.md`](06_UI_UX_LOCALIZATION.md)
- Ölçüm planı: [`09_ANALYTICS_EXPERIMENTS.md`](09_ANALYTICS_EXPERIMENTS.md), [`../analytics/EVENTS.md`](../analytics/EVENTS.md)
- Gizlilik ve rıza: [`../analytics/PRIVACY_AND_CONSENT.md`](../analytics/PRIVACY_AND_CONSENT.md)
- Yayın: [`11_STORE_RELEASE.md`](11_STORE_RELEASE.md), [`../store/DATA_SAFETY_AND_LISTING.md`](../store/DATA_SAFETY_AND_LISTING.md)
