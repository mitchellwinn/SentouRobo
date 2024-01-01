extends Node

const HP_MAX = 100
const SHIELD_MAX = 100
var hp
var shield

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	statsCheck()
	pass

func statsCheck():
	hp = clamp(hp,0,HP_MAX)
	shield = clamp(shield,0,SHIELD_MAX)
