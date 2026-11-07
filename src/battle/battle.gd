extends Control
## Turn-based strain battle with animated sprites, HUDs, catching and XP.
## Usage: b.setup(cfg); var result: String = await b.run()   # "win" | "lose" | "run" | "caught"

const Menus = preload("res://src/ui/menus.gd")
const STG_KEYS := ["atk", "def", "sa", "sd", "spe"]
const BG_TOP := {"ferry": Color("6ab0e8"), "canal": Color("2a2a6a")}

signal _btn(i: int)

var cfg = {}
var kind = "wild"
var foes: Array = []
var foe_i = 0
var me = {}
var op = {}
var bg_key = "canal"
var bg_tex: Texture2D
var plat_tex: Texture2D
var foe_spr: Sprite2D
var my_spr: Sprite2D
var trainer_spr: Sprite2D
var tin_spr: Sprite2D
var msg: DialogBox
var mode = "none":          # none | cmd | moves
	set(v):
		mode = v
		_mode_frame = Engine.get_process_frames()
var _mode_frame = 0
var cursor = 0
var _last_cmd = 0
var disp = {"me": 0.0, "op": 0.0}
var disp_xp = 0.0
var hud_on = {"me": false, "op": false}
var _shake = 0.0
var _t = 0.0
var _escapes = 0
var _ko_xp_given = {}

# layout
var vp = Vector2.ZERO
var sh = 0.0
var arena_b = 0.0
var bg_y = 0.0
var foe_plat = Vector2.ZERO
var my_plat = Vector2.ZERO
var foe_home = Vector2.ZERO
var my_home = Vector2.ZERO
var panel_y = 0.0


func setup(c: Dictionary) -> void:
	cfg = c
	kind = c.get("kind", "wild")
	foes = c.foes
	bg_key = c.get("bg", "canal")
	bg_tex = load("res://assets/battle/bg_%s.png" % bg_key)
	plat_tex = load("res://assets/battle/plat_%s.png" % bg_key)
	mouse_filter = Control.MOUSE_FILTER_STOP
	vp = get_viewport_rect().size
	size = vp
	sh = vp.y - Game.PANEL_H
	panel_y = sh
	arena_b = sh - 62
	bg_y = arena_b - bg_tex.get_height()
	foe_plat = Vector2(196, bg_y + 168)
	my_plat = Vector2(74, arena_b - 6)
	foe_home = foe_plat + Vector2(-32, -58)
	my_home = Vector2(my_plat.x - 32, arena_b - 64)

	foe_spr = _mk_sprite()
	my_spr = _mk_sprite()
	tin_spr = Sprite2D.new()
	tin_spr.texture = load("res://assets/ui/tin.png")
	tin_spr.visible = false
	add_child(tin_spr)
	trainer_spr = Sprite2D.new()
	trainer_spr.region_enabled = true
	trainer_spr.region_rect = Rect2(0, 0, 16, 24)
	trainer_spr.scale = Vector2(3, 3)
	trainer_spr.centered = false
	trainer_spr.visible = false
	add_child(trainer_spr)
	msg = DialogBox.new()
	add_child(msg)
	msg.layout(Rect2(2, sh - 60, vp.x - 4, 58))
	msg.auto_advance = 1.6

	op = _side(foes[0])
	me = _side(Game.state.party[Game.first_able()])
	me.idx = Game.first_able()
	Game.mark_seen(op.mon.sp)
	disp.op = float(op.mon.hp)
	disp.me = float(me.mon.hp)
	disp_xp = float(me.mon.xp)


func _mk_sprite() -> Sprite2D:
	var s = Sprite2D.new()
	s.centered = false
	var m = ShaderMaterial.new()
	m.shader = load("res://src/shaders/flash.gdshader")
	s.material = m
	s.visible = false
	add_child(s)
	return s


func _side(mon: Dictionary) -> Dictionary:
	var stg = {}
	for k in STG_KEYS:
		stg[k] = 0
	var s = {"mon": mon, "stg": stg, "daz": 0, "idx": -1}
	if mon.status == "DAZ":
		s.daz = 2
	return s


# ================================================================== drawing
func _process(delta: float) -> void:
	_t += delta
	_shake = maxf(0.0, _shake - delta)
	position = Vector2(randf_range(-3, 3), randf_range(-2, 2)).round() if _shake > 0.0 else Vector2.ZERO
	# smooth HP / XP bars
	for k in ["me", "op"]:
		var side: Dictionary = me if k == "me" else op
		if side.is_empty():
			continue
		var target = float(side.mon.hp)
		var maxhp = float(side.mon.stats[0])
		var speed = maxhp * 0.9 * delta
		disp[k] = move_toward(float(disp[k]), target, maxf(speed, 0.25))
	if not me.is_empty():
		disp_xp = move_toward(disp_xp, float(me.mon.xp), maxf(10.0, absf(float(me.mon.xp) - disp_xp) * 3.0 * delta))
	# idle bob
	if foe_spr.visible and not foe_spr.has_meta("busy"):
		foe_spr.position.y = foe_home.y + (1.0 if fmod(_t, 1.2) < 0.6 else 0.0)
	if my_spr.visible and not my_spr.has_meta("busy"):
		my_spr.position.y = my_home.y + (1.0 if fmod(_t + 0.3, 1.0) < 0.5 else 0.0)
	_handle_keys()
	queue_redraw()


