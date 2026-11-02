class_name BoardView
extends Control

## Interactive Puzzle Board for Bundoku (Tavşandoku)
## Uses original extracted Meowdoku UI/board textures (brush X-marks, lock badges,
## 12 pattern icons) combined with Bundoku bunny sprites.

signal bunny_count_changed(placed: int, total: int)
signal mistake_made(cell: Vector2i, reason: String)
signal board_solved()
signal draft_state_changed(is_draft: bool)
signal undo_availability_changed(can_undo: bool)

const STATE_EMPTY := 0
const STATE_CROSS := 1
const STATE_BUNNY := 2

const SOURCE_MANUAL := 0
const SOURCE_AUTO := 1
const SOURCE_PREFILL := 2
const SOURCE_DRAFT := 3
const SOURCE_HINT := 4

const PATTERN_ICON_PATHS: Array[String] = [
	"res://assets/ui/game_pattern_icon_pattern_claw.png",
	"res://assets/ui/game_pattern_icon_pattern_bell.png",
	"res://assets/ui/game_pattern_icon_pattern_fishbone.png",
	"res://assets/ui/game_pattern_icon_pattern_whisker.png",
	"res://assets/ui/game_pattern_icon_pattern_sparkle.png",
	"res://assets/ui/game_pattern_icon_pattern_ear.png",
	"res://assets/ui/game_pattern_icon_pattern_heart.png",
	"res://assets/ui/game_pattern_icon_pattern_yarn.png",
	"res://assets/ui/game_pattern_icon_pattern_sprout.png",
	"res://assets/ui/game_pattern_icon_pattern_paw.png",
	"res://assets/ui/game_pattern_icon_pattern_triangle.png",
	"res://assets/ui/game_pattern_icon_pattern_dot.png",
]

var grid_size: int = 5
var region_map: Array = []
var solution_set: Dictionary = {} # Vector2i -> true
var prefill_set: Dictionary = {}  # Vector2i -> true

var cell_state: Array = []
var cell_source: Array = []
var auto_cross_owners: Array = []
var cell_scale: Array = []
var conflict_cells: Dictionary = {}
var conflict_pairs: Array = []
var highlight_cells: Array[Vector2i] = []

var draft_mode: bool = false
var _draft_snapshot: Dictionary = {}
var _undo_stack: Array[Dictionary] = []

var _is_dragging: bool = false
var _drag_mode: int = -1
var _drag_visited: Dictionary = {}
var _last_tap_cell: Vector2i = Vector2i(-1, -1)
var _last_tap_time_ms: int = 0
const DOUBLE_TAP_MS := 300

var _board_rect: Rect2 = Rect2()
var _cell_px: float = 64.0
var _grid_origin: Vector2 = Vector2.ZERO

var _tex_bunny_idle: Texture2D = null
var _tex_bunny_conflict: Texture2D = null
var _tex_mark_brush: Texture2D = null
var _tex_mark_white: Texture2D = null
var _tex_mark_lock: Texture2D = null
var _tex_wrong_mark: Texture2D = null
var _tex_patterns: Array[Texture2D] = []
var _pulse_time: float = 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_load_textures()
	GameState.settings_changed.connect(queue_redraw)

func _load_textures() -> void:
	_tex_bunny_idle = _load_tex("res://assets/chatgpt_ui/icon_bunny.png")
	_tex_bunny_conflict = _load_tex("res://assets/chatgpt_ui/icon_bunny_conflict.png")
	_tex_mark_brush = _load_tex("res://assets/ui/game_icon_mark_white_brush.png")
	_tex_mark_white = _load_tex("res://assets/ui/game_icon_mark_white.png")
	_tex_mark_lock = _load_tex("res://assets/chatgpt_ui/icon_lock.png")
	_tex_wrong_mark = _load_tex("res://assets/ui/game_cat_progress_wrong_mark.png")
	_tex_patterns.clear()
	for p: String in PATTERN_ICON_PATHS:
		var t := _load_tex(p)
		if t != null:
			_tex_patterns.append(t)

func _load_tex(path: String) -> Texture2D:
	if ResourceLoader.exists(path):
		var res = load(path)
		if res is Texture2D:
			return res
	if FileAccess.file_exists(path):
		var img := Image.new()
		if img.load(path) == OK:
			return ImageTexture.create_from_image(img)
	return null

