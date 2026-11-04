# Bundoku ads integration (AdMob + UMP)

> **Özet (TR):** Reklamlar Poing Studios AdMob eklentisi (v5.1.0) ile çalışır. Açılışta UMP onay akışı,
> ardından `MobileAds.initialize()`, interstitial + rewarded ön yükleme ve alta sabitlenen uyarlanabilir
> (adaptive) banner yüklenir. Banner'ın yüksekliği `banner_loaded(height_px)` ile bildirilir ve arayüzün
> alt boşluğu bu kadar artırılır; tam ekran reklamlar sırasında banner gizlenir. Reklam hazır değilse
> (masaüstü, editör, fill yok) oyun eskisi gibi simüle edilmiş reklam modalını gösterir. Test kimlikleri
> yayına çıkmadan değiştirilmelidir; ayrıntılar aşağıdaki yayın kontrol listesinde.

Source of truth: [`scripts/ads/ad_manager.gd`](../../scripts/ads/ad_manager.gd) (autoload `Ads`),
[`scripts/ui/main_controller.gd`](../../scripts/ui/main_controller.gd) (offer/fallback) and
[`assets/ads/ads_config.json`](../../assets/ads/ads_config.json) (ad units).

## 1. Architecture

```
main_controller._ready()
  └─ Ads.start()
       ├─ OS is not Android/iOS, or Engine.has_singleton("PoingGodotAdMob") == false
       │    → supported = false, return (controller uses the simulated modal)
       └─ UserMessagingPlatform.consent_information.update(ConsentRequestParameters)
            ├─ status REQUIRED + form available → ConsentForm.show()
            └─ otherwise → _finish_consent()
                 ├─ Telemetry.set_consent(analytics_state, "granted" | "denied")
                 ├─ consent_finished(can_request_ads)
                 └─ MobileAds.initialize(OnInitializationCompleteListener)
                      ├─ preload interstitial + rewarded (retry 15s / 30s / 60s, max 3)
                      └─ load adaptive bottom banner (retry 30s, max 3)
                           └─ banner_loaded(height_px) → controller reserves bottom space
```

Offer flow (`_show_ad_modal`):

1. `ad_offered` is tracked exactly once.
2. Placements `free_hint`, `free_carrot`, `revive` call `Ads.show_rewarded(placement)`;
   `level_break` calls `Ads.show_interstitial(placement)`.
3. `true` → real ad: `ad_shown` (`simulated=0`), screen `ad`, no simulated modal; the level timer is
   paused through `_ad_is_active`.
4. `false` → unchanged simulated modal (3 s countdown, `ad_shown` `simulated=1`, ad-free UX intact).
5. `Ads.ad_closed` → `ad_closed` (`simulated=0`, `watched_sec`) once, then the pending completion runs.
   Rewarded completions run **only** when `Ads.ad_rewarded` fired (`_pending_ad_reward_earned`).

Every loaded ad gets a `FullScreenContentCallback` and an `on_ad_paid` handler. `on_ad_paid` builds the
ILARE row (`ad_platform`, `ad_source`, `ad_format`, `ad_unit_name`, `currency`, `value`, `precision`,
`placement`) and:

* always emits the local `ad_impression` signal,
* calls `Telemetry.track("ad_impression", …)` **only** when `Telemetry.analytics_allowed()` is true.

The simulated modal never emits `ad_impression` and never sets revenue fields.

## 2. Test IDs (current defaults)

| Item | Value | Where |
|---|---|---|
| Android App ID | `ca-app-pub-3940256099942544~3347511713` | `project.godot` → `[admob] general/android/app_id` |
| Interstitial unit | `ca-app-pub-3940256099942544/1033173712` | `assets/ads/ads_config.json` |
| Rewarded unit | `ca-app-pub-3940256099942544/5224354917` | `assets/ads/ads_config.json` |
| Banner unit (adaptive) | `ca-app-pub-3940256099942544/9214589741` | `assets/ads/ads_config.json` |

These are Google's public test units. They must never ship in a production build.

## 3. Wiring real IDs

