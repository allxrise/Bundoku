extends Node

## Bundoku Telemetry — local-first, BigQuery-ready analytics.
##
## Mirrors the Hungry Pan (CookLab) analytics contract:
##   * GA4/Firebase event vocabulary and limits (name <= 40 chars, <= 25 params,
##     strings <= 100 chars) so rows can later be loaded into BigQuery verbatim.
##   * One consent gate for everything (analytics + ad signals).
##   * Local JSONL sink on the device: user://telemetry/events-*.jsonl.
##   * No user identifier is ever sent; user_pseudo_id is a random install id.
##
## There is no backend yet. Events accumulate locally; a future ingest can read
## the JSONL files (see docs/analytics/BIGQUERY.md) or an HTTP sink can be wired
## in upload_pending() once an endpoint exists.
##
## Usage:
##   Telemetry.track("level_start", {"level": 1, "size": 4, "tier": "easy"})
##   Telemetry.set_screen("game")
##   Telemetry.set_level_context(1)

signal event_logged(event_name: String)

const SCHEMA_VERSION := 1
const MAX_PARAMS := 25
const MAX_STRING_LEN := 100
const MAX_EVENT_NAME_LEN := 40
const HELD_LIMIT := 256
const FILE_MAX_BYTES := 2 * 1024 * 1024
const FILE_KEEP := 7
const PERF_SAMPLE_SEC := 60.0
const FLUSH_EVERY_SEC := 5.0

## Countries where analytics is held until the player opts in (EEA + UK + CH).
const EEA_COUNTRIES: Array[String] = [
	"AT", "BE", "BG", "HR", "CY", "CZ", "DK", "EE", "FI", "FR", "DE", "GR",
	"HU", "IE", "IT", "LV", "LT", "LU", "MT", "NL", "PL", "PT", "RO", "SK",
	"SI", "ES", "SE", "IS", "LI", "NO", "GB", "CH",
]

const STATE_PATH := "user://telemetry/state.cfg"
const QUEUE_DIR := "user://telemetry"

## Analytics gate: "unset" | "granted" | "held" | "denied".
var consent_state: String = "unset"
## Ad-signal gate (personalized ads / ad_storage): "unset" | "granted" | "denied".
var ads_consent_state: String = "unset"
var enabled: bool = true

## Optional HTTP sink. Empty means local-only.
var upload_url: String = ""
var upload_token: String = ""

var screen: String = "boot"
var level_context: int = 0
var user_properties: Dictionary = {}

var user_pseudo_id: String = ""
var session_id: String = ""
var session_number: int = 0
var session_started_unix: int = 0

var _common: Dictionary = {}
var _held: Array[String] = []
var _session_events: int = 0
var _perf_accum: float = 0.0
var _fps_sum: float = 0.0
var _fps_min: float = 9999.0
var _fps_max: float = 0.0
var _fps_samples: int = 0
var _flush_accum: float = 0.0
var _pending_flush: bool = false
var _started: bool = false
var _last_tap_id: String = ""
var _last_tap_ms: int = 0

func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(QUEUE_DIR)
	_load_state()
	_init_identity()
	_common = _build_common_props()
	_decide_initial_consent()
	session_id = _new_id()
	session_number += 1
	session_started_unix = int(Time.get_unix_time_from_system())
	_save_state()

	get_tree().node_added.connect(_on_node_added)
	_bind_existing_buttons(get_tree().root)

	track("session_start", {
		"session_number": session_number,
		"first_open": session_number == 1,
	})
	if session_number == 1:
		track("first_open", {})
	_started = true

func _process(delta: float) -> void:
	if not enabled or consent_state == "denied":
		return
	_perf_accum += delta
	if _perf_accum >= PERF_SAMPLE_SEC:
		_perf_accum = 0.0
		_track_perf_sample()

func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_WINDOW_FOCUS_OUT:
			if _started:
				track("app_pause", {"screen": screen, "level": level_context})
				_flush_now()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_WM_WINDOW_FOCUS_IN:
			if _started:
				track("app_resume", {"screen": screen, "level": level_context})
		NOTIFICATION_WM_CLOSE_REQUEST:
			if _started:
				_end_session()
		NOTIFICATION_PREDELETE:
			if _started:
				_flush_now()

