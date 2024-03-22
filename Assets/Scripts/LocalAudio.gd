extends Node3D

@export var sfx1: AudioStreamPlayer3D
@export var sfx2: AudioStreamPlayer3D
@export var sfx3: AudioStreamPlayer3D
@export var sfxConstant1: AudioStreamPlayer3D
@export var sfxConstant2: AudioStreamPlayer3D
var rng = RandomNumberGenerator.new()


@rpc("any_peer", "reliable", "call_local")
func play(path, volume, pitch, pitchRandomize):
	var sfx
	sfx = preload("res://Assets/Prefabs/SFX3D.tscn")
	var sfxInstance = sfx.instantiate()
	add_child(sfxInstance)
	sfxInstance.position = Vector3.ZERO
	sfxInstance.stream = load(path)
	sfxInstance.volume_db = volume+AudioManager.volumeMixdB+AudioManager.sfxMixdB
	sfxInstance.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
	sfxInstance.play()
	await get_tree().create_timer(2.0).timeout
	sfxInstance.queue_free()

@rpc("any_peer", "reliable", "call_local")
func playConstant(path, volume, pitch, pitchRandomize, channel):
	var sfx
	match channel:
		1:
			sfx = sfxConstant1
		2:
			sfx = sfxConstant2
	sfx.stream = load(path)
	sfx.volume_db = volume+AudioManager.volumeMixdB+AudioManager.sfxMixdB
	sfx.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
	sfx.play()
	
@rpc("any_peer", "reliable", "call_local")
func stopConstant(channel):
	var sfx
	match channel:
		1:
			sfx = sfxConstant1
		2:
			sfx = sfxConstant2
	sfx.playing = false

@rpc("any_peer", "reliable", "call_local")	
func stopAll():
	sfxConstant1.playing=false
	sfxConstant2.playing=false
