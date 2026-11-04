# Bundoku analytics event dictionary

> **Özet (TR):** Bu sayfa Bundoku'nun hangi olayı, hangi parametrelerle, hangi koddan gönderdiğini tanımlar.
> Tüm satırlar tek bir rıza kapısından geçer ve cihazda `user://telemetry/events-YYYYMMDD.jsonl` dosyasına yazılır.
> Kullanıcı kimliği, serbest metin, dosya yolu veya reklam kimliği gönderilmez. Depo tarafı ve hazır sorgular:
> [BIGQUERY.md](BIGQUERY.md). Rıza ayrıntıları: [PRIVACY_AND_CONSENT.md](PRIVACY_AND_CONSENT.md).

App: **Bundoku** (`com.bundoku.puzzle`), version **1.0.4**, Godot 4.4, telemetry schema version **1**.
Autoload: `Telemetry` (`scripts/core/telemetry.gd`). There is no network sink yet: rows accumulate locally with a
future BigQuery load path (see BIGQUERY.md).

## Pipeline

```mermaid
flowchart LR
    A["Game call sites<br/>game_state / board_view / main_controller"] --> B["Telemetry.track(name, params)"]
    B --> C{"Consent gate<br/>consent_state"}
    C -->|granted| D["user://telemetry/events-YYYYMMDD.jsonl"]
    C -->|held (EEA/UK/CH, no answer)| E["Memory ring buffer<br/>max 256 rows"]
    C -->|denied| F["Dropped (never written)"]
    E -->|set_consent granted| D
    D --> G["tools/bq_load.py<br/>+ event_date"]
    G --> H["BigQuery<br/>bundoku.telemetry_events<br/>(future)"]
```

* Every event is one JSON object per line. `params` and `user_properties` are nested objects.
* No user id: `user_pseudo_id` is 16 random bytes generated on first launch. No free text, file path, nickname,
  email, receipt or advertising id is ever logged.
* `set_screen()` and `set_level_context()` mutate row-level context; the same values are repeated on every row so
  warehouse joins do not depend on ordering.
* Automatic events (`session_*`, `first_open`, `app_pause`, `app_resume`, `performance_sample`, `ui_tap`,
  `screen_checkpoint`, `consent_changed`) are emitted by the autoload itself; the rest come from game call sites.

## Consent policy

`Telemetry._decide_initial_consent()` decides once per install; `set_consent()` changes it later and emits
`consent_changed`.

| Region / state | Analytics | Where rows go | Ad signals |
|---|---|---|---|
| Outside EEA/UK/CH, not answered | **on** (`granted`) | written immediately | `unset` (UMP integration later) |
| EEA/UK/CH, not answered | **held** | kept in memory, **max 256 rows**, oldest dropped | `unset` |
| Player opts in | **on** (`granted`) | held rows flushed to disk, new rows written | separate answer (`ad_signals`) |
| Player opts out / withdraws | **denied** | nothing written or sent; held rows are not promoted | `denied` |
| Ads consent | independent of analytics | n/a | `granted` / `denied` / `unset`; `ad_personalization_allowed()` |

`region_eea` (0/1) and the in-game `language` are repeated on every row. Ad-signal consent never gates analytics
rows and analytics consent never enables personalized ads. Analytics is on by default outside the EEA/UK/CH; the
future UMP/privacy card owns the in-region ask.

## Row envelope

One row per event. Field types match `assets/analytics/bigquery_schema.json`.

| Field | Type | Meaning |
|---|---|---|
| `schema` | INTEGER | Telemetry schema version (1). |
| `event_name` | STRING | Sanitized name, `[a-z0-9_]{1,40}`. |
| `event_ts_us` | INTEGER | Microseconds since epoch (UTC). |
| `event_date` | DATE | **Not emitted by the game.** Derived by `tools/bq_load.py` from `event_ts_us` (UTC); partition column. |
| `user_pseudo_id` | STRING | Random install id (hex, 32 chars). |
| `session_id` | STRING | Random session id. |
| `session_number` | INTEGER | Lifetime session counter, starts at 1. |
| `screen` | STRING | `boot`, `home`, `game`, `result`, `ad`, `out_of_lives`, `league`, `language`. |
| `level` | INTEGER | `level_context`, 1-based; 0 when no level is active. |
| `params` | JSON | Event-specific object (tables below). |
| `user_properties` | JSON | Latest user properties (see below). |
| `app_version` | STRING | `application/config/version` (1.0.4). |
| `engine_version` | STRING | Godot version string. |
| `platform` | STRING | `OS.get_name()`. |
| `os_version` | STRING | OS version. |
| `device_model` | STRING | Device model. |
| `device_brand` | STRING | Processor name as reported by the OS. |
| `cpu_count` | INTEGER | Logical CPUs. |
| `gpu_vendor` | STRING | GPU vendor. |
| `gpu_name` | STRING | GPU name. |
| `screen_w`, `screen_h` | INTEGER | Screen pixels. |
| `locale` | STRING | OS locale (`tr_TR`). |
| `language` | STRING | In-game language code. |
| `is_mobile` | INTEGER | 0/1. |
| `is_debug` | INTEGER | 0/1. |
| `region_eea` | INTEGER | 0/1, EEA/UK/CH locale. |

