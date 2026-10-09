# PieceData.gd — класс-хранилище всех данных игры (перенесено из старого game.gd 1:1)
# Не является узлом: используется как "библиотека" констант и фабрика словарей-фигур.
class_name PieceData
extends RefCounted

const GRID_SIZE = 8                       # размер поля 8x8

# --- ВСЕ ФИГУРЫ (массив массивов Vector2i) — из старого кода, без изменений ---
const ALL_SHAPES = [
	[Vector2i(0,0)], [Vector2i(0,0), Vector2i(1,0)], [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	[Vector2i(0,0), Vector2i(0,1)], [Vector2i(0,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(0,3), Vector2i(0,4)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1),
		Vector2i(0,2), Vector2i(1,2), Vector2i(2,2)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)], [Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1)], [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(0,2), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(1,1), Vector2i(1,2), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2)],
	[Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	[Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2), Vector2i(1,2)],
	[Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
]

const SMALL_SHAPE_IDX = [0, 1, 5, 11, 12, 13, 14]   # индексы «спасательных» мелких фигур
# Фигуры для спецэффекта line_clear (берутся из ALL_SHAPES)
const SPECIAL_SHAPES = [ALL_SHAPES[0], ALL_SHAPES[1], ALL_SHAPES[2], ALL_SHAPES[5], ALL_SHAPES[6], ALL_SHAPES[9]]

# --- Палитра цветов — из старого кода ---
const COLOR_PALETTE = [
	Color("#2EC4FF"), Color("#9BFF3D"), Color("#FF2FD0"),
	Color("#FF9E2C"), Color("#B15CFF"), Color("#FF5C7C"), Color("#2EE6D6"),
]

# --- Спецфигуры: шансы/интервалы — из старого кода ---
const BOMB_CHANCE = 0.030
const LINE_CLEAR_CHANCE = 0.035
const BOMB_MIN_INTERVAL = 6
const LINE_MIN_INTERVAL = 5
const BOMB_COLOR = Color(0.18, 0.10, 0.35)
const LINE_CLEAR_COLOR = Color(1.0, 0.85, 0.15)

# --- Пороги плотности поля для rescue-режима генерации ---
const DENSITY_RESCUE = 0.55
const DENSITY_EMERGENCY = 0.85

# --- Параметры отрисовки блоков в лотке ---
const TRAY_BLOCK_STEP = 54.0     # шаг сетки фигуры в лотке (px базовых)
const TRAY_BLOCK_SIZE = 48.0     # размер блока фигуры в лотке (px базовых)
const MAX_TRAY_SIZE = 220.0      # максимальный габарит фигуры в лотке

# ============================================================================
# ГЕНЕРАЦИЯ ФИГУР (порт логики _make_smart_piece / generate_new_pieces)
# ============================================================================

static func make_piece(data: Dictionary) -> Dictionary:
	"""Создаёт словарь-фигуру {blocks, color, type} с независимыми копиями данных."""
	return {
		"blocks": (data.get("blocks", []) as Array).duplicate(),
		"color": data.get("color", Color.WHITE),
		"type": data.get("type", "normal"),
	}

static func shape_index_of(piece: Dictionary) -> int:
	"""Возвращает индекс формы фигуры в ALL_SHAPES (или -1)."""
	for i in range(ALL_SHAPES.size()):
		if ALL_SHAPES[i] == piece["blocks"]:
			return i
	return -1

static func difficulty_bias(score: float) -> float:
	"""Кривая сложности по счёту: 0..1 (мелкие фигуры -> крупные). Из старого кода."""
	var s = score
	if s < 800.0: return s / 800.0 * 0.25
	elif s < 3000.0: return 0.25 + (s - 800.0) / 2200.0 * 0.35
	elif s < 8000.0: return 0.60 + (s - 3000.0) / 5000.0 * 0.30
	return min(1.0, 0.90 + (s - 8000.0) / 20000.0 * 0.10)

static func pick_small_shape_idx() -> int:
	return SMALL_SHAPE_IDX[randi() % SMALL_SHAPE_IDX.size()]

static func pick_shape_idx_smart(rescue: bool, score: float) -> int:
	"""Выбор индекса формы. rescue=true — только мелкие фигуры (спасение при
	высокой плотности поля). Кривая сложности сохранена из старого кода."""
	if rescue: return pick_small_shape_idx()
	var bias = difficulty_bias(score)
	var roll = randf()
	if roll > bias * 0.6: return SMALL_SHAPE_IDX[randi() % SMALL_SHAPE_IDX.size()]
	if roll > bias * 0.35:
		var med = [1, 2, 5, 6, 11, 12, 13, 14, 15, 16, 17, 18, 22, 23]
		return med[randi() % med.size()]
	var big = [3, 4, 7, 8, 10, 19, 20, 21, 24, 25, 26]
	return big[randi() % big.size()]

