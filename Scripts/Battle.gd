extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS (RESOLUTION DYNAMIC)
# =================================================================
@export_group("UI Scaling Layouts")
@export var win_popup_width_ratio: float = 0.5   # 50% of the screen width
@export var win_popup_height_ratio: float = 0.3  # 30% of the screen height

@export_group("Speed Control Button Layout")
# Percentage scaling settings for control system alignment
@export var speed_buttons_x_offset_ratio: float = 0.06  # 3% margin from screen left edge
@export var speed_buttons_y_offset_ratio: float = 0.02  # 2% margin from screen top edge
@export var gap_between_buttons_ratio: float = 0.24   # Separation step size (18% of screen width)
@export var speed_button_width_ratio: float = 0.15     # Dynamic width (15% of screen width)
@export var speed_button_height_ratio: float = 0.07   # Dynamic height (3.5% of screen height)

@export_group("Audience Stadium Positioning")
# Coordinates are percentages of your screen size (0.0 to 1.0)
@export var audience_center_x_ratio: float = 0.5  # Centered horizontally (50% of screen)
@export var audience_center_y_ratio: float = 0.7  # Placed down in lower-middle half
@export var audience_width_ratio: float = 1.1     # Total crowd spans 110% of screen width
@export var audience_height_ratio: float = 0.4    # Total crowd spans 40% of screen height

@export_subgroup("Audience Grid Details")
@export var audience_columns: int = 11
@export var audience_rows: int = 6
@export var original_sprite_width: float = 44.0   # Base width pixel size of your asset texture
@export var original_sprite_height: float = 44.0  # Base height pixel size of your asset texture
# =================================================================

var player_hp_bar: ProgressBar
var enemy_hp_bar: ProgressBar
@onready var win_popup = $WinPopup

@onready var player_sprite = $Hero 
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
	var screen_size = get_viewport_rect().size
	print("Initializing Battle Scene at Resolution: ", screen_size.x, "x", screen_size.y)
	
	# --- CALCULATE SPEED BUTTON POSITIONS VIA EXPORT RATIOS ---
	var speed_buttons_start_pos = Vector2(
		screen_size.x * speed_buttons_x_offset_ratio, 
		screen_size.y * speed_buttons_y_offset_ratio
	)
	var gap_between_buttons = screen_size.x * gap_between_buttons_ratio
	
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
	
	# Dynamic sizing hooks matching the clean inspector configuration
	var screen_size = get_viewport_rect().size
	btn.custom_minimum_size = Vector2(
		screen_size.x * speed_button_width_ratio, 
		screen_size.y * speed_button_height_ratio
	) 
	
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

# ---------------------------------
# MATHEMATICAL AUDIENCE SPINNER
# ---------------------------------
func spawn_audience():
	randomize()
	
	var screen_size = get_viewport_rect().size
	
	var zone_size = Vector2(
		screen_size.x * audience_width_ratio,
		screen_size.y * audience_height_ratio
	)
	var zone_center = Vector2(
		screen_size.x * audience_center_x_ratio,
		screen_size.y * audience_center_y_ratio
	)
	var zone_top_left = zone_center - (zone_size / 2.0)
	
	var spacing_x = zone_size.x / audience_columns
	var spacing_y = zone_size.y / audience_rows

	var scale_x = (spacing_x / original_sprite_width) * 0.9
	var scale_y = (spacing_y / original_sprite_height) * 0.9
	var uniform_scale = min(scale_x, scale_y)

	for y in range(audience_rows):
		for x in range(audience_columns):
			var audience = AudienceScene.instantiate()
			audience_container.add_child(audience)
			
			audience.scale = Vector2(uniform_scale, uniform_scale)

			var offset_x = 0.0
			if y % 2 == 1:
				offset_x = spacing_x * 0.5

			audience.position = Vector2(
				zone_top_left.x + (x * spacing_x) + offset_x,
				zone_top_left.y + (y * spacing_y)
			)

			audience.set_filled(randf() < 0.7)

# ---------------------------------
# HEALTH BAR CREATION
# ---------------------------------
func create_health_bar() -> ProgressBar:
	var screen_size = get_viewport_rect().size
	var bar := ProgressBar.new()
	bar.size = Vector2(screen_size.x * 0.27, screen_size.y * 0.016) 
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
	var offset_x = player_hp_bar.size.x / 2.0
	var offset_y = get_viewport_rect().size.y * 0.05
	
	player_hp_bar.position = player_sprite.position + Vector2(-offset_x, offset_y)
	enemy_hp_bar.position = enemy_sprite.position + Vector2(-offset_x, offset_y)

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
	
	var screen_size = get_viewport_rect().size
	var horizontal_dash_distance = screen_size.x * 0.055 

	if player_turn_counter >= GameManager.enemy_speed:
		player_turn_counter = 0
		animate_attack(player_sprite, player_base_pos, Vector2(horizontal_dash_distance, 0))
		GameManager.enemy_hp -= GameManager.player_damage
		print("PLAYER attacks for:", GameManager.player_damage)

	GameManager.enemy_hp = clamp(GameManager.enemy_hp, 0, GameManager.max_enemy_hp)
	if GameManager.enemy_hp <= 0:
		update_bars()
		check_game_state()
		return

	if enemy_turn_counter >= GameManager.player_speed:
		enemy_turn_counter = 0
		animate_attack(enemy_sprite, enemy_base_pos, Vector2(-horizontal_dash_distance, 0))
		
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
	var screen_size = get_viewport_rect().size
	
	result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	var dynamic_panel_size = Vector2(
		screen_size.x * win_popup_width_ratio,
		screen_size.y * win_popup_height_ratio
	)
	$WinPopup/Panel.custom_minimum_size = dynamic_panel_size
	$WinPopup/Panel.size = dynamic_panel_size
	
	var center_pos = (screen_size - dynamic_panel_size) / 2.0
	win_popup.global_position = center_pos
	
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
