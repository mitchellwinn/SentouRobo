extends CharacterBody3D
########################
const SPEED = 2
const THRUST_SPEED = 13
const JUMP_VELOCITY = 11
########################
@export var skeleton: Skeleton3D
@export var camera: Camera3D
@export var floorCheckRay: ShapeCast3D
@export var wallCheckRay: ShapeCast3D
@export var waterCheckRay: RayCast3D
@export var rotateCheckRay: RayCast3D
@export var localAnimatorOverlay: AnimationPlayer
@export var localAnimator: AnimationPlayer
@export var UIAnimator: AnimationPlayer
@export var localAudio: Node
@export var sparkL: GPUParticles3D
@export var sparkR: GPUParticles3D
@export var exhaust: GPUParticles3D
@export var gunArm: BoneAttachment3D
@export var gunShoulder: BoneAttachment3D
@export var muzzleFlash: GPUParticles3D
########################
var mouseMovement = Vector3.ZERO
var direction = Vector3.ZERO
var usingAbility = ""
var antiGravity = false
var airbornLastFrame = false
var airbornVelocity = 0
var upBuffer = 0
var rightBuffer = 0
var leftBuffer = 0
var downBuffer = 0
var jumpBuffer = 0
var footAlternation = 1
var shooting = false
var swinging = false
var running = false
var shotTimer = 0
var drowning = false
#initializes mech#######################
func _ready():
	UIAnimator.play("fadeFromBlack")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
#main process for mech controller#######################
func _physics_process(delta):
	gravity()
	if atAllActionable():
		if testLanding():
			localAudio.play("res://Assets/SFX/RobotLand1.wav",-20,1,.035)
		mouseLook(delta)
		mouseMovement = Vector3.ZERO
		attacks(delta)
		abilities(delta)
		if fullyActionable():
			move(delta)
		testDrown()
	move_and_slide()
	animate()
	inputBuffers()
	shotTimer-=delta
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
#returns true if the player is using an attacking ability#######################
func usingAttack():
	if shooting or swinging:
		return true
	else:
		return false
#returns false if the player has no authority#######################
func atAllActionable():
	if drowning:
		return false
	else:
		return true
#returns false if the player is not in an ordinary state#######################
func fullyActionable():
	if usingAbility == "":
		return true
	else:
		return false
#rotates the player and the camera as the mouse is moved#######################
func mouseLook(delta):
	rotate_y(mouseMovement.x/-100)
	camera.rotation.x+=(-mouseMovement.y/70)
	if camera.rotation.x > 1.1 :
		camera.rotation.x = 1.1
	elif camera.rotation.x < -1.1 :
		camera.rotation.x = -1.1
	camera.position.y = camera.rotation.x*-.7+1.195
	camera.position.z = (abs(camera.rotation.x-1)*.65+-1.39)*1.5
#determines how much negative velocity player should receive on a given frame#######################
func gravity():
	# Add Gravity.
	if !antiGravity:
		if !is_on_floor():
			velocity.y = lerp(velocity.y,-16.0,.02)
		else:
			velocity.y = lerp(velocity.y,-16.0,.02)
#returns true if the mech was airborn last frame and traveling downwards with speed
func testLanding():
	var justLanded = false
	if is_on_floor() and airbornLastFrame and abs(airbornVelocity)>2:
		justLanded = true
		airbornLastFrame = false
	elif !is_on_floor():
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
	var posStorage = camera.position
	var rotStorage = camera.rotation #these are relative so we can restore to them later
	var basisyStorage = camera.basis.y
	camera.reparent(get_node("/root"),true)
	var t =0
	while t<4:
		camera.fov = lerp(camera.fov,40.0,.002)
		camera.basis.y = lerp(camera.basis.y,(splashPos-camera.global_position).normalized(),.002)
		t+=1.0/60
		await get_tree().physics_frame
	match GameManager.gamemode:
		0:
			camera.reparent(self,false)
			camera.position = posStorage
			camera.rotation = rotStorage
			camera.basis.y = basisyStorage
			GameManager.respawn()
			await get_tree().physics_frame
	drowning = false
#determines how the mech will move in response to inputs while in an ordinary state#######################
func move(delta):	
	# Handle Jump.
	if jumpBuffer>0:
		if (is_on_floor()):
			localAudio.play("res://Assets/SFX/RobotJump1.wav",-10,1,.035)
			velocity += basis.y*JUMP_VELOCITY
			jumpBuffer = 0
		elif (wallCheckRay.is_colliding() and velocity.y<0):
			localAudio.play("res://Assets/SFX/RobotJump1.wav",-12,1.2,.1)
			velocity.y=0
			velocity += basis.y*JUMP_VELOCITY
			velocity += wallCheckRay.get_collision_normal(0)*1.3
			jumpBuffer = 0

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
		if is_on_floor():
			velocity.x = lerp(velocity.x,direction.x*SPEED*runBoost,.6)
			velocity.z = lerp(velocity.z,direction.z*SPEED*runBoost,.6)
		else:
			velocity.x = lerp(velocity.x,direction.x*SPEED*runBoost,.01)
			velocity.z = lerp(velocity.z,direction.z*SPEED*runBoost,.01)	
#checks to see if the mech should be running instead of walking#######################
func testRunning():
	running = false
	if Vector3(velocity.x,0,velocity.z).length()>2.2 and basis.z.dot(velocity.normalized())>.5:
		running = true
		rotateToNormal()
	return running
#checks for attack usage and prevents from using other attacks until resolved#######################
func attacks(delta):
	if Input.is_action_pressed("shoot"):
		if !usingAttack():
			shoot(delta)
	if Input.is_action_just_pressed("swing"):
		if !usingAttack():
			swing(delta)
