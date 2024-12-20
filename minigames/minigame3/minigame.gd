extends Node


var remaining_time = 0
var collected_gems = 0
var collected_coins = 0
var timer = 0
var minutes_passed = 0
var coin_counter = 0
var effect_coins = load("res://minigames/minigame3/coins_add_effect.tscn")
var effect_gems = load("res://minigames/minigame3/gems_add_effect.tscn")
var coin = load("res://minigames/minigame3/coin.tscn")
var gem = load("res://minigames/minigame3/gem.tscn")
onready var coins_count = $"../gui/base/coins"
onready var gems_count = $"../gui/base/gems"
onready var remains = $"../gui/base/remains"
onready var spawn_pos = $spawn_pos.global_translation


func add_gems(gems):
	collected_gems += gems
	G.setv("gems", G.getv("gems", 10) + gems)
	var n = effect_gems.instance()
	n.text = "+" + str(gems)
	gems_count.add_child(n)


func add_coins(coins):
	collected_coins += coins
	G.setv("coins", G.getv("coins", 10) + coins)
	var n = effect_coins.instance()
	n.text = "+" + str(coins)
	coins_count.add_child(n)


func _ready():
	remaining_time = G.getv("ss_remained", 0)


func _process(delta):
	coins_count.text = str(collected_coins)
	gems_count.text = str(collected_gems)
	var seconds = int(ceil(remaining_time))
	remains.text = tr("3.remains") % [seconds / 3600, seconds / 60 % 60, seconds % 60]
	if remaining_time <= 0:
		return
	remaining_time -= delta
	timer += delta
	if timer >= 60:
		timer = 0
		spawn_item(coin, 8)
		add_coins(8)
		minutes_passed += 1
	if minutes_passed >= 10:
		minutes_passed = 0
		spawn_item(gem, 1)
		add_gems(1)


func quit():
	get_tree().change_scene("res://scenes/menu/levels.tscn")


func _on_spawn_timer_timeout():
	G.setv("ss_remained", remaining_time)
	if remaining_time <= 0:
		return
	if coin_counter >= 75:
		spawn_item(gem, 1)
		coin_counter = 0
	else:
		spawn_item(coin, 1)
		coin_counter += 1


func spawn_item(item, count):
	for i in range(count):
		var n = item.instance()
		var tra = Transform.IDENTITY
		tra.origin = Vector3(spawn_pos.x + rand_range(-2, 2), spawn_pos.y + rand_range(-1, 1), spawn_pos.z + rand_range(-2, 2))
		n.global_transform = tra
		add_child(n, true)


func _on_ticket_selector_started():
	remaining_time += 10 * 60
	G.setv("ss_remained", remaining_time)
