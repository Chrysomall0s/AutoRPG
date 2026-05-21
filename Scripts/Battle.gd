extends Control

@onready var SpellData = preload("res://Scripts/SpellData.gd").new()
@onready var spell_bar = $SpellBar
var spell_buttons = []

var player_hp_bar: ProgressBar
var mana_bar: ProgressBar
@onready var ui_anchor = $UIAnchor
@onready var win_popup = $WinPopup

@onready var player_sprite = $Hero
@onready var enemy_sprite = $Foe # Used as a template for the horde

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")
@onready var audience_container = $AudienceContainer
@onready var result_label = $WinPopup/Panel/Label

# ---------------------------------
# HORDE SYSTEM & TARGETING
# ---------------------------------
enum TargetMode { FIRST, WEAKEST, STRONGEST }
var current_target_mode: TargetMode = TargetMode.FIRST

var active_enemies: Array = []
var round_time_left: float = 20.0
var spawn_timer: float = 0.0

var round_timer_label: Label

var won := false
var player_turn_counter := 0
var player_base_pos := Vector2()
var enemy_base_pos := Vector2()

# ---------------------------------
# SPELL SYSTEM
# ---------------------------------
func spawn_spells():
	for child in spell_bar.get_children():
		child.queue_free()

	spell_buttons.clear()

	for i in range(3):
		var spell = SpellData.spells[i]

		var btn = Button.new()
		btn.text = spell["name"] + " (" + str(spell["cost"]) + ")"
		btn.custom_minimum_size = Vector2(150, 50)

		btn.pressed.connect(func():
			cast_spell(spell)
		)

		btn.position = Vector2(200 + i * 160, 0)

		spell_bar.add_child(btn)
		spell_buttons.append(btn)
		
func cast_spell(spell):
	if GameManager.player_mp < spell["cost"]:
		print("Not enough mana!")
		return

	GameManager.player_mp -= spell["cost"]

	if spell.has("damage"):
		var target = get_target()
		if target != null:
			target["hp"] -= spell["damage"]
			if target["hp"] <= 0:
				kill_enemy(target)

	if spell.has("heal"):
		GameManager.player_hp += spell["heal"]
		GameManager.player_hp = min(GameManager.player_hp, GameManager.max_player_hp)

	update_bars()    
		
func load_upgrade_sprites():
	var layers = $Hero/UpgradeLayers

	# 1. Clear old sprites
	for child in layers.get_children():
		child.queue_free()

	# 2. Rebuild general owned upgrades
	for upgrade in GameManager.owned_upgrades:
		if not upgrade or not upgrade.has("icon"):
			continue

		var sprite = Sprite2D.new()
		sprite.texture = load(upgrade["icon"])
		sprite.name = upgrade["name"]

		if upgrade.has("layer"):
			sprite.z_index = upgrade["layer"]

		layers.add_child(sprite)
	
	# 3. Rebuild equipped slots
	for slot_name in GameManager.equipped_slots:
			
		var upgrade = GameManager.equipped_slots[slot_name]

		if not upgrade or not upgrade.has("icon"):
			continue

		var sprite = Sprite2D.new()
		var icon_suffix = upgrade["icon"]
		
		match slot_name:
			"Left":
				icon_suffix += "/L.png"
			"Middle":
				icon_suffix += "/M.png"
			"Right":
				icon_suffix += "/R.png"
				
		sprite.texture = load(icon_suffix)
		sprite.name = upgrade["name"]

		if upgrade.has("layer"):
			sprite.z_index = upgrade["layer"]

		layers.add_child(sprite)

func _ready():
	load_upgrade_sprites()
	spawn_spells()
	
	# Speed Buttons
	create_speed_button("Pause", _pause_game, Vector2(20, 20))
	create_speed_button("Slow", _slow_game, Vector2(150, 20))
	create_speed_button("Normal", _normal_game, Vector2(280, 20))
	create_speed_button("Fast", _fast_game, Vector2(410, 20))
	
	# Target Buttons (Placed below speed buttons)
	create_target_button("First", TargetMode.FIRST, Vector2(20, 70))
	create_target_button("Weakest", TargetMode.WEAKEST, Vector2(150, 70))
	create_target_button("Strongest", TargetMode.STRONGEST, Vector2(280, 70))
	
	# Round Timer UI
	round_timer_label = Label.new()
	round_timer_label.position = Vector2(get_viewport_rect().size.x / 2.0 - 50, 20)
	round_timer_label.add_theme_font_size_override("font_size", 32)
	add_child(round_timer_label)
	
	player_base_pos = player_sprite.position
	enemy_base_pos = enemy_sprite.position
	enemy_sprite.hide() # Hide the template
	
	player_hp_bar = create_health_bar()
	add_child(player_hp_bar)

	mana_bar = create_health_bar()
	add_child(mana_bar)
	mana_bar.max_value = GameManager.player_mp
	mana_bar.value = GameManager.player_mp
	
	update_bars()
	setup_battle_timer()
	spawn_audience()

