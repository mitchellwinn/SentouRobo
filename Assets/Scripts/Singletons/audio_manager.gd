extends Node

var musicVolume: int
var volumeMixdB = 0
var sfxMixdB = 0
var musicMixdB = 0
var rng = RandomNumberGenerator.new()
var musicInstance
var currentMusicPath = ""

signal stop_song

func _process(delta):
	if musicInstance != null and musicVolume !=null:
		musicInstance.volume_db = musicVolume+volumeMixdB+musicMixdB

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
	
func stop_songs():
	stop_song.emit()
	
func playMusic(path,volume,pitch,pitchRandomize):
	if path == currentMusicPath:
		return
	stop_song.emit()
	await get_tree().process_frame
	var song = load(path)
	var music
	musicVolume = volume
	currentMusicPath = path
	music = preload("res://Assets/Prefabs/SFX.tscn")
	musicInstance = music.instantiate()
	get_node("/root").add_child(musicInstance)
	musicInstance.stream = song
	musicInstance.volume_db = musicVolume+volumeMixdB+musicMixdB
	musicInstance.pitch_scale = pitch + rng.randf_range(-pitchRandomize,pitchRandomize)
	musicInstance.play()
	await stop_song
	musicInstance.queue_free()
	
