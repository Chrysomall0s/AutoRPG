extends Area2D

signal dropped_on(target_node)

var is_dragging: bool = false
var is_enabled: bool = false
var drag_offset: Vector2 = Vector2.ZERO

func _input_event(viewport, event, shape_idx):
	if not is_enabled: return
	
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_dragging = true
			drag_offset = global_position - get_global_mouse_position()
		else:
			is_dragging = false
			check_drop()

func _process(delta):
	if is_dragging:
		global_position = get_global_mouse_position() + drag_offset

func check_drop():
	# Detect if we dropped over another weapon
	var overlapping_areas = get_overlapping_areas()
	for area in overlapping_areas:
		if area != self:
			dropped_on.emit(area)
