extends Node

@export var chatBubblePath: String
@export var ipField: TextEdit
@export var nameEntry: TextEdit
@export var chatBar: TextEdit
@export var menu: Control
@export var level: Node3D
@export var connectionNames: Node
@export var chatSpawnPoint: Control
@export var sendButton: Button
@export var readyButton: Button
@export var startButton: Button
var external_ip
var hostIP = ""
var devices
@export var connectionList: Array
@export var connectionListID: Array
@export var readyList: Array
@export var stageName: RichTextLabel
@export var gameMode: RichTextLabel
signal player_connected(peer_id)
signal player_disconnected(peer_id) 
signal server_disconnected
var peer = ENetMultiplayerPeer.new()
@export var stageList = ["[center]VALLEY","[center]TEST"]
@export var modeList = ["[center]TRAINING","[center]DEATHMATCH"]
var stageIndex = 0
var modeIndex = 1
@export var timeLimit: RichTextLabel
@export var scoreLimit: RichTextLabel


# Called when the node enters the scene tree for the first time.
func _ready():
	readyList = [false,false,false,false,false,false,false,false]
	multiplayer.peer_connected.connect(_on_player_connected)
	multiplayer.peer_disconnected.connect(_on_player_disconnected)
	multiplayer.connected_to_server.connect(_on_connected_ok)
	multiplayer.connection_failed.connect(_on_connected_fail)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	portMap()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Input.is_action_pressed("return"):
		if GameManager.gamemode == -4:
			_on_send_chat_pressed()
		elif GameManager.gamemode == -3:
			_on_connect_pressed()
	if multiplayer.is_server():
		if GameManager.gameTimer >= timeLimit.get_child(0).text.to_int() and GameManager.gamemode>0:
			GameManager.gamemode=-1
			rpc("end_game")
	


func updateNameList():
	var i = 0
	for _name in connectionNames.get_children():
		_name.text=""
	for connection in connectionList:
		connectionNames.get_child(i).text = connection
		if readyList[i]:
			connectionNames.get_child(i).modulate = Color(0,1,0,1)
		else:
			connectionNames.get_child(i).modulate = Color(1,1,1,1)
		i +=1
	
func portMap():
	var upnp = UPNP.new()
	
	upnp.delete_port_mapping(9999,"UDP")
	upnp.delete_port_mapping(9999,"TCP")
	
	var discover_result = upnp.discover()
	
	if discover_result == UPNP.UPNP_RESULT_SUCCESS:
		if upnp.get_gateway() and upnp.get_gateway().is_valid_gateway():
			
			var map_result_udp = upnp.add_port_mapping(9999,9999,"godot_udp", "UDP", 0)
			var map_result_tcp = upnp.add_port_mapping(9999,9999,"godot_tcp", "TCP", 0)
			
			if not map_result_udp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999,9999,"","UDP")
			if not map_result_tcp == UPNP.UPNP_RESULT_SUCCESS:
				upnp.add_port_mapping(9999,9999,"","TCP")
	
	external_ip = upnp.query_external_address()
	
	#upnp.delete_port_mapping(9999,"UDP")
	#upnp.delete_port_mapping(9999,"TCP")
	
	#$UI/PublicIP.text = str(external_ip)

func _on_host_button_pressed():
	if nameEntry.text.strip_edges(true,true) == "":
		return
	match GameManager.gamemode:
		-4,-3:
			return
	if!GameManager.hasControl():
		return
	GameManager.waiting = true
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	hostGame()

func _on_connect_pressed():
	if nameEntry.text.strip_edges(true,true) == "":
		return
	match GameManager.gamemode:
		-5:
			return
	if!GameManager.hasControl():
		return
	GameManager.waiting = true
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	hostIP = ipField.text
	joinGame()

func hostGame():
	peer.create_server(9999)
	multiplayer.multiplayer_peer = peer 
	menu.onlineRoom()
	GameManager.activePlayerName = nameEntry.text
	startButton.get_parent().visible = true
	readyButton.get_parent().self_modulate = Color(0,0,0,0)
	readyButton.disabled = true
	rpc("addNameToConnectionList","[center]"+nameEntry.text+"♚",multiplayer.get_unique_id())
	timeLimit.get_child(0).editable = true
	scoreLimit.get_child(0).editable = true
		#start_game("res://Assets/Scenes/Test.tscn")

func joinGame():
	peer.create_client(hostIP,9999)
	multiplayer.multiplayer_peer = peer
	startButton.get_parent().visible = false
	readyButton.get_parent().self_modulate = Color(1,1,1,1)
	#start_game("res://Assets/Scenes/Test.tscn")

