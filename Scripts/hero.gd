extends Sprite2D

var outline_shader = preload("res://Assets/shaders/outline_shader.gdshader")

@onready var layers: Node2D = $UpgradeLayers
var health_bar: ProgressBar = null

@export_group("Floating Rainbow Settings")
@export var rainbow_radius_x: float = 300.0
@export var rainbow_radius_y: float = 300.0
@export var rainbow_offset: Vector2 = Vector2(0, 0)
@export var rainbow_y_offset: float = 0.0
@export var float_amplitude: float = 4.0
@export var float_wave_speed: float = 2.5
@export var weapon_follow_smoothness: float = 8.0

var dragging_weapon: Area2D = null
var drag_offset: Vector2 = Vector2.ZERO

@export var show_placeholders: bool = false
@export var placeholder_texture: Texture2D

var weapon_sprites: Array[Area2D] = []
var floating_time := 0.0

func _ready():
	# If the inspector didn't set a value, grab it from the node
	if placeholder_texture == null:
		placeholder_texture = $Sprite2D.texture

func _find_upgrade_by_name(target_name: String) -> Dictionary:
	for upgrade in UpgradeData.upgrades:
		if upgrade["name"] == target_name: return upgrade
	return {}

#func draw_health(target: Dictionary):
#
	#if not health_bar:
		#health_bar = ProgressBar.new()
		#health_bar.size = Vector2(100, 20)
		#health_bar.position = Vector2(-50, 150)
		#health_bar.z_index = 4096
#
		#var style_bg = StyleBoxFlat.new()
		#style_bg.bg_color = Color.BLACK
		#health_bar.add_theme_stylebox_override("background", style_bg)
#
		#var style_fg = StyleBoxFlat.new()
		#style_fg.bg_color = Color.GREEN
		#health_bar.add_theme_stylebox_override("fill", style_fg)
#
		#add_child(health_bar)
#
	#health_bar.max_value = GameManager.getpassive3("MAXHP",target)
	#health_bar.value = GameManager.getpassive3("HP",target)

func _update_placeholder_position(weapon: Area2D, index: int, delta: float):
	# Calculate the bobbing effect (using the same logic as the main weapons)
	# Adding 'index' inside sin() gives each a slightly different phase
	var float_off = sin(floating_time * float_wave_speed + (index + 6)) * float_amplitude
	
	# Calculate X and Y base positions
	var x_offset = rainbow_radius_x * (index + 2)
	var y_offset = (-rainbow_radius_y / 4.0) + float_off # Add the bob here
	
	var target = Vector2(x_offset, y_offset)
	
	# Move the placeholder to the target position
	weapon.position = weapon.position.lerp(target, delta * weapon_follow_smoothness)
	