func _process(delta: float) -> void:
	var needs_redraw := false
	if not highlight_cells.is_empty() or not conflict_cells.is_empty():
		_pulse_time += delta * 4.5
		needs_redraw = true
	for r in range(grid_size):
		for c in range(grid_size):
			if r < cell_scale.size() and c < cell_scale[r].size():
				var s: float = cell_scale[r][c]
				if absf(s - 1.0) > 0.005:
					cell_scale[r][c] = lerpf(s, 1.0, minf(1.0, delta * 14.0))
					needs_redraw = true
				else:
					cell_scale[r][c] = 1.0
	if needs_redraw:
		queue_redraw()

func setup_level(level_data: Dictionary) -> void:
	if _tex_bunny_idle == null:
		_load_textures()
	grid_size = int(level_data.get("size", 5))
	region_map = level_data.get("regionMap", []).duplicate(true)
	solution_set.clear()
	for pair in level_data.get("solution", []):
		if pair is Array and pair.size() >= 2:
			solution_set[Vector2i(int(pair[0]), int(pair[1]))] = true

	prefill_set.clear()
	for pair in level_data.get("prefillPositions", []):
		if pair is Array and pair.size() >= 2:
			prefill_set[Vector2i(int(pair[0]), int(pair[1]))] = true

	cell_state.clear()
	cell_source.clear()
	auto_cross_owners.clear()
	cell_scale.clear()
	conflict_cells.clear()
	conflict_pairs.clear()
	highlight_cells.clear()
	_undo_stack.clear()
	draft_mode = false
	_draft_snapshot.clear()

	for r in range(grid_size):
		var st_row := []
		var src_row := []
		var own_row := []
		var scl_row := []
		for c in range(grid_size):
			st_row.append(STATE_EMPTY)
			src_row.append(SOURCE_MANUAL)
			own_row.append([])
			scl_row.append(1.0)
		cell_state.append(st_row)
		cell_source.append(src_row)
		auto_cross_owners.append(own_row)
		cell_scale.append(scl_row)

	for pos: Vector2i in prefill_set.keys():
		cell_state[pos.x][pos.y] = STATE_BUNNY
		cell_source[pos.x][pos.y] = SOURCE_PREFILL
		if GameState.auto_cross_enabled:
			_apply_auto_cross_for_bunny(pos, SOURCE_PREFILL)

	SoundManager.play("board_enter", -3.0)
	_emit_counts()
	undo_availability_changed.emit(false)
	draft_state_changed.emit(false)
	queue_redraw()

func _calculate_layout() -> void:
	var pad := 12.0
	var avail_w := size.x - pad * 2.0
	var avail_h := size.y - pad * 2.0
	var board_side := minf(avail_w, avail_h)
	_cell_px = floorf(board_side / float(grid_size))
	var actual_side := _cell_px * float(grid_size)
	_grid_origin = Vector2(
		floorf((size.x - actual_side) * 0.5),
		floorf((size.y - actual_side) * 0.5)
	)
	_board_rect = Rect2(_grid_origin, Vector2(actual_side, actual_side))

