# 12 — Yayın ve canlı operasyon

> **Karar:** Bundoku sunucusuz bir oyundur; yayın sonrası içerik ve davranış değişiklikleri yalnız yeni
> sürümle gelir. Canlı operasyon bu nedenle "yayın kapıları + sürüm ritmi + olay müdahalesi" olarak
> tasarlanır. Uzaktan yapılandırma, push ve uygulama içi haber kanalı yoktur; bunlar **Planlanan**'dır.

Etiketler: **Mevcut**, **Planlanan**, **Açık**. Ölçüm tanımları:
[09_ANALYTICS_EXPERIMENTS.md](09_ANALYTICS_EXPERIMENTS.md). Yayın kapıları:
[../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md).

## 1. Bugünkü canlı operasyon yetenekleri

| Yetenek | Mevcut davranış | Sınır |
|---|---|---|
| Günlük bölüm | `(gün × 7) % 120`, açılmış bölüme kırpılır | Yeni içerik değil; aynı 120 bölümden seçer |
| Lig | 7 simüle rakip + oyuncu; her temizlemede her rakip %45 olasılıkla +3…+12 kupa | Sezon, sıfırlama, gerçek rakip yok |
| Yıldız | 3/2/1; kayıt `completed_levels` içinde | Yıldız harcanmıyor |
| Ekonomi | Başlangıç 5 ipucu / 3 havuç; her 2./4. bölümde bonus | Satın alma yok |
| Reklam | Tier bazlı interstitial + ödüllü + banner | Test kimlikleri; SSV yok |
| İçerik | 120 gömülü bölüm | Bölümler APK içinde; sıcak düzeltme yok |
| Duyuru | Yok | Mağaza "yenilikler" ve sürüm notu dışında kanal yok |
| Uzaktan kontrol | Yok | Özellik bayrağı / kill switch yok |

Kaynak: günlük seçim ve reklam teklifleri `scripts/ui/main_controller.gd`; ekonomi, lig ve yıldız
`scripts/core/game_state.gd`; reklam yükleme `scripts/ads/ad_manager.gd`; içerik
`assets/levels/levels_database.json`.

## 2. Yayın aşamaları ve kapılar

| Aşama | Amaç | Kapı | Durum |
|---|---|---|---|
| Internal | Teknik doğrulama | Release AAB, gerçek reklam kimlikleri, cihazda açılış | **Planlanan** |
| Closed test | Akış ve rıza doğrulaması | P0 kapanışı; Data Safety taslağı; geri bildirim toplanması | **Planlanan** |
| Open test | Ölçek ve reklam dolumu | Çökme oranı izlenebilir; reklam hataları loglanıyor | **Planlanan** |
| Production | Genel yayın | Tüm P0 kapalı; mağaza formları onaylı; destek kanalı hazır | **Planlanan** |

**Kural:** Her aşama bir öncekinin çıkış kriterlerini sağlamadan açılmaz. Sayısal eşikler, ilk ölçüm
tabanı alındıktan sonra `09`daki metrikler üzerinden belirlenir; bu belge hedef sayı uydurmaz.

## 3. İçerik ritmi

| Konu | Karar | Durum |
|---|---|---|
| 120 bölüm | Tek seferlik lansman içeriği | **Mevcut** |
| Günlük bölüm | Açılmış bölümlerden tarih tabanlı seçim | **Mevcut** |
| Yeni bölüm paketi | Doğrulayıcıdan geçen yeni JSON paketi + sürüm | **Planlanan** |
| Mevsimsel etkinlik | Sunucu/remote config olmadan mümkün değil | **Planlanan** |
| İçerik doğrulama | Her bölüm çözüm izni + bölge + komşuluk + ipucu motoru testi | **Planlanan** (script yok) |

**Açık:** Bölümler uygulama paketinde olduğu için hatalı bir bölüm ancak yeni sürümle düzeltilir. Yayın
öncesi 120/120 doğrulaması bu yüzden zorunludur ([13_QA_ACCEPTANCE.md](13_QA_ACCEPTANCE.md)).

## 4. Ölçüm ve gözden geçirme ritmi