#checks for ability usage and transitions into an ability state when used in an ordinary state#######################
func abilities(delta):
	if Input.is_action_just_pressed("thrust"):
		if fullyActionable():
			thrust(delta)
	if Input.is_action_just_pressed("up") and upBuffer>0:
		if fullyActionable():
			dash(delta,basis.z,"Forward")
	elif Input.is_action_just_pressed("down") and downBuffer>0:
		if fullyActionable():
			dash(delta,-basis.z,"Backward")
	elif Input.is_action_just_pressed("left") and leftBuffer>0:
		if fullyActionable():
			dash(delta,basis.x,"Left")
	elif Input.is_action_just_pressed("right") and rightBuffer>0:
		if fullyActionable():
			dash(delta,-basis.x,"Right")
#swings#######################
func swing(delta):
	swinging = true
	shotTimer=-10
	#await get_tree().process_frame
	localAnimatorOverlay.seek(0)
	var t = 0
	localAudio.play("res://Assets/SFX/Combat/ArmThrust.wav",-20,1,.035)
	while(t<.6):
		#rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		#camera.fov = lerp(camera.fov,130.0,.003)
	swinging = false
#shoots#######################
func shoot(delta):
	shooting = true
	shotTimer=5
	#await get_tree().process_frame
	localAnimatorOverlay.seek(0)
	var t = 0
	localAudio.play("res://Assets/SFX/Combat/Guns 8.wav",-25,1,.035)
	ParticleManager.emitParticle(muzzleFlash,false)
	ParticleManager.emitParticle(muzzleFlash,true)
	while(t<.6):
		#rotateToNormal()
		t+=delta*2.4
		await get_tree().physics_frame
		#camera.fov = lerp(camera.fov,130.0,.003)
	shooting = false
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
		if jumpBuffer>0 and rotateCheckRay.is_colliding():
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
		velocity.x = lerp(velocity.x,direction.x*THRUST_SPEED,.01)
		velocity.z = lerp(velocity.z,direction.z*THRUST_SPEED,.01)
		camera.fov = lerp(camera.fov,70+velocity.length()*6,.03)
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
	shotTimer = -1
	localAnimator.seek(0)
	usingAbility = "dash"+dir
	var t = 0
	velocity = dashDir*10
	localAudio.play("res://Assets/SFX/RobotWalk1.wav",-15,1,.035)
	while(t<.8):
		rotateToNormal()
		if t>.2:
			if Input.is_action_just_pressed("thrust"):
				thrust(delta)
				return
		t+=delta*2.4
		await get_tree().physics_frame
		camera.fov = lerp(camera.fov,115.0,.03)
	usingAbility = ""
	match footAlternation:
		1:
			footAlternation = 2
		2:
			footAlternation = 1
#if near the ground, rotates the mech to match the normal of the ground
#otherwise, rotateFlatten is called######################
func rotateToNormal():
	if rotateCheckRay.is_colliding():
		var normal = rotateCheckRay.get_collision_normal()
		basis.y = lerp(basis.y,normal,.1) 
		basis.x = lerp(basis.x,-basis.z.cross(normal),.1)
		basis = basis.orthonormalized()
		up_direction = normal
		apply_floor_snap()
	else:
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
		localAnimator.play("Local/thrust",.25)
		localAnimator.speed_scale = 1.15
	elif usingAbility == "dashForward":
		localAnimator.play("Local/dashForward"+str(footAlternation),.25)
		localAnimator.speed_scale = 1.2
	elif usingAbility == "dashBackward":
		localAnimator.play("Local/dashBackward"+str(footAlternation),.25)
		localAnimator.speed_scale = 1.2
	elif usingAbility == "dashLeft":
		localAnimator.play("Local/dashLeft",.25)
		localAnimator.speed_scale = 1.4
	elif usingAbility == "dashRight":
		localAnimator.play("Local/dashRight",.25)
		localAnimator.speed_scale = 1.4
	elif is_on_floor():
		if velocity.length()<1:
			localAnimator.play("Local/idle",.5)
			localAnimator.speed_scale = 0.5
		elif velocity.dot(Vector3(basis.z.x,0,basis.z.z).normalized()) > 0:
			if !running:
				localAnimator.play("Local/walk",.35)
				localAnimator.speed_scale = 0.75
			else:
				localAnimator.play("Local/run",.35)
				localAnimator.speed_scale = 1 
		elif localAnimator.current_animation!="Local/walkBack":
			localAnimator.play("Local/walkBack",.35)
			localAnimator.speed_scale = 0.75
	else:
		if velocity.y>0:
			localAnimator.play("Local/jump",.25)
			localAnimator.speed_scale = 0.45
		elif localAnimator.current_animation!="Local/fall":
			localAnimator.play("Local/fall",.5)
			localAnimator.speed_scale = 0.75
	if swinging:
		localAnimatorOverlay.play("Local/meleeAttack1",.015)
		localAnimatorOverlay.speed_scale = 1.6
	elif shooting:
		localAnimatorOverlay.play("Local/rangedAttack1",.015)
		localAnimatorOverlay.speed_scale = .6
	elif shotTimer>0: 
		localAnimatorOverlay.play("Local/rangedAttack1",.35)
		localAnimatorOverlay.seek(0)
	elif shotTimer>-0.5:
		localAnimatorOverlay.play(localAnimator.current_animation,.35)
	else:
		localAnimatorOverlay.stop()
	var torso = skeleton.find_bone("Bone")
	var pose = skeleton.get_bone_global_pose_no_override(torso)
	pose = pose.rotated_local(Vector3.RIGHT, -camera.rotation.x*2)
	pose = pose.rotated_local(Vector3.UP, -.4)
	skeleton.set_bone_global_pose_override(torso, pose, .5, true)
