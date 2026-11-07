extends RefCounted
## Menus: start menu, party, summary, bag, dex and the starter picker.
## All screens draw inside the screen area (above the touch panel) and are awaited.


# ================================================================== list screen
class ListScreen:
	extends Control
	signal picked(i: int)
	var title = ""
	var rows: Array = []        # {icon, text, sub, hp(-1 none), right}
	var sel = 0
	var cancel = true
	var row_h = 30
	var _active = false
	var _scroll = 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func open(parent: Node, r: Array, ttl: String, can_cancel := true, rh := 30) -> int:
		rows = r
		title = ttl
		cancel = can_cancel
		row_h = rh
		size = Vector2(Game.main.vp_size().x, Game.main.screen_h())
		parent.add_child(self)
		queue_redraw()
		await get_tree().process_frame
		_active = true
		var i: int = await picked
		_active = false
		return i

	func _visible_rows() -> int:
		return maxi(1, int((size.y - 30) / row_h))

	func _process(_d: float) -> void:
		if not _active or rows.is_empty():
			if _active and Input.is_action_just_pressed("b") and cancel:
				picked.emit(-1)
			return
		if Input.is_action_just_pressed("up"):
			sel = (sel - 1 + rows.size()) % rows.size()
			Sfx.play("blip", -6.0)
		elif Input.is_action_just_pressed("down"):
			sel = (sel + 1) % rows.size()
			Sfx.play("blip", -6.0)
		elif Input.is_action_just_pressed("a"):
			Sfx.play("confirm", -6.0)
			picked.emit(sel)
		elif Input.is_action_just_pressed("b") and cancel:
			Sfx.play("cancel", -6.0)
			picked.emit(-1)
		var vr = _visible_rows()
		if sel < _scroll:
			_scroll = sel
		elif sel >= _scroll + vr:
			_scroll = sel - vr + 1
		queue_redraw()

	func _gui_input(ev) -> void:
		if not _active:
			return
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			if ev.position.y < 24 and ev.position.x > size.x - 50 and cancel:
				Sfx.play("cancel", -6.0)
				picked.emit(-1)
			else:
				var i = _scroll + int((ev.position.y - 26) / row_h)
				if i >= 0 and i < rows.size() and ev.position.y >= 26:
					sel = i
					Sfx.play("confirm", -6.0)
					picked.emit(i)
			accept_event()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color("1c1830"))
		for i in 12:
			draw_rect(Rect2(0, i * 6, size.x, 3), Color("221d3a"))
		draw_rect(Rect2(0, 0, size.x, 22), Color("3c5a9a"))
		draw_rect(Rect2(0, 22, size.x, 2), Color("2a2440"))
		PixelText.draw_str(self, Vector2(8, 7), title, Color.WHITE, Color("1e2a5a"))
		if cancel:
			PixelText.draw_str(self, Vector2(size.x - 44, 7), "BACK", Color("c8d8ff"), Color("1e2a5a"))
		var vr = _visible_rows()
		for k in vr:
			var i = _scroll + k
			if i >= rows.size():
				break
			var r: Dictionary = rows[i]
			var y = 26 + k * row_h
			var box = Rect2(4, y, size.x - 8, row_h - 3)
			var on = i == sel
			draw_rect(box.grow(1), Color("2a2440"))
			draw_rect(box, Color("f8f4e8") if on else Color("d8d0e8"))
			if on:
				draw_rect(Rect2(box.position, Vector2(3, box.size.y)), Color("d84848"))
			var x = 10.0
			if r.get("icon") != null:
				var tex: Texture2D = r.icon
				var isz = mini(tex.get_height(), row_h - 4)
				draw_texture_rect(tex, Rect2(8, y + (row_h - 3 - isz) / 2.0, isz, isz), false)
				x = 12 + isz
			PixelText.draw_str(self, Vector2(x, y + 5), str(r.get("text", "")), PixelText.INK, PixelText.SHADOW)
			if r.has("right"):
				var rt = str(r.right)
				PixelText.draw_str(self, Vector2(box.end.x - PixelText.width_of(rt) - 6, y + 5), rt, Color("3c5a9a"))
			if r.has("sub"):
				PixelText.draw_str(self, Vector2(x, y + 16), str(r.sub), Color("6a6484"))
			if float(r.get("hp", -1.0)) >= 0.0:
				var f: float = r.hp
				UI.draw_bar(self, Rect2(box.end.x - 74, y + 18, 66, 4), f, UI.hp_color(f))
		if rows.is_empty():
			PixelText.draw_str(self, Vector2(10, 34), "Nothing here yet.", Color("a8a0c8"))


