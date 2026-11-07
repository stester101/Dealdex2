class_name ChoiceBox
extends Control
## Vertical option list with a cursor. Usage: var i = await box.choose(["YES", "NO"], rect)
## Returns the index, or -1 when cancelled with B.

signal chosen(idx: int)

const ROW_H := 14
var _frame: NinePatchRect
var _opts: Array = []
var _sel = 0
var _cancel = true
var _active = false
var _blink = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame = UI.frame()
	add_child(_frame)
	visible = false


func choose(opts: Array, at: Vector2, cancel := true, start := 0) -> int:
	_opts = opts
	_cancel = cancel
	_sel = clampi(start, 0, opts.size() - 1)
	var w = 0
	for o in opts:
		w = maxi(w, PixelText.width_of(str(o)))
	size = Vector2(w + 30, opts.size() * ROW_H + 14)
	position = Vector2(minf(at.x, get_viewport_rect().size.x - size.x - 2), at.y - size.y)
	_frame.size = size
	visible = true
	queue_redraw()
	await get_tree().process_frame
	_active = true
	var r: int = await chosen
	_active = false
	visible = false
	return r


func _process(delta: float) -> void:
	if not _active:
		return
	_blink += delta
	if Input.is_action_just_pressed("up"):
		_sel = (_sel - 1 + _opts.size()) % _opts.size()
		Sfx.play("blip", -6.0)
		queue_redraw()
	elif Input.is_action_just_pressed("down"):
		_sel = (_sel + 1) % _opts.size()
		Sfx.play("blip", -6.0)
		queue_redraw()
	elif Input.is_action_just_pressed("a"):
		Sfx.play("confirm", -6.0)
		chosen.emit(_sel)
	elif Input.is_action_just_pressed("b") and _cancel:
		Sfx.play("cancel", -6.0)
		chosen.emit(-1)


func _gui_input(ev) -> void:
	if not _active:
		return
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		var i = int((ev.position.y - 7) / ROW_H)
		if i >= 0 and i < _opts.size():
			_sel = i
			queue_redraw()
			Sfx.play("confirm", -6.0)
			chosen.emit(i)
		accept_event()


func _draw() -> void:
	for i in _opts.size():
		var y = 8 + i * ROW_H
		if i == _sel:
			PixelText.draw_str(self, Vector2(8, y), PixelText.CURSOR, Color("d84848"))
		PixelText.draw_str(self, Vector2(18, y), str(_opts[i]), PixelText.INK, PixelText.SHADOW)
