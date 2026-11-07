extends Node
## Game state, strain maths and save/load. Autoload "Game".

const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1
const PANEL_H := 196          # height of the touch-control panel at the bottom
const TS := 16

var main = null          # set by main.gd
var state = {}


func _ready() -> void:
	_setup_input()
	new_state()


func _setup_input() -> void:
	var binds = {
		"up": [KEY_UP, KEY_W], "down": [KEY_DOWN, KEY_S], "left": [KEY_LEFT, KEY_A], "right": [KEY_RIGHT, KEY_D],
		"a": [KEY_Z, KEY_ENTER, KEY_SPACE], "b": [KEY_X, KEY_BACKSPACE, KEY_SHIFT], "start": [KEY_ESCAPE, KEY_TAB, KEY_M],
	}
	for action in binds:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for k in binds[action]:
			var ev = InputEventKey.new()
			ev.physical_keycode = k
			InputMap.action_add_event(action, ev)


func new_state() -> void:
	state = {
		"v": SAVE_VERSION, "name": "SIMON", "map": "ferry", "x": 9, "y": 14, "dir": 0,
		"party": [], "bag": {"tin": 5, "cuppa": 3}, "coins": 300,
		"flags": {}, "seen": {}, "caught": {}, "steps": 0, "play_s": 0.0, "heal_map": "ferry", "heal_x": 9, "heal_y": 14,
	}


func flag(k: String) -> bool:
	return bool(state.flags.get(k, false))


func set_flag(k: String, v := true) -> void:
	state.flags[k] = v


func _process(delta: float) -> void:
	state.play_s = float(state.get("play_s", 0.0)) + delta


# ------------------------------------------------------------------ strains
func stat_calc(base: int, lvl: int, is_hp: bool) -> int:
	if is_hp:
		return int(base * 2 * lvl / 100.0) + lvl + 10
	return int(base * 2 * lvl / 100.0) + 5


func xp_for(lvl: int) -> int:
	return lvl * lvl * lvl


func moves_at(sp: String, lvl: int) -> Array:
	var out: Array = []
	for pair in Data.SPECIES[sp].learn:
		if int(pair[0]) <= lvl and not out.has(pair[1]):
			out.append(pair[1])
	while out.size() > 4:
		out.pop_front()
	return out


func mk_mon(sp: String, lvl: int) -> Dictionary:
	var m = {"sp": sp, "lvl": lvl, "xp": xp_for(lvl), "moves": [], "pp": [], "status": "", "hp": 1, "stats": [], "nick": ""}
	for mv in moves_at(sp, lvl):
		m.moves.append(mv)
		m.pp.append(int(Data.MOVES[mv].pp))
	recalc(m)
	m.hp = m.stats[0]
	return m


func recalc(m: Dictionary) -> void:
	var bs: Array = Data.SPECIES[m.sp].bs
	var old_max = int(m.stats[0]) if m.stats.size() > 0 else 0
	var s: Array = []
	for i in 6:
		s.append(stat_calc(int(bs[i]), int(m.lvl), i == 0))
	m.stats = s
	if old_max > 0:
		m.hp = clampi(int(m.hp) + (int(s[0]) - old_max), 0, int(s[0]))


func mon_name(m: Dictionary) -> String:
	return m.nick if m.nick != "" else Data.SPECIES[m.sp].name


func heal_all() -> void:
	for m in state.party:
		m.hp = m.stats[0]
		m.status = ""
		for i in m.moves.size():
			m.pp[i] = int(Data.MOVES[m.moves[i]].pp)


func first_able() -> int:
	for i in state.party.size():
		if int(state.party[i].hp) > 0:
			return i
	return -1


func mark_seen(sp: String) -> void:
	state.seen[sp] = true


func mark_caught(sp: String) -> void:
	state.seen[sp] = true
	state.caught[sp] = true


func add_item(id: String, n := 1) -> void:
	state.bag[id] = int(state.bag.get(id, 0)) + n
	if int(state.bag[id]) <= 0:
		state.bag.erase(id)


# ------------------------------------------------------------------ save
func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game() -> bool:
	var f = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if f == null:
		return false
	f.store_string(JSON.stringify(state))
	return true


func load_game() -> bool:
	if not has_save():
		return false
	var f = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if f == null:
		return false
	var data = JSON.parse_string(f.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return false
	new_state()
	for k in data:
		state[k] = data[k]
	_fix_numbers()
	return true


func _fix_numbers() -> void:
	# JSON gives floats; make the integer fields integers again
	for k in ["x", "y", "dir", "coins", "steps", "heal_x", "heal_y"]:
		state[k] = int(state[k])
	for m in state.party:
		for k in ["lvl", "xp", "hp"]:
			m[k] = int(m[k])
		var s: Array = []
		for v in m.stats:
			s.append(int(v))
		m.stats = s
		var p: Array = []
		for v in m.pp:
			p.append(int(v))
		m.pp = p
	for k in state.bag.keys():
		state.bag[k] = int(state.bag[k])


func vibrate(ms: int) -> void:
	if OS.has_feature("android"):
		Input.vibrate_handheld(ms)
