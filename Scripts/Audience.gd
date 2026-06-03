extends Area2D

@onready var seat = $Seat
@onready var person = $Person # Assuming this is a Sprite2D

var viewer_data = null
var is_filled := false

func setup_type(data: Dictionary):
	viewer_data = data
	is_filled = true
	person.visible = true
	
	# Check if sprite_data exists for this audience member
	if data.has("sprite_data"):
		var s_data = data["sprite_data"]
		person.hframes = 4
		person.vframes = 4
		person.texture = load(s_data["texture"])
		person.frame = s_data["frame"]
	# Fallback to old icon system
	elif data.has("icon") and ResourceLoader.exists(data.icon):
		person.texture = load(data.icon)
		
func set_filled(value: bool):
	is_filled = value
	person.visible = value
	seat.modulate = Color(1, 1, 1) if value else Color(0.5, 0.5, 0.5)

func _process(delta):
	# Throw logic based on upgrade stats
	if is_filled and viewer_data and randf() < viewer_data.get("throw_chance", 0):
		perform_throw()

func perform_throw():
	var target = get_tree().current_scene.get_node_or_null("Foe")
	if not target: return
	
	var projectile = Sprite2D.new()
	
	# Set the same texture and region
	projectile.texture = person.texture
	projectile.hframes = 4
	projectile.vframes = 4
	projectile.frame = person.frame # Keep the same specific character
	
	projectile.scale = Vector2(0.15, 0.15)
	projectile.global_position = person.global_position
	get_tree().current_scene.add_child(projectile)
	
	var tween = create_tween()
	tween.tween_property(projectile, "position", target.global_position, 0.4)
	tween.tween_callback(func():
		apply_effect()
		projectile.queue_free()
	)

func apply_effect():
	# If the viewer is an Empty Fan or has no value, do nothing
	if viewer_data.name == "Empty Fan" or viewer_data.value == 0:
		return

	Stats.execute_weapon(viewer_data.type, viewer_data.value, GameManager.player_profile, GameManager.current_enemy_profile)
