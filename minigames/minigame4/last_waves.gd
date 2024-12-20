extends Node2D


export (String) var location = "Где-то"
export (String) var level_name = "УРОВЕНЬ: ТЕСТ"
export (Array, PackedScene) var mobs = []
export (Array, int) var mobs_locations = []
onready var pos = $spawn_pos
onready var st = $spawn_timer
onready var hp_butt = $shop/shop/panel/base/options/hp/buy
onready var arm_butt = $shop/shop/panel/base/options/armor/buy
onready var def_butt = $shop/shop/panel/base/options/defense/buy
onready var atk_butt = $shop/shop/panel/base/options/attack/buy
var hp_cost = 2
var arm_cost = 3
var def_cost = 1
var atk_cost = 3
var tint
var wave_number = 1
var mob_count = 0
var player : MinigameHero
var gen = RandomNumberGenerator.new()
var hh_text = load("res://prefabs/effects/hurt_heal_text.tscn")

signal wave_ended


func _enter_tree():
	tint = $tint/tint
	tint.color = Color.black


func get_rewards():
	var wave = floor((wave_number - 1) / 5)
	if wave >= 4:
		wave += 0.5
	if wave <= 0:
		return
	var loot = {
		"gems" : floor(G.current_tickets * wave / 2.5), 
		"coins" : G.current_tickets * wave * 40, 
		"box" : round(G.current_tickets * wave / 1.5),
	}
	G.receive_loot(loot)


func _ready():
	var current_location = int(G.getv("level", "1_1").split('_')[0])
	for i in range(mobs.size() - 1, -1, -1):
		if mobs_locations[i] > current_location:
			mobs.remove(i)
	
	gen.randomize()
	player = load("res://minigames/minigame4/hero.tscn").instance()
	player.get_node("camera/gui/base/intro/text/main").text = level_name
	player.get_node("camera/gui/base/intro/text/location").text = location
	player.get_node("camera/gui/base/pause_menu/panel/restart").disabled = true
	player.position = pos.position
	player.name = "player"
	player.custom_respawn_scene = "res://minigames/minigame4/minigame.tscn"
	if not G.getv("hardcore", false):
		player.get_node("camera").connect("gived_up", self, "get_rewards")
	hp_butt.connect("pressed", self, "buy_health")
	arm_butt.connect("pressed", self, "buy_armor")
	def_butt.connect("pressed", self, "buy_defense")
	atk_butt.connect("pressed", self, "buy_attack")
	add_child(player)
	if has_node("lights"):
		if G.getv("graphics", 15) & G.Graphics.BEAUTY_LIGHT == 0:
			for i in $lights.get_children():
				if i is Light2D:
					i.hide()
				else:
					i.color = Color(0.35, 0.35, 0.35, 1)
	tint.color = Color(1, 1, 1, 0)
	yield(get_tree().create_timer(2, false), "timeout")
	start_wave()


func start_wave():
	$shop.hide()
	if player.immune_counter > 0:
		player.immune_counter -= 1
	player.can_control = true
	player.make_dialog(tr("4.wave.start") % wave_number, 5, Color.red)
	mob_count = round(wave_number * 0.65) + gen.randi_range(0, 3)
	if wave_number == 20:
		mob_count = 4
	for i in range(mob_count):
		spawn_mob(i)
		st.start(gen.randf_range(0.7, 1.5))
		yield(st, "timeout")
	player.make_dialog(tr("4.wave.end"))
	yield(self, "wave_ended")
	if wave_number == 20:
		wave_number += 1
		G.addv("ls_completed", 1)
		$tint/tint/anim.play("win")
		yield($tint/tint/anim, "animation_finished")
		G.ach.complete(Achievements.LAST_STANDER)
		get_rewards()
		yield(G, "loot_end")
		G.dialog_in_menu = tr("4.win")
		get_tree().change_scene("res://scenes/menu/menu.tscn")
		return
	player.make_dialog(tr("4.wave.clear"), 2, Color.green)
	wave_number += 1
	player.immune_counter += 1
	yield(get_tree().create_timer(2, false), "timeout")
	player.stop()
	player.can_control = false
	$shop.show()
	update_shop()


func spawn_mob(pos_id = -1):
	mobs.shuffle()
	var mob = mobs[0].instance() as Mob
	mob.vision_distance = 10000
	if wave_number != 20:
		mob.stats_multiplier = 1 + wave_number * 0.2 + gen.randf_range(-wave_number * 0.05, wave_number * 0.08)
		var spawn_id = str(gen.randi_range(0, 3))
		mob.global_position = get_node("spawn_points/pos" + spawn_id).global_position
		get_node("spawn_points/pos" + spawn_id + "/anim").play("spawn")
		if G.percent_chance(2):
			mob.stats_multiplier *= 1.5
			mob.modulate = Color.red
	else:
		mob.stats_multiplier = 20
		mob.modulate = Color.red
		var spawn_id = str(pos_id)
		mob.global_position = get_node("spawn_points/pos" + spawn_id).global_position
		get_node("spawn_points/pos" + spawn_id + "/anim").play("spawn")
	mob.connect("died", self, "mob_died", [mob])
	if mob.has_signal("transformed"):
		mob.connect("transformed", self, "mob_transformed")
	$mobs.add_child(mob, true)


func mob_died(node):
	if not node is Mob:
		return
	mob_count -= 1
	player.make_dialog(tr("4.wave.left") + str(mob_count))
	if mob_count <= 0:
		emit_signal("wave_ended")
	var amount = round(node.stats_multiplier * gen.randf_range(1, 2.5)) + gen.randi_range(1, 4)
	player.add_coins(amount)
	var hh = hh_text.instance()
	hh.global_position = node.global_position
	hh.z_index = 30
	hh.get_node("text").modulate = Color.yellow
	hh.get_node("text").text = "+" + str(amount)
	add_child(hh)


func mob_transformed(mob):
	if not mob is Mob:
		return
	mob._vision_distance = 100000000
	if mob.has_signal("transformed"):
		mob.connect("died", self, "mob_died", [mob])
		mob.connect("transformed", self, "mob_transformed")
	elif mob.has_signal("returned_to_owner"):
		mob.connect("returned_to_owner", self, "mob_transformed")


func update_shop():
	hp_butt.disabled = player.coins < hp_cost
	arm_butt.disabled = player.coins < arm_cost
	def_butt.disabled = player.coins < def_cost
	atk_butt.disabled = player.coins < atk_cost
	hp_butt.text = str(hp_cost)
	arm_butt.text = str(arm_cost)
	atk_butt.text = str(atk_cost)
	def_butt.text = str(def_cost)


func buy_health():
	player.add_max_health(20, hp_cost)
	hp_cost += 1
	update_shop()


func buy_armor():
	player.add_armor(15, arm_cost)
	arm_cost += 1
	update_shop()


func buy_defense():
	player.add_defense(1, def_cost)
	def_cost += 1
	update_shop()


func buy_attack():
	player.add_attack(6, atk_cost)
	atk_cost += 1
	update_shop()
