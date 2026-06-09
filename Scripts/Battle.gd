extends Control

const TimeController = preload("res://Scripts/time.gd")
var time_ctrl = TimeController.new()

# =================================================================
# SETTINGS & REFERENCES
# =================================================================
@onready var player_sprite = $Hero 
@onready var enemy_sprite = $Foe
@onready var audience_container = $AudienceContainer

var battle_over := false
var won := false

# =================================================================
# INITIALIZATION
# =================================================================
func advance_or_finish_tournament():
	var diff_key = GameManager.get_difficulty_key()
	var next_round = GameManager.currentRound + 1

	var next_enemy = MonsterData.get_monster(diff_key, next_round)

	# If there is another fight
	if next_enemy != {}:
		GameManager.currentRound = next_round
		GameManager.current_enemy_profile = next_enemy
		get_tree().reload_current_scene()
	else:
		# Tournament finished
		GameManager.unlock_difficulty_mastery()
		show_tournament_win()

func _ready():
	add_child(time_ctrl)
	time_ctrl.create_time_buttons(self)
	
	var screen_size = get_viewport_rect().size
	player_sprite.position = Vector2(screen_size.x * 0.25, screen_size.y * 0.3)
	enemy_sprite.position = Vector2(screen_size.x * 0.75, screen_size.y * 0.3)
	
	player_sprite.refresh_character_and_weapons(GameManager.player_profile)
	enemy_sprite.refresh_character_and_weapons(GameManager.current_enemy_profile)
		
	if audience_container.has_method("populate_audience"):
		audience_container.populate_audience()

# =================================================================
# MAIN LOOP
# =================================================================
func _process(delta):
	if battle_over: return
	
	# 1. Update Floating Animations
	player_sprite.update_weapon_movements(delta, player_sprite.position)
	enemy_sprite.update_weapon_movements(delta, enemy_sprite.position)
	
	# 2. Combat Resolution
	_process_combat_ticks(GameManager.player_profile, GameManager.current_enemy_profile, player_sprite, enemy_sprite, delta)
	_process_combat_ticks(GameManager.current_enemy_profile, GameManager.player_profile, enemy_sprite, player_sprite, delta)
	
	var stats = GameManager.player_profile["stats"]
	player_sprite.draw_health(stats)
	if stats["hp"] <= 0:
		check_game_state() 
	
	stats = GameManager.current_enemy_profile["stats"]
	enemy_sprite.draw_health(stats)
	if stats["hp"] <= 0:
		check_game_state() 

func _process_combat_ticks(opponent_stats: Dictionary, target_stats: Dictionary, attacker_node, target_node, delta):
	for weapon in attacker_node.weapon_sprites:
		if weapon.get_meta("is_attacking", false):
			continue

		var timer = weapon.get_meta("cooldown_timer") - delta

		if timer <= 0:
			var type = weapon.get_meta("weapon_type")
			var amount = weapon.get_meta("amount")
			var friendly = weapon.get_meta("friendly")

			Stats.execute_weapon(type, amount, target_stats, opponent_stats)
			if friendly:
				attacker_node.attack_target(
				weapon,
				attacker_node.global_position + Vector2(0, -50),
				0.2
				)
			else:
				attacker_node.attack_target(
				weapon,
				target_node.global_position,
				0.2
				)
			timer = weapon.get_meta("cooldown_max")

		weapon.set_meta("cooldown_timer", timer)

# =================================================================
# GAME STATE
# =================================================================
func show_tournament_win():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center)

	var vbox = VBoxContainer.new()
	center.add_child(vbox)

	var label = Label.new()
	label.text = "YOU WON THE TOURNAMENT"
	label.add_theme_font_size_override("font_size", 64)
	vbox.add_child(label)

	var btn = Button.new()
	btn.text = "Return to Menu"
	btn.pressed.connect(func():
		Engine.time_scale = 1
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	)
	vbox.add_child(btn)

	Engine.time_scale = 0

func check_game_state():
	if battle_over: return
	battle_over = true

	if GameManager.current_enemy_profile["stats"]["hp"] <= 0:
		advance_or_finish_tournament()
	else:
		show_loss_popup()

func show_loss_popup():
	var canvas = CanvasLayer.new()
	canvas.layer = 100
	add_child(canvas)

	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)

	var center_box = CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_box)

	var vbox = VBoxContainer.new()
	center_box.add_child(vbox)

	var result_label = Label.new()
	result_label.text = "YOU LOST"
	result_label.add_theme_font_size_override("font_size", 64)
	vbox.add_child(result_label)

	var continue_btn = Button.new()
	continue_btn.text = "Return to Menu"
	continue_btn.custom_minimum_size = Vector2(200, 60)
	continue_btn.pressed.connect(func():
		Engine.time_scale = 1
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
	)
	vbox.add_child(continue_btn)

	Engine.time_scale = 0
	
func show_win_popup():
	# 1. Use a CanvasLayer to ensure the UI is drawn on top of EVERYTHING
	# and is not affected by camera movement or node positions.
	var canvas = CanvasLayer.new()
	canvas.layer = 100 # Ensure it's on the top layer
	add_child(canvas)
	
	# 2. Create the full-screen overlay inside the CanvasLayer
	var overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0.8)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
	# 3. Create a CenterContainer to force content to the middle
	var center_box = CenterContainer.new()
	center_box.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(center_box)
	
	# 4. Create VBoxContainer for layout
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	center_box.add_child(vbox)
	
	# 5. Create Label and Button
	var result_label = Label.new()
	result_label.text = "YOU WON" if won else "YOU LOST"
	result_label.add_theme_font_size_override("font_size", 64)
	vbox.add_child(result_label)
	
	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(200, 60)
	continue_btn.pressed.connect(_on_continue_pressed)
	vbox.add_child(continue_btn)
	
	Engine.time_scale = 0

func _on_continue_pressed():
	Engine.time_scale = 1
	if won:
		# Go to store if won
		get_tree().change_scene_to_file("res://Scenes/Store.tscn")
	else:
		# Go to main menu if lost
		get_tree().change_scene_to_file("res://Scenes/MainMenu.tscn")
