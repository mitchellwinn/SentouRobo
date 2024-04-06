extends CharacterBody3D
########################
const SPEED = 15
const THRUST_SPEED = 35
const JUMP_VELOCITY = 100
########################
@export var backFireRAnchor: Node3D
@export var backFireLAnchor: Node3D
@export var stats: Node
@export var skeleton: Skeleton3D
@export var camera: Camera3D
@export var cameraTarget: Node3D
@export var cameraBlockCheck: RayCast3D
@export var scalar: Node3D
@export var floorCheckRay: ShapeCast3D
@export var wallCheckRay: ShapeCast3D
@export var waterCheckRay: RayCast3D
@export var rotateCheckRay: RayCast3D
@export var localAnimatorOverlayL: AnimationPlayer
@export var localAnimatorOverlayR: AnimationPlayer
@export var localAnimator: AnimationPlayer
@export var UIAnimator: AnimationPlayer
@export var localAudio: Node
@export var sparkL: GPUParticles3D
@export var sparkR: GPUParticles3D
@export var exhaust: GPUParticles3D
@export var leftArm: BoneAttachment3D
@export var rightArm: BoneAttachment3D
@export var leftShoulder: BoneAttachment3D
@export var rightShoulder: BoneAttachment3D
@export var muzzle1L: Sprite3D
@export var muzzle1R: Sprite3D
@export var collider: CollisionShape3D
@export var UIoffset: Control
@export var hitscannerL: RayCast3D
@export var hitscannerR: RayCast3D
@export var kd: RichTextLabel
@export var killscore: RichTextLabel
@export var deathscore: RichTextLabel
@export var floorAnimCheck: RayCast3D
@export var meleeHitbox1: Area3D
@export var trainingmode: RichTextLabel
@export var timer: RichTextLabel
########################
var torso 
var pose 
var mouseMovement = Vector3.ZERO
var direction = Vector3.ZERO
@export var usingAbility = ""
@export var falling : bool
@export var velo: Vector3
@export var momentum: Vector3
@export var weaponSwitchComplete:= true
var dead
var interruptable = false
var antiGravity = false
var airbornLastFrame = false
var airbornVelocity = 0
var upBuffer = 0
var rightBuffer = 0
var leftBuffer = 0
var downBuffer = 0
var jumpBuffer = 0
var jumpTimer = 0
@export var footAlternation = 1
@export var shootingL = false
@export var swingingL = false
@export var shootingR = false
@export var swingingR = false
@export var running = false
@export var shotTimerL: float
@export var shotTimerR: float
var drowning = false
var gravityGain : float
var flattening = false
var optionsMenuInstance
var spawnIndex = -1
#prints data after each frame
func frameDebug():
	print("______frame debug______")
	print("on floor:"+str(is_on_floor()))
	print("floor raycast: "+str(floorCheckRay.is_colliding()))
	print("floor animation raycast: "+str(floorAnimCheck.is_colliding()))
	print("rotate to normal raycast: "+str(rotateCheckRay.is_colliding()))
	print("facing up/down: "+str(basis.z.y))
	print("gravity: "+str(gravityGain))
	print("atAllActionable: " + str(atAllActionable()))
	print("fullyActionable: " + str(fullyActionable()))
	print("current ability:" + str(usingAbility))
	print("waiting: "+str(GameManager.waiting))
	print("velo: "+str(velo.length()))
	print("jump timer: "+str(jumpTimer))
#initializes mech######################
func _enter_tree():
	set_multiplayer_authority(name.to_int())
	$Stats.set_multiplayer_authority(name.to_int())
	scale = Vector3.ONE


