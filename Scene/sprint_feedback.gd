extends Sprite2D

@export var min_size : float
@export var max_size : float
@onready var signal_timer: SignalTimer = $"../../Accel_SignalTimer"

func _ready() -> void:
	visible = false;
	signal_timer.on_started.connect(on_feedback_start)
	signal_timer.on_stopped.connect(on_feedback_stop)
	signal_timer.on_time_passed.connect(on_feedback_tick)
	
func on_feedback_start():
	visible = true
	global_scale = Vector2.ONE * max_size
	
func on_feedback_tick(ratio : float):
	var value = lerp(max_size, min_size, 1 - ratio)
	scale = Vector2.ONE * value
	
func on_feedback_stop():
	visible = false
