class_name HeaderLabel extends Label

func _init(font_color := UIColors.Base.PURE_WHITE) -> void:
	theme_type_variation = "HeaderLabel"
	add_theme_color_override("font_color", font_color)