func _ready():
	skeleton = $Scalar/mech/Armature/Skeleton3D
	localAnimator = $Scalar/mech/AnimationPlayer
	localAnimatorOverlayL = $Scalar/mech/AnimationPlayer2
	localAnimatorOverlayR = $Scalar/mech/AnimationPlayer3
	
	var torso = skeleton.find_bone("Bone")
	var pose = skeleton.get_bone_global_pose_no_override(torso)
	if GameManager.gamemode==0:
		trainingmode.visible = true
		kd.visible = false
		killscore.visible = false
		deathscore.visible = false
		timer.visible = false
		
	else:
		trainingmode.visible = false
		kd.visible = true
		killscore.visible = true
		deathscore.visible = true
		timer.visible = true
		
	if multiplayer.multiplayer_peer != null:
		if !is_multiplayer_authority():
			$Scalar/UI.visible = false
			return
	rpc("updateMechInGame")
	GameManager.spawnPoints = GameManager.menu.network.level.currentStage.get_node("SpawnPoints").get_children()
	spawnIndex = GameManager.menu.network.connectionListID.find(name.to_int())
	$Stats.id = name.to_int()
	GameManager.menu.animTitle.play("fadeFromBlack")
	GameManager.myRobot = self
	GameManager.myRobot.global_position = GameManager.spawnPoints[spawnIndex].global_position
	GameManager.myRobot.global_rotation = GameManager.spawnPoints[spawnIndex].global_rotation
	GameManager.playerCamera = camera
	GameManager.playerCamera.current = true
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.reparent(get_node("/root"),true)
	
	

func _process(delta):
	jumpTimer-=delta
	
#main process for mech controller#######################
func _physics_process(delta):
	animate()
	if multiplayer.multiplayer_peer != null:
		if !is_multiplayer_authority():
			return
	velo = velocity
	if Input.is_action_just_pressed("esc"):
		GameManager.optionsMenu = !GameManager.optionsMenu
		if GameManager.optionsMenu:
			GameManager.saveData()
			optionsMenuInstance = GameManager.spawnChild(get_node("/root"),"OptionsMenu","res://Assets/Prefabs/Options.tscn",Vector2(300,30),0,Vector2(.15,.15))
			#optionsMenuInstance = GameManager.spawnChild(UIoffset,"OptionsMenu","res://Assets/Prefabs/Options.tscn",Vector2(1200,135),0,Vector2(.15*4.166,.15*4.166))
		else:
			optionsMenuInstance.queue_free()
	if !dead:
		gravity(delta)
	if atAllActionable():
		if testLanding() and usingAbility != "thrust":
			localAudio.play("res://Assets/SFX/RobotLand1.wav",-20,1,.035)
		mouseLook(delta)
		mouseMovement = Vector3.ZERO
		attacks(delta)
		abilities(delta)
	if fullyActionable():
		move(delta)
	if semiActionable():
		jump(delta)
	testDrown()
	move_and_slide()
	#apply_floor_snap()
	if !drowning:
		cameraInterpolation(delta)
	inputBuffers()
	shotTimerL-=delta
	shotTimerR-=delta
	#frameDebug()
#remembers recently pressed buttons at the end of the main process#######################
func inputBuffers():
	upBuffer-=1
	downBuffer-=1
	leftBuffer-=1
	rightBuffer-=1
	jumpBuffer-=1
	if Input.is_action_just_pressed("jump"):
		jumpBuffer = 18
	if Input.is_action_just_pressed("up"):
		upBuffer = 15
	if Input.is_action_just_pressed("down"):
		downBuffer = 15
	if Input.is_action_just_pressed("left"):
		leftBuffer = 15
	if Input.is_action_just_pressed("right"):
		rightBuffer = 15
#used to get mouse look inputs#######################
func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseMotion:
		mouseMovement = event.relative
#returns true if the player is using an attacking ability on the left hand#######################
func usingAttackL():
	if (shootingL or swingingL):
		return true
	else:
		return false
#returns true if the player is using an attacking ability on the right hand#######################
func usingAttackR():
	if (shootingR or swingingR):
		return true
	else:
		return false
#returns false if the player has no authority#######################
func atAllActionable():
	if optionsMenuInstance!=null:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return false
	if drowning or GameManager.waiting or dead:
		return false
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return true
#returns false if the player is not in an ordinary state########################
func fullyActionable():
	if usingAbility == "":
		return true
	else:
		return false
#returns false if the player cannot interrupt its unordinary state##############
func semiActionable():
	if usingAbility == "" or interruptable:
		return true
	else:
		return false
