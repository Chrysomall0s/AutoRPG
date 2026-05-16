extends Node

#Code 0000 X_YY_Z

#X
#8horns
#7hair
#6Armour
#5Clothes
#4base
#3Flying
#2Around
#1Skin

#YY Name

#Z is later

var upgrades = [
	{"name": "Breastplate", "type": "speed", "value": 2, "weight": 120, "cost": 1, "icon": "res://Assets/Mods/Armour/Breastplate.png", "layer": 6000, "is_equip": false},
	{"name": "Earring", "type": "hp", "value": 10, "weight": 40, "cost": 1, "icon": "res://Assets/Mods/Armour/Earring.png", "layer": 6000, "is_equip": false},
	{"name": "Gauntlets", "type": "damage", "value": 5, "weight": 30, "cost": 2, "icon": "res://Assets/Mods/Armour/Gauntlets.png", "layer": 6000, "is_equip": false},
	{"name": "Helmet", "type": "heal", "value": 0, "weight": 20, "cost": 1, "icon": "res://Assets/Mods/Armour/Helmet.png", "layer": 6000, "is_equip": false},
	
	{"name": "Sword", "type": "heal", "value": 0, "weight": 20, "cost": 1, "icon": "res://Assets/Weapons/Sword", "layer": 9000, "is_equip": true},
	{"name": "Bow", "type": "heal", "value": 0, "weight": 20, "cost": 1, "icon": "res://Assets/Weapons/Bow", "layer": 9000, "is_equip": true},
	{"name": "Staff", "type": "heal", "value": 0, "weight": 20, "cost": 1, "icon": "res://Assets/Weapons/Staff", "layer": 9000, "is_equip": true},
	
	{"name": "Character1", "type": "heal", "value": 0, "weight": 0, "cost": 1, "icon": "res://Assets/Mods/Faces/Character1.png", "layer": 0, "is_equip": false},
 	{"name": "Character2", "type": "heal", "value": 0, "weight": 20, "cost": 1, "icon": "res://Assets/Mods/Faces/Character2.png", "layer": 0, "is_equip": false}
]
