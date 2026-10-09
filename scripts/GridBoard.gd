extends Node2D
# GridBoard.gd — сетка 8x8: размещение фигур, сжигание полных линий/столбцов,
# спецэффекты и проверка допустимости ходов.
# ВАЖНО: queue_redraw() вызывается СТРОГО при изменении состояния сетки
# (установка блока / сжигание линий / вспышки), а не каждый кадр.

signal lines_cleared(count: int)
signal density_changed(density: float)

const GRID_SIZE := PieceData.GRID_SIZE
const CELL_BASE := 101.25          # CELL_SIZE_BASE из старого кода
const FLASH_TIME := 0.3            # длительность вспышки сгоревшей клетки

var grid: Array = []               # grid[y][x] = Color | null
var cell_size := CELL_BASE
var board_origin := Vector2(75.0, 310.0)   # GRID_POS_BASE (скорректирован в set_layout)
var flash_cells: Array = []        # [{x, y, timer, max}] — подсветка сгоревших клеток

func _ready() -> void:
	reset_grid()

func reset_grid() -> void:
	grid.clear()
	for y in range(GRID_SIZE):
		var row: Array = []
		for x in range(GRID_SIZE):
			row.append(null)
		grid.append(row)
	flash_cells.clear()
	queue_redraw()

func set_layout(scale: float, origin: Vector2) -> void:
	cell_size = CELL_BASE * scale
	board_origin = origin
	queue_redraw()

# ---------------- Размещение фигур ----------------
func can_place(shape: Array, grid_pos: Vector2i) -> bool:
	# Выход за границы или коллизия с занятой клеткой => нельзя
	for b in shape:
		var x := grid_pos.x + b.x
		var y := grid_pos.y + b.y
		if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
			return false
		if grid[y][x] != null:
			return false
	return true

func place_piece(shape: Array, color: Color, grid_pos: Vector2i) -> void:
	for b in shape:
		grid[grid_pos.y + b.y][grid_pos.x + b.x] = color
	queue_redraw()  # ИЗМЕНЕНИЕ СОСТОЯНИЯ → единичный redraw
	density_changed.emit(field_density())

func pixel_to_grid(p: Vector2) -> Vector2i:
	# Перевод мировой точки (якорь фигуры) в координаты клетки сетки
	var off := p - board_origin
	return Vector2i(roundi(off.x / cell_size), roundi(off.y / cell_size))

func field_density() -> float:
	var filled := 0
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if grid[y][x] != null:
				filled += 1
	return float(filled) / float(GRID_SIZE * GRID_SIZE)

# ---------------- Полная проверка и сжигание строк/столбцов ----------------
func clear_full_lines() -> int:
	var full_rows: Array[int] = []
	var full_cols: Array[int] = []
	for y in range(GRID_SIZE):
		if is_row_full(y):
			full_rows.append(y)
	for x in range(GRID_SIZE):
		if is_column_full(x):
			full_cols.append(x)
	var count := full_rows.size() + full_cols.size()
	for y in full_rows:
		clear_row(y)
	for x in full_cols:
		clear_column(x)
	if count > 0:
		queue_redraw()  # ИЗМЕНЕНИЕ СОСТОЯНИЯ → redraw
		lines_cleared.emit(count)
	return count

func is_row_full(y: int) -> bool:
	for x in range(GRID_SIZE):
		if grid[y][x] == null:
			return false
	return true

func is_column_full(x: int) -> bool:
	for y in range(GRID_SIZE):
		if grid[y][x] == null:
			return false
	return true

func clear_row(y: int) -> void:
	for x in range(GRID_SIZE):
		if grid[y][x] != null:
			flash_cells.append({"x": x, "y": y, "timer": FLASH_TIME, "max": FLASH_TIME})
		grid[y][x] = null

func clear_column(x: int) -> void:
	for y in range(GRID_SIZE):
		if grid[y][x] != null:
			flash_cells.append({"x": x, "y": y, "timer": FLASH_TIME, "max": FLASH_TIME})
		grid[y][x] = null

# Спецэффект бомбы: взрыв 3x3 вокруг клетки (cx; cy)
func explode_at(cx: int, cy: int) -> int:
	var removed := 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var x := cx + dx
			var y := cy + dy
			if x < 0 or x >= GRID_SIZE or y < 0 or y >= GRID_SIZE:
				continue
			if grid[y][x] != null:
				removed += 1
				flash_cells.append({"x": x, "y": y, "timer": FLASH_TIME, "max": FLASH_TIME})
			grid[y][x] = null
	queue_redraw()
	return removed

# ---------------- Проверка Game Over ----------------
func has_valid_moves(available_shapes: Array) -> bool:
	# Хоть одна оставшаяся в лотке фигура должна куда-то помещаться
	for blocks in available_shapes:
		if blocks.is_empty():
			continue
		if blocks_have_spot(blocks):
			return true
	return false

func blocks_have_spot(blocks: Array) -> bool:
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			if can_place(blocks, Vector2i(x, y)):
				return true
	return false

# ---------------- Таймеры вспышек ----------------
func _process(delta: float) -> void:
	# Redraw здесь ТОЛЬКО пока есть активные вспышки — не постоянно
	if flash_cells.is_empty():
		return
	for i in range(flash_cells.size() - 1, -1, -1):
		flash_cells[i].timer -= delta
		if flash_cells[i].timer <= 0.0:
			flash_cells.remove_at(i)
	queue_redraw()

# ---------------- Отрисовка поля ----------------
func _draw() -> void:
	var o := board_origin
	# Фон-панель сетки
	draw_rect(Rect2(o - Vector2.ONE * 12.0,
		Vector2.ONE * (GRID_SIZE * cell_size) + Vector2.ONE * 24.0),
		Color("#1a0a3a"), true)
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var cell_rect := Rect2(o + Vector2(x, y) * cell_size, Vector2.ONE * cell_size)
			var col: Variant = grid[y][x]
			if col != null:
				_draw_cell(cell_rect, col)
			else:
				draw_rect(cell_rect.grow(-cell_size * 0.08), Color(1, 1, 1, 0.05), false, 1.5)
	# Вспышки сгоревших клеток
	for f in flash_cells:
		var t := clampf(f.timer / f.max, 0.0, 1.0)
		var fr := Rect2(o + Vector2(f.x, f.y) * cell_size, Vector2.ONE * cell_size)
		draw_rect(fr, Color(1, 1, 1, 0.7 * t), true)

func _draw_cell(rect: Rect2, col: Color) -> void:
	var inner := rect.grow(-rect.size.x * 0.06)
	draw_rect(inner, col, true)
	draw_rect(Rect2(inner.position + Vector2(inner.size.x * 0.08, inner.size.y * 0.08),
		Vector2(inner.size.x * 0.84, inner.size.y * 0.35)), Color(1, 1, 1, 0.3), true)
	draw_rect(inner, col.lightened(0.45), false, 2.0)
