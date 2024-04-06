#Part.gd
extends Resource

class_name Part

var inGameName: String
var partName: String
var partCategory: String
var partWeight: int

func _init(_inGameName, _name,_category,_weight):
	inGameName = _inGameName
	partName = _name
	partCategory = _category
	partWeight = _weight
