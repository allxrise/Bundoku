extends Node

## Ads — AdMob (Poing Studios addon) wrapper for Bundoku.
##
## Pipeline:
##   UMP consent update -> consent form (if required) -> MobileAds.initialize()
##   -> preload interstitial + rewarded + adaptive bottom banner -> controller
##   falls back to its simulated ad modal whenever an ad is unavailable (desktop,
##   editor, no fill, consent blocked, plugin missing).
##
## Telemetry contract:
##   * "ad_impression" is only written when Telemetry.analytics_allowed().
##   * The ad-signal consent gate is mirrored into Telemetry.ads_consent_state.
##   * Load failures are reported through signals/push_warning and, at most,
##     one rate-limited telemetry row per format per minute.
##
## Real (SDK) ads never emit ad impressions for the simulated modal in
## main_controller.gd; that path stays simulated=1 and revenue-free.

signal ad_ready(format: String)
signal ad_failed(format: String, message: String)
signal ad_shown(format: String, placement: String)
signal ad_closed(format: String, placement: String, duration_sec: int)
signal ad_rewarded(placement: String, amount: int, reward_type: String)
signal ad_impression(placement: String, data: Dictionary)
signal consent_finished(can_request_ads: bool)
signal privacy_options_closed()
## Emitted whenever the reserved banner height changes (0 releases the space).
signal banner_loaded(height_px: int)
signal banner_failed(message: String)

const CONFIG_PATH := "res://assets/ads/ads_config.json"

const FORMAT_INTERSTITIAL := "interstitial"
const FORMAT_REWARDED := "rewarded"
const FORMAT_BANNER := "banner"

const DEFAULT_INTERSTITIAL_UNIT := "ca-app-pub-3940256099942544/1033173712"
const DEFAULT_REWARDED_UNIT := "ca-app-pub-3940256099942544/5224354917"
const DEFAULT_BANNER_UNIT := "ca-app-pub-3940256099942544/9214589741"

## Retry delays after a failed load (seconds). MAX_LOAD_ATTEMPTS retries.
const RETRY_DELAYS: Array[float] = [15.0, 30.0, 60.0]
const MAX_LOAD_ATTEMPTS := 3
const LOAD_FAILURE_TELEMETRY_COOLDOWN_MS := 60000

## Banner retry: fixed 30 s, at most 3 attempts after the first failure.
const BANNER_RETRY_DELAY_SEC := 30.0
const BANNER_MAX_ATTEMPTS := 3

## Runtime state.
var supported: bool = false
var test_mode: bool = true
var debug_eea: bool = false

var _preload_enabled: bool = true
var enable_banner: bool = true
var _interstitial_unit: String = DEFAULT_INTERSTITIAL_UNIT
var _rewarded_unit: String = DEFAULT_REWARDED_UNIT
var _banner_unit: String = DEFAULT_BANNER_UNIT

var _consent_resolved: bool = false
var _initializing: bool = false
var _initialized: bool = false

var _interstitial_ad: InterstitialAd = null
var _rewarded_ad: RewardedAd = null
var _showing_interstitial: InterstitialAd = null
var _showing_rewarded: RewardedAd = null

var _interstitial_loader: InterstitialAdLoader = null
var _rewarded_loader: RewardedAdLoader = null
var _interstitial_loading: bool = false
var _rewarded_loading: bool = false
var _interstitial_attempts: int = 0
var _rewarded_attempts: int = 0
var _interstitial_timer: Timer = null
var _rewarded_timer: Timer = null

var _banner_view: AdView = null
var _banner_loading: bool = false
var _banner_loaded: bool = false
var _banner_height_px: int = 0
var _banner_attempts: int = 0
var _banner_retry_timer: Timer = null
var _banner_failure_logged: bool = false

var _active_format: String = ""
var _active_placement: String = ""
var _active_started_msec: int = 0
var _active_reward_earned: bool = false
var _active_reward_amount: int = 0
var _active_reward_type: String = ""
var _placement_by_format: Dictionary = {}

