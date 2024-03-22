extends Node3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	$Icosphere.rotate(basis.y.normalized(), delta*.1)
	$Icosphere_001.rotate(basis.y.normalized(), -delta*.2)
