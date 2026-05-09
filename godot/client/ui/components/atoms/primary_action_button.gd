class_name PrimaryActionButton extends Button

func _init() -> void:
	theme_type_variation = "PrimaryActionButton"
	mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	
	# Internal hover/click audio can be safely wired here
	# mouse_entered.connect(_play_hover_sound)
	# pressed.connect(_play_click_sound)