| Ritim | Bakılan | Kaynak |
|---|---|---|
| Günlük | Yeni sürümde çökme/ANR, reklam yükleme hatası, rıza hatası | Play Console, `ad_load_failed`, `banner_failed` |
| Haftalık | Huni, bölüm tamamlama, ipucu kullanımı, oturum süresi | BigQuery (`09`) |
| Sürüm bazlı | D1/D7, gelir, geri bildirim | BigQuery + AdMob + mağaza yorumları |
| İçerik bazlı | Bölüm bazlı `mistake`, `level_fail`, `seconds` | BigQuery |

**Açık:** Analitik rızası verilmeyen kullanıcılar ölçümde yoktur; EEA'da rıza kartı olmadığı için bu bölge
neredeyse tamamen ölçüm dışıdır. Reklam geliri için AdMob raporu esas alınır; uygulama içi `ad_impression`
yalnız atıf içindir.

## 5. Destek ve iletişim

| Konu | Mevcut | Planlanan |
|---|---|---|
| Destek e-postası | Yok | Mağaza listesinde yayınlanacak adres |
| Gizlilik talebi | Yerel veri silme (uygulama verisini temizleme) | Politikada açık talep yolu |
| Mağaza yorumları | Yanıt süreci tanımsız | Haftalık triyaj |
| Sürüm notu | `VERSION_HISTORY.md` | Mağaza "yenilikler" metni |
| Oyun içi duyuru | Yok | Gerekmiyor; uzaktan içerik yok |

## 6. Olay müdahale defteri

| Belirti | Tespit | İlk müdahale | Sınır |
|---|---|---|---|
| Reklam SDK başlatılamıyor | `Ads.supported=false`, simüle modal | Akış devam eder; gelir kaybı kabul edilir | Uzaktan düzeltme yok |
| Reklam doldurmuyor | `ad_load_failed`, `banner_failed` | 3 deneme sonrası vazgeç; banner alanı serbest kalır | Kullanıcı akışı kilitlenmez |
| UMP formu açılmıyor | `push_warning`, `consent_finished(false)` | Reklamsız devam; analitik rızası ayrı kalır | EEA kartı eksikliği ayrı P0 |
| Hatalı bölüm | Bölüm bazlı `level_fail` artışı, yorumlar | Yeni sürümde düzelt veya bölümü geri çek | Sıcak düzeltme yok |
| Kayıt bozulması | Açılışta ilerleme sıfır | Kullanıcıya bildir; yerel veriyi silme seçeneği | Bulut yedek yok |
| Sürüm regresyonu | Play Console çökme artışı | Aşamalı yayını durdur; önceki sürüme dönüş | Play dağıtımıyla sınırlı |
| Gizlilik ihlali şüphesi | Kod/log incelemesi | Reklam ve telemetriyi kapatacak sürüm | Uzaktan kill switch yok |

## 7. Sürüm ritmi ve geriye dönük uyumluluk

- Sürümler P0/P1 backlog'una göre çıkar; takvim vaadi yoktur.
- `versionCode` her yüklemede artar; `versionName` anlamlı bir değişiklikte artar.
- Kayıt biçimi değişirse `load_save()` eski anahtarları okumaya devam eder; yeni alanlar varsayılanla gelir.
- Zorunlu güncelleme yoktur; eski sürümler oyunu oynamaya devam eder.
- Reklam kimlikleri ve gizlilik metni değişirse aynı sürümde Data Safety güncellenir.

## 8. Açık işler

- **Açık:** Uzaktan yapılandırma, özellik bayrağı ve kill switch yok.
- **Açık:** Push bildirimi, günlük hatırlatma ve gerçek günlük içerik yok.
- **Açık:** Lig sezonu, sıfırlama ve gerçek rakip verisi yok.
- **Açık:** Destek e-postası, mağaza yorum triyajı ve gizlilik iletişim adresi yok.
- **Açık:** Çökme/ANR izleme yok; olay tespiti mağaza panosuna bağımlı.
- **Planlanan:** İçerik doğrulayıcı, bölüm paketleri, mevsimsel etkinlik altyapısı.
