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

const settings_file = "user://DodgeOptions.save"


################################################################################
#	Inherited Methods
################################################################################


func _ready() -> void:
	_load_settings()
	$CenterContainer/VBoxContainer/MaxAnswerSelection.value = maxAnswer
	$CenterContainer/VBoxContainer/GameTypeSelection.select(selectedGameType)


func _process(delta):
	if Input.is_action_just_released("ui_cancel"):
		_exit()


################################################################################
#	Public Methods
################################################################################


################################################################################
#	Private Methods
################################################################################

func _save_settings():
	var f = File.new()
	f.open(settings_file, File.WRITE)
	f.store_var(selectedGameType)
	f.store_var(maxAnswer)
	f.close()
	
	
func _load_settings():
	var f = File.new()
	if f.file_exists(settings_file):
		f.open(settings_file, File.READ)
		selectedGameType = f.get_var()
		maxAnswer = f.get_var()


################################################################################
#	Signal Handling
################################################################################


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
	_save_settings()
	visible = false
