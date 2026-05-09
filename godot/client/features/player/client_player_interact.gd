extends Camera3D
## Attached to the Local Player's Camera3D

const INTERACT_RANGE = 3.0
const COMBAT_RANGE = 15.0

var _current_target: Entity = null
var _crosshair: ColorRect

func _ready() -> void:
	# Build a simple dot crosshair purely in code
	_crosshair = ColorRect.new()
	_crosshair.custom_minimum_size = Vector2(4, 4)
	_crosshair.color = UIColors.Base.PURE_WHITE
	_crosshair.set_anchors_preset(Control.PRESET_CENTER)
	_crosshair.name = "Crosshair"

	# Add it to the global UI Canvas so it renders on top
	var canvas := get_tree().root.get_node_or_null("ClientMain/UICanvas")
	if canvas: canvas.add_child(_crosshair)

func _exit_tree() -> void:
	if is_instance_valid(_crosshair): _crosshair.queue_free()

func _physics_process(_delta: float) -> void:
	var space_state := get_world_3d().direct_space_state
	var center := get_viewport().get_visible_rect().size / 2
	var origin := project_ray_origin(center)
	var end := origin + project_ray_normal(center) * COMBAT_RANGE

	var query := PhysicsRayQueryParameters3D.create(origin, end)
	# Masking for Layer 14 (Items) and Layer 13 (NPC/Enemy Hurtboxes)
	query.collision_mask = (1 << 13) | (1 << 12)
	var result := space_state.intersect_ray(query)

	if result and result.collider:
		@warning_ignore("unsafe_cast")
		var hit_node := (result.collider as Node).get_parent() as Entity
		if hit_node is Entity:
			_current_target = hit_node

			# --- Interaction Logic (Range 3.0m) ---
			var interactable := hit_node.get_component(C_Interactable) as C_Interactable
			@warning_ignore("unsafe_cast")
			if interactable and origin.distance_to(result.position as Vector3) <= INTERACT_RANGE:
				# Convert the hashed Enum ID back into a readable string (e.g., "PICKUP" -> "Pickup")
				# For localization, you can wrap this in tr(): tr("ACTION_" + verb_key)
				var verb_key: String = ActionVerb.ID.find_key(interactable.action_verb)
				var display_verb := verb_key.capitalize() if verb_key else "Interact"

				# Tell the UI to show "Bone [E to Pickup]"
				UIEventBus.world.show_interaction_prompt.emit(interactable.item_name, display_verb)

				if Input.is_action_just_pressed("interact"): # Default 'E' or 'F'
					_send_interaction_request(hit_node, interactable.interact_op_code)
				return

			# --- Combat Hover Logic (Range 15.0m) ---
			if hit_node.has_component(C_Health):
				# Turn crosshair red when hovering a valid target
				_crosshair.color = UIColors.Action.DENY_RED
				UIEventBus.world.hide_interaction_prompt.emit()
				return

	# Reset UI if nothing hit
	_crosshair.color = UIColors.Base.PURE_WHITE
	UIEventBus.world.hide_interaction_prompt.emit()

func _unhandled_input(event: InputEvent) -> void:
	# Attack on Left Click
	if event is InputEventMouseButton and (event as InputEventMouseButton).button_index == MOUSE_BUTTON_LEFT and (event as InputEventMouseButton).pressed:
		if _current_target and _current_target.has_component(C_Health):
			_send_attack_request(_current_target)

func _send_interaction_request(target_entity: Entity, op_code: int) -> void:
	var net_id := EntityMap.client.get_network_id(target_entity)
	var writer := StreamPeerBuffer.new()
	writer.put_64(net_id)

	# We blindly send the OpCode defined by the component.
	# Zero client-side branching.
	NetworkRouter.client.queue_packet(0, op_code, writer.data_array)

func _send_attack_request(target_entity: Entity) -> void:
	var net_id := EntityMap.client.get_network_id(target_entity)
	var writer := StreamPeerBuffer.new()
	writer.put_64(net_id)
	writer.put_u16(1) # Basic Attack Skill ID

	# Send CAST_SKILL to Server
	NetworkRouter.client.queue_packet(0, OpCode.ID.CAST_SKILL, writer.data_array)
