class_name PlayerHealthBar extends ProgressBar

func _init() -> void:
	custom_minimum_size = Vector2(300, 24)
	show_percentage = true
	
	var bg := StyleBoxFlat.new()
	bg.bg_color = UIColors.Base.PURE_BLACK
	bg.set_border_width_all(2)
	bg.border_color = UIColors.Base.CHIP_BLUE
	
	var fill := StyleBoxFlat.new()
	fill.bg_color = UIColors.Action.DENY_RED
	
	add_theme_stylebox_override("background", bg)
	add_theme_stylebox_override("fill", fill)

func _ready() -> void:
	UIUtils.safe_connect(UIEventBus.combat.player_health_changed, _on_health_changed, "PlayerHealthBar")

	value = 100
	max_value = 100

func _on_health_changed(current: int, maximum: int) -> void:
	max_value = maximum
	var t := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	var _tween_prop := t.tween_property(self , "value", current, 0.2)
