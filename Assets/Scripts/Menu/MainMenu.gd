extends Control

#animators
@export var animTitle: AnimationPlayer
@export var animMain: AnimationPlayer
@export var animStage: AnimationPlayer
#buttons
@export var myRobot: TextureRect
@export var online: TextureRect
@export var training: TextureRect
@export var trials: TextureRect
@export var options: TextureRect
#other
@export var previewMech: Node3D
@export var previewMechSkeleton: Node3D
@export var mainMenuDescription: RichTextLabel
@export var stageSelectDescription: RichTextLabel
@export var press: TextureRect #press play titlescreen image
@export var offset: Control #used as the parent when spawning new UI elements
@export var SFX1: AudioStreamPlayer
@export var SFX2: AudioStreamPlayer
# Called when the node enters the scene tree for the first time.
func _ready():
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
#transitions to main menu layout
func main():
	GameManager.gamemode = -1
	GameManager.buttonSelection = null
	mainMenuDescription.text = "Welcome, cadet! It is always good to see you!"
	mainMenuDescription.visible_ratio = 0
	GameManager.waiting = true
	animMain.play("mainMenuIN")
	var t = 0.0
	while(!GameManager.buttonSelection and t<1):
		t+= 1.0/30
		await get_tree().process_frame
	GameManager.waiting = false

func stageSelect():
	GameManager.buttonSelection = null
	stageSelectDescription.text = "SELECT A STAGE"
	stageSelectDescription.visible_ratio = 0
	GameManager.waiting = true
	animStage.play("stageSelectIN")
	GameManager.waiting = false

func _on_back_button_pressed():
	if!GameManager.hasControl():
		return
	match GameManager.gamemode:
		-1: #we are on main menu so go to title
			title()
		0: #we are on stage select so go to main menu
			animStage.play("stageSelectOUT")
			main()

func _on_training_button_pressed():
	if!GameManager.hasControl():
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	GameManager.gamemode = 0 #training
	await get_tree().create_timer(.2).timeout
	animMain.play("mainMenuOUT")
	stageSelect()
	#loadStage("Valley")

func _on_options_button_pressed():
	if!GameManager.hasControl() or GameManager.optionsMenu:
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
	GameManager.loadScene("Valley/Valley")


func _on_test_button_pressed():
	if!GameManager.hasControl():
		return
	GameManager.waiting = true
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	animTitle.play("fadeToBlack")
	GameManager.loadScene("Test")
