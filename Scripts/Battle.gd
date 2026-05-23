extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS
# =================================================================
@export_group("UI Positions")
@export var win_popup_custom_pos := Vector2(340, 200)

@export_subgroup("Speed Button Layout")
@export var speed_buttons_start_pos := Vector2(20, 20)
@export var gap_between_buttons := 130.0
# =================================================================

var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
@onready var win_popup = $WinPopup

@onready var player_sprite = $Hero # This is now your instantiated Hero scene node
@onready var enemy_sprite = $Foe

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")
@onready var audience_container = $AudienceContainer
@onready var result_label = $WinPopup/Panel/Label

var battle_over := false
var won := false
var player_turn_counter := 0
var enemy_turn_counter := 0

var player_base_pos := Vector2()
var enemy_base_pos := Vector2()

func _ready():
	# Configure layout positions for the speed controls
	create_speed_button("Pause", _pause_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 0, 0))
	create_speed_button("Slow", _slow_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 1, 0))
	create_speed_button("Normal", _normal_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 2, 0))
	create_speed_button("Fast", _fast_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 3, 0))
	
	# Grabs coordinates safely relative to parent transforms
	await get_tree().process_frame
	player_base_pos = player_sprite.position
	enemy_base_pos = enemy_sprite.position
	
	player_hp_bar = create_health_bar()
	enemy_hp_bar = create_health_bar()

	add_child(player_hp_bar)
	add_child(enemy_hp_bar)
	
	player_hp_bar.max_value = GameManager.max_player_hp
	enemy_hp_bar.max_value = GameManager.max_enemy_hp
	
	update_bars()
	setup_battle_timer()
	spawn_audience()

# ---------------------------------
# SPEED SYSTEM
# ---------------------------------
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

# ---------------------------------
# HEALTH BAR CREATION
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
func _process(_delta):
	if battle_over: return
	update_health_bar_positions()

func update_health_bar_positions():
	player_hp_bar.position = player_sprite.position + Vector2(-100, 60)
	enemy_hp_bar.position = enemy_sprite.position + Vector2(-100, 60)

# ---------------------------------
# TIMER
# ---------------------------------
func setup_battle_timer():
	var max_speed = max(GameManager.player_speed, GameManager.enemy_speed)
	if max_speed <= 0: max_speed = 1.0
	
	$Timer.wait_time = 1.0 / max_speed
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()

# ---------------------------------
# COMBAT LOOP
# ---------------------------------
func _on_timer_timeout():
	if battle_over: return

	player_turn_counter += 1
	enemy_turn_counter += 1

	# PLAYER attacks every enemy_speed ticks
	if player_turn_counter >= GameManager.enemy_speed:
		player_turn_counter = 0
		animate_attack(player_sprite, player_base_pos, Vector2(40, 0))
		GameManager.enemy_hp -= GameManager.player_damage
		print("PLAYER attacks for:", GameManager.player_damage)

	GameManager.enemy_hp = clamp(GameManager.enemy_hp, 0, GameManager.max_enemy_hp)
	if GameManager.enemy_hp <= 0:
		update_bars()
		check_game_state()
		return

	# ENEMY attacks every player_speed ticks
	if enemy_turn_counter >= GameManager.player_speed:
		enemy_turn_counter = 0
		animate_attack(enemy_sprite, enemy_base_pos, Vector2(-40, 0))
		
		var dmg = GameManager.enemy_dmg if "enemy_dmg" in GameManager else randi_range(5, 12)
		GameManager.player_hp -= dmg
		print("ENEMY attacks for:", dmg)

	GameManager.player_hp = clamp(GameManager.player_hp, 0, GameManager.max_player_hp)

	update_bars()
	check_game_state()

# ---------------------------------
# ATTACK ANIMATION
# ---------------------------------
func animate_attack(sprite, base_pos: Vector2, move_offset: Vector2):
	if sprite.has_meta("attack_tween"):
		var old_tween = sprite.get_meta("attack_tween")
		if old_tween and old_tween.is_valid():
			old_tween.kill()

	var tween = create_tween()
	sprite.set_meta("attack_tween", tween)

	var attack_pos = base_pos + move_offset

	tween.tween_property(sprite, "position", attack_pos, 0.12)
	tween.tween_property(sprite, "position", base_pos, 0.18)

# ---------------------------------
# UI / GAME OVER STATE
# ---------------------------------
func update_bars():
	player_hp_bar.value = GameManager.player_hp
	enemy_hp_bar.value = GameManager.enemy_hp

func check_game_state():
	if GameManager.enemy_hp <= 0:
		won = true
		battle_over = true
		show_win_popup()
	elif GameManager.player_hp <= 0:
		won = false
		battle_over = true
		show_win_popup()

func update_popup_text_scale():
	var panel_size = $WinPopup/Panel.size
	var scale_factor = panel_size.y / 300.0
	result_label.add_theme_font_size_override("font_size", int(48 * scale_factor))
	
func show_win_popup():
	result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	win_popup.global_position = win_popup_custom_pos
	
	$WinPopup/Panel.custom_minimum_size = Vector2(300, 300)
	$Timer.stop()
	Engine.time_scale = 1
	
	if not won:
		result_label.text = "YOU LOST"
	else:
		result_label.text = "YOU WON"
		
	win_popup.visible = true
	update_popup_text_scale()
	
func _on_continue_pressed():
	Engine.time_scale = 1
	if not won:
		get_tree().change_scene_to_file("res://Scenes/DeathScreen.tscn")
	else:
		get_tree().change_scene_to_file("res://Scenes/Map.tscn")
