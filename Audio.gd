extends Node

func play_sfx(stream: AudioStream, pitch: float = 1.0):
	if not stream: return
	var player = AudioStreamPlayer.new()
	player.stream = stream
	player.pitch_scale = pitch
	add_child(player)
	player.play()
	player.finished.connect(player.queue_free) # Удаляем из памяти после проигрывания
