# Proje sağlığı — Bundoku

Bu belge, depodaki kod ve doğrulanmış ölçümlere dayanan durum özetidir. Hiçbir test bu belge yazılırken yeniden çalıştırılmamıştır; "kanıt" sütunu mevcut doğrulama kayıtlarını ve dosya yollarını gösterir. Genel bağlam: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md). Yayın maddeleri: [../release/SHIP_CHECKLIST.md](../release/SHIP_CHECKLIST.md).

## Durum özeti

| Alan | Durum | Özet |
|---|---|---|
| Derleme ve çalıştırma | Sağlıklı | Debug APK üretildi, Pixel 9 / Android 17'de kurulup açıldı |
| Bölüm içeriği | Sağlıklı | 120/120 bölüm gerçek girişle çözüldü; 0 doğrulama hatası |
| Oynanış çekirdeği | Sağlıklı | Kurallar, can, taslak, geri al ve otomatik X test edildi |
| İpucu motoru | Sağlıklı | 120/120 çözüm, sıfır hata |
| Kayıt sistemi | İzlemede | Çalışıyor; düz `ConfigFile`, şifresiz |
| Yerelleştirme | İzlemede | 20 dil metni var; RTL aynalama ve İngilizce çoğul eksiği açık |
| Reklam | İzlemede | Gerçek SDK akışı var; kimlikler test, SSV yok, app-ads.txt yok |
| Analitik | İzlemede | Yerel JSONL çalışıyor; sunucu yok, EEA rıza kartı yok |
| Monetizasyon | Riskli | IAP ve reklamsız satın alma yok; bayrak bağlı ama kullanılmıyor |
| Mağaza ve gizlilik | Bloke | Gizlilik URL'si, veri güvenliği formu ve kalıcı anahtar yok |
| Varlık kökeni | Riskli | Görsel/işitsel varlıklar için Meowdoku'dan alınmış beyanı var; lisans netleşmeli |
| Otomasyon | İzlemede | Otomatik test ve CI yok; doğrulama elle |

Durum tanımları: **Sağlıklı** = kabul kanıtı var; **İzlemede** = çalışıyor ancak bilinen açık var; **Riskli** = yayın öncesi zorunlu iş; **Bloke** = yayın bu haliyle yapılamaz.

## Doğrulanmış kanıt

| Kanıt | Sonuç | Dayanak |
|---|---|---|
| Bölüm çözülebilirliği | 120/120 gerçek dokunma girişiyle çözüldü | Bölüm doğrulama çalışması; `assets/levels/levels_database.json` |
| İpucu hattı | 120/120 çözüm, 0 hatalı öneri | `scripts/gameplay/hint_solver.gd` |
| Bölge/çözüm bütünlüğü | Her bölümde N satır, N sütun, N bölge, N tavşan; komşuluk ihlali yok | JSON üzerinde yapılan doğrulama |
| Geri al | 60 anlık görüntü sınırı; otomatik X sahipliği geri yükleniyor | `board_view.gd:_push_undo`, `_remove_bunny_at` |
| Taslak modu | Çakışan taslak can/starları etkilemiyor; iptal öncesi duruma dönüyor | `board_view.gd:_place_bunny_at`, `cancel_draft` |
| Cihaz testi | Debug APK kuruldu ve açıldı | Pixel 9, Android 17 |
| Telemetri | Cihazda olay satırları yazıldı | `user://telemetry/events-*.jsonl` |
| Banner | `banner_loaded` yüksekliği 84 px; `banner ad_impression` alındı | `scripts/ads/ad_manager.gd`, cihaz kaydı |
| APK boyutu | `build/android/Bundoku-debug.apk` ≈ 185 MB (193.504.835 bayt) | Derleme çıktısı |

## Açık maddeler

