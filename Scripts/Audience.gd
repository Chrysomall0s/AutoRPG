extends Area2D

@onready var seat = $Seat
@onready var person = $Person

var is_filled := false

func _init():
	print("INIT CALLED:", name)
	print("THIS NODE IS:", self.name)
	print("CLASS:", self.get_class())
	print("=== AUDIENCE CHILDREN ===")
	for child in get_children():
		print(child.name, " - ", child.get_class())
	if seat == null:
		print("ERROR: Seat node not found!")

	if person == null:
		print("ERROR: Person node not found!")

func _ready():
	print("THIS NODE IS:", self.name)
	print("CLASS:", self.get_class())
	print("=== AUDIENCE CHILDREN ===")
	for child in get_children():
		print(child.name, " - ", child.get_class())
	if seat == null:
		print("ERROR: Seat node not found!")

	if person == null:
		print("ERROR: Person node not found!")

func set_filled(value: bool):
	is_filled = value

	if is_filled:
		person.visible = true
		seat.modulate = Color(1, 1, 1)
	else:
		person.visible = false
		seat.modulate = Color(0.5, 0.5, 0.5)


func person_comes():
	person.visible = true
	is_filled = true


func person_leaves():
	person.visible = false
	is_filled = false