@rpc("any_peer", "reliable", "call_local")
func start_game(_level,_mode):
	GameManager.menu.animTitle.play("fadeToBlack")
	await get_tree().create_timer(1).timeout
	change_level(_level)
	GameManager.gamemode = _mode #DeathMatch
	if multiplayer.is_server():
		var i = 1
		for id in multiplayer.get_peers():
			level.spawn_mech(id,i)
			i+=1
		level.spawn_mech(1,0)

func change_level(scene :String):
	for c in level.get_children():
		level.remove_child(c)
		c.queue_free()
	var stageToLoad = load(scene)
	var stage = stageToLoad.instantiate()
	hideUI()
	level.add_child(stage)
	level.currentStage = stage
	
func showUI():
	GameManager.menu.get_node("Eclipse").visible = true
	GameManager.menu.get_node("Eclipse2").visible = true
	GameManager.menu.get_node("DirectionalLight3D").visible = true
	GameManager.menu.get_node("Title").visible = true
	#GameManager.menu.get_node("Online").visible = true
	#GameManager.menu.get_node("MainMenu").visible = true
	#GameManager.menu.get_node("StageSelect").visible = true
	GameManager.menu.get_node("Earth").visible = true
	GameManager.menu.get_node("PreviewMech").visible = true
	GameManager.menu.get_node("SubViewport/Camera3D").current = true
	GameManager.menu.get_node("SubViewport2/Camera3D").current = true
	GameManager.menu.get_node("SubViewport3/Camera3D").current = true

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
	
func _on_copy_pressed():
	DisplayServer.clipboard_set(external_ip)

func _on_player_connected(id):
	pass

@rpc("any_peer", "reliable", "call_local")
func end_game():
	if GameManager.gamemode == 0:
		return
	GameManager.mainMenu.animTitle.play("fadeToBlack")
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	await get_tree().create_timer(1).timeout
	GameManager.optionsMenu = false
	GameManager.saveData()
	GameManager.mainMenu.animTitle.play("fadeFromBlack")
	GameManager.menu.network.level.currentStage = null
	for player in GameManager.players.get_children():
		player.queue_free()
	GameManager.waiting = true
	GameManager.gamemode = -1
	GameManager.clear_level()
	GameManager.menu.network.showUI()
	GameManager.menu.title()

func remove_multiplayer_peer():
	multiplayer.multiplayer_peer.close( )
	clearConnectionList()
	level.currentStage = null
	readyList = [false,false,false,false,false,false,false,false]

func _on_player_disconnected(id):
	print("player has disconnected from room")
	if id == connectionListID[0]:
		closeRoom()
		rpc("clearConnectionList")
		readyList = [false,false,false,false,false,false,false,false]
		remove_multiplayer_peer()
		return
	rpc("clearConnectionList")
	if multiplayer.is_server():
		rpc("addNameToConnectionList","[center]"+nameEntry.text+"♚",multiplayer.get_unique_id())
	else:
		rpc("addNameToConnectionList","[center]"+nameEntry.text,multiplayer.get_unique_id())
	player_disconnected.emit()
	
func _on_server_disconnected(id):
	closeRoom()
	player_disconnected.emit()

func closeRoom():
	print("room has closed")
	rpc("clearConnectionList")
	if GameManager.gamemode<0:
		menu.goBack()
	else:
		GameManager.mainMenu.animTitle.play("fadeFromBlack")
		GameManager.menu.network.level.currentStage = null
		for player in GameManager.players.get_children():
			player.queue_free()
		GameManager.waiting = true
		GameManager.gamemode = -1
		GameManager.clear_level()
		GameManager.menu.network.showUI()
	GameManager.menu.title()


func _on_connected_ok():
	GameManager.waiting = false
	GameManager.activePlayerName = nameEntry.text
	startButton.get_parent().visible = false
	readyButton.disabled = false
	var peer_id = multiplayer.get_unique_id()
	player_connected.emit(peer_id)
	menu.onlineRoom()
	rpc("getServerConnectionList")
	updateNameList()
	while connectionList.size()==0:
		await get_tree().process_frame
	rpc("addNameToConnectionList","[center]"+nameEntry.text,multiplayer.get_unique_id())
	timeLimit.get_child(0).editable = false
	scoreLimit.get_child(0).editable = false
	

func _on_connected_fail():
	GameManager.waiting = false
	remove_multiplayer_peer()

@rpc("any_peer", "reliable", "call_local")
func addNameToConnectionList(_name,id):
	connectionList.append(_name)
	connectionListID.append(id)
	var i = 0
	for readyStat in readyList:
		if connectionList.size()<i+1:
			readyStat = false
		i += 1
	updateNameList()
	
@rpc("any_peer", "reliable", "call_local")
func clearConnectionList():
	connectionList.clear()
	connectionListID.clear()
	updateNameList()
	
