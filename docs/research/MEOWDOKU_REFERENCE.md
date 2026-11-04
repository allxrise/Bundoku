# Meowdoku referansı

Bundoku'nun oynanış ve ürün modeli, **Meowdoku: Brain Puzzle Games** (`com.oakever.meowdoku`) oyunundan incelenerek tasarlanmıştır. Bu belge, neyin referans alındığını, neyin bilinçli olarak farklı yapıldığını ve hangi köken risklerinin açık kaldığını kaydeder. Ham teknik kanıt: [../../REA/README.md](../../REA/README.md).

Referans sürümü: `1.23.0` (`versionCode 1669`), XAPK/split APK. Aşağıdaki tüm referans bilgileri REA statik analiz raporundan alınmıştır; yeniden çalıştırılmamıştır.

## 1. Referans kimliği

| Özellik | Meowdoku (referans) | Kaynak |
|---|---|---|
| Paket | `com.oakever.meowdoku` | REA raporu |
| Geliştirici altyapısı | Oakever Games / Learnings (Lexin) | REA raporu |
| Motor | Godot 4.6.1, `gl_compatibility` | REA raporu |
| SDK | minSdk 24, targetSdk 36 | `REA/manifest.json` |
| Boyut | ~349,5 MB, 21 split APK | REA raporu |
| İmza | APK Signature Scheme v2 + v3, Play Source Stamp | REA raporu |
| Bölüm bankası | 4×4'ten 12×12'ye `.bin` bankaları (`MDBK`) | REA raporu |
| Kayıt | Çift slotlu, şifreli `ConfigFile` | REA raporu |
| Backend | `meowdoku-api.dailyinnovation.biz`, öneri API'si | REA raporu |
| IAP | Reklamsız abonelikler (`noad_1week`, `noad_1month`, `noad_1year`) | REA raporu |
| Reklam | AppLovin MAX, AdMob, Pangle, Mintegral, Unity Ads ve daha fazlası | REA raporu |
| Autoload | 28 servis (GameState, RobotService, StreakManager, PurchaseManager vb.) | REA raporu |
| Dil | 17 Android dil paketi, 76 `.translation` dosyası | REA raporu |

## 2. Bundoku'nun aldığı fikirler

| Fikir | Meowdoku'daki karşılığı | Bundoku'daki uygulama | Durum |
|---|---|---|---|
| Yıldız Savaşı / Queens kuralı | Aynı tür bulmaca | `scripts/gameplay/board_view.gd`, `hint_solver.gd` | Mevcut |
| Kademeli ipucu hattı | `HintPipeline` | 9 adımlı `HintSolver.compute_hint` | Mevcut |
| Tek dokunuş X, çift dokunuş tavşan | Dokunma modeli | `_handle_single_tap_or_start_drag`, `_handle_double_tap` | Mevcut |
| Taslak/deneme modu | Güvenli deneme | `draft_mode`, `apply_draft`, `cancel_draft` | Mevcut |
| Otomatik X | Komşuluk temizliği | `_apply_auto_cross_for_bunny`, ayarlanabilir | Mevcut |
| Can ve hata cezası | 3 can | `_lives`, `mistake_made` | Mevcut |
| Yıldız değerlendirmesi | Süre/hata | `complete_level` (hata ve süre eşikleri) | Mevcut |
| Günlük bölüm düğmesi | Günlük içerik | Tarihe bağlı indeks, açık bölümle sınırlı | Mevcut |
| Lig/rakip simülasyonu | `RobotService`, `rank_activity` | `league_rivals`, `get_leaderboard` | Mevcut (simülasyon) |
| Banner + interstitial + rewarded | Çoklu ağ | AdMob + UMP, Meta mediation | Mevcut |
| Bölge renkleri + desen modu | Renk körlüğü desteği | 14 pastel renk, 12 desen ikonu | Mevcut |
| Alt bant reklam rezervasyonu | Banner yerleşimi | `banner_loaded(height_px)` ile alt boşluk | Mevcut |

Ortaklık bilinçli olarak **mekanik ve ürün akışı** düzeyindedir; sunucu, hesap ve abonelik altyapısı alınmamıştır.

## 3. Bilinçli farklar

| Konu | Meowdoku | Bundoku | Neden |
|---|---|---|---|
| İçerik hacmi | 4×4–12×12 bankalar, çok sayıda seviye | 120 bölüm, 4×4–9×9 | Küçük, doğrulanabilir lansman seti |
| Bölüm biçimi | Sıkıştırılmış `MDBK` ikili bankaları | Okunabilir JSON (`levels_database.json`) | Denetlenebilirlik ve basit üretim |
| Backend | Bulut kayıt, öneri API'si, hesap | Yok; tamamen çevrimdışı | Operasyon ve gizlilik yükünü azaltmak |
| Kayıt | Şifreli, çift slotlu | Düz `ConfigFile` | Basitlik; şifreleme açık risk |
| IAP | Reklamsız abonelikler | Yok; yalnızca `no_ads_purchased` bayrağı | Henüz uygulanmadı |
| Reklam ağı | Çoklu aracılı ağ | AdMob + UMP + Meta mediation | Tek SDK ile başlangıç |
| Rakip sistemi | Dosya tabanlı bot simülasyonu | Bellekte 7 rakip, rastgele kupa artışı | Kapsamı dar tutmak |
| Dil | 17 Android dil paketi | 20 dil, tek `loc.gd` sözlüğü | Metin tabanlı hızlı yerelleştirme |
| Günlük seri | Streak yönetimi ve kurtarma | `streak_days` alanı var, UI akışı yok | Sonraki sürüm |
| Platform | Android (referans paket) | Android; iOS preset'i yok | Odak |

