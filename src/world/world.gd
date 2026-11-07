class_name World
extends Node2D
## Overworld: builds a map, runs grid movement, NPCs, lighting, encounters and map scripts.

const Maps = preload("res://src/world/maps.gd")
const DIRS := [Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1)]

var map_id = ""
var map = {}
var w = 0
var h = 0
var rows: Array = []
var player: Actor
var npcs: Array[Actor] = []
var busy = false
var _solid = {}              # Vector2i -> true for prop footprints
var _ysort: Node2D
var _cam: Camera2D
var _cont = false
var _turn_wait = 0.0
var _bump_cd = 0.0
var _cooldown = 0.0
var _light_tex: GradientTexture2D
var _gulls: Array = []
var _wander_t = {}
var _banner: Control


# ================================================================== build
class GroundLayer:
	extends Node2D
	const M = preload("res://src/world/maps.gd")
	var world: World
	var water = false

	func _draw() -> void:
		var atlas: Texture2D = Data.tex("res://assets/tiles.png")
		for y in world.h:
			var row: String = world.rows[y]
			for x in world.w:
				var tn: String = M.LEGEND.get(row[x], "void")
				var is_w: bool = tn in M.WATER
				if is_w != water:
					continue
				var i = Data.tile_index(tn)
				draw_texture_rect_region(atlas, Rect2(x * 16, y * 16, 16, 16), Rect2((i % 8) * 16, (i / 8) * 16, 16, 16))


func load_map(id: String, at: Vector2i, d: int) -> void:
	for c in get_children():
		c.queue_free()
	npcs.clear()
	_solid.clear()
	_gulls.clear()
	_wander_t.clear()
	map_id = id
	map = Maps.MAPS[id]
	rows = map.rows
	h = rows.size()
	w = String(rows[0]).length()
	Game.state.map = id

	var bg = ColorRect.new()   # out-of-map backdrop (sea or night)
	bg.color = Color("1e4474") if map.get("sea", false) else Color("120e22")
	bg.position = Vector2(-400, -400)
	bg.size = Vector2(w * 16 + 800, h * 16 + 800)
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(bg)

	var water = GroundLayer.new()
	water.world = self
	water.water = true
	var mat = ShaderMaterial.new()
	mat.shader = load("res://src/shaders/water.gdshader")
	water.material = mat
	add_child(water)
	var ground = GroundLayer.new()
	ground.world = self
	add_child(ground)

	_ysort = Node2D.new()
	_ysort.y_sort_enabled = true
	add_child(_ysort)

	_light_tex = GradientTexture2D.new()
	_light_tex.width = 128
	_light_tex.height = 128
	_light_tex.fill = GradientTexture2D.FILL_RADIAL
	_light_tex.fill_from = Vector2(0.5, 0.5)
	_light_tex.fill_to = Vector2(1.0, 0.5)
	var g = Gradient.new()
	g.set_color(0, Color(1, 1, 1, 1))
	g.set_color(1, Color(1, 1, 1, 0))
	g.add_point(0.45, Color(1, 1, 1, 0.45))
	_light_tex.gradient = g

	for p in map.get("props", []):
		_add_prop(p[0], Vector2i(p[1], p[2]))
	for L in map.get("lights", []):
		_add_light(Vector2(L[0], L[1]), L[2], L[3], Color(L[4]))

	var cm = CanvasModulate.new()
	cm.color = map.get("tint", Color.WHITE)
	add_child(cm)

	for n in map.get("npcs", []):
		if n.has("hidden_unless") and not Game.flag(n.hidden_unless):
			continue
		if n.has("hidden_if") and Game.flag(n.hidden_if):
			continue
		var a = Actor.new()
		a.id = n.id
		a.data = n
		_ysort.add_child(a)
		a.setup(n.sheet, Vector2i(n.x, n.y), n.dir)
		npcs.append(a)

	player = Actor.new()
	player.id = "player"
	_ysort.add_child(player)
	player.setup("hero", at, d)
	player.step_finished.connect(_on_player_step)
	_update_grass(player)

	if map.get("gulls", false):
		_make_gulls()
		_make_smoke(Vector2(11 * 16 + 16, 7 * 16 - 38))

	_cam = Camera2D.new()
	add_child(_cam)
	_cam.make_current()
	_update_camera()
	Sfx.music(map.get("music", ""))
	Game.state.x = at.x
	Game.state.y = at.y
	_show_banner(map.get("name", ""))


