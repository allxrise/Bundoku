# Bundoku dokümantasyonu

Bu dizin Bundoku'nun ürün, teknik, analitik, yayın ve gizlilik kararlarının tek giriş noktasıdır. Belgeler Türkçe yazılır; her iddia ilgili kaynak dosyasına veya ölçüme bağlanır.

Uygulama sürümü: Android `1.0.4` (`versionCode 5`, `export_presets.cfg`), proje içi `1.0.0` (`project.godot`; bilinen uyumsuzluk). Motor derlemesi Godot 4.7.2 stable, renderer GL Compatibility.

## Durum etiketleri

| Etiket | Anlam |
|---|---|
| **Mevcut** | Kodda uygulanmış ve bu depoda doğrulanabilir. |
| **Planlanan** | Karar verilmiş veya yol haritasında olan, henüz kodda olmayan iş. |
| **Açık** | Bilinen eksik, risk veya çözülmemiş karar. |

Hiçbir belge "Planlanan" işi "Mevcut" gibi sunmaz. Sayısal hedefler, kullanıcı/gelir tahminleri ve mağaza durumu uydurulmaz.

## Belge haritası

### Planlama

| Belge | Ne yanıtlar | Durum |
|---|---|---|
| [plan/README.md](plan/README.md) | Plan belgelerinin okuma sırası ve karar listesi | Mevcut |
| [01_PRODUCT_STRATEGY.md](plan/01_PRODUCT_STRATEGY.md) | Hedef kitle, farklılaşma, başarı ölçütleri, kapsam sınırları | Mevcut |
| [02_CORE_GAMEPLAY.md](plan/02_CORE_GAMEPLAY.md) | Kesin kurallar, etkileşim modeli, ipucu hattı, can/yıldız | Mevcut |
| [04_CONTENT_AND_PROGRESSION.md](plan/04_CONTENT_AND_PROGRESSION.md) | Bölüm şeması, dağılım, kilit açma, günlük bölüm | Mevcut |
| [05_ECONOMY_MONETIZATION.md](plan/05_ECONOMY_MONETIZATION.md) | İpucu/havuç ekonomisi, reklam aralıkları, planlanan IAP | Mevcut + Planlanan |
| [06_UI_UX_LOCALIZATION.md](plan/06_UI_UX_LOCALIZATION.md) | Ekran envanteri, güvenli alan, görsel tokenlar, 20 dil | Mevcut + Açık |
| [08_TECHNICAL_ARCHITECTURE.md](plan/08_TECHNICAL_ARCHITECTURE.md) | Autoload'lar, veri akışı, kayıt, derleme | Mevcut |
| [09_ANALYTICS_EXPERIMENTS.md](plan/09_ANALYTICS_EXPERIMENTS.md) | Olay stratejisi, huni, deney planı | Mevcut + Planlanan |
| [10_PRODUCTION_BACKLOG.md](plan/10_PRODUCTION_BACKLOG.md) | Önceliklendirilmiş iş listesi | Planlanan |
| [11_STORE_RELEASE.md](plan/11_STORE_RELEASE.md) | Play mağaza gereksinimleri, sürümleme | Planlanan + Açık |
| [12_LAUNCH_LIVEOPS.md](plan/12_LAUNCH_LIVEOPS.md) | Yayın sonrası içerik ve iletişim | Planlanan |
| [13_QA_ACCEPTANCE.md](plan/13_QA_ACCEPTANCE.md) | Kabul senaryoları ve kanıt durumu | Mevcut + Açık |
| [14_SOURCES_DECISIONS.md](plan/14_SOURCES_DECISIONS.md) | Kaynaklar, kararlar ve gerekçeleri | Mevcut |

### Yayın ve mağaza

| Belge | Ne yanıtlar |
|---|---|
| [release/SHIP_CHECKLIST.md](release/SHIP_CHECKLIST.md) | Yayın öncesi maddeler, imza, sürüm, reklam kimlikleri |
| [release/VERSION_HISTORY.md](release/VERSION_HISTORY.md) | Sürüm bazlı değişiklik kaydı |
| [store/DATA_SAFETY_AND_LISTING.md](store/DATA_SAFETY_AND_LISTING.md) | Play veri güvenliği beyanı ve mağaza metinleri |

