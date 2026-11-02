extends Node

## Original Meowdoku Audio + Procedural Fallback Sound Manager for Bundoku

const ORIG_STREAMS := {
	"bunny_place": "res://assets/audio/orig/mark_cat.res",
	"x_mark": "res://assets/audio/orig/mark_x_2.res",
	"unmark_x": "res://assets/audio/orig/unmark_x_2.res",
	"auto_cross": "res://assets/audio/orig/auto_x_mark.res",
	"error": "res://assets/audio/orig/mark_wrong_1.res",
	"hint": "res://assets/audio/orig/use_hint.res",
	"carrot": "res://assets/audio/orig/rank_fish_collect_1.res",
	"win": "res://assets/audio/orig/level_win.res",
	"fail": "res://assets/audio/orig/level_fail.res",
	"click": "res://assets/audio/orig/btn_click_2.res",
	"clear": "res://assets/audio/orig/all_cleared.res",
	"board_enter": "res://assets/audio/orig/board_enter_1.res",
}

const FALLBACK_WAVS := {
	"bunny_place": "res://assets/audio/bunny_place.wav",
	"x_mark": "res://assets/audio/x_mark.wav",
	"auto_cross": "res://assets/audio/auto_cross_sweep.wav",
	"error": "res://assets/audio/error_buzz.wav",
	"hint": "res://assets/audio/hint_chime.wav",
	"carrot": "res://assets/audio/carrot_boost.wav",
	"win": "res://assets/audio/win_fanfare.wav",
	"click": "res://assets/audio/ui_click.wav",
}

const BGM_PATH := "res://assets/audio/orig/bgm_meowdoku_melody.res"

var sound_enabled: bool = true
var music_enabled: bool = true
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _bgm_player: AudioStreamPlayer
const POOL_SIZE := 8

func _ready() -> void:
	for i in range(POOL_SIZE):
		var p := AudioStreamPlayer.new()
		p.bus = "Master"
		add_child(p)
		_players.append(p)

	_bgm_player = AudioStreamPlayer.new()
	_bgm_player.bus = "Master"
	_bgm_player.volume_db = -9.0
	_bgm_player.finished.connect(func():
		if music_enabled:
			_bgm_player.play()
	)
	add_child(_bgm_player)

	_load_streams()
	_start_bgm()

func _load_streams() -> void:
	for key: String in ORIG_STREAMS.keys():
		var path: String = ORIG_STREAMS[key]
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStream:
				_streams[key] = res
	for key: String in FALLBACK_WAVS.keys():
		if not _streams.has(key):
			var path: String = FALLBACK_WAVS[key]
			if ResourceLoader.exists(path):
				var res = load(path)
				if res is AudioStream:
					_streams[key] = res

func _start_bgm() -> void:
	if ResourceLoader.exists(BGM_PATH):
		var bgm = load(BGM_PATH)
		if bgm is AudioStream:
			_bgm_player.stream = bgm
			if music_enabled:
				_bgm_player.play()

func set_music_enabled(enabled: bool) -> void:
	music_enabled = enabled
	if _bgm_player == null or _bgm_player.stream == null:
		return
	if music_enabled:
		if not _bgm_player.playing:
			_bgm_player.play()
	else:
		_bgm_player.stop()

func play(sound_name: String, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if not sound_enabled:
		return
	if not _streams.has(sound_name):
		return
	for p in _players:
		if not p.playing:
			p.stream = _streams[sound_name]
			p.volume_db = volume_db
			p.pitch_scale = pitch_scale
			p.play()
			return
	var p0 := _players[0]
	p0.stream = _streams[sound_name]
	p0.volume_db = volume_db
	p0.pitch_scale = pitch_scale
	p0.play()