func _draw() -> void:
	# background
	draw_rect(Rect2(0, 0, vp.x, arena_b), BG_TOP.get(bg_key, Color.BLACK))
	draw_texture(bg_tex, Vector2(0, bg_y))
	draw_texture(plat_tex, foe_plat - Vector2(56, 14))
	draw_texture(plat_tex, my_plat - Vector2(56, 14))
	if hud_on.op:
		_draw_hud(op, Rect2(6, bg_y + 112, 128, 32), false)
	if hud_on.me:
		_draw_hud(me, Rect2(vp.x - 136, arena_b - 52, 132, 46), true)
	# bottom area under message box
	draw_rect(Rect2(0, sh - 62, vp.x, 62), Color("1c1830"))
	_draw_panel()


func _draw_hud(side: Dictionary, r: Rect2, mine: bool) -> void:
	var m: Dictionary = side.mon
	draw_rect(r.grow(1), Color("2a2440"))
	draw_rect(r, Color("f6f0d8"))
	draw_rect(Rect2(r.position.x, r.end.y - 4, r.size.x, 4), Color("d8ccaa"))
	if mine:
		draw_rect(Rect2(r.position.x - 1, r.position.y - 1, 4, r.size.y + 2), Color("3cae6e"))
	else:
		draw_rect(Rect2(r.end.x - 3, r.position.y - 1, 4, r.size.y + 2), Color("d84848"))
	PixelText.draw_str(self, r.position + Vector2(6, 4), Game.mon_name(m).to_upper(), PixelText.INK, PixelText.SHADOW)
	var lv = "Lv%d" % int(m.lvl)
	PixelText.draw_str(self, Vector2(r.end.x - PixelText.width_of(lv) - 7, r.position.y + 4), lv, PixelText.INK)
	if m.status != "":
		var sc: Color = Data.STATUS[m.status].col
		draw_rect(Rect2(r.position.x + 6, r.position.y + 15, 21, 9), sc)
		PixelText.draw_str(self, r.position + Vector2(7, 16), m.status, Color.WHITE)
	var key = "me" if mine else "op"
	var f = float(disp[key]) / float(m.stats[0])
	PixelText.draw_str(self, r.position + Vector2(30, 16), "HP", Color("e8a030"), Color("6a4a20"))
	UI.draw_bar(self, Rect2(r.position.x + 44, r.position.y + 18, r.size.x - 52, 4), f, UI.hp_color(f))
	if mine:
		var hp_txt = "%d/%d" % [int(ceil(float(disp.me))), int(m.stats[0])]
		PixelText.draw_str(self, Vector2(r.end.x - PixelText.width_of(hp_txt) - 7, r.position.y + 26), hp_txt, PixelText.INK)
		var lo = Game.xp_for(int(m.lvl))
		var hi = Game.xp_for(int(m.lvl) + 1)
		var xf = clampf((disp_xp - lo) / float(hi - lo), 0.0, 1.0)
		draw_rect(Rect2(r.position.x + 6, r.end.y - 6, r.size.x - 12, 3), Color("54506a"))
		draw_rect(Rect2(r.position.x + 6, r.end.y - 6, (r.size.x - 12) * xf, 3), Color("5aa8f0"))


func _btn_rects() -> Array:
	var out: Array = []
	var top = panel_y + 10
	var bw = (vp.x - 18) / 2.0
	var bh = 52.0
	var count = 4 if mode == "cmd" else 5
	for i in 4:
		out.append(Rect2(6 + (i % 2) * (bw + 6), top + (i / 2) * (bh + 6), bw, bh))
	if count == 5:
		out.append(Rect2(6, top + 2 * (bh + 6), vp.x - 12, 30))
	return out


func _draw_panel() -> void:
	draw_rect(Rect2(0, panel_y, vp.x, Game.PANEL_H), Color("221e38"))
	draw_rect(Rect2(0, panel_y, vp.x, 3), Color("0e0c1a"))
	if mode == "none":
		return
	var rects = _btn_rects()
	if mode == "cmd":
		var labels = ["FIGHT", "BAG", "STRAINS", "RUN"]
		var cols = [Color("d8484a"), Color("e8a030"), Color("3cae6e"), Color("4a6ad8")]
		for i in 4:
			_draw_button(rects[i], labels[i], "", cols[i], i == cursor, true)
	else:
		var m: Dictionary = me.mon
		for i in 4:
			if i < m.moves.size():
				var mv: Dictionary = Data.MOVES[m.moves[i]]
				var sub = "%s  PP %d/%d" % [str(mv.type).to_upper(), int(m.pp[i]), int(mv.pp)]
				_draw_button(rects[i], str(mv.name).to_upper(), sub, Data.TYPE_COL[mv.type], i == cursor, int(m.pp[i]) > 0)
			else:
				_draw_button(rects[i], "-", "", Color("3a3654"), false, false)
		_draw_button(rects[4], "BACK", "", Color("5a5480"), cursor == 4, true)


