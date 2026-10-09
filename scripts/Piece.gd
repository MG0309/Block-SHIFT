extends Node2D
# Piece.gd — одна фигура: drag & drop (мышь/касание), отрисовка только своих
# блоков, сигнал piece_dropped при отпускании, плавный Tween-возврат.

signal piece_dropped(piece_node: Node2D, global_pos: Vector2)

var data: Dictionary = {"blocks": [], "color": Color.WHITE, "type": "normal"}
var slot_index: int = 0                     # индекс слота в лотке
var home_position: Vector2 = Vector2.ZERO   # позиция слота в мировых координатах
var ui_scale: float = 1.0

var _dragging := false
var _returning := false
var _drag_offset := Vector2.ZERO

# Кэш габаритов фигуры (пересчитывается один раз в setup)
var _cell_step := 54.0
var _cell_size := 48.0
var _shape_extent := Vector2.ZERO
var _shape_origin := Vector2.ZERO

func setup(piece_data: Dictionary, index: int, p_ui_scale: float) -> void:
	data = piece_data
	slot_index = index
	ui_scale = p_ui_scale
	_recalc_bounds()

func _recalc_bounds() -> void:
	# Определяем габариты формы в клетках и масштаб под MAX_TRAY_SIZE
	var min_x := 999
	var max_x := -999
	var min_y := 999
	var max_y := -999
	for b in data["blocks"]:
		min_x = mini(min_x, b.x)
		max_x = maxi(max_x, b.x)
		min_y = mini(min_y, b.y)
		max_y = maxi(max_y, b.y)
	var fit := 1.0
	var span_cells := maxf(float(max_x - min_x + 1), float(max_y - min_y + 1))
	if span_cells * PieceData.TRAY_BLOCK_STEP * ui_scale > PieceData.MAX_TRAY_SIZE:
		fit = PieceData.MAX_TRAY_SIZE / (span_cells * PieceData.TRAY_BLOCK_STEP * ui_scale)
	_cell_step = PieceData.TRAY_BLOCK_STEP * fit * ui_scale
	_cell_size = PieceData.TRAY_BLOCK_SIZE * fit * ui_scale
	_shape_extent = Vector2((max_x - min_x + 1) * _cell_step, (max_y - min_y + 1) * _cell_step)
	_shape_origin = Vector2(min_x * _cell_step, min_y * _cell_step)

func is_empty() -> bool:
	return data["blocks"].is_empty()

func shape_bounding_rect() -> Rect2:
	# Мировой прямоугольник фигуры; его левый-верхний угол — якорь для сетки
	return Rect2(global_position + _shape_origin, _shape_extent)

func contains_global_point(p: Vector2) -> bool:
	# Попадание касания с небольшим запасом по краям (удобно на телефоне)
	var local := to_local(p)
	var pad := 10.0 * ui_scale
	return Rect2(_shape_origin - Vector2.ONE * pad,
		_shape_extent + Vector2.ONE * pad * 2.0).has_point(local)

# ---------------- Ввод: drag & drop ----------------
func _input(event: InputEvent) -> void:
	if _returning or is_empty():
		return
	if event is InputEventScreenTouch:
		if event.pressed and contains_global_point(event.position):
			_begin_drag(event.position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _dragging:
			_end_drag(event.position)
			get_viewport().set_input_as_handled()
		return
	if event is InputEventScreenDrag and _dragging:
		global_position = event.global_position - _drag_offset
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and contains_global_point(event.global_position):
			_begin_drag(event.global_position)
			get_viewport().set_input_as_handled()
		elif not event.pressed and _dragging:
			_end_drag(event.global_position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion and _dragging:
		global_position = event.global_position - _drag_offset

func _begin_drag(pos: Vector2) -> void:
	_dragging = true
	_drag_offset = pos - global_position
	z_index = 100  # во время перетаскивания рисуем поверх всего
	move_to_front()

func _end_drag(pos: Vector2) -> void:
	_dragging = false
	z_index = 0
	piece_dropped.emit(self, pos)

# ---------------- Плавный возврат в лоток при некорректном ходе ----------------
func reset_position() -> void:
	if _returning:
		return
	_returning = true
	var tw := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "global_position", home_position, 0.25)
	tw.tween_callback(func(): _returning = false)

# ---------------- Отрисовка только СВОЕЙ фигуры ----------------
func _draw() -> void:
	if is_empty():
		return
	for b in data["blocks"]:
		var r := Rect2(Vector2(b.x, b.y) * _cell_step, Vector2.ONE * _cell_size)
		_draw_neon_block(r, data["color"], data.get("type", "normal"))

func _draw_neon_block(rect: Rect2, col: Color, type: String) -> void:
	# Стиль неоновых блоков из старого _render_block_styled (упрощённая версия)
	var inner := rect.grow(-rect.size.x * 0.06)
	draw_rect(inner, col, true)
	# Верхний блик
	draw_rect(Rect2(inner.position + Vector2(inner.size.x * 0.08, inner.size.y * 0.08),
		Vector2(inner.size.x * 0.84, inner.size.y * 0.35)), Color(1, 1, 1, 0.35), true)
	# Тень снизу
	draw_rect(Rect2(inner.position + Vector2(0.0, inner.size.y * 0.8),
		Vector2(inner.size.x, inner.size.y * 0.2)), Color(0, 0, 0, 0.3), true)
	# Обводка
	draw_rect(inner, col.lightened(0.5), false, maxf(1.5, 2.0 * ui_scale))
	if type == "bomb":
		draw_circle(inner.get_center(), inner.size.x * 0.28, Color(1, 0.4, 0.9, 0.9))
	elif type == "line_clear":
		var c := inner.get_center()
		draw_line(c - Vector2.ONE * inner.size.x * 0.25,
			c + Vector2.ONE * inner.size.x * 0.25, Color.WHITE, 3.0)
