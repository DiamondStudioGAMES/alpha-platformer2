extends Control


const CLASSES = ["knight", "butcher", "spearman", "wizard", "archer"]
var classes_to_unlock = []
var gadget_classes = []
var power_classes = []
var ulti_classes = []
var soul_power_classes = []
var amulet_types = []
var current_receive = null
var current_cost = null
var current_id = -1
var current_day = 0
var current_unix_time = 0
var offer_obj = load("res://prefabs/menu/offer.tscn")
onready var p0 = $scroll/offers/resources/potion0/count
onready var b0 = $scroll/offers/resources/potion0/buy
onready var p1 = $scroll/offers/resources/potion1/count
onready var b1 = $scroll/offers/resources/potion1/buy
onready var p2 = $scroll/offers/resources/potion2/count
onready var b2 = $scroll/offers/resources/potion2/buy
onready var http = $http_request
var gem = load("res://textures/items/gem.png")
var coin = load("res://textures/items/coin.png")
var diamond_box = load("res://textures/items/diamond_box.png")
var gold_box = load("res://textures/items/gold_box.png")
var box = load("res://textures/items/box.png")
var token = load("res://textures/items/token.png")
var ulti_token = load("res://textures/items/ulti_token.png")
var sp = load("res://textures/items/soul_power.png")
var gadget = load("res://textures/items/gadget.png")
var ticket = load("res://textures/items/ticket.png")
var wild_token = load("res://textures/items/wild_token.png")
var wild_ulti_token = load("res://textures/items/wild_ulti_token.png")
var CLASS_ICONS = {
	"knight" : load("res://textures/classes/knight_helmet.png"),
	"butcher" : load("res://textures/classes/butcher_helmet.png"),
	"spearman" : load("res://textures/classes/spearman_helmet.png"),
	"wizard" : load("res://textures/classes/wizard_helmet.png"),
	"archer" : load("res://textures/classes/archer_helmet.png") 
}
var ULTI_ICONS = {
	"knight" : load("res://textures/gui/ulti_icon_0.tres"),
	"butcher" : load("res://textures/gui/ulti_icon_1.tres"),
	"spearman" : load("res://textures/gui/ulti_icon_2.tres"),
	"wizard" : load("res://textures/gui/ulti_icon_3.tres"),
	"archer" : load("res://textures/gui/ulti_icon_4.tres")
}
var POTIONS_ICONS = {
	"small" : load("res://textures/items/small_potion.png"),
	"normal" : load("res://textures/items/normal_potion.png"),
	"big" : load("res://textures/items/big_potion.png")
}
var AMULET_ICONS = {
	"power" : load("res://textures/items/amulet_power_frag.png"),
	"defense" : load("res://textures/items/amulet_defense_frag.png"),
	"health" : load("res://textures/items/amulet_health_frag.png"),
	"speed" : load("res://textures/items/amulet_speed_frag.png"),
	"reload" : load("res://textures/items/amulet_reload_frag.png"),
	"ulti" : load("res://textures/items/amulet_ulti_frag.png"),
}


func _ready():
	fetch_online_offers()
	$confirm.get_ok().text = tr("shop.buy")
	current_day = Time.get_date_dict_from_system()["day"]
	current_unix_time = Time.get_unix_time_from_system()
	show_offers()
	if not G.getv("learned", false):
		G.setv("shop_visited", true)


func _process(delta):
	$coins.text = str(G.getv("coins", 0))
	$gems.text = str(G.getv("gems", 0))
	$tickets.text = str(G.getv("tickets", 0))
	if current_day != Time.get_date_dict_from_system()["day"]:
		G.ignore_next_music_stop = true
		get_tree().reload_current_scene()
	if G.getv("potions1", 0) < 1:
		p0.text = ""
		b0.disabled = false
	else:
		p0.text = tr("shop.you_have") + str(G.getv("potions1", 0))
		b0.disabled = int(p0.text) >= 3
	if G.getv("potions2", 0) < 1:
		p1.text = ""
		b1.disabled = false
	else:
		p1.text = tr("shop.you_have") + str(G.getv("potions2", 0))
		b1.disabled = int(p1.text) >= 2
	if G.getv("potions3", 0) < 1:
		p2.text = ""
		b2.disabled = false
	else:
		p2.text = tr("shop.you_have") + str(G.getv("potions3", 0))
		b2.disabled = int(p2.text) >= 1


