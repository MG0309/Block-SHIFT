extends Node2D
# Tray.gd — нижний лоток: хранение и спавн 3 фигур (узлов Piece),
# связывание сигналов piece_dropped, авто-ресpawn пустого лотка.

signal tray_empty()                              # все три фигуры использованы
signal piece_dropped_from_tray(piece_node: Node2D, global_pos: Vector2)

const PIECE_SCENE := preload("res://scenes/Piece.tscn")
# Центры трёх слотов в базовом разрешении 900x1600 (порт из старого кода)
const SLOT_CENTERS_BASE := [Vector2(170, 1240), Vector2(450, 1240), Vector2(730, 1240)]
const BASE_VIEWPORT := Vector2(900, 1600)

var ui_scale: float = 1.0
var spawn_stagger: float = 0.10   # каскадное появление фигур (PIECE_SPAWN_STAGGER)

func set_scale(scale: float) -> void:
	ui_scale = scale
	for c in get_children():
		if c.has_method("setup"):
			c.ui_scale = scale
			c._recalc_bounds()
			c.queue_redraw()
	_position_pieces()

# ---------------- Спавн волны из 3 фигур ----------------
func spawn_pieces(pieces_data: Array) -> void:
	clear_tray()
	for i in range(pieces_data.size()):
		var node := PIECE_SCENE.instantiate()
		add_child(node)
		node.setup(pieces_data[i], i, ui_scale)
		node.home_position = _slot_world_pos(i)
		node.global_position = node.home_position
		node.piece_dropped.connect(_on_piece_dropped)
		# Каскадное появление с задержкой (как в старом коде)
		node.modulate.a = 0.0
		var tw := node.create_tween()
		tw.tween_interval(spawn_stagger * i)
		tw.tween_property(node, "modulate:a", 1.0, 0.18)
	queue_redraw()

func clear_tray() -> void:
	# Полная очистка памяти старых фигур
	for c in get_children():
		c.queue_free()

func get_remaining_shapes() -> Array:
	# Массивы блоков живых (неизрасходованных) фигур — для has_valid_moves()
	var shapes: Array = []
	for c in get_children():
		if c is Node2D and c.has_method("is_empty") and not c.is_empty():
			shapes.append(c.data["blocks"])
	return shapes

func remove_piece(piece_node: Node2D) -> void:
	# Вызывается Main после успешного размещения: полная очистка памяти
	piece_node.queue_free()
	_check_tray_state()

func _check_tray_state() -> void:
	# Авто-спавн новых 3 фигур, когда лоток пуст (get_child_count() == 0).
	# Ждём кадр, чтобы queue_free() реально удалил детей из дерева.
	await get_tree().process_frame
	if get_child_count() == 0:
		tray_empty.emit()

func _on_piece_dropped(piece_node: Node2D, global_pos: Vector2) -> void:
	piece_dropped_from_tray.emit(piece_node, global_pos)

func _slot_world_pos(i: int) -> Vector2:
	# Позиция центра слота в мировых координатах (Node2D без смещения = экран)
	var base := SLOT_CENTERS_BASE[i]
	# Фигура рисуется от левого-верхнего угла bounding rect — центрируем его
	return base - Vector2.ONE * PieceData.MAX_TRAY_SIZE * 0.5 * ui_scale \
		+ Vector2.ONE * PieceData.MAX_TRAY_SIZE * 0.5

func _position_pieces() -> void:
	for c in get_children():
		if c is Node2D and c.has_method("is_empty") and not c.is_empty():
			c.home_position = _slot_world_pos(c.slot_index)
			c.global_position = c.home_position

func _draw() -> void:
	# Три слота-подложки лотка
	for i in range(SLOT_CENTERS_BASE.size()):
		var center := SLOT_CENTERS_BASE[i] * ui_scale
		var half := PieceData.MAX_TRAY_SIZE * 0.5 * ui_scale
		var r := Rect2(center - Vector2.ONE * half, Vector2.ONE * half * 2.0)
		draw_rect(r, Color(1, 1, 1, 0.04), true)