# ================================================================== summary
class Summary:
	extends Control
	signal closed
	var mon = {}
	var sp = ""
	var dex_only = false
	var _f0 = 0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func show_for(parent: Node) -> void:
		size = Vector2(Game.main.vp_size().x, Game.main.screen_h())
		_f0 = Engine.get_process_frames()
		parent.add_child(self)
		await get_tree().process_frame
		await closed
		queue_free()

	func _process(_d: float) -> void:
		if Engine.get_process_frames() <= _f0 + 1:
			return
		if Input.is_action_just_pressed("a") or Input.is_action_just_pressed("b"):
			Sfx.play("cancel", -6.0)
			closed.emit()

	func _gui_input(ev) -> void:
		if ev is InputEventMouseButton and ev.pressed:
			closed.emit()
			accept_event()

	func _draw() -> void:
		var S: Dictionary = Data.SPECIES[sp]
		draw_rect(Rect2(Vector2.ZERO, size), Color("1c1830"))
		var tc: Color = Data.TYPE_COL[S.types[0]]
		draw_rect(Rect2(0, 0, size.x, 96), tc.darkened(0.55))
		for i in 8:
			draw_rect(Rect2(0, 8 + i * 11, size.x, 4), tc.darkened(0.45))
		draw_texture_rect(Data.strain_tex(sp), Rect2(12, 14, 72, 72), false)
		PixelText.draw_str(self, Vector2(98, 14), "No.%03d" % int(S.no), Color("ffe8a0"))
		var nm: String = Game.mon_name(mon) if not dex_only else S.name
		PixelText.draw_str(self, Vector2(98, 28), nm.to_upper(), Color.WHITE, Color(0, 0, 0, 0.5), 1)
		if not dex_only:
			PixelText.draw_str(self, Vector2(98, 40), "Lv%d" % int(mon.lvl), Color.WHITE)
		var tx = 98.0
		for t in S.types:
			UI.type_badge(self, Vector2(tx, 54), t)
			tx += PixelText.width_of(t) + 12
		var y = 104.0
		if dex_only:
			for line in PixelText.wrap_lines(S.flavor, int(size.x - 20)):
				PixelText.draw_str(self, Vector2(10, y), line, Color("e8e0f8"))
				y += 12
			PixelText.draw_str(self, Vector2(10, size.y - 16), "A/B: BACK", Color("8a84a8"))
			return
		var hpf: float = float(mon.hp) / float(mon.stats[0])
		PixelText.draw_str(self, Vector2(98, 70), "HP %d/%d" % [mon.hp, mon.stats[0]], Color.WHITE)
		UI.draw_bar(self, Rect2(98, 82, 100, 4), hpf, UI.hp_color(hpf))
		var lbl = ["ATTACK", "DEFENCE", "SP.ATK", "SP.DEF", "SPEED"]
		for i in 5:
			PixelText.draw_str(self, Vector2(10, y), lbl[i], Color("a8a0c8"))
			PixelText.draw_str(self, Vector2(80, y), str(mon.stats[i + 1]), Color.WHITE)
			y += 12
		var lo = Game.xp_for(int(mon.lvl))
		var hi = Game.xp_for(int(mon.lvl) + 1)
		PixelText.draw_str(self, Vector2(130, 104), "NEXT LV", Color("a8a0c8"))
		PixelText.draw_str(self, Vector2(130, 116), "%d XP" % (hi - int(mon.xp)), Color.WHITE)
		UI.draw_bar(self, Rect2(130, 130, 100, 3), float(int(mon.xp) - lo) / float(hi - lo), Color("5aa8f0"))
		y += 8
		PixelText.draw_str(self, Vector2(10, y), "MOVES", Color("ffe8a0"))
		y += 13
		for i in mon.moves.size():
			var mv: Dictionary = Data.MOVES[mon.moves[i]]
			draw_rect(Rect2(8, y - 2, size.x - 16, 12), Color("2a2444"))
			draw_rect(Rect2(8, y - 2, 3, 12), Data.TYPE_COL[mv.type])
			PixelText.draw_str(self, Vector2(16, y), str(mv.name).to_upper(), Color.WHITE)
			PixelText.draw_str(self, Vector2(size.x - 70, y), "PP %d/%d" % [mon.pp[i], mv.pp], Color("a8a0c8"))
			y += 14


