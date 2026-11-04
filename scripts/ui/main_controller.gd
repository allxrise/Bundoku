extends Control

## Main UI Controller for Bundoku: Tavşan Bulmacası
## Implements the "Cozy Kawaii Woodland / Bunny Bakery" UI Design System:
## - Warm oatmeal/vanilla 3D tactile cards (#FFF9EC / #CBAE83 / #A98762)
## - Carrot-orange primary CTAs (#FFAC48 / #D66E2C / #A94E27) & Berry-pink accents (#F58CA4)
## - Color-coded rule pills, recessed pastry-mold progress slots, and Wooden Bakery Tray board
## - Smooth Godot 4 Tween micro-animations (button squish/spring, slot pop-in, heart shake, star reveal)
## - Clean commercial player-facing UI (zero dev/MVP debug counters or cheat buttons)

var _bg_tex: Texture2D = null
var _logo_tex: Texture2D = null
var _bunny_idle_tex: Texture2D = null
var _bunny_conflict_tex: Texture2D = null
var _carrot_tex: Texture2D = null

var _ui_tex: Dictionary = {}
var _font_base: FontFile = null
var _font_bold: FontVariation = null
var _font_extrabold: FontVariation = null

# Screens
var _home_screen: Control
var _game_screen: Control
var _home_margin: MarginContainer
var _game_margin: MarginContainer
var _modal_layer: Control
var _damage_flash: ColorRect
# Bottom space reserved for the AdMob banner, in viewport pixels.
var _banner_inset_px: int = 0

# Staggered animation card groups
var _home_anim_cards: Array[Control] = []
var _game_anim_cards: Array[Control] = []

# Home UI refs
var _home_trophy_label: Label
var _home_streak_label: Label
var _home_hints_label: Label
var _home_carrots_label: Label
var _home_play_btn_label: Label
var _home_speech_label: Label
var _home_sound_icon: TextureRect
var _level_grid: GridContainer

# Game UI refs
var _level_title_label: Label
var _timer_label: Label
var _heart_icons: Array[TextureRect] = []
var _progress_slots_box: HBoxContainer
var _progress_label: Label
var _last_placed_count: int = 0
var _mode_btn: Button
var _mode_icon_rect: TextureRect
var _mode_caption_lbl: Label
var _auto_x_btn: Button
var _auto_x_lbl: Label
var _pattern_btn: Button
var _pattern_lbl: Label
var _game_sound_icon: TextureRect
var _board_view: BoardView
var _toast_panel: PanelContainer
var _toast_title: Label
var _toast_body: Label
var _draft_bar: HBoxContainer
var _undo_btn: Button
var _hint_btn: Button
var _hint_badge_lbl: Label
var _carrot_btn: Button
var _carrot_badge_lbl: Label
var _draft_btn: Button
var _draft_icon_rect: TextureRect
var _draft_caption_lbl: Label

# Gameplay session state
var _active_level_idx: int = 0
var _lives: int = 3
var _mistakes: int = 0
var _elapsed_sec: int = 0
var _timer_accum: float = 0.0
var _is_playing: bool = false

# Ad countdown state (silent background logic, clean player-facing modal)
var _ad_countdown_sec: float = 0.0
var _ad_countdown_total: float = 3.0
var _ad_is_active: bool = false
var _ad_close_btn: Button = null
var _ad_close_lbl: Label = null
var _ad_progress_bar: ProgressBar = null
var _ad_on_complete: Callable = Callable()

# Real (AdMob) ad offer state. The simulated modal keeps using _ad_on_complete.
var _pending_ad_placement: String = ""
var _pending_ad_on_complete: Callable = Callable()
var _pending_ad_reward_earned: bool = false

# Cozy Kawaii Woodland / Bunny Bakery Palette
const PALETTE := {
	"bg_oatmeal": Color("#F8F0DF"),
	"card_face": Color("#FFF9EC"),
	"card_alt": Color("#F4E9D6"),
	"card_lip": Color("#CBAE83"),
	"card_border": Color("#A98762"),
	"card_shadow": Color(0.45, 0.34, 0.23, 0.22),

	"text_main": Color("#60452F"),
	"text_sec": Color("#987A5B"),
	"text_light": Color("#FFF9EC"),

	"carrot_face": Color("#FFAC48"),
	"carrot_lip": Color("#D66E2C"),
	"carrot_border": Color("#A94E27"),

	"berry_face": Color("#F58CA4"),
	"berry_lip": Color("#C95678"),
	"berry_border": Color("#A83D60"),

	"sage_face": Color("#DCE8CF"),
	"sage_border": Color("#8FA878"),
	"sage_text": Color("#466333"),

	"cream_face": Color("#FFF4DC"),
	"cream_lip": Color("#D4B98F"),

	"well_bg": Color("#D8C5A8"),
	"well_border": Color("#A88B68"),
	"slot_empty": Color("#EDE0C9"),
	"slot_empty_border": Color("#C2A784"),
	"slot_filled": Color("#F9BB62"),
	"slot_filled_border": Color("#C18D45")
}

const UI_TEXTURE_FILES := [
	"common_big_star",
	"common_small_star",
	"common_btn_close",
	"common_btn_orange_capsule",
	"common_btn_orange_round",
	"common_btn_primary",
	"common_dialog_frame_9patch",
	"common_icon_back",
	"common_icon_settings",
	"common_love_heart",
	"common_normal_btn_bg",
	"common_round_btn_base",
	"common_success_check_mark",
	"game_btn_auto_mark_1",
	"game_btn_tool_bg",
	"game_cat_progress_bar_bg",
	"game_cat_progress_dot",
	"game_cat_progress_dot_bg",
	"game_cat_progress_slot",
	"game_icon_draft_pencil",
	"game_icon_hint_lamp",
	"game_icon_mark_lock",
	"game_icon_mark_white",
	"game_icon_mark_white_brush",
	"game_icon_pencil_selected",
	"game_icon_timer",
	"game_icon_undo",
	"game_pattern_icon_pattern_paw",
	"game_rule_diagram_color",
	"game_rule_diagram_line",
	"game_rule_diagram_touch",
	"home_lock",
	"pop_icon_fire",
	"rank_activity_award_podium_gold",
	"rank_activity_award_podium_silver",
	"rank_activity_award_podium_bronze"
]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_load_assets()
	_setup_fonts_and_theme()
	_build_ui()
	_apply_safe_area_margins()
	call_deferred("_apply_safe_area_margins")
	resized.connect(_apply_safe_area_margins)
	get_tree().create_timer(0.15).timeout.connect(_apply_safe_area_margins)
	GameState.stats_changed.connect(_refresh_all_ui)
	_show_home_screen()
	# The manager signal carries (format, placement, duration); the controller only
	# needs placement + duration and derives the format from the placement.
	Ads.ad_closed.connect(_on_ads_ad_closed_signal)
	Ads.ad_rewarded.connect(_on_ads_ad_rewarded)
	Ads.consent_finished.connect(_on_ads_consent_finished)
	Ads.banner_loaded.connect(_on_banner_loaded)
	Ads.start()

func _apply_safe_area_margins() -> void:
	var vp_size: Vector2 = get_viewport_rect().size
	if vp_size.x <= 0.0 or vp_size.y <= 0.0:
		vp_size = Vector2(540.0, 960.0)

	var win_size: Vector2i = DisplayServer.window_get_size()
	var scale_y: float = vp_size.y / float(maxi(1, win_size.y))
	var scale_x: float = vp_size.x / float(maxi(1, win_size.x))

	var is_mobile: bool = OS.has_feature("android") or OS.has_feature("ios") or OS.has_feature("mobile")
	var top_inset_vp: int = 0
	var bottom_inset_vp: int = 0
	var left_inset_vp: int = 0
	var right_inset_vp: int = 0

	# Display-safe-area and cutout rects are display-relative. Mapping them onto the
	# window only makes sense when the window covers the display (mobile fullscreen);
	# on desktop they describe the taskbar/menu bar and would fake insets that clip
	# the 540px-wide layout.
	if is_mobile:
		var safe_top_px: float = 0.0
		var safe_bottom_px: float = 0.0
		var safe_left_px: float = 0.0
		var safe_right_px: float = 0.0

		var safe_rect: Rect2i = DisplayServer.get_display_safe_area()
		if safe_rect.size.x > 0 and safe_rect.size.y > 0 and win_size.x > 0 and win_size.y > 0:
			safe_top_px = maxf(safe_top_px, float(maxi(0, safe_rect.position.y)))
			safe_bottom_px = maxf(safe_bottom_px, float(maxi(0, win_size.y - (safe_rect.position.y + safe_rect.size.y))))
			safe_left_px = maxf(safe_left_px, float(maxi(0, safe_rect.position.x)))
			safe_right_px = maxf(safe_right_px, float(maxi(0, win_size.x - (safe_rect.position.x + safe_rect.size.x))))

		var cutouts: Array[Rect2] = DisplayServer.get_display_cutouts()
		for cutout in cutouts:
			if win_size.y > 0 and cutout.position.y < float(win_size.y) * 0.25:
				safe_top_px = maxf(safe_top_px, cutout.position.y + cutout.size.y)
			elif win_size.y > 0 and (cutout.position.y + cutout.size.y) > float(win_size.y) * 0.75:
				safe_bottom_px = maxf(safe_bottom_px, float(win_size.y) - cutout.position.y)

		top_inset_vp = int(ceil(safe_top_px * scale_y))
		bottom_inset_vp = int(ceil(safe_bottom_px * scale_y))
		left_inset_vp = int(ceil(safe_left_px * scale_x))
		right_inset_vp = int(ceil(safe_right_px * scale_x))

		# Ensure a generous top safe margin for notch / punch-hole cameras and bottom margin for gesture bars
		top_inset_vp = maxi(top_inset_vp, 88)
		bottom_inset_vp = maxi(bottom_inset_vp, 28)

	# While a banner occupies the bottom strip it already covers the gesture /
	# safe-area region, so do not stack base + safe padding on top of it.
	var home_bottom := 16 + bottom_inset_vp
	var game_bottom := 14 + bottom_inset_vp
	if _banner_inset_px > 0:
		home_bottom = _banner_inset_px + 8
		game_bottom = _banner_inset_px + 6

	if _home_margin != null:
		_home_margin.add_theme_constant_override("margin_left", 18 + left_inset_vp)
		_home_margin.add_theme_constant_override("margin_right", 18 + right_inset_vp)
		_home_margin.add_theme_constant_override("margin_top", 14 + top_inset_vp)
		_home_margin.add_theme_constant_override("margin_bottom", home_bottom)

	if _game_margin != null:
		_game_margin.add_theme_constant_override("margin_left", 14 + left_inset_vp)
		_game_margin.add_theme_constant_override("margin_right", 14 + right_inset_vp)
		_game_margin.add_theme_constant_override("margin_top", 12 + top_inset_vp)
		_game_margin.add_theme_constant_override("margin_bottom", game_bottom)

## Ads reports the banner height in viewport pixels; reserve exactly that much at
## the bottom so the AdView never covers the home or game layout.
func _on_banner_loaded(height_px: int) -> void:
	_banner_inset_px = maxi(0, height_px)
	_apply_safe_area_margins()