func spawn_weapons(weapon_data_array: Array):
	var MAX_SLOTS = 9 if show_placeholders else 6
	# Clean up old weapons
	for child in get_children():
		if child.has_meta("slot_index"): child.queue_free()
	weapon_sprites.clear()
		
	for i in range(MAX_SLOTS):
		var weapon_container: Area2D = Area2D.new() # Create this immediately
		var visual_sprite: Sprite2D = null
		
		# Check if we have data
		# --- PATH 1: Real Weapons ---
		if i < weapon_data_array.size() and weapon_data_array[i]:
			var data = weapon_data_array[i]
			var weapon_info = _find_upgrade_by_name(data) if data is String else data
			
			if not weapon_info.is_empty():
				visual_sprite = GameManager._create_weapon_sprite(weapon_info)
				visual_sprite.set_meta("upgrade_data", weapon_info)
				weapon_container.add_child(visual_sprite)
		
		# --- PATH 2: Placeholders (GlobalUpgrades) ---
		elif i >= 6 and GameManager.GlobalUpgrades[i-6]:
			var data = GameManager.GlobalUpgrades[i-6]
			var weapon_info = _find_upgrade_by_name(data) if data is String else data
			
			if not weapon_info.is_empty():
				visual_sprite = GameManager._create_weapon_sprite(weapon_info)
				visual_sprite.set_meta("upgrade_data", weapon_info)
				weapon_container.add_child(visual_sprite)
				if(weapon_info.get("category") == "viewer"):
					weapon_container.set_meta("Item", true)
				if(weapon_info.get("category") == "passive"):
					weapon_container.set_meta("Item", false)
		
		# --- PATH 3: Empty Placeholders ---
		elif show_placeholders and placeholder_texture:
			visual_sprite = Sprite2D.new()
			visual_sprite.texture = placeholder_texture
			visual_sprite.modulate = Color(1, 1, 1, 0.3)
			weapon_container.add_child(visual_sprite)
		
		# --- CRITICAL FIX: ALWAYS SET META IF SPRITE EXISTS ---
		if visual_sprite:
			weapon_container.set_meta("sprite", visual_sprite)
			
			# Setup Collision for any created sprite
			var shape = CollisionShape2D.new()
			shape.shape = RectangleShape2D.new()
			# Use visual_sprite.get_rect() or fallback to texture size
			var rect = visual_sprite.get_rect()
			shape.shape.size = rect.size * visual_sprite.scale *1.5
			weapon_container.add_child(shape)
			weapon_container.set_meta("collision_shape", shape)
		
	   # --- MODIFICATION START ---
		var target_pos: Vector2
		
		if i >= 6:
			# Matches the logic in _update_placeholder_position
			var idx = i - 6
			var float_off = sin(floating_time * float_wave_speed + (idx + 6)) * float_amplitude
			var x_offset = rainbow_radius_x * (idx + 2)
			var y_offset = (-rainbow_radius_y / 4.0) + float_off
			target_pos = Vector2(x_offset, y_offset)
		else:
			# Existing orbital logic for slots 0-5
			var angle = (i as float) * (PI / 5.0)      
			var float_off = sin(floating_time * float_wave_speed + i) * float_amplitude
			target_pos = rainbow_offset + Vector2(
				-cos(angle) * rainbow_radius_x, 
				-sin(angle) * rainbow_radius_y + rainbow_y_offset + float_off
			)
		
		# Apply the position directly
		weapon_container.position = target_pos
		# --- MODIFICATION END ---
		
		weapon_container.set_meta("slot_index", i)
		weapon_container.set_meta("sprite", visual_sprite)
		weapon_container.input_pickable = true
		weapon_container.input_event.connect(_on_weapon_input.bind(weapon_container))
		
		add_child(weapon_container)
		weapon_sprites.append(weapon_container) # Now all slots are tracked!

func _on_weapon_input(_viewport, event: InputEvent, _shape_idx, weapon: Area2D):
	if not show_placeholders: return
	
	# Handle Touch
	if event is InputEventScreenTouch:
		if event.pressed:
			dragging_weapon = weapon
			# We use global_position for easier touch tracking
			drag_offset = weapon.global_position - event.position
		else:
			# Touch released (Drop)
			if dragging_weapon == weapon:
				_check_drop(weapon)
				dragging_weapon = null

# For mobile, it is often smoother to update position in _input
var drag_tween: Tween = null

func _find_node_by_name(parent: Node, name: String) -> Node:
	for child in parent.get_children():
		if child.name == name:
			return child
		var found = _find_node_by_name(child, name)
		if found:
			return found
	return null

func get_audience_container():
	# Get the root node of the current scene
	return get_parent().get_node_or_null("AudienceContainer")

