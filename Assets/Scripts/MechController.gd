extends CharacterBody3D
########################
const SPEED = 7
const THRUST_SPEED = 24
const JUMP_VELOCITY = 40
########################
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
@export var muzzle1L: GPUParticles3D
@export var muzzle1R: GPUParticles3D
@export var collider: CollisionShape3D
@export var UIoffset: Control
########################
var mouseMovement = Vector3.ZERO
var direction = Vector3.ZERO
var usingAbility = ""
var interruptable = false
var antiGravity = false
var airbornLastFrame = false
var airbornVelocity = 0
var upBuffer = 0
var rightBuffer = 0
var leftBuffer = 0
var downBuffer = 0
var jumpBuffer = 0
var footAlternation = 1
var shootingL = false
var swingingL = false
var shootingR = false
var swingingR = false
var running = false
var shotTimerL = 0
var shotTimerR = 0
var drowning = false
var gravityGain = 0
var flattening = false
var optionsMenuInstance
#initializes mech#######################
func _ready():
	UIAnimator.play("fadeFromBlack")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	GameManager.playerCamera = camera
	camera.reparent(get_node("/root"),true)
	GameManager.updatePartGraphics(skeleton)
#main process for mech controller#######################
func _physics_process(delta):
	if Input.is_action_just_pressed("esc"):
		GameManager.optionsMenu = !GameManager.optionsMenu
		if GameManager.optionsMenu:
			GameManager.saveData()
			optionsMenuInstance = GameManager.spawnChild(get_node("/root"),"OptionsMenu","res://Assets/Prefabs/Options.tscn",Vector2(300,30),0,Vector2(.15,.15))
			#optionsMenuInstance = GameManager.spawnChild(UIoffset,"OptionsMenu","res://Assets/Prefabs/Options.tscn",Vector2(1200,135),0,Vector2(.15*4.166,.15*4.166))
		else:
			optionsMenuInstance.queue_free()
	gravity(delta)
	if atAllActionable():
		if testLanding():
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
	apply_floor_snap()
	if !drowning:
		cameraInterpolation(delta)
	animate()
	inputBuffers()
	shotTimerL-=delta
	shotTimerR-=delta
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
	if drowning or GameManager.waiting:
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
	camera.global_position = lerp(camera.global_position,adjustedPosition,delta*5)
	cameraTarget.reparent(get_node("/root"),true) #ajust parenting to root to make QUAT global instead of local
	camera.quaternion = camera.quaternion.slerp(cameraTarget.quaternion,delta*5)
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
	if !antiGravity:
		if !floorCheckRay.is_colliding():
			if usingAbility == "thrust":
				gravityGain += delta*40
				velocity.y = lerp(velocity.y,-32.0-gravityGain,.02)
				velocity+= basis.y * -1.5
			else:
				gravityGain += delta*15
				velocity.y = lerp(velocity.y,-32.0-gravityGain,.02)
		else:
			gravityGain = 0
			velocity.y = lerp(velocity.y,-16.0,.04)
#returns true if the mech was airborn last frame and traveling downwards with speed
func testLanding():
	var justLanded = false
	if is_on_floor() and airbornLastFrame and abs(airbornVelocity)>5:
		justLanded = true
		airbornLastFrame = false
	elif !floorCheckRay.is_colliding():
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
	drowning = true
	ParticleManager.spawnParticle("res://Assets/Prefabs/Particles/water_splash.tscn",2,splashPos)
	var posStorage = cameraTarget.position
	var rotStorage = cameraTarget.rotation #these are relative so we can restore to them later
	var basisyStorage = cameraTarget.basis.y
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
		0:
			GameManager.respawn()
			cameraTarget.reparent(scalar,false)
			cameraTarget.position = posStorage
			cameraTarget.rotation = rotStorage
			cameraTarget.basis.y = basisyStorage
			camera.position = posStorage
			camera.rotation = rotStorage
			camera.basis.y = basisyStorage
			await get_tree().physics_frame
	visible = true
	collider.disabled = false
	drowning = false
# Handle Jump.
func jump(delta):
	if jumpBuffer>0:
		if (is_on_floor()):
			localAudio.play("res://Assets/SFX/RobotJump1.wav",-10,1,.035)
			velocity += (basis.y+Vector3.UP).normalized()*JUMP_VELOCITY
			jumpBuffer = 0
		elif (wallCheckRay.is_colliding() and velocity.y<0):
			localAudio.play("res://Assets/SFX/RobotJump1.wav",-12,1.2,.1)
			velocity.y=0
			velocity += basis.y*JUMP_VELOCITY
			velocity += wallCheckRay.get_collision_normal(0)*1.3
			jumpBuffer = 0
