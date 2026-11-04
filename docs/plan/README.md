# Bundoku ürün planı

Bu dizin, oyunun ne olduğunu ve yayına kadar hangi kararların verilmesi gerektiğini belgeleyen plan setidir. Numaralar sabittir; **03 ve 07 numaralı belgeler bu ağaçta yoktur**. Her belge "Mevcut / Planlanan / Açık" etiketlerini kullanır.

Üst indeks: [../README.md](../README.md). Uygulama sürümü: Android `1.0.4` (`versionCode 5`).

## Okuma sırası

1. [01_PRODUCT_STRATEGY.md](01_PRODUCT_STRATEGY.md) — kime, neden, hangi sınırlar içinde.
2. [02_CORE_GAMEPLAY.md](02_CORE_GAMEPLAY.md) — kurallar ve etkileşim sözleşmesi.
3. [04_CONTENT_AND_PROGRESSION.md](04_CONTENT_AND_PROGRESSION.md) — 120 bölümün yapısı ve kilit açma.
4. [05_ECONOMY_MONETIZATION.md](05_ECONOMY_MONETIZATION.md) — ipucu/havuç, reklam aralıkları, planlanan IAP.
5. [06_UI_UX_LOCALIZATION.md](06_UI_UX_LOCALIZATION.md) — ekranlar, güvenli alan, 20 dil.
6. [08_TECHNICAL_ARCHITECTURE.md](08_TECHNICAL_ARCHITECTURE.md) — kod ve veri akışı.
7. [09_ANALYTICS_EXPERIMENTS.md](09_ANALYTICS_EXPERIMENTS.md) — ne ölçülüyor, ne ölçülecek.
8. [10_PRODUCTION_BACKLOG.md](10_PRODUCTION_BACKLOG.md) — iş listesi.
9. [11_STORE_RELEASE.md](11_STORE_RELEASE.md) — mağaza ve sürümleme.
10. [12_LAUNCH_LIVEOPS.md](12_LAUNCH_LIVEOPS.md) — yayın sonrası.
11. [13_QA_ACCEPTANCE.md](13_QA_ACCEPTANCE.md) — kabul kanıtı.
12. [14_SOURCES_DECISIONS.md](14_SOURCES_DECISIONS.md) — kaynak ve karar kaydı.

## Belge özeti

| Belge | Ana soru | Durum | Bağımlı olduğu belge |
|---|---|---|---|
| [01_PRODUCT_STRATEGY.md](01_PRODUCT_STRATEGY.md) | Hangi oyuncuya, hangi farkla satıyoruz? | Mevcut | — |
| [02_CORE_GAMEPLAY.md](02_CORE_GAMEPLAY.md) | Kurallar ve dokunma davranışı tam olarak nedir? | Mevcut | 01 |
| [04_CONTENT_AND_PROGRESSION.md](04_CONTENT_AND_PROGRESSION.md) | 120 bölüm nasıl üretildi, nasıl açılıyor? | Mevcut | 02 |
| [05_ECONOMY_MONETIZATION.md](05_ECONOMY_MONETIZATION.md) | Para ve reklam dengesi nedir? | Mevcut + Planlanan | 02, 04 |
| [06_UI_UX_LOCALIZATION.md](06_UI_UX_LOCALIZATION.md) | Ekranlar ve diller nasıl çalışıyor? | Mevcut + Açık | 02 |
| [08_TECHNICAL_ARCHITECTURE.md](08_TECHNICAL_ARCHITECTURE.md) | Kod hangi katmanlardan oluşuyor? | Mevcut | 02, 04 |
| [09_ANALYTICS_EXPERIMENTS.md](09_ANALYTICS_EXPERIMENTS.md) | Hangi davranış ölçülüyor? | Mevcut + Planlanan | 05, 08 |
| [10_PRODUCTION_BACKLOG.md](10_PRODUCTION_BACKLOG.md) | Sıradaki işler neler? | Planlanan | 01–09 |
| [11_STORE_RELEASE.md](11_STORE_RELEASE.md) | Mağazaya çıkmak için ne eksik? | Planlanan + Açık | 05, 06, 09 |
| [12_LAUNCH_LIVEOPS.md](12_LAUNCH_LIVEOPS.md) | Yayından sonra ne olacak? | Planlanan | 09, 11 |
| [13_QA_ACCEPTANCE.md](13_QA_ACCEPTANCE.md) | Hangi senaryolar kabul edildi? | Mevcut + Açık | 02–08 |
| [14_SOURCES_DECISIONS.md](14_SOURCES_DECISIONS.md) | Hangi karar hangi kanıta dayanıyor? | Mevcut | Tümü |

