class_name ServerPlayerInputSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_MoveInput, C_Velocity]) \
	.with_none([C_Stunned, C_Dead]) \
	.iterate([C_MoveInput, C_Velocity])

func process(entities: Array[Entity], components: Array, _delta: float) -> void:
	var inputs: Array = components[0]
	var velocities: Array = components[1]

	for i in range(entities.size()):
		var input: C_MoveInput = inputs[i]
		var vel: C_Velocity = velocities[i]

		vel.direction = Vector3(input.dir.x, 0, input.dir.y).normalized()
		vel.speed = 5.0 if vel.direction.length_squared() > 0 else 0.0