#responsible for interpolating the camera to match its target position
#in a way that allows for a smooth gameplay experience
func cameraInterpolation(delta):
	var adjustedPosition = checkCameraPositionBlocked()
	camera.global_position = lerp(camera.global_position,adjustedPosition,delta*.25*(velocity.length()/2+4))
	cameraTarget.reparent(get_node("/root"),true) #ajust parenting to root to make QUAT global instead of local
	#cameraTarget.basis.y = Vector3.UP
	#cameraTarget.basis.x = Vector3.RIGHT
	camera.quaternion = camera.quaternion.slerp(cameraTarget.quaternion,delta*10)
	#camera.basis.y = Vector3.UP
	cameraTarget.reparent(scalar,true) #ajust parenting ^^^
#checks to see if the camera would be clipping into terrain before lining up with target
func checkCameraPositionBlocked():
	if cameraBlockCheck.is_colliding():
		#print("camera would clip! ["+str(cameraBlockCheck.get_collision_point())+"]")
		#return cameraBlockCheck.get_collision_point()
		return cameraTarget.global_position
	else:
		return cameraTarget.global_position
#rotates the player and the camera as the mouse is moved#######################
func mouseLook(delta):
	rotate_y(mouseMovement.x/-100)
	cameraTarget.rotation.x+=(-mouseMovement.y/70)
	if cameraTarget.rotation.x > 1.1 :
		cameraTarget.rotation.x = 1.1
	elif cameraTarget.rotation.x < -1.1 :
		cameraTarget.rotation.x = -1.1
	cameraTarget.position.y = (cameraTarget.rotation.x*-.7+1.195)
	cameraTarget.position.z = ((abs(cameraTarget.rotation.x-1)*.65+-1.39)*1.5)
#determines how much negative velocity player should receive on a given frame#######################
func gravity(delta):
	# Add Gravity.
	falling = false
	if !antiGravity:
		if !is_on_floor():
			if usingAbility == "thrust" and rotateCheckRay.is_colliding():
				global_position = lerp(global_position,rotateCheckRay.get_collision_point(),delta*5)
			if usingAbility == "thrust" and floorAnimCheck.is_colliding():
				global_position = lerp(global_position,rotateCheckRay.get_collision_point(),delta*100)
			falling = true
			gravityGain += delta*15
			velocity.y = lerp(velocity.y,-32.0-gravityGain,.06)
		elif usingAbility == "thrust":
			apply_floor_snap()
			#velocity.y = 0
#returns true if the mech was airborn last frame and traveling downwards with speed
func testLanding():
	var justLanded = false
	if is_on_floor() and airbornLastFrame and abs(airbornVelocity)>15:
		justLanded = true
		airbornLastFrame = false
	elif !floorAnimCheck.is_colliding():
		airbornLastFrame=true
		airbornVelocity = velocity.y
	return justLanded
#tests to see if water is underneath
func testDrown():
	if waterCheckRay.is_colliding():
		drown(waterCheckRay.get_collision_point())
		return false
#handles death upon colliding with water#######################
func drown(splashPos):
	if drowning:
		return
	dead = true
	drowning = true
	ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/water_splash.tscn",2,splashPos,Vector3.UP)
	var camStorage = cameraTarget.transform
	cameraTarget.reparent(get_node("/root"),true)
	var t =0
	collider.disabled = true
	while t<4:
		if t>.03:
			visible = false
		camera.fov = lerp(camera.fov,40.0,.002)
		cameraTarget.basis.y = lerp(cameraTarget.basis.y,(splashPos-cameraTarget.global_position).normalized(),.002)
		t+=1.0/60
		await get_tree().physics_frame
	match GameManager.gamemode:
		0,1:
			collider.disabled = false
			GameManager.respawn()
			cameraTarget.reparent(scalar,false)
			cameraTarget.transform = camStorage
			camera.global_transform = cameraTarget.global_transform
			await get_tree().physics_frame
	visible = true
	drowning = false
	dead = false
	