func _load_assets() -> void:
	_bg_tex = _load_image_tex("res://assets/chatgpt_ui/bundoku_bg_meadow.png")
	if _bg_tex == null:
		_bg_tex = _load_image_tex("res://assets/sprites/bg_meadow.png")
	_logo_tex = _load_image_tex("res://assets/chatgpt_ui/bundoku_logo.png")
	_bunny_idle_tex = _load_image_tex("res://assets/chatgpt_ui/icon_bunny.png")
	_bunny_conflict_tex = _load_image_tex("res://assets/chatgpt_ui/icon_bunny_conflict.png")
	_carrot_tex = _load_image_tex("res://assets/chatgpt_ui/icon_carrot.png")

	for key in UI_TEXTURE_FILES:
		var path := "res://assets/ui/%s.png" % key
		var tex := _load_image_tex(path)
		if tex != null:
			_ui_tex[key] = tex

	var chatgpt_overrides := {
		"common_big_star": "icon_star",
		"common_small_star": "icon_star",
		"common_love_heart": "icon_heart",
		"rank_activity_award_podium_gold": "icon_trophy",
		"game_icon_hint_lamp": "icon_hint",
		"game_icon_draft_pencil": "icon_pencil",
		"game_icon_pencil_selected": "icon_pencil",
		"game_icon_undo": "icon_undo",
		"common_icon_back": "icon_undo",
		"icon_broom": "icon_broom",
		"pop_icon_fire": "icon_flame",
		"game_icon_timer": "icon_timer",
		"home_lock": "icon_lock",
		"game_icon_mark_lock": "icon_lock",
		"icon_sound_on": "icon_sound_on",
		"icon_sound_off": "icon_sound_off",
		"icon_play": "icon_play",
		"icon_ad_video": "icon_ad_video",
		"panel_cream_card": "panel_cream_card",
		"panel_cream_card_sm": "panel_cream_card_sm",
		"panel_wood_frame": "panel_wood_frame",
		"panel_wood_frame_sm": "panel_wood_frame_sm",
		"panel_recessed_well": "panel_recessed_well",
		"panel_recessed_well_sm": "panel_recessed_well_sm",
		"btn_pill_orange": "btn_pill_orange",
		"btn_pill_orange_sm": "btn_pill_orange_sm",
		"btn_pill_pink": "btn_pill_pink",
		"btn_pill_pink_sm": "btn_pill_pink_sm",
		"btn_pill_green": "btn_pill_green",
		"btn_pill_green_sm": "btn_pill_green_sm",
		"tile_gold": "tile_gold",
		"tile_gold_sm": "tile_gold_sm",
		"tile_blue": "tile_blue",
		"tile_blue_sm": "tile_blue_sm",
		"tile_pink": "tile_pink",
		"tile_pink_sm": "tile_pink_sm",
		"tile_green": "tile_green",
		"tile_green_sm": "tile_green_sm",
		"ribbon_gold": "ribbon_gold"
	}
	for k in chatgpt_overrides.keys():
		var cpath := "res://assets/chatgpt_ui/%s.png" % chatgpt_overrides[k]
		var ctex := _load_image_tex(cpath)
		if ctex != null:
			_ui_tex[k] = ctex

	if ResourceLoader.exists("res://assets/fonts/Baloo2.ttf"):
		var f = load("res://assets/fonts/Baloo2.ttf")
		if f is FontFile:
			_font_base = f
	elif ResourceLoader.exists("res://assets/fonts/Baloo2.res"):
		var f2 = load("res://assets/fonts/Baloo2.res")
		if f2 is FontFile:
			_font_base = f2

func _setup_fonts_and_theme() -> void:
	if _font_base != null:
		var sys_fallback := SystemFont.new()
		sys_fallback.font_names = PackedStringArray([
			"Noto Sans", "Roboto", "Noto Sans CJK SC", "Noto Sans CJK JP", "Noto Sans CJK KR",
			"Noto Sans Arabic", "Noto Sans Devanagari", "Noto Sans Bengali", "Noto Sans Telugu",
			"Droid Sans Fallback", "sans-serif"
		])
		_font_base.fallbacks = [sys_fallback]

		_font_bold = FontVariation.new()
		_font_bold.base_font = _font_base
		_font_bold.variation_opentype = {"wght": 700}
		_font_bold.variation_embolden = 0.16

		_font_extrabold = FontVariation.new()
		_font_extrabold.base_font = _font_base
		_font_extrabold.variation_opentype = {"wght": 800}
		_font_extrabold.variation_embolden = 0.35

		var th := Theme.new()
		th.default_font = _font_bold
		th.default_font_size = 15
		theme = th

func _get_ui_tex(key: String) -> Texture2D:
	return _ui_tex.get(key, null)

func _load_image_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var r = load(path)
		if r is Texture2D:
			return r
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			img.generate_mipmaps()
			return ImageTexture.create_from_image(img)
	return null

func _process(delta: float) -> void:
	# Ad modals must not eat into the level timer: star thresholds use elapsed_sec.
	if _is_playing and not _ad_is_active:
		_timer_accum += delta
		if _timer_accum >= 1.0:
			_timer_accum -= 1.0
			_elapsed_sec += 1
			_update_timer_label()

	if _ad_is_active:
		_ad_countdown_sec = maxf(0.0, _ad_countdown_sec - delta)
		if _ad_progress_bar != null:
			_ad_progress_bar.value = ((_ad_countdown_total - _ad_countdown_sec) / maxf(0.1, _ad_countdown_total)) * 100.0
		if _ad_countdown_sec <= 0.0:
			if _ad_close_btn != null and _ad_close_btn.disabled:
				_ad_close_btn.disabled = false
				_style_tactile_button(_ad_close_btn, PALETTE.carrot_face, PALETTE.carrot_border, PALETTE.carrot_lip, PALETTE.text_light, 18, 6)
				if _ad_close_lbl != null:
					_ad_close_lbl.text = Loc.t("ad_continue")
		else:
			if _ad_close_lbl != null:
				_ad_close_lbl.text = Loc.t("ad_wait_sec") % int(ceil(_ad_countdown_sec))

func _update_timer_label() -> void:
	var mins := _elapsed_sec / 60
	var secs := _elapsed_sec % 60
	_timer_label.text = "%02d:%02d" % [mins, secs]

# ------------------------------------------------------------------------------
# Cozy Kawaii Bakery StyleBox & Micro-Animation Helpers
# ------------------------------------------------------------------------------

func _pick_chatgpt_container_key(col: Color, is_compact: bool, prefer_tile: bool = false) -> String:
	var suffix := "_sm" if is_compact else ""
	if col.g > col.r + 0.02 and col.g >= col.b:
		return ("tile_green" if prefer_tile else "btn_pill_green") + suffix
	if col.b > col.r + 0.02 and col.b >= col.g - 0.04:
		return "tile_blue" + suffix
	if col.r > 0.88 and col.g > 0.45 and col.g < 0.74 and col.b < 0.42:
		return "btn_pill_orange" + suffix
	if col.r > 0.85 and col.b > col.g - 0.04 and col.g < 0.92:
		return ("tile_pink" if prefer_tile else "btn_pill_pink") + suffix
	if col.r > 0.90 and col.g > 0.72 and col.b < 0.75:
		return "tile_gold" + suffix
	return "panel_cream_card" + suffix

func _make_9slice_style(
	tex_key: String,
	slice_h: int,
	slice_v: int,
	pad_h: int,
	pad_v: int,
	modulate_col: Color = Color.WHITE,
	pad_top_override: int = -1,
	pad_bot_override: int = -1
) -> StyleBox:
	var tex := _get_ui_tex(tex_key)
	if tex == null:
		var fallback := StyleBoxFlat.new()
		fallback.bg_color = PALETTE.card_face * modulate_col
		fallback.set_corner_radius_all(16)
		fallback.content_margin_left = pad_h
		fallback.content_margin_right = pad_h
		fallback.content_margin_top = pad_v
		fallback.content_margin_bottom = pad_v
		return fallback
	var sb := StyleBoxTexture.new()
	sb.texture = tex
	sb.texture_margin_left = float(slice_h)
	sb.texture_margin_right = float(slice_h)
	sb.texture_margin_top = float(slice_v)
	sb.texture_margin_bottom = float(slice_v)
	sb.content_margin_left = float(pad_h)
	sb.content_margin_right = float(pad_h)
	sb.content_margin_top = float(pad_top_override if pad_top_override >= 0 else pad_v)
	sb.content_margin_bottom = float(pad_bot_override if pad_bot_override >= 0 else pad_v)
	sb.modulate_color = modulate_col
	return sb

func _make_card_style(
	bg: Color,
	border: Color,
	radius: int = 16,
	border_w: int = 3,
	bottom_lip: int = 6,
	pad_h: int = 14,
	pad_v: int = 10,
	_with_shadow: bool = true
) -> StyleBox:
	# Tiny micro-badges, progress slot dots, and thin progress bars use crisp StyleBoxFlat
	if radius <= 12:
		var flat := StyleBoxFlat.new()
		flat.bg_color = bg
		flat.border_color = border
		flat.set_border_width_all(border_w)
		flat.border_width_bottom = border_w + bottom_lip
		flat.set_corner_radius_all(radius)
		flat.content_margin_left = float(pad_h)
		flat.content_margin_right = float(pad_h)
		flat.content_margin_top = float(pad_v)
		flat.content_margin_bottom = float(pad_v)
		return flat
	var is_compact := (radius <= 16 and bottom_lip <= 4)
	var key := _pick_chatgpt_container_key(bg, is_compact, false)
	var sh := 18 if is_compact else 24
	var sv := 12 if is_compact else 18
	var mod := Color(1.0, 1.0, 1.0, bg.a)
	if border == Color("#A99F90"):
		mod = Color(0.82, 0.80, 0.76, 0.92)
	return _make_9slice_style(key, sh, sv, pad_h, pad_v, mod)

func _make_recessed_style(
	bg: Color = PALETTE.well_bg,
	border: Color = PALETTE.well_border,
	radius: int = 16,
	pad_h: int = 12,
	pad_v: int = 6
) -> StyleBox:
	if radius <= 10:
		var flat := StyleBoxFlat.new()
		flat.bg_color = bg
		flat.border_color = border
		flat.set_border_width_all(2)
		flat.set_corner_radius_all(radius)
		flat.content_margin_left = float(pad_h)
		flat.content_margin_right = float(pad_h)
		flat.content_margin_top = float(pad_v)
		flat.content_margin_bottom = float(pad_v)
		return flat
	var is_compact := (radius <= 14)
	var key := "panel_recessed_well_sm" if is_compact else "panel_recessed_well"
	var sh := 18 if is_compact else 24
	var sv := 14 if is_compact else 16
	return _make_9slice_style(key, sh, sv, pad_h, maxi(8, pad_v), Color.WHITE)

func _style_tactile_button(
	btn: Button,
	face_col: Color,
	border_col: Color,
	lip_col: Color,
	text_col: Color = PALETTE.text_main,
	radius: int = 18,
	bevel: int = 6,
	pad_h: int = 12,
	pad_v: int = 6
) -> void:
	if radius <= 12:
		var flat_n := StyleBoxFlat.new()
		flat_n.bg_color = face_col
		flat_n.border_color = border_col
		flat_n.set_border_width_all(2)
		flat_n.border_width_bottom = 2 + bevel
		flat_n.set_corner_radius_all(radius)
		flat_n.content_margin_left = float(pad_h)
		flat_n.content_margin_right = float(pad_h)
		flat_n.content_margin_top = float(pad_v)
		flat_n.content_margin_bottom = float(pad_v)
		btn.add_theme_stylebox_override("normal", flat_n)
		btn.add_theme_stylebox_override("hover", flat_n)
		btn.add_theme_stylebox_override("pressed", flat_n)
		btn.add_theme_stylebox_override("focus", flat_n)
		btn.add_theme_color_override("font_color", text_col)
		if _font_extrabold != null:
			btn.add_theme_font_override("font", _font_extrabold)
		_attach_button_anim(btn)
		return
	var is_compact := (radius <= 15 or bevel <= 4)
	var prefer_tile := (radius >= 16 and radius <= 18)
	var key := _pick_chatgpt_container_key(face_col, is_compact, prefer_tile)
	var sh := 14 if is_compact else (16 if prefer_tile else 22)
	var sv := 11 if is_compact else (16 if prefer_tile else 18)

	var normal_sb := _make_9slice_style(key, sh, sv, pad_h, pad_v, Color.WHITE)
	var hover_sb := _make_9slice_style(key, sh, sv, pad_h, pad_v, Color(1.06, 1.06, 1.06, 1.0))
	var pressed_sb := _make_9slice_style(key, sh, sv, pad_h, pad_v, Color(0.92, 0.90, 0.88, 1.0))
	var disabled_sb := _make_9slice_style("panel_cream_card_sm" if is_compact else "panel_cream_card", sh, sv, pad_h, pad_v, Color(0.80, 0.78, 0.74, 0.85))
	if border_col == Color("#A99F90"):
		normal_sb = disabled_sb

	btn.add_theme_stylebox_override("normal", normal_sb)
	btn.add_theme_stylebox_override("hover", hover_sb)
	btn.add_theme_stylebox_override("pressed", pressed_sb)
	btn.add_theme_stylebox_override("focus", hover_sb)
	btn.add_theme_stylebox_override("disabled", disabled_sb)
	btn.add_theme_color_override("font_color", text_col)
	btn.add_theme_color_override("font_hover_color", text_col)
	btn.add_theme_color_override("font_pressed_color", text_col)
	btn.add_theme_color_override("font_disabled_color", Color("#7E7468"))
	if _font_extrabold != null:
		btn.add_theme_font_override("font", _font_extrabold)

	_attach_button_anim(btn)

