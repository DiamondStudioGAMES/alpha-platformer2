extends Player
class_name Death


var is_active_gadget = false
var another_attack = false
var _attack = load("res://prefabs/classes/death_attack.tscn")
var THEWORLD = load("res://prefabs/effects/THEWORLD.tscn")
var ORA = load("res://prefabs/classes/ORA.tscn")
var curr_lvl_loc = 1
onready var trail = $trail
onready var eye = $visual/body/head/helmet/eye


func _ready():
	curr_lvl_loc = int(get_tree().current_scene.name.trim_prefix("level_").split("_")[0])
	have_gadget = true
	max_health = curr_lvl_loc * 25 + 250
	defense = curr_lvl_loc + 15
	$ulti.damage = 125 + curr_lvl_loc * 15
	current_health = max_health
	_health_bar.max_value = max_health
	_health_change_bar.max_value = max_health
	_update_bars()
	$camera/gui/base/ulti_use/ulti_name.text = tr("ulti.death")
	RECHARGE_SPEED = 0.7
	if MP.auth(self):
		$control_indicator/sp.show()
	eye.modulate = eye.self_modulate
	eye.self_modulate = Color.white
	class_nam = "death"
	hate_level = 0


func send_my_data():
	ms.sync_call(self, "apply_eye_color", [eye.modulate])
	.send_my_data()


func apply_data(data):
	.apply_data(data)
	max_health = curr_lvl_loc * 25 + 250
	defense = curr_lvl_loc + 15
	current_health = max_health
	RECHARGE_SPEED = 0.1
	_health_bar.max_value = max_health
	_health_change_bar.max_value = max_health
	_update_bars()


func apply_eye_color(clr):
	eye.modulate = clr
	eye.self_modulate = Color.white


func attack():
	if MP.auth(self):
		G.ach.complete(Achievements.DARK_CREATION)
	if is_hurt or is_stunned or _is_drinking or not can_control:
		return
	if not can_attack:
		_attack_empty_anim.play("empty")
		return
	if another_attack:
		oraoraora()
		return
	ms.sync_call(self, "attack")
	can_attack = false
	_is_attacking = true
	attack_cooldown = RECHARGE_SPEED + 0.35
	_anim_tree["parameters/attack_seek/seek_position"] = 0
	_anim_tree["parameters/attack_shot/active"] = true
	yield(get_tree().create_timer(0.35), "timeout")
	if MP.auth(self):
		var node = _attack.instance()
		node.global_position = global_position
		node.scale.x = _body.scale.x
		node.scale.y = GRAVITY_SCALE
		node.damage = 85 + curr_lvl_loc * 8
		if randi() % 10 == 2:
			node.damage *= 3
			node.modulate = Color.black
		_level.add_child(node, true)
	_is_attacking = false


func oraoraora():
	ms.sync_call(self, "oraoraora")
	_is_attacking = true
	can_attack = false
	attack_cooldown = RECHARGE_SPEED
	_anim_tree["parameters/ora_seek/seek_position"] = 0
	_anim_tree["parameters/ora_shot/active"] = true
	for _i in range(3):
		if not MP.auth(self):
			continue
		yield(get_tree().create_timer(0.2), "timeout")
		var node = ORA.instance()
		var offset = Vector2(randi()%13-6, randi()%20-10)
		offset.x *= _body.scale.x
		if _body.scale.x < 0:
			node.rotation_degrees = 180
		node.global_position = global_position + offset
		node.get_node("attack").damage = 30 + curr_lvl_loc * 3
		_level.add_child(node, true)
	_is_attacking = false


func ulti():
	if ulti_percentage < 100 or is_stunned or is_hurt or _is_drinking or is_active_gadget or not can_control:
		return
	ms.sync_call(self, "ulti")
	$skill_use_sfx.play()
	ulti_percentage = 0
	_health_timer = 0
	_is_ultiing = true
	immune_counter += 1
	_ulti_tween.interpolate_property(_ulti_bar, "value", 100, 0, 0.5)
	_ulti_tween.start()
	_anim_tree["parameters/ulti_shot/active"] = true
	$camera/gui/base/ulti_use/anim.play("ulti_use")
	if MP.auth(self):
		G.addv("ulti_used", 1)
		G.ach.check(Achievements.SKILL)
	yield(get_tree().create_timer(0.8, false), "timeout")
	can_see = false
	$visual.modulate = Color(1, 1, 1, 0.25)
	collision_layer = 0b0
	collision_mask = 0b11001
	trail.points.clear()
	trail.show()
	$gadget_active.emitting = true
	var shape_owner = $ulti.shape_find_owner(0)
	$ulti.shape_owner_set_disabled(shape_owner, false)
	SPEED = 185
	JUMP_POWER = 280
	yield(get_tree().create_timer(3, false), "timeout")
	SPEED = 92
	JUMP_POWER = 255
	$visual.modulate = Color.white
	trail.hide()
	collision_layer = 0b10
	collision_mask = 0b11101
	can_see = true
	$gadget_active.emitting = false
	$ulti.shape_owner_set_disabled(shape_owner, true)
	_is_ultiing = false
	immune_counter -= 1


func _process(delta):
	if is_active_gadget:
		if not get_tree().paused:
			get_tree().paused = true
		gadget_cooldown = 10
	if not MP.auth(self):
		return
	if Input.is_action_just_pressed("attack1"):
		attack()
	if Input.is_action_just_pressed("ulti"):
		ulti()
	if Input.is_action_just_pressed("gadget"):
		use_gadget()


func revive(hpc = -1):
	_anim_tree["parameters/ora_shot/active"] = false
	.revive(hpc)


func use_gadget():
	if _is_ultiing:
		return false
	var success = .use_gadget()
	if not success:
		return
	var effect = THEWORLD.instance()
	add_child(effect)
	_camera_tween.interpolate_property($visual/body/arm_right/hand/weapon, "self_modulate", Color.white, Color(1,1,1,0), 0.5)
	_camera_tween.start()
	yield(get_tree().create_timer(0.5, false), "timeout")
	another_attack = true
	pause_mode = PAUSE_MODE_PROCESS
	var time_scale = Engine.time_scale
	get_tree().paused = true
	Physics2DServer.set_active(true)
	VisualServer.set_shader_time_scale(0)
	Engine.time_scale = 1
	is_active_gadget = true
	_knockback = 0
	is_hurt = false
	stun_time = 0
	immune_counter += 1
	yield(get_tree().create_timer(0.5), "timeout")
	var time_to_stop = 4 + floor(curr_lvl_loc / 2.0)
	if G.current_level == "10_10":
		time_to_stop = 5
	yield(get_tree().create_timer(time_to_stop / time_scale), "timeout")
	effect.get_node("anim").play("ZERO")
	yield(get_tree().create_timer(0.5), "timeout")
	pause_mode = PAUSE_MODE_INHERIT
	get_tree().paused = false
	is_active_gadget = false
	immune_counter -= 1
	VisualServer.set_shader_time_scale(1)
	Engine.time_scale = time_scale
	_camera_tween.interpolate_property($visual/body/arm_right/hand/weapon, "self_modulate", Color(1,1,1,0), Color(1,1,1,1), 0.5)
	_camera_tween.start()
	another_attack = false


func calculate_fall_damage():
	if _is_ultiing:
		return
	.calculate_fall_damage()