var _load_failure_log_ms: Dictionary = {}

func _ready() -> void:
	_load_config()
	_create_retry_timer(FORMAT_INTERSTITIAL)
	_create_retry_timer(FORMAT_REWARDED)
	_create_banner_retry_timer()

# ------------------------------------------------------------------------------
# Public API
# ------------------------------------------------------------------------------

## Starts UMP + AdMob. Safe to call on every platform; becomes a no-op when the
## SDK is unavailable (desktop/editor export without the native plugin).
func start() -> void:
	if supported:
		return
	var os_name := OS.get_name()
	if os_name != "Android" and os_name != "iOS":
		supported = false
		return
	if not Engine.has_singleton("PoingGodotAdMob"):
		supported = false
		push_warning("Ads: PoingGodotAdMob singleton missing; using simulated ads.")
		return
	supported = true
	_request_consent_update()

func is_supported() -> bool:
	return supported

func is_ready(format: String) -> bool:
	if not supported:
		return false
	if format == FORMAT_INTERSTITIAL:
		return _interstitial_ad != null
	if format == FORMAT_REWARDED:
		return _rewarded_ad != null
	return false

func can_request_ads() -> bool:
	if not supported:
		return false
	var status: int = UserMessagingPlatform.consent_information.get_consent_status()
	return (
		status == ConsentInformation.ConsentStatus.OBTAINED
		or status == ConsentInformation.ConsentStatus.NOT_REQUIRED
	)

## True when the banner exists and was successfully loaded at least once.
func is_banner_loaded() -> bool:
	return _banner_loaded and _banner_view != null

## Reserved banner height in viewport pixels (0 when no banner is showing).
func banner_height_px() -> int:
	return _banner_height_px

## Re-shows an already loaded banner. No-op on desktop or before a successful load.
func show_banner() -> void:
	if not supported or _banner_view == null or not _banner_loaded:
		return
	_banner_view.show()

## Hides the banner without releasing its reserved space (full-screen ads use this).
func hide_banner() -> void:
	if not supported or _banner_view == null:
		return
	_banner_view.hide()

## Tears the banner down and releases the reserved viewport space.
func destroy_banner() -> void:
	_stop_banner_retry()
	_banner_loading = false
	var had_height := _banner_height_px > 0
	_banner_loaded = false
	_banner_height_px = 0
	if _banner_view != null:
		_banner_view.destroy()
		_banner_view = null
	if had_height:
		banner_loaded.emit(0)

func privacy_options_required() -> bool:
	if not supported:
		return false
	var status: int = (
		UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
	)
	return status == ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED

func show_privacy_options() -> void:
	if not supported:
		return
	UserMessagingPlatform.show_privacy_options_form(
		func(form_error: FormError) -> void: _on_privacy_options_dismissed(form_error)
	)

## Returns false when no ad is ready so the caller can fall back.
func show_interstitial(placement: String) -> bool:
	if not supported or _interstitial_ad == null:
		return false
	var ad := _interstitial_ad
	_interstitial_ad = null
	_showing_interstitial = ad
	_begin_show(FORMAT_INTERSTITIAL, placement)
	hide_banner()
	ad.show()
	return true

## Returns false when no ad is ready so the caller can fall back.
func show_rewarded(placement: String) -> bool:
	if not supported or _rewarded_ad == null:
		return false
	var ad := _rewarded_ad
	_rewarded_ad = null
	_showing_rewarded = ad
	_begin_show(FORMAT_REWARDED, placement)
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(item: RewardedItem) -> void:
		_on_user_earned_reward(item)
	hide_banner()
	ad.show(listener)
	return true

# ------------------------------------------------------------------------------
# Config
# ------------------------------------------------------------------------------

