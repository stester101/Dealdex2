extends Node
## Root: owns the world, the battle layer, UI overlays, touch controls and screen fades.

const Story = preload("res://src/world/story.gd")
const BattleScene = preload("res://src/battle/battle.gd")
const Menus = preload("res://src/ui/menus.gd")
const Title = preload("res://src/screens/title.gd")

var story = Story.new()
var world: World
var ui_layer: CanvasLayer
var battle_layer: CanvasLayer
var panel_layer: CanvasLayer
var fade_layer: CanvasLayer
var dialog_layer: CanvasLayer
var dialog: DialogBox
var choice: ChoiceBox
var panel: TouchPanel
var fader: ColorRect
var _overlay_open = 0
var in_battle = false


func _ready() -> void:
	Game.main = self
	RenderingServer.set_default_clear_color(Color("0f0d1a"))
	world = World.new()
	add_child(world)
	battle_layer = CanvasLayer.new()
	battle_layer.layer = 2
	add_child(battle_layer)
	panel_layer = CanvasLayer.new()
	panel_layer.layer = 3
	add_child(panel_layer)
	ui_layer = CanvasLayer.new()
	ui_layer.layer = 5
	add_child(ui_layer)
	dialog_layer = CanvasLayer.new()
	dialog_layer.layer = 6
	add_child(dialog_layer)
	fade_layer = CanvasLayer.new()
	fade_layer.layer = 10
	add_child(fade_layer)

	panel = TouchPanel.new()
	panel_layer.add_child(panel)
	dialog = DialogBox.new()
	dialog_layer.add_child(dialog)
	choice = ChoiceBox.new()
	dialog_layer.add_child(choice)
	fader = UI.fade_rect()
	fade_layer.add_child(fader)
	get_viewport().size_changed.connect(_layout)
	_layout()
	if "--selftest" in OS.get_cmdline_user_args():
		await _selftest()
		return
	if "--shots" in OS.get_cmdline_user_args():
		await _shots()
		return
	_show_title()


# ------------------------------------------------------------------ CI screenshots
func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var img = get_viewport().get_texture().get_image()
	var dir = ProjectSettings.globalize_path("res://logs/shots/")
	DirAccess.make_dir_recursive_absolute(dir)
	img.save_png(dir + name + ".png")
	print("SHOT ", name, " ", img.get_size())


func _wait(s: float) -> void:
	await get_tree().create_timer(s).timeout


func _shots() -> void:
	## Renders key screens to logs/shots/*.png (CI runs this under xvfb).
	Sfx.muted = true
	var t = Title.new()
	ui_layer.add_child(t)
	t.run()
	await _wait(1.0)
	await _shot("01_title")
	t.queue_free()
	Game.new_state()
	for sp in ["tulipup", "cookush", "grachtling"]:
		Game.state.party.append(Game.mk_mon(sp, 7))
	world.load_map("ferry", Vector2i(11, 16), 3)
	await _wait(0.5)
	await _shot("02_ferry")
	Menus.starter_picker(self)
	await _wait(0.6)
	await _shot("03_starter")
	for c in ui_layer.get_children():
		c.queue_free()
	dialog.close()
	choice.visible = false
	world.load_map("ferry", Vector2i(10, 22), 0)
	await _wait(0.5)
	await _shot("04_ferry_cargo")
	world.load_map("quay", Vector2i(16, 9), 3)
	await _wait(2.6)
	await _shot("05_quay")
	world.load_map("quay", Vector2i(14, 20), 0)
	await _wait(2.6)
	await _shot("06_park")
	dialog.say(["Amsterdam. Smell that?", "...That's the canal, mate."], "KETTLE")
	await _wait(1.2)
	await _shot("07_dialog")
	dialog.close()
	world.load_map("hostel", Vector2i(4, 5), 3)
	await _wait(2.6)
	await _shot("08_hostel")
	world.load_map("quay", Vector2i(16, 9), 3)
	panel.visible = false
	in_battle = true
	var b = BattleScene.new()
	battle_layer.add_child(b)
	b.setup({"kind": "wild", "foes": [Game.mk_mon("bitterbal", 5)], "bg": "canal"})
	b.msg.auto_advance = 0.3
	b.run()
	await _wait(1.0)
	await _shot("09_battle_intro")
	await _wait(3.5)
	await _shot("10_battle_cmd")
	b.mode = "moves"
	await _wait(0.2)
	await _shot("11_battle_moves")
	b.queue_free()
	var b2 = BattleScene.new()
	battle_layer.add_child(b2)
	b2.setup({"kind": "trainer", "foes": [Game.mk_mon("stowaweed", 4)], "name": "DECKHAND DES", "sheet": "deckhand", "bg": "ferry"})
	b2.msg.auto_advance = 0.3
	b2.run()
	await _wait(1.0)
	await _shot("12_trainer_intro")
	await _wait(4.0)
	await _shot("13_ferry_battle")
	b2.queue_free()
	panel.visible = true
	in_battle = false
	Menus.party_list(self)
	await _wait(0.4)
	await _shot("14_party")
	for c in ui_layer.get_children():
		c.queue_free()
	Menus.show_summary(self, Game.state.party[0])
	await _wait(0.4)
	await _shot("15_summary")
	print("SHOTS DONE")
	get_tree().quit(0)


