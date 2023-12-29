extends Button

@export var menu : Control
@export var classification: String
@export var buttonName : String
@export var description : String
@export var path : String
@export var delay: float

func _on_mouse_entered():
	if GameManager.hasControl():
		AudioManager.playSound("res://Assets/SFX/Change.wav",-10,2.24,0)
		GameManager.buttonSelection = self
		get_parent().texture = load("res://Assets/"+path+"/"+buttonName+"^.png")
		if classification == "stageSelect":	
			if description != "":
				menu.stageSelectDescription.text = description
				menu.stageSelectDescription.visible_ratio = 0
		elif classification == "mainMenu":	
			if description != "":
				menu.mainMenuDescription.text = description
				menu.mainMenuDescription.visible_ratio = 0
			
			if buttonName == "myRobot":
				menu.previewMech.visible = true


func _on_mouse_exited():
	if GameManager.hasControl():
		get_parent().texture = load("res://Assets/"+path+"/"+buttonName+"_.png")
		if buttonName == "myRobot":
			menu.previewMech.visible = false


func _on_pressed():
	await get_tree().create_timer(delay).timeout
	get_parent().texture = load("res://Assets/"+path+"/"+buttonName+"_.png")