func _draw_button(r: Rect2, label: String, sub: String, col: Color, on: bool, enabled: bool) -> void:
	var c = col if enabled else col.darkened(0.55)
	draw_rect(r.grow(1), Color("0e0c1a"))
	draw_rect(r, c.darkened(0.35))
	draw_rect(Rect2(r.position, Vector2(r.size.x, r.size.y - 4)), c)
	draw_rect(Rect2(r.position + Vector2(2, 2), Vector2(r.size.x - 4, 2)), c.lightened(0.3))
	if on:
		draw_rect(Rect2(r.position - Vector2(2, 2), Vector2(r.size.x + 4, 2)), Color.WHITE)
		draw_rect(Rect2(r.position + Vector2(-2, r.size.y), Vector2(r.size.x + 4, 2)), Color.WHITE)
		draw_rect(Rect2(r.position - Vector2(2, 2), Vector2(2, r.size.y + 4)), Color.WHITE)
		draw_rect(Rect2(r.position + Vector2(r.size.x, -2), Vector2(2, r.size.y + 4)), Color.WHITE)
	var lw = PixelText.width_of(label)
	var ly = r.position.y + (r.size.y - 4) / 2.0 - (8.0 if sub != "" else 4.0)
	PixelText.draw_str(self, Vector2(floor(r.position.x + (r.size.x - lw) / 2.0), floor(ly)), label, Color.WHITE, c.darkened(0.6))
	if sub != "":
		var sw = PixelText.width_of(sub)
		PixelText.draw_str(self, Vector2(floor(r.position.x + (r.size.x - sw) / 2.0), floor(ly + 13)), sub, Color(1, 1, 1, 0.85))


# ================================================================== input
func _handle_keys() -> void:
	if mode == "none" or Engine.get_process_frames() == _mode_frame:
		return
	var n = 4 if mode == "cmd" else 5
	if Input.is_action_just_pressed("left") and cursor % 2 == 1 and cursor < 4:
		cursor -= 1
		Sfx.play("blip", -6.0)
	elif Input.is_action_just_pressed("right") and cursor % 2 == 0 and cursor < 4:
		cursor += 1
		Sfx.play("blip", -6.0)
	elif Input.is_action_just_pressed("up") and cursor >= 2:
		cursor = 2 if cursor == 4 else cursor - 2
		Sfx.play("blip", -6.0)
	elif Input.is_action_just_pressed("down") and cursor < 2 + (2 if n == 5 else 0):
		cursor = 4 if cursor >= 2 else cursor + 2
		cursor = mini(cursor, n - 1)
		Sfx.play("blip", -6.0)
	elif Input.is_action_just_pressed("a"):
		_btn.emit(cursor)
	elif Input.is_action_just_pressed("b") and mode == "moves":
		_btn.emit(4)


func _gui_input(ev) -> void:
	if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
		if mode != "none" and ev.position.y >= panel_y:
			var rects = _btn_rects()
			for i in rects.size():
				if (rects[i] as Rect2).has_point(ev.position):
					cursor = i
					_btn.emit(i)
					break
		elif msg.visible and ev.position.y >= sh - 62:
			msg._tapped = true
		accept_event()


func say(t: String) -> void:
	await msg.say([t])


