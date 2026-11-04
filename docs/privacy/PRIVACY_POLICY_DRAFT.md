# Bundoku gizlilik politikası — taslak

> **Durum: TASLAK.** Bu metin hukuki görüş değildir. Yayınlanmadan önce aşağıdaki köşeli parantezli alanlar doldurulmalı, hukuk/uyum kontrolü yapılmalı ve Play Veri Güvenliği formuyla birebir uyumlu hale getirilmelidir. Uygulama davranışı: `scripts/core/telemetry.gd`, `scripts/ads/ad_manager.gd`. Ayrıntılar: [../analytics/PRIVACY_AND_CONSENT.md](../analytics/PRIVACY_AND_CONSENT.md). Mağaza beyanı: [../store/DATA_SAFETY_AND_LISTING.md](../store/DATA_SAFETY_AND_LISTING.md).

**Yürürlük tarihi:** [YÜRÜRLÜK TARİHİ]
**Veri sorumlusu:** [GELİŞTİRİCİ ADI / TÜZEL KİŞİ], [ADRES]
**İletişim:** [E-POSTA]
**Politika URL'si:** [POLİTİKA URL]

## 1. Kapsam

Bu politika, **Bundoku: Tavşan Bulmacası** mobil oyunu (`com.bundoku.puzzle`) için geçerlidir. Oyun çevrimdışı oynanabilir; hesap oluşturma, giriş, bulut kayıt ve oyun içi sohbet yoktur.

## 2. İşlenen veriler

### 2.1 Cihazda kalan oyun verileri

| Veri | Amaç | Yer |
|---|---|---|
| İlerleme, yıldızlar, tamamlanan bölümler, kupa | Oyun durumunu sürdürmek | `user://bundoku_save.cfg` |
| İpucu/havuç sayıları, reklam sayaçları | Ekonomi ve reklam sıklığını yönetmek | `user://bundoku_save.cfg` |
| Dil, ses, otomatik X, desen, ilk dokunma ayarları | Tercihleri hatırlamak | `user://bundoku_save.cfg` |

Bu dosya cihazda düz metin olarak tutulur ve sunucuya gönderilmez.

### 2.2 Yerel analitik olayları

Oyun, ürün iyileştirmesi için aşağıdaki olayları cihazda JSONL olarak yazar:

- Oturum açma/kapama, ilk açılış, duraklatma/devam.
- Bölüm başlangıcı, tamamlanma, başarısızlık, terk; süre, hata sayısı, yıldız, bölüm boyutu, zorluk.
- Tavşan yerleştirme/kaldırma, geri al, taslak, tahtayı temizleme; satır/sütun gibi konum bilgileri.
- İpucu ve havuç kullanımı; kalan kaynak sayıları.
- Ekran görüntülemeleri ve düğme dokunuşları (`ui_tap`: ekran, düğme kimliği).
- Ayar değişiklikleri (dil, ses, otomatik X, desen, ilk dokunma).
- 60 saniyede bir performans örneği (FPS, kare süresi, bellek, nesne/düğüm sayısı).
- Cihaz bağlamı: uygulama sürümü, motor sürümü, platform, işletim sistemi sürümü, cihaz modeli, CPU/GPU bilgisi, ekran boyutu, yerel ayar, oyun dili.
- Rastgele üretilmiş kurulum kimliği (`user_pseudo_id`) ve oturum kimliği.

**Oyunun kendi telemetrisinde toplanmayanlar:** ad, takma ad, e-posta, telefon, hesap kimliği, serbest metin, dosya yolu, ekran görüntüsü, kişi listesi, konum, reklam kimliği (GAID/IDFA), ödeme bilgisi. Reklam SDK'ları kendi politikaları kapsamında reklam kimliğini işleyebilir (bkz. 2.3).

### 2.3 Reklam verileri