func _load_config() -> void:
	var data: Dictionary = {}
	if FileAccess.file_exists(CONFIG_PATH):
		var file := FileAccess.open(CONFIG_PATH, FileAccess.READ)
		if file != null:
			var text := file.get_as_text()
			file.close()
			var parsed: Variant = JSON.parse_string(text)
			if parsed is Dictionary:
				data = parsed
			else:
				push_warning("Ads: %s is not a JSON object; using defaults." % CONFIG_PATH)
	else:
		push_warning("Ads: %s missing; using default test units." % CONFIG_PATH)

	test_mode = bool(data.get("test_mode", true))
	debug_eea = bool(data.get("debug_eea", false))
	_preload_enabled = bool(data.get("preload", true))
	enable_banner = bool(data.get("enable_banner", true))
	_interstitial_unit = str(data.get("android_interstitial_unit", DEFAULT_INTERSTITIAL_UNIT))
	_rewarded_unit = str(data.get("android_rewarded_unit", DEFAULT_REWARDED_UNIT))
	_banner_unit = str(data.get("android_banner_unit", DEFAULT_BANNER_UNIT))
	if _interstitial_unit == "":
		_interstitial_unit = DEFAULT_INTERSTITIAL_UNIT
	if _rewarded_unit == "":
		_rewarded_unit = DEFAULT_REWARDED_UNIT
	if _banner_unit == "":
		_banner_unit = DEFAULT_BANNER_UNIT

# ------------------------------------------------------------------------------
# UMP consent
# ------------------------------------------------------------------------------

func _request_consent_update() -> void:
	var params := ConsentRequestParameters.new()
	params.tag_for_under_age_of_consent = false
	if debug_eea:
		var debug_settings := ConsentDebugSettings.new()
		debug_settings.debug_geography = DebugGeography.Values.EEA
		params.consent_debug_settings = debug_settings
	UserMessagingPlatform.consent_information.update(
		params, _on_consent_update_success, _on_consent_update_failure
	)

func _on_consent_update_success() -> void:
	var info: ConsentInformation = UserMessagingPlatform.consent_information
	if (
		info.get_consent_status() == ConsentInformation.ConsentStatus.REQUIRED
		and info.get_is_consent_form_available()
	):
		UserMessagingPlatform.load_consent_form(
			_on_consent_form_loaded, _on_consent_form_failed
		)
	else:
		_finish_consent()

func _on_consent_update_failure(form_error: FormError) -> void:
	var message := "unknown"
	if form_error != null:
		message = str(form_error.message)
	push_warning("Ads: consent update failed (%s); continuing without UMP." % message)
	_finish_consent()

func _on_consent_form_loaded(consent_form: ConsentForm) -> void:
	consent_form.show(
		func(form_error: FormError) -> void: _on_consent_form_dismissed(form_error)
	)

func _on_consent_form_failed(form_error: FormError) -> void:
	var message := "unknown"
	if form_error != null:
		message = str(form_error.message)
	push_warning("Ads: consent form failed to load (%s)." % message)
	_finish_consent()

func _on_consent_form_dismissed(form_error: FormError) -> void:
	if form_error != null:
		push_warning("Ads: consent form dismissed with error (%s)." % str(form_error.message))
	_finish_consent()

func _on_privacy_options_dismissed(form_error: FormError) -> void:
	if form_error != null:
		push_warning("Ads: privacy options failed (%s)." % str(form_error.message))
	_sync_telemetry_consent(can_request_ads())
	_sync_banner_consent()
	privacy_options_closed.emit()

## Banner is consent-gated: drop it when consent is revoked, (re)load it when granted.
func _sync_banner_consent() -> void:
	if not can_request_ads():
		destroy_banner()
	elif enable_banner and _can_load():
		_load_banner()

func _finish_consent() -> void:
	var first_resolution := not _consent_resolved
	_consent_resolved = true
	var can_ads := can_request_ads()
	# force on the first resolution so the ad-signal gate is persisted even when
	# it already matches the default ("unset" -> "denied" is a real change).
	_sync_telemetry_consent(can_ads, first_resolution)
	consent_finished.emit(can_ads)
	_maybe_initialize()

