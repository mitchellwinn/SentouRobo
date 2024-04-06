extends TextureRect

var activeTab: Control
@export var general: Control
@export var generalTab: TextureRect
@export var audio: Control
@export var audioTab: TextureRect
@export var video: Control
@export var videoTab: TextureRect
@export var bgVideo: VideoStreamPlayer
@export var textTitle: RichTextLabel
@export var masterVolumeSlider: HSlider
@export var masterVolumeValue: RichTextLabel
@export var sfxVolumeSlider: HSlider
@export var sfxVolumeValue: RichTextLabel
@export var musicVolumeSlider: HSlider
@export var musicVolumeValue: RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	masterVolumeSlider.value = AudioManager.volumeMixdB
	sfxVolumeSlider.value = AudioManager.sfxMixdB
	musicVolumeSlider.value = AudioManager.musicMixdB
	activeTab = general
	multiplayer.server_disconnected.connect(_on_back_button_pressed)
	displayActiveTab()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	if bgVideo.stream_position>.5:
		bgVideo.stream_position = 0
		bgVideo.play()
	if activeTab == audio:
		adjustAudioAmounts()

func adjustAudioAmounts():
	#master
	AudioManager.volumeMixdB = masterVolumeSlider.value
	if AudioManager.volumeMixdB == masterVolumeSlider.min_value:
		AudioManager.volumeMixdB =  -999
		masterVolumeValue.text = "[right]"+"-∞"
	else:
		masterVolumeValue.text = "[right]"+str(AudioManager.volumeMixdB)
	#sfx
	AudioManager.sfxMixdB = sfxVolumeSlider.value
	if AudioManager.sfxMixdB == sfxVolumeSlider.min_value:
		AudioManager.sfxMixdB =  -999
		sfxVolumeValue.text = "[right]"+"-∞"
	else:
		sfxVolumeValue.text = "[right]"+str(AudioManager.sfxMixdB)
	#music
	AudioManager.musicMixdB = musicVolumeSlider.value
	if AudioManager.musicMixdB == musicVolumeSlider.min_value:
		AudioManager.musicMixdB =  -999
		musicVolumeValue.text = "[right]"+"-∞"
	else:
		musicVolumeValue.text = "[right]"+str(AudioManager.musicMixdB)

func displayActiveTab():
	general.visible = false
	generalTab.position.x = 2000 +113.333
	audio.visible = false
	audioTab.position.x = 2000 +113.333
	video.visible = false
	videoTab.position.x = 2000 +113.333
	activeTab.visible = true
	match activeTab:
		general:
			textTitle.text = "[center]"+get_tree().get_current_scene().get_name()+"[/center]"
			generalTab.position.x = 2160 +113.333
		audio:
			audioTab.position.x = 2160 +113.333
		video:
			videoTab.position.x = 2160 +113.333 
			
#----------------------------------------------
#-------DETERMINE ACTIVE TAB-------------------
#----------------------------------------------
func _on_general_button_pressed():
	activeTab = general
	displayActiveTab()

func _on_audio_button_pressed():
	activeTab = audio
	displayActiveTab()

func _on_video_button_pressed():
	activeTab = video
	displayActiveTab()
#-------GENERAL TAB-----------------------------
func _on_back_button_pressed():
	#close options menu
	GameManager.optionsMenu = false
	GameManager.saveData()
	queue_free()
	
func _on_exit_button_pressed():
	#close options menu
	#GameManager.myRobot.UIAnimator.play("fadeToBlack")
	GameManager.mainMenu.animTitle.play("fadeToBlack")
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	await get_tree().create_timer(1).timeout
	if multiplayer.multiplayer_peer != null:
			print("disconnect attempt")
			#GameManager.myRobot.queue_free()
			GameManager.menu.network.remove_multiplayer_peer()
			GameManager.menu.network.clearConnectionList()
	GameManager.optionsMenu = false
	GameManager.saveData()
	
	#go to title
	if GameManager.gamemode >= 0:
		GameManager.menu.network.level.currentStage = null
		for player in GameManager.players.get_children():
			player.queue_free()
		GameManager.waiting = true
		GameManager.gamemode = -1
		GameManager.clear_level()
		GameManager.menu.network.showUI()
		GameManager.menu.title()
	else:
		GameManager.waiting = true
		GameManager.menu.animOnline.play("onlineROOM_OUT")
		GameManager.mainMenu.animTitle.play("fadeToBlack")
		await get_tree().create_timer(1).timeout
		GameManager.waiting = false
		GameManager.mainMenu.title()
	queue_free()