# ================================================================== starter picker
class StarterPick:
	extends Control
	signal picked(i: int)
	var sel = 1
	var t = 0.0
	var active = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(d: float) -> void:
		t += d
		queue_redraw()
		if not active:
			return
		if Input.is_action_just_pressed("left"):
			sel = (sel + 2) % 3
			Sfx.play("blip", -6.0)
		elif Input.is_action_just_pressed("right"):
			sel = (sel + 1) % 3
			Sfx.play("blip", -6.0)
		elif Input.is_action_just_pressed("a"):
			Sfx.play("confirm", -6.0)
			picked.emit(sel)

	func _gui_input(ev) -> void:
		if active and ev is InputEventMouseButton and ev.pressed:
			var i = clampi(int(ev.position.x / (size.x / 3.0)), 0, 2)
			sel = i
			Sfx.play("confirm", -6.0)
			picked.emit(i)
			accept_event()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.05, 0.12, 0.88))
		var cw = size.x / 3.0
		var top = size.y / 2.0 - 70
		PixelText.draw_str(self, Vector2(floor((size.x - PixelText.width_of("CHOOSE YOUR STRAIN")) / 2.0), top - 22), "CHOOSE YOUR STRAIN", Color("ffe8a0"), Color("2a1e3a"))
		for i in 3:
			var sp: String = Data.STARTERS[i]
			var S: Dictionary = Data.SPECIES[sp]
			var c: Color = Data.TYPE_COL[S.types[0]]
			var r = Rect2(i * cw + 3, top, cw - 6, 130)
			draw_rect(r.grow(1), Color("2a2440"))
			draw_rect(r, c.darkened(0.55) if i != sel else c.darkened(0.25))
			if i == sel:
				draw_rect(Rect2(r.position, Vector2(r.size.x, 2)), Color.WHITE)
			var bob = round(sin(t * 4.0) * 2.0) if i == sel else 0.0
			draw_texture(Data.strain_tex(sp), Vector2(r.position.x + (r.size.x - 64) / 2.0, top + 8 + bob))
			var nm = str(S.name).to_upper()
			PixelText.draw_str(self, Vector2(r.position.x + floor((r.size.x - PixelText.width_of(nm)) / 2.0), top + 80), nm, Color.WHITE, Color(0, 0, 0, 0.5))
			var tw = PixelText.width_of(str(S.types[0]).to_upper()) + 6
			UI.type_badge(self, Vector2(r.position.x + floor((r.size.x - tw) / 2.0), top + 94), S.types[0])
		var S2: Dictionary = Data.SPECIES[Data.STARTERS[sel]]
		var y = top + 140
		for line in PixelText.wrap_lines(S2.flavor, int(size.x - 16)):
			PixelText.draw_str(self, Vector2(8, y), line, Color("e8e0f8"))
			y += 12


# ================================================================== API
static func party_rows() -> Array:
	var r: Array = []
	for m in Game.state.party:
		var st = " %s" % m.status if m.status != "" else ""
		r.append({"icon": Data.strain_icon(m.sp), "text": Game.mon_name(m).to_upper(), "right": "Lv%d" % m.lvl,
			"sub": "HP %d/%d%s" % [m.hp, m.stats[0], st], "hp": float(m.hp) / float(m.stats[0])})
	return r


static func party_list(main, ttl := "STRAINS", can_cancel := true) -> int:
	var L = ListScreen.new()
	var i: int = await L.open(main.ui_layer, party_rows(), ttl, can_cancel, 34)
	L.queue_free()
	return i


static func show_summary(main, mon: Dictionary) -> void:
	var s = Summary.new()
	s.mon = mon
	s.sp = mon.sp
	await s.show_for(main.ui_layer)


