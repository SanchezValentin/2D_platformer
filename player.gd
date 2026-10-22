extends CharacterBody2D

@onready var anchor: Node2D = $Anchor
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var coyote_wall_jump_timer: Timer = $CoyoteWallJumpTimer

@export var movement_data : PlayerMetricsData

func _physics_process(delta: float) -> void:
	var x_input = Input.get_axis("move_left", "move_rigth")
	var was_on_floor = is_on_floor()
	var was_on_wall = is_on_wall_only()
	apply_gravity(delta)
	
	if is_on_floor() or coyote_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("jump"):
			velocity.y = -movement_data.jump_velocity
			coyote_jump_timer.stop()
	
	if is_on_wall_only() or coyote_wall_jump_timer.time_left > 0.0:
		if Input.is_action_just_pressed("jump") :
			velocity.y = -movement_data.wall_jump_Y
			velocity.x = movement_data.wall_jump_X * get_wall_normal().x
			coyote_wall_jump_timer.stop()
	
	if x_input == 0:
		apply_friction(delta)
		animation_player_upper.play("stand")
		animation_player_lower.play("stand")
	else:
		accelerate_horizontaly(x_input, delta)
		anchor.scale.x = sign(x_input)
		animation_player_upper.play("run")
		animation_player_lower.play("run")
	
	if not is_on_floor():
		animation_player_lower.play("jump")
		animation_player_upper.play("jump")
	move_and_slide()
	
	var just_left_wall = was_on_wall and not is_on_wall_only()
	if just_left_wall:
		coyote_wall_jump_timer.start()
	
	var just_left_ledge = was_on_floor  and not is_on_floor() and velocity.y >= 0
	if just_left_ledge:
		coyote_jump_timer.start()

func accelerate_horizontaly(horizontal_direction: float, delta: float) -> void:
	var acceleration_amount: float = movement_data.acceleration
	if not is_on_floor(): acceleration_amount = movement_data.air_acceleration
	velocity.x = move_toward(velocity.x, movement_data.speed * horizontal_direction, acceleration_amount * delta * abs(horizontal_direction))

func apply_friction(delta) -> void :
	var friction_amount: float = movement_data.friction
	if not is_on_floor(): friction_amount = movement_data.air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)

func apply_gravity(delta) -> void:
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += movement_data.up_gravity * delta
		else:
			velocity.y += movement_data.down_gravity * delta 