func _draw() -> void:
	if region_map.is_empty() or cell_state.is_empty():
		return
	_calculate_layout()

	# 1. Cozy Wooden Bakery Tray Frame (3-Layer Tactile Wood Rim)
	var outer_tray := _board_rect.grow(10.0)
	var inner_rim := _board_rect.grow(5.0)
	var shadow_rect := Rect2(outer_tray.position + Vector2(0, 6), outer_tray.size)
	draw_rect(shadow_rect, Color("#73563B").lerp(Color.TRANSPARENT, 0.55), true)
	draw_rect(outer_tray, Color("#704A32"), true)
	draw_rect(outer_tray.grow(-2.0), Color("#A97C50"), true)
	draw_rect(inner_rim, Color("#E4BD87"), true)
	draw_rect(_board_rect.grow(2.0), Color("#806044"), true)

	# 2. Cells & Original Pattern Icons
	for r in range(grid_size):
		for c in range(grid_size):
			var rect := Rect2(_grid_origin + Vector2(c * _cell_px, r * _cell_px), Vector2(_cell_px, _cell_px))
			var reg_id: int = int(region_map[r][c]) % GameState.REGION_COLORS.size()
			var base_col: Color = GameState.REGION_COLORS[reg_id]

			draw_rect(rect, base_col, true)
			# Soft inner bevel highlight
			draw_rect(Rect2(rect.position, Vector2(rect.size.x, _cell_px * 0.12)), Color(1, 1, 1, 0.18), true)
			draw_rect(Rect2(rect.position + Vector2(0, _cell_px * 0.88), Vector2(rect.size.x, _cell_px * 0.12)), Color(0, 0, 0, 0.07), true)

			# Original Meowdoku pattern icons when Pattern Mode is enabled
			if GameState.pattern_mode_enabled and not _tex_patterns.is_empty():
				var ptex: Texture2D = _tex_patterns[reg_id % _tex_patterns.size()]
				var psize := Vector2(_cell_px * 0.34, _cell_px * 0.34)
				var prect := Rect2(rect.position + Vector2(3, 3), psize)
				draw_texture_rect(ptex, prect, false, Color(0.18, 0.12, 0.08, 0.36))

			var pos := Vector2i(r, c)
			if highlight_cells.has(pos):
				var alpha := 0.28 + 0.18 * sin(_pulse_time)
				draw_rect(rect.grow(-2.0), Color(1.0, 0.96, 0.4, alpha), true)
				draw_rect(rect.grow(-2.0), Color(1.0, 0.85, 0.1, 0.92), false, 2.5)

			if conflict_cells.has(pos):
				var calpha := 0.30 + 0.20 * sin(_pulse_time * 1.6)
				draw_rect(rect, Color(0.95, 0.18, 0.18, calpha), true)

	# 3. Region & cell grid lines (Bakery Tray Compartments)
	var thin_col := Color(0.45, 0.32, 0.22, 0.28)
	var thick_col := Color("#5C3D28")
	for r in range(grid_size):
		for c in range(grid_size):
			var p0 := _grid_origin + Vector2(c * _cell_px, r * _cell_px)
			var reg_curr: int = int(region_map[r][c])
			if c + 1 < grid_size:
				var reg_right: int = int(region_map[r][c + 1])
				var x := p0.x + _cell_px
				if reg_curr != reg_right:
					draw_line(Vector2(x, p0.y), Vector2(x, p0.y + _cell_px), thick_col, 3.6)
				else:
					draw_line(Vector2(x, p0.y), Vector2(x, p0.y + _cell_px), thin_col, 1.1)
			if r + 1 < grid_size:
				var reg_bot: int = int(region_map[r + 1][c])
				var y := p0.y + _cell_px
				if reg_curr != reg_bot:
					draw_line(Vector2(p0.x, y), Vector2(p0.x + _cell_px, y), thick_col, 3.6)
				else:
					draw_line(Vector2(p0.x, y), Vector2(p0.x + _cell_px, y), thin_col, 1.1)

	draw_rect(_board_rect, thick_col, false, 4.0)

	# 4. Draw cell contents (Original Brush X Marks & Bundoku Bunnies)
	for r in range(grid_size):
		for c in range(grid_size):
			var st: int = cell_state[r][c]
			if st == STATE_EMPTY:
				continue
			var src: int = cell_source[r][c]
			var scl: float = cell_scale[r][c]
			var center := _grid_origin + Vector2((c + 0.5) * _cell_px, (r + 0.5) * _cell_px)

			if st == STATE_CROSS:
				var xtex := _tex_mark_brush if _tex_mark_brush != null else _tex_mark_white
				if xtex != null:
					var side := _cell_px * 0.42 * scl
					var tint := Color(0.24, 0.16, 0.12, 0.82)
					if src == SOURCE_AUTO:
						side = _cell_px * 0.34 * scl
						tint = Color(0.24, 0.16, 0.12, 0.48)
					elif src == SOURCE_DRAFT:
						tint = Color(0.12, 0.42, 0.92, 0.92)
					var xrect := Rect2(center - Vector2(side, side) * 0.5, Vector2(side, side))
					draw_texture_rect(xtex, xrect, false, tint)
				else:
					var half := _cell_px * 0.17 * scl
					draw_line(center + Vector2(-half, -half), center + Vector2(half, half), Color(0.24, 0.16, 0.12, 0.8), 3.0, true)
					draw_line(center + Vector2(half, -half), center + Vector2(-half, half), Color(0.24, 0.16, 0.12, 0.8), 3.0, true)

			elif st == STATE_BUNNY:
				var pos := Vector2i(r, c)
				var is_conflict := conflict_cells.has(pos)
				var radius := _cell_px * 0.40 * scl

				# Soft drop shadow under bunny
				draw_circle(center + Vector2(0, _cell_px * 0.10), radius * 0.72, Color(0.12, 0.08, 0.05, 0.22))

				if src == SOURCE_DRAFT:
					draw_arc(center, radius * 0.92, 0.0, TAU, 32, Color(0.15, 0.48, 0.96, 0.90), 3.0, true)
				elif is_conflict:
					draw_circle(center, radius * 0.92, Color(0.95, 0.18, 0.18, 0.35))
					draw_arc(center, radius * 0.92, 0.0, TAU, 32, Color(0.95, 0.18, 0.18, 0.95), 3.0, true)

				var tex := _tex_bunny_conflict if is_conflict else _tex_bunny_idle
				if tex != null:
					var icon_size := Vector2(radius * 2.05, radius * 2.05)
					var icon_rect := Rect2(center - icon_size * 0.5, icon_size)
					draw_texture_rect(tex, icon_rect, false)

				# ChatGPT wooden padlock badge for prefilled cells
				if src == SOURCE_PREFILL and _tex_mark_lock != null:
					var lock_pos := center + Vector2(radius * 0.56, radius * 0.50)
					var lsize := Vector2(_cell_px * 0.28, _cell_px * 0.28)
					var lrect := Rect2(lock_pos - lsize * 0.5, lsize)
					draw_texture_rect(_tex_mark_lock, lrect, false, Color.WHITE)

	# 5. Conflict lines between conflicting bunnies
	for pair in conflict_pairs:
		var a: Vector2i = pair[0]
		var b: Vector2i = pair[1]
		var pa := _grid_origin + Vector2((a.y + 0.5) * _cell_px, (a.x + 0.5) * _cell_px)
		var pb := _grid_origin + Vector2((b.y + 0.5) * _cell_px, (b.x + 0.5) * _cell_px)
		draw_line(pa, pb, Color(1.0, 0.18, 0.18, 0.88), 4.2, true)