func _input(event):
	if not show_placeholders: return

	# 1. Start Dragging
	if event is InputEventScreenTouch and event.pressed:
		for weapon in weapon_sprites:
			if not weapon.has_meta("collision_shape"): continue
			
			var collision_shape = weapon.get_meta("collision_shape")
			var shape_size = collision_shape.shape.size
			var global_rect = Rect2(weapon.global_position - (shape_size / 2), shape_size)
			
			var slot_idx = weapon.get_meta("slot_index")-6
			var item_data
			var cost
			if(slot_idx >= 0):
				item_data = GameManager.GlobalUpgrades[slot_idx]
				if(slot_idx >= 0 and item_data):
					cost = item_data["cost"]
					var is_too_expensive2 = cost > GameManager.getpassive("MAXGold")
					
					# Corrected the typo below
					if is_too_expensive2:
						continue
			if global_rect.has_point(event.position):
				if(weapon.has_meta("Item")):
					item_data = GameManager.GlobalUpgrades[slot_idx]
					cost = item_data["cost"]
					
					if(!weapon.get_meta("Item")):
						#is passive item
						GameManager.addtopassive("MAXGold", -cost)
						GameManager.addtopassive("Gold", -cost)
						GameManager.addtopassive("MAX"+item_data["name"], 1)
						GameManager.GlobalUpgrades[slot_idx] = null
						refresh_character_and_weapons(GameManager.player_profile)
						return
					else:
						#is audience item
						GameManager.addtopassive("MAXGold", -cost)
						GameManager.addtopassive("Gold", -cost)
						GameManager.player_profile["audience"].append(item_data)
						GameManager.GlobalUpgrades[slot_idx] = null
						var container = get_audience_container()
						refresh_character_and_weapons(GameManager.player_profile)
						if container and container.has_method("populate_audience"):
							container.populate_audience()
						return
						
				dragging_weapon = weapon
				drag_offset = weapon.global_position - event.position
				
				# SMOOTHNESS: Scale up on grab
				if drag_tween: drag_tween.kill()
				drag_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
				drag_tween.tween_property(weapon, "scale", Vector2(1.2, 1.2), 0.15)
				break
	
	# 2. Moving
	elif event is InputEventScreenDrag and dragging_weapon:
		# Use a faster lerp for tighter responsiveness
		var target_pos = event.position + drag_offset
		dragging_weapon.global_position = dragging_weapon.global_position.lerp(target_pos, 0.9)
		
	# 3. Stop Dragging
	elif event is InputEventScreenTouch and not event.pressed and dragging_weapon:
		# SMOOTHNESS: Scale back down
		if drag_tween: drag_tween.kill()
		drag_tween = create_tween().set_trans(Tween.TRANS_CUBIC)
		drag_tween.tween_property(dragging_weapon, "scale", Vector2(1.0, 1.0), 0.15)
		
		_check_drop(dragging_weapon)
		dragging_weapon = null

