class_name Level
extends Node2D


const DEATH_CHANCES = {
	-1 : [2, 7],
	0 : [3, 8],
	1 : [5, 10],
	2 : [6, 12],
	3 : [8, 15],
	4 : [10, 20],
}
export (String) var location = "Где-то"
export (String) var level_name = "УРОВЕНЬ: ТЕСТ"
export (NodePath) var game_over_spawn_pos = @"spawn_pos"
var tint
var player
var gen = RandomNumberGenerator.new()
onready var pos = $spawn_pos


func _enter_tree():
	tint = $tint/tint
	tint.color = Color.black


func _ready():
	if MP.is_active:
		yield($"/root/mg", "game_started")
	gen.randomize()
	var chance = DEATH_CHANCES[G.getv("hate_level", -1)][1] if G.getv("go_chance", false) \
			else DEATH_CHANCES[G.getv("hate_level", -1)][0]
	chance = 100 if G.getv("hated_death", false) else chance
	if G.percent_chance(chance) and name.begins_with("level"):
		print("death")
		player = load("res://prefabs/classes/death.tscn").instance()
	else:
		player = load("res://prefabs/classes/" + G.getv("selected_class", "player") + ".tscn").instance()
	player.get_node("camera/gui/base/intro/text/main").text = tr(level_name)
	player.get_node("camera/gui/base/intro/text/location").text = tr(location)
	player.get_node("camera").limit_top = $borders/up.global_position.y + 64
	player.get_node("camera").limit_bottom = $borders/down.global_position.y - 64
	if G.getv("go_chance", false) and not MP.is_active:
		player.position = get_node(game_over_spawn_pos).position
	else:
		player.position = pos.position
	player.name = "player" + (str(get_tree().get_network_unique_id()) if MP.is_active else "")
	add_child(player)
	G.setv("hated_death", false)
	G.setv("go_chance", false)
	if has_node("lights"):
		if G.getv("graphics", G.Graphics.BEAUTY_DEFAULT) & G.Graphics.BEAUTY_LIGHT == 0:
			for i in $lights.get_children():
				if i is Light2D:
					i.hide()
				else:
					i.color = Color(0.35, 0.35, 0.35, 1)
	tint.color = Color.transparent
