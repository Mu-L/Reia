class_name BodyTextLabel extends Label

func _init(font_color := UIColors.Base.SOFT_WHITE) -> void:
	theme_type_variation = "BodyTextLabel"
	add_theme_color_override("font_color", font_color)
