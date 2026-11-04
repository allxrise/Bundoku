# Ekonomi ve Monetizasyon

> **Özet:** Bugünkü ekonomi tek para birimsizdir: ipucu ve altın havuç sayıları, reklamla beslenen iki yumuşak
> kaynaktır. Satın alma (IAP), mağaza, sezon ve gerçek para girişi yoktur. Reklam geliri AdMob üzerinden
> planlanmıştır ancak yayın kimlikleri hâlâ Google test birimleridir. Bu belge mevcut akışları, planlanan IAP
> yönünü, reklam sıklığını ve etik/politika sınırlarını ayırır.
> Kaynaklar: [`scripts/core/game_state.gd`](../../scripts/core/game_state.gd),
> [`scripts/ui/main_controller.gd`](../../scripts/ui/main_controller.gd),
> [`scripts/ads/ad_manager.gd`](../../scripts/ads/ad_manager.gd),
> [`assets/ads/ads_config.json`](../../assets/ads/ads_config.json).

Durum etiketleri: **Mevcut**, **Planlanan**, **Açık**.

## 1. Mevcut kaynaklar ve harcamalar

| Öğe | Başlangıç | Kaynak | Harcama | Kalıcı |
|---|---|---|---|---|
| İpucu | 5 | Her 2. seviyenin **ilk** çözümünde +1; ödüllü reklamla +2 | 1 / ipucu kullanımı | Evet (`progress/hints_count`) |
| Altın havuç | 3 | Her 4. seviyenin **ilk** çözümünde +1; ödüllü reklamla +2 | 1 / havuç kullanımı | Evet (`progress/carrots_count`) |
| Kupa | 120 | Her çözümde `10 + stars × 5` | Yok (harcanmıyor) | Evet (`progress/player_trophies`) |
| Can | 3 (seviye başına) | Her seviye başında sıfırlanır; reklamla yenilenir | Hatalı tavşan başına 1 | Hayır |
| Yıldız | 0 | Çözüm kalitesi (hata + süre) | Yok | Evet (`completed_levels`) |
| Reklamsız | `false` | **Planlanan** IAP | — | Evet ama hiç `true` olmuyor |

Kod kanıtı: `GameState.complete_level()` içindeki `bonus_hint` / `bonus_carrot` blokları yalnızca
`prev_stars == 0` (ilk çözüm) durumunda çalışır; `(idx + 1) % 2 == 0` ve `(idx + 1) % 4 == 0` koşulları
seviye numarasına bağlıdır, kademeye değil. Yani 2, 4, 6… numaralı seviyeler ipucu; 4, 8, 12… numaralı seviyeler
havuç verir (4. seviye ikisini birden verir).

## 2. Booster davranışı

| Booster | Etki | Ücret | Sıfırken | Kaynak |
|---|---|---|---|---|
| İpucu | `HintSolver`'ın seçtiği tek mantık adımını uygular ve açıklar | 1 ipucu | Ödüllü reklam teklifi → +2 ipucu | `_on_hint_pressed()` |
| Altın havuç | En çok boş hücresi olan bölgenin çözüm tavşanını açar; çakışan tavşanları cezasız kaldırır | 1 havuç | Ödüllü reklam teklifi → +2 havuç | `_on_carrot_pressed()` |
| Can yenileme (revive) | 3 can + otomatik ipucu | Ödüllü reklam | — | `_on_revive_ad_completed()` |
| Taslak modu | Güvenli deneme | **Ücretsiz** | — | `toggle_draft_mode()` |

İpucu sonucu boş dönerse (`res.is_empty()`) sayaç düşmez; havuç da aday bulamazsa harcanmaz. Reklamla gelen
+2 ödülü `GameState.add_free_boosters()` üzerinden yazılır.

## 3. Reklam sıklığı (Mevcut)

Zorunlu tam ekran reklam (interstitial) yalnızca **çözümden sonra** teklif edilir (`level_break`): kazanma
ekranından önce gösterilir. Oyun sırasında zorunlu reklam yoktur; ödüllü reklam yalnızca oyuncu isterse açılır.

| Kademe | Aralık (çözülen seviye) | Kod |
|---|---|---|
| `easy` | 5 | `AD_INTERVAL_BY_TIER` |
| `medium` | 4 | aynı |
| `hard` | 3 | aynı |
| `expert` | 2 | aynı |
| `super_hard` | 1 | Tanımlı ama veritabanında bu kademe yok |

