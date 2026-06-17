extends Area2D

@onready var seat = $Seat
@onready var person = $Person # Assuming this is a Sprite2D
@onready var medal = $Medal
@onready var lock = $Lock # Make sure this path matches your scene tree
var is_border := false
var viewer_data = null
var is_filled := false
var amfriendly = true
func _ready():
    if person.material is ShaderMaterial:
        # This makes the material unique to THIS specific instance of the audience scene
        person.material = person.material.duplicate()

func set_medal(data: Dictionary) -> void:
    medal.visible = false

    if data.is_empty():
        return

    if data.get(2, false):
        medal.visible = true
        medal.frame = 2 # gold
    elif data.get(1, false):
        medal.visible = true
        medal.frame = 1 # silver
    elif data.get(0, false):
        medal.visible = true
        medal.frame = 0 # bronze

func set_is_border(status: bool):
    is_border = status
    # Update the lock visibility immediately in case it was already set
    if lock != null:
        lock.visible = (!is_filled and !is_border)

func set_team(is_friendly: bool):
    amfriendly = is_friendly
    if person.material is ShaderMaterial:
        person.material.set_shader_parameter("is_friendly", is_friendly)

func setup_type(data: Dictionary, is_friendly: bool):
    viewer_data = data
    is_filled = true
    person.visible = true
    
    # Apply the shader state
    set_team(is_friendly)
    
    # ... rest of your existing texture loading code ...
    
    # Check if sprite_data exists for this audience member
    if data.has("icon"):
        var texture_path = data["icon"]
        if ResourceLoader.exists(texture_path):
            person.texture = load(texture_path)
            person.hframes = 4
            person.vframes = 4
            person.frame = data.get("index", 0) # Default to 0 if "index" is missing
        else:
            push_error("Texture not found at: " + texture_path)
        
func set_filled(value: bool):
    is_filled = value
    person.visible = value
    if lock != null:
        lock.visible = (!value and !is_border)
    seat.modulate = Color(1, 1, 1) if value else Color(0.5, 0.5, 0.5)

#func _process(delta):
    # Throw logic based on upgrade stats
    #if is_filled and viewer_data and randf() < viewer_data.get("throw_chance", 0):
        #perform_throw()

func goldd():
    GameManager.addtopassive("MAXGold",1)

func perform_throw():
    var projectile = Sprite2D.new()
    var atlas
    var index 
    var throwright = true
    # Set the texture and region
    if (amfriendly):
        throwright = false
        if (GameManager.DidWin ):
        
            atlas = load("res://Assets/atlas/icon.tres") # Use the base texture
            index = 0 
        else :
            atlas = load("res://Assets/atlas/icon2.tres") # Use the base texture
            index = 2
    else:
        if (GameManager.DidWin ):
        
            atlas = load("res://Assets/atlas/icon2.tres") # Use the base texture
            index = 2 
        else :
            atlas = load("res://Assets/atlas/icon.tres") # Use the base texture
            index = 0
    
    # 2. Create the AtlasTexture resource
    var atlas_texture = AtlasTexture.new()
    atlas_texture.atlas = atlas
    
    # 3. Calculate position in the 4x4 grid
    var tile_size = Vector2(250, 250)
    
    var col = index % 4
    var row = index / 4
    
    # 4. Define the region (the slice of the image)
    var region_rect = Rect2(Vector2(col, row) * tile_size, tile_size)
    atlas_texture.region = region_rect
    
    projectile.texture = atlas_texture
    
    # --- Rest of your existing logic ---
    projectile.scale = Vector2(0.8, 0.8)
    projectile.global_position = person.global_position
    get_tree().current_scene.add_child(projectile)
    
    var screen_size = get_viewport_rect().size
    # Random x between 20% and 80% of screen width
    var random_x
    var target_y = screen_size.y * 0.72

    # Logic to constrain target_x based on throwright
    if throwright:
        # Throw to the right side (50% to 90% of screen width)
        random_x = randf_range(screen_size.x * 0.6, screen_size.x * 0.9)
    else:
        # Throw to the left side (10% to 50% of screen width)
        random_x = randf_range(screen_size.x * 0.1, screen_size.x * 0.4)
    # Fixed height for the floor (e.g., 60% down the screen)
    var target_pos = Vector2(random_x, target_y)
    
    # Animate the movement
    var tween = create_tween()
    tween.set_trans(Tween.TRANS_QUAD)
    tween.tween_property(projectile, "position", target_pos, 0.5)
func apply_effect():
    # If the viewer is an Empty Fan or has no value, do nothing
    if viewer_data.name == "Empty Fan" or viewer_data.value == 0:
        return

    #Stats_Handler.execute_weapon(viewer_data.type, viewer_data.value, GameManager.player_profile, GameManager.current_enemy_profile)