static func pick_fresh_color(last_colors: Array) -> Color:
	"""Цвет, не повторяющий последние два (анти-паттерн), из старого кода."""
	var attempts = 0
	while attempts < 10:
		var c = COLOR_PALETTE[randi() % COLOR_PALETTE.size()]
		var same = 0
		for lc in last_colors:
			if lc == c: same += 1
		if same < 2: return c
		attempts += 1
	return COLOR_PALETTE[randi() % COLOR_PALETTE.size()]

static func make_smart_piece(state: Dictionary) -> Dictionary:
	"""Фабрика одной фигуры. state содержит: score, density, grid_ref (Array),
	pieces_since_bomb, pieces_since_line, last_shapes, last_colors, force_small.
	Возвращает {piece=..., pieces_since_bomb=..., pieces_since_line=...} —
	обновлённые счётчики передаются обратно вызывающему коду."""
	var force_small: bool = state.get("force_small", false)
	var density: float = state.get("density", 0.0)
	var grid_ref: Array = state.get("grid_ref", [])
	var since_bomb: int = state.get("pieces_since_bomb", 0)
	var since_line: int = state.get("pieces_since_line", 0)
	var roll = randf()

	if not force_small and not grid_ref.is_empty():
		# Бомба: шанс растёт с плотностью поля
		if density > 0.45 and roll < BOMB_CHANCE and since_bomb >= BOMB_MIN_INTERVAL:
			since_bomb = 0
			return {"piece": make_piece({"blocks": [Vector2i(0, 0)], "color": BOMB_COLOR, "type": "bomb"}),
				"pieces_since_bomb": since_bomb, "pieces_since_line": since_line + 1}
		# Ищем линию/столбец, близкий к заполнению (GRID_SIZE-2)
		var near_line = false
		for y in range(GRID_SIZE):
			var fl = 0
			for x in range(GRID_SIZE):
				if grid_ref[y][x] != null: fl += 1
			if fl >= GRID_SIZE - 2: near_line = true; break
		if not near_line:
			for x in range(GRID_SIZE):
				var fl = 0
				for y in range(GRID_SIZE):
					if grid_ref[y][x] != null: fl += 1
				if fl >= GRID_SIZE - 2: near_line = true; break
		if (near_line or density > 0.60) and roll < BOMB_CHANCE + LINE_CLEAR_CHANCE and since_line >= LINE_MIN_INTERVAL:
			since_line = 0
			return {"piece": make_piece({"blocks": SPECIAL_SHAPES[randi() % SPECIAL_SHAPES.size()],
				"color": LINE_CLEAR_COLOR, "type": "line_clear"}),
				"pieces_since_bomb": since_bomb + 1, "pieces_since_line": since_line}

	var idx = pick_shape_idx_smart(force_small, float(state.get("score", 0)))
	# Анти-паттерн: не более двух одинаковых форм в окне истории
	var attempts = 0
	var last_shapes: Array = state.get("last_shapes", [])
	while attempts < 8 and last_shapes.size() >= 2:
		var same_count = 0
		for s in last_shapes:
			if s == idx: same_count += 1
		if same_count < 2: break
		idx = randi() % ALL_SHAPES.size()
		attempts += 1
	var col = pick_fresh_color(state.get("last_colors", []))
	return {"piece": make_piece({"blocks": ALL_SHAPES[idx], "color": col, "type": "normal"}),
		"pieces_since_bomb": since_bomb + 1, "pieces_since_line": since_line + 1}

static func has_small_piece(piece_set: Array) -> bool:
	for p in piece_set:
		if shape_index_of(p) in SMALL_SHAPE_IDX: return true
	return false

static func count_special(piece_set: Array) -> int:
	var c = 0
	for p in piece_set:
		if p["type"] == "bomb" or p["type"] == "line_clear": c += 1
	return c

static func count_color(piece_set: Array, col: Color) -> int:
	var c = 0
	for p in piece_set:
		if p["color"].is_equal_approx(col): c += 1
	return c

static func update_history(piece_set: Array) -> Dictionary:
	"""Возвращает {last_shapes, last_colors} для анти-паттерн контроля следующей волны."""
	var shapes: Array = []
	var colors: Array = []
	for p in piece_set:
		shapes.append(shape_index_of(p))
		colors.append(p["color"])
	return {"last_shapes": shapes, "last_colors": colors}
