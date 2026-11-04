# 13 — QA ve kabul kriterleri

> **Karar:** Yayın, release imzalı yapı üzerinde aşağıdaki senaryoların tamamı geçmeden onaylanmaz. Bölüm
> içeriği ve ipucu motoru yayın öncesi otomatik/elle doğrulanır; reklam, rıza ve kayıt akışları cihazda
> ayrıca denenir. Bu belge her satırın doğrulama türünü (çalıştırma, kod incelemesi) açıkça işaretler.

Etiketler: **Çalıştırma** (cihazda veya araçla çalıştırılarak doğrulandı), **Kod** (kaynak/veri incelemesiyle
doğrulandı, cihaz testi ayrı), **Açık** (eksik veya henüz doğrulanmadı), **Planlanan** (uygulanmadı).
Kaynaklar: `scripts/`, `assets/levels/`, APK çıktısı. Oynanış kuralları:
[02_CORE_GAMEPLAY.md](02_CORE_GAMEPLAY.md); içerik: [04_CONTENT_AND_PROGRESSION.md](04_CONTENT_AND_PROGRESSION.md).

## 1. Doğrulanmış kanıtlar

| Kanıt | Sonuç | Ortam / yöntem |
|---|---|---|
| 120 bölüm çözülebilirliği | 120/120 gerçek girdiyle çözüldü | Cihaz/oyun içi oynanış |
| İpucu hattı | 120/120 sıfır hatayla çözdü | `HintSolver` uçtan uca |
| Geri alma | 60 anlık görüntü sınırı; otomatik X sahipliği geri yükleniyor | `board_view.gd` davranış testi |
| Taslak modu | Çakışan taslak tavşan can/yıldız kaybettirmiyor; iptal öncesi duruma dönüyor | `board_view.gd` davranış testi |
| Cihaz telemetrisi | Satırlar `user://telemetry/` altında oluştu | Pixel 9, Android 17 |
| Banner rezervasyonu | `banner_loaded` yüksekliği 84 viewport px | Pixel 9, Android 17 |
| Banner gösterimi | `banner ad_impression` kaydı alındı | Pixel 9, Android 17 |
| Debug APK | Kuruldu ve açıldı | Pixel 9, Android 17 |

**Not:** Bu kanıtlar debug yapıya aittir; release imzalı AAB üzerinde tekrarlanmalıdır (PB-12).

## 2. Oynanış kabul kriterleri

| ID | Senaryo | Beklenen | Durum |
|---|---|---|---|
| G-01 | Tahtaya N tavşan yerleştir | Satır/sütun/bölge başına tam 1; çapraz komşuluk yok | **Çalıştırma** |
| G-02 | Çakışan tavşan | `mistake_made`, 1 can gider, hücreler kırmızı vurgulanır | **Kod** |
| G-03 | Tek dokunuş boş hücre | X konur; sürükleme geçilen hücrelere X yayar | **Kod** |
| G-04 | Çift dokunuş | Tavşan konur/kaldırılır (300 ms eşiği) | **Kod** |
| G-05 | Önceden dolu hücre | Dokunuş yok sayılır; silinemez | **Kod** |
| G-06 | Oto-X açık | Tavşanın satırı, sütunu, bölgesi ve 8 komşusu X olur | **Kod** |
| G-07 | Tavşan kaldırma | Yalnız o tavşanın sahiplendiği otomatik X'ler temizlenir | **Kod** |
| G-08 | Taslak modunda çakışma | Can gitmez; onay işaretleri kalıcı yapar, çakışmayı hata saymaz | **Çalıştırma** |
| G-09 | Taslak iptali | Taslak öncesi tahta aynen geri gelir | **Çalıştırma** |
| G-10 | Geri al | Son hamle geri alınır; 60 adım sonrası en eski düşer | **Çalıştırma** |
| G-11 | Can bitişi | 3 hata sonrası "canlar tükendi" modalı; yenile veya baştan başlat | **Kod** |
| G-12 | Çözüm | Tavşan sayısı N ve çakışma yoksa kazanma bir kez tetiklenir | **Kod** |

