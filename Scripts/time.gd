extends Node

var controller_node: Control

func setup_time_controls(parent: Control, x_offset_ratio: float, y_offset_ratio: float, gap_ratio: float, w_ratio: float, h_ratio: float):
	controller_node = parent
	var screen_size = controller_node.get_viewport_rect().size
	var start_pos = Vector2(screen_size.x * x_offset_ratio, screen_size.y * y_offset_ratio)
	var gap = screen_size.x * gap_ratio
	
	_create_btn("Pause", _pause, start_pos + Vector2(gap * 0, 0), w_ratio, h_ratio)
	_create_btn("Slow", _slow, start_pos + Vector2(gap * 1, 0), w_ratio, h_ratio)
	_create_btn("Normal", _normal, start_pos + Vector2(gap * 2, 0), w_ratio, h_ratio)
	_create_btn("Fast", _fast, start_pos + Vector2(gap * 3, 0), w_ratio, h_ratio)

func _create_btn(text: String, callback: Callable, pos: Vector2, w_ratio: float, h_ratio: float):
	var btn = Button.new()
	btn.text = text
	var screen_size = controller_node.get_viewport_rect().size
	btn.custom_minimum_size = Vector2(screen_size.x * w_ratio, screen_size.y * h_ratio)
	btn.position = pos
	btn.pressed.connect(callback)
	controller_node.add_child(btn)

func _pause(): Engine.time_scale = 0.0
func _slow(): Engine.time_scale = 0.5
func _normal(): Engine.time_scale = 1.0
func _fast(): Engine.time_scale = 2.0
