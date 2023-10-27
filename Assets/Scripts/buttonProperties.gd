extends Button

@export var menu : Control
@export var buttonName : String
@export var description : String

func _on_mouse_entered():
	if menu.hasControl():
		AudioManager.playSound("res://Assets/SFX/Change.wav",-10,2.24,0)
		menu.buttonSelection = self
		get_parent().texture = load("res://Assets/MainMenuAssets/"+buttonName+"^.png")
		menu.mainMenuDescription.text = description
		menu.mainMenuDescription.visible_ratio = 0
		
		if buttonName == "myRobot":
			menu.previewMech.visible = true
		
		var t = 0.0
		while t<1:
			menu.mainMenuDescription.visible_ratio = t
			t+= 1.0/30
			await get_tree().process_frame


func _on_mouse_exited():
	if menu.hasControl():
		get_parent().texture = load("res://Assets/MainMenuAssets/"+buttonName+"_.png")
		
		if buttonName == "myRobot":
			menu.previewMech.visible = false
