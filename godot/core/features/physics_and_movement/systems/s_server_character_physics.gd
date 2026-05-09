class_name ServerCharacterPhysicsSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_Transform, C_Velocity, C_CharacterBody3D]) \
	.with_none([C_Stunned, C_Dead]) \
	.iterate([C_Transform, C_Velocity, C_CharacterBody3D])

func process(entities: Array[Entity], components: Array, delta: float) -> void:
	var transforms: Array = components[0]
	var velocities: Array = components[1]
	var character_bodies: Array = components[2]

	for i in range(entities.size()):
		var entity: Entity = entities[i]
		var trans: C_Transform = transforms[i]
		var vel: C_Velocity = velocities[i]
		var body_comp: C_CharacterBody3D = character_bodies[i]

		var body := body_comp.node

		if not is_instance_valid(body): continue

		if not body_comp.physics_initialized:
			body.global_transform = trans.transform
			body_comp.physics_initialized = true
			continue

		var current_vel := body.velocity

		# Apply Gravity
		if not body.is_on_floor():
			current_vel.y -= 9.8 * delta

		current_vel.x = vel.direction.x * vel.speed
		current_vel.z = vel.direction.z * vel.speed

		body.velocity = current_vel
		var _collided := body.move_and_slide()

		# ONLY sync to network if the position actually changed
		if body.global_transform.origin != trans.transform.origin:
			trans.transform = body.global_transform
			if not entity.has_component(C_NetworkSyncDirty):
				cmd.add_component(entity, C_NetworkSyncDirty.new())
