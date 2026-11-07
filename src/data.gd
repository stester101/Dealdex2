extends Node
## Static game data: types, moves, strains, items, props. Autoload "Data".

const TileIds = preload("res://src/gen/tile_ids.gd")

# ------------------------------------------------------------------ types
const TYPES := ["Dust", "Indica", "Sativa", "Hybrid", "Kush", "Haze", "Diesel", "Exotic"]
const TYPE_COL := {
	"Dust": Color("9a8f77"), "Indica": Color("6f7bd6"), "Sativa": Color("e0733c"), "Hybrid": Color("3fae7a"),
	"Kush": Color("8a6bd0"), "Haze": Color("5aa7c9"), "Diesel": Color("c9963a"), "Exotic": Color("d4a13a"),
}
var CHART = {}

# ------------------------------------------------------------------ moves
# cat: P physical, S special, T status
# fx keys: deb {stat:n} on foe, buff {stat:n} on self, heal f, st status id + ch chance
var MOVES = {
	"barge": {"name": "Shoulder Barge", "type": "Dust", "cat": "P", "pow": 40, "acc": 100, "pp": 35, "desc": "A heavy lean. Classic."},
	"tut": {"name": "Disapproving Tut", "type": "Dust", "cat": "T", "pow": 0, "acc": 100, "pp": 40, "fx": {"deb": {"atk": -1}}, "desc": "Lowers the foe's Attack."},
	"stare": {"name": "Long Stare", "type": "Dust", "cat": "T", "pow": 0, "acc": 100, "pp": 30, "fx": {"deb": {"def": -1}}, "desc": "Lowers the foe's Defence."},
	"rummage": {"name": "Rummage", "type": "Dust", "cat": "P", "pow": 55, "acc": 95, "pp": 25, "desc": "Digs through pockets for something hard."},
	"badbatch": {"name": "Bad Batch", "type": "Dust", "cat": "T", "pow": 0, "acc": 85, "pp": 20, "fx": {"st": "GRN", "ch": 100}, "desc": "The foe greens out. Loses HP each turn."},
	"petalpop": {"name": "Petal Pop", "type": "Sativa", "cat": "S", "pow": 40, "acc": 100, "pp": 30, "desc": "Fires a burst of bright petals."},
	"sativarush": {"name": "Sativa Rush", "type": "Sativa", "cat": "P", "pow": 60, "acc": 95, "pp": 20, "desc": "An energetic charge."},
	"buzz": {"name": "Head Buzz", "type": "Sativa", "cat": "T", "pow": 0, "acc": 100, "pp": 20, "fx": {"buff": {"spe": 2}}, "desc": "Sharply raises Speed."},
	"syrupslap": {"name": "Syrup Slap", "type": "Indica", "cat": "S", "pow": 40, "acc": 100, "pp": 30, "fx": {"deb": {"spe": -1}, "ch": 30}, "desc": "Sticky. May lower the foe's Speed."},
	"drowse": {"name": "Drowse", "type": "Indica", "cat": "T", "pow": 0, "acc": 75, "pp": 15, "fx": {"st": "DAZ", "ch": 100}, "desc": "Puts the foe into a daze."},
	"couchcrush": {"name": "Couch Crush", "type": "Indica", "cat": "P", "pow": 60, "acc": 100, "pp": 20, "desc": "Sinks the foe into the cushions."},
	"leafjab": {"name": "Leaf Jab", "type": "Hybrid", "cat": "P", "pow": 40, "acc": 100, "pp": 30, "desc": "A quick poke with a leaf."},
	"clogstomp": {"name": "Clog Stomp", "type": "Hybrid", "cat": "P", "pow": 60, "acc": 95, "pp": 20, "desc": "Wooden. Loud. Effective."},
	"rootup": {"name": "Root Up", "type": "Hybrid", "cat": "T", "pow": 0, "acc": 100, "pp": 10, "fx": {"heal": 0.5}, "desc": "Restores half of max HP."},
	"canalsplash": {"name": "Canal Splash", "type": "Haze", "cat": "S", "pow": 45, "acc": 100, "pp": 30, "desc": "You do not want this in your mouth."},
	"mistveil": {"name": "Mist Veil", "type": "Haze", "cat": "T", "pow": 0, "acc": 100, "pp": 20, "fx": {"buff": {"def": 1, "sd": 1}}, "desc": "Raises both defences."},
	"fogbank": {"name": "Fog Bank", "type": "Haze", "cat": "S", "pow": 65, "acc": 90, "pp": 15, "desc": "A wall of canal fog."},
	"peck": {"name": "Kush Peck", "type": "Kush", "cat": "P", "pow": 45, "acc": 100, "pp": 30, "desc": "Pecks for crumbs. Gets your fingers."},
	"strut": {"name": "Bread Strut", "type": "Kush", "cat": "T", "pow": 0, "acc": 100, "pp": 20, "fx": {"buff": {"atk": 1}}, "desc": "Raises Attack."},
	"mustard": {"name": "Mustard Spit", "type": "Diesel", "cat": "S", "pow": 40, "acc": 100, "pp": 30, "fx": {"deb": {"def": -1}, "ch": 30}, "desc": "May lower the foe's Defence."},
	"deepfry": {"name": "Deep Fry", "type": "Diesel", "cat": "S", "pow": 55, "acc": 95, "pp": 20, "desc": "Straight from the snack wall."},
	"crumble": {"name": "Crumble Cannon", "type": "Diesel", "cat": "P", "pow": 65, "acc": 90, "pp": 15, "desc": "Fires hot crumbs."},
}

