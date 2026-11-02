class_name HintSolver
extends RefCounted

## Bundoku Step-by-Step Logical Deduction Engine
## Faithfully mirrors Meowdoku's HintPipeline:
## 1. CorrectionStep (wrong bunny or wrong X on a solution cell)
## 2. BasicMarkStep (unmarked row/col/region/8-neighbor of an existing bunny)
## 3. SingleCandidateStep (only 1 empty cell left in a region, row, or column)
## 4. RegionLineStep (all empty cells of a region lie in one row/col, or vice versa)
## 5. NeighborhoodEliminationStep (placing a bunny at (r,c) would wipe out an entire region)
## 6. DirectRevealFallback (places the next solution bunny with explanation)

const STATE_EMPTY := 0
const STATE_CROSS := 1
const STATE_BUNNY := 2

static func compute_hint(
	size: int,
	region_map: Array,
	solution_set: Dictionary, # Vector2i -> true
	board_state: Array # 2D array of int (STATE_EMPTY, STATE_CROSS, STATE_BUNNY)
) -> Dictionary:
	# 1. Check for wrong Bunnies placed by the player
	for r in range(size):
		for c in range(size):
			var pos := Vector2i(r, c)
			if board_state[r][c] == STATE_BUNNY and not solution_set.has(pos):
				return {
					"type": "remove_wrong_bunny",
					"target_cells": [pos],
					"highlight_cells": [pos],
					"title": "Hatalı Tavşan Düzeltmesi",
					"message": "Satır %d, Sütun %d hücresindeki tavşan kurallarla çelişiyor. Önce bunu kaldıralım!" % [r + 1, c + 1]
				}

	# 2. Check for wrong X marks placed on actual solution cells
	for sol_pos: Vector2i in solution_set.keys():
		if board_state[sol_pos.x][sol_pos.y] == STATE_CROSS:
			return {
				"type": "clear_wrong_cross",
				"target_cells": [sol_pos],
				"highlight_cells": [sol_pos],
				"title": "Hatalı X İşareti",
				"message": "Satır %d, Sütun %d aslında bir tavşan hücresi! Buradaki X işaretini temizleyelim." % [sol_pos.x + 1, sol_pos.y + 1]
			}

	# 3. BasicMarkStep: Check if any correctly placed Bunny still has empty cells in its row/col/region/neighbors
	for r in range(size):
		for c in range(size):
			if board_state[r][c] == STATE_BUNNY:
				var elim: Array[Vector2i] = []
				var reg: int = int(region_map[r][c])
				for nr in range(size):
					for nc in range(size):
						if nr == r and nc == c:
							continue
						if board_state[nr][nc] == STATE_EMPTY:
							if nr == r or nc == c or int(region_map[nr][nc]) == reg or (abs(nr - r) <= 1 and abs(nc - c) <= 1):
								elim.append(Vector2i(nr, nc))
				if elim.size() > 0:
					return {
						"type": "place_crosses",
						"target_cells": elim,
						"highlight_cells": [Vector2i(r, c)] + elim,
						"title": "Temel Eleme Kuralı",
						"message": "Satır %d, Sütun %d'deki tavşan kendi satırını, sütununu, bölgesini ve komşu hücrelerini X ile kapatır." % [r + 1, c + 1]
					}

	# 4. SingleCandidateStep — Region with only 1 empty cell left
	for reg_id in range(size):
		var has_bunny := false
		var empty_cells: Array[Vector2i] = []
		var reg_cells: Array[Vector2i] = []
		for r in range(size):
			for c in range(size):
				if int(region_map[r][c]) == reg_id:
					var p := Vector2i(r, c)
					reg_cells.append(p)
					if board_state[r][c] == STATE_BUNNY:
						has_bunny = true
					elif board_state[r][c] == STATE_EMPTY:
						empty_cells.append(p)
		if not has_bunny and empty_cells.size() == 1:
			var target := empty_cells[0]
			return {
				"type": "place_bunny",
				"target_cells": [target],
				"highlight_cells": reg_cells,
				"title": "Bölgede Tek Aday!",
				"message": "Bu renkli bölgede tavşan koyulabilecek yalnızca tek bir boş hücre (Satır %d, Sütun %d) kaldı!" % [target.x + 1, target.y + 1]
			}

	# 5. SingleCandidateStep — Row with only 1 empty cell left
	for r in range(size):
		var has_bunny := false
		var empty_cells: Array[Vector2i] = []
		var row_cells: Array[Vector2i] = []
		for c in range(size):
			var p := Vector2i(r, c)
			row_cells.append(p)
			if board_state[r][c] == STATE_BUNNY:
				has_bunny = true
			elif board_state[r][c] == STATE_EMPTY:
				empty_cells.append(p)
		if not has_bunny and empty_cells.size() == 1:
			var target := empty_cells[0]
			return {
				"type": "place_bunny",
				"target_cells": [target],
				"highlight_cells": row_cells,
				"title": "Satırda Tek Aday!",
				"message": "%d. satırda tavşan için yalnızca tek bir boş hücre (Sütun %d) kaldı!" % [r + 1, target.y + 1]
			}

	# 6. SingleCandidateStep — Column with only 1 empty cell left
	for c in range(size):
		var has_bunny := false
		var empty_cells: Array[Vector2i] = []
		var col_cells: Array[Vector2i] = []
		for r in range(size):
			var p := Vector2i(r, c)
			col_cells.append(p)
			if board_state[r][c] == STATE_BUNNY:
				has_bunny = true
			elif board_state[r][c] == STATE_EMPTY:
				empty_cells.append(p)
		if not has_bunny and empty_cells.size() == 1:
			var target := empty_cells[0]
			return {
				"type": "place_bunny",
				"target_cells": [target],
				"highlight_cells": col_cells,
				"title": "Sütunda Tek Aday!",
				"message": "%d. sütunda tavşan için yalnızca tek bir boş hücre (Satır %d) kaldı!" % [c + 1, target.x + 1]
			}

	# 7. RegionLineStep: All empty cells of a region lie in the same Row or Column
	for reg_id in range(size):
		var empty_cells: Array[Vector2i] = []
		var has_bunny := false
		for r in range(size):
			for c in range(size):
				if int(region_map[r][c]) == reg_id:
					if board_state[r][c] == STATE_BUNNY:
						has_bunny = true
					elif board_state[r][c] == STATE_EMPTY:
						empty_cells.append(Vector2i(r, c))
		if has_bunny or empty_cells.is_empty():
			continue

		# Check if all empty_cells share the same row
		var first_r := empty_cells[0].x
		var same_row := true
		for p in empty_cells:
			if p.x != first_r:
				same_row = false
				break
		if same_row:
			var elim: Array[Vector2i] = []
			for c in range(size):
				if int(region_map[first_r][c]) != reg_id and board_state[first_r][c] == STATE_EMPTY:
					elim.append(Vector2i(first_r, c))
			if elim.size() > 0:
				return {
					"type": "place_crosses",
					"target_cells": elim,
					"highlight_cells": empty_cells + elim,
					"title": "Bölge-Satır Kesişimi",
					"message": "Bu bölgenin tüm boş hücreleri %d. satırda yer alıyor. Dolayısıyla %d. satırın bölge dışındaki hücrelerinde tavşan olamaz!" % [first_r + 1, first_r + 1]
				}

		# Check if all empty_cells share the same col
		var first_c := empty_cells[0].y
		var same_col := true
		for p in empty_cells:
			if p.y != first_c:
				same_col = false
				break
		if same_col:
			var elim: Array[Vector2i] = []
			for r in range(size):
				if int(region_map[r][first_c]) != reg_id and board_state[r][first_c] == STATE_EMPTY:
					elim.append(Vector2i(r, first_c))
			if elim.size() > 0:
				return {
					"type": "place_crosses",
					"target_cells": elim,
					"highlight_cells": empty_cells + elim,
					"title": "Bölge-Sütun Kesişimi",
					"message": "Bu bölgenin tüm boş hücreleri %d. sütunda yer alıyor. Dolayısıyla %d. sütunun bölge dışındaki hücreleri X ile elenir!" % [first_c + 1, first_c + 1]
				}

	# 8. Neighborhood / Region Wipeout Step:
	# If an empty cell (r,c) outside a small region R would eliminate ALL empty cells of region R, then (r,c) must be X!
	for reg_id in range(size):
		var reg_empty: Array[Vector2i] = []
		var has_bunny := false
		for r in range(size):
			for c in range(size):
				if int(region_map[r][c]) == reg_id:
					if board_state[r][c] == STATE_BUNNY:
						has_bunny = true
					elif board_state[r][c] == STATE_EMPTY:
						reg_empty.append(Vector2i(r, c))
		if has_bunny or reg_empty.is_empty() or reg_empty.size() > 4:
			continue
		var elim: Array[Vector2i] = []
		for r in range(size):
			for c in range(size):
				if int(region_map[r][c]) == reg_id or board_state[r][c] != STATE_EMPTY:
					continue
				var wipes_all := true
				for rp: Vector2i in reg_empty:
					var conflicts: bool = (r == rp.x) or (c == rp.y) or (absi(r - rp.x) <= 1 and absi(c - rp.y) <= 1)
					if not conflicts:
						wipes_all = false
						break
				if wipes_all:
					elim.append(Vector2i(r, c))
		if elim.size() > 0:
			return {
				"type": "place_crosses",
				"target_cells": elim,
				"highlight_cells": reg_empty + elim,
				"title": "Komşuluk Kesişimi Elemesi",
				"message": "İşaretlenen hücrelere tavşan koymak komşu bölgedeki tüm adayları yok edeceği için bu hücrelerde tavşan olamaz!"
			}

	# 9. Fallback: Reveal the next unplaced Bunny from the solution
	for sol_pos: Vector2i in solution_set.keys():
		if board_state[sol_pos.x][sol_pos.y] != STATE_BUNNY:
			return {
				"type": "place_bunny",
				"target_cells": [sol_pos],
				"highlight_cells": [sol_pos],
				"title": "Tavşan Konumu Bulundu!",
				"message": "Mantıksal çözüm adımı: Satır %d, Sütun %d hücresine bir tavşan yerleşmeli!" % [sol_pos.x + 1, sol_pos.y + 1]
			}

	return {}