func _cell_from_local_pos(local_pos: Vector2) -> Vector2i:
	if not _board_rect.has_point(local_pos):
		return Vector2i(-1, -1)
	var c := int((local_pos.x - _grid_origin.x) / _cell_px)
	var r := int((local_pos.y - _grid_origin.y) / _cell_px)
	if r < 0 or r >= grid_size or c < 0 or c >= grid_size:
		return Vector2i(-1, -1)
	return Vector2i(r, c)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var cell := _cell_from_local_pos(event.position)
		if event.pressed:
			if cell.x == -1:
				return
			highlight_cells.clear()
			var now_ms := Time.get_ticks_msec()
			if cell == _last_tap_cell and (now_ms - _last_tap_time_ms) <= DOUBLE_TAP_MS:
				_is_dragging = false
				_last_tap_cell = Vector2i(-1, -1)
				_handle_double_tap(cell)
				return
			_last_tap_cell = cell
			_last_tap_time_ms = now_ms
			_handle_single_tap_or_start_drag(cell)
		else:
			_is_dragging = false
			_drag_visited.clear()

	elif event is InputEventMouseMotion and _is_dragging:
		var cell := _cell_from_local_pos(event.position)
		if cell.x != -1 and not _drag_visited.has(cell):
			_handle_drag_over_cell(cell)

