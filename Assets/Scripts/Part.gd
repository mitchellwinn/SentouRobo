#Part.gd
extends Resource

class_name Part

var partName: String
var partCategory: String
var partWeight: int

func _init(_name,_category,_weight):
	partName = _name
	partCategory = _category
	partWeight = _weight
