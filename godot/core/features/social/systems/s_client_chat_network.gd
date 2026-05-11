class_name ClientChatNetworkSystem extends System

var reader := StreamPeerBuffer.new()

func query() -> QueryBuilder:
	process_empty = true
	return super.query()

func process(_entities: Array[Entity], _components: Array, _delta: float) -> void:
	var chat_message_bucket := NetworkRouter.client.consume_bucket(OpCode.ID.CHAT_MESSAGE)
	if not chat_message_bucket.is_empty():
		_process_chat(chat_message_bucket)

func _process_chat(bucket: Dictionary) -> void:
	var offsets: PackedInt32Array = bucket["offsets"]
	reader.data_array = bucket["data"]

	for i in range(offsets.size()):
		reader.seek(offsets[i])
		var sender := reader.get_string()
		var message := reader.get_string()

		UIEventBus.world.chat_message_received.emit(sender, message)
