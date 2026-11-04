# Yayın kontrol listesi

> **Kullanım:** Her madde işaretlenmeden mağazaya yükleme yapılmaz. `[x]` yalnızca bu depoda veya cihazda
> doğrulanmış işleri gösterir; `[ ]` açık iştir. Parola, keystore değeri veya gerçek reklam kimliği bu
> belgeye yazılmaz. İlgili: [../plan/11_STORE_RELEASE.md](../plan/11_STORE_RELEASE.md),
> [../plan/13_QA_ACCEPTANCE.md](../plan/13_QA_ACCEPTANCE.md),
> [../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md).

## 1. Kimlik ve sürüm

- [ ] Paket adı `com.bundoku.puzzle` olarak kilitli; mağaza kaydıyla aynı.
- [ ] `project.godot` `config/version` ile `export_presets.cfg` `version/name` aynı (şu an `1.0.0` vs `1.0.4`).
- [ ] `versionCode` bir önceki yüklemeden büyük (mevcut 5).
- [ ] `application/config/name` mağaza adıyla aynı: `Bundoku: Tavşan Bulmacası`.
- [ ] Sürüm notu [VERSION_HISTORY.md](VERSION_HISTORY.md) içine yazıldı.

## 2. Gizli bilgiler ve imza

- [ ] `export_presets.cfg` içinde düz metin keystore parolası yok.
- [ ] Keystore ve parola depo dışında, erişimi sınırlı bir kasada.
- [ ] Geçici release anahtarı döndürüldü; eski parola geçersiz.
- [ ] Play App Signing upload key'i ayrı tutuluyor.
- [ ] Release derlemesi yeni anahtarla imzalandı ve imza doğrulandı.
- [ ] CI/yerel derleme parolayı ortam değişkeninden okuyor; komut geçmişinde parola yok.

## 3. Reklam ve mediation

- [ ] Gerçek AdMob App ID `project.godot` `[admob]` bölümüne eklendi.
- [ ] `aapt2 dump xmltree --file AndroidManifest.xml` gerçek `com.google.android.gms.ads.APPLICATION_ID` gösteriyor.
- [ ] `assets/ads/ads_config.json` gerçek interstitial, rewarded ve banner birimlerini taşıyor.
- [ ] `test_mode` `false`; APK içinde `ca-app-pub-3940256099942544` geçmiyor.
- [ ] `enable_banner` ve `preload` yayın kararıyla uyumlu.
- [ ] `app-ads.txt` geliştirici alan adı kökünde yayında ve doğru satıcı satırlarını içeriyor.
- [ ] AdMob mediation grubunda Meta Audience Network yapılandırıldı; test gösteriminde `ad_source` görüldü.
- [ ] ILARE (impression-level ad revenue) AdMob hesabında açık; `ad_impression.value` sıfırdan farklı.
- [ ] Rewarded ödüllerin istemci tarafında verildiği biliniyor; SSV kararı belgelendi.
- [ ] Reklamlar oyun sırasında değil, yalnız bölüm sonunda ve ödüllü akışlarda gösteriliyor.

## 4. Gizlilik, rıza ve veri güvenliği

- [ ] Gizlilik politikası URL'si yayında ve mağaza listesine eklendi.
- [ ] Politika [../privacy/PRIVACY_POLICY_DRAFT.md](../privacy/PRIVACY_POLICY_DRAFT.md) ile aynı veri türlerini anlatıyor.
- [ ] Gizlilik politikasına oyun içinden erişim var (dil modalı veya ayarlar).
- [ ] EEA/UK/CH için analitik rıza kartı var; ret yerel telemetri dosyalarını siliyor.
- [ ] UMP privacy options gerekli olduğunda görünür ve çalışıyor.
- [ ] Data Safety formu reklam SDK'larının topladığı verileri kapsıyor.
- [ ] `READ_BASIC_PHONE_STATE` izni kaldırıldı veya gerekçesi ve beyanı tamam.
- [ ] Veri silme yolu (uygulama verisini temizleme ve destek adresi) belgeli.
- [ ] Telemetri `upload_url` boş; sunucu eklenirse politika ve form güncellenecek.

## 5. Mağaza listesi ve formlar

