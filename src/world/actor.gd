class_name Actor
extends Node2D
## A character on the tile grid. Origin = feet (bottom-centre of its tile).
## Sheet layout: 3 frames (stand, stepA, stepB) x 4 rows (down, left, right, up), 16x24 each.

signal step_finished

const DIRS := [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]
const WALK_T := 0.2
const RUN_T := 0.11

var id = ""
var tile = Vector2i.ZERO
var dir = 0
var moving = false
var data = {}               # npc definition from the map
var sprite: Sprite2D
var grass_overlay: Sprite2D
var emote: Sprite2D
var _from = Vector2.ZERO
var _to = Vector2.ZERO
var _t = 0.0
var _dur = WALK_T
var _parity = 0


func setup(sheet: String, t: Vector2i, d := 0) -> void:
	var sh = Sprite2D.new()
	sh.texture = Data.tex("res://assets/props/shadow.png")
	sh.centered = false
	sh.position = Vector2(-8, -4)
	add_child(sh)
	sprite = Sprite2D.new()
	sprite.texture = Data.tex("res://assets/chars/%s.png" % sheet)
	sprite.centered = false
	sprite.region_enabled = true
	sprite.position = Vector2(-8, -25)
	add_child(sprite)
	grass_overlay = Sprite2D.new()
	grass_overlay.texture = Data.tex("res://assets/tiles.png")
	grass_overlay.region_enabled = true
	var gi = Data.tile_index("tallgrass")
	grass_overlay.region_rect = Rect2((gi % 8) * 16, (gi / 8) * 16 + 9, 16, 7)
	grass_overlay.centered = false
	grass_overlay.position = Vector2(-8, -7)
	grass_overlay.visible = false
	add_child(grass_overlay)
	emote = Sprite2D.new()
	emote.texture = Data.tex("res://assets/ui/emote_alert.png")
	emote.position = Vector2(0, -32)
	emote.visible = false
	add_child(emote)
	place(t, d)


func place(t: Vector2i, d := -1) -> void:
	tile = t
	if d >= 0:
		dir = d
	position = Vector2(t.x * 16 + 8, t.y * 16 + 16)
	moving = false
	_frame(0)


func face(d: int) -> void:
	dir = d
	_frame(0)


func face_towards(t: Vector2i) -> void:
	var d = t - tile
	if absi(d.x) > absi(d.y):
		face(2 if d.x > 0 else 1)
	elif d.y != 0:
		face(0 if d.y > 0 else 3)


func _frame(f: int) -> void:
	if sprite:
		sprite.region_rect = Rect2(f * 16, dir * 24, 16, 24)


func start_step(d: int, run := false) -> void:
	dir = d
	_from = position
	tile += DIRS[d]
	_to = Vector2(tile.x * 16 + 8, tile.y * 16 + 16)
	_t = 0.0
	_dur = RUN_T if run else WALK_T
	moving = true
	_parity = 1 - _parity


func _process(delta: float) -> void:
	if not moving:
		return
	_t += delta
	var k = clampf(_t / _dur, 0.0, 1.0)
	position = _from.lerp(_to, k).round()
	_frame((1 + _parity) if k < 0.6 else 0)
	if k >= 1.0:
		moving = false
		_frame(0)
		step_finished.emit()


func walk_path(dirs: Array, run := false) -> void:
	## Scripted movement for cutscenes.
	for d in dirs:
		start_step(int(d), run)
		await step_finished


func show_emote(sec := 0.7) -> void:
	emote.visible = true
	emote.position = Vector2(0, -30)
	var tw = create_tween()
	tw.tween_property(emote, "position:y", -34.0, 0.08)
	tw.tween_property(emote, "position:y", -32.0, 0.08)
	Sfx.play("select")
	await get_tree().create_timer(sec).timeout
	emote.visible = false
