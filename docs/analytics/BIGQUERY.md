# Bundoku telemetry in BigQuery

> **Özet (TR):** Bundoku şu an sunucusuz çalışır: olaylar cihazda `user://telemetry/events-YYYYMMDD.jsonl`
> dosyalarına yazılır. Bu sayfa bu dosyaların BigQuery'ye nasıl yükleneceğini (`bq mk`, `bq load`,
> `tools/bq_load.py`), hazır görünümü ve kopyala-çalıştır sorguları içerir. Olay sözlüğü:
> [EVENTS.md](EVENTS.md). Rıza: [PRIVACY_AND_CONSENT.md](PRIVACY_AND_CONSENT.md).

Source of truth today is the **local device dump**, not a cloud pipeline. Nothing is uploaded by the app. An
operator copies the JSONL files off the device and loads them; there is no backfill until a real sink exists.
App: **Bundoku** (`com.bundoku.puzzle`), version **1.0.4**.

## 1. Naming and layout

| Item | Name |
|---|---|
| Google Cloud project | *your project* (replace `my-project`) |
| Dataset | `bundoku` |
| Table | `bundoku.telemetry_events` |
| Partitioning | Daily on `event_date` (`DATE` derived from `TIMESTAMP_MICROS(event_ts_us)`, UTC) |
| Clustering | `event_name` |
| Schema | [`assets/analytics/bigquery_schema.json`](../../assets/analytics/bigquery_schema.json) |

`event_date` is **not** written by the game. `tools/bq_load.py` adds it per row:

```python
datetime.fromtimestamp(event_ts_us / 1_000_000, tz=timezone.utc).strftime("%Y-%m-%d")
```

so the partition always matches the UTC day of `event_ts_us`, regardless of the device's local time zone.
One row per event; `params` and `user_properties` are BigQuery `JSON` columns.

## 2. Create the dataset

```bash
# Once per project. Pick a location and keep it (US or EU).
bq --location=US mk --dataset \
  --description "Bundoku local-first telemetry" \
  my-project:bundoku
```

## 3. Load a device dump

The device files are already newline-delimited JSON matching the schema except for `event_date`. Two options:

### Option A — `bq load` directly (no transformation)

`bq load` cannot derive `event_date`, and the partition column must exist in every row, so use the loader unless
your dumps already contain `event_date`.

### Option B — `tools/bq_load.py` (recommended)

```bash
python3 tools/bq_load.py \
  --project my-project \
  --dataset bundoku \
  --table telemetry_events \
  events-20261104.jsonl events-20261105.jsonl
```

The tool validates every line, derives `event_date`, writes a gzipped NDJSON temp file and runs:

```bash
bq load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --schema=assets/analytics/bigquery_schema.json \
  --time_partitioning_field=event_date \
  --clustering_fields=event_name \
  my-project:bundoku.telemetry_events \
  /tmp/bundoku-telemetry-XXXX.jsonl.gz
```

Flags: `--schema` (default `assets/analytics/bigquery_schema.json`), `--dry-run` (validate and print the command),
`--keep-temp` (keep the gzipped file). Exit codes: `2` usage/`bq` missing, `3` bad input row, `4` load failed.

### Raw `bq load` for archive files

If a dump already carries `event_date`, load it without the Python step:

```bash
bq load \
  --source_format=NEWLINE_DELIMITED_JSON \
  --schema=assets/analytics/bigquery_schema.json \
  --time_partitioning_field=event_date \
  --clustering_fields=event_name \
  my-project:bundoku.telemetry_events \
  events-20261104.jsonl
```

`bq load` accepts `.jsonl`, `.jsonl.gz` and `.ndjson` transparently; append is the default. Reloading the same file
**duplicates rows** — dedupe with `(user_pseudo_id, event_ts_us, event_name)` if a load is repeated, or export a
clean partition.

## 4. The flattened view

Most queries read `params` through `JSON_VALUE`/`SAFE_CAST`. Create this once per dataset:

```sql
CREATE OR REPLACE VIEW `my-project.bundoku.v_events` AS
SELECT
  event_date,
  event_name,
  event_ts_us,
  user_pseudo_id,
  session_id,
  session_number,
  screen,
  level,
  app_version,
  platform,
  os_version,
  device_model,
  locale,
  language,
  is_mobile,
  is_debug,
  region_eea,
  SAFE_CAST(JSON_VALUE(params.level) AS INT64)        AS p_level,
  SAFE_CAST(JSON_VALUE(params.size) AS INT64)         AS p_size,
  JSON_VALUE(params.tier)                              AS p_tier,
  JSON_VALUE(params.source)                            AS p_source,
  SAFE_CAST(JSON_VALUE(params.prefill) AS INT64)      AS p_prefill,
  SAFE_CAST(JSON_VALUE(params.unlocked) AS INT64)     AS p_unlocked,
  SAFE_CAST(JSON_VALUE(params.seconds) AS INT64)      AS p_seconds,
  SAFE_CAST(JSON_VALUE(params.mistakes) AS INT64)     AS p_mistakes,
  SAFE_CAST(JSON_VALUE(params.stars) AS INT64)        AS p_stars,
  SAFE_CAST(JSON_VALUE(params.trophies) AS INT64)     AS p_trophies,
  SAFE_CAST(JSON_VALUE(params.bonus_hint) AS INT64)   AS p_bonus_hint,
  SAFE_CAST(JSON_VALUE(params.bonus_carrot) AS INT64) AS p_bonus_carrot,
  SAFE_CAST(JSON_VALUE(params.hints_left) AS INT64)   AS p_hints_left,
  SAFE_CAST(JSON_VALUE(params.carrots_left) AS INT64) AS p_carrots_left,
  SAFE_CAST(JSON_VALUE(params.ad_pending) AS INT64)   AS p_ad_pending,
  JSON_VALUE(params.reason)                            AS p_reason,
  SAFE_CAST(JSON_VALUE(params.placed) AS INT64)       AS p_placed,
  SAFE_CAST(JSON_VALUE(params.lives_left) AS INT64)   AS p_lives_left,
  SAFE_CAST(JSON_VALUE(params.mistakes_total) AS INT64) AS p_mistakes_total,
  SAFE_CAST(JSON_VALUE(params.row) AS INT64)          AS p_row,
  SAFE_CAST(JSON_VALUE(params.col) AS INT64)          AS p_col,
  SAFE_CAST(JSON_VALUE(params.draft) AS INT64)        AS p_draft,
  SAFE_CAST(JSON_VALUE(params.remaining) AS INT64)    AS p_remaining,
  SAFE_CAST(JSON_VALUE(params.marks) AS INT64)        AS p_marks,
  JSON_VALUE(params.booster)                           AS p_booster,
  JSON_VALUE(params.hint_type)                         AS p_hint_type,
  JSON_VALUE(params.placement)                         AS p_placement,
  JSON_VALUE(params.format)                            AS p_format,
  SAFE_CAST(JSON_VALUE(params.simulated) AS INT64)    AS p_simulated,
  SAFE_CAST(JSON_VALUE(params.watched_sec) AS INT64)  AS p_watched_sec,
  JSON_VALUE(params.button)                            AS p_button,
  JSON_VALUE(params.setting)                           AS p_setting,
  SAFE_CAST(JSON_VALUE(params.value) AS INT64)        AS p_value,
  JSON_VALUE(params.from)                              AS p_from,
  JSON_VALUE(params.to)                                AS p_to,
  JSON_VALUE(params.analytics)                         AS p_analytics,
  JSON_VALUE(params.ad_signals)                        AS p_ad_signals,
  SAFE_CAST(JSON_VALUE(params.fps) AS INT64)          AS p_fps,
  SAFE_CAST(JSON_VALUE(params.frame_time_ms) AS INT64) AS p_frame_time_ms,
  SAFE_CAST(JSON_VALUE(params.events) AS INT64)       AS p_events,
  SAFE_CAST(JSON_VALUE(user_properties.max_level) AS INT64) AS up_max_level,
  SAFE_CAST(JSON_VALUE(user_properties.trophies) AS INT64)  AS up_trophies,
  SAFE_CAST(JSON_VALUE(user_properties.hints) AS INT64)     AS up_hints,
  SAFE_CAST(JSON_VALUE(user_properties.carrots) AS INT64)   AS up_carrots,
  SAFE_CAST(JSON_VALUE(user_properties.no_ads) AS INT64)    AS up_no_ads,
  JSON_VALUE(user_properties.language)                      AS up_language
FROM `my-project.bundoku.telemetry_events`;
```