func _add_prop(pname: String, t: Vector2i) -> void:
	var P: Dictionary = Data.PROPS[pname]
	var tx: Texture2D = Data.tex(P.tex)
	var node = Node2D.new()
	node.position = Vector2(t.x * 16, (t.y + 1) * 16)
	var s = Sprite2D.new()
	s.texture = tx
	s.centered = false
	s.position = Vector2(P.get("ox", 0), -tx.get_height())
	node.add_child(s)
	_ysort.add_child(node)
	for fy in int(P.fh):
		for fx in int(P.fw):
			_solid[Vector2i(t.x + fx, t.y - fy)] = true
	for L in P.get("lights", []):
		_add_light(node.position + Vector2(L[0], L[1]), L[2], L[3], Color(L[4]))


func _add_light(pos: Vector2, energy: float, sc: float, col: Color) -> void:
	var tint: Color = map.get("tint", Color.WHITE)
	if tint.v >= 0.85 and not map.get("indoor", false):
		return   # daylight maps skip lamps
	var l = PointLight2D.new()
	l.texture = _light_tex
	l.position = pos
	l.energy = energy
	l.texture_scale = sc
	l.color = col
	add_child(l)
	# gentle flicker
	var tw = l.create_tween().set_loops()
	tw.tween_property(l, "energy", energy * 0.9, randf_range(0.6, 1.2))
	tw.tween_property(l, "energy", energy, randf_range(0.6, 1.2))


func _make_gulls() -> void:
	for i in 3:
		var s = Sprite2D.new()
		s.texture = Data.tex("res://assets/props/gull.png")
		s.hframes = 2
		s.position = Vector2(randf_range(0, w * 16), randf_range(10, h * 16 - 40))
		s.z_index = 20
		s.set_meta("v", Vector2(randf_range(14, 24), randf_range(-3, 3)))
		add_child(s)
		_gulls.append(s)


func _make_smoke(pos: Vector2) -> void:
	var p = CPUParticles2D.new()
	p.position = pos
	p.amount = 18
	p.lifetime = 2.6
	p.direction = Vector2(0.3, -1)
	p.spread = 12.0
	p.initial_velocity_min = 10.0
	p.initial_velocity_max = 16.0
	p.gravity = Vector2(10, -4)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 4.0
	var ramp = Gradient.new()
	ramp.set_color(0, Color(0.35, 0.35, 0.4, 0.9))
	ramp.set_color(1, Color(0.7, 0.7, 0.75, 0.0))
	p.color_ramp = ramp
	p.z_index = 15
	add_child(p)


func _show_banner(text: String) -> void:
	if text == "" or Game.main == null:
		return
	Game.main.banner(text)


# ================================================================== queries
func tile_name(t: Vector2i) -> String:
	if t.x < 0 or t.y < 0 or t.x >= w or t.y >= h:
		return "void"
	return Maps.LEGEND.get(String(rows[t.y])[t.x], "void")


func npc_at(t: Vector2i) -> Actor:
	for n in npcs:
		if n.tile == t:
			return n
	return null


func blocked(t: Vector2i, me: Actor = null) -> bool:
	if tile_name(t) in Maps.SOLID:
		return true
	if _solid.has(t):
		return true
	for n in npcs:
		if n != me and n.tile == t:
			return true
	if player and player != me and player.tile == t:
		return true
	return false


func _key(t: Vector2i) -> String:
	return "%d,%d" % [t.x, t.y]


