extends Node

func emitParticleTree(particleRoot, active):
	particleRoot.emitting = active
	for child in particleRoot.get_children():
		if child is GPUParticles3D:
			child.emitting = active
			emitParticleTree(child,active)

func emitParticle(particleRoot, active):
	particleRoot.emitting = active

func spawnParticle(path, lifetime, pos, normal):
	rpc("rpcSpawnParticle",path,lifetime,pos,normal)

@rpc("any_peer", "reliable", "call_local")
func rpcSpawnParticle(path, lifetime, pos,normal):
	var thisParticle = GameManager.spawn("particleSpawn",path,pos,Vector3.ZERO,Vector3(1,1,1))
	if thisParticle.get_node("AnimationPlayer"):
		thisParticle.get_node("AnimationPlayer").play("main")
	else:
		thisParticle.basis.y = normal
		thisParticle.emitting = true
	
	await get_tree().create_timer(lifetime).timeout
	thisParticle.queue_free()

func spawnParticleChild(path, lifetime, parent,pos, normal):
	rpc("rpcSpawnParticle",path,lifetime,pos,normal)

@rpc("any_peer", "reliable", "call_local")
func rpcSpawnParticleChild(path, lifetime, parent,pos,normal):
	var thisParticle = GameManager.spawnChild(parent,"particleSpawn",path,pos,Vector3.ZERO,Vector3(1,1,1))
	if thisParticle.get_node("AnimationPlayer"):
		thisParticle.get_node("AnimationPlayer").play("splashFull")
	else:
		thisParticle.basis.y = normal
		thisParticle.emitting = true
	
	await get_tree().create_timer(lifetime).timeout
	thisParticle.queue_free()
	
func spawnParticleChildd(path, _name, lifetime, parent,pos, normal):
	var thisParticle = GameManager.spawnChild(parent,_name,path,Vector3.ZERO,Vector3.ZERO,Vector3(1,1,1))
	if thisParticle.get_node("AnimationPlayer"):
		thisParticle.get_node("AnimationPlayer").play("splashFull")
	else:
		thisParticle.basis.y = normal
		thisParticle.emitting = true
	print (thisParticle.global_position)
	
	if lifetime<100:
		await get_tree().create_timer(lifetime).timeout
		thisParticle.queue_free()