func _end_session() -> void:
	var seconds := int(Time.get_unix_time_from_system()) - session_started_unix
	track("session_end", {"seconds": seconds, "events": _session_events, "screen": screen})
	_flush_now()

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

func track(event_name: String, params: Dictionary = {}) -> void:
	if not enabled:
		return
	if consent_state == "denied":
		return
	var name := _sanitize_name(event_name)
	if name == "":
		return
	var clean := _sanitize_params(params)
	_session_events += 1
	var row := _build_row(name, clean)
	var line := JSON.stringify(row)
	if consent_state == "held":
		_held.append(line)
		if _held.size() > HELD_LIMIT:
			_held.pop_front()
		event_logged.emit(name)
		return
	_append_line(line)
	event_logged.emit(name)

## Screen context used by screen_checkpoint / ui_tap rows.
func set_screen(new_screen: String) -> void:
	if new_screen == "" or new_screen == screen:
		return
	screen = new_screen
	track("screen_checkpoint", {"screen": screen, "level": level_context})

func set_level_context(level: int) -> void:
	level_context = level

## GA4-style user properties, repeated on every row for warehouse joins.
func set_user_property(key: String, value: Variant) -> void:
	var k := _sanitize_name(key)
	if k == "":
		return
	match typeof(value):
		TYPE_STRING, TYPE_STRING_NAME:
			user_properties[k] = str(value).substr(0, MAX_STRING_LEN)
		TYPE_BOOL:
			user_properties[k] = 1 if bool(value) else 0
		TYPE_INT:
			user_properties[k] = int(value)
		TYPE_FLOAT:
			user_properties[k] = snappedf(float(value), 0.0001)
		_:
			user_properties[k] = str(value).substr(0, MAX_STRING_LEN)
	_save_state()

func set_consent(state: String, ad_signals: String = "") -> void:
	if state in ["unset", "granted", "held", "denied"]:
		consent_state = state
	if ad_signals != "" and ad_signals in ["unset", "granted", "denied"]:
		ads_consent_state = ad_signals
	if consent_state == "granted":
		_flush_held()
	_save_state()
	_refresh_common()
	track("consent_changed", {
		"analytics": consent_state,
		"ad_signals": ads_consent_state,
	})

func is_eea_region() -> bool:
	var locale := OS.get_locale() # e.g. "en_US"
	var parts := locale.split("_")
	var country := ""
	if parts.size() > 1:
		country = parts[1].to_upper()
	elif parts.size() == 1 and parts[0].length() == 2:
		country = parts[0].to_upper()
	return country in EEA_COUNTRIES

func analytics_allowed() -> bool:
	return enabled and consent_state == "granted"

func ad_personalization_allowed() -> bool:
	return ads_consent_state == "granted"

func queue_dir() -> String:
	return QUEUE_DIR

func held_count() -> int:
	return _held.size()

func session_event_count() -> int:
	return _session_events

## Flushes buffered rows to disk. Safe to call from anywhere.
func flush() -> void:
	_pending_flush = true
	_flush_now()

## Uploads queued files when a backend is configured. Returns false if disabled.
func upload_pending() -> bool:
	if upload_url == "" or consent_state != "granted":
		return false
	# Backend not provisioned yet (no server API). See docs/analytics/BIGQUERY.md
	# for the expected JSONL layout and bq load command.
	push_warning("Telemetry.upload_pending(): no upload_url configured; keeping rows local.")
	return false

# ------------------------------------------------------------------------------
# Row construction
# ------------------------------------------------------------------------------

func _build_row(name: String, params: Dictionary) -> Dictionary:
	var row := {
		"schema": SCHEMA_VERSION,
		"event_name": name,
		"event_ts_us": int(Time.get_unix_time_from_system() * 1000000.0),
		"user_pseudo_id": user_pseudo_id,
		"session_id": session_id,
		"session_number": session_number,
		"screen": screen,
		"level": level_context,
		"params": params,
		"user_properties": user_properties.duplicate(),
	}
	row.merge(_common, false) # common props win
	return row