1. **App ID** — AdMob UI → *App settings* → App ID. Put it in `project.godot`:
   ```ini
   [admob]
   general/android/enabled=true
   general/android/app_id="ca-app-pub-XXXXXXXX~YYYYYYYY"
   general/ios/enabled=false
   mediation/meta=true
   ```
   (Or edit it in **Project Settings → General → Admob**.) The App ID is *not* read from the JSON.
2. **Ad units** — create one interstitial, one rewarded and one banner unit in AdMob, then update:
   ```json
   {
     "test_mode": false,
     "android_interstitial_unit": "ca-app-pub-XXXXXXXX/1111111111",
     "android_rewarded_unit": "ca-app-pub-XXXXXXXX/2222222222",
     "android_banner_unit": "ca-app-pub-XXXXXXXX/3333333333",
     "enable_banner": true,
     "preload": true
   }
   ```
   `test_mode` is informational for the team; real revenue still requires real unit IDs. Set
   `enable_banner` to `false` to ship without a banner (the controller then keeps its normal margins).
3. **Export filters** — `assets/ads/ads_config.json` is a plain JSON resource. If the export preset filters
   it out, the game silently falls back to the hard-coded test units in `ad_manager.gd`. Confirm the JSON is
   inside the exported APK (e.g. `unzip -l build/*.apk | grep ads_config`).

## 4. Meta bidding through AdMob mediation

1. `project.godot` already has `admob/mediation/meta=true`, which makes the addon inject the Meta
   (Audience Network) adapter during the Gradle build.
2. In AdMob create a **mediation group** for each format, add an **AdMob** ad source and a **Meta Audience
   Network** ad source (bidding), and attach a **Meta placement ID** from Meta Audience Network.
3. Host `app-ads.txt` at the **root of the developer website domain** (the domain listed on the Play Store,
   `https://<domain>/app-ads.txt`). It must contain Google's and Meta's authorized seller lines for this
   App ID; AdMob's *app-ads.txt* page generates the block.
4. `ad_source` in `ad_impression` comes from `ResponseInfo.loaded_adapter_response_info.ad_source_name`,
   so mediation wins are distinguishable per network.

Bidding is asynchronous: the SDK decides the winner. No app-side waterfall configuration exists.

## 5. Impression-level revenue (ILARE)

1. AdMob UI → *Account settings* (or *App settings* for the app) → enable **Impression-level ad revenue**.
   Without it, `on_ad_paid` still fires but `value_micros` is 0 and only `precision=UNKNOWN` is reported.
2. The app reports `value = value_micros / 1_000_000.0` as a float plus currency and precision. Rows land
   locally as `ad_impression` and are only written when analytics consent is granted (`held` rows are
   buffered by Telemetry, `denied` rows are dropped).
3. Revenue totals should come from AdMob's own reporting for billing truth; the telemetry row is for
   per-placement/per-network attribution, not accounting.

## 6. Banner ads (adaptive, bottom)

`Ads` loads one persistent, non-fullscreen banner after `MobileAds.initialize()`:

* **Unit / size** — `android_banner_unit` from `assets/ads/ads_config.json` (default: Google's
  adaptive banner test unit), sized with
  `AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(AdSize.FULL_WIDTH)` and anchored to
  `AdPosition.BOTTOM`. When the SDK returns a zero-width size, `AdSize.BANNER` (320×50) is used.
* **Load gate** — `enable_banner` (default `true`), `preload`, `Ads.supported`, consent
  (`can_request_ads()`) and `GameState.no_ads_purchased == false`. On desktop/editor `Ads.supported`
  is `false`, so no banner view is ever created and the UI keeps its normal margins.
* **Layout reservation** — on `on_ad_loaded` the banner is shown and `Ads` converts
  `AdView.get_height_in_pixels()` from device pixels to viewport pixels
  (`px * viewport_h / window_h`), then emits `banner_loaded(height_px)`. `main_controller.gd` stores
  it in `_banner_inset_px` and adds it to the bottom margin of `_home_margin` and `_game_margin`
  inside `_apply_safe_area_margins()`, so neither screen is ever covered. `banner_loaded(0)` is
  emitted when the banner is destroyed, releasing the space again.