# ---------------------------------
# BUTTON CREATION
# ---------------------------------
func create_speed_button(text: String, callback, pos: Vector2):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 40)
	btn.position = pos
	btn.pressed.connect(callback)
	add_child(btn)

func create_target_button(text: String, mode: TargetMode, pos: Vector2):
	var btn = Button.new()
	btn.text = "Target: " + text
	btn.custom_minimum_size = Vector2(120, 40)
	btn.position = pos
	btn.pressed.connect(func():
		current_target_mode = mode
	)
	add_child(btn)
	
func _pause_game():
	Engine.time_scale = 0.0

func _slow_game():
	Engine.time_scale = 0.5

func _normal_game():
	Engine.time_scale = 1.0

func _fast_game():
	Engine.time_scale = 2.0
			
# ---------------------------------
# AUDIENCE
# ---------------------------------
func get_spawn_rect() -> Rect2:
	var shape = $AudienceZone/SpawnArea/CollisionShape2D.shape as RectangleShape2D
	var center = $AudienceZone/SpawnArea/CollisionShape2D.global_position
	var size = shape.size
	var top_left = center - size / 2
	return Rect2(top_left, size)

func spawn_audience():
	randomize()

	var cols = 11
	var rows = 6

	var rect = get_spawn_rect()
	var spacing_x = rect.size.x / cols
	var spacing_y = rect.size.y / rows

	for y in range(rows):
		for x in range(cols):
			var audience = AudienceScene.instantiate()
			audience_container.add_child(audience)

			var offset_x = 0.0
			if y % 2 == 1:
				offset_x = spacing_x * 0.5

			audience.position = Vector2(
				rect.position.x + x * spacing_x + offset_x,
				rect.position.y + y * spacing_y
			)

			audience.set_filled(randf() < 0.7)

func create_health_bar() -> ProgressBar:
	var bar := ProgressBar.new()
	bar.size = Vector2(200, 20)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100
	return bar

# ---------------------------------
# PROCESS & HORDE MANAGEMENT
# ---------------------------------
func _process(delta):
	if won or GameManager.player_hp <= 0:
		return
		
	# Process Round Timer
	var time_passed = delta * Engine.time_scale
	round_time_left -= time_passed
	round_timer_label.text = "Time Left: " + str(ceil(round_time_left)) + "s"
	
	if round_time_left <= 0:
		won = true
		show_win_popup()
		return
		
	# Process Spawning
	spawn_timer -= time_passed
	if spawn_timer <= 0:
		spawn_timer = 2.0
		spawn_new_monster()

	update_health_bar_positions()
	update_spell_buttons()

func spawn_new_monster():
	var new_sprite = enemy_sprite.duplicate()
	new_sprite.show()
	add_child(new_sprite)
	
	var new_bar = create_health_bar()
	new_bar.max_value = GameManager.max_enemy_hp
	new_bar.value = GameManager.max_enemy_hp
	add_child(new_bar)
	
	# Spread them out slightly around the base position so they don't overlap entirely
	var spawn_offset = Vector2(randf_range(0, 150), randf_range(-60, 60))
	var start_pos = enemy_base_pos + spawn_offset
	new_sprite.position = start_pos
	
	var enemy_data = {
		"sprite": new_sprite,
		"hp_bar": new_bar,
		"hp": GameManager.max_enemy_hp,
		"turn_counter": 0,
		"base_pos": start_pos
	}
	
	active_enemies.append(enemy_data)

func kill_enemy(enemy_data):
	if is_instance_valid(enemy_data["sprite"]):
		enemy_data["sprite"].queue_free()
	if is_instance_valid(enemy_data["hp_bar"]):
		enemy_data["hp_bar"].queue_free()
	active_enemies.erase(enemy_data)

