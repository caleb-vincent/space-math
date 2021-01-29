extends RigidBody2D

export var value : int = -1 setget _set_value, _get_value
var isAnswer : bool = false setget _set_answer


func _init() -> void:
	_setInactive()


func _on_VisibilityNotifier2D_screen_exited() -> void:
	queue_free()


func _set_value(v : int) -> void:
	$Label.text = str(v)


func _get_value() -> int:
	return int($Label.text)


func _set_answer(a : bool ) -> void:
	if a && !isAnswer:
		_setActive()
		isAnswer = a
	elif !a && isAnswer:
		_setInactive()
		isAnswer = a


func _setInactive() -> void:
	set_collision_layer(0x8)
	set_collision_mask(get_collision_mask() & ~0x2)
	#$DebugParticles.visible = false


func _setActive() -> void:
	set_collision_layer(0x4)
	set_collision_mask(get_collision_mask() | 0x2)
	#$DebugParticles.visible = true