func _handle_single_tap_or_start_drag(cell: Vector2i) -> void:
	if prefill_set.has(cell):
		return
	var cur: int = cell_state[cell.x][cell.y]
	var tag := SOURCE_DRAFT if draft_mode else SOURCE_MANUAL

	if GameState.bunny_first_tap_mode:
		_push_undo()
		if cur == STATE_EMPTY:
			_place_bunny_at(cell, tag)
		elif cur == STATE_BUNNY:
			_remove_bunny_at(cell)
			cell_state[cell.x][cell.y] = STATE_CROSS
			cell_source[cell.x][cell.y] = tag
			cell_scale[cell.x][cell.y] = 1.25
			SoundManager.play("x_mark")
		else:
			cell_state[cell.x][cell.y] = STATE_EMPTY
			auto_cross_owners[cell.x][cell.y].clear()
			SoundManager.play("unmark_x")
		_recheck_conflicts_and_win()
		queue_redraw()
		return

	if cur == STATE_EMPTY:
		_push_undo()
		_is_dragging = true
		_drag_mode = STATE_CROSS
		_drag_visited = {cell: true}
		cell_state[cell.x][cell.y] = STATE_CROSS
		cell_source[cell.x][cell.y] = tag
		cell_scale[cell.x][cell.y] = 1.28
		SoundManager.play("x_mark")
		queue_redraw()
	elif cur == STATE_CROSS:
		_push_undo()
		_is_dragging = true
		_drag_mode = STATE_EMPTY
		_drag_visited = {cell: true}
		cell_state[cell.x][cell.y] = STATE_EMPTY
		auto_cross_owners[cell.x][cell.y].clear()
		SoundManager.play("unmark_x")
		queue_redraw()
	elif cur == STATE_BUNNY:
		_push_undo()
		_remove_bunny_at(cell)
		SoundManager.play("unmark_x")
		_recheck_conflicts_and_win()
		queue_redraw()

func _handle_double_tap(cell: Vector2i) -> void:
	if prefill_set.has(cell):
		return
	var cur: int = cell_state[cell.x][cell.y]
	var tag := SOURCE_DRAFT if draft_mode else SOURCE_MANUAL
	if cur != STATE_BUNNY:
		_place_bunny_at(cell, tag)
	else:
		_push_undo()
		_remove_bunny_at(cell)
	_recheck_conflicts_and_win()
	queue_redraw()

func _handle_drag_over_cell(cell: Vector2i) -> void:
	if prefill_set.has(cell):
		return
	_drag_visited[cell] = true
	var cur: int = cell_state[cell.x][cell.y]
	if cur == STATE_BUNNY:
		return
	var tag := SOURCE_DRAFT if draft_mode else SOURCE_MANUAL
	if _drag_mode == STATE_CROSS and cur == STATE_EMPTY:
		cell_state[cell.x][cell.y] = STATE_CROSS
		cell_source[cell.x][cell.y] = tag
		cell_scale[cell.x][cell.y] = 1.22
		SoundManager.play("x_mark", -2.0, randf_range(0.95, 1.06))
		queue_redraw()
	elif _drag_mode == STATE_EMPTY and cur == STATE_CROSS:
		cell_state[cell.x][cell.y] = STATE_EMPTY
		auto_cross_owners[cell.x][cell.y].clear()
		SoundManager.play("unmark_x", -2.0)
		queue_redraw()

func _place_bunny_at(pos: Vector2i, src: int) -> void:
	cell_state[pos.x][pos.y] = STATE_BUNNY
	cell_source[pos.x][pos.y] = src
	auto_cross_owners[pos.x][pos.y].clear()
	cell_scale[pos.x][pos.y] = 1.42
	SoundManager.play("bunny_place")

	var conflicts := _find_conflicts_for_cell(pos)
	if not conflicts.is_empty():
		SoundManager.play("error")
		mistake_made.emit(pos, "Kural İhlali! Aynı satır, sütun, bölge veya çapraz komşuda iki tavşan olamaz.")
	elif GameState.auto_cross_enabled:
		var cross_src := SOURCE_DRAFT if draft_mode else SOURCE_AUTO
		_apply_auto_cross_for_bunny(pos, cross_src)
	_emit_counts()

