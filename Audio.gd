# Audio.gd — Autoload-синглтон (имя в проекте: "Audio").
# Менеджер SFX: пул заранее созданных AudioStreamPlayer (без аллокаций в рантайме).
# Плюс динамический режим по ТЗ: создание игрока и автоудаление через queue_free()
# после завершения проигрывания (play_sfx_dynamic).
extends Node

# --- Пул статичных плееров (создаются один раз при старте) ---
var _players: Dictionary = {}          # имя -> AudioStreamPlayer
var _streams: Dictionary = {}          # имя -> AudioStream (предзагруженные ресурсы)
var _music_player: AudioStreamPlayer   # отдельный плеер фоновой музыки
var _music_track: AudioStream = null

var sound_enabled: bool = true         # настройки из старого кода
var music_enabled: bool = true
var vibration_enabled: bool = true

func _ready() -> void:
	# Предзагрузка всех SFX с диска один раз — дальше только play()/stop()
	_load_stream("place", "res://sounds/place.wav")
	_load_stream("clear", "res://sounds/clear.wav")
	_load_stream("bomb", "res://sounds/bomb.wav")
	_load_stream("combo", "res://sounds/combo.wav")
	_load_stream("gameover", "res://sounds/gameover.wav")
	_load_stream("button", "res://sounds/button.wav")
	_load_stream("music_menu", "res://sounds/music_menu.ogg")
	for pname in _streams:
		if pname.begins_with("music"):
			continue
		var p := AudioStreamPlayer.new()
		p.stream = _streams[pname]
		p.bus = "Master"
		add_child(p)
		_players[pname] = p
	# Отдельный плеер фоновой музыки
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	_music_player.volume_db = -12.0
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

func _load_stream(key: String, path: String) -> void:
	if ResourceLoader.exists(path):
		_streams[key] = load(path)

# ---------------------------------------------------------------------------
# Воспроизведение SFX из пула (без аллокаций в рантайме)
# ---------------------------------------------------------------------------
func play_sfx(name: String, pitch: float = 1.0) -> void:
	if not sound_enabled:
		return
	if not _players.has(name):
		return
	var p: AudioStreamPlayer = _players[name]
	if p.stream == null:
		return
	p.pitch_scale = clampf(pitch, 0.05, 4.0)
	p.play()

func stop_sfx(name: String) -> void:
	if _players.has(name):
		(_players[name] as AudioStreamPlayer).stop()

# ---------------------------------------------------------------------------
# Динамический вариант по ТЗ: создать плеер, сыграть, удалить через queue_free()
# Используется для одноразовых/нетипичных звуков.
# ---------------------------------------------------------------------------
func play_sfx_dynamic(stream: AudioStream, pitch: float = 1.0) -> void:
	if not sound_enabled or stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = clampf(pitch, 0.05, 4.0)
	add_child(player)
	player.play()
	# Автоочистка памяти после завершения проигрывания
	player.finished.connect(player.queue_free)

# ---------------------------------------------------------------------------
# Фоновая музыка
# ---------------------------------------------------------------------------
func play_music(track_name: String) -> void:
	if not music_enabled:
		return
	if not _streams.has(track_name):
		return
	var track: AudioStream = _streams[track_name]
	if _music_player.stream == track and _music_player.playing:
		return
	_music_player.stream = track
	_music_track = track
	_music_player.play()

func stop_music() -> void:
	if _music_player.playing:
		_music_player.stop()

func _on_music_finished() -> void:
	# Зацикливание трека вручную (ogg без loop-флага)
	if _music_track != null and music_enabled:
		_music_player.play()

# ---------------------------------------------------------------------------
# Вибрация (порт из старого кода)
# ---------------------------------------------------------------------------
func vibrate(ms: int) -> void:
	if not vibration_enabled:
		return
	if not (OS.has_feature("mobile") or OS.has_feature("web")):
		return
	Input.vibrate_handheld(maxi(ms, 50))

func vibrate_combo(streak: int, density: float) -> void:
	if not vibration_enabled:
		return
	if not (OS.has_feature("mobile") or OS.has_feature("web")):
		return
	var extra := int(density * 40.0)
	if streak < 5:
		Input.vibrate_handheld(50 + streak * 12 + extra)
	else:
		Input.vibrate_handheld(45)
		await get_tree().create_timer(0.09).timeout
		Input.vibrate_handheld(60)
		if streak >= 10:
			await get_tree().create_timer(0.09).timeout
			Input.vibrate_handheld(95)
