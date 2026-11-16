extends Node

@export var is_timed : bool
@export var activation_time : float

@onready var gate_sprite: Sprite2D = $Gate/Sprite2D
@onready var switch_sprite: Sprite2D = $Switch/Sprite2D

@onready var switch_collider: Area2D = $Switch/Area2D
@onready var gate_collider: CollisionShape2D = $Gate/StaticBody2D/CollisionShape2D

var is_activated : bool
var start_activation_time : float

func _ready() -> void:
	is_activated = false
	
	switch_collider.body_entered.connect(on_switch_pressed)

func _process(delta: float) -> void:
	if is_timed and is_activated:		
		if (Time.get_ticks_msec() >= start_activation_time + activation_time * 1000):
			on_time_elapsed()
	


func on_switch_pressed(body: Node2D):
	if not is_activated:
		is_activated = true
		gate_sprite.visible = false
		gate_collider.set_deferred("disabled", true)
	
	start_activation_time = Time.get_ticks_msec()
	
func on_time_elapsed():
	is_activated = false
	
	gate_sprite.visible = true
	gate_collider.disabled = false
	
