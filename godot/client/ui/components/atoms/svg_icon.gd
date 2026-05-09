class_name SVGIcon extends TextureRect

func _init() -> void:
	expand_mode = TextureRect.EXPAND_FIT_WIDTH
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
