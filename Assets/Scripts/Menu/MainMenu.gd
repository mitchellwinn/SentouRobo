extends Control

#animators
@export var animTitle: AnimationPlayer
@export var animMain: AnimationPlayer
#buttons
@export var myRobot: TextureRect
@export var online: TextureRect
@export var training: TextureRect
@export var trials: TextureRect
@export var options: TextureRect
#other
@export var previewMech: Node3D
@export var mainMenuDescription: RichTextLabel
@export var press: TextureRect #press play titlescreen image
var waiting = true
var buttonSelection
# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.gamemode = -1 #menuScreens
	title()
 
func _physics_process(delta):
	previewMech.get_node("AnimationPlayer").play("idle")

func hasControl():
	if waiting or GameManager.gamemode!=-1:
		return false
	return true

#transitions to title screen
#waits for input on the title screen before calling main()
func title():
	waiting = true
	animTitle.play("titleIN")
	await get_tree().create_timer(1.5).timeout #wait length of animation before yielding control
	waiting = false
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
	buttonSelection = null
	mainMenuDescription.text = "Welcome, cadet! It is always good to see you!"
	mainMenuDescription.visible_ratio = 0
	waiting = true
	animMain.play("mainMenuIN")
	var t = 0.0
	while(!buttonSelection and t<1):
		if t>.3:
			mainMenuDescription.visible_ratio = t
		t+= 1.0/30
		await get_tree().process_frame
	waiting = false


func _on_back_button_pressed():
	if!hasControl():
		return
	title()
	

func _on_training_button_pressed():
	if!hasControl():
		return
	buttonFeedback(buttonSelection.get_parent())
	GameManager.gamemode = 0 #training
	await get_tree().create_timer(.7).timeout
	animMain.play("menuOUT")
	animTitle.play("fadeToBlack")
	await get_tree().create_timer(1).timeout
	GameManager.change_scene("res://Assets/Scenes/Harbor.tscn")

func buttonFeedback(button):
	AudioManager.playSound("res://Assets/SFX/MenuSelect1.wav",-10,1,0)
	var t = 0.0
	while(t<1.5):
		t+=1.0/60
		if ((Time.get_ticks_msec()*16)%1000)>500:
			button.modulate = Color(1,1,1,1)
		else:
			button.modulate = Color(1,1,1,0)
		await get_tree().process_frame
	button.modulate = Color(1,1,1,1)
