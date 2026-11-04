# 14 — Kaynaklar ve kararlar

> **Karar:** Bu depodaki her teknik iddia bir dosyaya veya ölçüme bağlanır. Belgeler çeliştiğinde önce kod ve
> derlenmiş çıktı, sonra bu sayfa, en son anlatı belgeleri gelir. Aşağıdaki karar kaydı geriye dönük
> gerekçeleri tutar; değişen karar silinmez, yeni satırla geçersiz kılınır.

Etiketler: **Mevcut**, **Planlanan**, **Açık**. Ölçüm politikası:
[09_ANALYTICS_EXPERIMENTS.md](09_ANALYTICS_EXPERIMENTS.md).

## 1. Kaynak hiyerarşisi

| Öncelik | Kaynak | Ne için |
|---|---|---|
| 1 | Derlenmiş APK / `aapt2` çıktısı | Paket kimliği, izinler, SDK, ABI, yön |
| 2 | `project.godot`, `export_presets.cfg` | Motor, autoload, sürüm, ekran, imza yolları |
| 3 | `scripts/**/*.gd` | Davranış, kural, olay, reklam akışı |
| 4 | `assets/levels/levels_database.json` | Bölüm içeriği ve dağılımı |
| 5 | `android/build/config.gradle` | SDK, NDK, Java, build tools |
| 6 | `docs/**` | Yorum ve karar; kodla çelişirse kod kazanır |
| 7 | `REA/README.md`, `docs/research/` | Referans oyun analizi; ürün kodu değil |

## 2. Karar kaydı

| ID | Karar | Gerekçe | Bedel / sonuç | Durum |
|---|---|---|---|---|
| D-01 | Tek sahne + kodla üretilen UI | Tema tutarlılığı, hızlı yineleme, 9-slice denetimi | UI düğümleri editörde görünmez; yeniden kurma maliyeti | **Mevcut** |
| D-02 | 120 bölüm gömülü JSON | Çevrimdışı, sunucusuz, deterministik | Sıcak düzeltme yok; paket büyür | **Mevcut** |
| D-03 | Düz `ConfigFile` kayıt | Basit, okunabilir, hızlı | Şifresiz; hile ve bozulma riski | **Mevcut** |
| D-04 | Yerel-öncelikli telemetri | Sunucu maliyeti yok; rıza kapısı tek yerde | D1/D7 için operatör dışa aktarımı gerekir | **Mevcut** |
| D-05 | AdMob + UMP + Meta mediation | Tek SDK ile interstitial/rewarded/banner | Test kimlikleri, SSV yok, SDK veri beyanı gerekir | **Mevcut** |
| D-06 | İpucu hattı Meowdoku mantığını izler | Kanıtlanmış adım sırası; 120/120 çözüm | Referansla davranışsal benzerlik | **Mevcut** |
| D-07 | 20 dil tek `DATA` sözlüğünde | Derleme bağımlılığı yok; fallback basit | Çeviri dosyası yok; RTL/çoğul altyapısı yok | **Mevcut** |
| D-08 | Reklam yoksa simüle modal | Masaüstü/editörde akış kırılmaz | Simüle gösterim gelir üretmez; metrikler ayrılmalı | **Mevcut** |
| D-09 | 1.0'da IAP yok | Kapsamı dar tutmak | `no_ads_purchased` kablolu ama hep `false` | **Açık** |
| D-10 | Android-öncelikli, 540×960 dikey | Tek elle oynanış, referansla aynı niş | iOS ve tablet kapsam dışı | **Mevcut** |
| D-11 | Yayına kadar test reklam kimlikleri | Politika gereği güvenli geliştirme | Yayın öncesi değiştirilmezse gelir yok | **Açık** |
| D-12 | Varsayılan dil `tr`, fallback `en → tr` | Hedef pazar Türkçe; eksik anahtar boş kalmaz | İngilizce metinlerde çoğul hatası | **Mevcut** |
| D-13 | Yıldız: hata/süre eşiği | Basit, oyuncuya açıklanabilir | Süre eşiği zor bölümlerde baskı yaratabilir | **Mevcut** |
| D-14 | Zorunlu interstitial oyun sırasında değil, bölüm sonunda | Oynanışı kesmemek | `level_break` kazanma modalından hemen önce; ödüllü reklam oyuncu isteğine bağlı | **Mevcut** |
| D-15 | Lig yerel simülasyon | Sunucusuz MVP | Gerçek rekabet ve sezon yok | **Mevcut** |

## 3. Ölçülmüş çelişkiler