func _remove_bunny_at(pos: Vector2i) -> void:
	cell_state[pos.x][pos.y] = STATE_EMPTY
	auto_cross_owners[pos.x][pos.y].clear()
	for r in range(grid_size):
		for c in range(grid_size):
			var owners: Array = auto_cross_owners[r][c]
			if owners.has(pos):
				owners.erase(pos)
				if owners.is_empty() and cell_state[r][c] == STATE_CROSS and (cell_source[r][c] == SOURCE_AUTO or cell_source[r][c] == SOURCE_DRAFT):
					cell_state[r][c] = STATE_EMPTY
	_emit_counts()

func _apply_auto_cross_for_bunny(bunny_pos: Vector2i, cross_src: int) -> void:
	var reg: int = int(region_map[bunny_pos.x][bunny_pos.y])
	var swept := false
	for r in range(grid_size):
		for c in range(grid_size):
			if r == bunny_pos.x and c == bunny_pos.y:
				continue
			if r == bunny_pos.x or c == bunny_pos.y or int(region_map[r][c]) == reg or (absi(r - bunny_pos.x) <= 1 and absi(c - bunny_pos.y) <= 1):
				if cell_state[r][c] == STATE_EMPTY:
					cell_state[r][c] = STATE_CROSS
					cell_source[r][c] = cross_src
					cell_scale[r][c] = 1.18
					auto_cross_owners[r][c].append(bunny_pos)
					swept = true
				elif cell_state[r][c] == STATE_CROSS and (cell_source[r][c] == SOURCE_AUTO or cell_source[r][c] == SOURCE_DRAFT):
					if not auto_cross_owners[r][c].has(bunny_pos):
						auto_cross_owners[r][c].append(bunny_pos)
	if swept:
		SoundManager.play("auto_cross", -3.0)

