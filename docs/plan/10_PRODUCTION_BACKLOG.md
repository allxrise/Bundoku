# 10 — Üretim backlog'u

> **Karar:** İlk mağaza sürümü yalnızca P0 listesi kapandığında yayınlanır. P0 maddeleri hukuki, güvenlik,
> mağaza politikası veya gelir kaybı riski taşır; P1 maddeleri yayın sonrası ilk sürümlerde, P2 maddeleri
> doğrulama gerektiren genişleme işleridir. Tarih, efor ve gelir tahmini verilmez.

Etiketler: **Açık** (henüz yok), **Planlanan** (karar verildi), **Mevcut** (kodda var).
Bağımlı belgeler: [../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md),
[11_STORE_RELEASE.md](11_STORE_RELEASE.md), [13_QA_ACCEPTANCE.md](13_QA_ACCEPTANCE.md),
[05_ECONOMY_MONETIZATION.md](05_ECONOMY_MONETIZATION.md).

## 1. Öncelik tanımı

| Seviye | Anlam | Kapı |
|---|---|---|
| P0 | Yayını engeller | Mağazaya yükleme öncesi kapanmalı |
| P1 | Yayın sonrası ilk sürümler | P0 sonrası sıralanır |
| P2 | Genişleme / doğrulama | Ürün kararı ve ölçüm gerektirir |

## 2. P0 — Yayın engelleyicileri

| ID | Alan | İş | Kabul ölçütü | Durum |
|---|---|---|---|---|
| PB-01 | Reklam | Gerçek AdMob App ID'sini `project.godot` `[admob]` bölümüne ekle | `aapt2 dump xmltree` gerçek `APPLICATION_ID` gösterir; test ID yok | **Açık** |
| PB-02 | Reklam | Gerçek interstitial/rewarded/banner birimlerini `assets/ads/ads_config.json`'a yaz, `test_mode=false` | APK içinde `ca-app-pub-3940256099942544` geçmez | **Açık** |
| PB-03 | Güvenlik | Keystore parolalarını `export_presets.cfg`'den çıkar; gizli yönetime taşı; geçici release anahtarını döndür | Depoda parola yok; yeni anahtarla imzalı çıktı üretilir | **Açık** |
| PB-04 | Hukuk | Meowdoku'dan alınan UI/ses varlıklarını değiştir veya lisansla; `assets/chatgpt_ui` kökenini belgele | Varlık kökeni tablosu ve lisans kaydı; kod yorumlarında "extracted" ifadesi kalmaz | **Açık** |
| PB-05 | Gizlilik | Yayınlanmış gizlilik politikası URL'si ve oyun içi erişim | URL mağaza listesinde ve dil modalında; içerik [../privacy/PRIVACY_POLICY_DRAFT.md](../privacy/PRIVACY_POLICY_DRAFT.md) ile uyumlu | **Açık** |
| PB-06 | Gizlilik | EEA/UK/CH analitik rıza kartı; ret durumunda yerel satırları sil | Rıza `set_consent` ile yazılır; ret sonrası dosyalar temizlenir; EEA senaryosu test edilir | **Açık** |
| PB-07 | Sürüm | `project.godot` sürümünü tek kaynağa bağla (`1.0.4` / `versionCode 5` ile hizala) | İki dosyada aynı sürüm; bump adımı belgelenir | **Açık** |
| PB-08 | Reklam | `app-ads.txt` dosyasını geliştirici alan adı kökünde yayınla; Meta mediation grubunu doğrula | `https://<alan>/app-ads.txt` 200 döner; Meta kaynaklı gösterim logda görülür | **Açık** |
| PB-09 | Yayın | AAB üret, release anahtarıyla imzala, Play internal testing'e yükle | Play'den kurulan sürüm Pixel 9'da açılır; imza doğrulanır | **Açık** |
| PB-10 | Mağaza | `READ_BASIC_PHONE_STATE` iznini kaldır veya gerekçelendir/beyan et | İzin yok ya da Data Safety ve manifest gerekçesi tutarlı | **Açık** |
| PB-11 | Mağaza | Data Safety formu, içerik derecelendirmesi, hedef kitle ve reklam beyanı | Formlar [../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md) ile birebir | **Açık** |
| PB-12 | QA | Release imzalı APK/AAB ile tam regresyon | [13_QA_ACCEPTANCE.md](13_QA_ACCEPTANCE.md) çıkış kriterleri sağlanır | **Açık** |

## 3. P1 — Yayın sonrası ilk sürümler