# ------------------------------------------------------------------ CI self-test
func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame


func _selftest() -> void:
	## Runs every system once with no player input. CI greps the log for "SELFTEST OK".
	print("SELFTEST start")
	Sfx.muted = true
	dialog.auto_advance = 0.02
	dialog.fast = true
	Game.new_state()
	for sp in Data.SPECIES:
		var m = Game.mk_mon(sp, 6)
		assert(m.moves.size() > 0)
		Game.state.party.append(m)
	Game.state.party.resize(6)
	print("SELFTEST strains ok")
	for id in ["ferry", "quay", "hostel"]:
		world.load_map(id, Vector2i(4, 6) if id == "hostel" else Vector2i(11, 16) if id == "ferry" else Vector2i(16, 9), 0)
		await _frames(3)
		print("SELFTEST map ", id, " ", world.w, "x", world.h, " npcs ", world.npcs.size())
	# scripted dialogue + yes/no
	await dialog.say(["Self-test line one.", "Line two is a bit longer so that it wraps onto the next line of the box."], "TEST")
	print("SELFTEST dialog ok")
	Game.set_flag("intro_done")
	world.load_map("ferry", Vector2i(11, 16), 3)
	await _frames(2)
	await story._arrival(world)
	print("SELFTEST arrival map ", world.map_id, " fade ", fader.color.a, " saved ", Game.has_save())
	assert(world.map_id == "quay" and fader.color.a < 0.05)
	# drag-to-move: touch the screen and drag down, player should walk south
	var y0 = world.player.tile.y
	var t1 = InputEventScreenTouch.new()
	t1.index = 0
	t1.position = Vector2(135, 120)
	t1.pressed = true
	Input.parse_input_event(t1)
	await _frames(2)
	var dr = InputEventScreenDrag.new()
	dr.index = 0
	dr.position = Vector2(135, 170)
	Input.parse_input_event(dr)
	await _wait(0.7)
	var t2 = InputEventScreenTouch.new()
	t2.index = 0
	t2.position = Vector2(135, 170)
	t2.pressed = false
	Input.parse_input_event(t2)
	await _wait(0.4)
	print("SELFTEST drag moved from y ", y0, " to ", world.player.tile.y)
	assert(world.player.tile.y > y0)
	# battle: run a few real turns with auto-advancing text
	var b = BattleScene.new()
	battle_layer.add_child(b)
	b.setup({"kind": "wild", "foes": [Game.mk_mon("grachtling", 4)], "bg": "canal"})
	b.msg.auto_advance = 0.02
	b.msg.fast = true
	await _frames(2)
	await b._send_out_me()
	for i in 3:
		if int(b.op.mon.hp) <= 0 or int(b.me.mon.hp) <= 0:
			break
		var r: String = await b._turn({"t": "move", "i": 0})
		print("SELFTEST turn ", i, " result '", r, "' hp ", b.me.mon.hp, "/", b.op.mon.hp)
	var caught: bool = await b._throw_tin(255.0)
	print("SELFTEST catch ", caught)
	await b._give_xp()
	b.queue_free()
	print("SELFTEST battle ok")
	# trainer battle object + menus data
	var b2 = BattleScene.new()
	battle_layer.add_child(b2)
	b2.setup({"kind": "trainer", "foes": [Game.mk_mon("bitterbal", 5), Game.mk_mon("cookush", 4)], "name": "TEST", "sheet": "deckhand", "bg": "ferry"})
	await _frames(2)
	print("SELFTEST ai ", b2._ai_pick(), " eff ", b2._eff(b2.me, "atk"))
	b2.queue_free()
	print("SELFTEST rows ", Menus.party_rows().size())
	print("SELFTEST save ", Game.save_game(), " load ", Game.load_game())
	var t = Title.new()
	ui_layer.add_child(t)
	await _frames(2)
	t.queue_free()
	print("SELFTEST OK")
	get_tree().quit(0)


func _layout() -> void:
	var vp = get_viewport().get_visible_rect().size
	panel.layout(vp)
	var sh = screen_h()
	dialog.layout(Rect2(2, sh - 58, vp.x - 4, 56))
	fader.size = vp


func screen_h() -> float:
	return get_viewport().get_visible_rect().size.y - Game.PANEL_H


func vp_size() -> Vector2:
	return get_viewport().get_visible_rect().size


func is_ui_open() -> bool:
	return _overlay_open > 0 or dialog.visible or choice.visible or in_battle