func _check_drop(dropped_weapon: Area2D):
	var mouse_pos = get_global_mouse_position()
	var target_weapon: Area2D = null

	for weapon in weapon_sprites:
		if weapon == dropped_weapon: continue
		
		var collision_shape = weapon.get_meta("collision_shape")
		var global_rect = Rect2(weapon.global_position - (collision_shape.shape.size / 2), collision_shape.shape.size)
		
		if global_rect.has_point(mouse_pos):
			target_weapon = weapon
			break
	
	if target_weapon:
		var dropped_idx = dropped_weapon.get_meta("slot_index")
		var target_idx = target_weapon.get_meta("slot_index")
				
		if ((dropped_idx >= 6 and target_idx < 6)):
			var shop_data
			var own_data
			shop_data = GameManager.GlobalUpgrades[dropped_idx - 6]
			own_data = GameManager.player_profile["weapons"][target_idx]  
			
			if(shop_data and own_data) :
				# MERGING
				if (shop_data.get("type", "") == own_data.get("type", "")):
					if (shop_data.get("friendly", 0) == own_data.get("friendly", 0)):
						own_data["speed"] += shop_data["speed"]
						own_data["level"] += shop_data["level"]
						own_data["cost"] += shop_data["cost"]
						GameManager.addtopassive("MAXGold", -shop_data["cost"])
						GameManager.addtopassive("Gold", -shop_data["cost"])
						GameManager.GlobalUpgrades[dropped_idx - 6] = null
						refresh_character_and_weapons(GameManager.player_profile)
						return
						
		if dropped_idx < 6 and target_idx < 6:
			var shop_data = GameManager.player_profile["weapons"][dropped_idx]
			var own_data = GameManager.player_profile["weapons"][target_idx]
			
			if shop_data and own_data:
				# MERGING
				if shop_data.get("type", "") == own_data.get("type", ""):
					if shop_data.get("friendly", 0) == own_data.get("friendly", 0):
						own_data["speed"] += shop_data["speed"]
						own_data["level"] += shop_data["level"]
						own_data["cost"] += shop_data["cost"]
						GameManager.addtopassive("MAXGold", -shop_data["cost"])
						GameManager.addtopassive("Gold", -shop_data["cost"])
						GameManager.player_profile["weapons"][dropped_idx] = null
						refresh_character_and_weapons(GameManager.player_profile)
						return         
						
						
						
		if (target_idx >= 6 and dropped_idx < 6):
				# REPLACE WITH ITEM
				var shop_data = GameManager.GlobalUpgrades[target_idx - 6]
				var own_data = GameManager.player_profile["weapons"][dropped_idx]  
				if (weapon_sprites[target_idx].has_meta("Item")):
					var cost = shop_data["cost"]
					if cost <= GameManager.getpassive("MAXGold") + own_data["cost"]:
						GameManager.addtopassive("MAXGold", -shop_data["cost"] + own_data["cost"])
						GameManager.addtopassive("Gold", -shop_data["cost"]+ own_data["cost"])
						GameManager.GlobalUpgrades[target_idx - 6] = own_data 
						GameManager.player_profile["weapons"][dropped_idx] = null
						if(!weapon_sprites[target_idx].get_meta("Item", false)):
							#is passive item
							GameManager.addtopassive("MAX"+shop_data["name"], 1)
							refresh_character_and_weapons(GameManager.player_profile)
							return
						else:
							#is audience item
							GameManager.player_profile["audience"].append(shop_data)
							var container = get_audience_container()
							refresh_character_and_weapons(GameManager.player_profile)
							if container and container.has_method("populate_audience"):
								container.populate_audience()
							refresh_character_and_weapons(GameManager.player_profile)
							return
		# --- NEW PURCHASE LOGIC ---
		#if dropped_idx >= 6 and target_idx < 6:
			#var shop_item = GameManager.GlobalUpgrades[dropped_idx - 6]
			#if shop_item and shop_item.has("cost"):
				#var cost = shop_item["cost"]
				## Check if enough money
				#if cost <= GameManager.getpassive("MAXGold"):
					## Set the item slot to your weapon
					#GameManager.player_profile["weapons"][target_idx] = shop_item
					## Buy the item and set the dragged slot to null
					#GameManager.GlobalUpgrades[dropped_idx - 6] = null
					## Exchange the money
					#GameManager.addtopassive("MAXGold", -cost)
					#
					## Refresh UI
					#refresh_character_and_weapons(GameManager.player_profile)
					#return # Return after successful purchase
				#else:
					#print("Not enough gold!")
		# ---------------------------
						
		#we switch
		if (dropped_idx >= 6 and target_idx < 6) or (target_idx >= 6 and dropped_idx < 6):
			var shop = dropped_idx
			var own = target_idx
			if(target_idx >= 6 ):
				shop = target_idx
				own = dropped_idx
			var shop_data = GameManager.GlobalUpgrades[shop - 6]
			var own_data = GameManager.player_profile["weapons"][own]
			
			var cost_shop = 0 
			if (shop_data):
				cost_shop = int(shop_data.get("cost", 0))
			var cost_own = 0 
			if (own_data):
				cost_own = int(own_data.get("cost", 0))
			if cost_shop > GameManager.getpassive("MAXGold") + cost_own:
				# Play an error sound or UI feedback here if desired
				print("Not enough gold to equip this weapon!")
				return # Stop the swap
			else:
				GameManager.addtopassive("MAXGold", cost_own - cost_shop)
				GameManager.addtopassive("Gold", cost_own - cost_shop)

		# 1. Swap Meta
		dropped_weapon.set_meta("slot_index", target_idx)
		target_weapon.set_meta("slot_index", dropped_idx)
		
		# 2. Swap References in array
		weapon_sprites[dropped_idx] = target_weapon
		weapon_sprites[target_idx] = dropped_weapon
		
		# 3. Update Data (Only if indices are within the valid weapon array range)
		var weapons_data = GameManager.player_profile["weapons"]
		
		# We only swap in the data array if both indices point to real weapon slots
		if dropped_idx < weapons_data.size() and target_idx < weapons_data.size():
			var temp_data = weapons_data[dropped_idx]
			weapons_data[dropped_idx] = weapons_data[target_idx]
			weapons_data[target_idx] = temp_data
		elif dropped_idx < weapons_data.size() and target_idx >= weapons_data.size():
			var temp_data = weapons_data[dropped_idx]
			weapons_data[dropped_idx] = GameManager.GlobalUpgrades[target_idx-6]
			GameManager.GlobalUpgrades[target_idx-6] = temp_data
		elif dropped_idx >= weapons_data.size() and target_idx < weapons_data.size():
			var temp_data = weapons_data[target_idx]
			weapons_data[target_idx] = GameManager.GlobalUpgrades[dropped_idx-6]
			GameManager.GlobalUpgrades[dropped_idx-6] = temp_data
		elif dropped_idx >= weapons_data.size() and target_idx >= weapons_data.size():
			var temp_data = GameManager.GlobalUpgrades[target_idx-6]
			GameManager.GlobalUpgrades[target_idx-6] = GameManager.GlobalUpgrades[dropped_idx-6]
			GameManager.GlobalUpgrades[dropped_idx-6] = temp_data
			
		# 4. Animate
		var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
		tween.tween_property(dropped_weapon, "global_position", target_weapon.global_position, 0.3)
		tween.tween_property(target_weapon, "global_position", dropped_weapon.global_position, 0.3)
