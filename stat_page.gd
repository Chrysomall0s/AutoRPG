extends Control

@export var statsbook_font_ratio: float = 0.02
@export var reference_height: float = 1080.0
# Now treated as a percentage multiplier (e.g., -0.2 is 20% of screen width to the left)
@export var horizontal_offset: float = -0.1

var stats_container: VBoxContainer
var current_page_index: int = 0
var margin_node: MarginContainer 

var pages = [
	{"title": "Tutorial (1/16)", "body": "This is an early demo for an auto JRPG Battler."},
	{"title": "Tutorial (2/16)", "body": "Pick a character. They are your squire. You want to make a hero out of them."},
	{"title": "Tutorial (3/16)", "body": "Select a difficulty tournament and equip them with gear in the shop."},
	{"title": "Tutorial (4/16)", "body": "Survive 10 rounds and voila... they are your champions!"},
	{"title": "Tutorial (5/16)", "body": "Looking for tips? The weapons in the shop can be merged if they are the same type."},
	{"title": "Tutorial (6/16)", "body": "You can hold and drag items to equip or move them around."},
	{"title": "Feedback (7/16)", "body": "We are mainly looking in this stage to find the fun.\n\nWhat if weapon slots had different curses?"},
	{"title": "Feedback (8/16)", "body": "What if each fight had a special scene?\n\nFor example: fighting in a forest might buff fire attacks!"},
	{"title": "Tutorial (9/16)", "body": "This is an early demo for an auto JRPG Battler."},
	{"title": "Tutorial (10/16)", "body": "Pick a character. They are your squire. You want to make a hero out of them."},
	{"title": "Tutorial (11/16)", "body": "Select a difficulty tournament and equip them with gear in the shop."},
	{"title": "Tutorial (12/16)", "body": "Survive 10 rounds and voila... they are your champions!"},
	{"title": "Tutorial (13/16)", "body": "Looking for tips? The weapons in the shop can be merged if they are the same type."},
	{"title": "Tutorial (14/16)", "body": "You can hold and drag items to equip or move them around."},
	{"title": "Feedback (15/16)", "body": "We are mainly looking in this stage to find the fun.\n\nWhat if weapon slots had different curses?"},
	{"title": "Feedback (16/16)", "body": "Enjoy!"}
	
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
	
	# Base font size (increased multiplier from 1x to 2x for base text)
	var font_size = int(vp_size.y * statsbook_font_ratio * 2)

	var flip_button = Button.new()
	flip_button.text = "NEXT PAGE"
	flip_button.pressed.connect(flip_page)
	# Doubled the button height
	flip_button.custom_minimum_size.y = font_size * 4 
	# Applied the new larger font size to the button
	flip_button.add_theme_font_size_override("font_size", font_size)
	stats_container.add_child(flip_button)

	var title = Label.new()
	title.text = page["title"]
	# Doubled the title scale (previously 2x, now 4x relative to original)
	title.add_theme_font_size_override("font_size", int(font_size * 2))
	stats_container.add_child(title)

	var body = Label.new()
	body.text = page["body"]
	# Applied the new larger font size
	body.add_theme_font_size_override("font_size", font_size)
	body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_container.add_child(body)

func flip_page():
	current_page_index = (current_page_index + 1) % pages.size()
	update_display()