func _build_common_props() -> Dictionary:
	var vp := DisplayServer.screen_get_size()
	if vp.x <= 0 or vp.y <= 0:
		vp = DisplayServer.window_get_size()
	var info := Engine.get_version_info()
	var props := {
		"app_version": str(ProjectSettings.get_setting("application/config/version", "0.0.0")),
		"engine_version": str(info.get("string", "")),
		"platform": OS.get_name(),
		"os_version": OS.get_version(),
		"device_model": OS.get_model_name(),
		"device_brand": OS.get_processor_name(),
		"cpu_count": OS.get_processor_count(),
		"gpu_vendor": RenderingServer.get_video_adapter_vendor(),
		"gpu_name": RenderingServer.get_video_adapter_name(),
		"screen_w": vp.x,
		"screen_h": vp.y,
		"locale": OS.get_locale(),
		"language": Loc.current_lang,
		"is_mobile": OS.has_feature("mobile"),
		"is_debug": OS.is_debug_build(),
		"region_eea": is_eea_region(),
	}
	return props

func _refresh_common() -> void:
	_common = _build_common_props()

func _decide_initial_consent() -> void:
	if consent_state != "unset":
		return
	# Outside EEA/UK/CH analytics starts on (CookLab policy). Inside it is held
	# until the player opts in; rows stay on the device meanwhile.
	consent_state = "held" if is_eea_region() else "granted"

func _track_perf_sample() -> void:
	var fps := Engine.get_frames_per_second()
	_fps_sum += float(fps)
	_fps_min = minf(_fps_min, float(fps))
	_fps_max = maxf(_fps_max, float(fps))
	_fps_samples += 1
	track("performance_sample", {
		"fps": fps,
		"fps_avg_session": int(round(_fps_sum / float(maxi(1, _fps_samples)))),
		"fps_min": int(_fps_min),
		"fps_max": int(_fps_max),
		"frame_time_ms": int(round(1000.0 / float(maxi(1, fps)))),
		"static_memory_mb": int(Performance.get_monitor(Performance.MEMORY_STATIC) / 1048576.0),
		"objects": int(Performance.get_monitor(Performance.OBJECT_COUNT)),
		"nodes": int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)),
	})

# ------------------------------------------------------------------------------
# UI tap hook (CookLab's V2UiTapReporter equivalent)
# ------------------------------------------------------------------------------

func _on_node_added(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node)

func _bind_existing_buttons(node: Node) -> void:
	if node is BaseButton:
		_bind_button(node)
	for child in node.get_children():
		_bind_existing_buttons(child)

func _bind_button(button: BaseButton) -> void:
	if button.has_meta("telemetry_bound"):
		return
	button.set_meta("telemetry_bound", true)
	button.pressed.connect(func(): _on_button_pressed(button))

func _on_button_pressed(button: BaseButton) -> void:
	if not is_instance_valid(button):
		return
	var id := _button_id(button)
	var now := Time.get_ticks_msec()
	if id == _last_tap_id and (now - _last_tap_ms) < 300:
		return
	_last_tap_id = id
	_last_tap_ms = now
	track("ui_tap", {"screen": screen, "button": id, "level": level_context})

func _button_id(button: BaseButton) -> String:
	if button.has_meta("telemetry_id"):
		return _sanitize_name(str(button.get_meta("telemetry_id")))
	var raw := String(button.name)
	var generic := raw.to_lower() in ["button", "btn", "basebutton", "base_button", "control"]
	if generic and button.get_parent() != null:
		raw = String(button.get_parent().name)
	var id := raw.to_snake_case()
	for suffix in ["_button", "_btn", "_action"]:
		if id.ends_with(suffix):
			id = id.substr(0, id.length() - suffix.length())
			break
	id = _sanitize_name(id)
	if id == "" and button is Button:
		var text := (button as Button).text.strip_edges()
		if text != "":
			id = _sanitize_name(text.to_lower().replace(" ", "_"))
	return id

# ------------------------------------------------------------------------------
# Serialization / queue
# ------------------------------------------------------------------------------

func _sanitize_name(name: String) -> String:
	var out := ""
	for i in range(name.length()):
		var ch := name[i]
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_":
			out += ch
		elif ch >= "A" and ch <= "Z":
			out += ch.to_lower()
		elif ch == " " or ch == "-" or ch == "/" or ch == ".":
			out += "_"
	if out.length() > MAX_EVENT_NAME_LEN:
		out = out.substr(0, MAX_EVENT_NAME_LEN)
	return out

