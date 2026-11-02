extends Node

## Global GameState for Bundoku (Tavşandoku)
## Manages levels, save data, boosters, settings, and simulated Bunny League leaderboard.

signal stats_changed
signal settings_changed

const SAVE_PATH := "user://bundoku_save.cfg"
const LEVELS_PATH := "res://assets/levels/levels_database.json"

var current_level_index: int = 0
var unlocked_level_index: int = 0
var completed_levels: Dictionary = {} # level_id -> { "stars": int, "time_sec": int }

var hints_count: int = 5
var carrots_count: int = 3
var streak_days: int = 1
var player_trophies: int = 120
var player_nickname: String = "Pamuk Tavşan"

# Settings (mirrors Meowdoku's settings)
var auto_cross_enabled: bool = true
var pattern_mode_enabled: bool = false
var bunny_first_tap_mode: bool = false

# Loaded levels array
var levels: Array = []

# Ad frequency tracking (Kolay: 5, Orta: 4, Zor: 3, Uzman: 2 bölümde bir)
var levels_since_last_ad: int = 0
var total_ads_watched: int = 0
var no_ads_purchased: bool = false

const AD_INTERVAL_BY_TIER := {
	"easy": 5,
	"medium": 4,
	"hard": 3,
	"expert": 2,
	"super_hard": 1
}

# Simulated Bunny League rivals (inspired by Meowdoku's RobotService)
var league_rivals: Array = [
	{"name": "Zıpzıp Efe", "trophies": 210},
	{"name": "Havuç Avcısı", "trophies": 185},
	{"name": "Tarçın Kulak", "trophies": 160},
	{"name": "Kartopu", "trophies": 135},
	{"name": "Benekli Pati", "trophies": 110},
	{"name": "Minik Yonca", "trophies": 95},
	{"name": "Pofuduk", "trophies": 70},
]

# Cozy Kawaii Bakery Pastel Region Palette (14 distinct ingredient colors)
const REGION_COLORS: Array[Color] = [
	Color("#F4C4CB"), # 1. Strawberry Milk
	Color("#C8D8ED"), # 2. Blueberry Cream
	Color("#D0E0B8"), # 3. Pistachio
	Color("#F4D0AD"), # 4. Peach Tart
	Color("#D9C9E9"), # 5. Lavender Sugar
	Color("#F2E3A9"), # 6. Lemon Custard
	Color("#BFE2D7"), # 7. Mint Macaron
	Color("#E9BDD3"), # 8. Rose Jam
	Color("#E6C39C"), # 9. Caramel
	Color("#E7E0D2"), # 10. Cloud Cream
	Color("#F7B7A3"), # 11. Apricot Glaze
	Color("#B8D8BA"), # 12. Matcha Cream
	Color("#D4C5EC"), # 13. Taro Milk
	Color("#F3D1DC"), # 14. Raspberry Frosting
]

# Pattern symbols for colorblind / pattern mode
const REGION_PATTERNS: Array[String] = [
	"✿", "♣", "★", "♦", "▲", "♥", "●", "✦", "☀", "❖", "♪", "✧", "⬟", "✪"
]

func _ready() -> void:
	_load_levels()
	load_save()

func _load_levels() -> void:
	levels.clear()
	if FileAccess.file_exists(LEVELS_PATH):
		var f := FileAccess.open(LEVELS_PATH, FileAccess.READ)
		if f != null:
			var text := f.get_as_text()
			f.close()
			var parsed = JSON.parse_string(text)
			if parsed is Array and parsed.size() > 0:
				levels = parsed
			elif parsed is Dictionary and parsed.has("levels") and parsed["levels"] is Array:
				levels = parsed["levels"]
	if levels.is_empty():
		levels = _build_fallback_levels()

func get_level_count() -> int:
	return levels.size()

func get_level(idx: int) -> Dictionary:
	if levels.is_empty():
		levels = _build_fallback_levels()
	var clamped := clampi(idx, 0, levels.size() - 1)
	return levels[clamped]

func get_ad_interval_for_tier(tier: String) -> int:
	return int(AD_INTERVAL_BY_TIER.get(tier.to_lower(), 5))

func complete_level(idx: int, elapsed_sec: int, mistakes: int) -> Dictionary:
	var stars := 3
	if mistakes >= 2 or elapsed_sec > 180:
		stars = 1
	elif mistakes == 1 or elapsed_sec > 90:
		stars = 2

	var prev_stars: int = completed_levels.get(idx, {}).get("stars", 0)
	var prev_time: int = completed_levels.get(idx, {}).get("time_sec", 999999)
	completed_levels[idx] = {
		"stars": maxi(stars, prev_stars),
		"time_sec": mini(elapsed_sec, prev_time)
	}

	if idx >= unlocked_level_index and idx + 1 < levels.size():
		unlocked_level_index = idx + 1

	var trophy_gain := 10 + stars * 5
	player_trophies += trophy_gain

	# Reward booster on first clear of every 2nd/4th level
	var bonus_hint := 0
	var bonus_carrot := 0
	if prev_stars == 0:
		if (idx + 1) % 2 == 0:
			hints_count += 1
			bonus_hint = 1
		if (idx + 1) % 4 == 0:
			carrots_count += 1
			bonus_carrot = 1

	# Simulate RobotService rivals advancing slightly
	for r in league_rivals:
		if randf() < 0.45:
			r["trophies"] = int(r["trophies"]) + randi_range(3, 12)

	# Tier-based Interstitial Ad check:
	# Easy = every 5 levels, Medium = every 4, Hard = every 3, Expert = every 2, Super Hard = every 1
	var lv := get_level(idx)
	var tier_str: String = str(lv.get("tier", "easy")).to_lower()
	var ad_interval: int = get_ad_interval_for_tier(tier_str)
	var show_interstitial_ad: bool = false
	if not no_ads_purchased:
		levels_since_last_ad += 1
		if levels_since_last_ad >= ad_interval:
			show_interstitial_ad = true
			levels_since_last_ad = 0
			total_ads_watched += 1

	save_game()
	stats_changed.emit()
	return {
		"stars": stars,
		"trophy_gain": trophy_gain,
		"bonus_hint": bonus_hint,
		"bonus_carrot": bonus_carrot,
		"show_interstitial_ad": show_interstitial_ad,
		"ad_interval": ad_interval,
		"levels_since_last_ad": levels_since_last_ad,
		"tier": tier_str,
	}

