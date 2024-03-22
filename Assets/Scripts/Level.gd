extends Node

@export var network: Node
@export var currentStage: Node3D

# Called when the node enters the scene tree for the first time.

func spawn_mech(id: int, spawnIndex):
	while currentStage == null:
		await get_tree().process_frame
	var player = load(GameManager.MECH_PREFAB_PATH).instantiate()
	player.name = str(id)
	#call_deferred("add_child",player)
	print ("Spawned client player "+player.name)
	#player.global_position = Vector3(0,5,0)
	GameManager.menu.get_node("Players").add_child(player)
	GameManager.spawnPoints = currentStage.get_node("SpawnPoints").get_children()
	GameManager.waiting = false
	

func del_player(id: int, ign: String):
	if not $Players.has_node(str(id)):
		return 
	$Players.get_node(str(id)).queue_free()

func _exit_tree():
	if not multiplayer.is_server():
		return
	multiplayer.peer_disconnected.disconnect(del_player)