#determines how the mech will move in response to inputs while in an ordinary state#######################
func move(delta):	
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	direction = Vector3.ZERO
	if true:
		camera.fov = lerp(camera.fov,100.0,0.1)
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
			runBoost = 3
		if !atAllActionable():
			direction = Vector3.ZERO
		if is_on_floor():
			velocity.x = lerp(velocity.x,direction.x*SPEED*runBoost,.2)
			velocity.z = lerp(velocity.z,direction.z*SPEED*runBoost,.2)
		else:
			velocity.x = lerp(velocity.x,direction.x*SPEED*runBoost,.01)
			velocity.z = lerp(velocity.z,direction.z*SPEED*runBoost,.01)	
#checks to see if the mech should be running instead of walking#######################
func testRunning():
	running = false
	if velocity.length()>SPEED*1.5 and basis.z.dot(velocity.normalized())>.5:
		running = true
		rotateToNormal()
	return running
#checks for attack usage and prevents from using other attacks until resolved#######################
func attacks(delta):
	if Input.is_action_pressed("weaponR"):
		if !usingAttackR():
			match GameManager.myRobotData["RightArmWeapon"].partCategory:
				"gun":
					shoot(delta, GameManager.myRobotData["RightArmWeapon"])
				"melee":
					swing(delta, GameManager.myRobotData["RightArmWeapon"])
	if Input.is_action_pressed("weaponL"):
		if !usingAttackL():
			match GameManager.myRobotData["LeftArmWeapon"].partCategory:
				"gun":
					shoot(delta, GameManager.myRobotData["LeftArmWeapon"])
				"melee":
					swing(delta, GameManager.myRobotData["LeftArmWeapon"])
#checks for ability usage and transitions into an ability state when used in an ordinary state#######################
func abilities(delta):
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
func swing(delta, weapon):
	match weapon.leftRight:
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
	localAudio.play("res://Assets/SFX/Combat/ArmThrust.wav",-20,1,.035)
	while(t<.6):
		#rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		#camera.fov = lerp(camera.fov,130.0,.003)
	match weapon.leftRight:
		"left":
			swingingL = false
		"right":
			swingingR = false
#shoots#######################
func shoot(delta, weapon):
	match weapon.leftRight:
		"left":
			shootingL = true
			shotTimerL =5
			localAnimatorOverlayL.seek(0)
		"right":
			shootingR = true
			shotTimerR = 5
			localAnimatorOverlayR.seek(0)
	#await get_tree().process_frame
	var t = 0
	localAudio.play("res://Assets/SFX/Combat/Guns 8.wav",-25,1,.035)
	match weapon.leftRight:
		"left":
			ParticleManager.emitParticle(muzzle1L,false)
			ParticleManager.emitParticle(muzzle1L,true)
		"right":
			ParticleManager.emitParticle(muzzle1R,false)
			ParticleManager.emitParticle(muzzle1R,true)
	while(t<.6):
		#rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		#camera.fov = lerp(camera.fov,130.0,.003)
	match weapon.leftRight:
		"left":
			shootingL = false
		"right":
			shootingR = false