Booleans in `params` are converted to `1`/`0` by the autoload. Floats are rounded to 4 decimals. String values are
truncated at 100 characters; at most 25 params per event.

## User properties

Repeated in `user_properties` on every row and persisted in `user://telemetry/state.cfg`.

| Property | Type | Set by |
|---|---|---|
| `max_level` | INTEGER | `game_state.complete_level()` = `unlocked_level_index + 1`. |
| `trophies` | INTEGER | `game_state.complete_level()` = `player_trophies`. |
| `hints` | INTEGER | `game_state.complete_level()` = `hints_count`. |
| `carrots` | INTEGER | `game_state.complete_level()` = `carrots_count`. |
| `no_ads` | INTEGER | `game_state.complete_level()` = `int(no_ads_purchased)`. |
| `language` | STRING | `game_state.set_language()` = active language code. |

## Session events

Emitted by the autoload; no call-site changes.

| Event | When | Params | Call site |
|---|---|---|---|
| `first_open` | First launch of this install (`session_number == 1`). | — | `telemetry.gd:_ready` |
| `session_start` | Every app start, before `first_open`. | `session_number` INT, `first_open` INT 0/1 | `telemetry.gd:_ready` |
| `session_end` | Window close request. | `seconds` INT, `events` INT, `screen` STRING | `telemetry.gd:_end_session` |
| `app_pause` | App backgrounded / focus lost. | `screen` STRING, `level` INT | `telemetry.gd:_notification` |
| `app_resume` | App foregrounded / focus gained. | `screen` STRING, `level` INT | `telemetry.gd:_notification` |
| `performance_sample` | Every 60 s of active time. | `fps` INT, `fps_avg_session` INT, `fps_min` INT, `fps_max` INT, `frame_time_ms` INT, `static_memory_mb` INT, `objects` INT, `nodes` INT | `telemetry.gd:_track_perf_sample` |

A force-quit may prevent `session_end`/`app_pause`; treat `session_start` as the session boundary.

## Run events

| Event | When | Params | Call site |
|---|---|---|---|
| `level_start` | A level begins loading, after `_active_level_idx` is set. | `level` INT 1-based, `size` INT, `tier` STRING (`easy`…`super_hard` raw tier), `source` STRING (`campaign`, `daily`, `next`, `retry`), `prefill` INT (prefilled bunnies in the level), `unlocked` INT (`unlocked_level_index + 1`) | `main_controller.gd:start_level` |
| `level_complete` | Board solved, after reward computation. | `level` INT, `size` INT, `tier` STRING, `seconds` INT, `mistakes` INT, `stars` INT 1–3, `trophies` INT (gain), `bonus_hint` INT, `bonus_carrot` INT, `hints_left` INT, `carrots_left` INT, `ad_pending` INT 0/1 | `game_state.gd:complete_level` |
| `level_unlocked` | Completion advanced `unlocked_level_index`. | `level` INT (newly unlocked, 1-based) | `game_state.gd:complete_level` |
| `level_fail` | Lives reached 0 and the out-of-lives modal opens. Once per open. | `level` INT, `reason` STRING (`out_of_lives`), `seconds` INT, `mistakes` INT | `main_controller.gd:_show_out_of_lives_modal` |
| `level_abandon` | Player leaves the game screen mid-level for home. | `level` INT, `seconds` INT, `mistakes` INT, `placed` INT | `main_controller.gd:_show_home_screen` |
| `mistake` | A wrong placement is registered (after `_mistakes++` and lives loss). | `level` INT, `reason` STRING (localized mistake text — see note), `lives_left` INT, `mistakes_total` INT | `main_controller.gd:_on_mistake_made` |

Note: `reason` on `mistake` is passed through from `BoardView` and can be a localized user-facing sentence. Only
the reason *kind* should be queried; do not treat it as a stable enum. (The call site should pass a short code when
the board signal provides one.)

`level_source` values: `campaign` (play button and level grid), `daily` (daily challenge button), `next` (win modal
Next), `retry` (out-of-lives restart). Default parameter is `campaign`.