# ================================================================== loop
func _process(delta: float) -> void:
	_bump_cd = maxf(0.0, _bump_cd - delta)
	for s in _gulls:
		var v: Vector2 = s.get_meta("v")
		s.position += v * delta
		if s.position.x > w * 16 + 30:
			s.position.x = -30
			s.position.y = randf_range(10, h * 16 - 40)
		s.frame = int(Time.get_ticks_msec() / 220) % 2
	_wander(delta)
	_update_camera()
	if player == null:
		return
	if busy or Game.main.is_ui_open():
		_cooldown = 0.12   # ignore the button press that just closed a dialog or menu
		return
	if player.moving:
		return
	if _cooldown > 0.0:
		_cooldown -= delta
		return
	if Input.is_action_just_pressed("start"):
		Game.main.open_menu()
		return
	if Input.is_action_just_pressed("a"):
		_interact()
		return
	var d = _input_dir()
	if d < 0:
		_cont = false
		_turn_wait = 0.0
		return
	if d != player.dir and not _cont:
		player.face(d)
		_turn_wait = 0.09
		_cont = true
		return
	if _turn_wait > 0.0:
		_turn_wait -= delta
		return
	_try_move(d)


func _input_dir() -> int:
	if Input.is_action_pressed("up"):
		return 3
	if Input.is_action_pressed("down"):
		return 0
	if Input.is_action_pressed("left"):
		return 1
	if Input.is_action_pressed("right"):
		return 2
	return -1


func _update_camera() -> void:
	if _cam == null or player == null:
		return
	var vp = get_viewport_rect().size
	var sh = vp.y - Game.PANEL_H
	var mw = w * 16.0
	var mh = h * 16.0
	var tl = player.position - Vector2(vp.x / 2.0, sh / 2.0 + 8.0)
	tl.x = (mw - vp.x) / 2.0 if mw <= vp.x else clampf(tl.x, 0.0, mw - vp.x)
	tl.y = (mh - sh) / 2.0 if mh <= sh else clampf(tl.y, 0.0, mh - sh)
	_cam.position = (tl + vp / 2.0).round()


func _try_move(d: int) -> void:
	player.face(d)
	var t: Vector2i = player.tile + DIRS[d]
	var doors: Dictionary = map.get("doors", {})
	if doors.has(_key(t)):
		_use_door(doors[_key(t)])
		return
	if (t.x < 0 or t.x >= w or t.y < 0 or t.y >= h) and map.has("edges"):
		run_script(map.edges)
		return
	if blocked(t, player):
		if _bump_cd <= 0.0:
			Sfx.play("bump", -4.0)
			_bump_cd = 0.3
		_cont = false
		return
	player.start_step(d, Input.is_action_pressed("b"))


func _on_player_step() -> void:
	Game.state.x = player.tile.x
	Game.state.y = player.tile.y
	Game.state.dir = player.dir
	Game.state.steps = int(Game.state.steps) + 1
	_update_grass(player)
	var warps: Dictionary = map.get("warps", {})
	if warps.has(_key(player.tile)):
		var wp: Dictionary = warps[_key(player.tile)]
		warp(wp.to, Vector2i(wp.x, wp.y), wp.dir)
		return
	var seen: bool = await _check_trainers()
	if seen:
		return
	_check_encounter()


func _update_grass(a: Actor) -> void:
	a.grass_overlay.visible = tile_name(a.tile) == "tallgrass"


func _check_encounter() -> void:
	var enc: Dictionary = map.get("encounters", {})
	if enc.is_empty() or not (tile_name(player.tile) in enc.tiles):
		return
	if Game.state.party.is_empty():
		return
	if randf() >= float(enc.rate):
		return
	var total = 0
	for e in enc.table:
		total += int(e[3])
	var r = randi() % total
	for e in enc.table:
		r -= int(e[3])
		if r < 0:
			var mon = Game.mk_mon(e[0], randi_range(int(e[1]), int(e[2])))
			busy = true
			_cont = false
			var res: String = await Game.main.start_battle({"kind": "wild", "foes": [mon], "bg": map.get("battle_bg", "canal")})
			busy = false
			if res == "lose":
				await whiteout()
			return


func _interact() -> void:
	var t: Vector2i = player.tile + DIRS[player.dir]
	var n = npc_at(t)
	if n:
		if n.data.has("trainer"):
			await _trainer_talk(n)
		else:
			n.face_towards(player.tile)
			await run_script(n.data.get("talk", ""), n)
		return
	var signs: Dictionary = map.get("signs", {})
	if signs.has(_key(t)):
		busy = true
		await Game.main.say(signs[_key(t)])
		busy = false
		return
	var doors: Dictionary = map.get("doors", {})
	if doors.has(_key(t)):
		_use_door(doors[_key(t)])


