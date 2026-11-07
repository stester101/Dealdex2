class_name TouchPanel
extends Control
## Bottom control deck: D-pad, A, B and MENU. Multi-touch; presses the real input actions,
## so all game code only reads Input actions.

var _dpad: Texture2D
var _ta: Texture2D
var _tb: Texture2D
var _touch_action = {}     # touch index -> action name
var _held = {}             # action -> count
var dpad_c = Vector2.ZERO
var a_c = Vector2.ZERO
var b_c = Vector2.ZERO
var start_r = Rect2()
const DPAD_R := 40.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_dpad = load("res://assets/ui/dpad.png")
	_ta = load("res://assets/ui/btn_a.png")
	_tb = load("res://assets/ui/btn_b.png")


func layout(vp: Vector2) -> void:
	position = Vector2(0, vp.y - Game.PANEL_H)
	size = Vector2(vp.x, Game.PANEL_H)
	dpad_c = Vector2(62, 92)
	a_c = Vector2(vp.x - 40, 74)
	b_c = Vector2(vp.x - 84, 104)
	start_r = Rect2(vp.x / 2 - 24, 160, 48, 16)
	queue_redraw()


func _draw() -> void:
	# shell
	draw_rect(Rect2(Vector2.ZERO, size), Color("221e38"))
	draw_rect(Rect2(0, 0, size.x, 3), Color("0e0c1a"))
	draw_rect(Rect2(0, 3, size.x, 2), Color("3a3458"))
	for i in 5:   # speaker grille
		draw_rect(Rect2(size.x / 2 - 22 + i * 10, 22, 4, 26), Color("15122a"))
	PixelText.draw_str(self, Vector2(size.x / 2 - 24, 60), "DEAL", Color("5a5480"))
	PixelText.draw_str(self, Vector2(size.x / 2 - 6, 70), "DEX", Color("5a5480"))
	PixelText.draw_str(self, Vector2(size.x / 2 + 12, 60), "2", Color("3cae6e"))
	# d-pad (drawn 2x)
	var dr = Rect2(dpad_c - Vector2(48, 48), Vector2(96, 96))
	draw_texture_rect(_dpad, dr, false, Color(0.82, 0.82, 0.9) if _held.has("up") or _held.has("down") or _held.has("left") or _held.has("right") else Color.WHITE)
	_draw_btn(_ta, a_c, "A", _held.has("a"))
	_draw_btn(_tb, b_c, "B", _held.has("b"))
	var sc = Color("3a3458") if not _held.has("start") else Color("2a2640")
	draw_rect(start_r.grow(1), Color("0e0c1a"))
	draw_rect(start_r, sc)
	PixelText.draw_str(self, start_r.position + Vector2(9, 4), "MENU", Color("a8a0d0"))


func _draw_btn(t: Texture2D, c: Vector2, letter: String, down: bool) -> void:
	var off = Vector2(0, 2) if down else Vector2.ZERO
	draw_texture_rect(t, Rect2(c - Vector2(20, 20) + off, Vector2(40, 40)), false, Color(0.8, 0.8, 0.8) if down else Color.WHITE)
	PixelText.draw_str(self, c - Vector2(3, 4) + off, letter, Color.WHITE, Color(0, 0, 0, 0.5))


func _action_at(p: Vector2) -> String:
	var l = p - position
	var d = l - dpad_c
	if d.length() < DPAD_R + 10:
		if d.length() < 6:
			return ""
		if absf(d.x) > absf(d.y):
			return "right" if d.x > 0 else "left"
		return "down" if d.y > 0 else "up"
	if l.distance_to(a_c) < 26:
		return "a"
	if l.distance_to(b_c) < 26:
		return "b"
	if start_r.grow(8).has_point(l):
		return "start"
	return ""


func _press(idx: int, act: String) -> void:
	var prev: String = _touch_action.get(idx, "")
	if prev == act:
		return
	if prev != "":
		_release_action(prev)
	_touch_action[idx] = act
	if act != "":
		_held[act] = int(_held.get(act, 0)) + 1
		Input.action_press(act)
		if act in ["a", "b", "start"]:
			Game.vibrate(12)
	queue_redraw()


func _release_action(act: String) -> void:
	var n = int(_held.get(act, 0)) - 1
	if n <= 0:
		_held.erase(act)
		Input.action_release(act)
	else:
		_held[act] = n


func release_all() -> void:
	for idx in _touch_action.keys():
		var a: String = _touch_action[idx]
		if a != "":
			_release_action(a)
	_touch_action.clear()
	queue_redraw()


func _input(ev) -> void:
	if not is_visible_in_tree():
		return
	if ev is InputEventScreenTouch:
		if ev.pressed:
			var act = _action_at(ev.position)
			if act != "" or ev.position.y >= position.y:
				_press(ev.index, act)
		else:
			_press(ev.index, "")
			_touch_action.erase(ev.index)
	elif ev is InputEventScreenDrag:
		if _touch_action.has(ev.index):
			var act = _action_at(ev.position)
			var prev: String = _touch_action[ev.index]
			# allow sliding across the d-pad, but do not slide onto A/B
			if prev in ["up", "down", "left", "right"] and act in ["up", "down", "left", "right"]:
				_press(ev.index, act)
	elif ev is InputEventMouseButton and not DisplayServer.is_touchscreen_available():
		# desktop testing with a mouse
		if ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.pressed:
				_press(-1, _action_at(ev.position))
			else:
				_press(-1, "")
	elif ev is InputEventMouseMotion and not DisplayServer.is_touchscreen_available() and _touch_action.has(-1):
		var act = _action_at(ev.position)
		if act in ["up", "down", "left", "right"]:
			_press(-1, act)
