extends Node

var volumeMixdB = -5
var rng = RandomNumberGenerator.new()

func playSound(path,volume,pitch,pitchRandomize):
	var sound = load(path)
	if get_tree().get_current_scene().get_name() == "Menu":
		var sfx = get_node("/root/Menu/SFX1")
		sfx.stream = sound
		sfx.volume_db = volume+volumeMixdB
		sfx.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
		sfx.play()
		
	
