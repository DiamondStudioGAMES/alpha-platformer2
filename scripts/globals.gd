extends Node
class_name Globals, "res://textures/gui/alpha_text.png"


const VERSION = "1.0.1"
const VERSION_STATUS = ""
const VERSION_STATUS_NUMBER = ""
const VERSION_CODE = 88

var main_file: ConfigFile
var save_file: ConfigFile
var save_timer = 0
var ignore_next_music_stop = false
var current_level = "1_1"
var current_scene = ""
var current_tickets = 0
var cached_ip = ""
var cached_multiplayer_role = MultiplayerRole.NONE
var custom_respawn_scene = ""
var dialog_in_menu = ""
var fps_text
var music
var time_timer
var ach: Achievements
var class_visuals
var loading_scene = load("res://scenes/menu/loading.tscn")
var box = load("res://scenes/menu/box.tscn")
const CLASSES_ID = {
	-1 : "player",
	0 : "knight",
	1 : "butcher",
	2 : "spearman",
	3 : "wizard",
	4 : "archer",
	5 : "player"
}
const CLASSES_BY_ID = {
	"knight" : 0,
	"butcher" : 1,
	"spearman" : 2,
	"wizard" : 3,
	"archer" : 4,
	"player" : 5
}
const RIM_NUMBERS = {
	1 : "I",
	2 : "II",
	3 : "III",
	4 : "IV",
	5 : "V"
}
const GADGETS = {
	"knight" : "gadgets.knight",
	"butcher" : "gadgets.butcher",
	"spearman" : "gadgets.spearman",
	"wizard" : "gadgets.wizard",
	"archer" : "gadgets.archer"
}
const SOUL_POWERS = {
	"knight" : "sp.knight",
	"butcher" : "sp.butcher",
	"spearman" : "sp.spearman",
	"wizard" : "sp.wizard",
	"archer" : "sp.archer"
}
const CLASSES = {
	"knight" : "class.knight",
	"butcher" : "class.butcher",
	"spearman" : "class.spearman",
	"wizard" : "class.wizard",
	"archer" : "class.archer",
	"player" : "class.none"
}
const ULTIS = {
	"knight" : "ulti.flurry",
	"butcher" : "ulti.smash",
	"spearman" : "ulti.stun",
	"wizard" : "ulti.heal",
	"archer" : "ulti.blitz"
}
const CLASS_COLORS = {
	"knight" : Color(0.8, 0, 0),
	"butcher" : Color(0.8, 0.8, 0),
	"spearman" : Color(0, 0.8, 0),
	"wizard" : Color(0.8, 0, 0.8),
	"archer" : Color(0, 0.8, 0.8)
}
const CLASS_COLORS_LIGHT = {
	"knight" : Color(1, 0, 0),
	"butcher" : Color(1, 1, 0),
	"spearman" : Color(0, 1, 0),
	"wizard" : Color(1, 0, 1),
	"archer" : Color(0, 1, 1)
}
const CLASS_COLORS_HIGHLIGHT = {
	"knight" : Color(1, 0.25, 0.25),
	"butcher" : Color(1, 1, 0.25),
	"spearman" : Color(0.25, 1, 0.25),
	"wizard" : Color(1, 0.25, 1),
	"archer" : Color(0.25, 1, 1)
}
const SOUL_COLORS = {
	6 : Color.red,
	0 : Color.orange,
	1 : Color.yellow,
	2 : Color.green,
	3 : Color.cyan,
	4 : Color.blue,
	5 : Color.magenta
}
const AMULET = {
	-1 : "none",
	0 : "power",
	1 : "defense",
	2 : "health",
	3 : "speed",
	4 : "reload",
	5 : "ulti",
}
const AMULET_ID = {
	"none" : -1,
	"power" : 0,
	"defense" : 1,
	"health" : 2,
	"speed" : 3,
	"reload" : 4,
	"ulti" : 5,
}
const AMULET_NAME = {
	-1 : "amulet.none",
	0 : "amulet.power",
	1 : "amulet.defense",
	2 : "amulet.health",
	3 : "amulet.speed",
	4 : "amulet.reload",
	5 : "amulet.ulti",
}
const AMULET_MAX = {
	-1 : 0,
	0 : 23,
	1 : 19,
	2 : 23,
	3 : 21,
	4 : 21,
	5 : 25,
}
enum EffectsType {
	STANDARD = 0,
	SIMPLE = 1,
	DISABLED = 2,
}
enum GrassType {
	GPU = 0,
	CPU = 1,
	STATIC = 2,
}
enum Graphics {
	BEAUTY_LIGHT = 1,
	BEAUTY_WATER = 2,
	BEAUTY_LAVA = 4,
	BEAUTY_FIRE = 8,
	BEAUTY_DEFAULT = 14,
	BEAUTY_ALL = 15,
}
enum Amulet {
	POWER = 0,
	DEFENSE = 1,
	HEALTH = 2,
	SPEED = 3,
	RELOAD = 4,
	ULTI = 5,
	NONE = -1,
}
enum MultiplayerRole {
	NONE = 0,
	SERVER = 1,
	CLIENT = 2,
}