## 4. Alınmayan veya doğrulanamayan şeyler

- Meowdoku'nun sunucu uç noktaları, hesap sistemi, IAP ürün kimlikleri ve SDK anahtarları kullanılmaz.
- Referans oyunun seviye bankaları kopyalanmaz; Bundoku bölümleri ayrı JSON verisidir ve kendi çözüm/bölge doğrulamasına sahiptir.
- Meowdoku'nun A/B test, uzaktan yapılandırma, çökme raporlama ve destek masası altyapısı yoktur.
- Referans oyunun kod davranışı yalnızca statik analizle görülmüştür; çalışırken karşılaştırmalı test yapılmamıştır.
- "Meowdoku daha iyi/kötü" iddiası kurulmaz; karşılaştırma yalnızca kapsam ve mimari düzeyindedir.

## 5. Köken ve lisans riski (Açık)

Kod yorumları ve varlık adları, bazı görsel/işitsel dosyaların referans oyundan alındığını gösterir:

- `scripts/gameplay/board_view.gd:5`: "Uses original extracted Meowdoku UI/board textures ... combined with Bundoku bunny sprites."
- `scripts/gameplay/board_view.gd:218`: "Original Meowdoku pattern icons".
- `scripts/core/sound_manager.gd:3`: "Original Meowdoku Audio + Procedural Fallback".
- `assets/ui/` altında 73 PNG ve `.import` dosyaları dahil 146 giriş; `assets/audio/` altında 8 WAV.

Bu durum yayın öncesi **P0 hukuk riskidir**. Seçenekler:

| Seçenek | Sonuç | Durum |
|---|---|---|
| Varlıkları özgün sanatla değiştir | En güvenli yol | Planlanan |
| Lisans/izin belgesi edin | Belge yoksa risk sürer | Açık |
| Yalnızca ölçü/renk benzerliği olduğunu doğrula | Dosya bazlı inceleme gerekir | Açık |

Kaynak kodun GDScript yapısı Bundoku'ya özgüdür; ancak görsel varlıkların dosya düzeyinde referans paketten geldiği beyanı, mağaza şikâyeti halinde savunmayı zorlaştırır. Bu belge hukuki görüş değildir.

## 6. Ürün dersleri

| Gözlem | Bundoku kararı | İlgili belge |
|---|---|---|
| Referans oyun backend ve hesap olmadan da oynanabilir çekirdeğe sahip | Çevrimdışı öncelikli başlangıç | [../plan/08_TECHNICAL_ARCHITECTURE.md](../plan/08_TECHNICAL_ARCHITECTURE.md) |
| Çoklu reklam ağı operasyon yükü getiriyor | Tek AdMob + UMP, gerekirse mediation | [../plan/05_ECONOMY_MONETIZATION.md](../plan/05_ECONOMY_MONETIZATION.md) |
| Bot rakipler lig hissi veriyor ama şeffaflık gerektiriyor | Lig simülasyon olarak kalacak; gerçek çok oyunculu yok | [../plan/04_CONTENT_AND_PROGRESSION.md](../plan/04_CONTENT_AND_PROGRESSION.md) |
| Şifreli kayıt ve bulut senkronu karmaşıklık ekliyor | Yerel kayıt; ileride imzalı/şifreli saklama değerlendirilecek | [PROJECT_HEALTH](../AI/PROJECT_HEALTH.md) |
| İçerik doğrulaması olmadan banka büyütmek riskli | Her bölüm çözüm + bölge + komşuluk doğrulamasından geçmeli | [../plan/04_CONTENT_AND_PROGRESSION.md](../plan/04_CONTENT_AND_PROGRESSION.md) |

## 7. Açık sorular

| # | Soru | Takip |
|---|---|---|
| 1 | Varlıkların hangi kısmı gerçekten referans paketten geldi? | Dosya bazlı köken envanteri |
| 2 | Referans oyunun ürün akışlarından hangileri patent/ticari sır kapsamında? | Hukuk kontrolü |
| 3 | Bundoku'nun farklılaşması tema ile sınırlı mı? | [../plan/01_PRODUCT_STRATEGY.md](../plan/01_PRODUCT_STRATEGY.md) |
| 4 | 120 bölüm lansman için yeterli mi, üretim hattı nasıl ölçeklenir? | [../plan/04_CONTENT_AND_PROGRESSION.md](../plan/04_CONTENT_AND_PROGRESSION.md) |
