extends Node
########################
var rng = RandomNumberGenerator.new()
var spawnPoints: Array
var gamemode = 0
var myRobot
########################

# Called when the node enters the scene tree for the first time.
func _ready():
	RenderingServer.set_default_clear_color(Color(0.38431372549,0.38431372549,0.38431372549,1))
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func change_scene(scene):
	var sceneFrom = get_tree().get_current_scene().get_name()
	if sceneFrom == "Menu":
		RenderingServer.set_default_clear_color(Color(0,0,0,1))
	get_tree().change_scene_to_file(scene)
	while get_tree().get_current_scene().get_name() == sceneFrom:
		await get_tree().process_frame
	match gamemode:
		-1:
			pass
		0:
			RenderingServer.set_default_clear_color(Color(0,0,0,1))
			spawn_playerMech()

func spawn_playerMech():
	print(get_tree().get_current_scene().get_name())
	spawnPoints = get_node("/root/"+get_tree().get_current_scene().get_name()+"/SpawnPoints").get_children()
	var point = spawnPoints[rng.randi_range(0,spawnPoints.size()-1)]
	myRobot = spawn("Player","res://Assets/Prefabs/InGameMech.tscn",point.global_position,point.global_rotation)
	
func spawn(name_,path,globalPos,globalRot):
	var scene = load(path)
	var entity = scene.instantiate()
	entity.set_name(name_)
	get_node("/root").add_child(entity)
	entity.global_position = globalPos
	entity.global_rotation = globalRot
	return entity
	
func respawn():
	spawnPoints = get_node("/root/"+get_tree().get_current_scene().get_name()+"/SpawnPoints").get_children()
	var point = spawnPoints[rng.randi_range(0,spawnPoints.size()-1)]
	myRobot.global_position = point.global_position
	
