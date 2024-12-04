extends Control


var pending_promocode = ""
var promos = load("res://misc/promocodes.tres")
onready var line = $line_edit
onready var comment = $comment
onready var http = $http
onready var message = $online/message


func back():
	get_tree().change_scene("res://scenes/menu/shop.tscn")


func is_promocode_used(code = ""):
	if code in G.getv("promocodes_used", []):
		return true
	return false


func use_promocode(code = ""):
	G.setv("promocodes_used", G.getv("promocodes_used", []) + [code])


func set_comment(text = ""):
	comment.text = text


func enter():
	var text = line.text.to_lower().strip_edges().strip_escapes()
	line.text = ""
	if is_promocode_used(text):
		set_comment(tr("promocodes.used"))
		return
	if text.begins_with("online_"):
		fetch_online_promocode(text)
		return
	var found = false
	for i in promos.promocodes:
		var promo = i
		if promo.id == text:
			if not promo.custom_method_pass.empty():
				if not promo.call(promo.custom_method_pass, self):
					continue
			found = true
			set_comment(promo.comment)
			if not promo.reward.empty():
				G.receive_loot(promo.reward)
			if not promo.multiple_uses:
				use_promocode(text)
			if not promo.custom_method.empty():
				promo.call(promo.custom_method, self)
	if not found:
		set_comment(tr("promocodes.wrong"))


func fetch_online_promocode(text):
	pending_promocode = text
	$online.popup_centered()
	set_message(tr("promocodes.fetch"))
	http.download_file = OS.get_cache_dir().plus_file("online_promocodes_cache.cfg")
	http.connect("request_completed", self, "request", [], CONNECT_ONESHOT)
	var err = http.request("https://diamondstudiogames.github.io/apa2/promocodes.cfg")
	if err:
		set_message(tr("promocodes.fetch.error"), true)


func request(result, code, header, body):
	if result != HTTPRequest.RESULT_SUCCESS:
		set_message(tr("promocodes.fetch.error"), true)
		return
	set_message(tr("promocodes.fetch.check"))
	yield(get_tree(), "idle_frame")
	var cf = ConfigFile.new()
	var err = cf.load_encrypted_pass(OS.get_cache_dir().plus_file("online_promocodes_cache.cfg"), "apa2_online")
	var dir = Directory.new()
	dir.open(OS.get_cache_dir())
	dir.remove("online_promocodes_cache.cfg")
	if err:
		set_message(tr("promocodes.fetch.bad"), true)
		return
	if not cf.has_section(pending_promocode):
		set_message(tr("promocodes.fetch.no"), true)
		return
	if cf.has_section_key(pending_promocode, "only_for_ids"):
		if not G.getv("save_id", "none") in cf.get_value(pending_promocode, "only_for_ids", []):
			set_message(tr("promocodes.fetch.no"), true)
			return
	var reward = cf.get_value(pending_promocode, "reward", {})
	var comment = cf.get_value(pending_promocode, "comment", "")
	use_promocode(pending_promocode)
	G.receive_loot(reward)
	set_message(comment, true)


func set_message(mes, abort = false):
	if abort:
		set_comment(mes)
		$online.hide()
		return
	message.text = mes