func die():
	dead = true
	if !is_multiplayer_authority():
		return
	var camStorage = cameraTarget.transform
	#cameraTarget.reparent(get_node("/root"),true)
	collider.disabled = true
	visible = false
	await get_tree().create_timer(3).timeout
	collider.disabled = false
	match GameManager.gamemode:
		0,1:
			GameManager.respawn()
			cameraTarget.reparent(scalar,false)
			cameraTarget.transform = camStorage
			camera.global_transform = cameraTarget.global_transform
			await get_tree().physics_frame
	visible = true
	dead = false
	
# Handle Jump.
func jump(delta):
	if jumpBuffer>0:
		if (is_on_floor()):
			localAudio.rpc("play","res://Assets/SFX/RobotJump1.wav",-10,1,.035)
			velocity.y=0
			velocity += (basis.y+Vector3.UP).normalized()*JUMP_VELOCITY
			jumpBuffer = 0
			jumpTimer=.5
			gravityGain = 0
		elif (wallCheckRay.is_colliding() and velocity.y<0):
			localAudio.rpc("play","res://Assets/SFX/RobotJump1.wav",-12,1.2,.1)
			velocity.y=0
			velocity += basis.y*JUMP_VELOCITY
			velocity += wallCheckRay.get_collision_normal(0)*1.3
			jumpBuffer = 0
			jumpTimer=.2
			gravityGain = 0
#determines how the mech will move in response to inputs while in an ordinary state#######################
func move(delta):	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Vector3.ZERO
	if true:
		camera.fov = lerp(camera.fov,95.0,0.1)
		rotateFlatten()
		var tryMove = false
		if Input.is_action_pressed("up"):
			tryMove = true
			direction +=Vector3(basis.z.x,0,basis.z.z).normalized()
		if Input.is_action_pressed("down"):
			tryMove = true
			direction -=Vector3(basis.z.x,0,basis.z.z).normalized()
		if Input.is_action_pressed("left"):
			tryMove = true
			direction +=Vector3(basis.x.x,0,basis.x.z).normalized()
		if Input.is_action_pressed("right"):
			tryMove = true
			direction -=Vector3(basis.x.x,0,basis.x.z).normalized()
		var runBoost = 1
		if testRunning():
			runBoost = 4
		if !atAllActionable():
			direction = Vector3.ZERO
		if !floorAnimCheck.is_colliding():
			#velocity.x = lerp(velocity.x,direction.x*SPEED*runBoost/2+momentum.x,.2)
			#velocity.z = lerp(velocity.z,direction.z*SPEED*runBoost/2+momentum.z,.2)
			pass
		else:
			velocity.x = lerp(velocity.x,direction.x*SPEED*runBoost+momentum.x,.1)
			velocity.z = lerp(velocity.z,direction.z*SPEED*runBoost+momentum.z,.1)	
			
#checks to see if the mech should be running instead of walking#######################
func testRunning():
	running = false
	if velocity.length()>SPEED*1.5 and basis.z.dot(velocity.normalized())>.5:
		running = true
		rotateToNormal()
	return running
#checks for attack usage and prevents from using other attacks until resolved#######################
func attacks(delta):
	if Input.is_action_just_pressed("swapWeaponPrimary"):
		toggleBackFire(false)
	if Input.is_action_just_pressed("swapWeaponSecondary"):
		toggleBackFire(true)
	if Input.is_action_pressed("weaponR"):
		if !usingAttackR():
			activeWeaponType(delta,"Right")
	if Input.is_action_pressed("weaponL"):
		if !usingAttackL():
			activeWeaponType(delta,"Left")
#checks for active weapon type
func activeWeaponType(delta,side):
	if !stats.backFireOn:
		match  PartCompendium.weapons[GameManager.myRobotData[side+"ArmWeapon"]].partCategory:
			"gun":
				shoot(delta,  PartCompendium.weapons[GameManager.myRobotData[side+"ArmWeapon"]],side.to_lower())
			"melee":
				swing(delta,  PartCompendium.weapons[GameManager.myRobotData[side+"ArmWeapon"]],side.to_lower())
	else:
		match  PartCompendium.backFire[GameManager.myRobotData[side+"BackFire"]].partCategory:
			"laser":
				shoot(delta,  PartCompendium.backFire[GameManager.myRobotData[side+"BackFire"]],side.to_lower())