## 5. Queries

All queries filter on `event_date` so BigQuery prunes partitions (cost control). Replace the date window; the
examples use the last 30 complete days.

```sql
-- reuse in every query
WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                    AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
```

### 5.1 DAU / WAU

```sql
WITH daily AS (
  SELECT event_date, COUNT(DISTINCT user_pseudo_id) AS dau
  FROM `my-project.bundoku.v_events`
  WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1
)
SELECT
  d.event_date,
  d.dau,
  (SELECT COUNT(DISTINCT w.user_pseudo_id)
   FROM `my-project.bundoku.v_events` w
   WHERE w.event_date BETWEEN DATE_SUB(d.event_date, INTERVAL 6 DAY) AND d.event_date) AS wau
FROM daily d
ORDER BY d.event_date;
```

### 5.2 Session length

```sql
SELECT
  APPROX_QUANTILES(p_seconds, 100)[OFFSET(50)] AS p50_sec,
  APPROX_QUANTILES(p_seconds, 100)[OFFSET(90)] AS p90_sec,
  APPROX_QUANTILES(p_seconds, 100)[OFFSET(95)] AS p95_sec,
  COUNT(*) AS sessions
FROM `my-project.bundoku.v_events`
WHERE event_name = 'session_end'
  AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                    AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);
```

`session_end` is missing for force-quits; for an unbiased view derive the span from `MIN/MAX(event_ts_us)` per
`session_id` instead.

### 5.3 Level funnel and clear rate

```sql
WITH lvl AS (
  SELECT
    p_level AS level,
    COUNTIF(event_name = 'level_start')    AS starts,
    COUNTIF(event_name = 'level_complete') AS clears,
    COUNTIF(event_name = 'level_fail')     AS fails,
    COUNTIF(event_name = 'level_abandon')  AS abandons,
    COUNT(DISTINCT IF(event_name = 'level_start', user_pseudo_id, NULL)) AS players
  FROM `my-project.bundoku.v_events`
  WHERE event_name IN ('level_start', 'level_complete', 'level_fail', 'level_abandon')
    AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1
)
SELECT
  level, players, starts, clears, fails, abandons,
  SAFE_DIVIDE(clears, starts)   AS clear_rate,
  SAFE_DIVIDE(abandons, starts) AS abandon_rate
FROM lvl
ORDER BY level;
```

### 5.4 Drop-off by `max_level`

Snapshot user properties at each player's latest row.

```sql
WITH latest AS (
  SELECT
    user_pseudo_id,
    MAX_BY(up_max_level, event_ts_us) AS max_level
  FROM `my-project.bundoku.v_events`
  WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1
)
SELECT
  max_level,
  COUNT(*) AS players,
  SAFE_DIVIDE(COUNT(*), SUM(COUNT(*)) OVER ()) AS share
FROM latest
WHERE max_level IS NOT NULL
GROUP BY 1
ORDER BY 1;
```

Use the cumulative complement (`share` of players whose `max_level` is below N) to read drop-off; the histogram
itself is what players' progress looks like at the end of the window.

### 5.5 Hint / carrot usage

