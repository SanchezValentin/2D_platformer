extends CharacterBody2D

@onready var anchor: Node2D = $Anchor
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer

@export var movement_data : PlayerMetricsData

func _physics_process(delta: float) -> void:
	var x_input = Input.get_axis("ui_left", "ui_right")
	
	if not is_on_floor():
		velocity.y += movement_data.gravity_scale * delta
		
	velocity.x = x_input * movement_data.speed
	
	if is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("ui_accept"):
			velocity.y = movement_data.jump_velocity
			coyote_jump_timer.stop()
	
	var was_on_floor = is_on_floor()
	
	if x_input == 0:
		animation_player_upper.play("stand")
		animation_player_lower.play("stand")
	else:
		anchor.scale.x = sign(x_input)
		animation_player_upper.play("run")
		animation_player_lower.play("run")
		
	if not is_on_floor():
		animation_player_lower.play("jump")
		animation_player_upper.play("jump")
		
	move_and_slide()
	var just_left_ledge = was_on_floor  and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_jump_timer.start()
