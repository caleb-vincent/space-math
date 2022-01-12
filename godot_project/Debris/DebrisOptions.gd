extends Control

const settings_file = "user://DebrisOptions.save"

var maxAnswer : int = 10
var minAnswer : int = 0


################################################################################
#	Inherited Methods
################################################################################


func _ready() -> void:
	_load_settings()
	$CenterContainer/VBoxContainer/MaxAnswerSelection.value = maxAnswer
	$CenterContainer/VBoxContainer/MinAnswerSelection.value = minAnswer


func _process(delta):
	if Input.is_action_just_released("ui_cancel"):
		_exit()

################################################################################
#	Private Methods
################################################################################


func _save_settings():
	var f = File.new()
	f.open(settings_file, File.WRITE)
	f.store_var(minAnswer)
	f.store_var(maxAnswer)
	f.close()
	
	
func _load_settings():
	var f = File.new()
	if f.file_exists(settings_file):
		f.open(settings_file, File.READ)
		minAnswer = f.get_var()
		maxAnswer = f.get_var()


################################################################################
#	Signal Handling
################################################################################


func _exit() -> void:
	_save_settings()
	visible = false


func _on_MaxAnswerSelection_value_changed(value: float) -> void:
	maxAnswer = value


func _on_MinAnswerSelection_value_changed(value: float) -> void:
	minAnswer = value
