# İçerik ve İlerleme

> **Özet:** Oyunun tüm içeriği tek bir JSON dosyasındadır: [`assets/levels/levels_database.json`](../../assets/levels/levels_database.json).
> 120 seviye, 4×4–9×9 boyut, 4 kademe, doğrusal açılım. Bu belge şemayı, dağılımı, ön yerleştirme (prefill)
> kurallarını, günlük bölüm davranışını, lig simülasyonunu ve yeni seviye kabul kuralını tanımlar.
> Oynanış tarafı: [`02_CORE_GAMEPLAY.md`](02_CORE_GAMEPLAY.md).

Durum etiketleri: **Mevcut**, **Planlanan**, **Açık**.

## 1. Veritabanı şeması (Mevcut)

Dosyanın kökü bir **dizi**dir (120 eleman). `GameState._load_levels()` hem dizi hem `{"levels": [...]}`
sarmalını kabul eder, ancak dosya düz dizidir.

| Alan | Tip | Anlamı | Koddaki kullanımı |
|---|---|---|---|
| `id` | int | 1…120 | Yalnızca veri; oyun indeks kullanır |
| `size` | int | Tahta kenarı N (4…9) | `BoardView.setup_level()`, `level_header` |
| `tier` | string | `easy` / `medium` / `hard` / `expert` | Reklam aralığı, etiket, renk |
| `rank` | int | 1…5 | **Açık:** hiçbir kodda okunmuyor |
| `steps` | int | Üretimdeki adım sayısı | **Açık:** hiçbir kodda okunmuyor |
| `regionMap` | int[][] | N×N bölge kimlikleri, tam `0…N-1` | `regionMap[r][c]`, `REGION_COLORS` |
| `solution` | int[][] | N adet `[satır, sütun]` (0 tabanlı) | `solution_set`, ipucu ve havuç |
| `prefillPositions` | int[][] | Başlangıçta kilitli tavşanlar (boş olabilir) | `prefill_set`, kilit rozeti |

Gerçek örnek (seviye 1, dosyadan birebir):

```json
{
  "id": 1, "size": 4, "tier": "easy", "rank": 1, "steps": 4,
  "regionMap": [[3,3,0,3],[1,3,3,3],[3,3,2,2],[3,3,3,2]],
  "solution": [[0,2],[1,0],[2,3],[3,1]],
  "prefillPositions": [[2,3]]
}
```

120 seviyenin tamamı için doğrulanan yapısal gerçekler: `solution` uzunluğu = `size`; çözümde her satır,
sütun ve bölge tam bir kez; bölge kimlikleri tam `0…N-1`; çözümde komşu (çapraz dahil) tavşan çifti yok;
`prefillPositions` çözümün alt kümesi; ipucu hattı seviyeyi sıfır hatayla bitiriyor.

## 2. Dağılım

Her boyuttan (4×4, 5×5, 6×6, 7×7, 8×8, 9×9) **20'şer** seviye vardır.

| Kademe | Seviye | `rank` | Not |
|---|---|---|---|
| `easy` | 30 | 1 | Her boyuttan 5 seviye |
| `medium` | 30 | 2 | Her boyuttan 5 seviye |
| `hard` | 30 | 3 | Her boyuttan 5 seviye |
| `expert` | 30 | 4 (18 seviye), 5 (12 seviye) | Yalnızca bu kademede iki rank var |

Kademe, dosyadaki sırayla monoton değildir: ilk 15 seviye `easy`, 16–30 `medium`, 31–35 tekrar `easy`,
36–40 `hard`… Oyuncu 36. seviyede `hard` ile karşılaşır. "Kademe = bölüm aralığı" varsayımı yanlıştır;
ilerleme yalnızca dizin sırasına göredir. Boyut ve kademe ayrı eksenlerdir (her kademede 4×4 ile 9×9
birlikte bulunur), ancak zorluk doğrulanmış bir metrikle ölçülmüyor (Açık).

## 3. Ön yerleştirme (prefill)

| Kural | Değer |
|---|---|
| Prefill içeren seviye | 10 (id 1–10) |
| Prefill sayısı | Her birinde tam **1** tavşan |
| Boyutlar | id 1–5: 4×4, id 6–10: 5×5 |
| Kilit davranışı | Hücre dokunuşa kapalı; kilit rozeti çizilir (`board_view.gd` `_tex_mark_lock`) |
| Auto-X | Açılışta prefill tavşanları için otomatik X uygulanır (`setup_level()`) |

Prefill yalnızca öğretici işlev görür; 11. seviyeden itibaren tahta tamamen boştur. Ayrı bir eğitim/öğretici
ekranı yoktur (Açık).

## 4. Açılım ve ilerleme

- **Doğrusal (Mevcut):** `unlocked_level_index` tek bir tamsayıdır; yalnızca çözülen seviye bu indekse
  **eşitse** bir sonraki açılır (`GameState.complete_level()`).
- Seviye seçim ekranında indeks `≤ unlocked_level_index` olanlar açıktır; diğerleri kilit ikonuyla ve
  `disabled = true` olarak çizilir (`_populate_level_grid()`).
- `completed_levels[idx] = {"stars", "time_sec"}`; tekrar oynanınca en iyi yıldız ve en iyi süre korunur.
- Eski seviyeyi tekrar çözmek ilerlemeyi atlatmaz, ancak kupa kazandırır (bkz. §6 ve §8).
- 120. seviyeden sonra "sonraki bölüm" düğmesi gizlenir (`_show_win_modal()`).