func _attach_button_anim(btn: Button) -> void:
	if btn.has_meta("anim_bound"):
		return
	btn.set_meta("anim_bound", true)
	btn.button_down.connect(func():
		if btn.disabled:
			return
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2(1.05, 0.90), 0.09)
	)
	btn.button_up.connect(func():
		btn.pivot_offset = btn.size * 0.5
		var tw := btn.create_tween()
		tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(btn, "scale", Vector2.ONE, 0.22)
	)

func _animate_cards_enter(cards: Array[Control]) -> void:
	# Containers report size 0 until the first layout pass; pivoting before that
	# animates from the top-left corner instead of the card center.
	await get_tree().process_frame
	for i in range(cards.size()):
		var c := cards[i]
		if not is_instance_valid(c):
			continue
		c.modulate.a = 0.0
		c.scale = Vector2(0.95, 0.95)
		c.pivot_offset = c.size * 0.5
		var tw := c.create_tween()
		tw.tween_interval(float(i) * 0.05)
		tw.set_parallel(true)
		tw.tween_property(c, "modulate:a", 1.0, 0.24).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.tween_property(c, "scale", Vector2.ONE, 0.30).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _animate_slot_pop(slot: Control) -> void:
	await get_tree().process_frame
	if not is_instance_valid(slot):
		return
	slot.pivot_offset = slot.size * 0.5
	slot.scale = Vector2(0.45, 0.45)
	var tw := slot.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(slot, "scale", Vector2(1.18, 1.18), 0.14)
	tw.tween_property(slot, "scale", Vector2.ONE, 0.12)

func _animate_heart_loss(heart: Control) -> void:
	if not is_instance_valid(heart):
		return
	heart.pivot_offset = heart.size * 0.5
	var tw := heart.create_tween()
	tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(heart, "scale", Vector2(1.30, 0.75), 0.10)
	tw.tween_property(heart, "scale", Vector2.ONE, 0.18)

	if is_instance_valid(_damage_flash):
		_damage_flash.color = Color(0.92, 0.35, 0.35, 0.0)
		var ftw := create_tween()
		ftw.tween_property(_damage_flash, "color:a", 0.25, 0.07)
		ftw.tween_property(_damage_flash, "color:a", 0.0, 0.25)

func _make_label(
	text: String,
	font_size: int = 15,
	color: Color = PALETTE.text_main,
	extra_bold: bool = true,
	outline_px: int = 0,
	outline_col: Color = Color("#60452F"),
	shadow_offset_y: int = 0,
	shadow_col: Color = Color(0.45, 0.34, 0.23, 0.25)
) -> Label:
	var lbl := Label.new()
	lbl.text = text
	var ls := LabelSettings.new()
	ls.font = _font_extrabold if extra_bold else _font_bold
	ls.font_size = font_size
	ls.font_color = color
	ls.outline_size = outline_px
	ls.outline_color = outline_col
	if shadow_offset_y > 0:
		ls.shadow_size = 2
		ls.shadow_color = shadow_col
		ls.shadow_offset = Vector2(0, shadow_offset_y)
	lbl.label_settings = ls
	return lbl

func _make_icon_rect(tex: Texture2D, sz: Vector2, tint: Color = Color.WHITE) -> TextureRect:
	var tr := TextureRect.new()
	tr.texture = tex
	tr.custom_minimum_size = sz
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	tr.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	tr.modulate = tint
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return tr

func _build_ui() -> void:
	# 1. Warm Woodland Meadow + Oatmeal Backdrop
	if _bg_tex != null:
		var bg_rect := TextureRect.new()
		bg_rect.texture = _bg_tex
		bg_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg_rect)
	else:
		var bg_col := ColorRect.new()
		bg_col.color = PALETTE.bg_oatmeal
		bg_col.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(bg_col)

	# Subtle warm sunlight veil (12% opacity so ChatGPT's Woodland Meadow & Bunny Bakery background shines vividly!)
	var veil := ColorRect.new()
	veil.color = Color(1.0, 0.97, 0.90, 0.12)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(veil)

	_home_screen = Control.new()
	_home_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_home_screen)
	_build_home_screen()

	_game_screen = Control.new()
	_game_screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_game_screen)
	_build_game_screen()

	_damage_flash = ColorRect.new()
	_damage_flash.color = Color(1, 0, 0, 0)
	_damage_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_damage_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_damage_flash)

	_modal_layer = Control.new()
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.visible = false
	add_child(_modal_layer)

func _make_header_stat_pill(icon_tex: Texture2D, bg_col: Color, border_col: Color, text_col: Color, icon_sz: Vector2 = Vector2(22, 22)) -> Array:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", _make_card_style(bg_col, border_col, 16, 2, 4, 10, 5, true))
	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 6)
	pill.add_child(hb)
	if icon_tex != null:
		hb.add_child(_make_icon_rect(icon_tex, icon_sz))
	var lbl := _make_label("0", 15, text_col, true, 0, Color.TRANSPARENT, 1)
	hb.add_child(lbl)
	return [pill, lbl]

