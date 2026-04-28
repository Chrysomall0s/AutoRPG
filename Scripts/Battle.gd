extends Control

@onready var SpellData = preload("res://Scripts/SpellData.gd").new()
@onready var spell_bar = $SpellBar
var spell_buttons = []

var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
@onready var ui_anchor = $UIAnchor
@onready var win_popup = $WinPopup

@onready var player_sprite = $Hero
@onready var enemy_sprite = $Foe

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")
@onready var audience_container = $AudienceContainer
@onready var result_label = $WinPopup/Panel/Label
# ---------------------------------
# SPEED SYSTEM
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
		GameManager.enemy_hp -= spell["damage"]

	if spell.has("heal"):
		GameManager.player_hp += spell["heal"]
		GameManager.player_hp = min(GameManager.player_hp, GameManager.max_player_hp)

	update_bars()	
		
var won := false
var player_turn_counter := 0
var enemy_turn_counter := 0

var player_base_pos := Vector2()
var enemy_base_pos := Vector2()

var mana_bar: ProgressBar

func _ready():
	spawn_spells()
	create_speed_button("Pause", _pause_game, Vector2(20, 20))
	create_speed_button("Slow", _slow_game, Vector2(150, 20))
	create_speed_button("Normal", _normal_game, Vector2(280, 20))
	create_speed_button("Fast", _fast_game, Vector2(410, 20))
	
	player_base_pos = player_sprite.position
	enemy_base_pos = enemy_sprite.position
	
	player_hp_bar = create_health_bar()
	enemy_hp_bar = create_health_bar()

	add_child(player_hp_bar)
	add_child(enemy_hp_bar)

	mana_bar = create_health_bar()
	add_child(mana_bar)
	mana_bar.max_value = GameManager.player_mp
	mana_bar.value = GameManager.player_mp
	
	update_bars()
	setup_battle_timer()
	spawn_audience()

func create_speed_button(text: String, callback, pos: Vector2):
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(120, 40)

	btn.position = pos

	btn.pressed.connect(callback)

	add_child(btn)
	
func _pause_game():
	Engine.time_scale = 0.0

func _slow_game():
	Engine.time_scale = 0.5

func _normal_game():
	Engine.time_scale = 1.0

func _fast_game():
	Engine.time_scale = 2.0
			
func get_spawn_rect() -> Rect2:
	var shape = $AudienceZone/SpawnArea/CollisionShape2D.shape as RectangleShape2D

	# Area2D center in world space
	var center = $AudienceZone/SpawnArea/CollisionShape2D.global_position

	# rectangle size
	var size = shape.size

	# convert to top-left rect
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

			# stagger offset (half cell shift on odd rows)
			var offset_x = 0.0
			if y % 2 == 1:
				offset_x = spacing_x * 0.5

			audience.position = Vector2(
				rect.position.x + x * spacing_x + offset_x,
				rect.position.y + y * spacing_y
			)

			audience.set_filled(randf() < 0.7)

# ---------------------------------
# HEALTH BAR CREATION
# (no fixed position here anymore)
# ---------------------------------
func create_health_bar() -> ProgressBar:
	var bar := ProgressBar.new()

	bar.size = Vector2(200, 20)
	bar.min_value = 0
	bar.max_value = 100
	bar.value = 100

	return bar


# ---------------------------------
# UPDATE LOOP (UI follows sprites)
# ---------------------------------
func _process(delta):
	update_health_bar_positions()
	update_spell_buttons()

func update_health_bar_positions():
	# below player sprite
	player_hp_bar.position = player_sprite.position + Vector2(-100, 60)

	# below enemy sprite
	enemy_hp_bar.position = enemy_sprite.position + Vector2(-100, 60)


# ---------------------------------
# TIMER
# ---------------------------------
func setup_battle_timer():
	var max_speed = max(GameManager.player_speed, GameManager.enemy_speed)

	$Timer.wait_time = 1.0 / max_speed
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()


# ---------------------------------
# COMBAT LOOP
# ---------------------------------
func _on_timer_timeout():
	player_turn_counter += 1
	enemy_turn_counter += 1

	# PLAYER attacks every enemy_speed ticks
	if player_turn_counter >= GameManager.enemy_speed:
		player_turn_counter = 0

		animate_attack(player_sprite, player_base_pos, Vector2(40, 0))
		GameManager.enemy_hp -= GameManager.player_damage
		print("PLAYER attacks for:", GameManager.player_damage)

	# ENEMY attacks every player_speed ticks
	if enemy_turn_counter >= GameManager.player_speed:
		enemy_turn_counter = 0

		animate_attack(enemy_sprite, enemy_base_pos, Vector2(-40, 0))
		var enemy_damage = randi_range(5, 12)
		GameManager.player_hp -= enemy_damage

		print("ENEMY attacks for:", enemy_damage)

	GameManager.player_hp = clamp(GameManager.player_hp, 0, GameManager.max_player_hp)
	GameManager.enemy_hp = clamp(GameManager.enemy_hp, 0, GameManager.max_enemy_hp)

	update_bars()
	check_game_state()


# ---------------------------------
# ATTACK ANIMATION
# ---------------------------------
func animate_attack(sprite, base_pos: Vector2, move_offset: Vector2):
	# kill old tween on this sprite
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
# UI
# ---------------------------------
func update_bars():
	player_hp_bar.value = GameManager.player_hp
	enemy_hp_bar.value = GameManager.enemy_hp
	mana_bar.value = GameManager.player_mp

func check_game_state():
	if GameManager.enemy_hp <= 0:
		won = true
		show_win_popup()

	elif GameManager.player_hp <= 0:
		won = false
		show_win_popup()
func update_spell_buttons():
	if spell_bar == null:
		return
	for i in range(spell_bar.get_child_count()):
		var btn = spell_bar.get_child(i)
		var spell = SpellData.spells[i]

		btn.disabled = GameManager.player_mp < spell["cost"]		
#func update_spell_positions():
	#for i in range(spell_bar.get_child_count()):
		#var btn = spell_bar.get_child(i)
		#btn.position = Vector2(200 + i * 160, get_viewport_rect().size.y - 80)
		#
func update_popup_text_scale():
	var panel_size = $WinPopup/Panel.size

	# base font size scaling factor
	var scale_factor = panel_size.y / 300.0

	result_label.add_theme_font_size_override("font_size", int(48 * scale_factor))
	
func show_win_popup():
	# stop combat
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
		result_label.text = "YOU WON"
	win_popup.visible = true
	update_popup_text_scale()
	
func _on_continue_pressed():
	Engine.time_scale = 1
	if (!won):
		get_tree().change_scene_to_file("res://Scenes/DeathScreen.tscn")
	if (won):
		get_tree().change_scene_to_file("res://Scenes/Store.tscn")
	