| Çelişki | Ölçüm | Etki |
|---|---|---|
| Sürüm | `project.godot` `1.0.0`; `export_presets.cfg` `1.0.4` / code 5 | Telemetri `app_version` yanlış; destek karışıklığı |
| Motor özellikleri | `project.godot` çalışma ağacında `"4.7"` (commit'li değer `"4.4"`); `docs/README.md` ve `docs/analytics/EVENTS.md` "Godot 4.4" | Belgelerde eski ifade; hangi değerin kalacağı karar bekliyor |
| Yön | `android/build/src/main/AndroidManifest.xml` `landscape`; derlenen APK `screenOrientation=1` (portrait) | Şablon dosyası yanıltıcı; export'ta yeniden üretiliyor |
| AdMob App ID | `ads_config.json` yorumu "App ID `project.godot` içinde" der; `project.godot` içinde `app_id` yok | APK eklenti varsayılan test ID'sini taşır |
| `steps` alanı | 120 bölümün 90'ında `steps != size`; kod alanı okumaz | Veri gürültüsü; yanlış varsayım riski |
| APK boyutu | Debug APK yaklaşık 185 MB | Mağaza indirme boyutu için release ölçümü gerekir |

## 4. Kaynak eşlemesi

| İddia | Birincil kaynak |
|---|---|
| Autoload sırası ve adları | `project.godot` |
| Oyun kuralları, can, yıldız, kupa, bonus | `scripts/core/game_state.gd` |
| Etkileşim, oto-X, taslak, geri alma | `scripts/gameplay/board_view.gd` |
| İpucu adım sırası | `scripts/gameplay/hint_solver.gd` |
| Ekranlar, modaller, reklam teklifi | `scripts/ui/main_controller.gd` |
| Reklam yükleme, UMP, banner | `scripts/ads/ad_manager.gd`, `assets/ads/ads_config.json` |
| Olay sözlüğü, rıza, rotasyon | `scripts/core/telemetry.gd`, `docs/analytics/EVENTS.md` |
| Bölüm dağılımı ve çözümler | `assets/levels/levels_database.json` |
| 20 dil ve fallback | `scripts/core/loc.gd` |
| Paket, sürüm, imza, izinler | `export_presets.cfg`, APK `aapt2` çıktısı |
| SDK/NDK/Java | `android/build/config.gradle` |
| Referans oyun davranışı | [../../REA/README.md](../../REA/README.md), [../research/MEOWDOKU_REFERENCE.md](../research/MEOWDOKU_REFERENCE.md) |

## 5. Açık kararlar

| ID | Soru | Neden bekliyor | Karar sahibi |
|---|---|---|---|
| O-01 | Reklamsız deneyim ücretli mi, abonelik mi? | IAP yok; fiyat ve politika belirsiz | Ürün |
| O-02 | Hedef kitle çocuk mu, genel mi? | Çocuk beyanı Families politikası ve reklam kısıtı getirir | Ürün / hukuk |
| O-03 | Meowdoku kaynaklı varlıklar değiştirilecek mi, lisanslanacak mı? | Köken ve lisans kaydı yok | Ürün / hukuk |
| O-04 | Analitik sunucusu hangi sağlayıcı? | Maliyet, KVKK/GDPR, saklama süresi | Teknik |
| O-05 | Günlük bölüm gerçek içerik mi olacak? | Sunucu ve içerik hattı gerekir | Ürün |
| O-06 | Lig gerçek mi kalacak, kaldırılacak mı? | Simülasyon uzun vadede inandırıcı değil | Ürün |
| O-07 | RTL ve çeviri kalitesi 1.0 kapsamında mı? | 20 dil iddiası ile çelişiyor | Ürün |

## 6. Kanıt boşlukları

- Kullanıcı sayısı, gelir, dönüşüm veya mağaza sıralaması için **hiçbir ölçüm yok**; bu belgelerde sayı
  verilmez.
- Mağaza başvurusu, incelemesi veya yayın durumu doğrulanmamıştır.
- Release imzalı AAB ve Play internal testing kanıtı yoktur.
- iOS derlemesi yoktur.
- Otomatik test/CI kaydı yoktur; bölüm ve ipucu doğrulamaları çalışma zamanı kanıtıdır.

## 7. Karar değiştirme kuralı

1. Yeni karar, eski satırı silmeden yeni ID ile eklenir; eski satır "geçersiz" olarak işaretlenir.
2. Karar koda yansıdıysa ilgili belge ve `docs/README.md` aynı değişiklikte güncellenir.
3. Ölçüm gerektiren kararlar `09`daki metrik tanımlarına bağlanır; ölçümsüz "iyileşti" ifadesi kullanılmaz.
4. Gizlilik, reklam ve mağaza metinleri karar değişikliğinde birlikte gözden geçirilir.