| Kural | Ayrıntı |
|---|---|
| Sayaç | `levels_since_last_ad` **global** tek sayaç; kademe değişince sıfırlanmaz, eşik yeni kademeden okunur |
| Sıfırlama | Reklam gösterildiğinde 0'lanır ve `total_ads_watched` +1 olur |
| Reklamsız bayrağı | `no_ads_purchased = true` ise interstitial sayacı artmaz; ödüllü istekler yine sorulabilir |
| Banner | Alt uyarlanabilir banner sürekli açık; tam ekran reklam sırasında gizlenir, alanı korunur |
| Ödüllü | Yalnızca oyuncu isterse: ipucu/havuç sıfırken veya can bitince |
| Simülasyon | SDK yoksa/fill yoksa 3 saniyelik modal; ödül yine verilir, gelir yok (`simulated=1`) |

## 4. Gerçek ve simüle reklam ayrımı

| Durum | Ne olur | Gelir | Telemetri |
|---|---|---|---|
| Android + SDK + dolu reklam | AdMob interstitial/rewarded gösterilir | Evet (ILARE ile) | `ad_shown simulated=0`, `ad_impression` |
| Masaüstü/editör | Simüle modal (3 sn) | Hayır | `ad_shown simulated=1` |
| Android, fill yok / yükleme başarısız | Simüle modal | Hayır | `ad_shown simulated=1` |
| Ödüllü reklam yarıda kapatıldı | Ödül verilmez (`Ads.ad_rewarded` gelmedi) | Kısmi | `ad_closed`, tamamlama çağrısı yok |
| Politika: reklam yüklenemedi | Oyuncu cezalandırılmaz | — | Simüle akış devam eder |

Gerçek reklamda `_show_ad_modal()` önce `Ads.show_interstitial()` / `Ads.show_rewarded()` çağırır; `true`
dönerse modal açılmaz ve seviye süresi `_ad_is_active` ile durur. Ödüllü tamamlama yalnızca
`_pending_ad_reward_earned` işaretliyse çalışır (`_on_ads_ad_closed()`).

## 5. Ölçüm ve gelir telemetrisi

| Olay | Ne zaman | Kritik parametre | Kaynak |
|---|---|---|---|
| `ad_offered` | Teklif açıldığında, bir kez | `placement`, `format`, `level` | `main_controller._show_ad_modal()` |
| `ad_shown` | Reklam gerçekten gösterildiğinde | `simulated` (0/1) | aynı |
| `ad_closed` | Reklam/modal kapandığında | `watched_sec`, `simulated` | aynı / `_on_ads_ad_closed()` |
| `ad_impression` | Yalnızca gerçek AdMob ödemesi (ILARE) | `ad_format`, `ad_source`, `value`, `currency`, `precision`, `placement` | `ad_manager.gd` |
| `ad_load_failed` | Yükleme hatası (dakikada en çok bir kez) | format | `ad_manager.gd` |
| `banner_failed` | Banner yüklemesi başarısız (deneme numarasıyla) | `attempt` | `ad_manager.gd` |

eCPM ancak `ad_impression` satırlarından hesaplanabilir: `value / gösterim × 1000`. Bugün tüm birimler test
kimliği olduğu için gerçek `value` gelmez. Tanım ve şema: [`../analytics/EVENTS.md`](../analytics/EVENTS.md),
[`../analytics/BIGQUERY.md`](../analytics/BIGQUERY.md). Reklam entegrasyon ayrıntısı:
[`../ads/INTEGRATION.md`](../ads/INTEGRATION.md).

## 6. Planlanan monetizasyon

| Öğe | Durum | Tasarım notu |
|---|---|---|
| Reklamsız IAP | **Planlanan** | Bayrak banner'ı ve interstitial zamanlamasını durduruyor; ödüllü reklamlar açık kalır; satın alma akışı yok |
| İpucu paketleri | **Planlanan** | Mevcut `add_free_boosters()` çağrılabilir; mağaza/ürün kimliği yok |
| Ödüllü SSV | **Açık** | Ödül istemci tarafında veriliyor; sunucu doğrulaması yok, hile mümkün |
| Fiyat/ürün kataloğu | **Açık** | Play Console ürünleri tanımlı değil; fiyat uydurulmamalı |
| Reklam sıklığı A/B | **Planlanan** | Ölçüm altyapısı olmadan test edilemez |