func _use_door(door: Dictionary) -> void:
	if door.has("script"):
		run_script(door.script)
	else:
		Sfx.play("door")
		warp(door.to, Vector2i(door.x, door.y), door.dir)


func warp(to: String, at: Vector2i, d: int) -> void:
	busy = true
	_cont = false
	await Game.main.fade_out(0.25)
	load_map(to, at, d)
	await Game.main.fade_in(0.25)
	busy = false


func _wander(delta: float) -> void:
	if busy:
		return
	for n in npcs:
		var r = int(n.data.get("wander", 0))
		if r <= 0 or n.moving:
			continue
		var t: float = _wander_t.get(n.id, randf_range(1.0, 3.0)) - delta
		if t > 0.0:
			_wander_t[n.id] = t
			continue
		_wander_t[n.id] = randf_range(1.5, 3.5)
		var d = randi() % 4
		var dest: Vector2i = n.tile + DIRS[d]
		var home = Vector2i(int(n.data.x), int(n.data.y))
		if absi(dest.x - home.x) > r or absi(dest.y - home.y) > r or blocked(dest, n) or tile_name(dest) == "tallgrass":
			n.face(d)
			continue
		n.start_step(d)


# ================================================================== trainers
func _check_trainers() -> bool:
	for n in npcs:
		if not n.data.has("trainer") or Game.flag("beat_" + str(n.data.trainer)):
			continue
		var sight = int(n.data.get("sight", 4))
		var dv: Vector2i = DIRS[n.dir]
		var t: Vector2i = n.tile
		for i in sight:
			t += dv
			if t == player.tile:
				busy = true
				_cont = false
				await n.show_emote()
				# walk up to the player
				var path: Array = []
				var c: Vector2i = n.tile
				while c + dv != player.tile:
					c += dv
					path.append(n.dir)
				if path.size() > 0:
					await n.walk_path(path)
				player.face_towards(n.tile)
				await _trainer_talk(n)
				return true
			if blocked(t, n) and t != player.tile:
				break
	return false


func _trainer_talk(n: Actor) -> void:
	busy = true
	var tid: String = n.data.trainer
	var T: Dictionary = Maps.TRAINERS[tid]
	n.face_towards(player.tile)
	if Game.flag("beat_" + tid):
		await Game.main.say(T.after, T.name)
		busy = false
		return
	await Game.main.say(T.intro, T.name)
	var foes: Array = []
	for pair in T.team:
		foes.append(Game.mk_mon(pair[0], int(pair[1])))
	var res: String = await Game.main.start_battle({"kind": "trainer", "foes": foes, "name": T.name, "coins": T.coins,
		"sheet": n.data.sheet, "bg": map.get("battle_bg", "canal"), "lose_line": T.lose[0]})
	if res == "win":
		Game.set_flag("beat_" + tid)
	else:
		await whiteout()
	busy = false


func whiteout() -> void:
	busy = true
	await Game.main.say(["You rush your strains back to safety...", "...and lose a few coins on the way."])
	Game.state.coins = int(Game.state.coins) / 2
	Game.heal_all()
	await Game.main.fade_out(0.4)
	load_map(Game.state.heal_map, Vector2i(int(Game.state.heal_x), int(Game.state.heal_y)), 0)
	await Game.main.fade_in(0.4)
	busy = false


# ================================================================== scripts
func npc(id: String) -> Actor:
	for n in npcs:
		if n.id == id:
			return n
	return null


func spawn_npc(id: String, sheet: String, t: Vector2i, d: int, talk := "") -> Actor:
	var a = Actor.new()
	a.id = id
	a.data = {"id": id, "sheet": sheet, "x": t.x, "y": t.y, "dir": d, "talk": talk}
	_ysort.add_child(a)
	a.setup(sheet, t, d)
	npcs.append(a)
	return a


func run_script(id: String, who: Actor = null) -> void:
	busy = true
	_cont = false
	var S = Game.main.story
	await S.run(id, self, who)
	busy = false