func _sanitize_params(params: Dictionary) -> Dictionary:
	var out := {}
	var count := 0
	for key in params.keys():
		if count >= MAX_PARAMS:
			break
		var k := _sanitize_name(str(key))
		if k == "":
			continue
		var v: Variant = params[key]
		var value: Variant
		match typeof(v):
			TYPE_STRING, TYPE_STRING_NAME:
				var s := str(v)
				value = s.substr(0, MAX_STRING_LEN)
			TYPE_BOOL:
				value = 1 if bool(v) else 0
			TYPE_INT:
				value = int(v)
			TYPE_FLOAT:
				value = snappedf(float(v), 0.0001)
			TYPE_VECTOR2I:
				var vi: Vector2i = v
				value = "%d,%d" % [vi.x, vi.y]
			TYPE_ARRAY:
				value = str(v).substr(0, MAX_STRING_LEN)
			_:
				value = str(v).substr(0, MAX_STRING_LEN)
		out[k] = value
		count += 1
	return out

func _current_file_path() -> String:
	var day := Time.get_date_string_from_system(true).replace("-", "")
	return "%s/events-%s.jsonl" % [QUEUE_DIR, day]

func _append_line(line: String) -> void:
	var path := _current_file_path()
	_rotate_if_needed(path)
	var f: FileAccess = null
	if FileAccess.file_exists(path):
		f = FileAccess.open(path, FileAccess.READ_WRITE)
		if f != null:
			f.seek_end()
	else:
		f = FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return
	f.store_line(line)
	f.close()

func _rotate_if_needed(path: String) -> void:
	if not FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return
	var size := f.get_length()
	f.close()
	if size >= FILE_MAX_BYTES:
		var stamp := Time.get_datetime_string_from_system(false, true).replace(":", "").replace("-", "").replace("T", "_")
		DirAccess.rename_absolute(path, "%s/archive-%s.jsonl" % [QUEUE_DIR, stamp])
		_prune_archives()

func _prune_archives() -> void:
	var dir := DirAccess.open(QUEUE_DIR)
	if dir == null:
		return
	var archives: Array[String] = []
	dir.list_dir_begin()
	var file := dir.get_next()
	while file != "":
		if not dir.current_is_dir() and file.begins_with("archive-") and file.ends_with(".jsonl"):
			archives.append(file)
		file = dir.get_next()
	dir.list_dir_end()
	archives.sort()
	while archives.size() > FILE_KEEP:
		DirAccess.remove_absolute("%s/%s" % [QUEUE_DIR, archives[0]])
		archives.pop_front()

func _flush_now() -> void:
	_pending_flush = false

func _flush_held() -> void:
	if _held.is_empty():
		return
	var held := _held.duplicate()
	_held.clear()
	for line in held:
		_append_line(line)

# ------------------------------------------------------------------------------
# Identity / persisted state
# ------------------------------------------------------------------------------

func _init_identity() -> void:
	user_pseudo_id = _new_id()

func _new_id() -> String:
	var crypto := Crypto.new()
	return crypto.generate_random_bytes(16).hex_encode()

func _load_state() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(STATE_PATH) != OK:
		return
	user_pseudo_id = str(cfg.get_value("identity", "user_pseudo_id", ""))
	session_number = int(cfg.get_value("identity", "session_number", 0))
	consent_state = str(cfg.get_value("consent", "analytics", "unset"))
	ads_consent_state = str(cfg.get_value("consent", "ad_signals", "unset"))
	if consent_state not in ["unset", "granted", "held", "denied"]:
		consent_state = "unset"
	if ads_consent_state not in ["unset", "granted", "denied"]:
		ads_consent_state = "unset"
	var stored_props = cfg.get_value("user", "properties", {})
	if stored_props is Dictionary:
		user_properties = stored_props.duplicate(true)

func _save_state() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("identity", "user_pseudo_id", user_pseudo_id)
	cfg.set_value("identity", "session_number", session_number)
	cfg.set_value("consent", "analytics", consent_state)
	cfg.set_value("consent", "ad_signals", ads_consent_state)
	cfg.set_value("user", "properties", user_properties)
	cfg.save(STATE_PATH)
