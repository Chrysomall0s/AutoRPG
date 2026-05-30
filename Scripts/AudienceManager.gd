extends Node2D

@export_group("Audience Grid Details")
@export var audience_columns: int = 11
@export var audience_rows: int = 6
@export var original_sprite_width: float = 44.0    
@export var original_sprite_height: float = 44.0   

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")
@onready var audience_container = self # Assuming script is on the container

func _ready():
	populate_audience()

func populate_audience():
	randomize()
	
	# 1. Ensure seat order is calculated once
	if GameManager.seat_priority_order.is_empty():
		GameManager.initialize_seating(audience_columns, audience_rows)
		
	# 2. Local pool to track who gets a seat (Duplicate to avoid modifying global state)
	var available_pool = GameManager.audience_members.duplicate()
	
	# 3. Setup positioning math
	var screen_size = get_viewport_rect().size
	var zone_size = Vector2(screen_size.x * 1.1, screen_size.y * 0.4)
	var zone_center = Vector2(screen_size.x * 0.5, screen_size.y * 0.7)
	var zone_top_left = zone_center - (zone_size / 2.0)
	var spacing_x = zone_size.x / audience_columns
	var spacing_y = zone_size.y / audience_rows
	var uniform_scale = min((spacing_x / original_sprite_width) * 0.9, (spacing_y / original_sprite_height) * 0.9)
	
	# 4. Instantiate all seats first and leave them empty
	var all_seats = []
	for y in range(audience_rows):
		for x in range(audience_columns):
			var audience = AudienceScene.instantiate()
			add_child(audience)
			audience.scale = Vector2(uniform_scale, uniform_scale)
			audience.position = zone_top_left + Vector2((x * spacing_x) + (spacing_x * 0.5 if y % 2 == 1 else 0.0), y * spacing_y)
			audience.set_filled(false)
			all_seats.append(audience)
			
	# 5. Fill seats based on the pre-calculated priority order
	for coord in GameManager.seat_priority_order:
		# Stop if we run out of viewers to place
		if available_pool.is_empty(): 
			break
		
		# Calculate flat index to find the seat in our all_seats array
		var seat_index = coord.y * audience_columns + coord.x
		
		# Safety check: ensure the seat index exists
		if seat_index >= 0 and seat_index < all_seats.size():
			var chosen_viewer = available_pool.pop_front()
			
			# CRITICAL SAFETY: Only call setup_type if data is a valid Dictionary
			if typeof(chosen_viewer) == TYPE_DICTIONARY:
				all_seats[seat_index].setup_type(chosen_viewer)
			else:
				push_warning("Audience pool contained invalid data (not a dictionary): ", chosen_viewer)
