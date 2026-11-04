# Veri güvenliği ve mağaza listesi

> **Karar:** Play Data Safety formu iki katmanı ayrı beyan eder: (1) uygulamanın kendi analitiği cihazda
> kalır ve cihaz dışına gönderilmez; (2) AdMob/Meta reklam SDK'ları cihaz ve reklam kimliği ile IP tabanlı
> yaklaşık konum gibi verileri kendi politikalarına göre işler. Form, ikinci katmanı "toplanıyor/paylaşılıyor"
> olarak kapsamak zorundadır. Bu belge hukuki görüş değildir; yayın öncesi SDK veri güvenliği kılavuzlarıyla
> doğrulanmalıdır.

İlgili: [../plan/11_STORE_RELEASE.md](../plan/11_STORE_RELEASE.md),
[../analytics/PRIVACY_AND_CONSENT.md](../analytics/PRIVACY_AND_CONSENT.md),
[../privacy/PRIVACY_POLICY_DRAFT.md](../privacy/PRIVACY_POLICY_DRAFT.md),
[../ads/INTEGRATION.md](../ads/INTEGRATION.md).

## 1. Envanter: uygulama ve SDK ayrımı

| Veri türü | Uygulama kendisi | Üçüncü taraf SDK | Amaç | Cihaz dışına çıkar mı? |
|---|---|---|---|---|
| Oyun içi eylemler (bölüm, hata, ipucu) | Evet, `user://telemetry` | Hayır | Ürün analizi | **Hayır** (sunucu yok) |
| Performans örnekleri (FPS, bellek) | Evet, yerel | Hayır | Performans | **Hayır** |
| Rastgele kurulum kimliği | Evet, yerel | Hayır | Kohort analizi | **Hayır** |
| Reklam kimliği (AD_ID) | Hayır | AdMob / Meta | Reklam | **Evet** (SDK) |
| Yaklaşık konum (IP) | Hayır | AdMob / Meta | Reklam | **Evet** (SDK) |
| Tanılama / SDK olayları | Hayır | AdMob / Meta | Reklam, sahtekârlık önleme | **Evet** (SDK) |
| Satın alma geçmişi | Yok | Yok | — | — |
| Ad, e-posta, telefon | Yok | Yok | — | — |
| Kişisel dosya, kişi, takvim | Yok | Yok | — | — |

**Mevcut:** `Telemetry.upload_url` boştur ve telemetri hiçbir HTTP isteği yapmaz
(`scripts/core/telemetry.gd`). Yerel dosyalar 2 MB'ta döner, 7 arşiv tutulur, `held` durumunda en fazla 256
satır bellekte bekler. **Açık:** SDK'ların hangi veri türlerini topladığı sürüm bazında Google/Meta
dokümanından doğrulanmalı; aşağıdaki tablo beyanın iskeletidir.

## 2. Data Safety beyanı (taslak)

| Play kategorisi | Beyan | Gerekçe | Durum |
|---|---|---|---|
| Konum → Yaklaşık konum | Toplanıyor, paylaşılıyor | Reklam SDK'sı IP'den türetir | **Açık** (SDK doğrulaması) |
| Kişisel bilgiler | Toplanmıyor | Hesap, form veya iletişim yok | **Mevcut** |
| Finansal bilgiler | Toplanmıyor | IAP yok | **Mevcut** |
| Sağlık / fitness | Toplanmıyor | İlgisiz | **Mevcut** |
| Mesajlar | Toplanmıyor | Sohbet yok | **Mevcut** |
| Fotoğraf / video | Toplanmıyor | Medya erişimi yok | **Mevcut** |
| Ses / müzik / dosyalar | Toplanmıyor | Kayıt yok | **Mevcut** |
| Kişiler / takvim | Toplanmıyor | İzin yok | **Mevcut** |
| Uygulama etkinliği | SDK'ya bağlı (doğrulanacak) | Reklam etkileşimi | **Açık** |
| Web tarama geçmişi | Toplanmıyor | Tarayıcı yok | **Mevcut** |
| Uygulama bilgisi ve performans | Yerel; SDK tanılaması olabilir | Reklam SDK'sı | **Açık** |
| Cihaz veya diğer kimlikler | Toplanıyor, paylaşılıyor | Reklam kimliği | **Açık** (SDK) |

**Beyan kuralları:**
- Uygulamanın kendi JSONL analitiği "toplanıyor" sayılmaz; cihazdan çıkmıyor. Sunucu eklenirse form aynı
  sürümde "toplanıyor" olarak güncellenir.
- Reklam SDK'ları nedeniyle formda "reklam veya pazarlama" amacı ve üçüncü taraflarla paylaşım işaretlenir.
- "Aktarım sırasında şifreleme" işaretlenir; SDK trafiği TLS üzerindendir, yine de SDK dokümanıyla doğrulanır.
- "Kullanıcı silmeyi talep edebilir" için destek adresi ve yerel veri silme yolu tanımlanır.
- Çocuklara yönelik beyan yapılırsa Families politikası, reklam SDK'sı kısıtları ve kişiselleştirilmiş
  reklamın kapatılması gerekir; mevcut `tag_for_under_age_of_consent=false` ayarı bunu karşılamaz.

## 3. İzin gerekçeleri

