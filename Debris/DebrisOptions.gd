extends Control

var maxAnswer : int = 10
var minAnswer : int = 0


func _ready() -> void:
	$CenterContainer/VBoxContainer/MaxAnswerSelection.value = maxAnswer
	$CenterContainer/VBoxContainer/MinAnswerSelection.value = minAnswer


func _process(delta):
	if Input.is_action_just_released("ui_cancel"):
		_exit()


func _exit() -> void:
	visible = false


func _on_MaxAnswerSelection_value_changed(value: float) -> void:
	maxAnswer = value


func _on_MinAnswerSelection_value_changed(value: float) -> void:
	minAnswer = value
