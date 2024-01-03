#Weapon.gd
extends Part

class_name Weapon

var leftRight

func _init(_leftRight,_name,_category,_weight):
	partName = _name
	partCategory = _category
	partWeight = _weight
	leftRight = _leftRight