```sql
SELECT
  p_booster AS booster,
  COUNT(*) AS uses,
  COUNT(DISTINCT user_pseudo_id) AS players,
  SAFE_DIVIDE(COUNT(*), COUNT(DISTINCT user_pseudo_id)) AS uses_per_player
FROM `my-project.bundoku.v_events`
WHERE event_name = 'booster_used'
  AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                    AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
GROUP BY 1
ORDER BY uses DESC;
```

### 5.6 Draft usage vs clear rate

```sql
WITH s AS (
  SELECT
    session_id,
    COUNTIF(event_name = 'draft_applied')  AS draft_applied,
    COUNTIF(event_name = 'draft_cancelled') AS draft_cancelled,
    COUNTIF(event_name = 'level_start')    AS starts,
    COUNTIF(event_name = 'level_complete') AS clears
  FROM `my-project.bundoku.v_events`
  WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1
)
SELECT
  IF(draft_applied > 0, 'used_draft', 'no_draft') AS grp,
  COUNT(*) AS sessions,
  SUM(starts) AS starts,
  SUM(clears) AS clears,
  SAFE_DIVIDE(SUM(clears), SUM(starts)) AS clear_rate,
  SUM(draft_applied) AS draft_applied_events,
  SUM(draft_cancelled) AS draft_cancelled_events
FROM s
GROUP BY 1;
```

### 5.7 Top buttons per screen

```sql
SELECT screen, p_button AS button, taps, players
FROM (
  SELECT
    screen,
    p_button,
    COUNT(*) AS taps,
    COUNT(DISTINCT user_pseudo_id) AS players,
    ROW_NUMBER() OVER (PARTITION BY screen ORDER BY COUNT(*) DESC) AS rn
  FROM `my-project.bundoku.v_events`
  WHERE event_name = 'ui_tap'
    AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1, 2
)
WHERE rn <= 10
ORDER BY screen, taps DESC;
```

Join with `screen_checkpoint` counts to read tap-through per screen (shown vs tapped).

### 5.8 Ad offer → show → close funnel

```sql
SELECT
  p_placement AS placement,
  COUNTIF(event_name = 'ad_offered') AS offered,
  COUNTIF(event_name = 'ad_shown')   AS shown,
  COUNTIF(event_name = 'ad_closed')  AS closed,
  SAFE_DIVIDE(COUNTIF(event_name = 'ad_shown'), COUNTIF(event_name = 'ad_offered')) AS show_rate,
  SAFE_DIVIDE(COUNTIF(event_name = 'ad_closed'), COUNTIF(event_name = 'ad_shown')) AS close_rate,
  AVG(IF(event_name = 'ad_closed', p_watched_sec, NULL)) AS avg_watched_sec
FROM `my-project.bundoku.v_events`
WHERE event_name IN ('ad_offered', 'ad_shown', 'ad_closed')
  AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                    AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
GROUP BY 1
ORDER BY offered DESC;
```

### 5.9 Reserved: ad revenue from `ad_impression`

`ad_impression` is reserved and not emitted yet (EVENTS.md). This query returns zero rows until an ad SDK writes
`p_placement`, `revenue_micros` and `currency`; it is guarded by `event_name` so it can live in a dashboard now.

```sql
SELECT
  event_date,
  SAFE_CAST(JSON_VALUE(params.revenue_micros) AS INT64) / 1e6 AS revenue_usd,
  JSON_VALUE(params.network) AS network,
  JSON_VALUE(params.currency) AS currency
FROM `my-project.bundoku.telemetry_events`
WHERE event_name = 'ad_impression'
  AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY);
```

### 5.10 Retention D1 / D7 / D30

Cohort = first day seen. Only cohorts old enough to observe the window are meaningful; filter `install_date` at
least 1/7/30 days back.