# Toggle function to be called from elsewhere
func set_show_placeholders(enabled: bool):
	show_placeholders = enabled

## Increases the orbit radius of the floating weapons.
## @param multiplier: The factor to multiply the current radius by (e.g., 1.1 for a 10% increase).
#func increase_weapon_orbit_radius(multiplier: float) -> void:
	#rainbow_radius_x *= multiplier
	#rainbow_radius_y *= multiplier
	#rainbow_y_offset += 100.0
	## Optional: Print to verify the change
	#print("Weapon orbit radius updated to: ", rainbow_radius_x, ", ", rainbow_radius_y)

# Inside Hero.gd
func activate_battle_mode():
	for weapon_area in weapon_sprites:
		if not weapon_area.has_meta("sprite"): continue

		var sprite = weapon_area.get_meta("sprite")
		if sprite and sprite.material is ShaderMaterial:
			sprite.material.set_shader_parameter("use_charge_shader", true)
			
func update_weapon_movements(delta: float, _player_pos: Vector2):
	floating_time += delta
	for i in range(weapon_sprites.size()):
		var weapon = weapon_sprites[i]
		if weapon == dragging_weapon:
			continue
		if weapon.get_meta("is_attacking", false): continue
		
		
		var slot_idx = weapon.get_meta("slot_index")
		if slot_idx < 6 and weapon.has_meta("sprite"):
			# Ensure default
			var visual_sprite = weapon.get_meta("sprite") # Get the sprite
			if (visual_sprite):
				var upgrade = visual_sprite.get_meta("upgrade_data", {}) 
				var Text =  "\n\n\n" + str(upgrade.get("cost", 0)) + "$: " if(show_placeholders) else ""
				update_label(visual_sprite, upgrade,Text)
		if slot_idx >= 6:
			# Ensure default
			var visual_sprite = weapon.get_meta("sprite") # Get the sprite
			var upgrade = visual_sprite.get_meta("upgrade_data", {}) 
			var cost = int(upgrade.get("cost", 0))
			var Text =  "\n\n\n" + str(cost) + "$: "
			var desc = Text + upgrade.get("Description", "")
			var label = update_label(visual_sprite, upgrade,desc)
			var is_too_expensive = cost > GameManager.getpassive("MAXGold")
			set_label_color(label, is_too_expensive)
			_update_placeholder_position(weapon, slot_idx - 6, delta)
			continue # Skips the rest of the loop for this item
		var angle = (slot_idx as float) * (PI / 5.0)        
		var float_off = sin(floating_time * float_wave_speed + slot_idx) * float_amplitude
		
		var target = rainbow_offset + Vector2(
			-cos(angle) * rainbow_radius_x, 
			-sin(angle) * rainbow_radius_y + rainbow_y_offset + float_off
		)
		weapon.position = weapon.position.lerp(target, delta * weapon_follow_smoothness)