| Öncelik | Madde | Etki | Kanıt / dosya |
|---|---|---|---|
| P0 | `assets/ui/` ve `assets/audio/` varlıklarının Meowdoku'dan alındığı beyanı | Telif/lisans riski; mağaza reddi veya kaldırma | `scripts/gameplay/board_view.gd:5`, `scripts/core/sound_manager.gd:3` |
| P0 | Kalıcı yayın anahtarı yok | Geçici anahtarla yayınlanan sürüm güncellenemez | `export_presets.cfg` |
| P0 | Keystore parolaları düz metin | Depoya erişen herkes imza anahtarını ele geçirebilir | `export_presets.cfg` |
| P0 | Gizlilik politikası URL'si ve Play veri güvenliği yok | Mağaza yayını engellenir | [../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md) |
| P1 | Reklam kimlikleri Google test kimlikleri | Yayında gelir üretmez | `assets/ads/ads_config.json`, `project.godot` |
| P1 | Ödüllü reklamda SSV yok | Ödül istemci tarafında; suiistimal edilebilir | `main_controller.gd:_on_ads_ad_rewarded` |
| P1 | EEA/UK/CH analitik rıza kartı yok | Satırlar bellekte tutuluyor, kullanıcıya sorulmuyor | `telemetry.gd:_decide_initial_consent` |
| P1 | IAP ve "reklamsız" satın alma yok | `no_ads_purchased` her zaman `false` | `game_state.gd`, `ad_manager.gd` |
| P1 | app-ads.txt ve reklam ağı doğrulaması yok | Meta/AdMob gelir ve doğrulama etkilenir | `docs/ads/INTEGRATION.md` |
| P2 | Sürüm uyumsuzluğu: 1.0.0 / 1.0.4 | Hata raporu ve mağaza karışıklığı | `project.godot`, `export_presets.cfg` |
| P2 | İngilizce `"1 Days"` çoğul hatası | Küçük yerelleştirme kusuru | `scripts/core/loc.gd` |
| P2 | Arapça/Urduca RTL aynalanmıyor | Okunabilirlik ve düzen sorunu | `main_controller.gd` |
| P2 | Kayıt dosyası şifresiz | Cihaz erişimiyle ilerleme değiştirilebilir | `game_state.gd:SAVE_PATH` |
| P2 | iOS export preset'i yok | Platform kapsamı Android ile sınırlı | `export_presets.cfg` |
| P2 | Otomatik test/CI yok | Regresyon riski | Depo geneli |

## Risk kaydı

| Risk | Olasılık | Etki | Azaltım |
|---|---|---|---|
| Varlık kökeni nedeniyle mağaza reddi | Orta | Yüksek | `assets/ui/` ve `assets/audio/` varlıklarını özgün sanat/sesle değiştir veya lisansı belgele |
| Test reklam kimliğiyle yayına çıkma | Yüksek | Yüksek | Yayın öncesi `ads_config.json` ve `project.godot` kimliklerini değiştir |
| Geçici anahtarla yayın | Yüksek | Yüksek | Play App Signing ile kalıcı anahtar oluştur, parolaları secret manager'a taşı |
| EEA'da rızasız analitik | Orta | Yüksek | UMP/özel rıza kartı; `held` durumunu kullanıcıya sor |
| Reklam yüküyle oturum bozulması | Orta | Orta | Aralıkları ölç; oyun içi zorunlu reklam yok politikasını koru |
| Sunucu olmaması nedeniyle sahte başarı hissi | Düşük | Orta | Lig/rakip sistemini açıkça simülasyon olarak etiketle |
| 120 bölümün tükenmesi | Orta | Orta | İçerik üretim hattı ve doğrulama kuralı ([04](../plan/04_CONTENT_AND_PROGRESSION.md)) |

## Yayın kapıları

Aşağıdaki üç kapı açılmadan mağaza gönderimi yapılmamalıdır:

1. **Hukuk:** varlık lisansı + gizlilik politikası URL'si + veri güvenliği formu.
2. **Gelir:** gerçek reklam kimlikleri + app-ads.txt + (karar verilirse) IAP.
3. **Teknik:** kalıcı imza anahtarı, sürüm tek kaynağı, son regresyon turu.

## Ölçüm boşlukları

- D1/D7 tutma, bölüm tamamlama hunisi ve reklam eCPM'si **ölçülmemiştir**; altyapı hazır ama yükleme yok.
- Cihaz üstü performans örnekleri 60 saniyede bir toplanıyor; mağaza öncesi sistematik cihaz matrisi yok.
- Otomatik bölüm doğrulayıcı betik depoda yok; doğrulama manuel/tek seferlik yapıldı.

## Bakım tetikleyicileri

| Olay | Güncelle |
|---|---|
| Reklam kimliği değişti | Bu belge, `../ads/INTEGRATION.md`, `../release/SHIP_CHECKLIST.md` |
| IAP eklendi | Bu belge, `../plan/05`, `../store/DATA_SAFETY_AND_LISTING.md` |
| Yeni sürüm | Bu belge, `../release/VERSION_HISTORY.md` |
| Varlık değişti | Bu belge, `../research/MEOWDOKU_REFERENCE.md` |
| Rıza akışı değişti | Bu belge, `../analytics/PRIVACY_AND_CONSENT.md`, `../privacy/PRIVACY_POLICY_DRAFT.md` |
