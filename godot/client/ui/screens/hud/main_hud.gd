class_name MainHUD extends Control

@onready var chat_box: ChatBox = $BottomLeftAnchor/ChatBox
@onready var health_bar: PlayerHealthBar = $BottomCenterAnchor/PlayerHealthBar
@onready var interaction_prompt: InteractionPrompt = $CenterAnchor/InteractionPrompt

func _ready() -> void:
	pass
