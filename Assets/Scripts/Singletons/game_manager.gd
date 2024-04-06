extends Node
###SUPER VARIABLES##########################
var menu
var rng = RandomNumberGenerator.new()
var gamemode = 0
var globalDelta
var myRobotData: Dictionary #information about what parts your robot is comprised of
var optionsMenu: bool
var waiting = false
var buttonSelection #anytime you are hovering over a button, it is saved here
###IN-GAME VARIABLES########################
var spawnPoints: Array #all possible spawn points for the player mech
var myRobot #in-game mech node that is owned by this client
var activePlayerName = ""
var playerCamera #in-game camera node that follows the mech
var players
var entities
var props
var gameTimer: float
###OUT-OF-GAME VARIABLES#####################
var mainMenu #allows other scripts to reference the main menu if applicable
var gameSaveData: Dictionary #utilized when writing information about the game to the hard drive
###CONSTANTS#################################
const MECH_PREFAB_PATH: String = "res://Assets/Prefabs/InGameMech.tscn"
const SAVE_PATH: String = "user://saveData.bin"
const MECH_SAVE_PATH: String = "user://mechSaveData.bin"
const Part = preload("res://Assets/Scripts/Part.gd")
const Weapon = preload("res://Assets/Scripts/Weapon.gd")
#############################################

# Called when the node enters the scene tree for the first time.
func _ready():
	while PartCompendium.indexedCategories.size()==0:
		await get_tree().process_frame
	GameManager.loadData()
	GameManager.loadMechData()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	globalDelta = delta
	if myRobot != null:
		gameTimer+=delta
	else:
		gameTimer = 0
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)
#updates the graphics of the mech	

func updateRobotColor(skeleton,robotData):
	var part = skeleton.get_child(0)
	part.get_child(0).get_active_material(0).albedo_color.r = robotData["Color1r"]
	part.get_child(0).get_active_material(0).albedo_color.g = robotData["Color1g"]
	part.get_child(0).get_active_material(0).albedo_color.b = robotData["Color1b"]
		
	part.get_child(0).get_active_material(1).albedo_color.r = robotData["Color2r"]
	part.get_child(0).get_active_material(1).albedo_color.g = robotData["Color2g"]
	part.get_child(0).get_active_material(1).albedo_color.b = robotData["Color2b"]
		
	part.get_child(0).get_active_material(2).albedo_color.r = robotData["Color3r"]
	part.get_child(0).get_active_material(2).albedo_color.g = robotData["Color3g"]
	part.get_child(0).get_active_material(2).albedo_color.b = robotData["Color3b"]
	return
	

