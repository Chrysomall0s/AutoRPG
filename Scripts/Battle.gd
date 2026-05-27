extends Control

# =================================================================
# GAME CONFIGURATION SETTINGS
# =================================================================
@export_group("Floating Rainbow Weapons Settings")
@export var rainbow_radius_x: float = 150.0
@export var rainbow_offset := Vector2(-150, -80)
@export var rainbow_radius_y: float = 150.0
@export var rainbow_y_offset: float = 45.0
@export var global_weapon_tick_delay: float = 0.45
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5

@export_group("Animation Speed Overrides")
@export var weapon_strike_duration: float = 0.28
@export var weapon_return_duration: float = 0.35
@export var weapon_follow_smoothness: float = 8.0

@export_group("UI Scaling Layouts")
@export var win_popup_width_ratio: float = 0.5   
@export var win_popup_height_ratio: float = 0.3  

@export_group("Speed Control Button Layout")
@export var speed_buttons_x_offset_ratio: float = 0.06  
@export var speed_buttons_y_offset_ratio: float = 0.02  
@export var gap_between_buttons_ratio: float = 0.24   
@export var speed_button_width_ratio: float = 0.15       
@export var speed_button_height_ratio: float = 0.07   

@export_group("Audience Stadium Positioning")
@export var audience_center_x_ratio: float = 0.5  
@export var audience_center_y_ratio: float = 0.7  
@export var audience_width_ratio: float = 1.1     
@export var audience_height_ratio: float = 0.4    

@export_subgroup("Audience Grid Details")
@export var audience_columns: int = 11
@export var audience_rows: int = 6
@export var original_sprite_width: float = 44.0   
@export var original_sprite_height: float = 44.0  

@export_group("Visual Gold Drop Engine")
@export var coin_texture_path: String = "res://icon.svg" 
@export var coin_scale: Vector2 = Vector2(0.15, 0.15)
@export var total_animated_coins: int = 12

@export_group("Escape Settings")
@export var flee_button_unlock_time: float = 10.0
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
var enemy_turn_counter := 0
var player_base_pos := Vector2()
var enemy_base_pos := Vector2()
var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0
var hud_gold_label: Label = null
var current_displayed_gold: int = 0
var escape_sequence_triggered := false

var timer_elapsed: float = 0.0
var hud_timer_label: Label = null
var flee_btn_created := false

func _ready():
	var screen_size = get_viewport_rect().size
	current_displayed_gold = GameManager.gold
	setup_gold_hud_display()
	setup_countdown_timer_hud()
	
	var speed_buttons_start_pos = Vector2(screen_size.x * speed_buttons_x_offset_ratio, screen_size.y * speed_buttons_y_offset_ratio)
	var gap_between_buttons = screen_size.x * gap_between_buttons_ratio
	create_speed_button("Pause", _pause_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 0, 0))
	create_speed_button("Slow", _slow_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 1, 0))
	create_speed_button("Normal", _normal_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 2, 0))
	create_speed_button("Fast", _fast_game, speed_buttons_start_pos + Vector2(gap_between_buttons * 3, 0))
	
	await get_tree().process_frame
	player_base_pos = player_sprite.position
	enemy_base_pos = enemy_sprite.position
	
	if GameManager.current_enemy_profile.has("icon"):
		var enemy_texture_path = GameManager.current_enemy_profile["icon"]
		if ResourceLoader.exists(enemy_texture_path): enemy_sprite.texture = load(enemy_texture_path)
	
	player_hp_bar = create_health_bar()
	enemy_hp_bar = create_health_bar()
	add_child(player_hp_bar)
	add_child(enemy_hp_bar)
	player_hp_bar.max_value = GameManager.max_player_hp
	enemy_hp_bar.max_value = GameManager.max_enemy_hp
	
	update_bars()
	setup_battle_timer()
	spawn_audience()
	spawn_floating_weapons()