```sql
WITH first_seen AS (
  SELECT user_pseudo_id, MIN(event_date) AS install_date
  FROM `my-project.bundoku.telemetry_events`
  WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
  GROUP BY 1
),
activity AS (
  SELECT DISTINCT user_pseudo_id, event_date
  FROM `my-project.bundoku.telemetry_events`
  WHERE event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 60 DAY)
                      AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
)
SELECT
  f.install_date,
  COUNT(DISTINCT f.user_pseudo_id) AS installs,
  COUNT(DISTINCT a1.user_pseudo_id) AS d1,
  COUNT(DISTINCT a7.user_pseudo_id) AS d7,
  COUNT(DISTINCT a30.user_pseudo_id) AS d30,
  SAFE_DIVIDE(COUNT(DISTINCT a1.user_pseudo_id), COUNT(DISTINCT f.user_pseudo_id))  AS d1_rate,
  SAFE_DIVIDE(COUNT(DISTINCT a7.user_pseudo_id), COUNT(DISTINCT f.user_pseudo_id))  AS d7_rate,
  SAFE_DIVIDE(COUNT(DISTINCT a30.user_pseudo_id), COUNT(DISTINCT f.user_pseudo_id)) AS d30_rate
FROM first_seen f
LEFT JOIN activity a1  ON a1.user_pseudo_id  = f.user_pseudo_id AND a1.event_date  = DATE_ADD(f.install_date, INTERVAL 1 DAY)
LEFT JOIN activity a7  ON a7.user_pseudo_id  = f.user_pseudo_id AND a7.event_date  = DATE_ADD(f.install_date, INTERVAL 7 DAY)
LEFT JOIN activity a30 ON a30.user_pseudo_id = f.user_pseudo_id AND a30.event_date = DATE_ADD(f.install_date, INTERVAL 30 DAY)
GROUP BY 1
ORDER BY 1;
```

A `first_open` row is the cleaner install signal once Cloud saves exist; today the first row of an install is the
install day.

### 5.11 Performance: p50 / p95 fps

```sql
SELECT
  event_date,
  COUNT(*) AS samples,
  APPROX_QUANTILES(p_fps, 100)[OFFSET(50)] AS p50_fps,
  APPROX_QUANTILES(p_fps, 100)[OFFSET(95)] AS p95_fps,
  APPROX_QUANTILES(p_frame_time_ms, 100)[OFFSET(95)] AS p95_frame_time_ms
FROM `my-project.bundoku.v_events`
WHERE event_name = 'performance_sample'
  AND event_date BETWEEN DATE_SUB(CURRENT_DATE(), INTERVAL 30 DAY)
                    AND DATE_SUB(CURRENT_DATE(), INTERVAL 1 DAY)
GROUP BY 1
ORDER BY 1;
```

`p95_fps` is the good tail; the bad tail is `APPROX_QUANTILES(p_fps, 100)[OFFSET(5)]`.

## 6. Operational notes

* **No backfill.** There is no sink and no historical cloud data; history begins the day the first dump is loaded.
  Local files remain the source of truth until an HTTP sink (`Telemetry.upload_pending()`) is provisioned.
* **Consent.** Only rows the device was allowed to write exist. Held rows that never got consent are absent by
  design; never infer "no activity" from a missing player in EEA/UK/CH.
* **Cost control.** Every query filters `event_date`; keep windows short. Prefer `v_events` over the raw table so
  `SAFE_CAST` and JSON paths stay in one place. Materialise daily aggregates with a scheduled query if dashboards
  grow.
* **Duplicates.** Reloading a dump appends duplicates. Dedupe by `(user_pseudo_id, event_ts_us, event_name,
  session_id)` when merging dumps, or use `SELECT DISTINCT` in exploratory queries.
* **Debug traffic.** `is_debug = 1` marks editor/debug builds. Exclude it for product metrics:
  `AND is_debug = 0`.
* `event_date` is UTC; `CREATE TABLE ... PARTITION BY event_date` is what `bq load` builds from
  `--time_partitioning_field=event_date`. If you create the table by hand, use
  `PARTITION BY DATE(TIMESTAMP_MICROS(event_ts_us))` and load with `event_date` present.
