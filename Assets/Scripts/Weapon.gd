#Weapon.gd
extends Part

class_name Weapon

var leftRight
var hitscan: bool
var damage
var shieldDamage
var knockback

func _init(_inGameName,_leftRight,_name,_category,_weight,_hitscan,_damage,_shieldDamage,_knockback):
	inGameName = _inGameName
	partName = _name
	partCategory = _category
	partWeight = _weight
	leftRight = _leftRight
	hitscan = _hitscan
	damage = _damage
	shieldDamage = _shieldDamage
	knockback = _knockback
