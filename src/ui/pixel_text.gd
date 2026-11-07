class_name PixelText
extends Control
## Bitmap text drawn from assets/ui/font.png (6x8 cells, ASCII 32..127).
## Char 127 is a right-pointing cursor triangle; use PixelText.CURSOR.

const CW := 6
const CH := 8
const LINE_H := 11
const CURSOR := "\u007f"
const INK := Color("2a2440")
const SHADOW := Color("c8c0d8")

static var _font: Texture2D

var text = "":
	set(v):
		text = v
		queue_redraw()
var color = INK
var shadow = SHADOW
var wrap_px = 0
var visible_chars = -1:
	set(v):
		visible_chars = v
		queue_redraw()
var scale_px = 1
var align = 0   # 0 left, 1 centre, 2 right


static func font() -> Texture2D:
	if _font == null:
		_font = load("res://assets/ui/font.png")
	return _font


static func width_of(s: String, sc := 1) -> int:
	return s.length() * CW * sc


static func wrap_lines(t: String, width_px: int, sc := 1) -> PackedStringArray:
	var out = PackedStringArray()
	for para in t.split("\n"):
		if width_px <= 0:
			out.append(para)
			continue
		var max_chars = maxi(1, width_px / (CW * sc))
		var line = ""
		for word in para.split(" "):
			var trial = word if line == "" else line + " " + word
			if trial.length() > max_chars and line != "":
				out.append(line)
				line = word
			else:
				line = trial
		out.append(line)
	return out


static func draw_str(ci: CanvasItem, pos: Vector2, s: String, col: Color, shad := Color(0, 0, 0, 0), sc := 1) -> void:
	var f = font()
	var x = pos.x
	for i in s.length():
		var code = s.unicode_at(i)
		if code < 32 or code > 127:
			code = 63
		var idx = code - 32
		var src = Rect2((idx % 16) * CW, (idx / 16) * CH, CW, CH)
		if code != 32:
			if shad.a > 0.0:
				ci.draw_texture_rect_region(f, Rect2(x + sc, pos.y + sc, CW * sc, CH * sc), src, shad)
			ci.draw_texture_rect_region(f, Rect2(x, pos.y, CW * sc, CH * sc), src, col)
		x += CW * sc


func _draw() -> void:
	var lines = wrap_lines(text, wrap_px, scale_px)
	var left = visible_chars if visible_chars >= 0 else 1 << 30
	var y = 0.0
	for line in lines:
		if left <= 0:
			break
		var shown = line.substr(0, mini(line.length(), left))
		left -= line.length() + 1
		var x = 0.0
		if align == 1:
			x = floor((size.x - width_of(line, scale_px)) / 2.0)
		elif align == 2:
			x = size.x - width_of(line, scale_px)
		draw_str(self, Vector2(x, y), shown, color, shadow, scale_px)
		y += LINE_H * scale_px


func char_count() -> int:
	var n = 0
	for line in wrap_lines(text, wrap_px, scale_px):
		n += line.length() + 1
	return n
