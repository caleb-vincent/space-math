extends Control

enum GameType {
	ADDITION 		= 0,
	SUBTRACTION 	= 1,
	FACT_FAMILIES 	= 2,
	MULTIPLICATION	= 3,
	DIVISION			= 4
}

var selectedGameType = GameType.ADDITION
var maxAnswer : int = 10


func _ready() -> void:
	$CenterContainer/VBoxContainer/MaxAnswerSelection.value = maxAnswer


func _process(delta):
	if Input.is_action_just_released("ui_cancel"):
		_exit()


func _on_GameType_selected(id: int) -> void:
	assert(id < GameType.size())
	selectedGameType = id
	if selectedGameType == GameType.MULTIPLICATION || selectedGameType == GameType.DIVISION:
		$CenterContainer/VBoxContainer/MaxAnswerSelection.value = 100
	else:
		$CenterContainer/VBoxContainer/MaxAnswerSelection.value = 10


func  _on_MaxAnswer_changed(id: float) -> void:
	maxAnswer = id
	pass


func _exit() -> void:
	visible = false