## 5. Günlük bölüm (Mevcut)

| Davranış | Ayrıntı |
|---|---|
| Seçim | `(gün × 7) % level_count` — ayın gününe göre deterministik, 7'şer atlayan indeks |
| Sınırlama | `min(daily_idx, unlocked_level_index)` — açılmamış seviyeye atlamaz |
| Giriş | `start_level(idx, "daily")`; telemetride `level_start.source = "daily"` |
| Ödül farkı | Yok: normal `complete_level()` akışı; reklam aralığı sayacı da artar |
| Tekrar | Aynı gün aynı seviye; tamamlanmışsa tekrar oynanabilir |

**Açık:** Ayrı ödül, seri (streak) sayacı veya "bugün oynandı" işareti yoktur. `streak_days` kaydedilir ve
gösterilir ama hiçbir kod onu artırmaz; değer her zaman `1` kalır (`loc.gd` metni "1 Gün" olarak görünür).

## 6. Lig simülasyonu (Mevcut)

`GameState.league_rivals` yedi yapay rakipten oluşur ve kayda yazılır: Zıpzıp Efe 210, Havuç Avcısı 185,
Tarçın Kulak 160, Kartopu 135, Benekli Pati 110, Minik Yonca 95, Pofuduk 70 kupa.

| Kural | Değer / kod |
|---|---|
| Oyuncu başlangıç kupası | 120 (`player_trophies`) |
| Seviye başına kupa | `10 + stars × 5` → 1 yıldız 15, 2 yıldız 20, 3 yıldız 25 |
| Rakip ilerlemesi | Her `complete_level()` çağrısında rakip başına %45 olasılıkla +3…12 kupa |
| Sıralama | Oyuncu + 7 rakip, kupaya göre azalan; oyuncu satırı yeşil (`get_leaderboard()`) |
| Sayfa | Yalnızca okuma; ödül, terfi/düşme veya sezon yok |

**Açık:** Lig sosyal değil, yerel simülasyondur; rakip isimleri sabit, sunucu yok. Kupa tekrar oynanan
seviyelerden de arttığı için birikim sınırsızdır (çiftçilik).

## 7. İçerik üretim hattı kuralı

Yeni seviye eklemek için **zorunlu** kabul kapısı:

| # | Kural | Doğrulama |
|---|---|---|
| 1 | `regionMap` N×N, kimlikler tam `0…N-1` | Yapısal kontrol |
| 2 | `solution` N çift; her satır, sütun ve bölge tam bir kez | Permütasyon kontrolü |
| 3 | Çözümde hiçbir iki tavşan yatay/dikey/çapraz komşu değil | Mesafe kontrolü |
| 4 | `prefillPositions` çözümün alt kümesi | Alt küme kontrolü |
| 5 | İpucu motoru seviyeyi sıfır hatayla bitirebiliyor | `HintSolver` ile tam koşu |
| 6 | Seviye gerçek oyuncu girdisiyle çözülebiliyor | Elle/otomasyon testi |

Bugün 1–4 arası kontroller 120/120 seviyede sağlanıyor; 5 ipucu motoruyla (sıfır hatayla), 6 gerçek oyuncu
girdisiyle 120/120 doğrulandı. Ancak **repoda otomatik doğrulayıcı betik yoktur** (`tools/` yalnızca
`bq_load.py` içeriyor); her içerik güncellemesinde kontrol tekrar elle yapılmalı. Planlanan:
`tools/validate_levels.py` benzeri bir kapı ([`10_PRODUCTION_BACKLOG.md`](10_PRODUCTION_BACKLOG.md)).

`steps` üretim artefaktıdır ve oyun tarafından okunmaz; 120 seviyenin 90'ında `steps != size`. Alanı "minimum
mantık adımı" olarak kullanmak için önce tanımı sabitleyip kodu bağlamak gerekir (Açık).

## 8. Açık maddeler

| Madde | Etki | Öneri |
|---|---|---|
| `rank` ve `steps` okunmuyor | Veri var, kullanılmıyor | Gösterime bağla ya da şemadan çıkar |
| Günlük seri yok | "1 Gün" sabit görünüyor | `streak_days` hesabını yaz veya pill'i kaldır |
| Kupa çiftçiliği | Lig anlamsızlaşır | Tekrar çözümde kupayı kaldır/azalt |
| İçerik 120 seviyede sabit | Uzun vadeli tutundurma sınırlı | İçerik hattı + doğrulayıcı |
| Kademe sırası eğrisi | 36. seviyede ani zorluk | Kademeleri yeniden sırala |

## 9. İlgili belgeler

- Oynanış kuralları ve ipucu hattı: [`02_CORE_GAMEPLAY.md`](02_CORE_GAMEPLAY.md)
- Ödül ekonomisi ve reklam aralıkları: [`05_ECONOMY_MONETIZATION.md`](05_ECONOMY_MONETIZATION.md)
- Ürün hedefleri: [`01_PRODUCT_STRATEGY.md`](01_PRODUCT_STRATEGY.md), [`13_QA_ACCEPTANCE.md`](13_QA_ACCEPTANCE.md)
- Seviye olayları: [`../analytics/EVENTS.md`](../analytics/EVENTS.md)