## Board events

| Event | When | Params | Call site |
|---|---|---|---|
| `bunny_placed` | A bunny is placed by the player or an automatic cross; skipped for `SOURCE_PREFILL` setup. | `row` INT 1-based, `col` INT 1-based, `source` STRING (`manual`, `auto`, `prefill`, `draft`, `hint`), `draft` INT 0/1 | `board_view.gd:_place_bunny_at` |
| `bunny_removed` | A bunny is removed by a tap/drag/hint. | `row` INT 1-based, `col` INT 1-based | `board_view.gd:_remove_bunny_at` |
| `undo` | An undo snapshot was restored. | `level` INT, `remaining` INT (undo stack depth after pop) | `board_view.gd:undo_move` |
| `draft_applied` | Draft marks committed as manual placements. | `level` INT, `marks` INT (number of `SOURCE_DRAFT` cells committed) | `board_view.gd:apply_draft` |
| `draft_cancelled` | Draft mode exited without committing. | `level` INT | `board_view.gd:cancel_draft` |
| `board_clear` | Clear button resets the board. | `level` INT | `board_view.gd:clear_board` |

`SOURCE_HINT` placements also emit `bunny_placed`; they are distinguishable by `source = "hint"` and usually pair
with `booster_used`.

## Boosters

| Event | When | Params | Call site |
|---|---|---|---|
| `booster_used` | A hint or carrot booster was successfully applied. | `booster` STRING (`hint` / `carrot`), `hint_type` STRING (hint result type; empty for carrot), `hints_left` INT **or** `carrots_left` INT, `level` INT | `main_controller.gd:_on_hint_pressed`, `_on_carrot_pressed` |

When the count is 0 the click opens an ad offer instead and only the ad events fire (see below).

## Monetization and ads

| Event | When | Params | Call site |
|---|---|---|---|
| `ad_offered` | The simulated ad modal opens. | `placement` STRING, `format` STRING (`interstitial`), `level` INT | `main_controller.gd:_show_ad_modal` |
| `ad_shown` | Same open, immediately after `ad_offered` (no real SDK yet). | `placement` STRING, `format` STRING, `simulated` INT 1, `level` INT | `main_controller.gd:_show_ad_modal` |
| `ad_closed` | Close button pressed, before the modal hides. | `placement` STRING, `format` STRING, `watched_sec` INT (`_ad_countdown_total`); row-level `level` carries the level | `main_controller.gd:_show_ad_modal` close lambda |
| `ad_impression` | Real AdMob impression paid (ILARE callback); never for the simulated modal. | `ad_platform` STRING, `ad_source` STRING, `ad_format` STRING (`interstitial`, `rewarded` or `banner`), `ad_unit_name` STRING, `currency` STRING, `value` FLOAT, `precision` INT, `placement` STRING | `ad_manager.gd:_emit_impression` |
| `banner_loaded` | Adaptive bottom banner loaded and shown. | `height_px` INT (reserved viewport pixels), `ad_unit` STRING (unit id) | `ad_manager.gd:_on_banner_loaded` |
| `banner_failed` | Banner load failed; a 30 s retry is scheduled. At most one row per app run. | `attempt` INT (1-based attempt number) | `ad_manager.gd:_on_banner_failed` |

Placements: `free_hint`, `free_carrot`, `level_break` (post-win interstitial), `revive` (out-of-lives revive).
`ad_offered` / `ad_shown` rows are the simulated modal path (`simulated=1`); real SDK impressions arrive
only as `ad_impression`, whose `ad_format` distinguishes `interstitial`, `rewarded` and `banner`.

Reserved for the future ad/IAP integration (do **not** emit yet; add rows in the same envelope when wired):

| Reserved event | Intended params |
|---|---|
| `rewarded_complete` | `placement`, `level`, `reward` |
| `rewarded_incomplete` | `placement`, `level`, `watched_sec` |
| `iap_attempt` | `product_id`, `placement` |
| `iap_purchase` | `product_id`, `price_micros`, `currency` (no receipt, no user id) |
| `iap_failed` | `product_id`, `error_code` |

## UI

| Event | When | Params | Call site |
|---|---|---|---|
| `screen_checkpoint` | Visible screen changed (once per transition). | `screen` STRING, `level` INT | `telemetry.gd:set_screen` (called from `main_controller.gd` screen changes) |
| `ui_tap` | Any bound `Button` pressed; 300 ms same-button debounce. | `screen` STRING, `button` STRING (from `telemetry_id` meta or node name), `level` INT | `telemetry.gd:_on_button_pressed` |

Screen ids: `boot`, `home`, `game`, `result`, `ad`, `out_of_lives`, `league`, `language`.

