extends Node

const HP_MAX = 100
const SHIELD_MAX = 100
var ign: String
var id: int
@export var hp = HP_MAX
@export var shield = SHIELD_MAX
var hpRatio = float(hp)/float(HP_MAX)
var shieldRatio = float(shield)/float(SHIELD_MAX)
@export var animatorSP: AnimationPlayer
@export var animatorHP: AnimationPlayer
@export var kills: int
@export var deaths:int
var lastAttacker: int

func _enter_tree():
	set_multiplayer_authority(get_parent().name.to_int())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	#statsCheck()
	if get_parent().name.to_int()!=multiplayer.get_unique_id():
		#print()
		return
	animateHP_UI()
	pass

func statsCheck():
	if !is_multiplayer_authority():
		return
	#print("statscheck")
	hp = clamp(hp,0,HP_MAX)
	shield = clamp(shield,0,SHIELD_MAX)
	if hp<=0:
		hp = HP_MAX
		shield = SHIELD_MAX
		deaths+=1
		rpc("addKillCount",lastAttacker)
		get_parent().die()
		get_parent().deathscore.text = "[center]"+str(deaths)

@rpc("any_peer", "reliable", "call_local")
func addKillCount(id):
	for player in GameManager.players.get_children():
		if player.name.to_int() == id:
			player.stats.kills+=1
			if player.stats.kills>GameManager.menu.network.scoreLimit.get_child(0).text.to_int():
				GameManager.menu.network.end_game()
				get_parent().killscore.text = "[center]"+str(kills)

func animateHP_UI():
	#print("animateHP_UI")
	hpRatio = lerp(hpRatio,float(hp)/float(HP_MAX),GameManager.globalDelta*2)
	shieldRatio = lerp(shieldRatio,float(shield)/float(SHIELD_MAX),GameManager.globalDelta*2)
	animatorHP.current_animation="HPfill"
	animatorSP.current_animation="SPfill"
	animatorHP.seek(hpRatio,true)
	animatorSP.seek(shieldRatio,true)
