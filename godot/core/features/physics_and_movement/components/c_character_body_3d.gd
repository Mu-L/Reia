class_name C_CharacterBody3D extends Component

var node: CharacterBody3D
var physics_initialized: bool = false

func _init(_node: CharacterBody3D = null) -> void:
	node = _node