### Analitik, reklam ve gizlilik

| Belge | Ne yanıtlar |
|---|---|
| [analytics/EVENTS.md](analytics/EVENTS.md) | Olay sözlüğü, parametreler, çağrı yerleri |
| [analytics/BIGQUERY.md](analytics/BIGQUERY.md) | JSONL → BigQuery yükleme, şema, sorgular |
| [analytics/PRIVACY_AND_CONSENT.md](analytics/PRIVACY_AND_CONSENT.md) | Toplanan/toplanmayan veri, rıza kapısı, saklama |
| [ads/INTEGRATION.md](ads/INTEGRATION.md) | AdMob/UMP akışı, banner rezervasyonu, test kimlikleri |
| [privacy/PRIVACY_POLICY_DRAFT.md](privacy/PRIVACY_POLICY_DRAFT.md) | Yayınlanabilir gizlilik politikası taslağı (boşluklarla) |

### Proje bilgisi ve araştırma

| Belge | Ne yanıtlar |
|---|---|
| [AI/PROJECT_CONTEXT.md](AI/PROJECT_CONTEXT.md) | Yeni katılan/AI için kısa mimari ve sözlük |
| [AI/PROJECT_HEALTH.md](AI/PROJECT_HEALTH.md) | Alan bazlı sağlık, kanıt ve açık riskler |
| [research/MEOWDOKU_REFERENCE.md](research/MEOWDOKU_REFERENCE.md) | Referans oyunla benzerlik/fark ve köken riski |
| [../REA/README.md](../REA/README.md) | Meowdoku statik analiz raporu (ham kanıt) |
| [../README.md](../README.md) | Kurulum, çalıştırma, derleme |

## Kaynak kodla eşleşme

| Belge konusu | Birincil kaynak |
|---|---|
| Oyun kuralları, can, yıldız, ödül | `scripts/core/game_state.gd`, `scripts/gameplay/board_view.gd` |
| İpucu hattı | `scripts/gameplay/hint_solver.gd` |
| Ekranlar ve modal akışları | `scripts/ui/main_controller.gd` |
| Reklam ve banner | `scripts/ads/ad_manager.gd`, `assets/ads/ads_config.json` |
| Telemetri | `scripts/core/telemetry.gd`, `assets/analytics/bigquery_schema.json` |
| 20 dil ve fallback | `scripts/core/loc.gd` |
| Bölüm verisi | `assets/levels/levels_database.json` |
| Android kimliği ve imza | `export_presets.cfg`, `android/build/config.gradle` |

## Bakım kuralları

1. Yeni bir davranış eklenirse önce bu indekste ilgili satır, sonra ilgili belge güncellenir.
2. Bir özellik yayına girerse etiketi **Planlanan → Mevcut** olarak değiştirilir ve kanıt satırı eklenir.
3. Bilinen bir eksik kapanırsa **Açık** satırı silinir; yerine doğrulama kanıtı yazılır.
4. Sürüm numarası değiştiğinde `release/VERSION_HISTORY.md`, `store/DATA_SAFETY_AND_LISTING.md` ve bu sayfadaki sürüm satırı birlikte güncellenir.
5. Belgelerde parola, keystore parolası, gerçek reklam birimi kimliği veya kişisel veri bulunmaz.

## Bilinen çelişkiler

| Çelişki | Etki | Takip |
|---|---|---|
| `project.godot` sürümü `1.0.0`, Android `1.0.4` | Hata raporlarında sürüm karışıklığı | [PROJECT_HEALTH](AI/PROJECT_HEALTH.md) |
| `project.godot` özellikleri Godot 4.7, eski analitik belgeleri 4.4 diyor | Doküman tutarlılığı | [VERSION_HISTORY](release/VERSION_HISTORY.md) |
| `assets/ui/` varlıkları Meowdoku'dan alınmış olarak tanımlanıyor | Yayın öncesi lisans/köken riski | [MEOWDOKU_REFERENCE](research/MEOWDOKU_REFERENCE.md) |
