extends Node
###SUPER VARIABLES##########################
var rng = RandomNumberGenerator.new()
var gamemode = 0
var myRobotData: Dictionary #information about what parts your robot is comprised of
var optionsMenu: bool
var waiting = false
var buttonSelection #anytime you are hovering over a button, it is saved here
###IN-GAME VARIABLES########################
var spawnPoints: Array #all possible spawn points for the player mech
var myRobot #in-game mech node that is owned by this client
var playerCamera #in-game camera node that follows the mech
###OUT-OF-GAME VARIABLES#####################
var mainMenu #allows other scripts to reference the main menu if applicable
var gameSaveData: Dictionary #utilized when writing information about the game to the hard drive
###CONSTANTS#################################
const SAVE_PATH: String = "user://saveData.bin"
const MECH_SAVE_PATH: String = "user://mechSaveData.bin"
const Part = preload("res://Assets/Scripts/Part.gd")
const Weapon = preload("res://Assets/Scripts/Weapon.gd")
#############################################

# Called when the node enters the scene tree for the first time.
func _ready():
	GameManager.loadData()
	GameManager.loadMechData()
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_just_pressed("fullscreen"):
		if DisplayServer.window_get_mode(0) == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED, 0)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN, 0)
#updates the graphics of the mech	
func updatePartGraphics(skeleton):
	#make all parts invisible
	for part in skeleton.get_children():
		part.visible = false
	#determine head visibility
	skeleton.get_node(GameManager.myRobotData["Head"].partName+"_Head").visible = true
	#determine UpperTorso visibility
	skeleton.get_node(GameManager.myRobotData["UpperTorso"].partName+"_UpperTorso").visible = true
	#determine Torso visibility
	skeleton.get_node(GameManager.myRobotData["Torso"].partName+"_Torso").visible = true
	#determine Right Thigh visibility
	skeleton.get_node(GameManager.myRobotData["RightThigh"].partName+"_Thigh_R").visible = true
	#determine Left Thigh visibility
	skeleton.get_node(GameManager.myRobotData["LeftThigh"].partName+"_Thigh_L").visible = true
	#determine Right Leg visibility
	skeleton.get_node(GameManager.myRobotData["RightLeg"].partName+"_Legs_R").visible = true
	#determine Left Leg visibility
	skeleton.get_node(GameManager.myRobotData["LeftLeg"].partName+"_Legs_L").visible = true
	#determine Right Foot visibility
	skeleton.get_node(GameManager.myRobotData["RightFoot"].partName+"_Foot_R").visible = true
	#determine Left Foot visibility
	skeleton.get_node(GameManager.myRobotData["LeftFoot"].partName+"_Foot_L").visible = true
	#determine Right Shoulder visibility
	skeleton.get_node(GameManager.myRobotData["RightShoulder"].partName+"_Shoulder_R").visible = true
	#determine Left Shoulder visibility
	skeleton.get_node(GameManager.myRobotData["LeftShoulder"].partName+"_Shoulder_L").visible = true
	#determine Right Arm visibility
	skeleton.get_node(GameManager.myRobotData["RightArm"].partName+"_Arm_R").visible = true
	#determine Left Arm visibility
	skeleton.get_node(GameManager.myRobotData["LeftArm"].partName+"_Arm_L").visible = true
	#determine left weapon visibility
	match GameManager.myRobotData["LeftArmWeapon"].partName:
		"Drill":
			skeleton.get_node("Drill_L").visible = true
		"NeedleCannon":
			skeleton.get_node("NeedleCannon_L").visible = true
		"PlasmaCannon":
			skeleton.get_node("PlasmaCannon_L").visible = true
	#determine right weapon visibility
	match GameManager.myRobotData["RightArmWeapon"].partName:
		"Drill":
			skeleton.get_node("Drill_R").visible = true
		"NeedleCannon":
			skeleton.get_node("NeedleCannon_R").visible = true
		"PlasmaCannon":
			skeleton.get_node("PlasmaCannon_R").visible = true
func initializeRobotParts():
	#Part.new(PART DISTINCTION, PART USE, PART WEIGHT)
	myRobotData = {
		"Head":Part.new("Mech1","armor", 2),
		"UpperTorso":Part.new("Mech1","armor", 3),
		"Torso":Part.new("Mech1","armor", 4),
		"RightThigh":Part.new("Mech1","armor", 2),
		"LeftThigh":Part.new("Mech1","armor", 2),
		"RightLeg":Part.new("Mech1","armor", 2),
		"LeftLeg":Part.new("Mech1","armor", 2),
		"RightFoot":Part.new("Mech1","armor", 2),
		"LeftFoot":Part.new("Mech1","armor", 2),
		"RightShoulder":Part.new("Mech1","armor", 2),
		"LeftShoulder":Part.new("Mech1","armor", 2),
		"RightArm":Part.new("Mech2","armor", 2),
		"LeftArm":Part.new("Mech2","armor", 2),
		"LeftArmWeapon":Weapon.new("left","NeedleCannon","gun",3),
		"RightArmWeapon":Weapon.new("right","NeedleCannon","gun",2)
	}

func hasControl():
	if waiting:
		return false
	return true

func change_scene(scene):
	var sceneFrom = get_tree().get_current_scene().get_name()
	if sceneFrom == "Menu":
		RenderingServer.set_default_clear_color(Color(0,0,0,1)) #makes background black
	get_tree().change_scene_to_file(scene)
	await get_tree().process_frame
	#while get_tree().get_current_scene().get_name() == sceneFrom:
		#await get_tree().process_frame
	match gamemode:
		-1:#menu; spawn nothing
			myRobot.queue_free()
			playerCamera.queue_free()
		0:#training mode; spawn player, make BG black
			print("spawn bullshit. Current game mode is: "+str(gamemode))
			RenderingServer.set_default_clear_color(Color(0,0,0,1)) #makes background black
			spawn_playerMech()
	GameManager.waiting = false

func spawn_playerMech():
	#print(get_tree().get_current_scene().get_name())
	spawnPoints = get_node("/root/"+get_tree().get_current_scene().get_name()+"/SpawnPoints").get_children()
	var point = spawnPoints[rng.randi_range(0,spawnPoints.size()-1)]
	myRobot = spawn("Player","res://Assets/Prefabs/InGameMech.tscn",point.global_position,point.global_rotation,Vector3(1,1,1))
	
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
	parent.add_child(entity)
	entity.position = pos
	entity.rotation = rot
	entity.scale = scale
	return entity
	
func respawn():
	spawnPoints = get_node("/root/"+get_tree().get_current_scene().get_name()+"/SpawnPoints").get_children()
	var point = spawnPoints[rng.randi_range(0,spawnPoints.size()-1)]
	myRobot.global_position = point.global_position+Vector3.UP*2
	
func buttonFeedback(button, path):
	AudioManager.playSound(path,-10,1,0)
	var t = 0.0
	while(t<1.5):
		t+=1.0/60
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
			var myRobotData = JSON.parse_string(file.get_line())

func getValueFromDict( dict, key):
	if dict.has(key):
		return dict[key]
	else:
		return null
	
func loadScene(scene):
	await get_tree().create_timer(1).timeout
	GameManager.change_scene("res://Assets/Scenes/"+scene+".tscn")
