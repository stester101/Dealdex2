extends Control
## Title screen: lamplit canal at night, logo, NEW GAME / CONTINUE.

signal _picked(v: String)

var _t = 0.0
var _bg: Texture2D
var _logo: Texture2D
var _ready_for_input = false
var _sprites: Array = []
var _choice: ChoiceBox


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_bg = load("res://assets/battle/bg_canal.png")
	_logo = load("res://assets/ui/logo.png")


func run() -> String:
	var vp = get_viewport_rect().size
	size = vp
	# strains bobbing on the quay
	var xs = [44, 135, 226]
	var sps = ["tulipup", "stroopuff", "klompy"]
	for i in 3:
		var s = Sprite2D.new()
		s.texture = Data.strain_tex(sps[i])
		s.position = Vector2(xs[i], 0)
		add_child(s)
		_sprites.append(s)
	Sfx.music("music_quay")
	await get_tree().create_timer(0.4).timeout
	_ready_for_input = true
	while true:
		await get_tree().process_frame
		if Input.is_action_just_pressed("a") or Input.is_action_just_pressed("start") or _tapped:
			_tapped = false
			break
	Sfx.play("confirm")
	_ready_for_input = false
	var opts = ["NEW GAME"]
	if Game.has_save():
		opts.push_front("CONTINUE")
	_choice = Game.main.choice
	var r: int = await _choice.choose(opts, Vector2(vp.x / 2 + 40, Game.main.screen_h() - 20), false)
	var pick: String = "continue" if opts[r] == "CONTINUE" else "new"
	await Game.main.fade_out(0.4)
	return pick


var _tapped = false


func _gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.pressed and _ready_for_input:
		_tapped = true


func _process(delta: float) -> void:
	_t += delta
	var sh: float = Game.main.screen_h() if Game.main else 400.0
	for i in _sprites.size():
		var s: Sprite2D = _sprites[i]
		s.position.y = sh - 74 + round(sin(_t * 2.2 + i * 1.7) * 2.0)
	queue_redraw()


func _draw() -> void:
	var vp = get_viewport_rect().size
	var sh: float = Game.main.screen_h() if Game.main else 400.0
	# night sky gradient (banded)
	var bands = 12
	for i in bands:
		var c = Color("120e2e").lerp(Color("5a3a6a"), float(i) / bands)
		draw_rect(Rect2(0, i * sh / bands, vp.x, sh / bands + 1), c)
	# stars
	for i in 40:
		var x = fmod(i * 73.3, vp.x)
		var y = fmod(i * 41.7, sh * 0.45)
		if fmod(_t * 1.5 + i * 0.37, 2.0) < 1.6:
			draw_rect(Rect2(x, y, 1, 1), Color(1, 1, 0.9, 0.8))
	# canal scene at the bottom of the screen area
	draw_texture(_bg, Vector2(0, sh - _bg.get_height()))
	# logo
	var ly = 46.0 + round(sin(_t * 1.6) * 2.0)
	draw_texture(_logo, Vector2(floor((vp.x - _logo.get_width()) / 2.0), ly))
	PixelText.draw_str(self, Vector2(floor((vp.x - PixelText.width_of("AMSTERDAM & BACK")) / 2.0), ly + 44), "AMSTERDAM & BACK", Color("ffe8a0"), Color("2a1e3a"))
	if _ready_for_input and fmod(_t, 1.0) < 0.7:
		var msg = "TAP TO START"
		PixelText.draw_str(self, Vector2(floor((vp.x - PixelText.width_of(msg)) / 2.0), sh * 0.42), msg, Color.WHITE, Color("2a1e3a"))
	PixelText.draw_str(self, Vector2(4, sh - 12), "v0.1 OPENING SLICE", Color(1, 1, 1, 0.5))
