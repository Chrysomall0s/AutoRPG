extends Node2D

@export_group("Grid Settings")
@export var audience_columns: int = 20
@export var audience_rows: int = 6

@export_group("Spacing & Sizing (Percentage of Screen)")
@export var seat_size: float = 0.042    # 5% of screen width
@export var gap_x: float = 0.01       # 1% of screen width
@export var gap_y: float = -0.04       # 2% of screen height
@export var starting_y: float = 0.77  # Starts 20% down from top

@onready var AudienceScene = preload("res://Scenes/Audience.tscn")

func populate_audience():
	# 1. Cleanup
	for child in get_children():
		child.queue_free()

	# 2. Setup Screen Math
	var screen_size = get_viewport_rect().size
	var seat_px = screen_size.x * seat_size
	var gap_x_px = screen_size.x * gap_x
	var gap_y_px = screen_size.y * gap_y
	var row_width = (audience_columns * seat_px) + ((audience_columns - 1) * gap_x_px)
	var start_x = (screen_size.x / 2.0) - (row_width / 2.0)
	var start_y = screen_size.y * starting_y

	# 3. Instantiate all seats
	var all_seats = []
	for y in range(audience_rows):
		var row_offset = (seat_px * 0.5) if (y % 2 != 0) else 0.0
		for x in range(audience_columns):
			var seat = AudienceScene.instantiate()
			add_child(seat)
			var scale_factor = seat_px / 44.0
			seat.scale = Vector2(scale_factor, scale_factor)
			seat.position = Vector2(start_x + (x * (seat_px + gap_x_px)) + row_offset, start_y + (y * (seat_px + gap_y_px)))
			seat.z_index = y
			seat.set_filled(false)
			all_seats.append(seat)

  # 4. RANDOMIZED "THOUSAND-YEAR DOOR" POPULATION
	var pool = GameManager.player_profile.get("audience", []) + GameManager.current_enemy_profile.get("audience", [])
	var player_count = GameManager.player_profile.get("audience", []).size()
	
	# Keep track of which seats are filled so we can calculate proximity
	var filled_seats = []
	var seat_scores = []
	
	# First, generate base scores for all seats (excluding edges)
	for i in range(all_seats.size()):
		var x = i % audience_columns
		var y = i / audience_columns
		
		# Skip edge seats (column 0 and last column)
		if x == 0 or x == audience_columns - 1:
			continue
		
		# 1. Front row bias: (Higher weight)
		var front_bias = (audience_rows - y) * 2000
		# 2. Center bias:
		var dist_from_center = abs(x - (audience_columns / 2.0))
		var center_bias = (audience_columns / 2.0 - dist_from_center) * 500
		# 3. HIGH RANDOMNESS: This allows people to sit "far away" randomly
		var randomness = randi_range(0, 3000) 
		
		seat_scores.append({"index": i, "score": front_bias + center_bias + randomness})

	# Sort by score descending
	seat_scores.sort_custom(func(a, b): return a.score > b.score)
	
	# Fill seats
	for item in seat_scores:
		if pool.is_empty(): break
		var idx = item.index
		
		# --- PROXIMITY PENALTY (The "Stranger Danger" logic) ---
		# If we have already filled seats, let's see if this seat is near one.
		# If it's too close to someone else, we reduce its score to encourage 
		# scattering, but we still fill it if the list is exhausted.
		var viewer = pool.pop_front()
		if typeof(viewer) == TYPE_DICTIONARY:
			all_seats[idx].setup_type(viewer, (player_count > 0))
			all_seats[idx].set_filled(true)
			filled_seats.append(idx)
			player_count -= 1