func get_target():
	if active_enemies.is_empty():
		return null
		
	var best_target = null
	
	match current_target_mode:
		TargetMode.FIRST:
			best_target = active_enemies[0]
		TargetMode.WEAKEST:
			best_target = active_enemies[0]
			for e in active_enemies:
				if e["hp"] < best_target["hp"]:
					best_target = e
		TargetMode.STRONGEST:
			best_target = active_enemies[0]
			for e in active_enemies:
				if e["hp"] > best_target["hp"]:
					best_target = e
					
	return best_target

func update_health_bar_positions():
	# Player
	player_hp_bar.position = player_sprite.position + Vector2(-100, 60)
	
	# Enemies
	for e in active_enemies:
		if is_instance_valid(e["hp_bar"]) and is_instance_valid(e["sprite"]):
			e["hp_bar"].position = e["sprite"].position + Vector2(-100, 60)
			e["hp_bar"].value = e["hp"]

# ---------------------------------
# COMBAT LOOP & TIMERS
# ---------------------------------
func setup_battle_timer():
	var max_speed = max(GameManager.player_speed, GameManager.enemy_speed)
	$Timer.wait_time = 1.0 / max_speed
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()

func _on_timer_timeout():
	if won or GameManager.player_hp <= 0:
		return
		
	player_turn_counter += 1

	# PLAYER ATTACK
	if player_turn_counter >= GameManager.enemy_speed:
		player_turn_counter = 0
		var target = get_target()
		
		if target != null:
			animate_attack(player_sprite, player_base_pos, Vector2(40, 0))
			target["hp"] -= GameManager.player_damage
			GameManager.gold += 1
			print("PLAYER attacks for:", GameManager.player_damage)
			
			if target["hp"] <= 0:
				kill_enemy(target)

	# ENEMIES ATTACK
	for enemy in active_enemies:
		enemy["turn_counter"] += 1
		if enemy["turn_counter"] >= GameManager.player_speed:
			enemy["turn_counter"] = 0
			
			animate_attack(enemy["sprite"], enemy["base_pos"], Vector2(-40, 0))
			var enemy_damage = GameManager.enemy_dmg
			GameManager.player_hp -= enemy_damage
			print("ENEMY attacks for:", enemy_damage)

	GameManager.player_hp = clamp(GameManager.player_hp, 0, GameManager.max_player_hp)
	update_bars()
	check_game_state()

func animate_attack(sprite, base_pos: Vector2, move_offset: Vector2):
	if not is_instance_valid(sprite):
		return
		
	if sprite.has_meta("attack_tween"):
		var old_tween = sprite.get_meta("attack_tween")
		if old_tween:
			old_tween.kill()

	var tween = create_tween()
	sprite.set_meta("attack_tween", tween)

	var attack_pos = base_pos + move_offset

	tween.tween_property(sprite, "position", attack_pos, 0.12)
	tween.tween_property(sprite, "position", base_pos, 0.18)

# ---------------------------------
# UI & GAME STATE
# ---------------------------------
func update_bars():
	player_hp_bar.value = GameManager.player_hp
	mana_bar.value = GameManager.player_mp

func check_game_state():
	# Note: Win check is now handled by the round timer in _process
	if GameManager.player_hp <= 0:
		won = false
		show_win_popup()

func update_spell_buttons():
	if spell_bar == null:
		return
	for i in range(spell_bar.get_child_count()):
		var btn = spell_bar.get_child(i)
		var spell = SpellData.spells[i]
		btn.disabled = GameManager.player_mp < spell["cost"]        
		
func update_popup_text_scale():
	var panel_size = $WinPopup/Panel.size
	var scale_factor = panel_size.y / 300.0
	result_label.add_theme_font_size_override("font_size", int(48 * scale_factor))
	
func show_win_popup():
	result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	win_popup.global_position = ui_anchor.global_position
	$WinPopup/Panel.custom_minimum_size = Vector2(300, 300)
	$Timer.stop()
	Engine.time_scale = 1
	
	if (!won):
		result_label.text = "YOU LOST"
	if (won):
		result_label.text = "SURVIVED"
		
	win_popup.visible = true
	update_popup_text_scale()
	
func _on_continue_pressed():
	Engine.time_scale = 1
	if (!won):
		get_tree().change_scene_to_file("res://Scenes/DeathScreen.tscn")
	if (won):
		get_tree().change_scene_to_file("res://Scenes/Store.tscn")
