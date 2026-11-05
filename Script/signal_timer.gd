class_name SignalTimer extends Timer 

signal on_started
signal on_time_passed(ratio: float)
signal on_stopped

var was_stopped : bool

func _ready() -> void:
	if (autostart):
		was_stopped = false
	else:
		was_stopped = true
	
func _process(_delta: float) -> void:
	
	if was_stopped and not is_stopped():
		on_started.emit()
		was_stopped = false
		
	if not was_stopped and is_stopped():
		on_stopped.emit()
		was_stopped = true
	
	if not is_stopped():
		on_time_passed.emit(time_left / wait_time)