func _sync_telemetry_consent(can_ads: bool, force: bool = false) -> void:
	if Telemetry == null:
		return
	var desired := "granted" if can_ads else "denied"
	if not force and Telemetry.ads_consent_state == desired:
		return
	Telemetry.set_consent(Telemetry.consent_state, desired)

# ------------------------------------------------------------------------------
# Initialization + preload
# ------------------------------------------------------------------------------

func _maybe_initialize() -> void:
	if not supported or _initialized or _initializing:
		return
	_initializing = true
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		_on_ads_initialized()
	MobileAds.initialize(listener)

func _on_ads_initialized() -> void:
	_initializing = false
	_initialized = true
	if _preload_enabled:
		_load_interstitial()
		_load_rewarded()
	if _preload_enabled and enable_banner:
		_load_banner()

func _can_load() -> bool:
	return supported and _initialized

# ------------------------------------------------------------------------------
# Banner (adaptive, anchored to the bottom edge)
# ------------------------------------------------------------------------------

func _load_banner() -> void:
	if not _can_load() or not enable_banner:
		return
	if GameState.no_ads_purchased or not can_request_ads():
		return
	if _banner_view != null or _banner_loading:
		return
	if _banner_unit == "":
		return
	_banner_loading = true
	var size: AdSize = AdSize.get_current_orientation_anchored_adaptive_banner_ad_size(
		AdSize.FULL_WIDTH
	)
	if size == null or size.width <= 0 or size.height <= 0:
		size = AdSize.BANNER
	var view := AdView.new(_banner_unit, size, AdPosition.BOTTOM)
	var listener := AdListener.new()
	listener.on_ad_loaded = func() -> void:
		_on_banner_loaded()
	listener.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_on_banner_failed(error)
	view.ad_listener = listener
	var weak_view: WeakRef = weakref(view)
	view.on_ad_paid = func(value: AdValue) -> void:
		_emit_impression(FORMAT_BANNER, FORMAT_BANNER, weak_view.get_ref(), value)
	_banner_view = view
	view.load_ad(AdRequest.new())

func _on_banner_loaded() -> void:
	_banner_loading = false
	_banner_loaded = true
	_banner_attempts = 0
	_banner_failure_logged = false
	_stop_banner_retry()
	if _banner_view == null:
		return
	# A full-screen creative is on top; _restore_banner() shows it on dismissal.
	if _active_format == "":
		_banner_view.show()
	_banner_height_px = _banner_viewport_height()
	banner_loaded.emit(_banner_height_px)
	if Telemetry != null:
		Telemetry.track(
			"banner_loaded",
			{"height_px": _banner_height_px, "ad_unit": _banner_unit}
		)

func _on_banner_failed(error: LoadAdError) -> void:
	_banner_loading = false
	var had_height := _banner_height_px > 0
	_banner_loaded = false
	_banner_height_px = 0
	if _banner_view != null:
		_banner_view.destroy()
		_banner_view = null
	var message := "load_failed"
	if error != null and str(error.message) != "":
		message = str(error.message)
	push_warning("Ads: banner load failed (%s)." % message)
	banner_failed.emit(message)
	if had_height:
		banner_loaded.emit(0)
	# One failure row per run is enough; retries are visible through banner_failed.
	if not _banner_failure_logged and Telemetry != null:
		_banner_failure_logged = true
		Telemetry.track("banner_failed", {"attempt": _banner_attempts + 1})
	_schedule_banner_retry()

