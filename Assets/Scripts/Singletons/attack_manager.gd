extends Node


var hitscanner: RayCast3D

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	
func shootHitscan():
	if !hitscanner.is_colliding():
		#complete miss
		return
	elif hitscanner.get