## 3. İçerik ve ekonomi kabul kriterleri

| ID | Senaryo | Beklenen | Durum |
|---|---|---|---|
| C-01 | Bölüm şeması | 120 kayıt; `id` 1–120; `size` 4–9; her boydan 20 | **Kod** |
| C-02 | Zorluk dağılımı | `easy/medium/hard/expert` × 30 | **Kod** |
| C-03 | Çözüm geçerliliği | Her `solution` satır/sütun/bölge permütasyonu; komşuluk yok | **Kod** |
| C-04 | İpucu çözücülüğü | Tüm bölümler ipucu hattıyla çözülür | **Çalıştırma** |
| C-05 | Yıldız | ≥2 hata veya >180 sn → 1; 1 hata veya >90 sn → 2; değilse 3 | **Kod** |
| C-06 | Kupa | `10 + 5 × yıldız` | **Kod** |
| C-07 | Bonus | İlk temizlemede her 2. bölüm +1 ipucu, her 4. +1 havuç | **Kod** |
| C-08 | Reklam aralığı | easy 5, medium 4, hard 3, expert 2 | **Kod** |
| C-09 | Kilit açma | Yalnız sıradaki kilitli bölüm ilerletir; eski bölüm tekrarı açmaz | **Kod** |
| C-10 | Günlük bölüm | Tarih tabanlı indeks açılmış bölüme kırpılır | **Kod** |

## 4. Reklam, rıza ve analitik kabul kriterleri

| ID | Senaryo | Beklenen | Durum |
|---|---|---|---|
| A-01 | Android + gerçek SDK | UMP → init → interstitial/rewarded/banner yüklenir | **Kod** (banner **Çalıştırma**) |
| A-02 | Masaüstü/editör | `supported=false`; 3 sn simüle modal; akış devam eder | **Kod** |
| A-03 | Banner | Alt alan rezerve edilir; tam ekran reklamda gizlenir | **Kod** (banner yükleme **Çalıştırma**) |
| A-04 | Ödüllü reklam | Gerçek reklamda ödül yalnız `ad_rewarded` geldiyse verilir; simüle modalda koşulsuz | **Açık** (gerçek SDK ile uçtan uca) |
| A-05 | Reklam yok/no-fill | Simüle modale düşer; kullanıcı kilitlenmez | **Kod** |
| A-06 | Analitik rıza | `denied` → satır yok; `held` → RAM'de ≤256; `granted` → JSONL | **Kod** |
| A-07 | Yükleme | `upload_url=""`; telemetri yüklemesi yok (reklam SDK trafiği hariç) | **Kod** |
| A-08 | EEA analitik kartı | Oyuncuya sorulur, ret dosyaları siler | **Açık** |
| A-09 | `ad_impression` | Yalnız gerçek reklamda; simüle modalda yok | **Kod** |
| A-10 | SSV | Sunucu tarafı ödül doğrulaması | **Açık** |

EEA testi: `assets/ads/ads_config.json` içindeki `debug_eea` yalnız UMP test coğrafyasını etkiler; analitik
`held` durumu `OS.get_locale()` ülke koduna bağlıdır. Analitik rıza senaryosu için cihaz dili/bölgesi
EEA ülkesine ayarlanmalı ve uygulama verisi temizlenmelidir.

## 5. Yerelleştirme ve UI kabul kriterleri

| ID | Senaryo | Beklenen | Durum |
|---|---|---|---|
| L-01 | 20 dil listesi | `Loc.LANGUAGES` 20 kayıt; modal 2 sütun | **Kod** |
| L-02 | Dil değişimi | Tüm ekranlar yeniden kurulur; seçim kayda yazılır | **Kod** |
| L-03 | Fallback | Eksik anahtar `en` → `tr` sırasıyla döner | **Kod** |
| L-04 | Arapça/Urduca | RTL yönü ve aynalama | **Açık** |
| L-05 | Çoğul | "1 Days" gibi hatalı biçim yok | **Açık** |
| L-06 | Güvenli alan | Çentik ve jest çubuğu içerik kaplamaz | **Açık** (senaryo test edilmedi) |
| L-07 | Banner + güvenli alan | Alt boşluk üst üste binmez | **Kod** (84 px ölçüldü) |
| L-08 | Küçük ekran / tablet | Taşma yok | **Planlanan** |
| L-09 | Kontrast / dokunma hedefi | WCAG AA; min 44×44 dp | **Açık** |