func buy(costs = "", receives = "", id = -1):
	var cost = JSON.parse(costs).result
	var receive = JSON.parse(receives).result
	for i in cost:
		if G.getv(i, 0) < cost[i]:
			$not_enough/anim.play("no")
			return
	current_receive = receive
	current_cost = cost
	current_id = id
	if cost.empty():
		confirm_buy()
		return
	var add = ""
	for i in receive:
		add += ", "
		match i:
			"coins":
				add += tr("item.coins").to_lower() + " (" + str(receive[i])
			"gems":
				add += tr("item.gems").to_lower() + " (" + str(receive[i])
			"tickets":
				add += tr("item.tickets").to_lower() + " (" + str(receive[i])
			"amulet_frags":
				for j in receive[i]:
					add += tr("item.frags").to_lower() + " (" + tr(G.AMULET_NAME[G.AMULET_ID[j]]) + \
							", " + str(receive[i][j])
			"gadget":
				for j in receive[i]:
					add += tr("item.gadget").to_lower() + " (" + tr(G.CLASSES[j])
			"soul_power":
				for j in receive[i]:
					add += tr("item.sp").to_lower() + " (" + tr(G.CLASSES[j])
			"class":
				for j in receive[i]:
					add += tr("item.class").to_lower() + " (" + tr(G.CLASSES[j])
			"tokens":
				for j in receive[i]:
					add += tr("item.tokens").to_lower() + " (" + tr(G.CLASSES[j]) + ", " + str(receive[i][j])
			"ulti_tokens":
				for j in receive[i]:
					add += tr("item.utokens").to_lower() + " (" + tr(G.CLASSES[j]) + ", " + str(receive[i][j])
			"wild_tokens":
				add += tr("item.wtokens").to_lower() + " (" + str(receive[i])
			"wild_ulti_tokens":
				add += tr("item.wutokens").to_lower() + " (" + str(receive[i])
			"potions1":
				add += tr("item.potion1").to_lower() + " (" + str(receive[i])
			"potions2":
				add += tr("item.potion2").to_lower() + " (" + str(receive[i])
			"potions3":
				add += tr("item.potion3").to_lower() + " (" + str(receive[i])
			"box":
				add += tr("item.box").to_lower() + " (" + str(receive[i])
			"gold_box":
				add += tr("item.box.big").to_lower() + " (" + str(receive[i])
			"diamond_box":
				add += tr("item.box.mega").to_lower() + " (" + str(receive[i])
		add += ")"
	add[0] = ""
	add += tr("shop.confirm.with")
	for i in cost:
		if i == "coins":
			add += " " + tr("item.coins").to_lower() + " (" + str(cost[i]) + ")"
		if i == "gems":
			add += " " + tr("item.gems").to_lower() + " (" + str(cost[i]) + ")"
	$confirm.dialog_text = tr("shop.confirm.text") + add + "?"
	$confirm.get_cancel().text = tr("menu.cancel")
	$confirm.popup_centered()


func confirm_buy():
	var rec = current_receive
	var c = current_cost
	var id = current_id
	var loot_to_show = {}
	current_receive = null
	current_cost = null
	current_id = -1
	for i in c:
		G.setv(i, G.getv(i, 0) - c[i])
	if id != -1:
		get_node("scroll/offers/offer" + str(id)).queue_free()
	if id > 1000:
		G.addv("online_offers_used_id", [id], [])
	remove_offer(id)
	G.receive_loot(rec)