func use_hint() -> bool:
	if hints_count <= 0:
		return false
	hints_count -= 1
	save_game()
	stats_changed.emit()
	return true

func use_carrot() -> bool:
	if carrots_count <= 0:
		return false
	carrots_count -= 1
	save_game()
	stats_changed.emit()
	return true

func add_free_boosters(hints: int, carrots: int) -> void:
	hints_count += hints
	carrots_count += carrots
	save_game()
	stats_changed.emit()

func get_leaderboard() -> Array:
	var all_entries: Array = []
	for r in league_rivals:
		all_entries.append({
			"name": str(r.get("name", "Rakip Tavşan")),
			"trophies": int(r.get("trophies", 100)),
			"is_player": false
		})
	all_entries.append({
		"name": player_nickname + " (Sen)",
		"trophies": player_trophies,
		"is_player": true
	})
	all_entries.sort_custom(func(a, b): return int(a["trophies"]) > int(b["trophies"]))
	return all_entries

func save_game() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "current_level_index", current_level_index)
	cfg.set_value("progress", "unlocked_level_index", unlocked_level_index)
	cfg.set_value("progress", "completed_levels", completed_levels)
	cfg.set_value("progress", "hints_count", hints_count)
	cfg.set_value("progress", "carrots_count", carrots_count)
	cfg.set_value("progress", "streak_days", streak_days)
	cfg.set_value("progress", "player_trophies", player_trophies)
	cfg.set_value("progress", "league_rivals", league_rivals)
	cfg.set_value("ads", "levels_since_last_ad", levels_since_last_ad)
	cfg.set_value("ads", "total_ads_watched", total_ads_watched)
	cfg.set_value("ads", "no_ads_purchased", no_ads_purchased)
	cfg.set_value("settings", "auto_cross_enabled", auto_cross_enabled)
	cfg.set_value("settings", "pattern_mode_enabled", pattern_mode_enabled)
	cfg.set_value("settings", "bunny_first_tap_mode", bunny_first_tap_mode)
	cfg.set_value("settings", "sound_enabled", SoundManager.sound_enabled)
	cfg.save(SAVE_PATH)

func load_save() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	current_level_index = int(cfg.get_value("progress", "current_level_index", 0))
	unlocked_level_index = int(cfg.get_value("progress", "unlocked_level_index", 0))
	completed_levels = cfg.get_value("progress", "completed_levels", {})
	hints_count = int(cfg.get_value("progress", "hints_count", 5))
	carrots_count = int(cfg.get_value("progress", "carrots_count", 3))
	streak_days = int(cfg.get_value("progress", "streak_days", 1))
	player_trophies = int(cfg.get_value("progress", "player_trophies", 120))
	league_rivals = cfg.get_value("progress", "league_rivals", league_rivals)
	levels_since_last_ad = int(cfg.get_value("ads", "levels_since_last_ad", 0))
	total_ads_watched = int(cfg.get_value("ads", "total_ads_watched", 0))
	no_ads_purchased = bool(cfg.get_value("ads", "no_ads_purchased", false))
	auto_cross_enabled = bool(cfg.get_value("settings", "auto_cross_enabled", true))
	pattern_mode_enabled = bool(cfg.get_value("settings", "pattern_mode_enabled", false))
	bunny_first_tap_mode = bool(cfg.get_value("settings", "bunny_first_tap_mode", false))
	SoundManager.sound_enabled = bool(cfg.get_value("settings", "sound_enabled", true))

func _build_fallback_levels() -> Array:
	return [
		{
			"id": 1,
			"size": 4,
			"tier": "easy",
			"regionMap": [
				[0, 0, 1, 1],
				[0, 1, 1, 1],
				[2, 2, 1, 3],
				[2, 2, 3, 3]
			],
			"solution": [[0, 1], [1, 3], [2, 0], [3, 2]],
			"prefillPositions": []
		},
		{
			"id": 2,
			"size": 5,
			"tier": "easy",
			"regionMap": [
				[0, 0, 0, 1, 1],
				[2, 0, 1, 1, 1],
				[2, 2, 2, 3, 4],
				[2, 3, 3, 3, 4],
				[3, 3, 4, 4, 4]
			],
			"solution": [[0, 1], [1, 4], [2, 0], [3, 2], [4, 3]],
			"prefillPositions": []
		}
	]