#checks for ability usage and transitions into an ability state when used in an ordinary state#######################
func abilities(delta):
	if usingAbility !="thrust":
		momentum = momentum.lerp(Vector3.ZERO,delta*.5)
	if Input.is_action_just_pressed("thrust"):
		if fullyActionable():
			thrust(delta)
	if Input.is_action_just_pressed("up") and upBuffer>0:
		if semiActionable():
			dash(delta,basis.z,"Forward")
	elif Input.is_action_just_pressed("down") and downBuffer>0:
		if semiActionable():
			dash(delta,-basis.z,"Backward")
	elif Input.is_action_just_pressed("left") and leftBuffer>0:
		if semiActionable():
			dash(delta,basis.x,"Left")
	elif Input.is_action_just_pressed("right") and rightBuffer>0:
		if semiActionable():
			dash(delta,-basis.x,"Right")
#swings#######################
func swing(delta, weapon, side):
	match side:
		"left":
			localAnimatorOverlayL.seek(0)
			swingingL = true
		"right":
			localAnimatorOverlayR.seek(0)
			swingingR = true
	shotTimerL=-10
	shotTimerR=-10
	#await get_tree().process_frame
	var t = 0
	localAudio.rpc("play","res://Assets/SFX/Combat/ArmThrust.wav",-20,1,.035)
	var hit = false
	while(t<.4):
		if meleeHitbox1.get_overlapping_bodies().size()>1 and !hit:
			AttackManager.meleeAttack(meleeHitbox1.get_overlapping_bodies()[1],weapon,self)
			hit = true
		#rotateToNormal()
		t+=delta
		await get_tree().physics_frame
		#camera.fov = lerp(camera.fov,130.0,.003)
	match weapon.leftRight:
		"left":
			swingingL = false
		"right":
			swingingR = false
#turns back fire weapons from active to inactive and vice versa
func toggleBackFire(toggle):
	print("toggle")
	weaponSwitchComplete = false
	stats.backFireOn = toggle
#shoots#######################
func shoot(delta, weapon, side):
	match weapon.hitscan:
		true:
			var hitscanner
			match side.to_lower():
				"left":
					hitscanner = hitscannerL
					shootingL = true
					shotTimerL =5
					localAnimatorOverlayL.seek(0)
				"right":
					hitscanner = hitscannerR
					shootingR = true
					shotTimerR = 5
					localAnimatorOverlayR.seek(0)
			match weapon.partCategory:
				"gun":
					print("shoot gun")
					shootEffect1(hitscanner,delta,side,weapon)
				"laser":
					print("shoot laser")
					shootEffect2(hitscanner,delta,side,weapon)
		false:
			pass #need to add projectiles
			#AttackManager.shootProjectile(weapon,self)
################################
func shootEffect1(hitscanner,delta,side,weapon):
	AttackManager.shootHitscan(hitscanner,weapon,self)
	var t = 0
	localAudio.rpc("play","res://Assets/SFX/Combat/Guns 8.wav",-25,1,.035)
	match side:
		"left":
			muzzle1L.get_node("AnimationPlayer").play("flash")
			muzzle1L.get_node("AnimationPlayer").seek(0)
		"right":
			muzzle1R.get_node("AnimationPlayer").play("flash")
			muzzle1R.get_node("AnimationPlayer").seek(0)
	while(t<.6):
		#rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		#camera.fov = lerp(camera.fov,130.0,.003)
	match side:
		"left":
			shootingL = false
		"right":
			shootingR = false