static func item_list(main, ttl := "BAG") -> String:
	var ids: Array = Game.state.bag.keys()
	var rows: Array = []
	for id in ids:
		var it: Dictionary = Data.ITEMS[id]
		rows.append({"icon": Data.tex(it.icon), "text": str(it.name).to_upper(), "right": "x%d" % Game.state.bag[id], "sub": it.desc})
	var L = ListScreen.new()
	var i: int = await L.open(main.ui_layer, rows, ttl, true, 34)
	L.queue_free()
	return "" if i < 0 else str(ids[i])


static func start_menu(main) -> void:
	var vp: Vector2 = main.vp_size()
	var last = 0
	while true:
		var opts = ["STRAINS", "BAG", "DEX", "SAVE", "CLOSE"]
		var i: int = await main.choice.choose(opts, Vector2(vp.x - 4, 4 + opts.size() * 14 + 14), true, last)
		if i < 0 or i == 4:
			return
		last = i
		match i:
			0:
				await _party_flow(main)
			1:
				await _bag_flow(main)
			2:
				await _dex_flow(main)
			3:
				if await main.ask("Save your progress?"):
					if Game.save_game():
						Sfx.play("confirm")
						await main.say(["Progress saved."])
					else:
						await main.say(["Could not save. Try again."])


static func _party_flow(main) -> void:
	while true:
		var i: int = await party_list(main)
		if i < 0:
			return
		await main.get_tree().process_frame
		var r: int = await main.choice.choose(["SUMMARY", "MOVE UP", "CANCEL"], Vector2(main.vp_size().x - 4, main.screen_h() - 4), true)
		if r == 0:
			await show_summary(main, Game.state.party[i])
		elif r == 1 and i > 0:
			var p: Array = Game.state.party
			var tmp = p[i - 1]
			p[i - 1] = p[i]
			p[i] = tmp


static func _bag_flow(main) -> void:
	while true:
		var id: String = await item_list(main)
		if id == "":
			return
		var it: Dictionary = Data.ITEMS[id]
		if it.has("heal"):
			var i: int = await party_list(main, "USE ON WHICH STRAIN?")
			if i < 0:
				continue
			var m: Dictionary = Game.state.party[i]
			if int(m.hp) <= 0 or int(m.hp) >= int(m.stats[0]):
				await main.say(["It won't have any effect."])
				continue
			var before = int(m.hp)
			m.hp = mini(int(m.stats[0]), int(m.hp) + int(it.heal))
			Game.add_item(id, -1)
			Sfx.play("heal")
			await main.say(["%s recovered %d HP." % [Game.mon_name(m), int(m.hp) - before]])
		else:
			await main.say(["Save that for a battle."])


static func _dex_flow(main) -> void:
	var keys: Array = Data.SPECIES.keys()
	keys.sort_custom(func(a, b): return int(Data.SPECIES[a].no) < int(Data.SPECIES[b].no))
	while true:
		var rows: Array = []
		for k in keys:
			var S: Dictionary = Data.SPECIES[k]
			var seen: bool = Game.state.seen.has(k)
			var caught: bool = Game.state.caught.has(k)
			rows.append({"icon": Data.strain_icon(k) if seen else null, "text": "%03d  %s" % [int(S.no), str(S.name).to_upper() if seen else "-----"],
				"right": "CAUGHT" if caught else ("SEEN" if seen else "")})
		var L = ListScreen.new()
		var i: int = await L.open(main.ui_layer, rows, "DEX  %d SEEN  %d CAUGHT" % [Game.state.seen.size(), Game.state.caught.size()], true, 30)
		L.queue_free()
		if i < 0:
			return
		if Game.state.seen.has(keys[i]):
			var s = Summary.new()
			s.sp = keys[i]
			s.dex_only = true
			await s.show_for(main.ui_layer)


static func starter_picker(main) -> String:
	var p = StarterPick.new()
	p.size = Vector2(main.vp_size().x, main.screen_h())
	main.ui_layer.add_child(p)
	while true:
		await main.get_tree().process_frame
		p.active = true
		var i: int = await p.picked
		p.active = false
		var sp: String = Data.STARTERS[i]
		var S: Dictionary = Data.SPECIES[sp]
		if await main.ask("Take %s, the %s strain?" % [S.name, S.types[0]], "KETTLE"):
			p.queue_free()
			return sp
	return ""