## Yayın ve mağaza belgeleri

| Belge | Ana soru |
|---|---|
| [../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md) | Yayın gününde hangi maddeler işaretlenmeli? |
| [../release/VERSION_HISTORY.md](../release/VERSION_HISTORY.md) | Hangi sürümde ne değişti? |
| [../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md) | Play veri güvenliği formu ve mağaza metni ne diyecek? |

## Açık kararlar

Aşağıdakiler plan belgelerinde işaretlenmiştir; sahibi ve tarihi yoktur, uydurulmaz.

| # | Karar | Neden gerekli | İlgili belge |
|---|---|---|---|
| K1 | IAP "reklamsız" ürünü ve fiyatı | `no_ads_purchased` bayrağı var, satın alma akışı yok | [05](05_ECONOMY_MONETIZATION.md), [11](11_STORE_RELEASE.md) |
| K2 | Ödüllü reklamda sunucu tarafı doğrulama (SSV) | Ödül şu an istemci tarafında veriliyor | [05](05_ECONOMY_MONETIZATION.md) |
| K3 | EEA/UK/CH için analitik rıza kartı | Bölgede satırlar bellekte tutuluyor, kullanıcıya soru sorulmuyor | [09](09_ANALYTICS_EXPERIMENTS.md), [../privacy/PRIVACY_POLICY_DRAFT.md](../privacy/PRIVACY_POLICY_DRAFT.md) |
| K4 | Gizlilik politikası URL'si ve app-ads.txt | Play beyanı ve reklam ağı doğrulaması için zorunlu | [11](11_STORE_RELEASE.md), [../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md) |
| K5 | Kalıcı yayın anahtarı | Şu an geçici `bundoku_release.keystore` kullanılıyor | [11](11_STORE_RELEASE.md), [../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md) |
| K6 | Sürüm numarası tek kaynağı | `project.godot` 1.0.0, Android 1.0.4 | [08](08_TECHNICAL_ARCHITECTURE.md), [../release/VERSION_HISTORY.md](../release/VERSION_HISTORY.md) |
| K7 | Arapça/Urduca RTL aynalama | Metin var, yerleşim aynalanmıyor | [06](06_UI_UX_LOCALIZATION.md) |
| K8 | `assets/ui/` köken ve lisans temizliği | Meowdoku'dan alınmış varlık beyanı var | [../research/MEOWDOKU_REFERENCE.md](../research/MEOWDOKU_REFERENCE.md) |

## Plan belgesi yazım kuralları

- Bölüm başlıkları önce kararı, sonra uygulamayı anlatır.
- Karşılaştırılabilir veriler tabloya yazılır; düz metin yalnızca gerekçe için kullanılır.
- "Mevcut" satırı bir dosya yoluna işaret etmelidir.
- "Planlanan" satırı bir kabul ölçütü içermelidir.
- Ölçülmemiş D1/D7, eCPM, gelir veya kullanıcı sayısı hedef olarak yazılmaz; yalnızca "ölçülecek metrik" olarak tanımlanır.
- Mağaza durumu, inceleme sonucu veya yayın tarihi doğrulanmadan yazılmaz.

## Bakım

| Tetikleyici | Güncellenecek belge |
|---|---|
| Yeni bölüm veya seviye kuralı | 02, 04 |
| Booster/reklam dengesi değişikliği | 05, 09 |
| Yeni dil veya ekran | 06, 13 |
| Autoload/veri şeması değişikliği | 08, 09 |
| Sürüm artışı | 11, `release/VERSION_HISTORY.md` |
| Yeni risk | 14, `AI/PROJECT_HEALTH.md` |