func _find_conflicts_for_cell(pos: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var reg: int = int(region_map[pos.x][pos.y])
	for r in range(grid_size):
		for c in range(grid_size):
			if r == pos.x and c == pos.y:
				continue
			if cell_state[r][c] == STATE_BUNNY:
				if r == pos.x or c == pos.y or int(region_map[r][c]) == reg or (absi(r - pos.x) <= 1 and absi(c - pos.y) <= 1):
					out.append(Vector2i(r, c))
	return out

func _recheck_conflicts_and_win() -> void:
	conflict_cells.clear()
	conflict_pairs.clear()
	var bunnies: Array[Vector2i] = []
	for r in range(grid_size):
		for c in range(grid_size):
			if cell_state[r][c] == STATE_BUNNY:
				bunnies.append(Vector2i(r, c))

	for i in range(bunnies.size()):
		for j in range(i + 1, bunnies.size()):
			var a := bunnies[i]
			var b := bunnies[j]
			var same_row: bool = (a.x == b.x)
			var same_col: bool = (a.y == b.y)
			var same_reg: bool = (int(region_map[a.x][a.y]) == int(region_map[b.x][b.y]))
			var touching: bool = (absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1)
			if same_row or same_col or same_reg or touching:
				conflict_cells[a] = true
				conflict_cells[b] = true
				conflict_pairs.append([a, b])

	_emit_counts()

	if bunnies.size() == grid_size and conflict_cells.is_empty():
		SoundManager.play("win")
		board_solved.emit()

func _emit_counts() -> void:
	var count := 0
	for r in range(grid_size):
		for c in range(grid_size):
			if cell_state[r][c] == STATE_BUNNY:
				count += 1
	bunny_count_changed.emit(count, grid_size)

func _capture_snapshot() -> Dictionary:
	return {
		"state": cell_state.duplicate(true),
		"source": cell_source.duplicate(true),
		"owners": auto_cross_owners.duplicate(true),
	}

func _restore_snapshot(snap: Dictionary) -> void:
	cell_state = snap["state"].duplicate(true)
	cell_source = snap["source"].duplicate(true)
	auto_cross_owners = snap["owners"].duplicate(true)
	_recheck_conflicts_and_win()
	queue_redraw()

func _push_undo() -> void:
	_undo_stack.append(_capture_snapshot())
	if _undo_stack.size() > 60:
		_undo_stack.pop_front()
	undo_availability_changed.emit(true)

func undo_move() -> void:
	if _undo_stack.is_empty():
		return
	var snap: Dictionary = _undo_stack.pop_back()
	_restore_snapshot(snap)
	SoundManager.play("click")
	undo_availability_changed.emit(not _undo_stack.is_empty())

func clear_board() -> void:
	_push_undo()
	highlight_cells.clear()
	for r in range(grid_size):
		for c in range(grid_size):
			var pos := Vector2i(r, c)
			if not prefill_set.has(pos):
				cell_state[r][c] = STATE_EMPTY
				cell_source[r][c] = SOURCE_MANUAL
				auto_cross_owners[r][c].clear()
	for pos: Vector2i in prefill_set.keys():
		if GameState.auto_cross_enabled:
			_apply_auto_cross_for_bunny(pos, SOURCE_PREFILL)
	_recheck_conflicts_and_win()
	SoundManager.play("clear")
	queue_redraw()

func toggle_draft_mode() -> void:
	if not draft_mode:
		draft_mode = true
		_draft_snapshot = _capture_snapshot()
		SoundManager.play("click")
		draft_state_changed.emit(true)
	else:
		apply_draft()

func apply_draft() -> void:
	if not draft_mode:
		return
	draft_mode = false
	for r in range(grid_size):
		for c in range(grid_size):
			if cell_source[r][c] == SOURCE_DRAFT:
				cell_source[r][c] = SOURCE_MANUAL
	_draft_snapshot.clear()
	SoundManager.play("bunny_place")
	draft_state_changed.emit(false)
	queue_redraw()

func cancel_draft() -> void:
	if not draft_mode:
		return
	draft_mode = false
	if not _draft_snapshot.is_empty():
		_restore_snapshot(_draft_snapshot)
	_draft_snapshot.clear()
	SoundManager.play("click")
	draft_state_changed.emit(false)
	queue_redraw()

func request_and_apply_hint() -> Dictionary:
	var hint := HintSolver.compute_hint(grid_size, region_map, solution_set, cell_state)
	if hint.is_empty():
		return {}
	_push_undo()
	highlight_cells.clear()
	for hc in hint.get("highlight_cells", []):
		highlight_cells.append(hc)
	var htype: String = hint.get("type", "")
	var targets: Array = hint.get("target_cells", [])
	if htype == "remove_wrong_bunny":
		for pos: Vector2i in targets:
			_remove_bunny_at(pos)
	elif htype == "clear_wrong_cross":
		for pos: Vector2i in targets:
			cell_state[pos.x][pos.y] = STATE_EMPTY
			auto_cross_owners[pos.x][pos.y].clear()
	elif htype == "place_crosses":
		for pos: Vector2i in targets:
			if cell_state[pos.x][pos.y] == STATE_EMPTY:
				cell_state[pos.x][pos.y] = STATE_CROSS
				cell_source[pos.x][pos.y] = SOURCE_HINT
				cell_scale[pos.x][pos.y] = 1.28
	elif htype == "place_bunny":
		for pos: Vector2i in targets:
			_place_bunny_at(pos, SOURCE_HINT)
	SoundManager.play("hint")
	_recheck_conflicts_and_win()
	queue_redraw()
	return hint

func apply_carrot_booster() -> Dictionary:
	var candidates: Array[Vector2i] = []
	for sol_pos: Vector2i in solution_set.keys():
		if cell_state[sol_pos.x][sol_pos.y] != STATE_BUNNY:
			candidates.append(sol_pos)
	if candidates.is_empty():
		return {}
	_push_undo()
	var best_pos := candidates[0]
	var best_empty := -1
	for cand in candidates:
		var reg: int = int(region_map[cand.x][cand.y])
		var empty_cnt := 0
		for r in range(grid_size):
			for c in range(grid_size):
				if int(region_map[r][c]) == reg and cell_state[r][c] == STATE_EMPTY:
					empty_cnt += 1
		if empty_cnt > best_empty:
			best_empty = empty_cnt
			best_pos = cand

	highlight_cells = [best_pos]
	_place_bunny_at(best_pos, SOURCE_HINT)
	SoundManager.play("carrot")
	_recheck_conflicts_and_win()
	queue_redraw()
	return {
		"title": "Altın Havuç Kullanıldı!",
		"message": "En zorlu bölgedeki tavşan (Satır %d, Sütun %d) ortaya çıkarıldı!" % [best_pos.x + 1, best_pos.y + 1]
	}
