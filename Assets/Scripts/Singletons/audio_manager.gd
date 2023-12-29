extends Node

var volumeMixdB = 0
var sfxMixdB = 0
var musicMixdB = 0
var rng = RandomNumberGenerator.new()

func playSound(path,volume,pitch,pitchRandomize):
	var sound = load(path)
	var sfx
	sfx = preload("res://Assets/Prefabs/SFX.tscn")
	var sfxInstance = sfx.instantiate()
	get_node("/root").add_child(sfxInstance)
	sfxInstance.stream = sound
	sfxInstance.volume_db = volume+volumeMixdB+sfxMixdB
	sfxInstance.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
	sfxInstance.play()
	await get_tree().create_timer(2.0).timeout
	sfxInstance.queue_free()
	
