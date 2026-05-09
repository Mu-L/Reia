class_name InteractionPrompt extends CenterContainer

var _label: BodyTextLabel

func _init() -> void:
	_label = BodyTextLabel.new()
	_label.add_theme_color_override("font_color", UIColors.Base.PURE_WHITE)
	_label.add_theme_color_override("font_outline_color", UIColors.Base.PURE_BLACK)
	_label.add_theme_constant_override("outline_size", 4)
	add_child(_label)

func _ready() -> void:
	hide()
	UIUtils.safe_connect(UIEventBus.world.show_interaction_prompt, _show_prompt, "InteractionPrompt show_interaction_prompt")
	UIUtils.safe_connect(UIEventBus.world.hide_interaction_prompt, hide, "InteractionPrompt hide_interaction_prompt")

func _show_prompt(item_name: String, verb: String) -> void:
	_label.text = "%s\n[E] %s" % [item_name, verb]
	show()
