extends Control

@onready var player_sprite = $Hero
const TimeController = preload("res://Scripts/time.gd")
var time_ctrl = TimeController.new()
@onready var textureRect = $TextureRect
func fit_to_screen():
	# 1. Disable anchors if you are setting size manually
	textureRect.anchor_left = 0
	textureRect.anchor_top = 0
	textureRect.anchor_right = 0
	textureRect.anchor_bottom = 0
	
	# 2. Set the size to the viewport
	textureRect.size = get_viewport_rect().size
	
	# 3. Ensure the texture stretches to fill that size
	textureRect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	textureRect.stretch_mode = TextureRect.STRETCH_SCALE
	
@onready var audience_container = $AudienceContainer

func _ready():
	fit_to_screen()
	randomize()
	add_child(time_ctrl)
	time_ctrl.create_shop_buttons(self)
	if audience_container.has_method("populate_audience"):
		audience_container.populate_audience()
	player_sprite.set_show_placeholders(true)    
	player_sprite.refresh_character_and_weapons(GameManager.player_profile)
	player_sprite.increase_weapon_orbit_radius(2.0)

func _process(delta: float) -> void:
	# 3. Delegate the movement calculations to the Hero node
	if is_instance_valid(player_sprite) and player_sprite.has_method("update_weapon_movements"):
		player_sprite.update_weapon_movements(delta, player_sprite.position)


	

# ---------------------------------
