class_name ChatBox extends VBoxContainer

@onready var chat_log: RichTextLabel = $ChatLog
@onready var input_field: BaseLineEdit = $InputField

func _ready() -> void:
	UIUtils.safe_connect(input_field.text_submitted, _on_text_submitted, "ChatBox text_submitted")
	UIUtils.safe_connect(UIEventBus.world.chat_message_received, _on_message_received, "ChatBox chat_message_received")

func _on_text_submitted(text: String) -> void:
	if text.strip_edges().is_empty(): return

	# Clear input
	input_field.text = ""
	input_field.release_focus()

	# Tell the network router to send the chat packet
	var writer := StreamPeerBuffer.new()
	writer.put_string(text)
	NetworkRouter.client.queue_packet(0, OpCode.ID.SEND_CHAT, writer.data_array)

func _on_message_received(sender: String, message: String) -> void:
	chat_log.append_text("[b]%s:[/b] %s\n" % [sender, message])