func info_box(box_type = "gold"):
	power_classes = []
	gadget_classes = []
	soul_power_classes = []
	ulti_classes = []
	amulet_types = []
	classes_to_unlock = CLASSES.duplicate()
	var had_classes = G.getv("classes", [])
	var has_amulet = false
	for i in had_classes:
		if i in classes_to_unlock:
			classes_to_unlock.erase(i)
	for i in had_classes:
		if G.getv(i + "_level", 0) >= 10:
			has_amulet = true
		if G.getv(i + "_level", 0) < 20:
			power_classes.append(i)
		if G.getv(i + "_ulti_level", 0) < 5:
			ulti_classes.append(i)
		if G.getv(i + "_level", 0) >= 15 and not G.getv(i + "_gadget", false):
			gadget_classes.append(i)
		if G.getv(i + "_level", 0) == 20 and not G.getv(i + "_soul_power", false):
			soul_power_classes.append(i)
	if has_amulet:
		for i in range(6):
			if G.getv("total_amulet_frags_"+G.AMULET[i], 0) < G.AMULET_MAX[i]:
				amulet_types.append(G.AMULET[i])
	var hero_chance = G.getv("hero_chance", 4) if not classes_to_unlock.empty() else 0
	var amul_chance = 16 if not amulet_types.empty() else 0
	var gadget_chance = 4 if not gadget_classes.empty() else 0
	var sp_chance = 2 if not soul_power_classes.empty() else 0
	var coins_chance = 100 - hero_chance - gadget_chance - sp_chance - amul_chance
	var coins_suffix = tr("shop.box_info.tokens") if not power_classes.empty() or not ulti_classes.empty() else ""
	if $box_info/base/diamond_box_visual is InstancePlaceholder:
		$box_info/base/diamond_box_visual.replace_by_instance()
		$box_info/base/gold_box_visual.replace_by_instance()
	$box_info/base/diamond_box_visual.hide()
	$box_info/base/gold_box_visual.hide()
	get_node("box_info/base/%s_box_visual" % box_type).show()
	$box_info/base/info/brief.text = tr("shop.box_info." + box_type)
	$box_info/base/info/info.text = tr("shop.box_info").format({"cs" : coins_suffix, "cc" : coins_chance, 
			"hc" : hero_chance, "ac" : amul_chance, "gc" : gadget_chance, "sc" : sp_chance})
	$box_info.show()


func show_offers():
	if G.getv("offers_upd", {"day": 0})["day"] != Time.get_date_dict_from_system()["day"] and \
			G.getv("offers_upd_time", Time.get_unix_time_from_system()) <= Time.get_unix_time_from_system():
		generate_offers()
		return
	for i in G.getv("offers", []):
		show_offer(i["costs"], i["receives"], i["id"], i["name"], i.get("sale", 0))