func updatePartGraphics(skeleton,robotData):
	#make all parts invisible
	for part in skeleton.get_children():
		if part.name == "Weapon_L" or part.name == "Weapon_R" or part.name == "BackFire_L" or part.name == "BackFire_R": 
			continue
		part.visible = false
	#determine head visibility
	skeleton.get_node(PartCompendium.head[robotData["Head"]].partName+"_Head").visible = true
	#determine UpperTorso visibility
	skeleton.get_node(PartCompendium.upperTorso[robotData["UpperTorso"]].partName+"_UpperTorso").visible = true
	#determine Torso visibility
	skeleton.get_node(PartCompendium.lowerTorso[robotData["Torso"]].partName+"_Torso").visible = true
	#determine Right Thigh visibility
	skeleton.get_node(PartCompendium.thighs[robotData["RightThigh"]].partName+"_Thigh_R").visible = true
	#determine Left Thigh visibility
	skeleton.get_node(PartCompendium.thighs[robotData["LeftThigh"]].partName+"_Thigh_L").visible = true
	#determine Right Leg visibility
	skeleton.get_node(PartCompendium.legs[robotData["RightLeg"]].partName+"_Legs_R").visible = true
	#determine Left Leg visibility
	skeleton.get_node(PartCompendium.legs[robotData["LeftLeg"]].partName+"_Legs_L").visible = true
	#determine Right Foot visibility
	skeleton.get_node(PartCompendium.feet[robotData["RightFoot"]].partName+"_Foot_R").visible = true
	#determine Left Foot visibility
	skeleton.get_node(PartCompendium.feet[robotData["LeftFoot"]].partName+"_Foot_L").visible = true
	#determine Right Shoulder visibility
	skeleton.get_node(PartCompendium.shoulders[robotData["RightShoulder"]].partName+"_Shoulder_R").visible = true
	#determine Left Shoulder visibility
	skeleton.get_node(PartCompendium.shoulders[robotData["LeftShoulder"]].partName+"_Shoulder_L").visible = true
	#determine Right Arm visibility
	skeleton.get_node(PartCompendium.arms[robotData["RightArm"]].partName+"_Arm_R").visible = true
	#determine Left Arm visibility
	skeleton.get_node(PartCompendium.arms[robotData["LeftArm"]].partName+"_Arm_L").visible = true
	#determine left weapon visibility
	skeleton.get_node(PartCompendium.backFire[robotData["LeftBackFire"]].partName+"_BackFire_L").visible = true
	skeleton.get_node(PartCompendium.backFire[robotData["LeftBackFire"]].partName+"_BackMount_L").visible = true
	skeleton.get_node(PartCompendium.backFire[robotData["RightBackFire"]].partName+"_BackFire_R").visible = true
	skeleton.get_node(PartCompendium.backFire[robotData["RightBackFire"]].partName+"_BackMount_R").visible = true
	#determine left weapon visibility
	match PartCompendium.weapons[robotData["LeftArmWeapon"]].partName:
		"Drill":
			skeleton.get_node("Drill_L").visible = true
		"NeedleCannon":
			skeleton.get_node("NeedleCannon_L").visible = true
		"PlasmaCannon":
			skeleton.get_node("PlasmaCannon_L").visible = true
	#determine right weapon visibility
	match PartCompendium.weapons[robotData["RightArmWeapon"]].partName:
		"Drill":
			skeleton.get_node("Drill_R").visible = true
		"NeedleCannon":
			skeleton.get_node("NeedleCannon_R").visible = true
		"PlasmaCannon":
			skeleton.get_node("PlasmaCannon_R").visible = true
func initializeRobotParts():
	#Part.new(PART DISTINCTION, PART USE, PART WEIGHT)
	myRobotData = {
		"Head":0,
		"UpperTorso":0,
		"Torso":0,
		"RightThigh":0,
		"LeftThigh":0,
		"RightLeg":0,
		"LeftLeg":0,
		"RightFoot":0,
		"LeftFoot":0,
		"RightShoulder":0,
		"LeftShoulder":0,
		"RightArm":0,
		"LeftArm":0,
		"LeftArmWeapon":0,
		"RightArmWeapon":1,
		"LeftBackFire":0,
		"RightBackFire":1,
		"Color1r":.9,
		"Color1g":.51,
		"Color1b":.04,
		"Color2r":1,
		"Color2g":1,
		"Color2b":1,
		"Color3r":0,
		"Color3g":0,
		"Color3b":0
	}

func hasControl():
	if waiting:
		return false
	return true
	
func clear_level():
	for c in menu.network.level.get_children():
		menu.network.level.remove_child(c)
		c.queue_free()

func spawn(name_,path,globalPos,globalRot,scale):
	var scene = load(path)
	var entity = scene.instantiate()
	entity.set_name(name_)
	entity.scale = scale
	get_node("/root").add_child(entity)
	entity.global_position = globalPos
	entity.global_rotation = globalRot
	return entity
	
func spawnChild(parent,name_,path,pos,rot,scale):
	var scene = load(path)
	var entity = scene.instantiate()
	entity.set_name(name_)
	print (entity.name)
	parent.add_child(entity)
	entity.position = pos
	entity.rotation = rot
	entity.scale = scale
	return entity
	
func spawnChildGlobal(parent,name_,path,pos,rot,scale):
	var scene = load(path)
	var entity = scene.instantiate()
	entity.set_name(name_)
	parent.add_child(entity)
	entity.global_position = pos
	entity.rotation = rot
	entity.scale = scale
	return entity
	
