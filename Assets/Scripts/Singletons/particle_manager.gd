extends Node

func emitParticleTree(particleRoot, active):
	particleRoot.emitting = active
	for child in particleRoot.get_children():
		if child is GPUParticles3D:
			child.emitting = active
			emitParticleTree(child,active)

func emitParticle(particleRoot, active):
	particleRoot.emitting = active

func spawnParticle(path, lifetime, pos):
	var thisParticle = GameManager.spawn("particleSpawn",path,pos,Vector3.ZERO)
	thisParticle.emitting = true
	await get_tree().create_timer(lifetime).timeout
	thisParticle.queue_free()