- [ ] 512×512 uygulama simgesi hazır.
- [ ] 1024×500 öne çıkan grafik hazır.
- [ ] En az 2, en fazla 8 gerçek telefon ekran görüntüsü hazır.
- [ ] Kısa açıklama 80, tam açıklama 4000 karakter sınırında.
- [ ] Türkçe ve İngilizce metinler yayında; diğer diller **Planlanan**.
- [ ] İçerik derecelendirmesi anketi doldurulmuş (reklam var, IAP yok, kullanıcı içeriği yok).
- [ ] Hedef kitle ve çocuk beyanı kararı verilmiş.
- [ ] "Reklam içerir" beyanı işaretli.
- [ ] Destek e-postası ve web sitesi alanları dolu.
- [ ] Mağaza metni olmayan özellikleri (reklamsız, bulut kayıt) vaat etmiyor.

## 6. Derleme ve teknik doğrulama

- [ ] `gradle_build/export_format=1` ile AAB üretimi.
- [ ] AAB release anahtarıyla imzalı; boyut ve ABI'ler kontrol edilmiş.
- [ ] `assets/ads/ads_config.json` paket içinde; yedek test kimliklerine düşülmüyor.
- [ ] `android/build/config.gradle`: minSdk 24, targetSdk 36, compileSdk 36, NDK 29.0.14206865.
- [ ] `arm64-v8a` cihazda kurulum ve açılış doğrulandı.
- [ ] Uygulama dikey kilitli; derlenmiş manifest `screenOrientation=1`.
- [ ] Kayıt dosyası `user://bundoku_save.cfg` yeni sürümde okunuyor.
- [ ] Yükseltme testi: önceki sürümün kaydı yeni sürümde korunuyor.
- [ ] Play internal testing kanalından kurulum doğrulaması.

## 7. Oynanış ve içerik

- [x] 120 bölümün tamamı gerçek girdiyle çözülebiliyor.
- [x] İpucu motoru 120/120 bölümü hatasız çözüyor.
- [x] Taslak ve geri alma semantiği doğrulandı.
- [ ] Oto-X ve can akışı release yapıda ayrıca doğrulandı.
- [x] Yıldız, kupa ve bonus formülleri kodla doğrulandı.
- [ ] Release yapıda bölüm 1–10 duman testi geçildi.
- [ ] Release yapıda can bitişi, yenile ve yeniden başlat akışı geçildi.
- [ ] Düşük bellek / arka plandan dönüş senaryosu geçildi.
- [ ] Uçak modunda oyun ve reklam fallback'i geçildi.
- [ ] RTL (Arapça/Urduca) yerleşimi kabul edildi veya ertelendi kararı yazıldı.

## 8. Analitik ve operasyon

- [x] Cihazda telemetri satırları oluşuyor (Pixel 9 / Android 17).
- [x] Banner yüksekliği 84 px olarak rezerve edildi.
- [x] `banner ad_impression` kaydı alındı.
- [ ] `denied` rıza durumunda satır yazılmadığı doğrulandı.
- [ ] `held` durumunda 256 satır sınırı ve çıkışta kayıp davranışı kabul edildi.
- [ ] `ad_shown(simulated=1)` satırları gelir raporundan dışlanıyor.
- [ ] Çökme/ANR için Play Console uyarıları izleniyor.
- [ ] Destek/yorum triyaj sorumlusu belirlendi.

## 9. Yayın ve geri dönüş

- [ ] Tüm P0 backlog maddeleri kapalı ([../plan/10_PRODUCTION_BACKLOG.md](../plan/10_PRODUCTION_BACKLOG.md)).
- [ ] Aşamalı yayın planı hazır (ör. %5 → %20 → %50 → %100).
- [ ] Geri dönüş planı: yayını durdur, önceki sürümü koru, hatalı sürümü yayından çek.
- [ ] İlk gün izlenecek metrikler ve eşikler yazılı.
- [ ] Gizlilik, reklam ve mağaza belgeleri aynı sürümü ve aynı veri türlerini anlatıyor.

## 10. Onay

| Alan | Onay | Tarih |
|---|---|---|
| Ürün | Bekliyor | — |
| Teknik | Bekliyor | — |
| Gizlilik / hukuk | Bekliyor | — |
| Mağaza | Bekliyor | — |
