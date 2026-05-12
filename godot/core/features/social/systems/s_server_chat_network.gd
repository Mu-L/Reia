class_name ServerChatNetworkSystem extends System

var reader := StreamPeerBuffer.new()
var writer := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var send_chat_bucket := NetworkRouter.server.consume_bucket(OpCode.ID.SEND_CHAT)
	if not send_chat_bucket.is_empty():
		_process_chat(send_chat_bucket)

func _process_chat(bucket: Dictionary) -> void:
	var ids: PackedInt64Array = bucket["ids"]
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(ids.size()):
		var client_id := ids[i]
		var player := EntityMap.server.get_entity(client_id)
		if not player:
			push_warning("[ServerChatNetworkSystem] Discarded chat message from unknown client ID: %d" % client_id)
			continue

		var username := (player.get_component(C_Username) as C_Username).username

		reader.seek(offsets[i])
		var message := reader.get_string()

		# Prepare broadcast payload
		writer.clear()
		writer.put_string(username)
		writer.put_string(message)

		var all_clients := EntityMap.server.get_all_active_clients()
		NetworkRouter.server.queue_broadcast(all_clients, OpCode.ID.CHAT_MESSAGE, writer.data_array)