func _process(delta):
	if battle_over: return
	
	if timer_elapsed < flee_button_unlock_time:
		timer_elapsed += delta * Engine.time_scale
		hud_timer_label.text = str(int(flee_button_unlock_time - timer_elapsed))
		if timer_elapsed >= flee_button_unlock_time:
			replace_timer_with_flee_button()
			
	update_health_bar_positions()
	update_weapon_positions(delta)

func replace_timer_with_flee_button():
	if flee_btn_created: return
	flee_btn_created = true
	hud_timer_label.visible = false
	
	var btn = Button.new()
	btn.text = "Flee"
	btn.custom_minimum_size = Vector2(120, 50)
	btn.anchor_left = 0.5
	btn.anchor_right = 0.5
	btn.anchor_top = 0.0
	btn.anchor_bottom = 0.0
	btn.position = Vector2(-60, get_viewport_rect().size.y * 0.02)
	
	btn.pressed.connect(func():
		escape_sequence_triggered = true
		check_game_state()
	)
	add_child(btn)

func check_game_state():
	if escape_sequence_triggered and not battle_over:
		won = true
		GameManager.escaped = true
		battle_over = true
		$Timer.stop()
		show_win_popup()
		return

	if GameManager.enemy_hp <= 0:
		won = true
		battle_over = true
		$Timer.stop()
		if not GameManager.cleared_tiles.has(GameManager.current_tile_id): GameManager.cleared_tiles.append(GameManager.current_tile_id)
		GameManager.persistent_tile_assignments[GameManager.current_tile_id] = 0
		var gold_reward = randi_range(15, 30) + (GameManager.selected_difficulty * 10)
		if "current_floor" in GameManager: gold_reward += (GameManager.current_floor * 5)
		GameManager.gold += gold_reward
		execute_visual_gold_drop(gold_reward)
		await get_tree().create_timer(1.2).timeout
		show_win_popup()
	elif GameManager.player_hp <= 0:
		won = false
		battle_over = true
		$Timer.stop()
		show_win_popup()

# --- HELPER FUNCTIONS ---

func setup_gold_hud_display():
	var screen_size = get_viewport_rect().size
	hud_gold_label = Label.new()
	hud_gold_label.text = "Gold: " + str(current_displayed_gold)
	hud_gold_label.position = Vector2(screen_size.x * 0.04, screen_size.y * 0.11)
	hud_gold_label.add_theme_font_size_override("font_size", int(screen_size.y * 0.028))
	add_child(hud_gold_label)

func setup_countdown_timer_hud():
	var screen_size = get_viewport_rect().size
	hud_timer_label = Label.new()
	hud_timer_label.text = str(int(flee_button_unlock_time))
	hud_timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hud_timer_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	hud_timer_label.add_theme_font_size_override("font_size", int(screen_size.y * 0.045))
	hud_timer_label.position.y = screen_size.y * 0.02
	add_child(hud_timer_label)

func spawn_floating_weapons():
	weapon_sprites.clear()
	for i in range(GameManager.equipped_weapons.size()):
		var weapon_data = GameManager.equipped_weapons[i]
		if weapon_data == null or typeof(weapon_data) != TYPE_DICTIONARY: continue
		var weapon = Sprite2D.new()
		weapon.texture = load(weapon_data.get("icon", "res://icon.svg"))
		weapon.scale = Vector2(0.3, 0.3) 
		add_child(weapon)
		weapon.set_meta("weapon_type", weapon_data.get("type", "damage"))
		weapon.set_meta("damage", weapon_data.get("damage", 0))
		weapon.set_meta("heal_value", weapon_data.get("heal_value", 0))
		weapon.set_meta("speed_threshold", weapon_data.get("speed", 3))
		weapon.set_meta("tick_counter", 0) 
		weapon.set_meta("slot_index", i)
		weapon.name = weapon_data.get("name", "Weapon")
		weapon_sprites.append(weapon)
	update_weapon_positions(0.0)