## Converts the SDK's device-pixel banner height into viewport units so the
## controller can reserve exactly the space the banner covers.
func _banner_viewport_height() -> int:
	if _banner_view == null:
		return 0
	var raw_px := int(_banner_view.get_height_in_pixels())
	if raw_px <= 0:
		return 0
	var vp_size: Vector2 = get_viewport().get_visible_rect().size
	var win_size: Vector2i = DisplayServer.window_get_size()
	if vp_size.y <= 0.0 or win_size.y <= 0:
		return raw_px
	return int(round(float(raw_px) * vp_size.y / float(win_size.y)))

func _restore_banner() -> void:
	if GameState.no_ads_purchased:
		return
	show_banner()

# ------------------------------------------------------------------------------
# Interstitial
# ------------------------------------------------------------------------------

func _load_interstitial() -> void:
	if not _can_load() or _interstitial_ad != null or _interstitial_loading:
		return
	if _interstitial_unit == "":
		return
	_interstitial_loading = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_on_interstitial_loaded(ad)
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_on_interstitial_failed(error)
	_interstitial_loader = InterstitialAdLoader.new()
	_interstitial_loader.load(_interstitial_unit, AdRequest.new(), callback)

func _on_interstitial_loaded(ad: InterstitialAd) -> void:
	_interstitial_loading = false
	_interstitial_loader = null
	_interstitial_attempts = 0
	_stop_retry(FORMAT_INTERSTITIAL)
	_interstitial_ad = ad
	_configure_interstitial(ad)
	ad_ready.emit(FORMAT_INTERSTITIAL)

func _on_interstitial_failed(error: LoadAdError) -> void:
	_interstitial_loading = false
	_interstitial_loader = null
	_report_load_failure(FORMAT_INTERSTITIAL, error)
	_schedule_retry(FORMAT_INTERSTITIAL)

func _configure_interstitial(ad: InterstitialAd) -> void:
	var weak_ad: WeakRef = weakref(ad)
	var full_screen := FullScreenContentCallback.new()
	full_screen.on_ad_showed_full_screen_content = func() -> void:
		_on_ad_shown(FORMAT_INTERSTITIAL)
	full_screen.on_ad_dismissed_full_screen_content = func() -> void:
		_on_ad_dismissed(FORMAT_INTERSTITIAL)
	full_screen.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_on_ad_failed_to_show(FORMAT_INTERSTITIAL, error)
	ad.full_screen_content_callback = full_screen
	ad.on_ad_paid = func(value: AdValue) -> void:
		_emit_impression(
			FORMAT_INTERSTITIAL,
			_placement_for(FORMAT_INTERSTITIAL),
			weak_ad.get_ref(),
			value
		)

# ------------------------------------------------------------------------------
# Rewarded
# ------------------------------------------------------------------------------

func _load_rewarded() -> void:
	if not _can_load() or _rewarded_ad != null or _rewarded_loading:
		return
	if _rewarded_unit == "":
		return
	_rewarded_loading = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_on_rewarded_loaded(ad)
	callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
		_on_rewarded_failed(error)
	_rewarded_loader = RewardedAdLoader.new()
	_rewarded_loader.load(_rewarded_unit, AdRequest.new(), callback)

func _on_rewarded_loaded(ad: RewardedAd) -> void:
	_rewarded_loading = false
	_rewarded_loader = null
	_rewarded_attempts = 0
	_stop_retry(FORMAT_REWARDED)
	_rewarded_ad = ad
	_configure_rewarded(ad)
	ad_ready.emit(FORMAT_REWARDED)

func _on_rewarded_failed(error: LoadAdError) -> void:
	_rewarded_loading = false
	_rewarded_loader = null
	_report_load_failure(FORMAT_REWARDED, error)
	_schedule_retry(FORMAT_REWARDED)