* **Full-screen ads** — `show_interstitial()` / `show_rewarded()` call `hide_banner()` first, so the
  banner never sits under a full-screen creative; `_on_ad_dismissed` / `_on_ad_failed_to_show` call
  `show_banner()` again when the banner is loaded.
* **No-ads purchase** — `GameState.no_ads_purchased` skips the load entirely.
* **No fill / errors** — `banner_failed(message)` is emitted, the view is destroyed, and the load is
  retried at most 3 times, 30 s apart. Only one `banner_failed` telemetry row is written per run.
* **Consent revoked** — closing the privacy options form with ads no longer permitted calls
  `destroy_banner()`, releasing the reserved space.

Public banner API on `Ads`:

| Member | Purpose |
|---|---|
| `banner_loaded(height_px)` | Reserved height in viewport px; `0` releases the space. |
| `banner_failed(message)` | Banner load failed (a retry is already scheduled). |
| `is_banner_loaded()` | `true` when a banner view is loaded. |
| `banner_height_px()` | Last reserved height (`0` when none). |
| `show_banner()` / `hide_banner()` | Visibility only; keeps the reservation. |
| `destroy_banner()` | Destroys the view and releases the reservation. |

## 7. Privacy options entry point

`_show_language_modal()` renders a **🔒 Privacy options** button above *Close*. It is
`visible = Ads.privacy_options_required()` (UMP `get_privacy_options_requirement_status() == REQUIRED`) and
calls `Ads.show_privacy_options()`. The button is English-only on purpose (no `Loc` keys); localize it once
the UMP form itself is localized. When the form closes, `privacy_options_closed` is emitted and the ad-signal
consent mirror is refreshed without writing a second `consent_changed` row.

## 8. No server-side verification (SSV)

Rewards are granted client-side: `Ads` reports `on_user_earned_reward` and the controller adds the booster
immediately. There is no SSV callback URL configured, so a modified client can claim rewards without watching
an ad. For a high-value economy, add a server endpoint, set
`RewardedAd.set_server_side_verification_options(...)` with user id + custom data, and grant rewards from the
server callback only.

## 9. Desktop / editor mock behavior

The addon returns mock plugins on non-mobile platforms. `Ads` deliberately **never** uses them for
analytics: `start()` returns early when `OS.get_name()` is not `Android`/`iOS`, or when
`Engine.has_singleton("PoingGodotAdMob")` is false. `Ads.is_supported()` is then `false`, `is_ready()` is
`false`, `show_*` returns `false`, and `main_controller` runs the simulated ad modal exactly as before.
Console warnings from the addon mock are expected and harmless.

## 10. Release checklist

- [ ] Replace `general/android/app_id` with the production App ID.
- [ ] Replace all three ad unit IDs in `assets/ads/ads_config.json` (interstitial, rewarded, banner);
      set `test_mode` to `false`.
- [ ] Keep `general/android/enabled=true` and Gradle build enabled in the Android export preset.
- [ ] Enable impression-level ad revenue in AdMob.
- [ ] Create mediation groups (AdMob + Meta bidding) and attach Meta placement IDs.
- [ ] Publish `app-ads.txt` at `https://<play-store-domain>/app-ads.txt`.
- [ ] Google Play **Data safety**: declare *Device or other IDs* (AD_ID), *App activity* (ads), and
      *Diagnostics*; confirm the AD_ID permission is present in the merged manifest.
- [ ] Verify the UMP form appears for a test EEA device (`"debug_eea": true` forces EEA geography via
      `ConsentDebugSettings` while testing).
- [ ] Verify `ad_impression` rows appear only with analytics consent and carry non-zero `value`.
- [ ] Verify the adaptive banner loads on Android, appears at the bottom, and the home/game layouts
      shrink by `height_px` (no overlap); confirm it disappears with `no_ads_purchased = true` and
      hides while an interstitial/rewarded ad is full-screen.
- [ ] Verify the simulated modal still works when ads are unavailable (airplane mode / no fill).
