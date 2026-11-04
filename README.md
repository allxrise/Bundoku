# Bundoku: Tavşan Bulmacası

Bundoku, 4×4–9×9 ızgaralarda oynanan, sevimli tavşan ve fırın temalı bir **Yıldız Savaşı / Queens** mantık bulmacasıdır. Oyuncu her satır, sütun ve renkli bölgeye tam olarak bir tavşan yerleştirir; tavşanlar birbirine dikey, yatay veya çapraz komşu olamaz.

- Paket: `com.bundoku.puzzle`
- Android sürümü: `1.0.4` (`versionCode 5`) — `export_presets.cfg`
- Proje içi sürüm: `1.0.0` — `project.godot` (**bilinen uyumsuzluk**)
- Motor: `project.godot` Godot 4.7 özellikleri bildirir; derleme **Godot 4.7.2 stable** ile yapılmış
- Renderer: GL Compatibility, 540×960 dikey, `canvas_items` / `expand`
- 120 el yapımı bölüm, 20 dil (`scripts/core/loc.gd`)

Bu depo oynanabilir bir Android ön sürümüdür. Mağaza yayını, IAP ve sunucu tarafı analitik henüz yoktur; ayrıntılar için [dokümantasyon indeksine](docs/README.md) bakın.

## Hızlı bağlantılar

| Konu | Belge |
|---|---|
| Dokümantasyon indeksi | [docs/README.md](docs/README.md) |
| Ürün planı indeksi | [docs/plan/README.md](docs/plan/README.md) |
| Ürün stratejisi | [docs/plan/01_PRODUCT_STRATEGY.md](docs/plan/01_PRODUCT_STRATEGY.md) |
| Oynanış kuralları | [docs/plan/02_CORE_GAMEPLAY.md](docs/plan/02_CORE_GAMEPLAY.md) |
| İçerik ve ilerleme | [docs/plan/04_CONTENT_AND_PROGRESSION.md](docs/plan/04_CONTENT_AND_PROGRESSION.md) |
| Ekonomi ve reklam | [docs/plan/05_ECONOMY_MONETIZATION.md](docs/plan/05_ECONOMY_MONETIZATION.md) |
| Arayüz ve yerelleştirme | [docs/plan/06_UI_UX_LOCALIZATION.md](docs/plan/06_UI_UX_LOCALIZATION.md) |
| Teknik mimari | [docs/plan/08_TECHNICAL_ARCHITECTURE.md](docs/plan/08_TECHNICAL_ARCHITECTURE.md) |
| Analitik olayları | [docs/analytics/EVENTS.md](docs/analytics/EVENTS.md) |
| Reklam entegrasyonu | [docs/ads/INTEGRATION.md](docs/ads/INTEGRATION.md) |
| Gizlilik politikası taslağı | [docs/privacy/PRIVACY_POLICY_DRAFT.md](docs/privacy/PRIVACY_POLICY_DRAFT.md) |
| Yayın kontrol listesi | [docs/release/SHIP_CHECKLIST.md](docs/release/SHIP_CHECKLIST.md) |
| Proje bağlamı | [docs/AI/PROJECT_CONTEXT.md](docs/AI/PROJECT_CONTEXT.md) |
| Proje sağlığı | [docs/AI/PROJECT_HEALTH.md](docs/AI/PROJECT_HEALTH.md) |
| Referans oyun analizi | [docs/research/MEOWDOKU_REFERENCE.md](docs/research/MEOWDOKU_REFERENCE.md), [REA/README.md](REA/README.md) |

## Gereksinimler

| Araç | Sürüm / not |
|---|---|
| Godot | 4.7.2 stable (proje `config/features` 4.7 bildirir; editörde 4.7.x açın) |
| JDK | 21 (yerel Android derlemesi); Gradle şablonu `android/build/config.gradle` içinde `JavaVersion.VERSION_17` tanımlıdır |
| Android SDK | build-tools `36.1.0`, compileSdk/targetSdk 36, minSdk 24 |
| NDK | `29.0.14206865` |
| Gradle | Şablonla gelen wrapper (`android/build/gradlew`) |
| Python | 3.x, standart kütüphane (yalnızca `tools/bq_load.py` için, opsiyonel) |