# 2. NEW: Update Passive Shader Parameters
	for sprite in layers.get_children():
		if sprite is Sprite2D and sprite.material is ShaderMaterial:
			# We need to find the data associated with this sprite. 
			# Storing the upgrade dictionary as meta is the cleanest way.
			var upgrade = sprite.get_meta("upgrade_data")
			if upgrade:
				var valueint = int(upgrade.get("value", 0.0))
				var levelint = int(upgrade.get("level", 1.0))
				
				var value = float(upgrade.get("value", 0.0))
				var level = float(upgrade.get("level", 1.0))
				var val_str = str(valueint).left(2) + afterv(value)
				var lvl_str = str(levelint).left(2) + afterv(level)
				var text =  "\n" + "\n" + lvl_str
				update_label(sprite, upgrade,text)
				var progress = clamp(level / value, 0.0, 1.0)
				#health
				sprite.material.set_shader_parameter("charge_progress", progress)
				#help draw over the sprite and under the sprite the numbers of value and level

func attack_target(weapon: Area2D, target_pos: Vector2, duration: float):
	weapon.set_meta("is_attacking", true)
	var local_target = to_local(target_pos)
	var tween = create_tween()
	tween.tween_property(weapon, "position", local_target, duration).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(weapon, "position", weapon.get_meta("original_pos", Vector2.ZERO), duration).set_ease(Tween.EASE_OUT)
	tween.finished.connect(func(): weapon.set_meta("is_attacking", false))

func ValueToLevel(profile: Dictionary):
	# Ensure the profile has a "passives" array before trying to iterate
	if not profile.has("passives"):
		return

	# Iterate through the passives array
	for passive in profile["passives"]:
		# Safety check: ensure the item is a dictionary and has both required keys
		if passive is Dictionary:
			if passive.has("level") and passive.has("value"):
				# Set the 'value' to the current 'level'
				passive["level"] = passive["value"]
				
				# Optional: print for debugging
				# print("Updated ", passive.get("name", "unknown"), " value to: ", passive["level"])
	

func refresh_character_and_weapons(profile: Dictionary):
	ValueToLevel(profile)
	if profile.get("icon") != null:
		var texture_path = profile["icon"]
		if ResourceLoader.exists(texture_path):
			self.texture = load(texture_path)
			self.hframes = 4
			self.vframes = 4
			self.frame = profile.get("index", 0) # Default to 0 if "index" is missing
		else:
			push_error("Texture not found at: " + texture_path)
		
	# Since this function is now inside the Hero script, 
	# you can call these methods directly
	load_upgrade_sprites(profile)
	spawn_weapons(profile["weapons"])
  