func show_offer(costs, receives, id = 0, name = tr("shop.offer.title"), sale = 0):
	var off = offer_obj.instance()
	off.name = "offer" + str(id)
	off.offer_rec = receives
	off.get_node("title").text = name
	if sale != 0:
		off.get_node("sale").show()
		if sale < 0:
			off.get_node("sale/amount").text = tr("shop.offer.sale") % -sale
		else:
			off.get_node("sale/amount").text = tr("shop.offer.more") % sale
	if not costs.empty():
		off.get_node("buy").icon = gem if costs.has("gems") else coin
		off.get_node("buy").text = str(costs[costs.keys()[0]])
	else:
		off.get_node("buy").text = tr("shop.offer.free")
		off.get_node("buy").icon = null
	var l = 0
	for i in receives:
		off.get_node("items/item" + str(l)).show()
		if i == "coins":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.coins")
			off.get_node("items/item" + str(l) + "/icon").texture = coin
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "gems":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.gems")
			off.get_node("items/item" + str(l) + "/icon").texture = gem
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "tickets":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.tickets")
			off.get_node("items/item" + str(l) + "/icon").texture = ticket
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "gadget":
			for j in receives[i]:
				off.get_node("items/item" + str(l)).show()
				off.get_node("items/item" + str(l) + "/name").text = tr("item.gadget")
				off.get_node("items/item" + str(l) + "/icon").texture = gadget
				off.get_node("items/item" + str(l) + "/count").text = tr(G.CLASSES[j])
				l += 1
		if i == "soul_power":
			for j in receives[i]:
				off.get_node("items/item" + str(l)).show()
				off.get_node("items/item" + str(l) + "/name").text = tr("item.sp")
				off.get_node("items/item" + str(l) + "/icon").texture = sp
				off.get_node("items/item" + str(l) + "/count").text = tr(G.CLASSES[j])
				l += 1
		if i == "class":
			for j in receives[i]:
				off.get_node("items/item" + str(l)).show()
				off.get_node("items/item" + str(l) + "/name").text = tr("item.class")
				off.get_node("items/item" + str(l) + "/icon").texture = CLASS_ICONS[j]
				off.get_node("items/item" + str(l) + "/count").text = tr(G.CLASSES[j])
				l += 1
		if i == "tokens":
			for j in receives[i]:
				off.get_node("items/item" + str(l)).show()
				off.get_node("items/item" + str(l) + "/name").text = tr("item.tokens")
				off.get_node("items/item" + str(l) + "/icon").texture = token
				off.get_node("items/item" + str(l) + "/icon").self_modulate = G.CLASS_COLORS[j]
				off.get_node("items/item" + str(l) + "/icon/sub").texture = CLASS_ICONS[j]
				off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i][j])
				l += 1
		if i == "ulti_tokens":
			for j in receives[i]:
				off.get_node("items/item" + str(l)).show()
				off.get_node("items/item" + str(l) + "/name").text = tr("item.utokens")
				off.get_node("items/item" + str(l) + "/icon").texture = ulti_token
				off.get_node("items/item" + str(l) + "/icon").self_modulate = G.CLASS_COLORS[j]
				off.get_node("items/item" + str(l) + "/icon/sub").texture = ULTI_ICONS[j]
				off.get_node("items/item" + str(l) + "/icon/sub").margin_left = 12
				off.get_node("items/item" + str(l) + "/icon/sub").margin_right = -12
				off.get_node("items/item" + str(l) + "/icon/sub").margin_top = 12
				off.get_node("items/item" + str(l) + "/icon/sub").margin_bottom = -12
				off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i][j])
				l += 1
		if i == "amulet_frags":
			for j in receives[i]:
				off.get_node("items/item" + str(l)).show()
				off.get_node("items/item" + str(l) + "/name").text = tr("item.frags")
				off.get_node("items/item" + str(l) + "/icon").texture = AMULET_ICONS[j]
				off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i][j])
				l += 1
		if i == "wild_tokens":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.tokens")
			off.get_node("items/item" + str(l) + "/icon").texture = wild_token
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "wild_ulti_tokens":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.utokens")
			off.get_node("items/item" + str(l) + "/icon").texture = wild_ulti_token
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "potions1":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.potion1")
			off.get_node("items/item" + str(l) + "/icon").texture = POTIONS_ICONS["small"]
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "potions2":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.potion2")
			off.get_node("items/item" + str(l) + "/icon").texture = POTIONS_ICONS["normal"]
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "potions3":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.potion3")
			off.get_node("items/item" + str(l) + "/icon").texture = POTIONS_ICONS["big"]
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "box":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.box")
			off.get_node("items/item" + str(l) + "/icon").texture = box
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "gold_box":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.box.big")
			off.get_node("items/item" + str(l) + "/icon").texture = gold_box
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
		if i == "diamond_box":
			off.get_node("items/item" + str(l) + "/name").text = tr("item.box.mega")
			off.get_node("items/item" + str(l) + "/icon").texture = diamond_box
			off.get_node("items/item" + str(l) + "/count").text = "x" + str(receives[i])
			l += 1
	off.get_node("buy").connect("pressed", self, "buy", [JSON.print(costs), JSON.print(receives), id])
	$scroll/offers.add_child(off)
	$scroll/offers.move_child(off, 0)


func remove_offer(id):
	var offs = G.getv("offers", [])
	for i in G.getv("offers", []):
		if i["id"] == id:
			offs.erase(i)