Godot Android build template kurulu olmalıdır (Editör → Project → Install Android Build Template). Depoda `android/build/` bu şablondan üretilmiş çıktıyı içerir.

## Çalıştırma

```bash
# Editörsüz çalıştırma (Linux)
godot --path .

# Ana sahne doğrudan
godot --path . res://scenes/main.tscn
```

Editörde `project.godot` açıp F5 ile de çalıştırılabilir. Masaüstünde gerçek AdMob SDK bulunmadığı için reklam akışları 3 saniyelik simüle modal ile çalışır (`scripts/ads/ad_manager.gd`).

## Derleme

```bash
mkdir -p build/linux build/android

# Linux (debug)
godot --headless --export-debug "Linux" build/linux/Bundoku.x86_64

# Android (debug, Gradle build)
godot --headless --export-debug "Android" build/android/Bundoku-debug.apk
```

Android çıktısı `build/android/Bundoku-debug.apk` altındadır (yaklaşık 185 MB).

```bash
# Bağlı cihaza kurma ve başlatma
adb install -r build/android/Bundoku-debug.apk
adb shell monkey -p com.bundoku.puzzle -c android.intent.category.LAUNCHER 1
```

İmza ayarları `export_presets.cfg` içindedir; yayın anahtarı geçicidir ve parola alanları düz metindir (bkz. [PROJECT_HEALTH](docs/AI/PROJECT_HEALTH.md)).

## Proje yapısı

| Yol | İçerik |
|---|---|
| `scenes/main.tscn` | Tek sahne; kök düğüm `main_controller.gd` çalıştırır |
| `scripts/core/` | `loc.gd`, `game_state.gd`, `sound_manager.gd`, `telemetry.gd` autoload'ları |
| `scripts/gameplay/` | `board_view.gd` (çizim + giriş), `hint_solver.gd` (ipucu hattı) |
| `scripts/ui/main_controller.gd` | Tüm ekranların prosedürel UI kurulumu |
| `scripts/ads/ad_manager.gd` | AdMob/UMP sarmalayıcı, banner ve ödüllü akışlar |
| `assets/levels/levels_database.json` | 120 bölüm; çözüm ve bölge haritaları |
| `assets/ui/`, `assets/chatgpt_ui/` | 9-slice ve ikon varlıkları (köken riski için araştırma notuna bakın) |
| `android/build/` | Android Gradle şablonu ve derleme çıktıları |
| `docs/` | Ürün, teknik, analitik, yayın ve gizlilik belgeleri |
| `tools/bq_load.py` | JSONL telemetriyi BigQuery'ye yükleme betiği |
| `REA/` | Referans oyun Meowdoku'nun statik analiz raporu |

## Doğrulama durumu

- 120/120 bölüm gerçek girişle çözüldü; ipucu hattı 120/120 çözümü sıfır hatayla tamamladı.
- Geri al, taslak modu ve otomatik X davranışı test edildi.
- Pixel 9 / Android 17 üzerinde debug APK kuruldu, açıldı; telemetri satırları, `banner_loaded` (84 px) ve `ad_impression` gözlendi.
- Otomatik test paketi ve CI yoktur. Ayrıntılı kabul durumu: [docs/plan/13_QA_ACCEPTANCE.md](docs/plan/13_QA_ACCEPTANCE.md).

## Katkı ve belge kuralları

- Belgeler Türkçedir; "Mevcut", "Planlanan" ve "Açık" etiketleri korunur.
- Ölçülmemiş kullanıcı, gelir veya tarih rakamı yazılmaz.
- Her davranış iddiası ilgili dosya yoluna referans verir.
- Yeni bir özellik eklenirse önce [docs/README.md](docs/README.md) indeksindeki ilgili belge güncellenir.
