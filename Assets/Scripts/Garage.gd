extends Control

@export var mechSkeleton: Skeleton3D
@export var categorySelection: Sprite2D
@export var colorPicker: ColorPicker
@export var partPicker: TextureRect
var categoryIndex = 0
var colorIndex = 0
var colorPicking = false

# Called when the node enters the scene tree for the first time.
func _ready():
	mechSkeleton = get_parent().get_node("PreviewMech/Armature/Skeleton3D")
	updateLeftMenu()
	updatePartButtons()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	categorySelection.position.y = lerp(categorySelection.position.y,110.415+categoryIndex*250,delta*15)
	if colorPicking:
		GameManager.myRobotData["Color"+str(colorIndex+1)+"r"] = colorPicker.color.r
		GameManager.myRobotData["Color"+str(colorIndex+1)+"g"] = colorPicker.color.g
		GameManager.myRobotData["Color"+str(colorIndex+1)+"b"] = colorPicker.color.b
		GameManager.updateRobotColor(mechSkeleton,GameManager.myRobotData)
	
func updateLeftMenu():
	if colorPicking:
		colorPicker.visible = true
		partPicker.visible = false
	else:
		colorPicker.visible = false
		partPicker.visible = true
	
func updatePartButtons():
	var i = 0
	for part in $Offset/Control/PartsAndStats/ScrollContainer/Control.get_children():
		if i<PartCompendium.indexedCategories[categoryIndex].size():
			part.visible = true
			part.get_child(0).text = PartCompendium.indexedCategories[categoryIndex][i].inGameName
		else:
			part.visible = false
		i+=1

func _on_head_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=0
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_legs_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=8
	await get_tree().create_timer(.2).timeout
	updatePartButtons()

func _on_upper_torso_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=1
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_feet_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=9
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_back_mount_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=10
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_shoulders_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=2
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_arms_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=3
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_left_fire_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=4
	await get_tree().create_timer(.2).timeout
	updatePartButtons()

func _on_right_fire_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=5
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_lower_torso_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=6
	await get_tree().create_timer(.2).timeout
	updatePartButtons()

func _on_thighs_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=7
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_button_pressed():#equip
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	match categoryIndex:
		0:
			GameManager.myRobotData["Head"] = GameManager.buttonSelection.index
		1:
			GameManager.myRobotData["UpperTorso"] = GameManager.buttonSelection.index
		2:
			GameManager.myRobotData["RightShoulder"] = GameManager.buttonSelection.index
			GameManager.myRobotData["LeftShoulder"] = GameManager.buttonSelection.index
		3:
			GameManager.myRobotData["RightArm"] = GameManager.buttonSelection.index
			GameManager.myRobotData["LeftArm"] = GameManager.buttonSelection.index
		4:
			GameManager.myRobotData["LeftArmWeapon"] = GameManager.buttonSelection.index
		5:
			GameManager.myRobotData["RightArmWeapon"] = GameManager.buttonSelection.index
		6:
			GameManager.myRobotData["Torso"] = GameManager.buttonSelection.index
		7:
			GameManager.myRobotData["RightThigh"] = GameManager.buttonSelection.index
			GameManager.myRobotData["LeftThigh"] = GameManager.buttonSelection.index
		8:
			GameManager.myRobotData["RightLeg"] = GameManager.buttonSelection.index
			GameManager.myRobotData["LeftLeg"] = GameManager.buttonSelection.index
		9:
			GameManager.myRobotData["RightFoot"] = GameManager.buttonSelection.index
			GameManager.myRobotData["LeftFoot"] = GameManager.buttonSelection.index
		10:
			GameManager.myRobotData["LeftBackFire"] = GameManager.buttonSelection.index
		11:
			GameManager.myRobotData["RightBackFire"] = GameManager.buttonSelection.index
	GameManager.updatePartGraphics(mechSkeleton,GameManager.myRobotData)


func _on_color_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	colorPicking = !colorPicking
	if colorPicking:
		colorPicker.color.r = GameManager.myRobotData["Color"+str(colorIndex+1)+"r"]
		colorPicker.color.g = GameManager.myRobotData["Color"+str(colorIndex+1)+"g"]
		colorPicker.color.b = GameManager.myRobotData["Color"+str(colorIndex+1)+"b"]
	updateLeftMenu()


func _on_color_1_pressed():
	colorIndex = 0
	colorPicker.color.r = GameManager.myRobotData["Color"+str(colorIndex+1)+"r"]
	colorPicker.color.g = GameManager.myRobotData["Color"+str(colorIndex+1)+"g"]
	colorPicker.color.b = GameManager.myRobotData["Color"+str(colorIndex+1)+"b"]


func _on_color_2_pressed():
	colorIndex = 1
	colorPicker.color.r = GameManager.myRobotData["Color"+str(colorIndex+1)+"r"]
	colorPicker.color.g = GameManager.myRobotData["Color"+str(colorIndex+1)+"g"]
	colorPicker.color.b = GameManager.myRobotData["Color"+str(colorIndex+1)+"b"]


func _on_color_3_pressed():
	colorIndex = 2
	colorPicker.color.r = GameManager.myRobotData["Color"+str(colorIndex+1)+"r"]
	colorPicker.color.g = GameManager.myRobotData["Color"+str(colorIndex+1)+"g"]
	colorPicker.color.b = GameManager.myRobotData["Color"+str(colorIndex+1)+"b"]


func _on_left_back_mount_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=10
	await get_tree().create_timer(.2).timeout
	updatePartButtons()


func _on_right_back_mount_button_pressed():
	if!GameManager.hasControl() or GameManager.gamemode!=-5:
		return
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
	categoryIndex=11
	await get_tree().create_timer(.2).timeout
	updatePartButtons()
