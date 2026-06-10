extends Marker2D

var velocity := Vector2(0, -100) # Speed of upward movement
var lifetime := 1.0               # Total seconds to live
var elapsed := 0.0

@onready var label = $Label
@onready var sprite = $Sprite2D

func _ready():
	# Randomize start position slightly so they don't spawn in a perfect stack
	position += Vector2(randf_range(-20, 20), randf_range(-20, 20))

func setup(amount: int, is_heal: bool, icon_index: int):
	label.text = str(amount)
	label.modulate = Color.GREEN if is_heal else Color.RED
	
	# --- ADD THIS TO SCALE FONT SIZE ---
	# Define a base size and increase it if the hit is large
	var base_font_size = 60
	var final_size = base_font_size + min(amount / 10, 20) # Increases size based on damage
	label.add_theme_font_size_override("font_size", final_size)
	# ------------------------------------
	
	# Atlas selection
	var frame_size = Vector2(16, 16) 
	var x = (icon_index % 4) * frame_size.x
	var y = (icon_index / 4) * frame_size.y
	sprite.region_enabled = true
	sprite.region_rect = Rect2(Vector2(x, y), frame_size)

func _process(delta):
	elapsed += delta
	
	# Move upwards
	position += velocity * delta
	
	# Fade out (Alpha component of modulate)
	var alpha = lerp(1.0, 0.0, elapsed / lifetime)
	modulate.a = alpha
	
	# Delete when finished
	if elapsed >= lifetime:
		queue_free()