func respawn():
	var point = spawnPoints[rng.randi_range(0,spawnPoints.size()-1)]
	myRobot.global_position = point.global_position
	myRobot.global_rotation = point.global_rotation
	
func buttonFeedback(button, path):
	AudioManager.playSound(path,-20,1,.05)
	var t = 0.0
	while(t<1.5):
		t+=3.0*globalDelta
		if ((Time.get_ticks_msec()*16)%1000)>500:
			if button != null:
				button.modulate = Color(1,1,1,1)
		else:
			if button != null:
				button.modulate = Color(1,1,1,0)
		await get_tree().process_frame
	if button != null:
		button.modulate = Color(1,1,1,1)
#save data to disk
func saveData() -> void:
	#--Adds relevant values to a dictionary to be written to the hard drive-------------------------
	gameSaveData["masterVolume"] = AudioManager.volumeMixdB
	gameSaveData["sfxVolume"] = AudioManager.sfxMixdB
	gameSaveData["musicVolume"] = AudioManager.musicMixdB
	#--And then writes it to a JSON file------------------------------------------------------------
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	var jstr = JSON.stringify(gameSaveData)
	file.store_line(jstr)
#save data to disk
func saveMechData() -> void:
	#--And then writes it to a JSON file------------------------------------------------------------
	var file = FileAccess.open(MECH_SAVE_PATH, FileAccess.WRITE)
	var jstr = JSON.stringify(myRobotData)
	file.store_line(jstr)
#load data from disk
func loadData() -> void:
	var file = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if not file:
		return
	if file == null:
		return
	if FileAccess.file_exists(SAVE_PATH) == true:
		if not file.eof_reached():
			var current_line = JSON.parse_string(file.get_line())
			if current_line:	
				#--Extracts relevant values from JSON dictionary to affect gameplay values----------------------
				var extractedValue
				extractedValue = getValueFromDict(current_line,"masterVolume")
				if extractedValue != null:
					AudioManager.volumeMixdB = extractedValue
				extractedValue = getValueFromDict(current_line,"sfxVolume")
				if extractedValue != null:
					AudioManager.sfxMixdB = extractedValue
				extractedValue = getValueFromDict(current_line,"musicVolume")
				if extractedValue != null:
					AudioManager.musicMixdB = extractedValue
#load mech data from disk
func loadMechData() -> void:
	var file = FileAccess.open(MECH_SAVE_PATH, FileAccess.READ)
	if not file:
		initializeRobotParts()
		return
	if file == null:
		initializeRobotParts()
		return
	if FileAccess.file_exists(SAVE_PATH) == true:
		if not file.eof_reached():
			myRobotData = JSON.parse_string(file.get_line())
			print(myRobotData)
			

func getValueFromDict( dict, key):
	if dict.has(key):
		return dict[key]
	else:
		return null

func hideUI():
	GameManager.menu.get_node("Eclipse").visible = false
	GameManager.menu.get_node("Eclipse2").visible = false
	GameManager.menu.get_node("DirectionalLight3D").visible = false
	GameManager.menu.get_node("Title").visible = false
	GameManager.menu.get_node("Online").visible = false
	GameManager.menu.get_node("MainMenu").visible = false
	GameManager.menu.get_node("StageSelect").visible = false
	GameManager.menu.get_node("Earth").visible = false
	GameManager.menu.get_node("PreviewMech").visible = false
	GameManager.menu.get_node("SubViewport/Camera3D").current = false
	GameManager.menu.get_node("SubViewport2/Camera3D").current = false
	GameManager.menu.get_node("SubViewport3/Camera3D").current = false

func loadScene(scene):
	var level = menu.network.level
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	var stageToLoad = load("res://Assets/Scenes/"+scene+".tscn")
	var stage = stageToLoad.instantiate()
	hideUI()
	level.add_child(stage)
	level.currentStage = stage
