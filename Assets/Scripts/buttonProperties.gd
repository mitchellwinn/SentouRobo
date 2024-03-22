extends Button

@export var menu : Control
@export var classification: String
@export var buttonName : String
@export var description : String
@export var path : String
@export var delay: float

func _on_mouse_entered():
	if true:
		if GameManager.buttonSelection != null:
			GameManager.buttonSelection.get_parent().texture = load("res://Assets/"+GameManager.buttonSelection.path+"/"+GameManager.buttonSelection.buttonName+"_.png")
		AudioManager.playSound("res://Assets/SFX/Change.wav",-10,2.5,1)
		GameManager.buttonSelection = self
		get_parent().texture = load("res://Assets/"+path+"/"+buttonName+"^.png")
		if classification == "stageSelect":	
			if description != "":
				menu.stageSelectDescription.text = description
				menu.stageSelectDescription.visible_ratio = 0
		elif classification == "mainMenu":	
			if !GameManager.hasControl():
				return
			if description != "":
				menu.mainMenuDescription.text = description
				menu.mainMenuDescription.visible_ratio = 0
			if buttonName.substr(0,4) != "back":
				menu.earth.visible = false
				menu.previewMech.visible = false
			if buttonName == "myRobot":
				menu.previewMech.visible = true
			elif buttonName == "online":
				menu.earth.visible = true
		match GameManager.gamemode:
			-2,-3:
				menu.earth.visible = true
func _on_mouse_exited():
	if GameManager.hasControl():
		get_parent().texture = load("res://Assets/"+path+"/"+buttonName+"_.png")

func _on_pressed():
	await get_tree().create_timer(delay).timeout
	get_parent().texture = load("res://Assets/"+path+"/"+buttonName+"_.png")