| ID | Alan | İş | Kabul ölçütü | Durum |
|---|---|---|---|---|
| PB-13 | Gelir | Reklamsız IAP; `no_ads_purchased` satın alma sonrası kalıcı olur | Banner ve interstitial yüklenmez; ayar kayda yazılır | **Planlanan** |
| PB-14 | Gelir | İpucu/havuç paketleri (tüketilebilir) | Satın alma makbuzu doğrulanır; bakiye çift artmaz | **Planlanan** |
| PB-15 | Reklam | Rewarded ödüller için sunucu tarafı doğrulama (SSV) | Ödül yalnız doğrulanmış imzayla verilir | **Planlanan** |
| PB-16 | Operasyon | Çökme/ANR raporlaması | Sürüm ve cihaz bilgisiyle rapor; kişisel veri yok | **Planlanan** |
| PB-17 | i18n | Arapça/Urduca RTL yönü ve aynalama | `layout_direction` uygulanır; ekranlar taşmaz | **Açık** |
| PB-18 | i18n | Çoğul ve tarih/süre biçimleri | "1 Days" gibi hatalar kalmaz; dil bazlı çoğul testi | **Açık** |
| PB-19 | Erişilebilirlik | Kontrast, dokunma hedefi, ekran okuyucu etiketleri | WCAG AA kontrast; min 44×44 dp hedef; odak sırası | **Planlanan** |
| PB-20 | Veri | Kayıt bütünlüğü: şifreleme veya imza, yedekleme/geri yükleme | Bozuk kayıt algılanır; kullanıcıya bildirilir | **Planlanan** |
| PB-21 | İçerik | Gerçek günlük bölüm ve seri takibi | Günlük bölüm tarihe göre benzersiz; seri kayda yazılır | **Planlanan** |
| PB-22 | İçerik | Lig sezonu/sıfırlama ve gerçek rakip verisi | Sezon sonu ödül; botlar yerine sunucu verisi | **Planlanan** |
| PB-23 | Analitik | Sunucu sink'i ve panolar | JSONL otomatik yüklenir; D1/D7 panoda | **Planlanan** |
| PB-24 | Mühendislik | Otomatik testler ve CI | Bölüm doğrulama + kritik akış testleri her PR'da | **Planlanan** |
| PB-25 | İçerik | Depo içi bölüm doğrulayıcı | 120 bölüm + yeni bölümler tek komutla doğrulanır | **Planlanan** |
| PB-26 | Reklam | Çevrimdışı/no-fill davranış denetimi | Simüle modal tutarlı; kullanıcı akışı kilitlenmez | **Açık** |

## 4. P2 — Genişleme

| ID | Alan | İş | Kabul ölçütü | Durum |
|---|---|---|---|---|
| PB-27 | Platform | iOS export ve App Store gereksinimleri | İmzalı build; iOS reklam kimlikleri | **Planlanan** |
| PB-28 | Altyapı | Hesap, bulut kayıt, cihazlar arası ilerleme | Çakışma çözümü ve gizlilik güncellemesi | **Planlanan** |
| PB-29 | İçerik | 120 sonrası bölüm paketleri | Yeni paketler doğrulayıcıdan geçer | **Planlanan** |
| PB-30 | UI | Tablet ve büyük ekran yerleşimi | 4:3 ve 16:10'da taşma yok | **Planlanan** |
| PB-31 | i18n | 20 dil için ana dili konuşuru incelemesi | Dil başına onay kaydı | **Planlanan** |
| PB-32 | Performans | Release profil ve bellek bütçesi | `performance_sample` ile regresyon eşiği | **Planlanan** |

## 5. Kapsam dışı (bilinçli)

- Oyun sırasında zorunlu (kapatılamaz) tam ekran reklam yok.
- Pay-to-win, loot box, enerji satışı yok.
- Kullanıcı hesabı, sosyal özellik veya sohbet yok (P2'de hesap kararı ayrıca verilir).
- Ücretli "yıldız satın alma" yok; yıldız yalnız oyunla kazanılır.

## 6. Tanımlama ve bakım kuralları

Kaynak: mevcut davranış iddiaları `scripts/`, `export_presets.cfg` ve derlenmiş APK çıktısına dayanır;
yayın kapıları [../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md) ile eşlenir.

1. Her satır tek bir doğrulanabilir çıktı üretir; "iyileştir" gibi ölçülemez iş kabul edilmez.
2. Bir P0 kapanmadan yenisi açılırsa yayın kapısı yeniden değerlendirilir.
3. P1/P2 işleri ölçüm (`09`) veya mağaza gereksinimi olmadan başlatılmaz.
4. Tamamlanan iş bu tablodan silinmez; **Mevcut** etiketi ve kanıt bağlantısıyla arşivlenir.
5. Sürüm notları [../release/VERSION_HISTORY.md](../release/VERSION_HISTORY.md) içine işlenir.
