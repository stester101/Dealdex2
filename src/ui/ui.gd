class_name UI
extends RefCounted
## Small UI helpers shared by all screens.


static func frame(kind := "frame") -> NinePatchRect:
	var n = NinePatchRect.new()
	n.texture = load("res://assets/ui/%s.png" % kind)
	n.patch_margin_left = 8
	n.patch_margin_right = 8
	n.patch_margin_top = 8
	n.patch_margin_bottom = 8
	n.mouse_filter = Control.MOUSE_FILTER_IGNORE
	n.show_behind_parent = true   # so the parent's _draw() text appears on top of the frame
	return n


static func label(t: String, pos: Vector2, col := PixelText.INK, shad := PixelText.SHADOW) -> PixelText:
	var l = PixelText.new()
	l.text = t
	l.position = pos
	l.color = col
	l.shadow = shad
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.size = Vector2(PixelText.width_of(t), PixelText.CH)
	return l


static func hp_color(frac: float) -> Color:
	if frac > 0.5:
		return Color("48c060")
	if frac > 0.2:
		return Color("e8b830")
	return Color("e04838")


static func draw_bar(ci: CanvasItem, r: Rect2, frac: float, col: Color) -> void:
	ci.draw_rect(r.grow(1), Color("2a2440"))
	ci.draw_rect(r, Color("54506a"))
	var w = floorf(r.size.x * clampf(frac, 0.0, 1.0))
	if w > 0:
		ci.draw_rect(Rect2(r.position, Vector2(w, r.size.y)), col)
		ci.draw_rect(Rect2(r.position, Vector2(w, 1)), col.lightened(0.35))


static func type_badge(ci: CanvasItem, pos: Vector2, t: String) -> void:
	var c: Color = Data.TYPE_COL.get(t, Color.GRAY)
	var w = PixelText.width_of(t.to_upper()) + 6
	ci.draw_rect(Rect2(pos, Vector2(w, 11)), c.darkened(0.45))
	ci.draw_rect(Rect2(pos + Vector2(1, 1), Vector2(w - 2, 9)), c)
	PixelText.draw_str(ci, pos + Vector2(3, 2), t.to_upper(), Color.WHITE, c.darkened(0.5))


static func fade_rect() -> ColorRect:
	var r = ColorRect.new()
	r.color = Color(0, 0, 0, 0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.set_anchors_preset(Control.PRESET_FULL_RECT)
	return r
