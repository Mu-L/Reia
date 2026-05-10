class_name ServerStateSyncSystem extends System

var writer := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	# We only care about entities that have moved (we would tag them with C_NetworkSyncDirty in Physics)
	return q.with_all([C_Transform, C_NetworkSyncDirty]).iterate([C_Transform])

func process(entities: Array[Entity], components: Array, _delta: float) -> void:
	if entities.is_empty(): return

	var transforms: Array = components[0]
	writer.clear()

	# Header: How many entities are updating?
	writer.put_u32(entities.size())

	# Payload: Pack the state
	for i in range(entities.size()):
		var entity := entities[i]
		var trans: C_Transform = transforms[i]
		var pos := trans.transform.origin

		# Get the network ID (Positive for players, Negative for monsters)
		writer.put_64(EntityMap.server.get_network_id(entity))
		writer.put_float(pos.x)
		writer.put_float(pos.y)
		writer.put_float(pos.z)

		# Remove the dirty flag so we don't sync them again next frame unless they move
		cmd.remove_component(entity, C_NetworkSyncDirty)

	# 3. Broadcast to all clients!
	# In a real MMO, you filter 'target_ids' to only include clients in the same Chunk.
	# For now, we broadcast to everyone (ID 0 in some setups, or pass an array of all connected clients)
	var all_connected_clients: PackedInt64Array = _get_all_active_clients()

	NetworkRouter.server.queue_broadcast(all_connected_clients, OpCode.ID.STATE_SYNC, writer.data_array)

## Dynamically grab all valid player IDs so the broadcast array isn't empty.
func _get_all_active_clients() -> PackedInt64Array:
	var ids := PackedInt64Array()

	for net_id: int in EntityMap.server._net_id_to_entity.keys():
		if net_id > 0: # 0 is server, negatives are NPCs
			var ids_failed := ids.push_back(net_id)
			if ids_failed:
				push_error("[ServerStateSyncSystem] Failed to queue client ID %d for state sync broadcast!" % net_id)

	# Fallback for local loopback demo if it executes before the player fully mounts
	if ids.is_empty():
		var ids_failed := ids.push_back(0)
		if ids_failed:
			push_error("[ServerStateSyncSystem] Failed to queue fallback client ID 0 for state sync broadcast!")

	return ids