func update_weapon_positions(delta: float):
	floating_time += delta
	for i in range(weapon_sprites.size()):
		var weapon = weapon_sprites[i]
		if weapon.has_meta("is_attacking") and weapon.get_meta("is_attacking") == true: continue
		var slot_idx = weapon.get_meta("slot_index")
		var angle = float(slot_idx) * (PI / 5.0)
		var float_offset = sin(floating_time * float_wave_speed + slot_idx) * float_amplitude
		var target_pos = player_sprite.position + rainbow_offset + Vector2(-cos(angle) * rainbow_radius_x, -sin(angle) * rainbow_radius_y + rainbow_y_offset + float_offset)
		if delta == 0.0: weapon.position = target_pos
		else: weapon.position = weapon.position.lerp(target_pos, (delta / (Engine.time_scale if Engine.time_scale > 0.0 else 1.0)) * weapon_follow_smoothness)

func create_speed_button(text: String, callback, pos: Vector2):
	var btn = Button.new()
	btn.text = text
	var screen_size = get_viewport_rect().size
	btn.custom_minimum_size = Vector2(screen_size.x * speed_button_width_ratio, screen_size.y * speed_button_height_ratio) 
	btn.position = pos
	btn.pressed.connect(callback)
	add_child(btn)
	
func _pause_game(): Engine.time_scale = 0.0
func _slow_game(): Engine.time_scale = 0.5
func _normal_game(): Engine.time_scale = 1.0
func _fast_game(): Engine.time_scale = 2.0

func spawn_audience():
	randomize()
	var screen_size = get_viewport_rect().size
	var zone_size = Vector2(screen_size.x * audience_width_ratio, screen_size.y * audience_height_ratio)
	var zone_center = Vector2(screen_size.x * audience_center_x_ratio, screen_size.y * audience_center_y_ratio)
	var zone_top_left = zone_center - (zone_size / 2.0)
	var spacing_x = zone_size.x / audience_columns
	var spacing_y = zone_size.y / audience_rows
	var uniform_scale = min((spacing_x / original_sprite_width) * 0.9, (spacing_y / original_sprite_height) * 0.9)
	for y in range(audience_rows):
		for x in range(audience_columns):
			var audience = AudienceScene.instantiate()
			audience_container.add_child(audience)
			audience.scale = Vector2(uniform_scale, uniform_scale)
			audience.position = zone_top_left + Vector2((x * spacing_x) + (spacing_x * 0.5 if y % 2 == 1 else 0.0), y * spacing_y)
			audience.set_filled(randf() < 0.7)

func create_health_bar() -> ProgressBar:
	var screen_size = get_viewport_rect().size
	var bar := ProgressBar.new()
	bar.size = Vector2(screen_size.x * 0.27, screen_size.y * 0.016) 
	return bar

func update_health_bar_positions():
	var offset_x = player_hp_bar.size.x / 2.0
	var offset_y = get_viewport_rect().size.y * 0.05 + rainbow_y_offset
	player_hp_bar.position = player_sprite.position + Vector2(-offset_x, offset_y)
	enemy_hp_bar.position = enemy_sprite.position + Vector2(-offset_x, get_viewport_rect().size.y * 0.05)

func setup_battle_timer():
	$Timer.wait_time = global_weapon_tick_delay 
	$Timer.timeout.connect(_on_timer_timeout)
	$Timer.start()

func _on_timer_timeout():
	if battle_over: return
	enemy_turn_counter += 1
	var horizontal_dash_distance = get_viewport_rect().size.x * 0.055 
	for weapon in weapon_sprites:
		if not is_instance_valid(weapon): continue
		var current_ticks = weapon.get_meta("tick_counter") + 1
		if current_ticks >= weapon.get_meta("speed_threshold"):
			weapon.set_meta("tick_counter", 0)
			execute_single_weapon_strike(weapon, weapon.get_meta("weapon_type"))
			if weapon.get_meta("weapon_type") == "heal":
				GameManager.player_hp = clamp(GameManager.player_hp + weapon.get_meta("heal_value"), 0, GameManager.max_player_hp)
			else:
				GameManager.enemy_hp -= weapon.get_meta("damage")
		else: weapon.set_meta("tick_counter", current_ticks)
	GameManager.enemy_hp = clamp(GameManager.enemy_hp, 0, GameManager.max_enemy_hp)
	if enemy_turn_counter >= GameManager.enemy_speed:
		enemy_turn_counter = 0
		animate_attack(enemy_sprite, enemy_base_pos, Vector2(-horizontal_dash_distance, 0))
		GameManager.player_hp -= GameManager.enemy_dmg
	GameManager.player_hp = clamp(GameManager.player_hp, 0, GameManager.max_player_hp)
	update_bars()
	check_game_state()