signal loot_end
signal hate_increased
signal loaded_to_scene(path)


func _ready():
	main_file = ConfigFile.new()
	main_file.load_encrypted_pass("user://main.apa2", "main")
	var dir = Directory.new()
	if not dir.dir_exists("user://saves/"):
		dir.make_dir_recursive("user://saves/")
	
	randomize()
	ach = Achievements.new()
	ach.name = "achievements"
	ach.layer = 128
	ach.pause_mode = PAUSE_MODE_PROCESS
	add_child(ach)
	music = AudioStreamPlayer.new()
	music.name = "menu_music"
	music.bus = "music"
	music.stream = load("res://sounds/music/menu/menu.ogg")
	add_child(music)
	fps_text = load("res://prefabs/menu/fps_counter.tscn").instance()
	fps_text.hide()
	add_child(fps_text)
	time_timer = Timer.new()
	time_timer.name = "timer"
	time_timer.wait_time = 1
	time_timer.pause_mode = PAUSE_MODE_PROCESS
	add_child(time_timer)
	time_timer.connect("timeout", self, "_update_timer")
	time_timer.start()
	class_visuals = load("res://prefabs/menu/class_visuals.tscn").instance()
	if OS.has_feature("editor") or OS.has_feature("cheats"):
		var ch = load("res://prefabs/menu/cheats.tscn").instance()
		add_child(ch)


func _process(delta):
	save_timer += delta
	if save_timer >= 10:
		save()
		save_timer = 0


func _notification(what):
	match what:
		NOTIFICATION_APP_PAUSED, NOTIFICATION_EXIT_TREE, \
		NOTIFICATION_WM_GO_BACK_REQUEST, NOTIFICATION_WM_QUIT_REQUEST, \
		NOTIFICATION_WM_FOCUS_OUT:
			save()


func getv(name, default_value = 0):
	return save_file.get_value("save", name, default_value)


func setv(name, value):
	save_file.set_value("save", name, value)


func addv(name, value, default_value = 0):
	save_file.set_value("save", name, save_file.get_value("save", name, default_value) + value)


func hasv(name):
	return save_file.has_section_key("save", name)


func main_setv(name, value):
	main_file.set_value("config", name, value)


func main_getv(name, default_value = 0):
	return main_file.get_value("config", name, default_value)


func main_addv(name, value, default_value = 0):
	main_file.set_value("config", name, main_file.get_value("config", name, default_value) + value)


func main_hasv(name):
	return main_file.has_section_key("config", name)


func set_save_meta(id, meta, data):
	main_file.set_value(id, meta, data)


func get_save_meta(id, meta, data):
	return main_file.get_value(id, meta, data)


func open_save(id):
	save_file = ConfigFile.new()
	save_file.load_encrypted_pass("user://saves/".plus_file(id + ".apa2save"), "apa2_save")


func close_save():
	save()
	save_file = null


func save():
	main_file.save_encrypted_pass("user://main.apa2", "main")
	if save_file != null:
		save_file.save_encrypted_pass("user://saves/".plus_file(getv("save_id", "pass") + ".apa2save"), "apa2_save")


func change_to_scene(path):
	if has_node("/root/loading"):
		if $"/root/loading".load_path == path:
			return
	var node = loading_scene.instance()
	node.load_path = path
	get_tree().root.add_child(node)


func receive_ad_reward():
	receive_loot({"gold_box" : 1})


