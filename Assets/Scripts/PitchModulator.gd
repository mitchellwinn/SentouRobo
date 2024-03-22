extends AudioStreamPlayer3D


# Called when the node enters the scene tree for the first time.
func _ready():
	pitch_scale  =  RandomNumberGenerator.new().randf_range(.9,1.4)
	volume_db = -20+AudioManager.volumeMixdB+AudioManager.sfxMixdB


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