func generate_offers():
	G.setv("offers", [])
	power_classes = []
	gadget_classes = []
	soul_power_classes = []
	ulti_classes = []
	amulet_types = []
	classes_to_unlock = CLASSES.duplicate()
	var had_classes = G.getv("classes", [])
	var has_amulet = false
	for i in had_classes:
		if i in classes_to_unlock:
			classes_to_unlock.erase(i)
	for i in had_classes:
		if G.getv(i + "_level", 0) >= 10:
			has_amulet = true
		if G.getv(i + "_level", 0) < 20:
			power_classes.append(i)
		if G.getv(i + "_ulti_level", 0) < 5:
			ulti_classes.append(i)
		if G.getv(i + "_level", 0) >= 15 and not G.getv(i + "_gadget", false):
			gadget_classes.append(i)
		if G.getv(i + "_level", 0) == 20 and not G.getv(i + "_soul_power", false):
			soul_power_classes.append(i)
	if has_amulet:
		for i in range(6):
			if G.getv("total_amulet_frags_"+G.AMULET[i], 0) < G.AMULET_MAX[i]:
				amulet_types.append(G.AMULET[i])
	var gen = RandomNumberGenerator.new()
	gen.randomize()
	var i = 0
	var limit = gen.randi_range(3, 6)
	while true:
		if i >= limit:
			break
		var offer = {}
		var list_of_types = [0, 1, 1, 2, 3, 4, 4, 5, 5, 5, 6, 6, 6, 7, 7, 7, 8, 8, 8, 9, 9, 10, 10, 10, 11]
		list_of_types.shuffle()
		var type = list_of_types[4]
		if type == 0:
			#COINS
			var mul = [1, 2, 4, 1, 1, 2]
			mul.shuffle()
			var discount = [1.1, 1.1, 1.1, 1.2, 1.2, 1.3]
			discount.shuffle()
			var cc = 2250 * mul[1] * discount[3]
			var cost = 15 if mul[1] == 1 else 25 if mul[1] == 2 else 45
			offer = {"costs": {"gems" : cost}, "receives" : {"coins" : cc}, "id" : i, "name" : tr("shop.offer.title"), "sale" : round((discount[3] - 1) * 100)}
		if type == 1:
			#POTIONS
			var t = ["1", "1", "2", "2", "3"]
			t.shuffle()
			var discount = [0.9, 0.9, 0.8, 0.7]
			discount.shuffle()
			var c = gen.randi_range(1, 4 - int(t[2]) - G.getv("potions" + t[2], 0))
			if c <= 0:
				continue
			var cost_1 = 300 if t[2] == "1" else 650 if t[2] == "2" else 1000
			var cost = cost_1 * c * discount[1]
			if G.getv("potions" + t[2], 0) + c > 4 - int(t[2]):
				continue
			offer = {"costs": {"coins" : cost}, "receives" : {"potions" + t[2] : c}, "id" : i, "name" : tr("shop.offer.title"), "sale" : round((1 - discount[1]) * -100)}
		if type == 2:
			#BOX
			var cost = gen.randi_range(2, 3)
			var count = gen.randi_range(2, 10)
			offer = {"costs": {"gems" : cost * count}, "receives" : {"box" : count}, "id" : i, "name" : tr("shop.offer.title"), "sale" : round((4 - cost) * -25)}
		if type == 3:
			#BOX GOLD
			var cost = 10 - gen.randi_range(2, 4)
			var count = gen.randi_range(1, 5)
			offer = {"costs": {"gems" : cost * count}, "receives" : {"gold_box" : count}, "id" : i, "name" : tr("shop.offer.title"), "sale" : round((10 - cost) * -10)}
		if type == 4:
			#DIAMOND BOX
			var cost = 30 - gen.randi_range(1, 3) * 5
			var count = gen.randi_range(1, 3)
			offer = {"costs": {"gems" : cost * count}, "receives" : {"diamond_box" : count}, "id" : i, "name" : tr("shop.offer.title"), "sale" : round((30 - cost) * -3.33)}
		if type == 5:
			#GADGET
			if not gadget_classes.empty():
				gadget_classes.shuffle()
				var to = gadget_classes[0]
				offer = {"costs": {"coins" : 1000}, "receives" : {"gadget" : [to]}, "id" : i, "name" : tr("shop.offer.item"), "sale" : 0}
			else:
				continue
		if type == 6:
			#SOUL POWER
			if not soul_power_classes.empty():
				soul_power_classes.shuffle()
				var to = soul_power_classes[0]
				offer = {"costs": {"coins" : 2000}, "receives" : {"soul_power" : [to]}, "id" : i, "name" : tr("shop.offer.item"), "sale" : 0}
			else:
				continue
		if type == 7:
			#TOKENS
			if randi() % 2 == 1:
				#POWER
				if power_classes.empty():
					continue
				power_classes.shuffle()
				var to = power_classes[0]
				var count = 20 + gen.randi_range(0, 10) * 10
				offer = {"costs": {"coins" : count * 5}, "receives" : {"tokens" : {to: count }}, "id" : i, "name" : tr("shop.offer.tokens"), "sale" : 0}
			else:
				#ULTI
				if ulti_classes.empty():
					continue
				ulti_classes.shuffle()
				var to = ulti_classes[0]
				var count = 10 + gen.randi_range(0, 10) * 2
				offer = {"costs": {"coins" : count * 20}, "receives" : {"ulti_tokens" : {to: count }}, "id" : i, "name" : tr("shop.offer.tokens"), "sale" : 0}
		if type == 8:
			#CLASS
			if classes_to_unlock.empty():
				continue
			classes_to_unlock.shuffle()
			var what = classes_to_unlock[0]
			var count_of_pt = 0
			var count_of_ut = 0
			var cost = 30
			var real_cost = 30
			if randi() % 3 == 1:
				count_of_pt = 120 + gen.randi_range(0, 1) * 120
				if count_of_pt == 100:
					real_cost += 4
					cost += 3
				else:
					real_cost += 8
					cost += 5
			if randi() % 3 == 2:
				count_of_ut = 30 + gen.randi_range(0, 1) * 30
				if count_of_ut == 30:
					real_cost += 4
					cost += 3
				else:
					real_cost += 8
					cost += 5
			var sale = real_cost / float(cost) * 100 - 100
			if count_of_pt == 0 and count_of_ut == 0:
				offer = {"costs": {"gems" : cost}, "receives" : {"class" : [what]}, "id" : i, "name" : tr("item.class"), "sale" : 0}
			elif count_of_pt == 0 and count_of_ut != 0:
				offer = {"costs": {"gems" : cost}, "receives" : {"class" : [what], "ulti_tokens" : {what: count_of_ut }}, "id" : i, "name" : tr("shop.offer.kit"), "sale" : sale}
			elif count_of_pt != 0 and count_of_ut == 0:
				offer = {"costs": {"gems" : cost}, "receives" : {"class" : [what], "tokens" : {what: count_of_pt}}, "id" : i, "name" : tr("shop.offer.kit"), "sale" : sale}
			else:
				offer = {"costs": {"gems" : cost}, "receives" : {"class" : [what], "tokens" : {what: count_of_pt}, "ulti_tokens" : {what: count_of_ut}}, "id" : i, "name" : tr("shop.offer.kit"), "sale" : sale}
		if type == 9: #WILD TOKENS
			if randi() % 2 == 1:
				#POWER
				if power_classes.empty():
					continue
				var count = 20 + gen.randi_range(0, 10) * 10
				offer = {"costs": {"coins" : count * 6}, "receives" : {"wild_tokens" : count}, "id" : i, "name" : tr("shop.offer.tokens"), "sale" : 0}
			else:
				#ULTI
				if ulti_classes.empty():
					continue
				var count = 10 + gen.randi_range(0, 15)
				offer = {"costs": {"coins" : count * 25}, "receives" : {"wild_ulti_tokens" : count}, "id" : i, "name" : tr("shop.offer.tokens"), "sale" : 0}
		if type == 10:
			# AMULET FRAGS
			if amulet_types.empty():
				continue
			var count = randi() % 2 + 1
			amulet_types.shuffle()
			var am_type = amulet_types[0]
			offer = {"costs": {"coins" : count * 150}, "receives" : {"amulet_frags": {am_type:count}}, "id" : i, "name" : tr("shop.offer.item"), "sale" : 0}
		if type == 11:
			#TICKETS
			var mul = [1, 2.5, 4, 1, 1, 2.5]
			mul.shuffle()
			var discount = [1.1, 1.1, 1.1, 1.2, 1.2, 1.3]
			discount.shuffle()
			var tc = round(10 * mul[1] * discount[3])
			var cost = 5 if mul[1] == 1 else 10 if mul[1] == 2.5 else 15
			offer = {"costs": {"gems" : cost}, "receives" : {"tickets" : tc}, "id" : i, "name" : tr("shop.offer.title"), "sale" : round((discount[3] - 1) * 100)}
		var exists = false
		for y in G.getv("offers", []):
			if offer["receives"].hash() == y["receives"].hash():
				exists = true
		if exists:
			continue
		G.setv("offers", G.getv("offers", []) + [offer])
		i += 1
	var free_receives = [{"gold_box":1}, {"tickets":gen.randi_range(2, 3)}, {"gems":gen.randi_range(1, 2)}, {"coins":10*gen.randi_range(15, 30)}]
	if not power_classes.empty():
		power_classes.shuffle()
		free_receives.append({"tokens":{power_classes[0]: gen.randi_range(15, 30)*2}})
	if not ulti_classes.empty():
		ulti_classes.shuffle()
		free_receives.append({"ulti_tokens":{ulti_classes[0]: gen.randi_range(7, 15)}})
	if not amulet_types.empty():
		amulet_types.shuffle()
		free_receives.append({"amulet_frags":{amulet_types[0]:1}})
	if G.getv("potions1", 0) < 5:
		free_receives.append({"potions1": 1})
	free_receives.shuffle()
	G.setv("offers", G.getv("offers", []) + [{"costs":{}, "receives":free_receives[0], "id" : 993, "name" : tr("shop.offer.gift")}])
	G.setv("offers_upd", Time.get_date_dict_from_system())
	G.setv("offers_upd_time", Time.get_unix_time_from_system())
	G.setv("collected_ad_bonus", false)
	G.save()
	show_offers()


