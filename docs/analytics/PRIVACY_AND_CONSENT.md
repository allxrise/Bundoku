# Bundoku privacy and consent

> **Özet (TR):** Bundoku analitiği cihazda kalır. Kullanıcı kimliği, serbest metin ve reklam kimliği toplanmaz.
> Olaylar `user://telemetry/` altında günlük JSONL dosyalarına yazılır; EEA/UK/CH'de oyuncu kabul edene kadar
> yalnızca bellekte tutulur. Yayın öncesi ilk açılış rıza kartı ve Play veri güvenliği beyanı hâlâ gereklidir.

App: **Bundoku** (`com.bundoku.puzzle`), version **1.0.4**. Implementation: `scripts/core/telemetry.gd`.
Event contract: [EVENTS.md](EVENTS.md). Warehouse tooling: [BIGQUERY.md](BIGQUERY.md).

## What is collected

* Discrete gameplay events (level start/complete/fail/abandon, mistakes, bunny placements/removals, undo, draft,
  board clear) with numeric/string parameters such as level, size, tier, stars, seconds, mistake count.
* Booster usage counts, simulated ad offer/show/close, screen checkpoints, button taps (`ui_tap` with a button id).
* Settings changes (language, sound, first-tap mode, auto-cross, pattern).
* Session lifecycle (first open, session start/end, pause/resume) and a 60-second performance sample (fps, frame
  time, memory, object and node counts).
* Device context repeated on every row: app version, engine version, platform, OS version, device model,
  device "brand" (processor name), CPU count, GPU vendor/name, screen size, locale, in-game language,
  `is_mobile`, `is_debug`, `region_eea`.
* A random per-install `user_pseudo_id` (16 random bytes, hex) and a random per-session `session_id`. These are
  not linked to any account or advertising identifier.
* Consent state and user properties: `max_level`, `trophies`, `hints`, `carrots`, `no_ads`, `language`.

Parameters are limited: ≤ 25 per event, strings ≤ 100 characters, names ≤ 40 characters (`[a-z0-9_]`).

## What is never collected

* Name, nickname, email, phone, account id, or any user identifier.
* Free text, chat, file paths, screenshots, or receipts.
* Advertising id (GAID/IDFA), Android ID, or any device-stable identifier beyond the random install id.
* Precise location, contacts, installed-app list, or health data.
* Purchase amounts or payment data (reserved `iap_*` events will carry product id and price only, never a receipt).

## Where it is stored

On the device, inside the Godot user data directory:

```
user://telemetry/state.cfg              # identity, session counter, consent, user properties
user://telemetry/events-YYYYMMDD.jsonl  # today's rows, one JSON object per line
user://telemetry/archive-<stamp>.jsonl  # rotated files
```

Nothing is uploaded: `Telemetry.upload_url` is empty and `upload_pending()` is a no-op. A future sink will reuse
the same JSONL layout (see BIGQUERY.md).

## Retention and rotation

* The active file rotates at **2 MB** (`FILE_MAX_BYTES = 2 * 1024 * 1024`).
* The newest **7** archives are kept (`FILE_KEEP = 7`); older archives are deleted automatically.
* Daily files are named by UTC date, so a day boundary starts a new file even below 2 MB.
* `state.cfg` is small and holds no events.

## Consent states

`Telemetry.consent_state` is one of `unset`, `granted`, `held`, `denied`; ad-signal consent
(`ads_consent_state`) is independent: `unset`, `granted`, `denied`.

| Situation | Analytics | Behaviour |
|---|---|---|
| Outside EEA/UK/CH, no answer | `granted` | rows written to disk immediately |
| EEA/UK/CH (locale country), no answer | `held` | rows kept in memory only, **≤ 256**, oldest dropped; nothing written |
| Player grants analytics | `granted` | held rows are flushed to disk, then new rows are written |
| Player denies / withdraws | `denied` | new rows dropped; held rows are not promoted; existing files are not deleted automatically |
| Ad signals granted/denied | separate | controls personalized ads only; never gates analytics |

`set_consent(state, ad_signals)` persists the choice and emits `consent_changed`. Default is decided once per
install from the OS locale (`is_eea_region()`), never on every launch. A `denied` player still gets no rows even if
the game keeps calling `track()`.

## How to opt out locally (operator or tester)

1. In-game: the future privacy card calls `Telemetry.set_consent("denied")`.
2. Without UI (QA builds): call `Telemetry.set_consent("denied")` from the debug console, or edit
   `user://telemetry/state.cfg` and set `[consent] analytics="denied"`.
3. Hard stop: set `Telemetry.enabled = false` (session-scoped) or delete the whole `user://telemetry/` directory.

Deleting the directory removes the install identity, queued rows and user properties; the next launch creates a
new `user_pseudo_id`.

## Operator: export and delete the local queue

Export (desktop/Android via `adb`, iOS via the app container):

```bash
# Android (debug build, app files are visible)
adb shell run-as com.bundoku.puzzle ls files/telemetry
adb exec-out run-as com.bundoku.puzzle cat files/telemetry/events-20261104.jsonl > events-20261104.jsonl
```

On desktop the directory is the Godot user-data path (for example
`~/.local/share/godot/app_userdata/Bundoku/telemetry/`). Copy `events-*.jsonl` and `archive-*.jsonl`; then load
them with `tools/bq_load.py` (BIGQUERY.md).

Delete:

```bash
adb shell run-as com.bundoku.puzzle rm -rf files/telemetry
```

or delete the directory from the user data path. Deleting while the app is running may recreate files on the next
flush; stop the app first. Rows already loaded into BigQuery are unaffected: delete them there by
`user_pseudo_id`/date if a data-subject request requires it.

## Open items before release

* **First-run consent card.** The EEA/UK/CH hold path exists, but there is no in-game card asking the player yet,
  so those players' rows stay in memory and are lost at exit. The card must call `set_consent("granted"/"denied")`
  and offer the ad-signal choice; UMP (Google User Messaging Platform) integration is the planned supplier of the
  ad-signal answer.
* **Play Console data safety.** Declare the collected data types (app activity, app info and performance, device
  or other ids — the random install id), that data is not shared, and that it is encrypted in transit once a sink
  exists. Today no data leaves the device, which the declaration must reflect.
* **Privacy policy URL.** A public policy page (what is collected, retention, contact, deletion) is required for
  the store listing and must match this document.
* **Consent withdrawal must delete local rows** (or stop collection and purge). Decide the exact behaviour and
  implement it with the card; `set_consent("denied")` currently only stops new rows.
* **Data-subject requests.** With no backend, deletion requests are handled by deleting `user://telemetry/` and
  any loaded BigQuery rows for that `user_pseudo_id`.
