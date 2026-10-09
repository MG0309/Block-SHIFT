extends Node2D
# Main.gd — глобальный менеджер игры: связывает GridBoard, Tray и UI (CanvasLayer),
# ведёт очки/комбо, генерирует волны фигур, проверяет Game Over.

@onready var board: Node2D = $GridBoard
@onready var tray: Node2D = $Tray
@onready var score_label: Label = $UI/ScoreLabel
@onready var combo_label: Label = $UI/ComboLabel
@onready var game_over_panel: Panel = $UI/GameOverPanel
@onready var restart_button: Button = $UI/GameOverPanel/RestartButton

const ALL_SHAPES := PieceData.ALL_SHAPES        # массив форм из старого кода
const COLOR_PALETTE := PieceData.COLOR_PALETTE  # палитра цветов из старого кода
const COMBO_GRACE := 3            # ходов «помиловки» комбо без линий
const SCORE_ANIM_SPEED := 6.0     # скорость анимации счётчика очков

var score := 0
var high_score := 0
var combo_streak := 0
var combo_grace_turns := 0
var game_over := false
var pieces_since_bomb := 0        # анти-паттерны генератора (порт из game.gd)
var pieces_since_line := 0
var last_shapes: Array = []
var last_colors: Array = []
var displayed_score := 0.0        # анимируемое значение счётчика

func _ready() -> void:
	randomize()
	game_over_panel.visible = false
	tray.tray_empty.connect(_on_tray_empty)
	tray.piece_dropped_from_tray.connect(_on_piece_dropped)
	board.lines_cleared.connect(_on_lines_cleared)
	restart_button.pressed.connect(restart)
	get_viewport().size_changed.connect(_apply_layout)
	_load_high_score()
	_apply_layout()
	_generate_wave()

func _apply_layout() -> void:
	# Масштабирование под любое разрешение от базовых 900x1600
	var vp := get_viewport_rect().size
	var s := minf(vp.x / 900.0, vp.y / 1600.0)
	board.set_layout(s, Vector2(75.0 * s + (vp.x - 900.0 * s) * 0.5, 310.0 * s))
	tray.set_scale(s)

# ---------------- Генерация волны из 3 фигур (порт generate_new_pieces) ----------------
func _generate_wave() -> void:
	var density := board.field_density()
	var rescue := density >= PieceData.DENSITY_RESCUE
	var emergency := density >= PieceData.DENSITY_EMERGENCY
	var state := {
		"score": score,
		"density": density,
		"grid_ref": board.grid,
		"pieces_since_bomb": pieces_since_bomb,
		"pieces_since_line": pieces_since_line,
		"last_shapes": last_shapes,
		"last_colors": last_colors,
		"force_small": rescue or emergency,
	}
	var candidate: Array = []
	for attempt in range(30):
		candidate.clear()
		for i in range(3):
			var res := PieceData.make_smart_piece(state)
			candidate.append(res["piece"])
			state["pieces_since_bomb"] = res["pieces_since_bomb"]
			state["pieces_since_line"] = res["pieces_since_line"]
		if not PieceData.has_small_piece(candidate):
			# Гарантируем хотя бы одну мелкую фигуру при забитом поле
			var forced := PieceData.make_smart_piece({
				"force_small": true, "score": score,
				"last_shapes": state["last_shapes"], "last_colors": state["last_colors"],
			})
			candidate[randi() % 3] = forced["piece"]
		# ИСПРАВЛЕНИЕ вместо жадного симулятора старого кода:
		# полный бэктрекинг всех порядков расстановки трёх фигур
		if _wave_is_solvable(candidate):
			break
	var hist := PieceData.update_history(candidate)
	last_shapes = hist["last_shapes"]
	last_colors = hist["last_colors"]
	pieces_since_bomb = state["pieces_since_bomb"]
	pieces_since_line = state["pieces_since_line"]
	tray.spawn_pieces(candidate)

func _wave_is_solvable(pieces_data: Array) -> bool:
	var sim := _clone_grid(board.grid)
	var blocks_list: Array = []
	for p in pieces_data:
		blocks_list.append(p["blocks"])
	return _backtrack(sim, blocks_list)

func _backtrack(sim: Array, remaining: Array) -> bool:
	# Перебор всех перестановок порядка фигур; линии сгорают сразу после
	# каждой установки — точно как в реальной игре.
	if remaining.is_empty():
		return true
	for i in range(remaining.size()):
		var blocks: Array = remaining[i]
		var rest := remaining.duplicate()
		rest.remove_at(i)
		for y in range(GridBoard.GRID_SIZE):
			for x in range(GridBoard.GRID_SIZE):
				if not _sim_can_place(sim, blocks, x, y):
					continue
				var next := _clone_grid(sim)
				_sim_place(next, blocks, x, y)
				_sim_clear_lines(next)
				if _backtrack(next, rest):
					return true
	return false

func _clone_grid(g: Array) -> Array:
	var out: Array = []
	for row in g:
		out.append(row.duplicate())
	return out

func _sim_can_place(g: Array, blocks: Array, sx: int, sy: int) -> bool:
	for b in blocks:
		var x := sx + b.x
		var y := sy + b.y
		if x < 0 or x >= GridBoard.GRID_SIZE or y < 0 or y >= GridBoard.GRID_SIZE:
			return false
		if g[y][x] != null:
			return false
	return true