func receive_loot(looted):
	var loot_to_show = {}
	var rec = looted.duplicate(true)
	var another_rec = rec.duplicate(true)
	for i in rec:
		if i.ends_with("box"):
			continue
		if i == "coins" or i == "gems" or i == "tickets" or i.begins_with("potions") or i.begins_with("garden"):
			addv(i, rec[i])
		if getv("potions1", 0) > 3:
			if another_rec.has("potions1"):
				another_rec["potions1"] = another_rec["potions1"] - getv("potions1", 0) + 3
				if another_rec["potions1"] <= 0:
					another_rec.erase("potions1")
			if not another_rec.has("coins"):
				another_rec["coins"] = 0
			another_rec["coins"] += (getv("potions1", 0) - 3) * 275
			addv("coins", (getv("potions1", 0) - 3) * 275)
			setv("potions1", 3)
		if getv("potions2", 0) > 2:
			if another_rec.has("potions2"):
				another_rec["potions2"] = another_rec["potions2"] - getv("potions2", 0) + 2
				if another_rec["potions2"] <= 0:
					another_rec.erase("potions2")
			if not another_rec.has("coins"):
				another_rec["coins"] = 0
			another_rec["coins"] += (getv("potions2", 0) - 2) * 600
			addv("coins", (getv("potions2", 0) - 2) * 600)
			setv("potions2", 2)
		if getv("potions3", 0) > 1:
			if another_rec.has("potions3"):
				another_rec["potions3"] = another_rec["potions3"] - getv("potions3", 0) + 1
				if another_rec["potions3"] <= 0:
					another_rec.erase("potions3")
			if not another_rec.has("coins"):
				another_rec["coins"] = 0
			another_rec["coins"] += (getv("potions3", 0) - 1) * 925
			addv("coins", (getv("potions3", 0) - 1) * 925)
			setv("potions3", 1)
		if i == "class":
			for j in rec[i]:
				addv("classes", [j], [])
		if i == "gadget":
			for j in rec[i]:
				setv(j + "_gadget", true)
		if i == "soul_power":
			for j in rec[i]:
				setv(j + "_soul_power", true)
		if i == "amulet_frags":
			for j in rec[i]:
				addv("amulet_frags_" + j, rec[i][j])
				addv("total_amulet_frags_" + j, rec[i][j])
		if i == "tokens":
			for j in rec[i]:
				addv(j + "_tokens", rec[i][j])
		if i == "ulti_tokens":
			for j in rec[i]:
				addv(j + "_ulti_tokens", rec[i][j])
	if another_rec.hash() != rec.hash():
		rec = another_rec
	for i in rec:
		loot_to_show[i] = rec[i]
	ach.check(Achievements.PROZAPASS)
	save()
	if not loot_to_show.empty():
		var n = box.instance()
		get_tree().root.add_child(n)
		n.show_loot(loot_to_show)
		n.connect("end_loot", self, "emit_signal", ["loot_end"])


func percent_chance(in_chance):
	in_chance *= 10000
	in_chance = int(in_chance)
	var max_add = 1000000 - in_chance
	var chance_range_start = randi() % (max_add + 1)
	var chance_range_end = chance_range_start + in_chance
	var random_number = randi() % 1000001
	return random_number >= chance_range_start and random_number <= chance_range_end


func calculate_hate_level():
	var prev_hate_level = getv("hate_level", -1)
	var bosses_died = 0
	for i in range(1, 10):
		if getv("boss_%d_10_killed" % i, false):
			bosses_died += 1
	var new_hate_level = 0
	if bosses_died == 0:
		new_hate_level = -1
	elif bosses_died <= 2:
		new_hate_level = 0
	elif bosses_died <= 4:
		new_hate_level = 1
	elif bosses_died <= 6:
		new_hate_level = 2
	elif bosses_died <= 8:
		new_hate_level = 3
	else:
		new_hate_level = 4
	setv("hate_level", new_hate_level)
	set_save_meta(getv("save_id", "nn"), "hate_level", new_hate_level)
	if new_hate_level != prev_hate_level:
		emit_signal("hate_increased")


func play_menu_music():
	if not music.playing:
		music.play()


func stop_menu_music():
	if not ignore_next_music_stop:
		music.stop()
	ignore_next_music_stop = false


func init_class_visuals():
	if not class_visuals.is_inside_tree():
		add_child(class_visuals)


func end_class_visuals():
	if class_visuals.is_inside_tree():
		remove_child(class_visuals)


func _update_timer():
	if save_file == null:
		return
	G.addv("time", 1)