Button ids set by `main_controller.gd` via `set_meta("telemetry_id", …)`: `play`, `daily`, `league`, `sound_toggle`,
`language`, `hint`, `carrot`, `undo`, `clear`, `draft`, `mode_toggle`, `auto_x_toggle`, `pattern_toggle`, `win_home`,
`win_next`, `revive`, `restart`, `ad_close`, `league_close`, `language_close`, and `level_<n>` for each level-grid
button.

## Settings and consent

| Event | When | Params | Call site |
|---|---|---|---|
| `language_changed` | A valid language code was applied. | `from` STRING (previous code), `to` STRING (new code) | `game_state.gd:set_language` |
| `setting_changed` | A toggle changed. | `setting` STRING (`sound`, `first_tap_mode`, `auto_cross`, `pattern`), `value` INT 0/1 | `main_controller.gd:_toggle_audio` and the three toggle lambdas in `_build_game_screen`/mode row |
| `consent_changed` | Consent state applied or changed, after saving state. | `analytics` STRING (`unset`/`granted`/`held`/`denied`), `ad_signals` STRING (`unset`/`granted`/`denied`) | `telemetry.gd:set_consent` |

`language_changed` also writes the `language` user property. `setting_changed` never includes free text.

## Naming and limits (GA4/Firebase compatible)

* Event names: `snake_case`, lowercase ASCII `[a-z0-9_]`, ≤ 40 characters. The autoload sanitizes instead of
  rejecting: uppercase → lowercase, spaces/`-`/`/`/`.` → `_`, other characters dropped, then truncated.
* Max **25** parameters per event; excess params are dropped in dictionary order.
* String param values are truncated at **100** characters; keys are sanitized the same way as event names.
* Booleans → 0/1 integer. Floats rounded to 4 decimals. `Vector2i` → `"x,y"` string; arrays → string.
* Event names are reserved by meaning: never reuse `level_complete` for a fail, etc. One action → one event, from
  one call site (e.g. `complete_level` is the only emitter of `level_complete`).
* No per-frame tracking. `performance_sample` is the only periodic event (every 60 s); everything else is a
  discrete user or system action.

## Mapping to the CookLab (Hungry Pan) analytics vocabulary

CookLab sends the same event names to Firebase/GA4; Bundoku currently writes the local JSONL only. The goal is a
shared warehouse vocabulary, not a shared schema.

| Bundoku event | CookLab / GA4-Firebase equivalent | Intentionally different |
|---|---|---|
| `level_start` | `level_start` | CookLab params: `level, world, mastery, difficulty`. Bundoku: `size, tier, source, prefill, unlocked`; no world/mastery. |
| `level_complete` | `level_complete` | CookLab has `pieces, coins, tier, difficulty`; Bundoku has `stars, trophies, bonus_*`, booster counts and `ad_pending`. No currency in the event. |
| `level_fail` | `level_fail` | Same name; Bundoku only fails on `out_of_lives` (no timer timeout yet). |
| `level_abandon` | `level_abandon` | Bundoku adds `placed`; fires only when leaving to home. |
| `ui_tap` | `ui_tap` | Same envelope (`screen, button, level`); CookLab binds a reporter per button, Bundoku binds on `node_added` + `telemetry_id` meta. |
| `screen_checkpoint` | `screen_checkpoint` | Same name/params; screen id set is Bundoku's eight screens (no shop/privacy ids yet). |
| `ad_shown` | `ad_shown` | Bundoku rows are simulated (`simulated=1`) until a real ad SDK is wired. |
| `ad_impression` | `ad_impression` (GA4 ad revenue) | Emitted for real SDK ads only, with ILRD `value`/`currency`/`precision` and `ad_source`; `ad_format` covers interstitial, rewarded and banner. |
| `booster_used` | `booster_used` | CookLab has shop boosters; Bundoku's are `hint`/`carrot` with inventory counts. |
| `iap_purchase` | `iap_purchase` | **Reserved.** CookLab deliberately sends no value; Bundoku will send product id + price only, never a receipt. |
| `currency_*` (GA4 e-commerce) | CookLab coins/stars economy | **Not used.** Bundoku has no soft currency purchase yet; do not emit `currency_*` params named `items`/`value` (GA4 reserved e-commerce keys). |

Additional Bundoku-only events (`first_open`, `session_start`, `session_end`, `app_pause`, `app_resume`,
`performance_sample`, `mistake`, `level_unlocked`, board/draft events, `ad_offered`, `ad_closed`,
`language_changed`, `setting_changed`, `consent_changed`) have no CookLab counterpart; CookLab relies on Firebase's
automatic session events and its own run settlement.