func _configure_rewarded(ad: RewardedAd) -> void:
	var weak_ad: WeakRef = weakref(ad)
	var full_screen := FullScreenContentCallback.new()
	full_screen.on_ad_showed_full_screen_content = func() -> void:
		_on_ad_shown(FORMAT_REWARDED)
	full_screen.on_ad_dismissed_full_screen_content = func() -> void:
		_on_ad_dismissed(FORMAT_REWARDED)
	full_screen.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		_on_ad_failed_to_show(FORMAT_REWARDED, error)
	ad.full_screen_content_callback = full_screen
	ad.on_ad_paid = func(value: AdValue) -> void:
		_emit_impression(
			FORMAT_REWARDED,
			_placement_for(FORMAT_REWARDED),
			weak_ad.get_ref(),
			value
		)

func _on_user_earned_reward(item: RewardedItem) -> void:
	if _active_format != FORMAT_REWARDED:
		return
	_active_reward_earned = true
	if item != null:
		_active_reward_amount = int(item.amount)
		_active_reward_type = str(item.type)

# ------------------------------------------------------------------------------
# Show lifecycle
# ------------------------------------------------------------------------------

func _begin_show(format: String, placement: String) -> void:
	_active_format = format
	_active_placement = placement
	_active_started_msec = Time.get_ticks_msec()
	_active_reward_earned = false
	_active_reward_amount = 0
	_active_reward_type = ""
	_placement_by_format[format] = placement

func _on_ad_shown(format: String) -> void:
	if format != _active_format:
		return
	_active_started_msec = Time.get_ticks_msec()
	ad_shown.emit(format, _active_placement)

func _on_ad_dismissed(format: String) -> void:
	if format != _active_format:
		return
	var placement := _active_placement
	var duration := _elapsed_sec()
	if format == FORMAT_REWARDED and _active_reward_earned:
		ad_rewarded.emit(placement, _active_reward_amount, _active_reward_type)
	ad_closed.emit(format, placement, duration)
	_reset_showing(format)
	_restore_banner()
	_reload(format)

func _on_ad_failed_to_show(format: String, error: AdError) -> void:
	var message := "failed_to_show"
	if error != null:
		message = str(error.message)
	push_warning("Ads: %s failed to show (%s)." % [format, message])
	ad_failed.emit(format, message)
	var placement := _placement_for(format)
	var duration := 0
	# Treat a failed presentation as a zero-length close so the caller's pending
	# completion can never leave the UI stuck behind a dead full-screen ad.
	if format == _active_format:
		duration = _elapsed_sec()
		placement = _active_placement
	_reset_showing(format)
	ad_closed.emit(format, placement, duration)
	_restore_banner()
	_reload(format)

func _elapsed_sec() -> int:
	if _active_started_msec <= 0:
		return 0
	return int(round(float(Time.get_ticks_msec() - _active_started_msec) / 1000.0))

func _reset_showing(format: String) -> void:
	if format == FORMAT_REWARDED:
		if _showing_rewarded != null:
			_showing_rewarded.destroy()
		_showing_rewarded = null
	else:
		if _showing_interstitial != null:
			_showing_interstitial.destroy()
		_showing_interstitial = null
	if format == _active_format:
		_active_format = ""
		_active_placement = ""
		_active_started_msec = 0
		_active_reward_earned = false
		_active_reward_amount = 0
		_active_reward_type = ""

func _reload(format: String) -> void:
	if not _preload_enabled or not _can_load():
		return
	if format == FORMAT_REWARDED:
		_load_rewarded()
	else:
		_load_interstitial()

# ------------------------------------------------------------------------------
# Impression-level revenue (ILARE) telemetry
# ------------------------------------------------------------------------------

func _emit_impression(format: String, placement: String, ad: Object, value: AdValue) -> void:
	var data := _build_impression_data(format, placement, ad, value)
	ad_impression.emit(placement, data)
	if Telemetry == null or not Telemetry.analytics_allowed():
		return
	Telemetry.track("ad_impression", data)