Oyun, Google AdMob üzerinden reklam gösterir; `project.godot` içinde etkinleştirilmiş Meta mediation ile Meta Audience Network aracılı reklam da kullanılabilir. Reklam yazılım geliştirme kitleri (SDK), reklam sunmak ve ölçmek için cihaz bilgisi, yaklaşık konum (IP'den türetilebilir), reklam etkileşimleri ve reklam kimliği gibi verileri işleyebilir. Bu işleme ilgili sağlayıcının politikasına tabidir.

## 3. İşleme amaçları ve hukuki dayanak

| Amaç | Hukuki dayanak (taslak) |
|---|---|
| Oyunu çalıştırmak ve tercihleri hatırlamak | Sözleşmenin ifası / meşru menfaat |
| Yerel ürün analitiği | Açık rıza (EEA/UK/CH) veya meşru menfaat (diğer bölgeler) |
| Kişiselleştirilmiş reklam | Açık rıza (UMP onayı) |
| Kişiselleştirilmemiş reklam | Meşru menfaat / sağlayıcı politikası |
| Güvenlik ve kötüye kullanım önleme | Meşru menfaat |

EEA/UK/CH'de analitik, kullanıcı kabul edene kadar cihazda bellekte tutulur ve dosyaya yazılmaz. Bu bölgeler için analitik rıza kartı **henüz uygulanmamıştır** (Açık madde).

## 4. Saklama ve silme

| Veri | Saklama |
|---|---|
| Oyun kaydı | Kullanıcı silene veya uygulamayı kaldırana kadar cihazda |
| Analitik JSONL | Etkin dosya 2 MB'ta döner; en fazla 7 arşiv tutulur |
| Rıza durumu ve kimlik | Uygulama verisi silinene kadar `user://telemetry/state.cfg` |
| Sunucu tarafı | **Yok**; uygulama hiçbir analitik veriyi yüklemez |

Kullanıcı, cihaz ayarlarından uygulama verilerini temizleyerek veya uygulamayı kaldırarak tüm yerel verileri silebilir.

## 5. Paylaşım

- Oyun verileri satılmaz, kiralanmaz veya reklam amacıyla üçüncü taraflarla paylaşılmaz.
- Reklam SDK'ları (Google AdMob, UMP ve yapılandırmada etkin olan Meta Audience Network) kendi politikaları kapsamında veri işler:
  - Google: https://policies.google.com/privacy
  - Meta: https://www.facebook.com/privacy/policy
- Yasal zorunluluk halinde yetkili makamlarla paylaşım yapılabilir.
- Analitik için sunucu/alt işleyici **yoktur**; ileride eklenirse bu politika ve mağaza beyanı güncellenir.

## 6. Uluslararası aktarım

Reklam sağlayıcıları verileri bulunduğunuz ülke dışında işleyebilir. Sağlayıcıların standart sözleşme hükümleri ve kendi aktarım mekanizmaları geçerlidir. [HUKUKİ ONAY GEREKLİ]

## 7. Çocuklar

Bu taslakta oyunun çocuklara yönelik pazarlanmadığı varsayılır. Mağaza yaş derecelendirmesi ve hedef kitlesi kararı [KARAR] olarak açıktır; derecelendirme tamamlanmadan bu bölüm kesinleşemez. Bilerek 13 yaş altından kişisel veri toplanmaz; böyle bir durum tespit edilirse veriler silinir.

## 8. Haklarınız

Bulunduğunuz yargı bölgesine göre şu haklara sahip olabilirsiniz: bilgi alma, erişim, düzeltme, silme, işlemeyi kısıtlama, itiraz, rıza geri çekme ve şikâyet. Başvuru: [E-POSTA]. Cihazdaki veriler için uygulama verisini temizlemek en hızlı yöntemdir.

## 9. Güvenlik

Yerel veriler uygulama kum havuzunda tutulur. Oyun kaydı ve yerel analitik için sunucu iletimi olmadığından bu veriler için aktarım şifrelemesi uygulanmaz; cihaz erişimi olan kişiler kayıt dosyasını okuyabilir (bilinen sınırlama). Reklam SDK'larının iletişimi kendi güvenlik uygulamalarına tabidir.

## 10. Değişiklikler

Bu politika güncellendiğinde yürürlük tarihi değişir; önemli değişiklikler mağaza sayfasında veya oyun içinde duyurulur.

## 11. İletişim

[GELİŞTİRİCİ ADI / TÜZEL KİŞİ]
[ADRES]
[E-POSTA]

## Yayın öncesi tamamlanacaklar

| # | Madde | Durum |
|---|---|---|
| 1 | Veri sorumlusu kimliği, adres ve e-posta | Açık |
| 2 | Yürürlük tarihi ve politikaya kalıcı URL | Açık |
| 3 | EEA/UK/CH analitik rıza akışı | Açık |
| 4 | Play Veri Güvenliği formu ile birebir eşleşme | Açık |
| 5 | Yaş derecelendirmesi ve çocuk kitlesi kararı | Açık |
| 6 | Reklam sağlayıcı listesinin kesinleşmesi (Meta mediation dahil) | Açık |
| 7 | Hukuki inceleme | Açık |