static func afterv(val: int) -> String:
	if val < 10:
		return ""
	elif val < 100:
		return ""
	elif val < 1000:
		return "A"
	elif val < 10000:
		return "B"
	elif val < 10000:
		return "C"
	elif val < 10000:
		return "D"
	elif val < 10000:
		return "E"
	else:
		return "F" # Good practice to provide a fallback

static func setup_or_update_label(sprite: Sprite2D, upgrade: Dictionary) -> Label:
	var label: Label
	if sprite.has_meta("text_label"):
		label = sprite.get_meta("text_label")
	else:
		var sprite_size = sprite.get_rect().size * sprite.global_scale
		var ratio = 270/sprite_size.x
		label = Label.new()
		sprite.add_child(label)
		sprite.set_meta("text_label", label)
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.custom_minimum_size = Vector2(sprite_size.x*0.6, 0)
		# Styling
		var settings = LabelSettings.new()
		settings.font_size = 80 *ratio
		settings.font_color = Color.BLACK
		settings.outline_size = 30
		settings.outline_color = Color.WHITE
		label.label_settings = settings
		
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		
		# Since it is a child, position it relative to the Sprite2D's center
		# Assuming the Sprite is 250x250 based on your code:
		label.size = Vector2(250, 250)
		label.position = Vector2(-125, -125) 
	label.z_index = 10
	return label

static func update_label(sprite: Sprite2D, upgrade: Dictionary, meta_key: String = "text_label") -> Label:
	var label: Label = setup_or_update_label(sprite, upgrade)
	label.text = meta_key
	return label

static func set_label_color(label: Label, is_too_expensive: bool) -> void:
	if label.label_settings:
		if is_too_expensive:
			label.label_settings.font_color = Color.RED
		else:
			label.label_settings.font_color = Color.BLACK

func load_upgrade_sprites(profile: Dictionary) -> void:
	# Clear existing icons
	for child in layers.get_children():
		child.queue_free()

	var passives = profile.get("passives", [])
	var count = 0
	
	# --- ADDED: Load UpgradeData to resolve names ---
	# -------------------------------------------------

	for item in passives:
		# Resolve string to full dictionary if necessary
		var upgrade = item
		if upgrade is String:
			for data in UpgradeData.upgrades:
				if data["name"] == upgrade:
					upgrade = data
					break
		
		# Now 'upgrade' is a dictionary (if found)
		if upgrade is Dictionary and upgrade.has("icon"):
			var sprite = Sprite2D.new()
			sprite.set_meta("upgrade_data", upgrade)
			
			# --- Create and attach label ---
			
			# --- APPLY SHADER ---
			var mat = ShaderMaterial.new()
			mat.shader = outline_shader
			mat.set_shader_parameter("level", float(upgrade.get("level", 1.0)))
			mat.set_shader_parameter("index", upgrade.get("index", 0))
			
			# Enable the charge shader and set progress
			mat.set_shader_parameter("use_charge_shader", true)
			var lvl = upgrade.get("level", 1.0)
			var val = upgrade.get("value", 1.0)

			# Safety check: if lvl is 0, we treat it as 1 to avoid the crash
			mat.set_shader_parameter("charge_progress", val / max(1.0, float(lvl)))
			sprite.material = mat
			# --------------------
			
			var icon_path = upgrade["icon"]
			if ResourceLoader.exists(icon_path):
				var atlas = load(icon_path).duplicate()
				var index = upgrade.get("index", 0)
				var tile_size = Vector2(250, 250)
				
				atlas.region = Rect2(Vector2((index % 4) * tile_size.x, (index / 4) * tile_size.y), tile_size)
				sprite.texture = atlas
				sprite.scale = Vector2(0.3, 0.3)
				
				var row = count / 6
				var col = count % 6
				sprite.position = Vector2(-110, 150) + Vector2(col * 40.0, row * 40.0)
				
				layers.add_child(sprite)
				count += 1