| İzin | Kaynak | Gerekçe | Karar |
|---|---|---|---|
| `INTERNET` | `export_presets.cfg` | Reklam SDK'sı | Gerekli |
| `AD_ID` / `com.google.android.gms.permission.AD_ID` | Birleşik manifest | Reklam kimliği | Reklam varsa gerekli |
| `ACCESS_NETWORK_STATE` | Birleşik manifest | Reklam bağlantısı | Gerekli |
| `READ_BASIC_PHONE_STATE` | Birleşik manifest | Oyun kodu bu izni kullanmıyor; kaynağı doğrulanmalı | **Açık** |
| `WAKE_LOCK` | Birleşik manifest | Reklam/oturum | SDK kaynaklı |
| `FOREGROUND_SERVICE` | Birleşik manifest | SDK kaynaklı | SDK kaynaklı |

`READ_BASIC_PHONE_STATE` normal izin olsa da oyun kodu bu izni kullanmıyor; gerekliliği ve Play beyanı
doğrulanmalıdır. İzin listesi `aapt2 dump badging build/android/Bundoku-debug.apk` ile doğrulanmıştır.

## 4. Mağaza listesi alanları

| Alan | Değer | Durum |
|---|---|---|
| Uygulama adı | `Bundoku: Tavşan Bulmacası` (25 karakter) | **Mevcut** |
| Kısa açıklama (TR) | `120 el yapımı mantık bulmacası: tavşanları yerleştir, ipuçlarını takip et.` | **Planlanan** |
| Kısa açıklama (EN) | `120 handcrafted logic puzzles: place the bunnies, follow the clues.` | **Planlanan** |
| Kategori | Bulmaca (Puzzle) | **Planlanan** |
| Etiketler | Mantık, bulmaca, rahatlatıcı, tek oyunculu | **Planlanan** |
| Reklam | Var | **Mevcut** |
| Uygulama içi satın alma | Yok | **Mevcut** |
| Hesap / giriş | Yok | **Mevcut** |
| Çevrimdışı | Oynanış evet; reklam için ağ gerekir | **Mevcut** |
| Yaş aralığı | Karar verilmedi | **Açık** |

## 5. Tam açıklama (taslak)

`Bundoku, sevimli tavşanların dünyasında geçen sakin bir mantık bulmacasıdır. Her satırda, her sütunda ve
her renkli bölgede tam olarak bir tavşan olacak şekilde tahtayı doldur. Tavşanlar birbirine dikey veya
çapraz komşu olamaz.`

`120 el yapımı bölüm, 4×4'ten 9×9'a kadar büyüyen tahtalar ve dört zorluk katmanıyla ilerle. Otomatik X,
taslak modu, geri alma ve ipucu araçlarıyla takıldığın yerde devam et. Oyun çevrimdışı çalışır ve 20 dilde
oynanabilir.`

`Reklam destekli ücretsiz bir oyundur; ödüllü reklamlar karşılığında ek ipucu ve can yenileme kazanabilirsin.`

**Yasak:** Olmayan özellik (reklamsız sürüm, bulut kayıt, günlük ödül, çok oyunculu) mağaza metnine yazılmaz.

## 6. İçerik derecelendirmesi cevapları

| Soru | Cevap |
|---|---|
| Şiddet, kan, korku | Hayır |
| Cinsellik, çıplaklık | Hayır |
| Küfür / uygunsuz dil | Hayır |
| Kontrollü madde, alkol, kumar | Hayır |
| Kullanıcılar arası etkileşim / kullanıcı içeriği | Hayır |
| Konum paylaşımı | Hayır (uygulama konum izni istemez; SDK IP verisi ayrı beyan) |
| Dijital satın alma | Hayır (IAP yok) |
| Reklam | Evet |
| Çevrimiçi hesap | Hayır |

## 7. "Yenilikler" metni (1.0.4)

`20 dilde oynanabilir; oyun içi dil seçici eklendi.`

Bu metin yalnız `febb93f` commit'inin işaretlediği `1.0.4` kapsamını anlatır. Sonraki board düzeltmeleri
(`40a6666`) hangi sürüme gireceği belirlenmeden mağaza metnine yazılmaz.

## 8. Yayın öncesi açık işler

- [ ] Reklam SDK'larının güncel veri türlerini Google/Meta kılavuzundan doğrula ve forma işle.
- [ ] Gizlilik politikası URL'sini yayınla; mağaza ve oyun içi erişimi ekle.
- [ ] `READ_BASIC_PHONE_STATE` iznini kaldır veya gerekçelendir.
- [ ] Destek e-postası ve veri silme talebi kanalını yayınla.
- [ ] Hedef kitle ve çocuk beyanı kararını ver; Families gereksinimlerini uygula.
- [ ] 512×512 simge, 1024×500 grafik ve gerçek ekran görüntülerini üret.
- [ ] Kısa/tam açıklamayı 80/4000 karakter sınırında doğrula.
- [ ] İçerik derecelendirmesi anketini doldur.
- [ ] `app-ads.txt` ve reklam beyanını tamamla.
- [ ] Data Safety, gizlilik politikası ve `docs/analytics/PRIVACY_AND_CONSENT.md` metinlerini aynı sürümde tut.