# ------------------------------------------------------------------ strains
var SPECIES = {
	"tulipup": {"name": "Tulipup", "no": 1, "types": ["Sativa"], "bs": [45, 52, 43, 60, 50, 65], "cr": 45, "xp": 64,
		"learn": [[1, "barge"], [1, "tut"], [5, "petalpop"], [9, "buzz"], [13, "sativarush"]],
		"flavor": "Sprouted in a bulb field and never sat still again. Faces the sun. Talks a lot."},
	"stroopuff": {"name": "Stroopuff", "no": 4, "types": ["Indica"], "bs": [60, 48, 58, 52, 62, 40], "cr": 45, "xp": 64,
		"learn": [[1, "barge"], [1, "stare"], [5, "syrupslap"], [9, "drowse"], [13, "couchcrush"]],
		"flavor": "Warm, sweet and always a bit sleepy. Best rested on top of a hot cuppa."},
	"klompy": {"name": "Klompy", "no": 7, "types": ["Hybrid"], "bs": [52, 60, 60, 40, 48, 50], "cr": 45, "xp": 64,
		"learn": [[1, "barge"], [1, "tut"], [5, "leafjab"], [9, "rootup"], [13, "clogstomp"]],
		"flavor": "A carved clog that took root. Sturdy. Clatters on the cobbles at night."},
	"stowaweed": {"name": "Stowaweed", "no": 10, "types": ["Dust"], "bs": [40, 45, 40, 30, 35, 45], "cr": 220, "xp": 40,
		"learn": [[1, "barge"], [3, "tut"], [6, "rummage"], [10, "badbatch"]],
		"flavor": "Hides in cargo sacks to cross the sea for free. Customs has never caught one."},
	"cookush": {"name": "Coo-Kush", "no": 12, "types": ["Kush"], "bs": [44, 55, 40, 35, 40, 62], "cr": 190, "xp": 50,
		"learn": [[1, "peck"], [3, "strut"], [8, "barge"], [12, "rummage"]],
		"flavor": "Rules Dam Square. Will take the chips out of your hand while you still hold them."},
	"grachtling": {"name": "Grachtling", "no": 15, "types": ["Haze"], "bs": [48, 35, 45, 62, 55, 42], "cr": 180, "xp": 52,
		"learn": [[1, "canalsplash"], [4, "mistveil"], [9, "fogbank"]],
		"flavor": "Forms from canal mist after dark. Glows near the bridges. Smells of bike oil."},
	"bitterbal": {"name": "Bitterbal", "no": 18, "types": ["Diesel"], "bs": [50, 58, 52, 45, 40, 38], "cr": 170, "xp": 55,
		"learn": [[1, "barge"], [4, "mustard"], [8, "deepfry"], [12, "crumble"]],
		"flavor": "Hot on the outside. Molten on the inside. Never eat one straight from the fryer."},
}
const STARTERS := ["tulipup", "stroopuff", "klompy"]
# rival takes the strain that beats yours
const COUNTER := {"tulipup": "stroopuff", "stroopuff": "klompy", "klompy": "tulipup"}

const STATUS := {
	"GRN": {"name": "GRN", "long": "greening out", "col": Color("7a4fb0")},
	"DAZ": {"name": "DAZ", "long": "dazed", "col": Color("6f7bd6")},
}

var ITEMS = {
	"tin": {"name": "Tin", "icon": "res://assets/ui/tin.png", "ball": 1.0, "price": 200, "desc": "A catch tin. Lob it at a weakened wild strain."},
	"cuppa": {"name": "Cuppa", "icon": "res://assets/ui/cuppa.png", "heal": 20, "price": 300, "desc": "Restores 20 HP. Two sugars."},
}