## 6. Kayıt ve sürüm kabul kriterleri

| ID | Senaryo | Beklenen | Durum |
|---|---|---|---|
| S-01 | Uygulamayı kapat/aç | İlerleme, yıldız, ekonomi, dil korunur | **Açık** (regresyon adımı) |
| S-02 | Kayıt dosyası | `user://bundoku_save.cfg`, düz ConfigFile | **Kod** |
| S-03 | Eski kayıt | Eksik anahtarlar varsayılanla yüklenir | **Kod** |
| S-04 | Bozuk kayıt | Kullanıcıya bildirim / kurtarma | **Açık** |
| S-05 | Sürüm alanları | `project.godot` = Android `versionName` | **Açık** |
| S-06 | Release imza | Play'den kurulan yapı açılır | **Açık** |

## 7. Test matrisi

| Ortam | Amaç | Durum |
|---|---|---|
| Pixel 9 / Android 17 / debug APK | Ana akış, reklam, telemetri | **Çalıştırma** |
| Android emülatörü x86_64 | İkinci cihaz, farklı çözünürlük | **Planlanan** |
| Masaüstü Linux / GL Compatibility | Simüle reklam, klavye/fare | **Planlanan** |
| Editör | Hızlı regresyon | **Planlanan** |
| Düşük RAM / arka plan | Süreç öldürme, kayıt dayanıklılığı | **Açık** |
| Uçak modu | Reklam yok, oyun devam | **Planlanan** |
| EEA dili | `held` rıza, kart yok | **Açık** |

## 8. Yayın öncesi duman testi

1. Uygulama verisini temizle: `adb shell pm clear com.bundoku.puzzle`.
2. Açılışta ana ekran, günlük/lig butonları ve bölüm ızgarası görünür.
3. Bölüm 1'i aç; tek dokunuş X, çift dokunuş tavşan, sürükleme X.
4. Geri al, taslak aç/kapat, ipucu ve havuç kullan.
5. Üç hata ile can bitişini, yenile akışını ve reklam modalını gör.
6. Bölümü çöz; yıldız, kupa ve bonus metnini doğrula.
7. Aralık dolduysa `level_break` interstitial'ının kazanma modalından önce geldiğini doğrula.
8. Banner yüksekliğinin alt yerleşimi kapatmadığını kontrol et.
9. Dili değiştir, uygulamayı kapat/aç, seçimin korunduğunu doğrula.
10. Telemetri satırlarını çek:
    `adb exec-out run-as com.bundoku.puzzle cat files/telemetry/events-$(date -u +%Y%m%d).jsonl`
    (yalnız debuggable yapıda; release'te operatör dışa aktarımı kullanılmaz).

## 9. Bilinen açıklar ve çıkış kriteri

| Açık | Etki | Takip |
|---|---|---|
| `1.0.0` / `1.0.4` sürüm uyumsuzluğu | Kohort ve destek karışıklığı | PB-07 |
| Test reklam kimlikleri | Yayında gelir yok / politika riski | PB-01, PB-02 |
| EEA analitik rıza kartı yok | Ölçüm kaybı, uyum riski | PB-06 |
| RTL ve çoğul hataları | 20 dil iddiası zayıflar | PB-17, PB-18 |
| Otomatik test/CI yok | Regresyon riski | PB-24 |
| Çökme raporlaması yok | Olay tespiti gecikir | PB-16 |
| Release AAB doğrulanmadı | Mağaza kapısı açık | PB-09, PB-12 |

**Çıkış kriteri:** P0 maddelerinin tamamı kapalı; bu belgedeki `Açık` satırlardan yayın engelleyici olanlar
kapatılmış; release AAB ile duman testi geçilmiş; telemetri, reklam ve gizlilik belgeleri kodla tutarlı.
