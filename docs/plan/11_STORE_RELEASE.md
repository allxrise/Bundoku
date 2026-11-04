# 11 — Mağaza ve sürüm yayını

> **Karar:** İlk yayın Google Play'dedir; paket kimliği `com.bundoku.puzzle` değişmez. Yayın, P0 backlog
> kapanmadan ve release imzalı AAB internal testing'de doğrulanmadan üretime alınmaz. Bu belge mağaza
> gereksinimlerini ve sürümleme kurallarını tanımlar; hiçbir mağaza başvurusu yapılmış gibi sunulmaz.

Etiketler: **Mevcut**, **Planlanan**, **Açık**. İlgili: [01_PRODUCT_STRATEGY.md](01_PRODUCT_STRATEGY.md),
[10_PRODUCTION_BACKLOG.md](10_PRODUCTION_BACKLOG.md), [../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md),
[../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md).

## 1. Mevcut kimlik ve yapılandırma

| Öğe | Değer | Kaynak |
|---|---|---|
| Paket adı | `com.bundoku.puzzle` | `export_presets.cfg` |
| Görünen ad | `Bundoku: Tavşan Bulmacası` | `export_presets.cfg` |
| Android sürüm | `1.0.4` (`versionCode 5`) | `export_presets.cfg`, APK badging |
| Proje sürümü | `1.0.0` | `project.godot` |
| min / target SDK | 24 / 36 | `android/build/config.gradle` |
| ABI | `arm64-v8a`, `x86_64` | APK badging |
| İzinler | `INTERNET`, `AD_ID`, `ACCESS_NETWORK_STATE`, `READ_BASIC_PHONE_STATE`, `WAKE_LOCK`, `FOREGROUND_SERVICE` | APK badging |
| Reklam | AdMob + UMP, Meta mediation açık; test kimlikleri | `project.godot`, `assets/ads/ads_config.json` |
| IAP | Yok | `scripts/` |
| Backend | Yok | `Telemetry.upload_url=""` |
| Debug APK | Yaklaşık 185 MB | `build/android/Bundoku-debug.apk` |

**Açık:** `project.godot` içinde `admob/general/android/app_id` tanımlı değil; derlenen APK eklentinin test
App ID'sini taşır. Play'e yüklenecek paket gerçek App ID ve gerçek reklam birimleriyle üretilmelidir.

## 2. Sürümleme politikası

| Kural | Karar |
|---|---|
| `versionCode` | Her yüklenen derlemede artar; asla geri kullanılmaz. Mevcut değer 5. |
| `versionName` | `MAJOR.MINOR.PATCH`; mevcut `1.0.4`. |
| Tek kaynak | Android `version/code` ve `version/name` ile `project.godot` `config/version` aynı olmalı. |
| Sürüm notu | Her sürüm `../release/VERSION_HISTORY.md` içine işlenir. |
| Uyumluluk | Kayıt biçimi değişirse `load_save()` geriye dönük okuma sağlar. |

**Açık:** İki sürüm alanı farklı (`1.0.0` vs `1.0.4`). Yayın öncesi `project.godot` `config/version` tek
kaynağa bağlanmalı; aksi halde telemetri `app_version` ve mağaza sürümü uyuşmaz.

## 3. İmzalama ve Play App Signing

| Adım | Durum | Not |
|---|---|---|
| Debug anahtarı | Mevcut | `~/.android/debug.keystore`; yalnız test |
| Release anahtarı | Mevcut (geçici) | `~/.android/bundoku_release.keystore`; döndürülmeli |
| Parola saklama | **Açık** | `export_presets.cfg` içinde düz metin; gizli yönetime taşınmalı |
| Play App Signing | **Planlanan** | İlk yüklemede Play'e bırakılır; upload key ayrı tutulur |
| Anahtar yedeği | **Açık** | Parola ve keystore yedeği depo dışında saklanmalı |

**Kural:** Yayın anahtarı ve parolası hiçbir belgeye, commit'e veya sürüm notuna yazılmaz. Geçici anahtar
döndürüldükten sonra eski parola geçersiz sayılır; yeni anahtarla internal testing'e yükleme yapılır.

## 4. Çıktı biçimi

- `export_presets.cfg` şu anda `gradle_build/export_format=0` (APK) üretir. Google Play yeni uygulamalarda
  AAB ister; yayın öncesi `gradle_build/export_format=1` yapılmalı ve ABI/paket doğrulanmalıdır.
- Gradle derlemesi açıktır (`gradle_build/use_gradle_build=true`); şablon `android/build` altındadır ve
  `.build_version` `4.7.2.stable` yazar.
