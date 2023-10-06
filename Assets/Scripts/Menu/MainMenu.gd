extends Control

@export var animPlay: AnimationPlayer
@export var press: TextureRect
var waiting = true

# Called when the node enters the scene tree for the first time.
func _ready():
	title()

func hasControl():
	if waiting:
		return false
	return true

func title():
	waiting = true
	animPlay.play("titleIN")
	await get_tree().create_timer(2).timeout #wait length of animation before yielding control
	waiting = false
	while(!PlayerInput.confirm):
		if (Time.get_ticks_msec()%1000)>500:
			press.modulate = Color(1,1,1,1)
		else:
			press.modulate = Color(1,1,1,0)
		await get_tree().process_frame
	var t = 0.0
	animPlay.play("titleOUT")
	while(t<1.75):
		t+=1.0/60
		if ((Time.get_ticks_msec()*16)%1000)>500:
			press.modulate = Color(1,1,1,1)
		else:
			press.modulate = Color(1,1,1,0)
		await get_tree().process_frame
	press.modulate = Color(1,1,1,0)