func shootEffect2(hitscanner,delta,side,weapon):
	var t = 0
	print ("firing side: side")
	match side.to_lower():
		"right":
			ParticleManager.spawnParticleChildd("res://Assets/Prefabs/Particles/beam_charge_1.tscn","beamCharge", 99999,backFireRAnchor ,backFireRAnchor.global_position, Vector3.UP)
		"left":
			ParticleManager.spawnParticleChildd("res://Assets/Prefabs/Particles/beam_charge_1.tscn", "beamCharge",99999,backFireLAnchor ,backFireLAnchor.global_position, Vector3.UP)
	localAudio.rpc("play","res://Assets/SFX/Combat/Guns 8.wav",-25,1,.035)
	while(t<.6):
		#rotateToNormal()
		t+=delta
		await get_tree().physics_frame
	while(Input.is_action_pressed("weapon"+side.substr(0,1).to_upper()) and usingAbility != "thrust"):
		await get_tree().physics_frame
	AttackManager.shootHitscan(hitscanner,weapon,self)
	match side.to_lower():
		"left":
			shootingL = false
			if backFireLAnchor.get_node("beamCharge"):
				backFireLAnchor.get_node("beamCharge").queue_free()
		"right":
			shootingR = false
			if backFireRAnchor.get_node("beamCharge"):
				backFireRAnchor.get_node("beamCharge").queue_free()
	
################################
#ability that propels the mech forward while holding shift, can ride vertically up ramps#######################
func thrust(delta):
	usingAbility = "thrust"
	var t = 0
	localAudio.rpc("play","res://Assets/SFX/TransitionThrust.wav",-10,1,.035)
	cameraTarget.position.y = .5
	toggleBackFire(false)
	while(t<.8):
		rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		camera.fov = lerp(camera.fov,35.0,.05)
	#floor_max_angle = 90
	#floor_block_on_wall = false
	floor_constant_speed = false
	localAudio.rpc("play","res://Assets/SFX/EngineStart1.wav",-20,1,.035)
	ParticleManager.emitParticle(exhaust,true)
	await get_tree().create_timer(.2).timeout
	ParticleManager.emitParticleTree(exhaust,true)
	while true:
		if !Input.is_action_pressed("thrust"):
			localAudio.stopAll()
			break
		if Input.is_action_pressed("left"):
			velocity+=basis.x/10
		if Input.is_action_pressed("right"):
			velocity-=basis.x/10
		if localAudio.sfxConstant1.playing == false:
			localAudio.rpc("playConstant","res://Assets/SFX/EngineRev1.wav",-30,2,.025,1)
		if !floorCheckRay.is_colliding():
			ParticleManager.emitParticleTree(sparkL,false)
			ParticleManager.emitParticleTree(sparkR,false)
			antiGravity = false
			localAudio.rpc("stopConstant",2)
		else:
			ParticleManager.emitParticleTree(sparkL,true)
			ParticleManager.emitParticleTree(sparkR,true)
			antiGravity = true
			if localAudio.sfxConstant2.playing == false:
				localAudio.rpc("playConstant","res://Assets/SFX/Grinding.wav",-25,1,.025,2)
		if jumpBuffer>0 and floorCheckRay.is_colliding():
			jumpBuffer = 0 
			localAudio.rpc("stopAll")
			localAudio.rpc("play","res://Assets/SFX/RobotJump1.wav",-10,1,.135)
			velocity += Vector3.UP*JUMP_VELOCITY
			velocity.x = velocity.x
			velocity.z = velocity.z
			gravityGain = 0
			break
		rotateToNormal()
		direction = Vector3.ZERO
		direction += Vector3(basis.z.x,basis.z.y,basis.z.z).normalized()
		#print(str(direction) + " antigrav: "+ str(antiGravity))
		if floorCheckRay.is_colliding() and  basis.z.y<0:
			momentum += direction*delta*4
		else:
			momentum = momentum.lerp(Vector3.ZERO,delta*0.2)
		#apply_floor_snap()
		velocity.x = lerp(velocity.x,direction.x*(momentum.length()+1)*THRUST_SPEED+momentum.x,.285)
		velocity.z = lerp(velocity.z,direction.z*(momentum.length()+1)*THRUST_SPEED+momentum.z,.285)
		#velocity.y = lerp(velocity.y,direction.y*(momentum.length()+1)*THRUST_SPEED+momentum.y,.085)
		camera.fov = lerp(camera.fov,clamp(50+velocity.length()*7,0.0,150.0)*1.5,.01)
		if camera.fov>130:
			camera.fov = 130
			#pass
		await get_tree().physics_frame
	cameraTarget.position.y = 1.272
	#floor_max_angle = 1.0472
	#floor_block_on_wall = true
	localAudio.rpc("play","res://Assets/SFX/EngineShutdown1.wav",-30,1,.035)
	floor_constant_speed = true
	antiGravity = false
	usingAbility = ""
	ParticleManager.emitParticleTree(sparkL,false)
	ParticleManager.emitParticleTree(sparkR,false)
	ParticleManager.emitParticleTree(exhaust,false)
