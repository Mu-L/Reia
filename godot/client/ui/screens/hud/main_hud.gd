class_name MainHUD extends Control

@onready var chat_box: ChatBox = $MarginContainer/BottomLeft/ChatBox
@onready var health_bar: PlayerHealthBar = $MarginContainer/TopLeft/PlayerHealthBar
@onready var interaction_prompt: InteractionPrompt = $CenterOffset/InteractionPrompt

func _ready() -> void:
	pass
