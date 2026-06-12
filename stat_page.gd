extends Control

@export var statsbook_font_ratio: float = 0.02
@export var reference_height: float = 1080.0
# Now treated as a percentage multiplier (e.g., -0.2 is 20% of screen width to the left)
@export var horizontal_offset: float = -0.1

var stats_container: VBoxContainer
var current_page_index: int = 0
var margin_node: MarginContainer 

var pages = [
	{"title": "Tutorial (1/8)", "body": "This is an early demo for an auto JRPG Battler."},
	{"title": "Tutorial (2/8)", "body": "Pick a character. They are your squire. You want to make a hero out of them."},
	{"title": "Tutorial (3/8)", "body": "Select a difficulty tournament and equip them with gear in the shop."},
	{"title": "Tutorial (4/8)", "body": "Survive 10 rounds and voila... they are your champions!"},
	{"title": "Tutorial (5/8)", "body": "Looking for tips? The weapons in the shop can be merged if they are the same type."},
	{"title": "Tutorial (6/8)", "body": "You can hold and drag items to equip or move them around."},
	{"title": "Feedback (7/8)", "body": "We are mainly looking in this stage to find the fun.\n\nWhat if weapon slots had different curses?"},
	{"title": "Feedback (8/8)", "body": "What if each fight had a special scene?\n\nFor example: fighting in a forest might buff fire attacks!"}
]

func _ready():
	var center_node = CenterContainer.new()
	center_node.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_node)

	margin_node = MarginContainer.new()
	center_node.add_child(margin_node)

	var panel = PanelContainer.new()
	margin_node.add_child(panel)

	stats_container = VBoxContainer.new()
	panel.add_child(stats_container)
	
	get_viewport().size_changed.connect(update_display)
	update_display()

func update_display():
	for child in stats_container.get_children():
		child.queue_free()

	var vp_size = get_viewport_rect().size
	
	# Apply dynamic horizontal offset
	var offset_px = vp_size.x * horizontal_offset
	margin_node.add_theme_constant_override("margin_left", int(offset_px))
	margin_node.add_theme_constant_override("margin_right", int(-offset_px))
	
	stats_container.custom_minimum_size = Vector2(vp_size.x * 0.4, 0)
	
	var page = pages[current_page_index]
	var font_size = int(vp_size.y * statsbook_font_ratio)

	var flip_button = Button.new()
	flip_button.text = "NEXT PAGE"
	flip_button.pressed.connect(flip_page)
	flip_button.custom_minimum_size.y = font_size * 2
	stats_container.add_child(flip_button)

	var title = Label.new()
	title.text = page["title"]
	title.add_theme_font_size_override("font_size", int(font_size * 2))
	stats_container.add_child(title)

	var body = Label.new()
	body.text = page["body"]
	body.add_theme_font_size_override("font_size", font_size)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_container.add_child(body)

func flip_page():
	current_page_index = (current_page_index + 1) % pages.size()
	update_display()