#ability that propels the mech by double tapping in a direction and suspends falling, 
#can be used in quick succession to "fly kick" across the map#######################
func dash(delta,dashDir,dir):
	match footAlternation:
		1:
			footAlternation = 2
		2:
			footAlternation = 1
	var alternation = footAlternation
	interruptable = false
	shotTimerL = -1
	shotTimerR = -1
	localAnimator.seek(0)
	usingAbility = "dash"+dir
	var t = 0
	velocity = dashDir*5*SPEED
	localAudio.rpc("play","res://Assets/SFX/RobotWalk1.wav",-15,1,.035)
	while(t<1):
		if jumpBuffer>0 and floorCheckRay.is_colliding():
			jumpBuffer = 0 
			localAudio.rpc("stopAll")
			localAudio.rpc("play","res://Assets/SFX/RobotJump1.wav",-10,1,.135)
			velocity += Vector3.UP*JUMP_VELOCITY
			velocity.x = velocity.x
			velocity.z = velocity.z
			break
		rotateToNormal()
		if t>.05:
			if Input.is_action_just_pressed("thrust"):
				thrust(delta)
				return
		if t>.8:
			if alternation!=footAlternation:
				return
			interruptable = true
		t+=delta*2.4
		await get_tree().physics_frame
		camera.fov = lerp(camera.fov,115.0,.03)
	usingAbility = ""
#if near the ground, rotates the mech to match the normal of the ground
#otherwise, rotateFlatten is called######################
func rotateToNormal():
	if rotateCheckRay.is_colliding():
		flattening = false
		var length = (global_position - rotateCheckRay.get_collision_point()).length()
		var normal = rotateCheckRay.get_collision_normal()
		var rotationSpeed = 0
		if (usingAbility == "thrust"):
			rotationSpeed = (16-clamp(length,0,16))/100
		else:
			rotationSpeed = (8-clamp(length,0,8))/50
		#print(rotationSpeed)
		basis.y = lerp(basis.y,normal,rotationSpeed) 
		basis.x = lerp(basis.x,-basis.z.cross(normal),rotationSpeed)
		basis = basis.orthonormalized()
		up_direction = normal
		#apply_floor_snap()
	else:
		flattening = true		
		rotateFlatten()
#corrects the rotation caused by rotateToNormal#######################
func rotateFlatten():
		basis.y = lerp(basis.y,Vector3(0,1,0),.03) 
		basis.x = lerp(basis.x,-basis.z.cross(Vector3(0,1,0)),.03)
		basis = basis.orthonormalized()
		up_direction = Vector3(0,1,0)
