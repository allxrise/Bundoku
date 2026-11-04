# Sürüm geçmişi

> **Karar:** Sürüm kaydı yalnız doğrulanabilir yapıtlara dayanır: `export_presets.cfg`, `project.godot`,
> derlenmiş APK ve git commit'leri. Bu depoda mağazaya yüklenmiş bir sürüme ait kayıt yoktur; bu sayfa
> yayın geçmişi değil, depo sürüm geçmişidir. Gelecekte her sürüm aynı tabloya işlenir.

İlgili: [../plan/11_STORE_RELEASE.md](../plan/11_STORE_RELEASE.md),
[SHIP_CHECKLIST.md](SHIP_CHECKLIST.md), [../plan/14_SOURCES_DECISIONS.md](../plan/14_SOURCES_DECISIONS.md).

## 1. Sürüm tablosu

| Sürüm | `versionCode` | Durum | Kanıt |
|---|---|---|---|
| `1.0.4` | 5 | Mevcut Android sürümü; mağazaya yüklendiğine dair kayıt yok | `export_presets.cfg`; APK badging |
| `1.0.0` | — | `project.godot` içindeki proje sürümü; uyumsuz | `project.godot` |
| Önceki kodlar | 2 | Yalnız commit kaydı var (`31ba337`) | git |
| Önceki kodlar | 1, 3, 4 | Kayıt yok | — |

**Açık:** `versionCode` 2'den 5'e nasıl gelindiği depoda kayıtlı değil. `project.godot` sürümü `1.0.0`
kaldığı için iki alan birbiriyle ve mağaza sürümüyle uyuşmuyor.

## 2. Değişiklik kaydı (commit bazlı)

| Commit | Özet | Sürüm eşlemesi |
|---|---|---|
| `40a6666` | Board: kazanmanın bir kez tetiklenmesi, taslak geri almanın tutarlılığı, havuç çakışma temizliği | Kayıtlı değil |
| `febb93f` | 20 dilli yerelleştirme, otomatik dil algılama, oyun içi dil seçici | `1.0.4` olarak işaretli |
| `20e1b90` | Tüm karo dokularında üst kenarlık; bölümler ızgarasında dokunmatik kaydırma | Kayıtlı değil |
| `a8a7cb5` | Pembe pill üst boşluğu, altın şerit, `tile_pink` / `tile_green` | Kayıtlı değil |
| `31ba337` | Release keystore yapılandırması, tema simgesi, `versionCode` 2 | Kod 2 |
| `677d5db` | ChatGPT 3D 9-slice UI kapları, çerçeveler, butonlar, karolar | Kayıtlı değil |
| `b5147ce` | İlk commit: oyun projesi + REA analiz arşivi | Başlangıç |

Commit özetleri mesajlardan alınmıştır; hangi commit'in hangi mağaza sürümüne girdiği yalnız `febb93f` için
açıkça işaretlidir. Diğer satırlar sürüm numarası iddiası taşımaz.

## 3. Yapıtlar

| Yapıt | Sürüm | Boyut / not |
|---|---|---|
| `build/android/Bundoku-debug.apk` | `1.0.4` / code 5 | Yaklaşık 185 MB; debug imzalı |
| Release AAB | Repoda yok | Üretildiğine dair kanıt yok |
| Play internal testing yüklemesi | Kayıt yok | Bu depoda kanıt yok |
| iOS derlemesi | Repoda yok | Kapsam dışı |

Debug APK'nın birleşik manifesti `INTERNET`, `AD_ID`, `ACCESS_NETWORK_STATE`, `READ_BASIC_PHONE_STATE`,
`WAKE_LOCK` ve `FOREGROUND_SERVICE` izinlerini taşır; App ID test kimliğidir.

## 4. Sürümleme kuralları

1. `versionCode` her Play yüklemesinde en az 1 artar; mevcut değer 5'tir, sonraki en az 6'dır.
2. `versionName` `MAJOR.MINOR.PATCH` biçimindedir; kırıcı kayıt değişikliği MAJOR artırır.
3. `project.godot` `config/version` ile Android `version/name` aynı commit'te güncellenir.
4. Her sürüm için bu dosyaya satır eklenir: sürüm, kod, tarih, kısa özet, kanıt.
5. Sürüm notu kullanıcıya görünen dille yazılır; iç commit mesajı kopyalanmaz.
6. Test reklam kimliğiyle üretilen yapı "release" sayılmaz.

## 5. Şablon

| Sürüm | Kod | Tarih | Özet | Kanıt |
|---|---|---|---|---|
| `x.y.z` | N | YYYY-AA-GG | Kullanıcıya görünen değişiklikler | APK/AAB özeti, test kaydı |

## 6. Bilinen sorunlar

| Sorun | Etki | Takip |
|---|---|---|
| `1.0.0` / `1.0.4` uyumsuzluğu | Telemetri `app_version`, destek, kohort | PB-07 |
| Belgelerde "Godot 4.4" ifadesi | `project.godot` `"4.7"` der; eski metin | 14 §3 |
| `versionCode` 3–4 kaydı yok | Sürüm geçmişi eksik | Bu sayfa |
| Release AAB yok | Mağaza kapısı açık | PB-09 |
| Test reklam kimlikleri | Gelir yok | PB-01, PB-02 |
