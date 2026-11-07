extends Node
## Sound effects and music. Autoload "Sfx".

var _pool: Array[AudioStreamPlayer] = []
var _music: AudioStreamPlayer
var _music_name = ""
var _cache = {}
var muted = false


func _ready() -> void:
	for i in 8:
		var p = AudioStreamPlayer.new()
		add_child(p)
		_pool.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -6.0
	add_child(_music)
	_music.finished.connect(_on_music_finished)


func _stream(n: String) -> AudioStream:
	if not _cache.has(n):
		var path = "res://assets/audio/%s.wav" % n
		_cache[n] = load(path) if ResourceLoader.exists(path) else null
	return _cache[n]


func play(n: String, vol_db := 0.0, pitch := 1.0) -> void:
	if muted:
		return
	var s = _stream(n)
	if s == null:
		return
	for p in _pool:
		if not p.playing:
			p.stream = s
			p.volume_db = vol_db
			p.pitch_scale = pitch
			p.play()
			return
	_pool[0].stream = s
	_pool[0].play()


func music(n: String) -> void:
	if n == _music_name and _music.playing:
		return
	_music_name = n
	var s = _stream(n)
	_music.stop()
	if s == null or muted:
		return
	_music.stream = s
	_music.play()


func stop_music() -> void:
	_music_name = ""
	_music.stop()


func jingle(n: String) -> void:
	# one-shot music that does not loop
	_music_name = "__jingle"
	var s = _stream(n)
	if s == null:
		return
	_music.stream = s
	_music.play()


func _on_music_finished() -> void:
	if _music_name != "" and _music_name != "__jingle":
		_music.play()
