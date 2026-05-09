class_name ClientInterpolationSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_VisualNode, C_MovementSync]).iterate([C_VisualNode, C_MovementSync])

func process(entities: Array[Entity], _components: Array, delta: float) -> void:
	var visuals: Array = _components[0]
	var syncs: Array = _components[1]

	for i in range(entities.size()):
		var entity: Entity = entities[i]
		var sync: C_MovementSync = syncs[i]
		var vis: C_VisualNode = visuals[i]

		if not is_instance_valid(vis.node): continue
		var target_pos := sync.server_transform.origin

		if entity.has_component(C_LocalPlayer):
			# Rubberband correction if prediction fails heavily
			if vis.node.global_transform.origin.distance_to(target_pos) > 2.0:
				vis.node.global_transform.origin = target_pos
		else:
			# Smoothly interpolate other players/monsters visually
			vis.node.global_transform.origin = vis.node.global_transform.origin.lerp(target_pos, delta * 15.0)