func execute_single_weapon_strike(weapon: Sprite2D, weapon_type: String):
	if battle_over or not is_instance_valid(weapon): return
	weapon.set_meta("is_attacking", true)
	var tween = create_tween().set_parallel(false)
	var target_position = enemy_sprite.position if weapon_type != "heal" and weapon_type != "shield" else player_sprite.position
	tween.tween_property(weapon, "position", target_position, weapon_strike_duration).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(weapon, "rotation", deg_to_rad(360), weapon_strike_duration * 0.5)
	tween.tween_property(weapon, "position", weapon.position, weapon_return_duration).finished.connect(func():
		if is_instance_valid(weapon):
			weapon.set_meta("is_attacking", false)
			weapon.rotation = 0
	)

func animate_attack(sprite, base_pos: Vector2, move_offset: Vector2):
	if sprite.has_meta("attack_tween") and sprite.get_meta("attack_tween").is_valid(): sprite.get_meta("attack_tween").kill()
	var tween = create_tween()
	sprite.set_meta("attack_tween", tween)
	tween.tween_property(sprite, "position", base_pos + move_offset, 0.12)
	tween.tween_property(sprite, "position", base_pos, 0.18)

func update_bars():
	player_hp_bar.value = GameManager.player_hp
	enemy_hp_bar.value = GameManager.enemy_hp

func execute_visual_gold_drop(reward_amount: int):
	var gold_per_coin = int(max(1, float(reward_amount) / float(total_animated_coins)))
	var target_ui_position = hud_gold_label.position + (hud_gold_label.size / 2.0)
	for i in range(total_animated_coins):
		await get_tree().create_timer(randf_range(0.02, 0.06)).timeout
		if not is_instance_valid(enemy_sprite) or not is_instance_valid(hud_gold_label): break
		var coin = Sprite2D.new()
		coin.texture = load(coin_texture_path)
		coin.scale = coin_scale
		coin.position = enemy_sprite.position
		add_child(coin)
		var coin_tween = create_tween().set_parallel(false)
		coin_tween.tween_property(coin, "position", enemy_sprite.position + Vector2(randf_range(-90, 90), randf_range(-120, -30)), 0.35)
		coin_tween.tween_property(coin, "position", target_ui_position, 0.55)
		coin_tween.finished.connect(func():
			coin.queue_free()
			current_displayed_gold += gold_per_coin
			hud_gold_label.text = "Gold: " + str(current_displayed_gold)
		)

func update_popup_text_scale():
	var panel_size = $WinPopup/Panel.size
	result_label.add_theme_font_size_override("font_size", int(48 * (panel_size.y / 300.0)))
	
func show_win_popup():
	var screen_size = get_viewport_rect().size
	result_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var dynamic_panel_size = Vector2(screen_size.x * win_popup_width_ratio, screen_size.y * win_popup_height_ratio)
	$WinPopup/Panel.custom_minimum_size = dynamic_panel_size
	$WinPopup/Panel.size = dynamic_panel_size
	win_popup.global_position = (screen_size - dynamic_panel_size) / 2.0
	Engine.time_scale = 1
	result_label.text = "YOU ESCAPED" if escape_sequence_triggered else ("YOU WON" if won else "YOU LOST")
	win_popup.visible = true
	update_popup_text_scale()
	
func _on_continue_pressed():
	Engine.time_scale = 1
	if not won: get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	else: 
		if not escape_sequence_triggered: GameManager.escaped = false 
		get_tree().change_scene_to_file("res://Scenes/map.tscn")