# ================================================================== flow
func run() -> String:
	if kind == "trainer":
		trainer_spr.texture = Data.tex("res://assets/chars/%s.png" % cfg.get("sheet", "deckhand"))
		trainer_spr.position = Vector2(vp.x + 10, foe_plat.y - 72)
		trainer_spr.visible = true
		var tw = create_tween()
		tw.tween_property(trainer_spr, "position:x", foe_plat.x - 24, 0.5).set_trans(Tween.TRANS_QUAD)
		await tw.finished
		await say("%s wants to battle!" % cfg.get("name", "TRAINER"))
		var tw2 = create_tween()
		tw2.tween_property(trainer_spr, "position:x", vp.x + 20, 0.35)
		await tw2.finished
		trainer_spr.visible = false
		await _send_out_foe()
		await say("%s sent out %s!" % [cfg.get("name", ""), Game.mon_name(op.mon).to_upper()])
	else:
		_set_foe_sprite()
		foe_spr.visible = true
		foe_spr.set_meta("busy", true)
		foe_spr.position = Vector2(-70, foe_home.y)
		var tw3 = create_tween()
		tw3.tween_property(foe_spr, "position:x", foe_home.x, 0.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		await tw3.finished
		foe_spr.remove_meta("busy")
		hud_on.op = true
		await say("A wild %s appeared!" % Game.mon_name(op.mon).to_upper())
	await _send_out_me()
	while true:
		var act: Dictionary = await _ask_action()
		var res: String = await _turn(act)
		if res != "":
			_finish()
			return res
	return "lose"


func _finish() -> void:
	for m in Game.state.party:
		if int(m.hp) <= 0:
			m.status = ""


func _set_foe_sprite() -> void:
	foe_spr.texture = Data.strain_tex(op.mon.sp)
	_fx(foe_spr, "flash", 0.0)
	_fx(foe_spr, "cut_y", 1.0)
	foe_spr.scale = Vector2.ONE


func _send_out_foe() -> void:
	_set_foe_sprite()
	await _pop_in(foe_spr, foe_home, Vector2(vp.x, foe_home.y - 30))
	hud_on.op = true
	disp.op = float(op.mon.hp)


func _send_out_me() -> void:
	my_spr.texture = Data.strain_tex(me.mon.sp, true)
	_fx(my_spr, "flash", 0.0)
	_fx(my_spr, "cut_y", 1.0)
	msg.say(["Go! %s!" % Game.mon_name(me.mon).to_upper()], "", false)
	await _pop_in(my_spr, my_home, Vector2(-20, my_home.y - 40))
	hud_on.me = true
	disp.me = float(me.mon.hp)
	disp_xp = float(me.mon.xp)
	await get_tree().create_timer(0.3).timeout


func _pop_in(spr: Sprite2D, home: Vector2, from: Vector2) -> void:
	# throw a tin, burst open, sprite scales in with a white flash
	tin_spr.visible = true
	tin_spr.position = from
	var target = home + Vector2(32, 40)
	var tw = create_tween()
	tw.tween_method(_tin_arc.bind(from, target, 40.0, 2.0), 0.0, 1.0, 0.4)
	Sfx.play("throw")
	await tw.finished
	tin_spr.visible = false
	Sfx.play("door")
	spr.set_meta("busy", true)
	spr.visible = true
	spr.position = home + Vector2(32, 64)
	spr.scale = Vector2(0.1, 0.1)
	_fx(spr, "flash", 1.0)
	_burst(target, Color.WHITE, 14, 50.0)
	var t2 = create_tween().set_parallel()
	t2.tween_property(spr, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_property(spr, "position", home, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	t2.tween_method(_fxv.bind(spr, "flash"), 1.0, 0.0, 0.35)
	await t2.finished
	spr.remove_meta("busy")


func _ask_action() -> Dictionary:
	while true:
		mode = "cmd"
		cursor = _last_cmd
		msg.show_text("What will %s do?" % Game.mon_name(me.mon).to_upper())
		var i: int = await _btn
		_last_cmd = i
		Sfx.play("confirm", -6.0)
		match i:
			0:
				mode = "moves"
				cursor = 0
				var j: int = await _btn
				if j == 4 or j >= me.mon.moves.size():
					Sfx.play("cancel", -6.0)
					continue
				if int(me.mon.pp[j]) <= 0:
					mode = "none"
					await say("No PP left for that move!")
					continue
				mode = "none"
				return {"t": "move", "i": j}
			1:
				mode = "none"
				var id: String = await Menus.item_list(Game.main, "BAG")
				if id == "":
					continue
				var it: Dictionary = Data.ITEMS[id]
				if it.has("ball"):
					if kind != "wild":
						await say("Kettle: Don't be a thief. You can't take a trainer's strain!")
						continue
					return {"t": "catch", "id": id}
				if it.has("heal"):
					var pi: int = await Menus.party_list(Game.main, "USE ON WHICH STRAIN?")
					if pi < 0:
						continue
					var pm: Dictionary = Game.state.party[pi]
					if int(pm.hp) <= 0 or int(pm.hp) >= int(pm.stats[0]):
						await say("It won't have any effect.")
						continue
					return {"t": "heal", "id": id, "i": pi}
			2:
				mode = "none"
				var pi2: int = await Menus.party_list(Game.main, "SWITCH TO WHICH STRAIN?")
				if pi2 < 0:
					continue
				if pi2 == me.idx:
					await say("%s is already out!" % Game.mon_name(me.mon).to_upper())
					continue
				if int(Game.state.party[pi2].hp) <= 0:
					await say("That strain has no energy left!")
					continue
				return {"t": "switch", "i": pi2}
			3:
				mode = "none"
				return {"t": "run"}
	return {}


# ================================================================== turn
func _turn(act: Dictionary) -> String:
	mode = "none"
	var foe_act = _ai_pick()
	match act.t:
		"run":
			if kind != "wild":
				await say("You can't run from a trainer battle!")
				return await _foe_only(foe_act)
			_escapes += 1
			var chance = 1.0 if _eff(me, "spe") >= _eff(op, "spe") else 0.5 + 0.15 * _escapes
			if randf() < chance:
				Sfx.play("door")
				await say("Got away safely!")
				return "run"
			await say("Couldn't get away!")
			return await _foe_only(foe_act)
		"switch":
			await _do_switch(int(act.i))
			return await _foe_only(foe_act)
		"heal":
			var m: Dictionary = Game.state.party[int(act.i)]
			var before = int(m.hp)
			m.hp = mini(int(m.stats[0]), int(m.hp) + int(Data.ITEMS[act.id].heal))
			Game.add_item(act.id, -1)
			Sfx.play("heal")
			if is_same(m, me.mon):
				_sparkle(my_spr, Color("6aff8a"), true)
			await say("%s recovered %d HP." % [Game.mon_name(m).to_upper(), int(m.hp) - before])
			return await _foe_only(foe_act)
		"catch":
			Game.add_item(act.id, -1)
			var caught: bool = await _throw_tin(float(Data.ITEMS[act.id].ball))
			if caught:
				return "caught"
			return await _foe_only(foe_act)
		"move":
			var my_mv: String = me.mon.moves[int(act.i)]
			var first_me = _goes_first(my_mv, foe_act)
			var order = [[me, op, my_mv, int(act.i)], [op, me, foe_act, -1]] if first_me else [[op, me, foe_act, -1], [me, op, my_mv, int(act.i)]]
			for o in order:
				var att: Dictionary = o[0]
				var def: Dictionary = o[1]
				if int(att.mon.hp) <= 0 or int(def.mon.hp) <= 0:
					continue
				if o[3] >= 0:
					att.mon.pp[o[3]] = int(att.mon.pp[o[3]]) - 1
				await _use_move(att, def, o[2])
				var r: String = await _check_faints()
				if r != "":
					return r
				if r == "" and (int(op.mon.hp) <= 0 or int(me.mon.hp) <= 0):
					break
			return await _end_of_turn()
	return ""


func _foe_only(foe_act: String) -> String:
	if foe_act != "" and int(op.mon.hp) > 0 and int(me.mon.hp) > 0:
		await _use_move(op, me, foe_act)
		var r: String = await _check_faints()
		if r != "":
			return r
	return await _end_of_turn()


func _goes_first(my_mv: String, foe_mv: String) -> bool:
	var pa = int(Data.MOVES[my_mv].get("pri", 0))
	var pb = int(Data.MOVES[foe_mv].get("pri", 0)) if foe_mv != "" else -9
	if pa != pb:
		return pa > pb
	var sa = _eff(me, "spe")
	var sb = _eff(op, "spe")
	if sa == sb:
		return randf() < 0.5
	return sa > sb


func _ai_pick() -> String:
	var m: Dictionary = op.mon
	var best = ""
	var best_s = -1.0
	for i in m.moves.size():
		if int(m.pp[i]) <= 0:
			continue
		var mv: Dictionary = Data.MOVES[m.moves[i]]
		var s = 0.0
		if mv.cat == "T":
			s = 28.0
			var fx: Dictionary = mv.get("fx", {})
			if fx.has("st") and me.mon.status != "":
				s = 0.0
			if fx.has("heal") and float(m.hp) / float(m.stats[0]) > 0.6:
				s = 0.0
		else:
			s = float(mv.pow) * Data.type_mult(mv.type, Data.SPECIES[me.mon.sp].types)
			if mv.type in Data.SPECIES[m.sp].types:
				s *= 1.5
		s *= randf_range(0.7, 1.3)
		if s > best_s:
			best_s = s
			best = m.moves[i]
	if best == "":
		best = m.moves[0]
	var idx: int = m.moves.find(best)
	if idx >= 0:
		m.pp[idx] = maxi(0, int(m.pp[idx]) - 1)
	return best


func _eff(side: Dictionary, key: String) -> float:
	var idx: int = ["hp", "atk", "def", "sa", "sd", "spe"].find(key)
	var base = float(side.mon.stats[idx])
	var s = int(side.stg[key])
	var mult = (2.0 + s) / 2.0 if s >= 0 else 2.0 / (2.0 - s)
	if key == "spe" and side.mon.status == "DAZ":
		mult *= 0.5
	return base * mult


func _spr_of(side: Dictionary) -> Sprite2D:
	return my_spr if is_same(side, me) else foe_spr


func _who(side: Dictionary) -> String:
	var n = Game.mon_name(side.mon).to_upper()
	return n if is_same(side, me) else ("Wild " + n if kind == "wild" else "Foe " + n)


func _use_move(att: Dictionary, def: Dictionary, mv_id: String) -> void:
	var mv: Dictionary = Data.MOVES[mv_id]
	if att.mon.status == "DAZ":
		if int(att.daz) <= 0:
			att.daz = randi_range(1, 3)
		att.daz = int(att.daz) - 1
		if int(att.daz) <= 0:
			att.mon.status = ""
			await say("%s snapped out of the daze!" % _who(att))
		else:
			await say("%s is dazed..." % _who(att))
			return
	await say("%s used %s!" % [_who(att), str(mv.name).to_upper()])
	# accuracy
	if mv.acc < 100 or (mv.cat == "T" and mv.get("fx", {}).has("deb")):
		var acc = float(mv.acc) / 100.0
		if randf() > acc:
			await say("It missed!")
			return
	var fx: Dictionary = mv.get("fx", {})
	if mv.cat == "T":
		await _status_move(att, def, mv, fx)
		return
	# damage
	var A = _eff(att, "atk" if mv.cat == "P" else "sa")
	var D = _eff(def, "def" if mv.cat == "P" else "sd")
	var lvl = int(att.mon.lvl)
	var dmg = floorf(floorf(floorf(2.0 * lvl / 5.0 + 2.0) * float(mv.pow) * A / D) / 50.0) + 2.0
	if mv.type in Data.SPECIES[att.mon.sp].types:
		dmg *= 1.5
	var tm = Data.type_mult(mv.type, Data.SPECIES[def.mon.sp].types)
	dmg *= tm
	var crit = randf() < 0.0625
	if crit:
		dmg *= 1.5
	dmg *= randf_range(0.85, 1.0)
	var d = maxi(1, int(dmg))
	await _attack_anim(att, def, mv, crit, tm)
	def.mon.hp = maxi(0, int(def.mon.hp) - d)
	await _wait_bar(def)
	if crit:
		await say("A critical hit!")
	if tm > 1.0:
		await say("It's super effective!")
	elif tm < 1.0:
		await say("It's not very effective...")
	# secondary effect
	if int(def.mon.hp) > 0 and fx.has("deb") and randf() * 100.0 < float(fx.get("ch", 100)):
		await _apply_stages(def, fx.deb)


func _status_move(att: Dictionary, def: Dictionary, mv: Dictionary, fx: Dictionary) -> void:
	var spr = _spr_of(att)
	await _lunge(spr, is_same(att, me), 4.0)
	if fx.has("buff"):
		_sparkle(spr, Data.TYPE_COL[mv.type], true)
		Sfx.play("buff")
		await _apply_stages(att, fx.buff)
	if fx.has("deb"):
		_sparkle(_spr_of(def), Color("8a84b4"), false)
		Sfx.play("debuff")
		await _apply_stages(def, fx.deb)
	if fx.has("heal"):
		if int(att.mon.hp) >= int(att.mon.stats[0]):
			await say("But %s is already at full HP!" % _who(att))
		else:
			_sparkle(spr, Color("6aff8a"), true)
			Sfx.play("heal")
			att.mon.hp = mini(int(att.mon.stats[0]), int(att.mon.hp) + int(float(att.mon.stats[0]) * float(fx.heal)))
			await _wait_bar(att)
			await say("%s restored its HP." % _who(att))
	if fx.has("st"):
		if def.mon.status != "":
			await say("But it failed!")
		else:
			def.mon.status = fx.st
			if fx.st == "DAZ":
				def.daz = randi_range(2, 3)
			_fx(_spr_of(def), "tint", Color(Data.STATUS[fx.st].col, 0.5))
			Sfx.play("debuff")
			await get_tree().create_timer(0.3).timeout
			_fx(_spr_of(def), "tint", Color(1, 1, 1, 0))
			await say("%s is %s!" % [_who(def), Data.STATUS[fx.st].long])


func _apply_stages(side: Dictionary, changes: Dictionary) -> void:
	var names = {"atk": "Attack", "def": "Defence", "sa": "Sp. Atk", "sd": "Sp. Def", "spe": "Speed"}
	for k in changes:
		var n = int(changes[k])
		var cur = int(side.stg[k])
		var nv = clampi(cur + n, -6, 6)
		if nv == cur:
			await say("%s's %s won't go any %s!" % [_who(side), names[k], "higher" if n > 0 else "lower"])
			continue
		side.stg[k] = nv
		var word = ("sharply rose!" if n >= 2 else "rose!") if n > 0 else ("harshly fell!" if n <= -2 else "fell!")
		await say("%s's %s %s" % [_who(side), names[k], word])


func _check_faints() -> String:
	if int(op.mon.hp) <= 0:
		await _faint_anim(foe_spr)
		hud_on.op = false
		await say("%s fainted!" % _who(op))
		await _give_xp()
		if kind == "trainer" and foe_i + 1 < foes.size():
			foe_i += 1
			op = _side(foes[foe_i])
			Game.mark_seen(op.mon.sp)
			await say("%s is about to send out %s." % [cfg.get("name", ""), Game.mon_name(op.mon).to_upper()])
			await _send_out_foe()
			return ""
		return await _win()
	if int(me.mon.hp) <= 0:
		await _faint_anim(my_spr)
		hud_on.me = false
		Game.vibrate(80)
		await say("%s fainted!" % Game.mon_name(me.mon).to_upper())
		if Game.first_able() < 0:
			return await _lose()
		var pi = -1
		while pi < 0 or int(Game.state.party[pi].hp) <= 0:
			pi = await Menus.party_list(Game.main, "CHOOSE THE NEXT STRAIN", false)
		me = _side(Game.state.party[pi])
		me.idx = pi
		await _send_out_me()
	return ""


func _win() -> String:
	if kind == "trainer":
		Sfx.jingle("jingle_victory")
		trainer_spr.visible = true
		trainer_spr.position = Vector2(vp.x + 10, foe_plat.y - 72)
		var tw = create_tween()
		tw.tween_property(trainer_spr, "position:x", foe_plat.x - 24, 0.4)
		await tw.finished
		await say("You beat %s!" % cfg.get("name", ""))
		if cfg.has("lose_line"):
			await say("%s: %s" % [cfg.get("name", ""), cfg.lose_line])
		var coins = int(cfg.get("coins", 0))
		if coins > 0:
			Game.state.coins = int(Game.state.coins) + coins
			Sfx.play("coin")
			await say("You got %d coins for winning!" % coins)
	return "win"


func _lose() -> String:
	if cfg.get("rival", false):
		trainer_spr.texture = Data.tex("res://assets/chars/%s.png" % cfg.get("sheet", "oli"))
		trainer_spr.visible = true
		trainer_spr.position = Vector2(foe_plat.x - 24, foe_plat.y - 72)
		await say("%s: Ha! Easy." % cfg.get("name", ""))
		Game.heal_all()
		return "lose_ok"
	await say("You have no strains left that can battle!")
	return "lose"


func _end_of_turn() -> String:
	for side in [me, op]:
		if side.mon.status == "GRN" and int(side.mon.hp) > 0:
			var d = maxi(1, int(side.mon.stats[0]) / 8)
			_fx(_spr_of(side), "tint", Color(0.48, 0.31, 0.69, 0.5))
			Sfx.play("debuff", -6.0)
			await get_tree().create_timer(0.25).timeout
			_fx(_spr_of(side), "tint", Color(1, 1, 1, 0))
			side.mon.hp = maxi(0, int(side.mon.hp) - d)
			await _wait_bar(side)
			await say("%s is greening out!" % _who(side))
			var r: String = await _check_faints()
			if r != "":
				return r
	return ""


func _do_switch(pi: int) -> void:
	await say("Come back, %s!" % Game.mon_name(me.mon).to_upper())
	var tw = create_tween().set_parallel()
	tw.tween_property(my_spr, "scale", Vector2(0.1, 0.1), 0.25)
	tw.tween_property(my_spr, "position", my_home + Vector2(32, 60), 0.25)
	await tw.finished
	my_spr.visible = false
	hud_on.me = false
	me = _side(Game.state.party[pi])
	me.idx = pi
	my_spr.scale = Vector2.ONE
	await _send_out_me()


# ================================================================== xp
func _give_xp() -> void:
	if int(me.mon.hp) <= 0:
		return
	var S: Dictionary = Data.SPECIES[op.mon.sp]
	var gain = int(float(S.xp) * float(op.mon.lvl) / 7.0 * (1.5 if kind == "trainer" else 1.0))
	gain = maxi(1, gain)
	me.mon.xp = int(me.mon.xp) + gain
	await say("%s gained %d XP!" % [Game.mon_name(me.mon).to_upper(), gain])
	while int(me.mon.lvl) < 100 and int(me.mon.xp) >= Game.xp_for(int(me.mon.lvl) + 1):
		# fill the bar to the end, then level up
		await get_tree().create_timer(0.4).timeout
		me.mon.lvl = int(me.mon.lvl) + 1
		Game.recalc(me.mon)
		disp.me = float(me.mon.hp)
		disp_xp = float(Game.xp_for(int(me.mon.lvl)))
		Sfx.play("levelup")
		_sparkle(my_spr, Color("ffe86a"), true)
		Game.vibrate(30)
		await say("%s grew to Lv%d!" % [Game.mon_name(me.mon).to_upper(), int(me.mon.lvl)])
		for pair in Data.SPECIES[me.mon.sp].learn:
			if int(pair[0]) == int(me.mon.lvl) and not me.mon.moves.has(pair[1]):
				await _learn(me.mon, pair[1])


func _learn(m: Dictionary, mv_id: String) -> void:
	var mv: Dictionary = Data.MOVES[mv_id]
	var nm = Game.mon_name(m).to_upper()
	if m.moves.size() < 4:
		m.moves.append(mv_id)
		m.pp.append(int(mv.pp))
		Sfx.play("caught")
		await say("%s learned %s!" % [nm, str(mv.name).to_upper()])
		return
	await say("%s wants to learn %s. But it already knows four moves." % [nm, str(mv.name).to_upper()])
	var opts: Array = []
	for id in m.moves:
		opts.append(str(Data.MOVES[id].name).to_upper())
	opts.append("KEEP OLD MOVES")
	msg.show_text("Forget which move?")
	var i: int = await Game.main.choice.choose(opts, Vector2(vp.x - 4, sh - 62), false)
	if i < 0 or i >= 4:
		await say("%s did not learn %s." % [nm, str(mv.name).to_upper()])
		return
	var old: String = str(Data.MOVES[m.moves[i]].name).to_upper()
	m.moves[i] = mv_id
	m.pp[i] = int(mv.pp)
	await say("1, 2 and... Poof! %s forgot %s and learned %s!" % [nm, old, str(mv.name).to_upper()])


# ================================================================== catching
func _throw_tin(ball: float) -> bool:
	await say("You lobbed a TIN!")
	var from = Vector2(20, arena_b - 20)
	var target = foe_home + Vector2(32, 36)
	tin_spr.visible = true
	tin_spr.rotation = 0.0
	Sfx.play("throw")
	var tw = create_tween()
	tw.tween_method(_tin_arc.bind(from, target, 70.0, 3.0), 0.0, 1.0, 0.55)
	await tw.finished
	tin_spr.rotation = 0.0
	# strain gets sucked in
	foe_spr.set_meta("busy", true)
	Sfx.play("door")
	var t2 = create_tween().set_parallel()
	t2.tween_method(_fxv.bind(foe_spr, "flash"), 0.0, 1.0, 0.15)
	t2.tween_property(foe_spr, "scale", Vector2(0.05, 0.05), 0.3).set_delay(0.12)
	t2.tween_property(foe_spr, "position", target - Vector2(2, 2), 0.3).set_delay(0.12)
	await t2.finished
	foe_spr.visible = false
	hud_on.op = true
	# drop
	var t3 = create_tween()
	t3.tween_property(tin_spr, "position:y", foe_plat.y - 6, 0.25).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	await t3.finished
	# catch maths
	var m: Dictionary = op.mon
	var mx = float(m.stats[0])
	var a = (3.0 * mx - 2.0 * float(m.hp)) * float(Data.SPECIES[m.sp].cr) * ball / (3.0 * mx)
	if m.status != "":
		a *= 1.5
	var p = clampf(a / 255.0, 0.02, 1.0)
	var shake_p = pow(p, 0.25)
	var shakes = 0
	for i in 3:
		if randf() < shake_p:
			shakes += 1
		else:
			break
	var ok = shakes == 3 and randf() < shake_p
	for i in mini(shakes + (0 if ok else 1), 3):
		await get_tree().create_timer(0.45).timeout
		Sfx.play("shake")
		Game.vibrate(15)
		var t4 = create_tween()
		t4.tween_property(tin_spr, "rotation", 0.35, 0.08)
		t4.tween_property(tin_spr, "rotation", -0.35, 0.12)
		t4.tween_property(tin_spr, "rotation", 0.0, 0.08)
		await t4.finished
	await get_tree().create_timer(0.4).timeout
	if ok:
		Sfx.play("caught")
		Game.vibrate(60)
		_burst(tin_spr.position, Color("ffe86a"), 16, 40.0)
		tin_spr.modulate = Color(0.6, 0.6, 0.7)
		await say("Gotcha! %s was caught!" % Game.mon_name(m).to_upper())
		Game.mark_caught(m.sp)
		m.status = ""
		if Game.state.party.size() < 6:
			Game.state.party.append(m)
			await say("%s joined your party." % Game.mon_name(m).to_upper())
		else:
			if not Game.state.has("box"):
				Game.state.box = []
			Game.state.box.append(m)
			await say("Your party is full. %s was sent to storage." % Game.mon_name(m).to_upper())
		return true
	# breaks free
	tin_spr.visible = false
	Sfx.play("door")
	_burst(target, Color.WHITE, 12, 40.0)
	foe_spr.visible = true
	var t5 = create_tween().set_parallel()
	t5.tween_property(foe_spr, "scale", Vector2.ONE, 0.25).set_trans(Tween.TRANS_BACK)
	t5.tween_property(foe_spr, "position", foe_home, 0.25)
	t5.tween_method(_fxv.bind(foe_spr, "flash"), 1.0, 0.0, 0.3)
	await t5.finished
	foe_spr.remove_meta("busy")
	var lines = ["Oh no! It broke free!", "Argh! So close!", "Aww! It looked caught!", "Nearly! Remind me: tins are cheap."]
	await say(lines[mini(shakes, 3)])
	return false


# ================================================================== animation helpers
func _wait_bar(side: Dictionary) -> void:
	var key = "me" if is_same(side, me) else "op"
	var t = 0.0
	while absf(float(disp[key]) - float(side.mon.hp)) > 0.5 and t < 2.0:
		await get_tree().process_frame
		t += get_process_delta_time()


func _lunge(spr: Sprite2D, mine: bool, dist := 10.0) -> void:
	spr.set_meta("busy", true)
	var home = spr.position
	var dir = Vector2(1, -0.5) if mine else Vector2(-1, 0.5)
	var tw = create_tween()
	tw.tween_property(spr, "position", home + dir * dist, 0.09)
	tw.tween_property(spr, "position", home, 0.12)
	await tw.finished
	spr.remove_meta("busy")


func _attack_anim(att: Dictionary, def: Dictionary, mv: Dictionary, crit: bool, tm: float) -> void:
	var a_spr = _spr_of(att)
	var d_spr = _spr_of(def)
	var col: Color = Data.TYPE_COL[mv.type]
	var a_c = a_spr.position + Vector2(32, 32)
	var d_c = d_spr.position + Vector2(32, 30)
	if mv.cat == "P":
		await _lunge(a_spr, is_same(att, me), 18.0)
	else:
		Sfx.play("throw", -4.0)
		for i in 7:
			var p = ColorRect.new()
			p.size = Vector2(4, 4)
			p.color = col.lightened(0.3 if i % 2 else 0.0)
			p.mouse_filter = Control.MOUSE_FILTER_IGNORE
			p.position = a_c
			add_child(p)
			var tw = create_tween()
			var off = Vector2(randf_range(-6, 6), randf_range(-6, 6))
			tw.tween_property(p, "position", d_c + off, 0.28).set_delay(i * 0.04)
			tw.tween_callback(p.queue_free)
		await get_tree().create_timer(0.3 + 6 * 0.04).timeout
	# impact
	Sfx.play("crit" if crit else ("super" if tm > 1.0 else "hit"))
	_burst(d_c, col, 14 if tm > 1.0 else 9, 60.0)
	if crit or tm > 1.0:
		_shake = 0.25
		Game.vibrate(45 if crit else 30)
	d_spr.set_meta("busy", true)
	var home = d_spr.position
	var tw2 = create_tween()
	for k in 3:
		tw2.tween_method(_fxv.bind(d_spr, "flash"), 1.0, 0.0, 0.1)
	var tw3 = create_tween()
	for k in 4:
		tw3.tween_property(d_spr, "position:x", home.x + (3 if k % 2 == 0 else -3), 0.04)
	tw3.tween_property(d_spr, "position:x", home.x, 0.04)
	await tw2.finished
	d_spr.position = home
	d_spr.remove_meta("busy")


func _faint_anim(spr: Sprite2D) -> void:
	Sfx.play("faint")
	spr.set_meta("busy", true)
	var home = spr.position
	var tw = create_tween().set_parallel()
	tw.tween_property(spr, "position:y", home.y + 64, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_method(_fxv.bind(spr, "cut_y"), 1.0, 0.0, 0.45)
	await tw.finished
	spr.visible = false
	spr.position = home
	_fx(spr, "cut_y", 1.0)
	spr.remove_meta("busy")


func _burst(at: Vector2, col: Color, n: int, speed: float) -> void:
	var p = CPUParticles2D.new()
	p.position = at
	p.one_shot = true
	p.emitting = false
	p.amount = n
	p.lifetime = 0.45
	p.explosiveness = 1.0
	p.spread = 180.0
	p.initial_velocity_min = speed * 0.5
	p.initial_velocity_max = speed
	p.gravity = Vector2(0, 60)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	var g = Gradient.new()
	g.set_color(0, col.lightened(0.4))
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _sparkle(spr: Sprite2D, col: Color, up: bool) -> void:
	var p = CPUParticles2D.new()
	p.position = spr.position + Vector2(32, 40 if up else 0)
	p.one_shot = true
	p.amount = 14
	p.lifetime = 0.8
	p.explosiveness = 0.6
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = Vector2(24, 6)
	p.direction = Vector2(0, -1 if up else 1)
	p.spread = 10.0
	p.gravity = Vector2.ZERO
	p.initial_velocity_min = 30.0
	p.initial_velocity_max = 50.0
	p.scale_amount_min = 2.0
	p.scale_amount_max = 2.0
	var g = Gradient.new()
	g.set_color(0, col.lightened(0.5))
	g.set_color(1, Color(col, 0.0))
	p.color_ramp = g
	add_child(p)
	p.emitting = true
	get_tree().create_timer(1.4).timeout.connect(p.queue_free)


func _fx(spr: Sprite2D, key: String, v) -> void:
	(spr.material as ShaderMaterial).set_shader_parameter(key, v)


func _fxv(v: float, spr: Sprite2D, key: String) -> void:
	(spr.material as ShaderMaterial).set_shader_parameter(key, v)


func _tin_arc(k: float, from: Vector2, target: Vector2, height: float, spins: float) -> void:
	tin_spr.position = from.lerp(target, k) + Vector2(0, -sin(k * PI) * height)
	tin_spr.rotation = k * TAU * spins