func _build_home_screen() -> void:
	_home_anim_cards.clear()

	var margin := MarginContainer.new()
	_home_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 18)
	margin.add_theme_constant_override("margin_right", 18)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	_home_screen.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	# 1. Top Stats Bar (Cozy Bakery Pills)
	var top_hbox := HBoxContainer.new()
	top_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	top_hbox.add_theme_constant_override("separation", 8)
	vbox.add_child(top_hbox)
	_home_anim_cards.append(top_hbox)

	var streak_pair := _make_header_stat_pill(_get_ui_tex("pop_icon_fire"), Color("#FFE4E5"), Color("#D88A92"), Color("#A94B5A"), Vector2(24, 24))
	streak_pair[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(streak_pair[0])
	_home_streak_label = streak_pair[1]

	var trophy_pair := _make_header_stat_pill(_get_ui_tex("rank_activity_award_podium_gold"), Color("#FCE6A9"), Color("#C99B4F"), Color("#815722"), Vector2(24, 24))
	trophy_pair[0].size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top_hbox.add_child(trophy_pair[0])
	_home_trophy_label = trophy_pair[1]

	var hint_pair := _make_header_stat_pill(_get_ui_tex("game_icon_hint_lamp"), Color("#FFF4DC"), Color("#C19C4C"), Color("#815722"), Vector2(24, 24))
	top_hbox.add_child(hint_pair[0])
	_home_hints_label = hint_pair[1]

	var carrot_pair := _make_header_stat_pill(_carrot_tex, Color("#E4EBD6"), Color("#A7BB8D"), Color("#506B43"), Vector2(24, 24))
	top_hbox.add_child(carrot_pair[0])
	_home_carrots_label = carrot_pair[1]

	var snd_btn := Button.new()
	snd_btn.set_meta("telemetry_id", "sound_toggle")
	snd_btn.custom_minimum_size = Vector2(46, 42)
	_style_tactile_button(snd_btn, PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, PALETTE.text_main, 16, 4, 6, 4)
	var snd_hb := CenterContainer.new()
	snd_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	snd_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	snd_btn.add_child(snd_hb)
	_home_sound_icon = _make_icon_rect(_get_ui_tex("icon_sound_on"), Vector2(26, 26))
	snd_hb.add_child(_home_sound_icon)
	snd_btn.pressed.connect(_toggle_audio)
	top_hbox.add_child(snd_btn)

	# 2. Hero Mascot & Woodland Bakery Banner Card (Featuring ChatGPT's 3D BUNDOKU Logo!)
	var hero_panel := PanelContainer.new()
	hero_panel.add_theme_stylebox_override("panel", _make_card_style(Color(1.0, 0.976, 0.925, 0.92), PALETTE.card_border, 22, 4, 8, 14, 12, true))
	vbox.add_child(hero_panel)
	_home_anim_cards.append(hero_panel)

	var hero_vbox := VBoxContainer.new()
	hero_vbox.add_theme_constant_override("separation", 8)
	hero_panel.add_child(hero_vbox)

	if _logo_tex != null:
		var logo_rect := _make_icon_rect(_logo_tex, Vector2(0, 142))
		logo_rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hero_vbox.add_child(logo_rect)
	else:
		var banner_panel := PanelContainer.new()
		banner_panel.add_theme_stylebox_override("panel", _make_card_style(Color("#F7D48A"), Color("#C18D45"), 18, 3, 5, 16, 10, false))
		hero_vbox.add_child(banner_panel)
		var main_title := _make_label("BUNDOKU", 38, Color("#FFF4DC"), true, 4, Color("#805334"), 3, Color("#73563B"))
		main_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		banner_panel.add_child(main_title)

	var speech_well := PanelContainer.new()
	speech_well.add_theme_stylebox_override("panel", _make_recessed_style(Color("#F4E9D6"), Color("#CBAE83"), 14, 12, 8))
	hero_vbox.add_child(speech_well)

	_home_speech_label = _make_label(str(Loc.quotes()[0]), 13, PALETTE.text_main, false)
	_home_speech_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_home_speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	speech_well.add_child(_home_speech_label)

	# 3. Main Action Buttons Row (Carrot Orange Primary CTA + Berry Pink Daily + Honey Gold League)
	var action_hbox := HBoxContainer.new()
	action_hbox.add_theme_constant_override("separation", 10)
	vbox.add_child(action_hbox)
	_home_anim_cards.append(action_hbox)

	var play_btn := Button.new()
	play_btn.set_meta("telemetry_id", "play")
	play_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	play_btn.custom_minimum_size = Vector2(0, 62)
	_style_tactile_button(play_btn, PALETTE.carrot_face, PALETTE.carrot_border, PALETTE.carrot_lip, PALETTE.text_light, 20, 7, 14, 8)
	var play_hb := HBoxContainer.new()
	play_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	play_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	play_hb.add_theme_constant_override("separation", 8)
	play_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_btn.add_child(play_hb)
	if _get_ui_tex("icon_play") != null:
		play_hb.add_child(_make_icon_rect(_get_ui_tex("icon_play"), Vector2(26, 26)))
	elif _bunny_idle_tex != null:
		play_hb.add_child(_make_icon_rect(_bunny_idle_tex, Vector2(32, 32)))
	_home_play_btn_label = _make_label(Loc.t("play_level") % (GameState.unlocked_level_index + 1), 20, Color("#FFF9EC"), true, 2, Color("#A94E27"), 2, Color("#A94E27"))
	_home_play_btn_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	play_hb.add_child(_home_play_btn_label)
	play_btn.pressed.connect(func():
		SoundManager.play("click")
		start_level(GameState.unlocked_level_index)
	)
	action_hbox.add_child(play_btn)

	var daily_btn := Button.new()
	daily_btn.set_meta("telemetry_id", "daily")
	daily_btn.custom_minimum_size = Vector2(118, 62)
	_style_tactile_button(daily_btn, PALETTE.berry_face, PALETTE.berry_border, PALETTE.berry_lip, Color.WHITE, 20, 7, 10, 8)
	var daily_hb := HBoxContainer.new()
	daily_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	daily_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	daily_hb.add_theme_constant_override("separation", 6)
	daily_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_btn.add_child(daily_hb)
	if _get_ui_tex("pop_icon_fire") != null:
		daily_hb.add_child(_make_icon_rect(_get_ui_tex("pop_icon_fire"), Vector2(24, 24)))
	var daily_lbl := _make_label(Loc.t("daily"), 16, Color.WHITE, true, 2, Color("#A83D60"), 2, Color("#A83D60"))
	daily_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	daily_hb.add_child(daily_lbl)
	daily_btn.pressed.connect(func():
		SoundManager.play("click")
		var daily_idx: int = (int(Time.get_date_dict_from_system().get("day", 1)) * 7) % maxi(1, GameState.get_level_count())
		# Never jump ahead of unlocked progress: the level grid would show it locked
		# and completing it used to unlock everything up to it.
		start_level(mini(daily_idx, GameState.unlocked_level_index), "daily")
	)
	action_hbox.add_child(daily_btn)

	var league_btn := Button.new()
	league_btn.set_meta("telemetry_id", "league")
	league_btn.custom_minimum_size = Vector2(96, 62)
	_style_tactile_button(league_btn, Color("#FCE6A9"), Color("#C99B4F"), Color("#D4B98F"), PALETTE.text_main, 20, 7, 10, 8)
	var lg_hb := HBoxContainer.new()
	lg_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	lg_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	lg_hb.add_theme_constant_override("separation", 6)
	lg_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	league_btn.add_child(lg_hb)
	if _get_ui_tex("rank_activity_award_podium_gold") != null:
		lg_hb.add_child(_make_icon_rect(_get_ui_tex("rank_activity_award_podium_gold"), Vector2(24, 24)))
	var lg_lbl := _make_label(Loc.t("league"), 16, PALETTE.text_main, true, 1, Color("#FFF4DC"), 1)
	lg_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lg_hb.add_child(lg_lbl)
	league_btn.pressed.connect(func():
		SoundManager.play("click")
		_show_league_modal()
	)
	action_hbox.add_child(league_btn)

	# 4. Level Selection Card (Clean Commercial Chapters View — No Dev Buttons)
	var lvl_panel := PanelContainer.new()
	lvl_panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	lvl_panel.add_theme_stylebox_override("panel", _make_card_style(Color(1.0, 0.976, 0.925, 0.90), PALETTE.card_border, 22, 4, 8, 16, 14, true))
	vbox.add_child(lvl_panel)
	_home_anim_cards.append(lvl_panel)

	var lvl_vbox := VBoxContainer.new()
	lvl_vbox.add_theme_constant_override("separation", 10)
	lvl_panel.add_child(lvl_vbox)

	var lvl_hdr_hbox := HBoxContainer.new()
	lvl_hdr_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	lvl_hdr_hbox.add_theme_constant_override("separation", 8)
	lvl_vbox.add_child(lvl_hdr_hbox)

	if _get_ui_tex("game_pattern_icon_pattern_paw") != null:
		lvl_hdr_hbox.add_child(_make_icon_rect(_get_ui_tex("game_pattern_icon_pattern_paw"), Vector2(22, 22), Color("#A98762")))

	var lvl_hdr := _make_label(Loc.t("chapters"), 18, PALETTE.text_main, true, 1, Color("#FFF4DC"), 1)
	lvl_hdr.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvl_hdr_hbox.add_child(lvl_hdr)

	var lang_btn := Button.new()
	lang_btn.set_meta("telemetry_id", "language")
	lang_btn.text = "🌐 " + Loc.get_short_code()
	lang_btn.custom_minimum_size = Vector2(74, 34)
	_style_tactile_button(lang_btn, PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, PALETTE.text_main, 12, 3, 10, 2)
	lang_btn.pressed.connect(func():
		SoundManager.play("click")
		_show_language_modal()
	)
	lvl_hdr_hbox.add_child(lang_btn)

	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	lvl_vbox.add_child(scroll)

	var grid_margin := MarginContainer.new()
	grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	grid_margin.add_theme_constant_override("margin_top", 6)
	grid_margin.add_theme_constant_override("margin_bottom", 10)
	grid_margin.add_theme_constant_override("margin_left", 4)
	grid_margin.add_theme_constant_override("margin_right", 8)
	scroll.add_child(grid_margin)

	_level_grid = GridContainer.new()
	_level_grid.columns = 4
	_level_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_level_grid.mouse_filter = Control.MOUSE_FILTER_PASS
	_level_grid.add_theme_constant_override("h_separation", 10)
	_level_grid.add_theme_constant_override("v_separation", 10)
	grid_margin.add_child(_level_grid)

func _populate_level_grid() -> void:
	for child in _level_grid.get_children():
		_level_grid.remove_child(child)
		child.queue_free()

	var total := GameState.get_level_count()
	var star_tex := _get_ui_tex("common_small_star")
	var lock_tex := _get_ui_tex("home_lock")

	for idx in range(total):
		var lv := GameState.get_level(idx)
		var sz: int = int(lv.get("size", 5))
		var tier: String = str(lv.get("tier", "easy"))
		var is_unlocked := (idx <= GameState.unlocked_level_index)
		var comp_info: Dictionary = GameState.completed_levels.get(idx, {})
		var stars: int = int(comp_info.get("stars", 0))

		var btn := Button.new()
		btn.set_meta("telemetry_id", "level_%d" % (idx + 1))
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.custom_minimum_size = Vector2(105, 72)
		btn.mouse_filter = Control.MOUSE_FILTER_PASS

		var face_col := PALETTE.cream_face
		var brd_col := PALETTE.card_border
		var lip_col := PALETTE.cream_lip
		if idx == GameState.unlocked_level_index and stars == 0:
			face_col = Color("#FFE7BA")
			brd_col = PALETTE.carrot_border
			lip_col = PALETTE.carrot_lip
		elif stars > 0:
			face_col = PALETTE.sage_face
			brd_col = PALETTE.sage_border
			lip_col = Color("#A7BB8D")

		_style_tactile_button(btn, face_col, brd_col, lip_col, PALETTE.text_main, 16, 5, 6, 6)
		btn.disabled = not is_unlocked

		var inner_vbox := VBoxContainer.new()
		inner_vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		inner_vbox.alignment = BoxContainer.ALIGNMENT_CENTER
		inner_vbox.add_theme_constant_override("separation", 3)
		inner_vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
		btn.add_child(inner_vbox)

		var top_lbl := _make_label(
			"%d" % (idx + 1),
			20,
			PALETTE.text_main if is_unlocked else Color("#8E8579"),
			true,
			1 if is_unlocked else 0,
			Color("#FFF9EC"),
			1 if is_unlocked else 0
		)
		top_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		top_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner_vbox.add_child(top_lbl)

		if stars > 0 and star_tex != null:
			var star_row := HBoxContainer.new()
			star_row.alignment = BoxContainer.ALIGNMENT_CENTER
			star_row.add_theme_constant_override("separation", 3)
			star_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
			for s in range(stars):
				star_row.add_child(_make_icon_rect(star_tex, Vector2(18, 18)))
			inner_vbox.add_child(star_row)
		elif is_unlocked:
			var tier_lbl := _make_label("%d×%d %s" % [sz, sz, _tier_tr(tier)], 11, _tier_color(tier), false)
			tier_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			tier_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
			inner_vbox.add_child(tier_lbl)
		else:
			if lock_tex != null:
				var lock_center := CenterContainer.new()
				lock_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
				lock_center.add_child(_make_icon_rect(lock_tex, Vector2(20, 20), Color(1, 1, 1, 0.88)))
				inner_vbox.add_child(lock_center)

		var captured_idx := idx
		btn.pressed.connect(func():
			SoundManager.play("click")
			start_level(captured_idx)
		)
		_level_grid.add_child(btn)

func _tier_tr(tier: String) -> String:
	match tier.to_lower():
		"easy": return Loc.t("tier_easy")
		"medium": return Loc.t("tier_medium")
		"hard": return Loc.t("tier_hard")
		"expert", "super_hard": return Loc.t("tier_expert")
		_: return Loc.t("tier_normal")

func _tier_color(tier: String) -> Color:
	match tier.to_lower():
		"easy": return Color("#526A40")
		"medium": return Color("#A94E27")
		"hard": return Color("#A83D60")
		"expert", "super_hard": return Color("#6A1B9A")
		_: return PALETTE.text_sec

func _make_rule_pill(diag_key: String, line1: String, line2: String, bg_col: Color, _brd_col: Color, txt_col: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	pill.custom_minimum_size = Vector2(0, 50)
	var tile_key := _pick_chatgpt_container_key(bg_col, false, true)
	pill.add_theme_stylebox_override("panel", _make_9slice_style(tile_key, 16, 14, 8, 7))

	var hb := HBoxContainer.new()
	hb.alignment = BoxContainer.ALIGNMENT_CENTER
	hb.add_theme_constant_override("separation", 7)
	pill.add_child(hb)

	var tex := _get_ui_tex(diag_key)
	if tex != null:
		hb.add_child(_make_icon_rect(tex, Vector2(36, 36)))

	var vb := VBoxContainer.new()
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", -2)
	hb.add_child(vb)

	var l1 := _make_label(line1, 12, txt_col, false, 0, Color.TRANSPARENT, 1)
	var l2 := _make_label(line2, 13, txt_col.darkened(0.15), true, 0, Color.TRANSPARENT, 1)
	vb.add_child(l1)
	vb.add_child(l2)
	return pill

func _make_tool_button(
	icon_tex: Texture2D,
	caption: String,
	face_col: Color,
	border_col: Color,
	lip_col: Color,
	with_badge: bool = false,
	icon_tint: Color = Color.WHITE
) -> Dictionary:
	var btn := Button.new()
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.custom_minimum_size = Vector2(0, 78)
	_style_tactile_button(btn, face_col, border_col, lip_col, PALETTE.text_main, 17, 6, 4, 6)

	var vb := VBoxContainer.new()
	vb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vb.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_theme_constant_override("separation", 3)
	vb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(vb)

	var icon_center := CenterContainer.new()
	icon_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(icon_center)

	var icon_rect := _make_icon_rect(icon_tex, Vector2(34, 34), icon_tint)
	icon_center.add_child(icon_rect)

	var cap_lbl := _make_label(caption, 13, PALETTE.text_main, false, 0, Color.TRANSPARENT, 1)
	cap_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cap_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(cap_lbl)

	var badge_lbl: Label = null
	if with_badge:
		var badge_panel := PanelContainer.new()
		badge_panel.custom_minimum_size = Vector2(24, 24)
		badge_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
		badge_panel.offset_left = -26
		badge_panel.offset_top = 3
		badge_panel.offset_right = -2
		badge_panel.offset_bottom = 27
		badge_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_theme_stylebox_override("panel", _make_card_style(PALETTE.carrot_face, PALETTE.carrot_border, 12, 2, 2, 4, 0, false))
		btn.add_child(badge_panel)

		badge_lbl = _make_label("0", 12, PALETTE.text_light, true, 1, PALETTE.carrot_border)
		badge_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge_panel.add_child(badge_lbl)

	return {
		"button": btn,
		"icon": icon_rect,
		"caption": cap_lbl,
		"badge": badge_lbl
	}

func _build_game_screen() -> void:
	_game_anim_cards.clear()

	var margin := MarginContainer.new()
	_game_margin = margin
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	_game_screen.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	margin.add_child(vbox)

	# 1. Header Card (Cozy 3D Raised Card with Level Badge, Hearts Pill, Timer Pill)
	var hdr_panel := PanelContainer.new()
	hdr_panel.add_theme_stylebox_override("panel", _make_card_style(PALETTE.card_face, PALETTE.card_border, 18, 3, 6, 12, 8, true))
	vbox.add_child(hdr_panel)
	_game_anim_cards.append(hdr_panel)

	var hdr_vbox := VBoxContainer.new()
	hdr_vbox.add_theme_constant_override("separation", 6)
	hdr_panel.add_child(hdr_vbox)

	var top_row := HBoxContainer.new()
	top_row.alignment = BoxContainer.ALIGNMENT_CENTER
	top_row.add_theme_constant_override("separation", 8)
	hdr_vbox.add_child(top_row)

	var back_btn := Button.new()
	back_btn.custom_minimum_size = Vector2(44, 40)
	_style_tactile_button(back_btn, Color("#FFF6E6"), PALETTE.card_border, PALETTE.card_lip, PALETTE.text_main, 14, 4, 4, 4)
	var back_icon := _get_ui_tex("common_icon_back")
	if back_icon != null:
		var bc := CenterContainer.new()
		bc.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		bc.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bc.add_child(_make_icon_rect(back_icon, Vector2(24, 24), Color.WHITE))
		back_btn.add_child(bc)
	back_btn.pressed.connect(func():
		SoundManager.play("click")
		_show_home_screen()
	)
	top_row.add_child(back_btn)

	# Level Badge Ribbon
	var lvl_badge := PanelContainer.new()
	lvl_badge.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	lvl_badge.custom_minimum_size = Vector2(0, 44)
	var ribbon_style := _make_9slice_style("ribbon_gold", 42, 10, 26, 6, Color.WHITE, 4, 8)
	if ribbon_style != null:
		lvl_badge.add_theme_stylebox_override("panel", ribbon_style)
	else:
		lvl_badge.add_theme_stylebox_override("panel", _make_card_style(Color("#F7D48A"), Color("#C18D45"), 14, 2, 3, 12, 4, false))
	top_row.add_child(lvl_badge)

	_level_title_label = _make_label(Loc.t("level_header") % [1, 5, 5, _tier_tr("easy")], 17, Color("#704A27"), true, 1, Color("#FFF4DC"), 1)
	_level_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_level_title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lvl_badge.add_child(_level_title_label)

	# Timer Pill (#E4EBD6 / #A7BB8D)
	var timer_pill := PanelContainer.new()
	timer_pill.custom_minimum_size = Vector2(0, 40)
	timer_pill.add_theme_stylebox_override("panel", _make_9slice_style("btn_pill_green_sm", 18, 12, 12, 6))
	top_row.add_child(timer_pill)

	var timer_hbox := HBoxContainer.new()
	timer_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	timer_hbox.add_theme_constant_override("separation", 5)
	timer_pill.add_child(timer_hbox)

	var timer_tex := _get_ui_tex("game_icon_timer")
	if timer_tex != null:
		timer_hbox.add_child(_make_icon_rect(timer_tex, Vector2(22, 22)))

	_timer_label = _make_label("00:00", 15, Color("#506B43"), true)
	timer_hbox.add_child(_timer_label)

	var game_snd_btn := Button.new()
	game_snd_btn.set_meta("telemetry_id", "sound_toggle")
	game_snd_btn.custom_minimum_size = Vector2(44, 40)
	_style_tactile_button(game_snd_btn, Color("#FFF6E6"), PALETTE.card_border, PALETTE.card_lip, PALETTE.text_main, 14, 4, 4, 4)
	var gs_center := CenterContainer.new()
	gs_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	gs_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	game_snd_btn.add_child(gs_center)
	_game_sound_icon = _make_icon_rect(_get_ui_tex("icon_sound_on"), Vector2(24, 24))
	gs_center.add_child(_game_sound_icon)
	game_snd_btn.pressed.connect(_toggle_audio)
	top_row.add_child(game_snd_btn)

	# Sub-row: Hearts Pill (#FFE4E5 / #D88A92) + Auto-X Toggle + Pattern Toggle
	var sub_row := HBoxContainer.new()
	sub_row.alignment = BoxContainer.ALIGNMENT_CENTER
	sub_row.add_theme_constant_override("separation", 8)
	hdr_vbox.add_child(sub_row)

	var hearts_pill := PanelContainer.new()
	hearts_pill.custom_minimum_size = Vector2(0, 38)
	hearts_pill.add_theme_stylebox_override("panel", _make_9slice_style("btn_pill_pink_sm", 18, 12, 12, 6))
	sub_row.add_child(hearts_pill)

	var hearts_hbox := HBoxContainer.new()
	hearts_hbox.add_theme_constant_override("separation", 5)
	hearts_pill.add_child(hearts_hbox)

	_heart_icons.clear()
	var heart_tex := _get_ui_tex("common_love_heart")
	for i in range(3):
		var hr := _make_icon_rect(heart_tex, Vector2(24, 24))
		hearts_hbox.add_child(hr)
		_heart_icons.append(hr)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sub_row.add_child(spacer)

	# Auto-X Toggle
	_auto_x_btn = Button.new()
	_auto_x_btn.set_meta("telemetry_id", "auto_x_toggle")
	_auto_x_btn.custom_minimum_size = Vector2(120, 34)
	var ax_hb := HBoxContainer.new()
	ax_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	ax_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	ax_hb.add_theme_constant_override("separation", 5)
	ax_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_auto_x_btn.add_child(ax_hb)
	if _get_ui_tex("game_btn_auto_mark_1") != null:
		ax_hb.add_child(_make_icon_rect(_get_ui_tex("game_btn_auto_mark_1"), Vector2(16, 16)))
	_auto_x_lbl = _make_label(Loc.t("auto_x_on"), 12, PALETTE.sage_text, false)
	_auto_x_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ax_hb.add_child(_auto_x_lbl)
	_auto_x_btn.pressed.connect(func():
		GameState.auto_cross_enabled = not GameState.auto_cross_enabled
		GameState.save_game()
		SoundManager.play("click")
		_refresh_settings_buttons()
		Telemetry.track("setting_changed", {"setting": "auto_cross", "value": int(GameState.auto_cross_enabled)})
	)
	sub_row.add_child(_auto_x_btn)

	# Pattern Mode Toggle
	_pattern_btn = Button.new()
	_pattern_btn.set_meta("telemetry_id", "pattern_toggle")
	_pattern_btn.custom_minimum_size = Vector2(124, 34)
	var pt_hb := HBoxContainer.new()
	pt_hb.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	pt_hb.alignment = BoxContainer.ALIGNMENT_CENTER
	pt_hb.add_theme_constant_override("separation", 5)
	pt_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_pattern_btn.add_child(pt_hb)
	if _get_ui_tex("game_pattern_icon_pattern_paw") != null:
		pt_hb.add_child(_make_icon_rect(_get_ui_tex("game_pattern_icon_pattern_paw"), Vector2(18, 18), Color("#8C4D69")))
	_pattern_lbl = _make_label(Loc.t("pattern_off"), 12, Color("#8C4D69"), false)
	_pattern_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pt_hb.add_child(_pattern_lbl)
	_pattern_btn.pressed.connect(func():
		GameState.pattern_mode_enabled = not GameState.pattern_mode_enabled
		GameState.save_game()
		GameState.settings_changed.emit()
		SoundManager.play("click")
		_refresh_settings_buttons()
		Telemetry.track("setting_changed", {"setting": "pattern", "value": int(GameState.pattern_mode_enabled)})
	)
	sub_row.add_child(_pattern_btn)

	# 2. Color-Coded Rule Indicator Pills (Section 2.5 of Design Spec)
	var rule_row := HBoxContainer.new()
	rule_row.add_theme_constant_override("separation", 7)
	vbox.add_child(rule_row)
	_game_anim_cards.append(rule_row)

	rule_row.add_child(_make_rule_pill("game_rule_diagram_color", Loc.t("rule1_a"), Loc.t("rule1_b"), Color("#DFE9CE"), Color("#A8BE8B"), Color("#526A40")))
	rule_row.add_child(_make_rule_pill("game_rule_diagram_line", Loc.t("rule2_a"), Loc.t("rule2_b"), Color("#D7E6F3"), Color("#93B5D1"), Color("#456B89")))
	rule_row.add_child(_make_rule_pill("game_rule_diagram_touch", Loc.t("rule3_a"), Loc.t("rule3_b"), Color("#F4D8E3"), Color("#D89BB5"), Color("#8C4D69")))

	# 3. Recessed Pastry-Mold Progress Well (Section 2.6 of Design Spec)
	var prog_panel := PanelContainer.new()
	prog_panel.add_theme_stylebox_override("panel", _make_recessed_style(PALETTE.well_bg, PALETTE.well_border, 16, 12, 6))
	vbox.add_child(prog_panel)
	_game_anim_cards.append(prog_panel)

	var prog_hbox := HBoxContainer.new()
	prog_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	prog_hbox.add_theme_constant_override("separation", 8)
	prog_panel.add_child(prog_hbox)

	_progress_slots_box = HBoxContainer.new()
	_progress_slots_box.alignment = BoxContainer.ALIGNMENT_CENTER
	_progress_slots_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_progress_slots_box.add_theme_constant_override("separation", 6)
	prog_hbox.add_child(_progress_slots_box)

	var count_badge := PanelContainer.new()
	count_badge.add_theme_stylebox_override("panel", _make_card_style(Color("#805334"), Color("#60452F"), 12, 1, 2, 10, 2, false))
	prog_hbox.add_child(count_badge)

	_progress_label = _make_label("0 / 5", 13, PALETTE.text_light, true)
	count_badge.add_child(_progress_label)

	# 4. Wooden Bakery Tray Board Section
	var board_card := PanelContainer.new()
	board_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var wood_style := _make_9slice_style("panel_wood_frame", 24, 18, 12, 12)
	if wood_style != null:
		board_card.add_theme_stylebox_override("panel", wood_style)
	else:
		board_card.add_theme_stylebox_override("panel", _make_card_style(PALETTE.card_face, PALETTE.card_border, 22, 4, 8, 10, 10, true))
	vbox.add_child(board_card)
	_game_anim_cards.append(board_card)

	_board_view = BoardView.new()
	_board_view.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_board_view.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_board_view.bunny_count_changed.connect(_on_bunny_count_changed)
	_board_view.mistake_made.connect(_on_mistake_made)
	_board_view.board_solved.connect(_on_board_solved)
	_board_view.draft_state_changed.connect(_on_draft_state_changed)
	_board_view.undo_availability_changed.connect(func(can_undo: bool):
		if _undo_btn != null:
			_undo_btn.disabled = not can_undo
	)
	board_card.add_child(_board_view)

	# 5. Draft Mode Action Bar
	_draft_bar = HBoxContainer.new()
	_draft_bar.visible = false
	_draft_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	_draft_bar.add_theme_constant_override("separation", 10)
	vbox.add_child(_draft_bar)

	var draft_apply_btn := Button.new()
	draft_apply_btn.text = Loc.t("draft_apply")
	draft_apply_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draft_apply_btn.custom_minimum_size = Vector2(0, 44)
	_style_tactile_button(draft_apply_btn, Color("#A6C98A"), Color("#526A40"), Color("#7FA362"), Color.WHITE, 14, 4, 12, 6)
	draft_apply_btn.pressed.connect(func(): _board_view.apply_draft())
	_draft_bar.add_child(draft_apply_btn)

	var draft_cancel_btn := Button.new()
	draft_cancel_btn.text = Loc.t("draft_cancel")
	draft_cancel_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	draft_cancel_btn.custom_minimum_size = Vector2(0, 44)
	_style_tactile_button(draft_cancel_btn, Color("#E98178"), Color("#913D3A"), Color("#B94E4B"), Color.WHITE, 14, 4, 12, 6)
	draft_cancel_btn.pressed.connect(func(): _board_view.cancel_draft())
	_draft_bar.add_child(draft_cancel_btn)

	# 6. Hint / Explanation Toast Panel
	_toast_panel = PanelContainer.new()
	_toast_panel.visible = false
	_toast_panel.add_theme_stylebox_override("panel", _make_card_style(Color("#FFF4DC"), Color("#C18D45"), 16, 3, 5, 12, 8, true))
	vbox.add_child(_toast_panel)

	var toast_hbox := HBoxContainer.new()
	toast_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	toast_hbox.add_theme_constant_override("separation", 10)
	_toast_panel.add_child(toast_hbox)

	var lamp_tex := _get_ui_tex("game_icon_hint_lamp")
	if lamp_tex != null:
		toast_hbox.add_child(_make_icon_rect(lamp_tex, Vector2(32, 32)))

	var toast_vbox := VBoxContainer.new()
	toast_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toast_vbox.add_theme_constant_override("separation", 2)
	toast_hbox.add_child(toast_vbox)

	_toast_title = _make_label(Loc.t("tool_hint"), 14, Color("#A94E27"), true)
	toast_vbox.add_child(_toast_title)

	_toast_body = _make_label("", 12, PALETTE.text_main, false)
	_toast_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_vbox.add_child(_toast_body)

	var toast_close_btn := Button.new()
	toast_close_btn.text = "✕"
	toast_close_btn.custom_minimum_size = Vector2(34, 34)
	toast_close_btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_style_tactile_button(toast_close_btn, Color("#F4E9D6"), PALETTE.card_border, PALETTE.card_lip, PALETTE.text_main, 10, 3, 4, 2)
	toast_close_btn.pressed.connect(func(): _toast_panel.visible = false)
	toast_hbox.add_child(toast_close_btn)

	# 7. Bottom Tools Row (Color-Coded Bakery Tool Buttons from Section 2.9 of Design Spec)
	var tools_hbox := HBoxContainer.new()
	tools_hbox.add_theme_constant_override("separation", 6)
	vbox.add_child(tools_hbox)
	_game_anim_cards.append(tools_hbox)

	var undo_dict := _make_tool_button(_get_ui_tex("game_icon_undo"), Loc.t("tool_undo"), Color("#E6D7BC"), Color("#A98762"), Color("#CBAE83"), false)
	_undo_btn = undo_dict["button"]
	_undo_btn.set_meta("telemetry_id", "undo")
	_undo_btn.pressed.connect(func(): _board_view.undo_move())
	tools_hbox.add_child(_undo_btn)

	var clear_dict := _make_tool_button(_get_ui_tex("icon_broom"), Loc.t("tool_clear"), Color("#F1C4BA"), Color("#C27B6D"), Color("#D88D80"), false, Color.WHITE)
	var clear_btn: Button = clear_dict["button"]
	clear_btn.set_meta("telemetry_id", "clear")
	clear_btn.pressed.connect(func():
		_toast_panel.visible = false
		_board_view.clear_board()
	)
	tools_hbox.add_child(clear_btn)

	var draft_dict := _make_tool_button(_get_ui_tex("game_icon_draft_pencil"), Loc.t("tool_draft"), Color("#D7E6F3"), Color("#93B5D1"), Color("#A6C2DC"), false)
	_draft_btn = draft_dict["button"]
	_draft_icon_rect = draft_dict["icon"]
	_draft_caption_lbl = draft_dict["caption"]
	_draft_btn.set_meta("telemetry_id", "draft")
	_draft_btn.pressed.connect(func(): _board_view.toggle_draft_mode())
	tools_hbox.add_child(_draft_btn)

	var hint_dict := _make_tool_button(_get_ui_tex("game_icon_hint_lamp"), Loc.t("tool_hint"), Color("#F2E3A9"), Color("#C19C4C"), Color("#D3B36D"), true)
	_hint_btn = hint_dict["button"]
	_hint_badge_lbl = hint_dict["badge"]
	_hint_btn.set_meta("telemetry_id", "hint")
	_hint_btn.pressed.connect(_on_hint_pressed)
	tools_hbox.add_child(_hint_btn)

	var carrot_dict := _make_tool_button(_carrot_tex, Loc.t("tool_carrot"), Color("#F4D0AD"), Color("#C18D45"), Color("#D8A46F"), true)
	_carrot_btn = carrot_dict["button"]
	_carrot_badge_lbl = carrot_dict["badge"]
	_carrot_btn.set_meta("telemetry_id", "carrot")
	_carrot_btn.pressed.connect(_on_carrot_pressed)
	tools_hbox.add_child(_carrot_btn)

	var mode_dict := _make_tool_button(_get_ui_tex("game_icon_mark_white_brush"), Loc.t("tool_first_x"), PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, false, PALETTE.text_main)
	_mode_btn = mode_dict["button"]
	_mode_icon_rect = mode_dict["icon"]
	_mode_caption_lbl = mode_dict["caption"]
	_mode_btn.set_meta("telemetry_id", "mode_toggle")
	_mode_btn.pressed.connect(func():
		GameState.bunny_first_tap_mode = not GameState.bunny_first_tap_mode
		GameState.save_game()
		SoundManager.play("click")
		_refresh_settings_buttons()
		Telemetry.track("setting_changed", {"setting": "first_tap_mode", "value": int(GameState.bunny_first_tap_mode)})
	)
	tools_hbox.add_child(_mode_btn)

func _toggle_audio() -> void:
	var new_state: bool = not SoundManager.sound_enabled
	SoundManager.sound_enabled = new_state
	SoundManager.set_music_enabled(new_state)
	GameState.save_game()
	if new_state:
		SoundManager.play("click")
	_refresh_settings_buttons()
	Telemetry.track("setting_changed", {"setting": "sound", "value": int(new_state)})

func _show_home_screen() -> void:
	if _is_playing and _game_screen.visible:
		Telemetry.track("level_abandon", {
			"level": _active_level_idx + 1,
			"seconds": _elapsed_sec,
			"mistakes": _mistakes,
			"placed": _last_placed_count,
		})
	Telemetry.set_screen("home")
	_is_playing = false
	_ad_is_active = false
	_apply_safe_area_margins()
	_home_screen.visible = true
	_game_screen.visible = false
	_dismiss_modal()
	var q := Loc.quotes()
	_home_speech_label.text = str(q[randi() % q.size()])
	_refresh_all_ui()
	_populate_level_grid()
	_animate_cards_enter(_home_anim_cards)

func start_level(idx: int, source: String = "campaign") -> void:
	_active_level_idx = clampi(idx, 0, GameState.get_level_count() - 1)
	GameState.current_level_index = _active_level_idx
	var lv := GameState.get_level(_active_level_idx)
	var sz: int = int(lv.get("size", 5))
	var raw_tier: String = str(lv.get("tier", "easy"))
	var tier_tr: String = _tier_tr(raw_tier)
	var prefill_arr: Array = lv.get("prefillPositions", [])
	Telemetry.set_screen("game")
	Telemetry.set_level_context(_active_level_idx + 1)
	Telemetry.track("level_start", {
		"level": _active_level_idx + 1,
		"size": sz,
		"tier": raw_tier,
		"source": source,
		"prefill": prefill_arr.size(),
		"unlocked": GameState.unlocked_level_index + 1,
	})

	_lives = 3
	_mistakes = 0
	_elapsed_sec = 0
	_timer_accum = 0.0
	# -1 forces the first bunny_count_changed from setup_level() to rebuild the slot
	# row, even for levels without prefilled bunnies.
	_last_placed_count = -1
	_is_playing = true
	_ad_is_active = false

	_apply_safe_area_margins()
	_home_screen.visible = false
	_game_screen.visible = true
	_dismiss_modal()
	_toast_panel.visible = false

	_level_title_label.text = Loc.t("level_header") % [_active_level_idx + 1, sz, sz, tier_tr]
	_update_timer_label()
	_update_lives_label()
	_refresh_settings_buttons()
	_refresh_booster_buttons()
	_board_view.setup_level(lv)
	_animate_cards_enter(_game_anim_cards)

func _update_lives_label() -> void:
	for i in range(_heart_icons.size()):
		var hr := _heart_icons[i]
		if i < _lives:
			hr.modulate = Color.WHITE
		else:
			hr.modulate = Color(0.45, 0.35, 0.35, 0.30)

func _rebuild_progress_slots(placed: int, total: int) -> void:
	if _progress_slots_box == null:
		return
	for c in _progress_slots_box.get_children():
		_progress_slots_box.remove_child(c)
		c.queue_free()

	var slot_px := clampf(290.0 / float(maxi(4, total)), 26.0, 36.0)

	for i in range(total):
		var is_filled := (i < placed)
		var well := PanelContainer.new()
		well.custom_minimum_size = Vector2(slot_px, slot_px)
		if is_filled:
			well.add_theme_stylebox_override("panel", _make_card_style(PALETTE.slot_filled, PALETTE.slot_filled_border, int(slot_px * 0.34), 2, 3, 2, 2, false))
		else:
			well.add_theme_stylebox_override("panel", _make_card_style(PALETTE.slot_empty, PALETTE.slot_empty_border, int(slot_px * 0.34), 2, 2, 2, 2, false))

		var center := CenterContainer.new()
		center.mouse_filter = Control.MOUSE_FILTER_IGNORE
		well.add_child(center)

		if is_filled and _bunny_idle_tex != null:
			center.add_child(_make_icon_rect(_bunny_idle_tex, Vector2(slot_px * 0.78, slot_px * 0.78)))
		else:
			var dot_tex := _get_ui_tex("game_cat_progress_dot")
			if dot_tex != null:
				center.add_child(_make_icon_rect(dot_tex, Vector2(slot_px * 0.32, slot_px * 0.32), Color("#A98762")))

		_progress_slots_box.add_child(well)
		if is_filled and placed > _last_placed_count and i == placed - 1:
			_animate_slot_pop(well)

	_last_placed_count = placed
	if _progress_label != null:
		_progress_label.text = "%d / %d" % [placed, total]

func _refresh_settings_buttons() -> void:
	var snd_tex := _get_ui_tex("icon_sound_on" if SoundManager.sound_enabled else "icon_sound_off")
	if _home_sound_icon != null and snd_tex != null:
		_home_sound_icon.texture = snd_tex
	if _game_sound_icon != null and snd_tex != null:
		_game_sound_icon.texture = snd_tex

	if _auto_x_btn != null:
		if _auto_x_lbl != null:
			_auto_x_lbl.text = Loc.t("auto_x_on") if GameState.auto_cross_enabled else Loc.t("auto_x_off")
			_auto_x_lbl.label_settings.font_color = PALETTE.sage_text if GameState.auto_cross_enabled else PALETTE.text_main
		_style_tactile_button(
			_auto_x_btn,
			PALETTE.sage_face if GameState.auto_cross_enabled else Color("#F4E9D6"),
			PALETTE.sage_border if GameState.auto_cross_enabled else PALETTE.card_border,
			Color("#A7BB8D") if GameState.auto_cross_enabled else PALETTE.card_lip,
			PALETTE.sage_text if GameState.auto_cross_enabled else PALETTE.text_main,
			12,
			3,
			8,
			2
		)
	if _pattern_btn != null:
		if _pattern_lbl != null:
			_pattern_lbl.text = Loc.t("pattern_on") if GameState.pattern_mode_enabled else Loc.t("pattern_off")
			_pattern_lbl.label_settings.font_color = Color("#8C4D69") if GameState.pattern_mode_enabled else PALETTE.text_main
		_style_tactile_button(
			_pattern_btn,
			Color("#F4D8E3") if GameState.pattern_mode_enabled else Color("#F4E9D6"),
			Color("#D89BB5") if GameState.pattern_mode_enabled else PALETTE.card_border,
			Color("#C95678") if GameState.pattern_mode_enabled else PALETTE.card_lip,
			Color("#8C4D69") if GameState.pattern_mode_enabled else PALETTE.text_main,
			12,
			3,
			8,
			2
		)
	if _mode_btn != null:
		if GameState.bunny_first_tap_mode:
			if _mode_icon_rect != null and _bunny_idle_tex != null:
				_mode_icon_rect.texture = _bunny_idle_tex
				_mode_icon_rect.modulate = Color.WHITE
			if _mode_caption_lbl != null:
				_mode_caption_lbl.text = Loc.t("tool_first_bunny")
				_mode_caption_lbl.label_settings.font_color = Color.WHITE
			_style_tactile_button(_mode_btn, PALETTE.berry_face, PALETTE.berry_border, PALETTE.berry_lip, Color.WHITE, 17, 6, 4, 6)
		else:
			var x_tex := _get_ui_tex("game_icon_mark_white_brush")
			if _mode_icon_rect != null and x_tex != null:
				_mode_icon_rect.texture = x_tex
				_mode_icon_rect.modulate = PALETTE.text_main
			if _mode_caption_lbl != null:
				_mode_caption_lbl.text = Loc.t("tool_first_x")
				_mode_caption_lbl.label_settings.font_color = PALETTE.text_main
			_style_tactile_button(_mode_btn, PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, PALETTE.text_main, 17, 6, 4, 6)

func _refresh_booster_buttons() -> void:
	if _hint_badge_lbl != null:
		_hint_badge_lbl.text = str(GameState.hints_count)
	if _carrot_badge_lbl != null:
		_carrot_badge_lbl.text = str(GameState.carrots_count)

func _refresh_all_ui() -> void:
	if _home_streak_label != null:
		_home_streak_label.text = Loc.t("streak_days") % GameState.streak_days
	if _home_trophy_label != null:
		_home_trophy_label.text = Loc.t("trophies") % GameState.player_trophies
	if _home_hints_label != null:
		_home_hints_label.text = str(GameState.hints_count)
	if _home_carrots_label != null:
		_home_carrots_label.text = str(GameState.carrots_count)
	if _home_play_btn_label != null:
		_home_play_btn_label.text = Loc.t("play_level") % (GameState.unlocked_level_index + 1)
	_refresh_booster_buttons()
	_refresh_settings_buttons()

func _on_bunny_count_changed(placed: int, total: int) -> void:
	# BoardView emits this twice per placement (place/remove + recheck); skip the
	# duplicate so the slot row is rebuilt once.
	if placed == _last_placed_count and _progress_slots_box != null and _progress_slots_box.get_child_count() == total:
		return
	_rebuild_progress_slots(placed, total)

func _on_draft_state_changed(is_draft: bool) -> void:
	if _draft_bar != null:
		_draft_bar.visible = is_draft
	if _draft_btn != null:
		var sel_tex := _get_ui_tex("game_icon_pencil_selected" if is_draft else "game_icon_draft_pencil")
		if _draft_icon_rect != null and sel_tex != null:
			_draft_icon_rect.texture = sel_tex
		if _draft_caption_lbl != null:
			_draft_caption_lbl.text = Loc.t("tool_confirm") if is_draft else Loc.t("tool_draft")
			_draft_caption_lbl.label_settings.font_color = Color.WHITE if is_draft else PALETTE.text_main
		_style_tactile_button(
			_draft_btn,
			PALETTE.berry_face if is_draft else Color("#D7E6F3"),
			PALETTE.berry_border if is_draft else Color("#93B5D1"),
			PALETTE.berry_lip if is_draft else Color("#A6C2DC"),
			Color.WHITE if is_draft else PALETTE.text_main,
			17,
			6,
			4,
			6
		)

func _show_toast(title: String, body: String) -> void:
	_toast_title.text = title
	_toast_body.text = body
	_toast_panel.visible = true

func _on_mistake_made(_cell: Vector2i, reason: String) -> void:
	_mistakes += 1
	var lost_idx := clampi(_lives - 1, 0, _heart_icons.size() - 1)
	_lives = maxi(0, _lives - 1)
	_update_lives_label()
	if lost_idx >= 0 and lost_idx < _heart_icons.size():
		_animate_heart_loss(_heart_icons[lost_idx])
	_show_toast(Loc.t("mistake_title"), reason)
	Telemetry.track("mistake", {
		"level": _active_level_idx + 1,
		"reason": reason,
		"lives_left": _lives,
		"mistakes_total": _mistakes,
	})
	if _lives <= 0:
		_is_playing = false
		_show_out_of_lives_modal()

func _on_hint_pressed() -> void:
	if GameState.hints_count <= 0:
		var on_hint_ad: Callable = func():
			GameState.add_free_boosters(2, 0)
			_show_toast(Loc.t("added_hint_title"), Loc.t("added_hint_msg"))
		_show_ad_modal(Loc.t("free_hint_title"), Loc.t("free_hint_sub"), on_hint_ad, "free_hint")
		return
	var res := _board_view.request_and_apply_hint()
	if not res.is_empty():
		GameState.use_hint()
		_show_toast(str(res.get("title", Loc.t("tool_hint"))), str(res.get("message", "")))
		Telemetry.track("booster_used", {
			"booster": "hint",
			"hint_type": str(res.get("type", "")),
			"hints_left": GameState.hints_count,
			"level": _active_level_idx + 1,
		})

func _on_carrot_pressed() -> void:
	if GameState.carrots_count <= 0:
		var on_carrot_ad: Callable = func():
			GameState.add_free_boosters(0, 2)
			_show_toast(Loc.t("added_carrot_title"), Loc.t("added_carrot_msg"))
		_show_ad_modal(Loc.t("free_carrot_title"), Loc.t("free_carrot_sub"), on_carrot_ad, "free_carrot")
		return
	var res := _board_view.apply_carrot_booster()
	if not res.is_empty():
		GameState.use_carrot()
		_show_toast(str(res.get("title", Loc.t("tool_carrot"))), str(res.get("message", "")))
		Telemetry.track("booster_used", {
			"booster": "carrot",
			"carrots_left": GameState.carrots_count,
			"level": _active_level_idx + 1,
		})

func _on_board_solved() -> void:
	_is_playing = false
	var reward := GameState.complete_level(_active_level_idx, _elapsed_sec, _mistakes)
	var show_ad: bool = bool(reward.get("show_interstitial_ad", false))
	if show_ad:
		_show_ad_modal(
			Loc.t("ad_break_title"),
			Loc.t("ad_break_sub"),
			func(): _show_win_modal(reward),
			"level_break"
		)
	else:
		_show_win_modal(reward)

func _dismiss_modal() -> void:
	if _modal_layer != null:
		_modal_layer.visible = false
		for c in _modal_layer.get_children():
			_modal_layer.remove_child(c)
			c.queue_free()
	_ad_is_active = false
	_ad_close_btn = null
	_ad_close_lbl = null
	_ad_progress_bar = null
	_ad_on_complete = Callable()

func _clear_modal() -> Dictionary:
	_dismiss_modal()
	_modal_layer.visible = true

	var dim := ColorRect.new()
	dim.color = Color(0.22, 0.15, 0.10, 0.68)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(dim)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(center)

	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(440, 0)
	card.add_theme_stylebox_override("panel", _make_card_style(PALETTE.card_face, PALETTE.card_border, 26, 5, 10, 22, 20, true))
	center.add_child(card)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	card.add_child(vbox)

	# Popup entrance animation
	card.modulate.a = 0.0
	card.scale = Vector2(0.86, 0.86)
	card.pivot_offset = Vector2(220, 150)
	var tw := card.create_tween()
	tw.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.set_parallel(true)
	tw.tween_property(card, "modulate:a", 1.0, 0.26)
	tw.tween_property(card, "scale", Vector2.ONE, 0.34)

	return {"card": card, "vbox": vbox}

func _show_ad_modal(ad_title: String, ad_subtitle: String, on_complete: Callable, placement: String = "unknown") -> void:
	_pending_ad_placement = placement
	_pending_ad_on_complete = on_complete
	_pending_ad_reward_earned = false
	Telemetry.track("ad_offered", {"placement": placement, "format": _ad_format_for_placement(placement), "level": _active_level_idx + 1})

	var real_shown := false
	if Ads.is_supported():
		if placement == "level_break":
			real_shown = Ads.show_interstitial(placement)
		elif placement == "free_hint" or placement == "free_carrot" or placement == "revive":
			real_shown = Ads.show_rewarded(placement)
	if real_shown:
		_ad_is_active = true # keep the level timer paused while the full-screen ad plays
		Telemetry.track("ad_shown", {
			"placement": placement,
			"format": _ad_format_for_placement(placement),
			"simulated": 0,
			"level": _active_level_idx + 1,
		})
		Telemetry.set_screen("ad")
		return

	_show_simulated_ad_modal(ad_title, ad_subtitle, placement)

func _ad_format_for_placement(placement: String) -> String:
	if placement == "free_hint" or placement == "free_carrot" or placement == "revive":
		return "rewarded"
	return "interstitial"

func _show_simulated_ad_modal(ad_title: String, ad_subtitle: String, placement: String) -> void:
	var modal := _clear_modal()
	var vbox: VBoxContainer = modal["vbox"]
	_ad_on_complete = _pending_ad_on_complete
	_ad_countdown_total = 3.0
	_ad_countdown_sec = 3.0
	_ad_is_active = true
	Telemetry.track("ad_shown", {"placement": placement, "format": "interstitial", "simulated": 1, "level": _active_level_idx + 1})
	Telemetry.set_screen("ad")

	var hdr := _make_label(ad_title, 24, PALETTE.text_main, true, 2, PALETTE.cream_face, 2)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	var ad_card := PanelContainer.new()
	ad_card.custom_minimum_size = Vector2(0, 154)
	var ad_wood_style := _make_9slice_style("panel_wood_frame", 24, 18, 16, 14)
	if ad_wood_style != null:
		ad_card.add_theme_stylebox_override("panel", ad_wood_style)
	else:
		ad_card.add_theme_stylebox_override("panel", _make_card_style(Color("#F7D48A"), Color("#C18D45"), 18, 3, 5, 16, 14, false))
	vbox.add_child(ad_card)

	var ad_vb := VBoxContainer.new()
	ad_vb.alignment = BoxContainer.ALIGNMENT_CENTER
	ad_vb.add_theme_constant_override("separation", 8)
	ad_card.add_child(ad_vb)

	var ad_icons := HBoxContainer.new()
	ad_icons.alignment = BoxContainer.ALIGNMENT_CENTER
	ad_icons.add_theme_constant_override("separation", 14)
	ad_vb.add_child(ad_icons)

	if _get_ui_tex("icon_ad_video") != null:
		ad_icons.add_child(_make_icon_rect(_get_ui_tex("icon_ad_video"), Vector2(54, 54)))
	if _bunny_idle_tex != null:
		ad_icons.add_child(_make_icon_rect(_bunny_idle_tex, Vector2(60, 60)))
	if _carrot_tex != null:
		ad_icons.add_child(_make_icon_rect(_carrot_tex, Vector2(54, 54)))

	var sponsor_lbl := _make_label(Loc.t("ad_sponsor"), 17, Color("#704A27"), true, 1, Color("#FFF4DC"), 1)
	sponsor_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_vb.add_child(sponsor_lbl)

	var sub_lbl := _make_label(ad_subtitle, 13, PALETTE.text_main, false)
	sub_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	sub_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ad_vb.add_child(sub_lbl)

	_ad_progress_bar = ProgressBar.new()
	_ad_progress_bar.min_value = 0.0
	_ad_progress_bar.max_value = 100.0
	_ad_progress_bar.value = 0.0
	_ad_progress_bar.show_percentage = false
	_ad_progress_bar.custom_minimum_size = Vector2(0, 14)
	_ad_progress_bar.add_theme_stylebox_override("background", _make_recessed_style(PALETTE.well_bg, PALETTE.well_border, 7, 0, 0))
	_ad_progress_bar.add_theme_stylebox_override("fill", _make_card_style(PALETTE.carrot_face, PALETTE.carrot_border, 7, 1, 0, 0, 0, false))
	vbox.add_child(_ad_progress_bar)

	_ad_close_btn = Button.new()
	_ad_close_btn.set_meta("telemetry_id", "ad_close")
	_ad_close_btn.custom_minimum_size = Vector2(0, 52)
	_ad_close_btn.disabled = true
	_style_tactile_button(_ad_close_btn, Color("#DCD5C8"), Color("#A99F90"), Color("#BEB4A4"), Color("#8E8579"), 18, 4, 12, 8)

	var close_center := CenterContainer.new()
	close_center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	close_center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ad_close_btn.add_child(close_center)

	_ad_close_lbl = _make_label(Loc.t("ad_wait_sec") % 3, 16, PALETTE.text_light, true, 2, PALETTE.carrot_border)
	_ad_close_lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
	close_center.add_child(_ad_close_lbl)

	_ad_close_btn.pressed.connect(func():
		SoundManager.play("click")
		Telemetry.track("ad_closed", {"placement": placement, "watched_sec": int(_ad_countdown_total)})
		_ad_is_active = false
		_modal_layer.visible = false
		if _ad_on_complete.is_valid():
			_ad_on_complete.call()
	)
	vbox.add_child(_ad_close_btn)

func _on_ads_ad_closed_signal(_format: String, placement: String, duration: int) -> void:
	_on_ads_ad_closed(placement, duration)

func _on_ads_ad_closed(placement: String, duration: int) -> void:
	_ad_is_active = false
	var format := _ad_format_for_placement(placement)
	Telemetry.track("ad_closed", {
		"placement": placement,
		"format": format,
		"watched_sec": duration,
		"simulated": 0,
		"level": _active_level_idx + 1,
	})
	var is_pending := placement == _pending_ad_placement
	# Rewarded placements only complete when the SDK granted the reward.
	var earned := format != "rewarded" or _pending_ad_reward_earned
	if is_pending and earned and _pending_ad_on_complete.is_valid():
		var on_complete := _pending_ad_on_complete
		_pending_ad_placement = ""
		_pending_ad_on_complete = Callable()
		_pending_ad_reward_earned = false
		on_complete.call()
	elif is_pending:
		_pending_ad_placement = ""
		_pending_ad_on_complete = Callable()
		_pending_ad_reward_earned = false
	Telemetry.set_screen("game" if _game_screen != null and _game_screen.visible else "home")

func _on_ads_ad_rewarded(placement: String, _amount: int, _reward_type: String) -> void:
	if placement == _pending_ad_placement:
		_pending_ad_reward_earned = true

func _on_ads_consent_finished(_can_request_ads: bool) -> void:
	# The privacy entry point is evaluated each time the language modal is built,
	# so nothing has to be rebuilt when consent resolves.
	pass

func _show_win_modal(reward: Dictionary) -> void:
	Telemetry.set_screen("result")
	var modal := _clear_modal()
	var vbox: VBoxContainer = modal["vbox"]

	var hdr := _make_label(Loc.t("win_title") % (_active_level_idx + 1), 24, PALETTE.text_main, true, 2, PALETTE.cream_face, 2)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	if _bunny_idle_tex != null:
		var m_center := CenterContainer.new()
		m_center.add_child(_make_icon_rect(_bunny_idle_tex, Vector2(68, 68)))
		vbox.add_child(m_center)

	var stars: int = int(reward.get("stars", 3))
	var big_star_tex := _get_ui_tex("common_big_star")
	if big_star_tex != null:
		var star_row := HBoxContainer.new()
		star_row.alignment = BoxContainer.ALIGNMENT_CENTER
		star_row.add_theme_constant_override("separation", 14)
		vbox.add_child(star_row)
		for i in range(3):
			var sr := _make_icon_rect(big_star_tex, Vector2(46, 56))
			if i >= stars:
				sr.modulate = Color(0.55, 0.48, 0.40, 0.30)
			else:
				sr.scale = Vector2.ZERO
				sr.pivot_offset = Vector2(23, 28)
				var stw := sr.create_tween()
				stw.tween_interval(0.15 + float(i) * 0.12)
				stw.tween_property(sr, "scale", Vector2(1.22, 1.22), 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
				stw.tween_property(sr, "scale", Vector2.ONE, 0.12)
			star_row.add_child(sr)

	var mins := _elapsed_sec / 60
	var secs := _elapsed_sec % 60
	var bonus_txt := ""
	if int(reward.get("bonus_hint", 0)) > 0:
		bonus_txt += Loc.t("bonus_hint")
	if int(reward.get("bonus_carrot", 0)) > 0:
		bonus_txt += Loc.t("bonus_carrot")

	var stats_well := PanelContainer.new()
	stats_well.add_theme_stylebox_override("panel", _make_recessed_style(Color("#F4E9D6"), Color("#CBAE83"), 14, 14, 10))
	vbox.add_child(stats_well)

	var stats_lbl := _make_label(
		Loc.t("win_stats") % [
			mins, secs, int(reward.get("trophy_gain", 20)), bonus_txt
		],
		15,
		PALETTE.text_main,
		false
	)
	stats_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_well.add_child(stats_lbl)

	var btn_row := HBoxContainer.new()
	btn_row.add_theme_constant_override("separation", 10)
	vbox.add_child(btn_row)

	var home_btn := Button.new()
	home_btn.set_meta("telemetry_id", "win_home")
	home_btn.text = Loc.t("home_menu")
	home_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	home_btn.custom_minimum_size = Vector2(0, 54)
	_style_tactile_button(home_btn, PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, PALETTE.text_main, 18, 6, 12, 8)
	home_btn.pressed.connect(func():
		SoundManager.play("click")
		_show_home_screen()
	)
	btn_row.add_child(home_btn)

	if _active_level_idx + 1 < GameState.get_level_count():
		var next_btn := Button.new()
		next_btn.set_meta("telemetry_id", "win_next")
		next_btn.text = Loc.t("next_level")
		next_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		next_btn.custom_minimum_size = Vector2(0, 54)
		_style_tactile_button(next_btn, PALETTE.carrot_face, PALETTE.carrot_border, PALETTE.carrot_lip, PALETTE.text_light, 18, 6, 12, 8)
		next_btn.pressed.connect(func():
			SoundManager.play("click")
			start_level(_active_level_idx + 1, "next")
		)
		btn_row.add_child(next_btn)

func _show_out_of_lives_modal() -> void:
	Telemetry.set_screen("out_of_lives")
	Telemetry.track("level_fail", {
		"level": _active_level_idx + 1,
		"reason": "out_of_lives",
		"seconds": _elapsed_sec,
		"mistakes": _mistakes,
	})
	var modal := _clear_modal()
	var vbox: VBoxContainer = modal["vbox"]

	var hdr := _make_label(Loc.t("out_of_lives_title"), 24, Color("#B74E4C"), true, 2, PALETTE.cream_face, 2)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	if _bunny_conflict_tex != null:
		var bc := CenterContainer.new()
		bc.add_child(_make_icon_rect(_bunny_conflict_tex, Vector2(64, 64)))
		vbox.add_child(bc)

	var desc := _make_label(
		Loc.t("out_of_lives_desc"),
		14,
		PALETTE.text_main,
		false
	)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)

	var revive_btn := Button.new()
	revive_btn.set_meta("telemetry_id", "revive")
	revive_btn.text = Loc.t("revive_btn")
	revive_btn.custom_minimum_size = Vector2(0, 54)
	_style_tactile_button(revive_btn, PALETTE.carrot_face, PALETTE.carrot_border, PALETTE.carrot_lip, PALETTE.text_light, 18, 6, 12, 8)
	revive_btn.pressed.connect(func():
		SoundManager.play("click")
		_show_ad_modal(Loc.t("revive_ad_title"), Loc.t("revive_ad_sub"), _on_revive_ad_completed, "revive")
	)
	vbox.add_child(revive_btn)

	var restart_btn := Button.new()
	restart_btn.set_meta("telemetry_id", "restart")
	restart_btn.text = Loc.t("restart_btn")
	restart_btn.custom_minimum_size = Vector2(0, 48)
	_style_tactile_button(restart_btn, PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, PALETTE.text_main, 18, 5, 12, 8)
	restart_btn.pressed.connect(func():
		SoundManager.play("click")
		start_level(_active_level_idx, "retry")
	)
	vbox.add_child(restart_btn)

func _on_revive_ad_completed() -> void:
	SoundManager.play("carrot")
	_lives = 3
	_update_lives_label()
	_is_playing = true
	_modal_layer.visible = false
	_board_view.request_and_apply_hint()

func _show_league_modal() -> void:
	Telemetry.set_screen("league")
	var modal := _clear_modal()
	var vbox: VBoxContainer = modal["vbox"]

	var hdr := _make_label(Loc.t("league_title"), 24, PALETTE.text_main, true, 2, PALETTE.cream_face, 2)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	var podium_keys := [
		"rank_activity_award_podium_gold",
		"rank_activity_award_podium_silver",
		"rank_activity_award_podium_bronze"
	]

	var entries := GameState.get_leaderboard()
	for i in range(entries.size()):
		var e: Dictionary = entries[i]
		var row_panel := PanelContainer.new()
		var is_p: bool = bool(e.get("is_player", false))
		row_panel.add_theme_stylebox_override(
			"panel",
			_make_card_style(
				PALETTE.sage_face if is_p else PALETTE.cream_face,
				PALETTE.sage_border if is_p else PALETTE.card_border,
				14,
				2 if is_p else 1,
				3,
				12,
				6,
				false
			)
		)
		vbox.add_child(row_panel)

		var rh := HBoxContainer.new()
		rh.alignment = BoxContainer.ALIGNMENT_CENTER
		rh.add_theme_constant_override("separation", 8)
		row_panel.add_child(rh)

		if i < 3:
			var pod_tex := _get_ui_tex(podium_keys[i])
			if pod_tex != null:
				rh.add_child(_make_icon_rect(pod_tex, Vector2(32, 18)))
		elif _bunny_idle_tex != null:
			rh.add_child(_make_icon_rect(_bunny_idle_tex, Vector2(22, 22)))

		var rank_lbl := _make_label(
			"#%d   %s" % [i + 1, str(e.get("name", ""))],
			14,
			PALETTE.sage_text if is_p else PALETTE.text_main,
			true
		)
		rank_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		rh.add_child(rank_lbl)

		var tr_lbl := _make_label(Loc.t("trophies") % int(e.get("trophies", 0)), 14, Color("#A94E27"), true)
		rh.add_child(tr_lbl)

	var close_btn := Button.new()
	close_btn.set_meta("telemetry_id", "league_close")
	close_btn.text = Loc.t("close_btn")
	close_btn.custom_minimum_size = Vector2(0, 50)
	_style_tactile_button(close_btn, PALETTE.carrot_face, PALETTE.carrot_border, PALETTE.carrot_lip, PALETTE.text_light, 18, 6, 12, 8)
	close_btn.pressed.connect(func():
		SoundManager.play("click")
		_modal_layer.visible = false
	)
	vbox.add_child(close_btn)

func _show_language_modal() -> void:
	Telemetry.set_screen("language")
	var modal := _clear_modal()
	var vbox: VBoxContainer = modal["vbox"]

	var hdr := _make_label("🌐 " + Loc.t("lang_modal_title"), 22, PALETTE.text_main, true, 2, PALETTE.cream_face, 2)
	hdr.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(hdr)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(0, 400)
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	vbox.add_child(scroll)

	var grid_margin := MarginContainer.new()
	grid_margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid_margin.mouse_filter = Control.MOUSE_FILTER_PASS
	grid_margin.add_theme_constant_override("margin_top", 4)
	grid_margin.add_theme_constant_override("margin_bottom", 6)
	grid_margin.add_theme_constant_override("margin_left", 4)
	grid_margin.add_theme_constant_override("margin_right", 6)
	scroll.add_child(grid_margin)

	var grid := GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.mouse_filter = Control.MOUSE_FILTER_PASS
	grid.add_theme_constant_override("h_separation", 8)
	grid.add_theme_constant_override("v_separation", 8)
	grid_margin.add_child(grid)

	for item in Loc.LANGUAGES:
		var code: String = str(item["code"])
		var lname: String = str(item["name"])
		var is_sel: bool = (code == Loc.current_lang)

		var lbtn := Button.new()
		lbtn.text = ("✓ " if is_sel else "") + lname
		lbtn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		lbtn.custom_minimum_size = Vector2(180, 44)
		lbtn.mouse_filter = Control.MOUSE_FILTER_PASS
		_style_tactile_button(
			lbtn,
			PALETTE.sage_face if is_sel else PALETTE.cream_face,
			PALETTE.sage_border if is_sel else PALETTE.card_border,
			Color("#A7BB8D") if is_sel else PALETTE.cream_lip,
			PALETTE.sage_text if is_sel else PALETTE.text_main,
			14,
			4,
			10,
			4
		)
		var captured_code := code
		lbtn.pressed.connect(func():
			SoundManager.play("click")
			GameState.set_language(captured_code)
			_modal_layer.visible = false
			_rebuild_all_ui_for_language()
		)
		grid.add_child(lbtn)

	var privacy_btn := Button.new()
	privacy_btn.set_meta("telemetry_id", "privacy_options")
	privacy_btn.text = "🔒 Privacy options"
	privacy_btn.custom_minimum_size = Vector2(0, 48)
	privacy_btn.visible = Ads.privacy_options_required()
	_style_tactile_button(privacy_btn, PALETTE.cream_face, PALETTE.card_border, PALETTE.cream_lip, PALETTE.text_main, 18, 4, 12, 8)
	privacy_btn.pressed.connect(func():
		SoundManager.play("click")
		Ads.show_privacy_options()
	)
	vbox.add_child(privacy_btn)

	var close_btn := Button.new()
	close_btn.set_meta("telemetry_id", "language_close")
	close_btn.text = Loc.t("close_btn")
	close_btn.custom_minimum_size = Vector2(0, 48)
	_style_tactile_button(close_btn, PALETTE.carrot_face, PALETTE.carrot_border, PALETTE.carrot_lip, PALETTE.text_light, 18, 6, 12, 8)
	close_btn.pressed.connect(func():
		SoundManager.play("click")
		_modal_layer.visible = false
	)
	vbox.add_child(close_btn)

func _rebuild_all_ui_for_language() -> void:
	for c in _home_screen.get_children():
		_home_screen.remove_child(c)
		c.queue_free()
	for c in _game_screen.get_children():
		_game_screen.remove_child(c)
		c.queue_free()
	_build_home_screen()
	_build_game_screen()
	_apply_safe_area_margins()
	_show_home_screen()
