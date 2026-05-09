class_name ServerSkillExecutionSystem extends System

func query() -> QueryBuilder:
	return q.with_all([C_CastRequest])

func process(entities: Array[Entity], _components: Array, _delta: float) -> void:
	for entity in entities:
		var request := entity.get_component(C_CastRequest) as C_CastRequest
		
		var target := request.target
		if target and target.has_component(C_Health) and not target.has_component(C_Dead):
			# TODO: For now, we just blindly apply 25 damage.
			# In the future, this needs to validate range, cooldowns, and apply formulas.
			cmd.add_component(target, C_DamageEvent.new(25, "PHYSICAL"))
			
		cmd.remove_component(entity, C_CastRequest)