func promocodes():
	get_tree().change_scene("res://scenes/menu/promocodes.tscn")


func quit():
	G.ignore_next_music_stop = true
	get_tree().change_scene("res://scenes/menu/levels.tscn")


func fetch_online_offers():
	http.download_file = OS.get_cache_dir().plus_file("online_offers_cache.cfg")
	http.connect("request_completed", self, "request_online_response", [], CONNECT_ONESHOT)
	var err = http.request("https://diamondstudiogames.github.io/apa2/offers.cfg")
	if err:
		print("fetch failed:", err)


func request_online_response(result, code, header, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		print("fetch failed:", result, " ", code)
		return
	yield(get_tree(), "idle_frame")
	var cf = ConfigFile.new()
	var err = cf.load_encrypted_pass(OS.get_cache_dir().plus_file("online_offers_cache.cfg"), "apa2_online")
	var dir = Directory.new()
	dir.open(OS.get_cache_dir())
	dir.remove("online_offers_cache.cfg")
	if err:
		print("fetch failed:", err)
		return
	if not cf.has_section("offers"):
		print("fetch failed:", "no offers")
		return
	for i in cf.get_section_keys("offers"):
		if int(i) in G.getv("online_offers_used_id", []):
			continue
		var j = cf.get_value("offers", i, {})
		if j.has("ids"):
			if not G.getv("save_id", "none") in j["ids"]:
				continue
		show_offer(j["costs"], j["receives"], int(i), j["name"], j["sale"])


func _enter_tree():
	G.play_menu_music()


func _exit_tree():
	G.stop_menu_music()