# ------------------------------------------------------------------ title / start
func _show_title() -> void:
	_overlay_open += 1
	var t = Title.new()
	ui_layer.add_child(t)
	var pick: String = await t.run()
	t.queue_free()
	_overlay_open -= 1
	if pick == "continue" and Game.load_game():
		world.load_map(Game.state.map, Vector2i(int(Game.state.x), int(Game.state.y)), int(Game.state.dir))
		await fade_in(0.4)
	else:
		Game.new_state()
		world.load_map("ferry", Vector2i(11, 16), 3)
		world.busy = true
		await fade_in(0.6)
		await world.run_script("intro")


# ------------------------------------------------------------------ helpers used by scripts
func say(lines: Array, speaker := "") -> void:
	await dialog.say(lines, speaker)


func ask(question: String, speaker := "") -> bool:
	await dialog.say([question], speaker, false)
	var r: int = await choice.choose(["YES", "NO"], Vector2(vp_size().x - 4, dialog.position.y - 2), true)
	dialog.close()
	return r == 0


func fade_out(t := 0.3) -> void:
	var tw = create_tween()
	tw.tween_property(fader, "color:a", 1.0, t)
	await tw.finished


func fade_in(t := 0.3) -> void:
	var tw = create_tween()
	tw.tween_property(fader, "color:a", 0.0, t)
	await tw.finished


func flash(col: Color, t := 0.2) -> void:
	var r = ColorRect.new()
	r.color = col
	r.size = vp_size()
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fade_layer.add_child(r)
	var tw = create_tween()
	tw.tween_property(r, "color:a", 0.0, t)
	await tw.finished
	r.queue_free()


## Text shown on top of a black fade (the dialog box sits under the fade layer).
func caption(text: String, secs := 1.8) -> void:
	var l = UI.label(text, Vector2.ZERO, Color.WHITE, Color(0, 0, 0, 0))
	l.position = Vector2(floor((vp_size().x - PixelText.width_of(text)) / 2.0), floor(screen_h() / 2.0))
	l.modulate.a = 0.0
	fade_layer.add_child(l)
	var tw = create_tween()
	tw.tween_property(l, "modulate:a", 1.0, 0.3)
	tw.tween_interval(secs)
	tw.tween_property(l, "modulate:a", 0.0, 0.3)
	await tw.finished
	l.queue_free()


## Saves silently once the intro is done. Called on map changes, after battles and when the app pauses.
func autosave() -> void:
	if Game.flag("intro_done") and not Game.state.party.is_empty():
		Game.save_game()


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_WM_CLOSE_REQUEST or what == NOTIFICATION_WM_GO_BACK_REQUEST or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		if world and world.player and not in_battle:
			autosave()


## True when the world is free to take movement input (used by drag-to-move).
func world_input_ok() -> bool:
	return world != null and world.player != null and not world.busy and not is_ui_open()


func banner(text: String) -> void:
	var b = Control.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var f = UI.frame()
	var wdt = PixelText.width_of(text) + 20
	f.size = Vector2(wdt, 24)
	b.add_child(f)
	var l = UI.label(text, Vector2(10, 8))
	b.add_child(l)
	b.position = Vector2(4, -30)
	ui_layer.add_child(b)
	var tw = create_tween()
	tw.tween_property(b, "position:y", 4.0, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(1.8)
	tw.tween_property(b, "position:y", -30.0, 0.25)
	tw.tween_callback(b.queue_free)


# ------------------------------------------------------------------ overlays
func open_menu() -> void:
	_overlay_open += 1
	Sfx.play("select")
	await Menus.start_menu(self)
	_overlay_open -= 1


func pick_starter() -> String:
	_overlay_open += 1
	var sp: String = await Menus.starter_picker(self)
	_overlay_open -= 1
	return sp


# ------------------------------------------------------------------ battle
func start_battle(cfg: Dictionary) -> String:
	in_battle = true
	panel.release_all()
	Sfx.play("encounter")
	Game.vibrate(60)
	Sfx.music("music_battle")
	# wipe transition
	var wipe = ColorRect.new()
	wipe.size = vp_size()
	wipe.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var mat = ShaderMaterial.new()
	mat.shader = load("res://src/shaders/transition.gdshader")
	wipe.material = mat
	fade_layer.add_child(wipe)
	for i in 3:
		await flash(Color(1, 1, 1, 0.8), 0.08)
	var tw = create_tween()
	tw.tween_method(func(v): mat.set_shader_parameter("progress", v), 0.0, 1.0, 0.55)
	await tw.finished
	panel.visible = false
	var b = BattleScene.new()
	battle_layer.add_child(b)
	b.setup(cfg)
	var tw2 = create_tween()
	tw2.tween_method(func(v): mat.set_shader_parameter("progress", v), 1.0, 0.0, 0.35)
	await tw2.finished
	wipe.queue_free()
	var res: String = await b.run()
	await fade_out(0.3)
	b.queue_free()
	panel.visible = true
	in_battle = false
	if world.map.size() > 0:
		Sfx.music(world.map.get("music", ""))
	await fade_in(0.3)
	autosave()
	return res
