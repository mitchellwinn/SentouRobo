extends Control

#animators
@export var animTitle: AnimationPlayer
@export var animMain: AnimationPlayer
@export var animStage: AnimationPlayer
@export var animOnline: AnimationPlayer
#buttons
@export var myRobot: TextureRect
@export var online: TextureRect
@export var training: TextureRect
@export var trials: TextureRect
@export var options: TextureRect
@export var host: TextureRect
@export var join: TextureRect
#other
@export var network: Node
#@export var menuBG1: VideoStreamPlayer
#@export var menuBG2: VideoStreamPlayer
#@export var menuBG3: VideoStreamPlayer
#@export var menuBG4: VideoStreamPlayer
@export var previewMech: Node3D
@export var earth: Node3D
@export var previewMechSkeleton: Node3D
@export var mainMenuDescription: RichTextLabel
@export var stageSelectDescription: RichTextLabel
@export var press: TextureRect #press play titlescreen image
@export var offset: Control #used as the parent when spawning new UI elements
@export var SFX1: AudioStreamPlayer
@export var SFX2: AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.menu = self
	GameManager.players = $Players
	RenderingServer.set_default_clear_color(Color(0.38431372549,0.38431372549,0.38431372549,1))
	GameManager.gamemode = -1 #menuScreens
	GameManager.mainMenu = self
	GameManager.waiting = false
	GameManager.updatePartGraphics(previewMechSkeleton)
	title()
 
func _physics_process(delta):
	previewMech.get_node("AnimationPlayer").play("idle")
	mainMenuDescription.visible_ratio += 1.0/30
	stageSelectDescription.visible_ratio += 1.0/30

#transitions to title screen
#waits for input on the title screen before calling main()
func title():
	AudioManager.stop_song.emit()
	AudioManager.currentMusicPath = ""
	#if !menuBG1.is_playing():
	#	menuBG1.play()
	#	menuBG1.loop = true
	SFX1.volume_db = AudioManager.volumeMixdB+AudioManager.sfxMixdB
	SFX2.volume_db = SFX1.volume_db
	GameManager.waiting = true
	animTitle.play("titleIN")
	await get_tree().create_timer(1.5).timeout #wait length of animation before yielding control
	GameManager.waiting = false
	while !Input.is_action_pressed("confirm"):
		if (Time.get_ticks_msec()%1000)>500:
			press.modulate = Color(1,1,1,1)
		else:
			press.modulate = Color(1,1,1,0)
		await get_tree().process_frame
	var t = 0.0
	animTitle.play("titleOUT")
	main()
	while(t<1):
		t+=1.0/60
		if ((Time.get_ticks_msec()*16)%1000)>500:
			press.modulate = Color(1,1,1,1)
		else:
			press.modulate = Color(1,1,1,0)
		await get_tree().process_frame
	press.modulate = Color(1,1,1,0)
	#menuBG1.call_deferred("stop")
#transitions to main menu layout
func main():
	previewMech.get_node("AnimationPlayer").play("idle")
	AudioManager.playMusic("res://Assets/Music/rainloop.wav",-20,1,0)
	#if !menuBG2.is_playing():
	#	menuBG2.loop = true
	#	menuBG2.play()
	GameManager.waiting = true
	GameManager.gamemode = -1
	GameManager.buttonSelection = null
	mainMenuDescription.text = "Welcome, cadet! It is always good to see you!"
	mainMenuDescription.visible_ratio = 0
	animMain.play("mainMenuIN")
	await get_tree().create_timer(.3).timeout
	GameManager.waiting = false
	#menuBG1.stop()

func onlineMenu():
	AudioManager.playMusic("res://Assets/Music/Flamenco Graffiti.mp3",-20,1,0)
	#if !menuBG3.is_playing():
	#	menuBG3.loop = true
	#	menuBG3.play()
	GameManager.waiting = true
	GameManager.gamemode = -2
	#GameManager.buttonSelection = null
	await get_tree().create_timer(.3).timeout
	GameManager.waiting = false
	#menuBG2.stop()
	
func enterIP():
	#if !menuBG3.is_playing():
	#	menuBG3.loop = true
	#	menuBG3.play()
	GameManager.waiting = true
	GameManager.gamemode = -3
	#GameManager.buttonSelection = null
	animOnline.play("onlineJOIN")
	await get_tree().create_timer(.4).timeout
	GameManager.waiting = false
	#menuBG2.stop()

func onlineRoom():
	GameManager.activePlayerName = network.nameEntry.text
	#if !menuBG4.is_playing():
	#	menuBG4.loop = true
	#	menuBG4.play()
	GameManager.waiting = true
	GameManager.gamemode = -4
	#GameManager.buttonSelection = null
	animOnline.play("onlineROOM")
	animMain.play("onlineJOIN_OUT")
	await get_tree().create_timer(.4).timeout
	GameManager.waiting = false
	#menuBG3.stop()

func stageSelect():
	GameManager.buttonSelection = null
	stageSelectDescription.text = "SELECT A STAGE"
	stageSelectDescription.visible_ratio = 0
	GameManager.waiting = true
	animStage.play("stageSelectIN")
	GameManager.waiting = false

func _on_back_button_pressed():
	goBack()

func goBack():
	if!GameManager.hasControl():
		return
	if GameManager.buttonSelection.get_parent() !=null:
		GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	match GameManager.gamemode:
		-4: #we are on online room menu so go to online menu
			onlineMenu()
			network.remove_multiplayer_peer()
			animOnline.play("onlineROOM_OUT")
		-3: #we are on enterIP menu so go to online menu
			onlineMenu()
			animOnline.play("onlineJOIN_OUT")
		-2: #we are on online menu so go to main menu
			animOnline.play("onlineOUT")
			main()
		-1: #we are on main menu so go to title
			title()
		0: #we are on stage select so go to main menu
			animStage.play("stageSelectOUT")
			main()

func _on_training_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-1:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	GameManager.gamemode = 0 #training
	await get_tree().create_timer(.2).timeout
	animMain.play("mainMenuOUT")
	stageSelect()
	#loadStage("Valley")

func _on_options_button_pressed():
	if!GameManager.hasControl() or GameManager.optionsMenu or GameManager.gamemode!=-1:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav",)
	GameManager.optionsMenu = true
	GameManager.spawnChild(offset,"OptionsMenu","res://Assets/Prefabs/Options.tscn",Vector2(1200,135),0,Vector2(.15*4.166,.15*4.166))


func _on_valley_button_pressed():
	if!GameManager.hasControl():
		return
	GameManager.waiting = true
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	animTitle.play("fadeToBlack")
	await get_tree().create_timer(1).timeout
	GameManager.loadScene("ValleyNew")
	network.level.spawn_mech(1,0)


func _on_test_button_pressed():
	if!GameManager.hasControl():
		return
	GameManager.waiting = true
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	animTitle.play("fadeToBlack")
	await get_tree().create_timer(1).timeout
	GameManager.loadScene("Test")
	network.level.spawn_mech(1,0)

func _on_join_button_pressed():
	if network.nameEntry.text.strip_edges(true,true) == "":
		return
	match GameManager.gamemode:
		-4,-3:
			return
	if!GameManager.hasControl():
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	await get_tree().create_timer(.2).timeout
	enterIP()


func _on_online_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-1:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	await get_tree().create_timer(.2).timeout
	animMain.play("mainMenuOUT")
	onlineMenu()
	animOnline.play("onlineIN")
	#loadStage("Valley")

