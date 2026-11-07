class_name DialogBox
extends Control
## Typewriter dialog box. Usage: await box.say(["Line one.", "Line two."], "KETTLE")

const LINES := 3
const PAD := Vector2(10, 9)
const CPS := 55.0

var _frame: NinePatchRect
var _label: PixelText
var _name_frame: NinePatchRect
var _name_label: PixelText
var _arrow_t = 0.0
var _waiting = false
var _tapped = false
var fast = false
var auto_advance = 0.0   # >0: pages also advance on their own after this many seconds


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	_frame = UI.frame()
	add_child(_frame)
	_label = PixelText.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_label)
	_name_frame = UI.frame()
	add_child(_name_frame)
	_name_label = UI.label("", Vector2.ZERO)
	add_child(_name_label)
	visible = false


func layout(r: Rect2) -> void:
	position = r.position
	size = r.size
	_frame.position = Vector2.ZERO
	_frame.size = r.size
	_label.position = PAD
	_label.size = r.size - PAD * 2
	_label.wrap_px = int(r.size.x - PAD.x * 2)


func _gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		_tapped = true
		accept_event()


func _advance_pressed() -> bool:
	var p = _tapped or Input.is_action_just_pressed("a") or Input.is_action_just_pressed("b")
	_tapped = false
	return p


func _process(delta: float) -> void:
	if _waiting:
		_arrow_t += delta
		queue_redraw()


func _draw() -> void:
	if _waiting and fmod(_arrow_t, 0.6) < 0.4:
		PixelText.draw_str(self, Vector2(size.x - 16, size.y - 16 + (1 if fmod(_arrow_t, 0.6) < 0.2 else 0)), "v", Color("d84848"))


func _set_speaker(speaker: String) -> void:
	_name_frame.visible = speaker != ""
	_name_label.visible = speaker != ""
	if speaker != "":
		var w = PixelText.width_of(speaker) + 16
		_name_frame.position = Vector2(4, -18)
		_name_frame.size = Vector2(w, 22)
		_name_label.text = speaker
		_name_label.position = Vector2(12, -11)
		_name_label.color = Color("3c5a9a")


## Shows every line (paginated), waits for A/tap between pages.
func say(lines: Array, speaker := "", wait_last := true) -> void:
	visible = true
	_set_speaker(speaker)
	for li in lines.size():
		var pages = _paginate(str(lines[li]))
		for pi in pages.size():
			await _type(pages[pi])
			var last = li == lines.size() - 1 and pi == pages.size() - 1
			if last and not wait_last:
				return
			await _wait()
	visible = false


func show_text(t: String) -> void:
	## Instantly shows text, no wait (used for prompts).
	visible = true
	_set_speaker("")
	_label.text = t
	_label.visible_chars = -1


func close() -> void:
	visible = false
	_waiting = false


func _paginate(t: String) -> Array:
	var lines = PixelText.wrap_lines(t, _label.wrap_px)
	var pages: Array = []
	var i = 0
	while i < lines.size():
		var chunk = PackedStringArray()
		for k in LINES:
			if i + k < lines.size():
				chunk.append(lines[i + k])
		pages.append("\n".join(chunk))
		i += LINES
	return pages


func _type(page: String) -> void:
	_label.text = page
	_label.visible_chars = 0
	var total = page.length()
	var shown = 0.0
	_tapped = false
	await get_tree().process_frame
	while shown < total:
		await get_tree().process_frame
		if _advance_pressed():
			break
		var before = int(shown)
		shown += get_process_delta_time() * CPS * (3.0 if fast or Input.is_action_pressed("b") else 1.0)
		if int(shown) / 2 != before / 2:
			Sfx.play("blip", -14.0)
		_label.visible_chars = int(shown)
	_label.visible_chars = -1


func _wait() -> void:
	_waiting = true
	_arrow_t = 0.0
	var t = 0.0
	while true:
		await get_tree().process_frame
		t += get_process_delta_time()
		if _advance_pressed():
			break
		if auto_advance > 0.0 and t >= auto_advance:
			break
	_waiting = false
	queue_redraw()
	Sfx.play("select", -10.0)