@rpc("any_peer","call_remote","reliable")
func getServerConnectionList():
	if multiplayer.is_server():
		rpc("returnConnectionList",connectionList,connectionListID,readyList)

@rpc("any_peer","call_local","reliable")
func returnConnectionList(list,listID,rList):
	connectionList = list
	connectionListID = listID
	readyList = rList
	updateNameList()

@rpc("any_peer","call_remote","reliable")
func syncReady(id,readyStatus):
	var i = 0
	for playerID in connectionListID:
		if playerID == id:
			readyList[i] = readyStatus
			return
		i+=1

@rpc("any_peer","call_local","reliable")
func sendChat(sender,msg,id,c1r,c1g,c1b,c2r,c2g,c2b,posx):
	var chat = preload("res://Assets/Prefabs/chat_bubble.tscn").instantiate()
	chat.texture.get_gradient().set_color(0,Color(c1r,c1g,c1b,1))
	chat.texture.get_gradient().set_color(1,Color(c2r,c2g,c2b,1))
	add_child(chat)
	if id == multiplayer.multiplayer_peer.get_unique_id():
		chat.global_position = chatSpawnPoint.global_position
	else:
		chat.global_position = Vector2(980,460)
	chat.get_node("Speaker").text = "[center]"+sender
	chat.get_node("Chat").text = "[center]"+msg
	var t = 0
	chat.scale = Vector2.ZERO
	while(t<10):
		var delta = GameManager.globalDelta
		chat.scale = chat.scale.lerp(Vector2.ONE/4,delta)
		chat.global_position.x = lerp(chat.global_position.x,697.0+posx,GameManager.globalDelta/3)
		chat.global_position.y = lerp(chat.global_position.y,-200.0,GameManager.globalDelta/10)
		t += delta
		await get_tree().process_frame
		
	chat.queue_free()

func _on_send_chat_pressed():
	if chatBar.text.strip_edges(true,true) == "":
		return
	var msg = chatBar.text
	chatBar.text = ""
	rpc("sendChat",GameManager.activePlayerName,msg,multiplayer.multiplayer_peer.get_unique_id(),GameManager.myRobotData["Color1r"],GameManager.myRobotData["Color1g"],GameManager.myRobotData["Color1b"],GameManager.myRobotData["Color2r"],GameManager.myRobotData["Color2g"],GameManager.myRobotData["Color2b"],RandomNumberGenerator.new().randi_range(-300,100))
	GameManager.buttonFeedback(sendButton.get_parent(),"res://Assets/SFX/Change.wav")


func _on_ready_button_pressed():
	var i = 0
	for playerID in connectionListID:
		if playerID == multiplayer.get_unique_id():
			break
		i+=1
	readyList[i] = !readyList[i]
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	rpc("syncReady",multiplayer.get_unique_id(),readyList[i])
	rpc("getServerConnectionList")


func _on_start_button_pressed():
	var i = 0
	for playerID in connectionListID:
		if i == 0:
			i+=1
			continue
		if readyList[i] == false:
			return
		i+=1
	GameManager.waiting = true
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/MenuSelect1.wav")
	rpc("start_game",getStageIndex(stageName.text),getModeIndex(gameMode.text))
			
func getModeIndex(text):
	match text.to_lower():
		"[center]deathmatch":
			return 1
		"[center]training":
			return 0
	return 0
	
func getStageIndex(text):
	match text.to_lower():
		"[center]valley":
			return "res://Assets/Scenes/ValleyNew.tscn"
		"[center]test":
			return "res://Assets/Scenes/Test.tscn"
	return "res://Assets/Scenes/Test.tscn"
	
#this is for online stage select stuff
func _on_left_arrow_button_pressed():
	if !multiplayer.is_server():
		return
	modeIndex-=1
	if modeIndex<0:
		modeIndex = modeList.size()-1
	updateRoomUI()

func _on_left_arrow_button_2_pressed():
	if !multiplayer.is_server():
		return
	stageIndex-=1
	if stageIndex<0:
		stageIndex = stageList.size()-1
	updateRoomUI()

func _on_right_arrow_button_pressed():
	if !multiplayer.is_server():
		return
	modeIndex+=1
	if modeIndex>modeList.size()-1:
		modeIndex = 0
	updateRoomUI()

func _on_right_arrow_button_2_pressed():
	if !multiplayer.is_server():
		return
	stageIndex+=1
	if stageIndex>modeList.size()-1:
		stageIndex = 0
	updateRoomUI()
	
func updateRoomUI():
	stageName.text = stageList[stageIndex]
	gameMode.text = modeList[modeIndex]
	GameManager.buttonFeedback(GameManager.buttonSelection.get_parent(),"res://Assets/SFX/Change.wav")