`no_ads_purchased` banner yüklemesini ve yeniden gösterimini engelliyor (`ad_manager.gd`
`_load_banner()`, `_restore_banner()`), ayrıca `game_state.gd` içinde interstitial sayacını durduruyor. Ancak
ödüllü reklam istekleri bu bayrağı **kontrol etmez** ve hiçbir kod bayrağı `true` yapmıyor; gerçek bir satın alma
akışı eklenmeden "reklamsız" davranışı garanti edilemez. Satın alma kaydı düz `ConfigFile` içinde tutulacaksa
mağaza doğrulaması (Play Billing makbuzu) gerekir; yerel dosya tek başına güvenilir değildir.

## 7. Etik ve politika sınırları

| Kural | Gerekçe | Mevcut uygulama |
|---|---|---|
| Oyun sırasında zorunlu reklam yok | Deneyim ve mağaza politikası | Yalnızca çözüm sonrası interstitial |
| Ödül gerçekten izlenerek kazanılır | Aldatıcı reklam yasağı | Ödüllü reklam yarıda kapanırsa ödül yok |
| Reklam gelirle bağlantılı ödül vaadi yok | Çocuk/yanıltıcılık riski | Metinler "+2 ipucu" diyor, para vaadi yok |
| Reklam kişiselleştirme rızası ayrı | GDPR/KVKK | UMP; reklam sinyali rızası analitikten bağımsız |
| Reklamsız satın alma reklamı kaldırır | Tüketici beklentisi | Bayrak hazır, ürün yok; yayına kadar vaat edilmemeli |
| Çocuk kitlesi | Yaş grubu belirsiz | Mağaza hedef kitle ve veri güvenliği formu doldurulmalı ([`../store/DATA_SAFETY_AND_LISTING.md`](../store/DATA_SAFETY_AND_LISTING.md)) |
| Test kimlikleriyle yayın yok | Politika ihlali | `test_mode: true`, tüm birimler test |

Ekonomi "pay-to-win" değildir: ipucu/havuç yalnızca zaman kazandırır, seviye atlamaz; reklam izlemek zorunlu
değildir, oyuncu seviyeyi kendi başına bitirebilir.

## 8. Riskler ve açık maddeler

| Risk / açık | Etki | Not |
|---|---|---|
| Test reklam kimlikleri | Sıfır gelir, politika riski | Yayın öncesi gerçek birimler + `test_mode: false` |
| `app-ads.txt` yok | Meta/AdMob doğrulaması zayıf | Domain ve dosya gerekli |
| SSV yok | Ödüllü ödül hilesi | Sunucu tarafı doğrulama |
| EEA analitik rıza kartı yok | Ölçüm ve uyum boşluğu | [`../analytics/PRIVACY_AND_CONSENT.md`](../analytics/PRIVACY_AND_CONSENT.md) |
| Kupa çiftçiliği | Lig/ekonomi anlamsız | Tekrar çözümde kupa kısıtlanmalı |
| Booster enflasyonu | İpucu değersizleşir | Kullanım/ödül oranı ölçülmeli (`booster_used`) |
| IAP yok | "Reklamsız" talebi karşılanamıyor | Planlanan; mağaza ürünü + `no_ads` yazımı |
| Reklam aralığı kademeye göre sert | `expert` 2 seviyede bir | Ölçüm sonrası ayar; D7 ile birlikte değerlendir |

## 9. İlgili belgeler

- Reklam entegrasyonu: [`../ads/INTEGRATION.md`](../ads/INTEGRATION.md)
- Olay sözlüğü: [`../analytics/EVENTS.md`](../analytics/EVENTS.md)
- Gizlilik ve rıza: [`../analytics/PRIVACY_AND_CONSENT.md`](../analytics/PRIVACY_AND_CONSENT.md)
- Deneyler ve metrikler: [`09_ANALYTICS_EXPERIMENTS.md`](09_ANALYTICS_EXPERIMENTS.md)
- Yayın ve mağaza: [`11_STORE_RELEASE.md`](11_STORE_RELEASE.md), [`../store/DATA_SAFETY_AND_LISTING.md`](../store/DATA_SAFETY_AND_LISTING.md)
- Ürün stratejisi: [`01_PRODUCT_STRATEGY.md`](01_PRODUCT_STRATEGY.md)
