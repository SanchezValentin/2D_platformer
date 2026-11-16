extends Node2D

@onready var area_2d: Area2D = $Area2D

func _ready() -> void:
	area_2d.body_entered.connect(on_body_entered_reset_scene)
	
	
func on_body_entered_reset_scene(body : Node2D):
	call_deferred("reset_scene")

func reset_scene():
	get_tree().reload_current_scene()
