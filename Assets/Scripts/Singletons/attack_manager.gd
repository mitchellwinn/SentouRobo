extends Node

var liveComboCount: int
var liveComboDamage: int
var timeSinceLastHit = 0


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	comboManager(delta)

func comboManager(delta):
	timeSinceLastHit += delta
	if timeSinceLastHit > 2.5:
		if liveComboCount >= 2:#combo end
			var flavorText = GameManager.spawnChild(GameManager.myRobot.get_node("Scalar/UI/Offset"),"flavorText","res://Assets/Prefabs/flavor_text_score.tscn",Vector2(-997,-481),0,Vector2(1.767,1.767))
			if liveComboDamage > 80:
				flavorText.flavorWord = "GREAT"
			else:
				flavorText.flavorWord = "COOL"
			AudioManager.playSound("res://Assets/SFX/Combat/"+flavorText.flavorWord+".wav",-20,1,0.1)
		liveComboDamage=0
		liveComboCount=0
	
func shootHitscan(hitscanner, weapon, dealer):
	if !hitscanner.is_colliding():
		#complete miss
		return
	else:
		if hitscanner.get_collider().collision_layer==1 || hitscanner.get_collider().collision_layer==16:
			ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/dirt_explode.tscn",10,hitscanner.get_collision_point(),hitscanner.get_collision_normal())
			ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/spark_explode2.tscn",2,hitscanner.get_collision_point(),hitscanner.get_collision_normal())
		elif hitscanner.get_collider().collision_layer==4:
			ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/water_splash.tscn",3,hitscanner.get_collision_point(),hitscanner.get_collision_normal())
		elif hitscanner.get_collider().collision_layer==2:
			if hitscanner.get_collider() != GameManager.myRobot:
				ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/spark_explode.tscn",2,hitscanner.get_collision_point(),hitscanner.get_collision_normal())
				GameManager.myRobot.UIAnimator.play("hit")
				GameManager.myRobot.UIAnimator.seek(0)
				timeSinceLastHit = 0
				liveComboCount += 1
				liveComboDamage += weapon.damage
				AudioManager.playSound("res://Assets/SFX/Combat/ShotHit.wav",-20,1,0.1)
				rpc("dealDamage",multiplayer.get_unique_id(),hitscanner.get_collider().name.to_int(),weapon.damage,weapon.shieldDamage,weapon.knockback*(hitscanner.get_collider().global_position-dealer.global_position).normalized())
				
func meleeAttack(recipient, weapon, dealer):
	if recipient != GameManager.myRobot:
		ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/spark_explode.tscn",2,GameManager.myRobot.basis.z+GameManager.myRobot.global_position,Vector3.UP)
		GameManager.myRobot.UIAnimator.play("hit")
		GameManager.myRobot.UIAnimator.seek(0)
		timeSinceLastHit = 0
		liveComboCount += 1
		liveComboDamage += weapon.damage
		AudioManager.playSound("res://Assets/SFX/Combat/ShotHit.wav",-20,1,0.1)
		rpc("dealDamage",multiplayer.get_unique_id(),recipient.name.to_int(),weapon.damage,weapon.shieldDamage,weapon.knockback*(recipient.global_position-dealer.global_position).normalized())	

@rpc("any_peer","call_local","reliable")
func dealDamage(attackerID,id,damage,shieldDamage,knockback):
	for player in GameManager.players.get_children():
		if id == player.name.to_int():
			player.stats.hp-=(damage/(player.stats.shield/25+1))
			player.stats.shield -= shieldDamage
			player.stats.lastAttacker = attackerID
			if knockback.length()>0:
				player.velocity = knockback
			#print("took damage")
			player.stats.statsCheck()
