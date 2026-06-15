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

func draw_health(target: Dictionary):

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

    health_bar.max_value = GameManager.getpassive3("MAXHP",target)
    health_bar.value = GameManager.getpassive3("HP",target)

func spawn_weapons(weapon_data_array: Array):
    const MAX_SLOTS = 6 
    
    # Clean up old weapons
    for child in get_children():
        if child.has_meta("slot_index"): child.queue_free()
    weapon_sprites.clear()
        
    for i in range(MAX_SLOTS):
        var weapon_container: Area2D = Area2D.new() # Create this immediately
        var visual_sprite: Sprite2D = null
        
        # Check if we have data
        if i < weapon_data_array.size() and weapon_data_array[i]:
            var data = weapon_data_array[i]
            var weapon_info = _find_upgrade_by_name(data) if data is String else data
            
            if not weapon_info.is_empty():
                visual_sprite = GameManager._create_weapon_sprite(weapon_info)
                weapon_container.add_child(visual_sprite)
                
                # Collision setup (Existing code)
                var shape = CollisionShape2D.new()
                shape.shape = RectangleShape2D.new()
                shape.shape.size = visual_sprite.get_rect().size * visual_sprite.scale
                weapon_container.add_child(shape)
                weapon_container.set_meta("collision_shape", shape)
        
        # Placeholder handling
        elif show_placeholders and placeholder_texture:
            visual_sprite = Sprite2D.new()
            visual_sprite.texture = placeholder_texture
            visual_sprite.modulate = Color(1, 1, 1, 0.3)
            weapon_container.add_child(visual_sprite)
            
            # Placeholders need a collision shape too if you want to drop things on them!
            var shape = CollisionShape2D.new()
            shape.shape = RectangleShape2D.new()
            shape.shape.size = placeholder_texture.get_size()
            weapon_container.add_child(shape)
            weapon_container.set_meta("collision_shape", shape)
        
        # --- NEW: Always register the container ---
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

func _input(event):
    if not show_placeholders: return

    # 1. Start Dragging
    if event is InputEventScreenTouch and event.pressed:
        for weapon in weapon_sprites:
            if not weapon.has_meta("collision_shape"): continue
            
            var collision_shape = weapon.get_meta("collision_shape")
            var shape_size = collision_shape.shape.size
            var global_rect = Rect2(weapon.global_position - (shape_size / 2), shape_size)
            
            if global_rect.has_point(event.position):
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
    # Find all areas overlapping the dropped weapon
    var overlapping_areas = dropped_weapon.get_overlapping_areas()
    var target_weapon: Area2D = null

    for area in overlapping_areas:
        # Check if we hit another weapon (excluding the weapon itself)
        if area != dropped_weapon and area in weapon_sprites:
            target_weapon = area
            break
    
    if target_weapon:
        # SWAP LOGIC
        var dropped_idx = dropped_weapon.get_meta("slot_index")
        var target_idx = target_weapon.get_meta("slot_index")
        
        # Swap the meta indices
        dropped_weapon.set_meta("slot_index", target_idx)
        target_weapon.set_meta("slot_index", dropped_idx)
        
        # Swap the references in the array
        weapon_sprites[dropped_idx] = target_weapon
        weapon_sprites[target_idx] = dropped_weapon
        
        # Optional: Tween them to each other's global position for a "swap" animation
        var tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_CUBIC)
        tween.tween_property(dropped_weapon, "global_position", target_weapon.global_position, 0.3)
        tween.tween_property(target_weapon, "global_position", dropped_weapon.global_position, 0.3)
        
        print("Swapped slot ", dropped_idx, " with ", target_idx)
    else:
        # If dropped in empty space, it will naturally return to its target orbit
        # via the update_weapon_movements function in the next frame.
        pass

# Toggle function to be called from elsewhere
func set_show_placeholders(enabled: bool):
    show_placeholders = enabled

## Increases the orbit radius of the floating weapons.
## @param multiplier: The factor to multiply the current radius by (e.g., 1.1 for a 10% increase).
func increase_weapon_orbit_radius(multiplier: float) -> void:
    rainbow_radius_x *= multiplier
    rainbow_radius_y *= multiplier
    
    # Optional: Print to verify the change
    print("Weapon orbit radius updated to: ", rainbow_radius_x, ", ", rainbow_radius_y)

# Inside Hero.gd
func activate_battle_mode():
    for weapon_area in weapon_sprites:
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
        var angle = float(slot_idx) * (PI / 5.0)
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
                var value = float(upgrade.get("value", 0.0))
                var level = float(upgrade.get("level", 1.0))
                var progress = clamp(level / value, 0.0, 1.0)
                
                sprite.material.set_shader_parameter("charge_progress", progress)

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
                passive["value"] = passive["level"]
                
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
            # --- APPLY SHADER ---
            var mat = ShaderMaterial.new()
            mat.shader = outline_shader
            mat.set_shader_parameter("level", float(upgrade.get("level", 1.0)))
            mat.set_shader_parameter("index", upgrade.get("index", 0))
            
            # Enable the charge shader and set progress
            mat.set_shader_parameter("use_charge_shader", true)
            mat.set_shader_parameter("charge_progress", upgrade.get("value", 1.0)/upgrade.get("level", 1.0))
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
                
                var row = count / 5
                var col = count % 5
                sprite.position = Vector2(-80, 150) + Vector2(col * 40.0, row * 40.0)
                
                if upgrade.has("layer"):
                    sprite.z_index = clamp(upgrade["layer"], -4096, 4096)
                
                layers.add_child(sprite)
                count += 1