# ------------------------------------------------------------------ world props
# footprint in tiles (solid), light: [x, y, energy, scale, colour] relative to prop origin (bottom-left)
var PROPS = {
	"house0": {"tex": "res://assets/props/house0.png", "fw": 2, "fh": 1, "lights": [[24, -14, 0.55, 0.35, "ffc870"]]},
	"house1": {"tex": "res://assets/props/house1.png", "fw": 2, "fh": 1, "lights": [[24, -14, 0.55, 0.35, "ffc870"]]},
	"house2": {"tex": "res://assets/props/house2.png", "fw": 2, "fh": 1, "lights": [[24, -14, 0.55, 0.35, "ffc870"]]},
	"house3": {"tex": "res://assets/props/house3.png", "fw": 2, "fh": 1, "lights": [[24, -14, 0.55, 0.35, "ffc870"]]},
	"house4": {"tex": "res://assets/props/house4.png", "fw": 2, "fh": 1, "lights": [[24, -14, 0.55, 0.35, "ffc870"]]},
	"coffeeshop": {"tex": "res://assets/props/coffeeshop.png", "fw": 3, "fh": 1, "lights": [[24, -34, 1.0, 0.55, "6aff8a"], [12, -14, 0.6, 0.4, "ffc870"], [37, -14, 0.6, 0.4, "ffc870"]]},
	"hostel": {"tex": "res://assets/props/hostel.png", "fw": 3, "fh": 1, "lights": [[24, -34, 0.7, 0.5, "8ab0ff"], [12, -14, 0.6, 0.4, "ffc870"], [37, -14, 0.6, 0.4, "ffc870"]]},
	"lamp": {"tex": "res://assets/props/lamp.png", "fw": 1, "fh": 1, "lights": [[8, -40, 1.25, 1.1, "ffd890"]]},
	"tree": {"tex": "res://assets/props/tree.png", "fw": 2, "fh": 1},
	"bikes": {"tex": "res://assets/props/bikes.png", "fw": 2, "fh": 1},
	"bench": {"tex": "res://assets/props/bench.png", "fw": 2, "fh": 1},
	"bollard": {"tex": "res://assets/props/bollard.png", "fw": 1, "fh": 1, "ox": 4},
	"houseboat": {"tex": "res://assets/props/houseboat.png", "fw": 4, "fh": 1, "lights": [[30, -18, 0.5, 0.45, "ffc870"]]},
	"ferry_cabin": {"tex": "res://assets/props/ferry_cabin.png", "fw": 7, "fh": 2},
	"funnel": {"tex": "res://assets/props/funnel.png", "fw": 2, "fh": 1},
	"lifeboat": {"tex": "res://assets/props/lifeboat.png", "fw": 3, "fh": 1},
	"crate": {"tex": "res://assets/props/crate.png", "fw": 1, "fh": 1},
	"crate_nl": {"tex": "res://assets/props/crate_nl.png", "fw": 1, "fh": 1},
	"sign": {"tex": "res://assets/props/sign.png", "fw": 1, "fh": 1},
}

var _tex_cache = {}


func _ready() -> void:
	_build_chart()


func tex(path: String) -> Texture2D:
	if not _tex_cache.has(path):
		_tex_cache[path] = load(path)
	return _tex_cache[path]


func tile_index(tname: String) -> int:
	return TileIds.NAMES.find(tname)


func _build_chart() -> void:
	for a in TYPES:
		CHART[a] = {}
		for d in TYPES:
			CHART[a][d] = 1.0
	var tri = [["Sativa", "Hybrid"], ["Hybrid", "Indica"], ["Indica", "Sativa"], ["Kush", "Diesel"], ["Diesel", "Haze"], ["Haze", "Kush"]]
	for pair in tri:
		CHART[pair[0]][pair[1]] = 2.0
		CHART[pair[1]][pair[0]] = 0.5
	for a in TYPES:
		if a != "Exotic":
			CHART[a]["Exotic"] = 0.75
	CHART["Dust"]["Exotic"] = 0.5
	for d in TYPES:
		if d != "Exotic":
			CHART["Exotic"][d] = 1.25
	CHART["Haze"]["Indica"] = 1.5
	CHART["Indica"]["Haze"] = 0.75
	CHART["Diesel"]["Sativa"] = 1.5
	CHART["Sativa"]["Diesel"] = 0.75
	CHART["Kush"]["Hybrid"] = 1.5
	CHART["Hybrid"]["Kush"] = 0.75


func type_mult(mv_type: String, def_types: Array) -> float:
	var m = 1.0
	for t in def_types:
		m *= float(CHART[mv_type][t])
	return m


func strain_tex(sp: String, back := false) -> Texture2D:
	return tex("res://assets/strains/%s%s.png" % [sp, "_back" if back else ""])


func strain_icon(sp: String) -> Texture2D:
	return tex("res://assets/strains/%s_icon.png" % sp)