#picks the correct animation for the mech based on the current situation#######################
func animate():
	#$Scalar.scale = Vector3(10,10,10)
	if swingingR:
		#localAnimatorOverlayL.play("meleeAttack1_L",.015)
		#localAnimatorOverlayL.speed_scale = 1.6
		localAnimator.play("meleeAttack1_R",.25)
		localAnimator.speed_scale = 1.6
	elif swingingL:
		#localAnimatorOverlayL.play("meleeAttack1_L",.015)
		#localAnimatorOverlayL.speed_scale = 1.6
		localAnimator.play("meleeAttack1_L",.25)
		localAnimator.speed_scale = 1.6
	elif usingAbility == "thrust":
		if !rotateCheckRay.is_colliding():
			localAnimator.play("fall",.5)
			localAnimator.speed_scale = 0.75
		elif localAnimator.current_animation != "thrust" and localAnimator.current_animation != "":
			#print("thurst animation start, was just playing: "+localAnimator.current_animation)
			localAnimator.play("thrust",.25)
			localAnimator.speed_scale = 1.15
	elif usingAbility == "dashForward":
		localAnimator.play("dashForward"+str(footAlternation),.25)
		localAnimator.speed_scale = 1.2
	elif usingAbility == "dashBackward":
		localAnimator.play("dashBackward"+str(footAlternation),.25)
		localAnimator.speed_scale = 1.2
	elif usingAbility == "dashLeft":
		localAnimator.play("dashLeft",.25)
		localAnimator.speed_scale = 1.4
	elif usingAbility == "dashRight":
		localAnimator.play("dashRight",.25)
		localAnimator.speed_scale = 1.4
	elif floorAnimCheck.is_colliding():
		if velo.length()<1:
			localAnimator.play("idle",.5)
			localAnimator.speed_scale = 0.5
		elif velo.dot(Vector3(basis.z.x,0,basis.z.z).normalized()) > 0:
			if !running:
				localAnimator.play("walk",.35)
				localAnimator.speed_scale = 0.75
			else:
				localAnimator.play("run",.35)
				localAnimator.speed_scale = 1 
		elif localAnimator.current_animation!="walkBack":
			localAnimator.play("walkBack",.35)
			localAnimator.speed_scale = 0.75
	else:
		if velo.y>0:
			localAnimator.play("jump",.25)
			localAnimator.speed_scale = 0.45
		elif localAnimator.current_animation!="fall":
			localAnimator.play("fall",.5)
			localAnimator.speed_scale = 0.75
	###
	if !stats.backFireOn:
		localAnimatorOverlayL.speed_scale = 1
		localAnimatorOverlayR.speed_scale = 1
		if shootingL:
			localAnimatorOverlayL.play("rangedAttack1overlay_L",.015)
			localAnimatorOverlayL.speed_scale = .6
			#localAnimator.play("rangedAttack1_L",.015)
			#localAnimator.speed_scale = .6
		elif shotTimerL>0: 
			localAnimatorOverlayL.speed_scale = 0
			localAnimatorOverlayL.play("rangedAttack1overlay_L",.35)
			localAnimatorOverlayL.seek(0)
		else:
			localAnimatorOverlayL.stop()
	###
		if shootingR:
			localAnimatorOverlayR.play("rangedAttack1overlay_R",.015)
			localAnimatorOverlayR.speed_scale = .6
			#localAnimator.play("rangedAttack1_R",.015)
			#localAnimator.speed_scale = .6
		elif shotTimerR>0: 
			if shotTimerL>0:
				localAnimatorOverlayR.speed_scale = 0
				localAnimatorOverlayR.play("rangedAttack1overlay_R",.35)
			else:
				localAnimatorOverlayR.play("rangedAttack1overlay_R",.35)
			localAnimatorOverlayR.seek(0)
		else:
			localAnimatorOverlayR.stop()
	###
	if stats.backFireOn:
		localAnimatorOverlayR.stop()
		localAnimatorOverlayL.stop()
		$Scalar/mech/AnimationPlayer4.play("SwitchBackFire",.015)
		if !weaponSwitchComplete:
			$Scalar/mech/AnimationPlayer4.speed_scale = 1
		else:
			$Scalar/mech/AnimationPlayer4.seek(.8)
			$Scalar/mech/AnimationPlayer4.speed_scale = 0
	else:
		$Scalar/mech/AnimationPlayer4.play("SwitchMainWeapon",.015)
		if !weaponSwitchComplete:
			$Scalar/mech/AnimationPlayer4.speed_scale = 1
		else:
			$Scalar/mech/AnimationPlayer4.seek(.8)
			$Scalar/mech/AnimationPlayer4.speed_scale = 0
	###
	var torso = skeleton.find_bone("Bone")
	var pose = skeleton.get_bone_global_pose_no_override(torso)
	pose = pose.rotated_local(Vector3.RIGHT, -(cameraTarget.rotation.x+30)*1.5)
	pose = pose.rotated_local(Vector3.UP, -.4)
	skeleton.set_bone_global_pose_override(torso, pose, .5, true)

@rpc("any_peer", "reliable", "call_local")
func updateMechInGame():
	GameManager.updatePartGraphics(skeleton,GameManager.myRobotData)
	GameManager.updateRobotColor(skeleton,GameManager.myRobotData)


func _on_animation_player_4_animation_finished(anim_name):
	weaponSwitchComplete = true