#ability that propels the mech forward while holding shift, can ride vertically up ramps#######################
func thrust(delta):
	usingAbility = "thrust"
	var t = 0
	localAudio.play("res://Assets/SFX/TransitionThrust.wav",-10,1,.035)
	while(t<.8):
		rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		camera.fov = lerp(camera.fov,130.0,.003)
	#floor_max_angle = 90
	#floor_block_on_wall = false
	floor_constant_speed = false
	localAudio.play("res://Assets/SFX/EngineStart1.wav",-20,1,.035)
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
			localAudio.playConstant("res://Assets/SFX/EngineRev1.wav",-30,2,.025,1)
		if !floorCheckRay.is_colliding():
			ParticleManager.emitParticleTree(sparkL,false)
			ParticleManager.emitParticleTree(sparkR,false)
			antiGravity = false
			localAudio.stopConstant(2)
		else:
			ParticleManager.emitParticleTree(sparkL,true)
			ParticleManager.emitParticleTree(sparkR,true)
			antiGravity = true
			if localAudio.sfxConstant2.playing == false:
				localAudio.playConstant("res://Assets/SFX/Grinding.wav",-25,1,.025,2)
		if jumpBuffer>0 and floorCheckRay.is_colliding():
			jumpBuffer = 0 
			localAudio.stopAll()
			localAudio.play("res://Assets/SFX/RobotJump1.wav",-10,1,.135)
			velocity += Vector3.UP*JUMP_VELOCITY
			velocity.x = velocity.x*2
			velocity.z = velocity.z*2
			break
		rotateToNormal()
		direction = Vector3.ZERO
		direction += Vector3(basis.z.x,basis.z.y,basis.z.z).normalized()
		#print(str(direction) + " antigrav: "+ str(antiGravity))
		velocity.x = lerp(velocity.x,direction.x*THRUST_SPEED,.035)
		velocity.z = lerp(velocity.z,direction.z*THRUST_SPEED,.035)
		camera.fov = lerp(camera.fov,clamp(70+velocity.length()*6,0.0,150.0),.03)
		if camera.fov>150:
			camera.fov = 150
			#pass
		await get_tree().physics_frame
	#floor_max_angle = 1.0472
	#floor_block_on_wall = true
	localAudio.play("res://Assets/SFX/EngineShutdown1.wav",-30,1,.035)
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
	localAudio.play("res://Assets/SFX/RobotWalk1.wav",-15,1,.035)
	while(t<1.4):
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
			rotationSpeed = .3
		else:
			rotationSpeed = (8-clamp(length,0,8))/50
		print(rotationSpeed)
		basis.y = lerp(basis.y,normal,rotationSpeed) 
		basis.x = lerp(basis.x,-basis.z.cross(normal),rotationSpeed)
		basis = basis.orthonormalized()
		up_direction = normal
		apply_floor_snap()
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
	if usingAbility == "thrust":
		if flattening:
			localAnimator.play("fall",.5)
			localAnimator.speed_scale = 0.75
		else:
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
	elif floorCheckRay.is_colliding():
		if velocity.length()<1:
			localAnimator.play("idle",.5)
			localAnimator.speed_scale = 0.5
		elif velocity.dot(Vector3(basis.z.x,0,basis.z.z).normalized()) > 0:
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
		if velocity.y>0:
			localAnimator.play("jump",.25)
			localAnimator.speed_scale = 0.45
		elif localAnimator.current_animation!="fall":
			localAnimator.play("fall",.5)
			localAnimator.speed_scale = 0.75
	###
	if swingingL:
		localAnimatorOverlayL.play("meleeAttack1_L",.015)
		localAnimatorOverlayL.speed_scale = 1.6
	elif shootingL:
		localAnimatorOverlayL.play("rangedAttack1_L",.015)
		localAnimatorOverlayL.speed_scale = .6
	elif shotTimerL>0: 
		localAnimatorOverlayL.play("rangedAttack1_L",.35)
		localAnimatorOverlayL.seek(0)
	elif shotTimerL>-0.5:
		#localAnimatorOverlayL.play(localAnimator.current_animation,.35)
		localAnimatorOverlayR.stop()
	else:
		localAnimatorOverlayL.stop()
	###
	if swingingR:
		localAnimatorOverlayR.play("meleeAttack1_R",.015)
		localAnimatorOverlayR.speed_scale = 1.6
	elif shootingR:
		localAnimatorOverlayR.play("rangedAttack1_R",.015)
		localAnimatorOverlayR.speed_scale = .6
	elif shotTimerR>0: 
		if shotTimerL>0:
			localAnimatorOverlayR.play("rangedAttack1Done_R",.35)
		else:
			localAnimatorOverlayR.play("rangedAttack1_R",.35)
		localAnimatorOverlayR.seek(0)
	elif shotTimerR>-0.5:
		#localAnimatorOverlayR.play(localAnimator.current_animation,.35)
		localAnimatorOverlayR.stop()
	else:
		localAnimatorOverlayR.stop()
	###
	var torso = skeleton.find_bone("Bone")
	var pose = skeleton.get_bone_global_pose_no_override(torso)
	pose = pose.rotated_local(Vector3.RIGHT, -cameraTarget.rotation.x*1.5)
	pose = pose.rotated_local(Vector3.UP, -.4)
	skeleton.set_bone_global_pose_override(torso, pose, .5, true)
