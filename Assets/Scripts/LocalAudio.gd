extends Node3D

@export var sfx1: AudioStreamPlayer3D
@export var sfx2: AudioStreamPlayer3D
@export var sfx3: AudioStreamPlayer3D
@export var sfxConstant1: AudioStreamPlayer3D
@export var sfxConstant2: AudioStreamPlayer3D
var alternation = 1
@onready var volumeMixdB = AudioManager.volumeMixdB
var rng = RandomNumberGenerator.new()

func play(path, volume, pitch, pitchRandomize):
	var sfx
	match alternation:
		1:
			sfx = sfx1
			alternation = 2
		2:
			sfx = sfx2
			alternation = 3
		3:
			sfx = sfx3
			alternation = 1
	sfx.stream = load(path)
	sfx.volume_db = volume+volumeMixdB
	sfx.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
	sfx.play()

func playConstant(path, volume, pitch, pitchRandomize, channel):
	var sfx
	match channel:
		1:
			sfx = sfxConstant1
		2:
			sfx = sfxConstant2
	sfx.stream = load(path)
	sfx.volume_db = volume+volumeMixdB
	sfx.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
	sfx.play()
	
func stopConstant(channel):
	var sfx
	match channel:
		1:
			sfx = sfxConstant1
		2:
			sfx = sfxConstant2
	sfx.playing = false
	
func stopAll():
	sfxConstant1.playing=false
	sfxConstant2.playing=false
	sfx1.playing=false
	sfx2.playing=false