- `armeabi-v7a` kapalı, `arm64-v8a` ve `x86_64` açıktır; Play dağıtımında x86_64 emülatör içindir, cihaz
  dağıtımı arm64'tür.
- APK içinde `assets/ads/ads_config.json` dışa aktarma filtresine takılmamalıdır; aksi halde kod içindeki
  yedek test kimlikleri kullanılır.

## 5. Mağaza listesi gereksinimleri

| Öğe | Gereksinim | Durum |
|---|---|---|
| Uygulama adı | En fazla 30 karakter; mevcut ad 25 | **Mevcut** |
| Kısa açıklama | En fazla 80 karakter | **Planlanan** |
| Tam açıklama | En fazla 4000 karakter | **Planlanan** |
| Uygulama simgesi | 512×512 PNG | **Açık** (kaynak 192/432 var) |
| Öne çıkan grafik | 1024×500 PNG/JPEG | **Açık** |
| Telefon ekran görüntüleri | En az 2, en fazla 8; gerçek cihazdan | **Açık** |
| Tanıtım videosu | İsteğe bağlı | **Planlanan** |
| Gizlilik politikası URL'si | Zorunlu | **Açık** |
| Data Safety formu | Reklam SDK'ları dahil | **Açık** |
| İçerik derecelendirmesi | Anket doldurulur | **Açık** |
| Reklam beyanı | "Reklam içerir" | **Planlanan** |
| Hedef kitle | Karar verilmedi; çocuk beyanı ayrı politika gerektirir | **Açık** |

## 6. Listeleme metni taslağı

**Türkçe başlık:** `Bundoku: Tavşan Bulmacası`

**Türkçe kısa açıklama (taslak):**
`120 el yapımı mantık bulmacası: tavşanları yerleştir, ipuçlarını takip et.`

**Türkçe tam açıklama (taslak):**
`Bundoku, sevimli tavşanların dünyasında geçen sakin bir mantık bulmacasıdır. Her satırda, her sütunda ve
her renkli bölgede tam olarak bir tavşan olacak şekilde tahtayı doldur. Tavşanlar birbirine dikey veya
çapraz komşu olamaz.`

`120 el yapımı bölüm, 4×4'ten 9×9'a kadar büyüyen tahtalar ve dört zorluk katmanıyla ilerle. Otomatik X,
taslak modu, geri alma ve ipucu araçlarıyla takıldığın yerde devam et. Oyun çevrimdışı çalışır ve 20 dilde
oynanabilir.`

`Reklam destekli ücretsiz bir oyundur; ödüllü reklamlar karşılığında ek ipucu ve can yenileme kazanabilirsin.`

**English short description (draft):**
`120 handcrafted logic puzzles: place the bunnies, follow the clues.`

**Not:** Mağaza metni olmayan özellikleri (reklamsız sürüm, bulut kayıt, günlük ödül) vaat etmez. IAP
eklenirse metin ve Data Safety aynı sürümde güncellenir.

## 7. Yayın süreci

1. P0 listesini kapat; sürüm ve imza kontrollerini yap.
2. `project.godot` ve `export_presets.cfg` sürümlerini eşitle; `versionCode` artır.
3. Gerçek reklam kimlikleriyle release AAB üret ve imzala.
4. Play Console'da internal testing kanalına yükle; Play'den kurup Pixel 9'da aç.
5. Data Safety, içerik derecelendirmesi, reklam ve hedef kitle formlarını doldur.
6. Kapalı test → açık test → üretim; her aşamada [13_QA_ACCEPTANCE.md](13_QA_ACCEPTANCE.md) çıkış kriterleri.
7. Üretimde aşamalı yayın (ör. %5 → %20 → %50 → %100) **Planlanan**; her aşamada çökme ve reklam hatası izlenir.

**Açık:** Play, yeni kişisel geliştirici hesapları için kapalı test şartı uygular; güncel şart ve test kullanıcı
sayısı Console'da doğrulanmalıdır, bu belge sayı uydurmaz.

## 8. Açık işler

- **Açık:** Gerçek App ID ve reklam birimleri; `app-ads.txt`; Meta mediation doğrulaması.
- **Açık:** Gizlilik politikası URL'si ve Data Safety formu.
- **Açık:** 512×512 simge, 1024×500 grafik, gerçek ekran görüntüleri.
- **Açık:** `READ_BASIC_PHONE_STATE` izninin gerekliliği ve beyanı.
- **Açık:** Sürüm alanlarının tekilleştirilmesi ve keystore parolalarının depodan çıkarılması.
- **Açık:** AAB çıktısı ve release imzasıyla cihaz testi.
- **Planlanan:** Aşamalı yayın, sürüm notu şablonu, mağaza metinlerinin 20 dile çevrilmesi.
