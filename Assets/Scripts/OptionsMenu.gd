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
	generalTab.position.x = 2000
	audio.visible = false
	audioTab.position.x = 2000
	video.visible = false
	videoTab.position.x = 2000
	activeTab.visible = true
	match activeTab:
		general:
			textTitle.text = "[center]"+get_tree().get_current_scene().get_name()+"[/center]"
			generalTab.position.x = 2160 
		audio:
			audioTab.position.x = 2160 
		video:
			videoTab.position.x = 2160 
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
	GameManager.optionsMenu = false
	GameManager.saveData()
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	await get_tree().create_timer(.5).timeout
	#go to title
	if get_tree().get_current_scene().get_name() != "Menu":
		GameManager.waiting = true
		GameManager.gamemode = -1
		GameManager.myRobot.UIAnimator.play("fadeToBlack")
		GameManager.loadScene("Menu")
		await get_tree().create_timer(1).timeout
	else:
		GameManager.waiting = true
		GameManager.mainMenu.animTitle.play("fadeToBlack")
		await get_tree().create_timer(1).timeout
		GameManager.waiting = false
		GameManager.mainMenu.title()
	queue_free()
