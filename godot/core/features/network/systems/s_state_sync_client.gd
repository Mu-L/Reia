class_name ClientStateSyncSystem extends System

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var state_sync_bucket := NetworkRouter.client.consume_bucket(OpCode.ID.STATE_SYNC)
	if not state_sync_bucket.is_empty():
		_process_state_sync(state_sync_bucket)

func _process_state_sync(bucket: Dictionary) -> void:
	# State Syncs are usually broadcasted, so there's usually only 1 "packet" in the bucket
	# sent by the Server (ID 0), containing data for dozens of entities inside its payload.
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]
	
	for i in range(offsets.size()):
		reader.seek(offsets[i])
		
		var entity_count := reader.get_u32()
		
		for e in range(entity_count):
			var net_id := reader.get_64()
			var target_x := reader.get_float()
			var target_y := reader.get_float()
			var target_z := reader.get_float()
			
			var entity := EntityMap.client.get_entity(net_id)
			if not entity: continue
			
			var sync_comp := entity.get_component(C_MovementSync) as C_MovementSync
			if sync_comp:
				# Store the absolute truth from the server
				sync_comp.server_transform.origin = Vector3(target_x, target_y, target_z)