func _sim_place(g: Array, blocks: Array, sx: int, sy: int) -> void:
	for b in blocks:
		g[sy + b.y][sx + b.x] = Color.WHITE

func _sim_clear_lines(g: Array) -> void:
	var rows: Array[int] = []
	var cols: Array[int] = []
	for y in range(GridBoard.GRID_SIZE):
		if not g[y].has(null):
			rows.append(y)
	for x in range(GridBoard.GRID_SIZE):
		var has_empty := false
		for y in range(GridBoard.GRID_SIZE):
			if g[y][x] == null:
				has_empty = true
				break
		if not has_empty:
			cols.append(x)
	for y in rows:
		for x in range(GridBoard.GRID_SIZE):
			g[y][x] = null
	for x in cols:
		for y in range(GridBoard.GRID_SIZE):
			g[y][x] = null

# ---------------- Обработка дропа фигуры ----------------
func _on_piece_dropped(piece_node: Node2D, _global_pos: Vector2) -> void:
	if game_over:
		piece_node.reset_position()
		return
	var blocks: Array = piece_node.data["blocks"]
	# Якорь = левый-верхний угол bounding rect фигуры → координата сетки
	var anchor := piece_node.shape_bounding_rect().position
	var gpos: Vector2i = board.pixel_to_grid(anchor)
	if not board.can_place(blocks, gpos):
		piece_node.reset_position()   # некорректный ход — плавный Tween-возврат
		return
	# Успешный ход: размещение, спецэффект, удаление узла из памяти
	board.place_piece(blocks, piece_node.data["color"], gpos)
	_apply_special(piece_node.data, gpos)
	score += blocks.size() * 10
	Audio.play_sfx("place")
	Audio.vibrate(35)
	tray.remove_piece(piece_node)     # внутри: piece_node.queue_free()
	var cleared := board.clear_full_lines()
	_apply_combo(cleared)
	_check_game_over()

func _apply_special(data: Dictionary, gpos: Vector2i) -> void:
	# Спецсвойства фигур: бомба (взрыв 3x3) и line_clear (крест)
	match data.get("type", "normal"):
		"bomb":
			for b in data["blocks"]:
				board.explode_at(gpos.x + b.x, gpos.y + b.y)
			Audio.play_sfx("bomb")
			Audio.vibrate(80)
		"line_clear":
			for b in data["blocks"]:
				board.clear_row(gpos.y + b.y)
				board.clear_column(gpos.x + b.x)
			Audio.play_sfx("clear", 1.6)

func _on_lines_cleared(_count: int) -> void:
	pass  # вся обработка бонусов — в _apply_combo (count приходит напрямую)

func _apply_combo(lines_cleared: int) -> void:
	# Порт apply_combo из старого кода: бонусы за линии + множитель комбо
	if lines_cleared > 0:
		combo_streak += 1
		combo_grace_turns = COMBO_GRACE
		var bonus := 0
		var title := ""
		match lines_cleared:
			1:
				bonus = 100
				title = "CLEAR!"
			2:
				bonus = 300
				title = "DOUBLE!"
			3:
				bonus = 700
				title = "TRIPLE!"
			_:
				bonus = 1200 + (lines_cleared - 4) * 500
				title = "MASSIVE!"
		var mult := minf(1.0 + (combo_streak - 1) * 0.5, 5.0)
		var total := int(bonus * mult)
		score += total
		combo_label.text = "%s · COMBO x%d +%d" % [title, combo_streak, total]
		Audio.play_sfx("combo" if combo_streak > 1 else "clear",
			clampf(1.0 + (combo_streak - 1) * 0.12, 1.0, 2.0))
		Audio.vibrate_combo(combo_streak, board.field_density())
	else:
		if combo_streak > 0:
			combo_grace_turns -= 1
			if combo_grace_turns <= 0:
				combo_streak = 0
				combo_label.text = ""

func _on_tray_empty() -> void:
	_generate_wave()

# ---------------- Определение проигрыша ----------------
func _check_game_over() -> void:
	# Проигрыш = ни одна оставшаяся в лотке фигура не встаёт на поле
	if not board.has_valid_moves(tray.get_remaining_shapes()):
		game_over = true
		Audio.play_sfx("gameover")
		Audio.vibrate(200)
		game_over_panel.visible = true

func restart() -> void:
	game_over = false
	score = 0
	displayed_score = 0.0
	combo_streak = 0
	combo_grace_turns = 0
	combo_label.text = ""
	game_over_panel.visible = false
	board.reset_grid()
	_generate_wave()

func _process(delta: float) -> void:
	# Анимация счётчика очков: обновляется ТОЛЬКО текст Label,
	# никакого queue_redraw() всего экрана (исправление из ТЗ).
	if absf(displayed_score - float(score)) > 0.5:
		displayed_score = lerpf(displayed_score, float(score), minf(1.0, delta * SCORE_ANIM_SPEED))
		score_label.text = str(int(roundf(displayed_score)))
	elif displayed_score != float(score):
		displayed_score = float(score)
		score_label.text = str(score)
		if score > high_score:
			high_score = score
			_save_high_score()

func _save_high_score() -> void:
	var f := FileAccess.open("user://highscore.save", FileAccess.WRITE)
	if f:
		f.store_string(str(high_score))

func _load_high_score() -> void:
	if FileAccess.file_exists("user://highscore.save"):
		var f := FileAccess.open("user://highscore.save", FileAccess.READ)
		if f:
			high_score = int(f.get_line())