func _build_impression_data(
	format: String, placement: String, ad: Object, value: AdValue
) -> Dictionary:
	var data := {
		"ad_platform": "AdMob",
		"ad_source": "unknown",
		"ad_format": format,
		"ad_unit_name": _unit_for(format),
		"currency": "USD",
		"value": 0.0,
		"precision": 0,
		"placement": placement,
	}
	if value != null:
		if value.currency_code != "":
			data["currency"] = value.currency_code
		data["value"] = float(value.value_micros) / 1000000.0
		data["precision"] = int(value.precision)
	var response_info: ResponseInfo = null
	if ad is RewardedAd:
		response_info = (ad as RewardedAd).get_response_info()
	elif ad is InterstitialAd:
		response_info = (ad as InterstitialAd).get_response_info()
	elif ad is AdView:
		response_info = (ad as AdView).get_response_info()
	if response_info != null and response_info.loaded_adapter_response_info != null:
		var source_name := response_info.loaded_adapter_response_info.ad_source_name
		if source_name != "":
			data["ad_source"] = source_name
	return data

func _unit_for(format: String) -> String:
	if format == FORMAT_REWARDED:
		return _rewarded_unit
	if format == FORMAT_BANNER:
		return _banner_unit
	return _interstitial_unit

func _placement_for(format: String) -> String:
	var placement := str(_placement_by_format.get(format, "unknown"))
	return "unknown" if placement == "" else placement

# ------------------------------------------------------------------------------
# Load retries + failure reporting
# ------------------------------------------------------------------------------

func _create_retry_timer(format: String) -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.name = "%sRetryTimer" % format.capitalize()
	add_child(timer)
	if format == FORMAT_REWARDED:
		_rewarded_timer = timer
		timer.timeout.connect(_load_rewarded)
	else:
		_interstitial_timer = timer
		timer.timeout.connect(_load_interstitial)

func _create_banner_retry_timer() -> void:
	var timer := Timer.new()
	timer.one_shot = true
	timer.name = "BannerRetryTimer"
	add_child(timer)
	_banner_retry_timer = timer
	timer.timeout.connect(_load_banner)

func _schedule_banner_retry() -> void:
	if _banner_retry_timer == null:
		return
	if not enable_banner or GameState.no_ads_purchased or not can_request_ads():
		return
	if _banner_attempts >= BANNER_MAX_ATTEMPTS:
		return
	_banner_attempts += 1
	_banner_retry_timer.start(BANNER_RETRY_DELAY_SEC)

func _stop_banner_retry() -> void:
	if _banner_retry_timer != null and not _banner_retry_timer.is_stopped():
		_banner_retry_timer.stop()

func _schedule_retry(format: String) -> void:
	var timer: Timer = _rewarded_timer if format == FORMAT_REWARDED else _interstitial_timer
	if timer == null:
		return
	var attempts := _rewarded_attempts if format == FORMAT_REWARDED else _interstitial_attempts
	if attempts >= MAX_LOAD_ATTEMPTS:
		return
	if format == FORMAT_REWARDED:
		_rewarded_attempts += 1
	else:
		_interstitial_attempts += 1
	timer.start(RETRY_DELAYS[mini(attempts, RETRY_DELAYS.size() - 1)])

func _stop_retry(format: String) -> void:
	var timer: Timer = _rewarded_timer if format == FORMAT_REWARDED else _interstitial_timer
	if timer != null and not timer.is_stopped():
		timer.stop()

func _report_load_failure(format: String, error: LoadAdError) -> void:
	var message := "load_failed"
	if error != null and str(error.message) != "":
		message = str(error.message)
	push_warning("Ads: %s load failed (%s)." % [format, message])
	ad_failed.emit(format, message)

	var now := Time.get_ticks_msec()
	var last_ms: int = int(_load_failure_log_ms.get(format, -LOAD_FAILURE_TELEMETRY_COOLDOWN_MS))
	if now - last_ms < LOAD_FAILURE_TELEMETRY_COOLDOWN_MS:
		return
	_load_failure_log_ms[format] = now
	if Telemetry != null:
		Telemetry.track("ad_load_failed", {"format": format})
