extends Sprite2D

var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")

@onready var layers: Node2D = $UpgradeLayers
var health_bar: ProgressBar = null

@export_group("Floating Rainbow Settings")
@export var rainbow_radius_x: float = 150.0
@export var rainbow_radius_y: float = 150.0
@export var rainbow_offset: Vector2 = Vector2(0, 0)
@export var rainbow_y_offset: float = -100.0
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5
@export var weapon_follow_smoothness: float = 8.0

var weapon_sprites: Array[Sprite2D] = []
var floating_time := 0.0

func _find_upgrade_by_name(target_name: String) -> Dictionary:
	var upgrade_data = preload("res://Scripts/UpgradeData.gd").new()
	for upgrade in upgrade_data.upgrades:
		if upgrade["name"] == target_name: return upgrade
	return {}

#func _ready() -> void:

func draw_health(stats: Dictionary):

	if not health_bar:
		health_bar = ProgressBar.new()
		health_bar.size = Vector2(100, 20)
		health_bar.position = Vector2(-50, 150)
		health_bar.z_index = 4096

		var style_bg = StyleBoxFlat.new()
		style_bg.bg_color = Color.BLACK
		health_bar.add_theme_stylebox_override("background", style_bg)

		var style_fg = StyleBoxFlat.new()
		style_fg.bg_color = Color.GREEN
		health_bar.add_theme_stylebox_override("fill", style_fg)

		add_child(health_bar)

	health_bar.max_value = stats["maxhp"]
	health_bar.value = stats["hp"]

func spawn_weapons(weapon_data_array: Array):
	weapon_sprites.clear()
	for child in get_children():
		if child.has_meta("slot_index"): child.queue_free()
		
	for i in range(weapon_data_array.size()):
		var data = weapon_data_array[i]
		if not data: continue
		
		var weapon_info = data
		if weapon_info is String:
			weapon_info = _find_upgrade_by_name(weapon_info)
		if weapon_info.is_empty(): continue

		var weapon = Sprite2D.new()
		var mat = ShaderMaterial.new()
		mat.shader = outline_shader
		weapon.material = mat
		var lvl = weapon_info.get("level", 1.0)
		mat.set_shader_parameter("level", float(lvl))
		var icon_path = weapon_info.get("icon", "res://icon.svg")
		var atlas = load(icon_path).duplicate()
		
		var index = weapon_info.get("index", 0)
		var tile_size = Vector2(250, 250)
		atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
		
		weapon.texture = atlas
		add_child(weapon)
		
		# --- WEAPON METADATA ---
		var speed_val = weapon_info.get("speed", 3.0)
		var cooldown_duration = 1.0 / ((10.0 + speed_val) / 10.0)
		
		weapon.set_meta("slot_index", i)
		weapon.set_meta("weapon_type", weapon_info.get("type"))
		weapon.set_meta("amount", weapon_info.get("amount"))
		weapon.set_meta("friendly", weapon_info.get("friendly"))
		weapon.set_meta("cooldown_max", cooldown_duration)
		weapon.set_meta("cooldown_timer", randf_range(0.0, cooldown_duration))
		
		weapon_sprites.append(weapon)

func update_weapon_movements(delta: float, _player_pos: Vector2):
	floating_time += delta
	for i in range(weapon_sprites.size()):
		var weapon = weapon_sprites[i]
		if weapon.get_meta("is_attacking", false): continue
		
		var slot_idx = weapon.get_meta("slot_index")
		var angle = float(slot_idx) * (PI / 5.0)
		var float_off = sin(floating_time * float_wave_speed + slot_idx) * float_amplitude
		
		var target = rainbow_offset + Vector2(
			-cos(angle) * rainbow_radius_x, 
			-sin(angle) * rainbow_radius_y + rainbow_y_offset + float_off
		)
		weapon.position = weapon.position.lerp(target, delta * weapon_follow_smoothness)

func attack_target(weapon: Sprite2D, target_pos: Vector2, duration: float):
	weapon.set_meta("is_attacking", true)
	var local_target = to_local(target_pos)
	var tween = create_tween()
	tween.tween_property(weapon, "position", local_target, duration).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(weapon, "position", weapon.get_meta("original_pos", Vector2.ZERO), duration).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): weapon.set_meta("is_attacking", false))

func refresh_character_and_weapons(profile: Dictionary):
	var sprite_data = profile.get("sprite_data")
	
	if sprite_data:
		# 1. Ensure the Sprite2D knows it's a 4x4 grid
		self.hframes = 4
		self.vframes = 4
		
		# 2. Load the texture
		self.texture = load(sprite_data["texture"])

		# 3. Set the specific index (0 to 15)
		self.frame = sprite_data["frame"]
		
	# Since this function is now inside the Hero script, 
	# you can call these methods directly
	load_upgrade_sprites()
	spawn_weapons(profile["weapons"])

func load_upgrade_sprites() -> void:
	# Clear existing icons
	for child in layers.get_children():
		child.queue_free()

	var passives = GameManager.player_profile.get("passives", [])
	
	# Configuration for the "flower bank" layout
	var columns = 5            # Number of icons per row
	var icon_spacing = 40.0    # Distance between icons
	var start_pos = Vector2(-80, 150) # Starting position relative to player
	var icon_scale = Vector2(0.2, 0.2) # Adjust size to be smaller/appropriate for bank

	var count = 0
	for upgrade in passives:
		if upgrade.has("icon"):
			var sprite = Sprite2D.new()
			
			# --- APPLY SHADER ---
			var mat = ShaderMaterial.new()
			mat.shader = outline_shader
			# Set the level uniform from the upgrade data
			mat.set_shader_parameter("level", float(upgrade.get("level", 1.0)))
			sprite.material = mat
			# --------------------
			
			var icon_path = upgrade["icon"]
			
			if ResourceLoader.exists(icon_path):
				var atlas = load(icon_path).duplicate()
				var index = upgrade.get("index", 0)
				var tile_size = Vector2(250, 250)
				
				# Slice the 4x4 atlas correctly
				atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
				
				sprite.texture = atlas
				sprite.scale = icon_scale
				
				# Calculate grid position: x increments by column, y increments by row
				var row = count / columns
				var col = count % columns
				sprite.position = start_pos + Vector2(col * icon_spacing, row * icon_spacing)
				
				if upgrade.has("layer"):
					sprite.z_index = clamp(upgrade["layer"], -4096, 4096)
				
				layers.add_child(sprite)
				count += 1
