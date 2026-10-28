extends CharacterBody2D

enum states { WALK,RUN,STOP,WALLRIDE }

@onready var anchor: Node2D = $Anchor
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var coyote_wall_jump_timer: Timer = $CoyoteWallJumpTimer
@onready var run_change_dir_timer: Timer = $RunChangeDirTimer

const DEFAULT_PLAYER_METRICS = preload("uid://dh0p37pdne8c5")
const RUN_PLAYER_METRICS = preload("uid://7pgjeelcqljd")

@export var state: = states.WALK
@export var movement_data : PlayerMetricsData

var run_count = 0
var x_dir = 1.0
var store_dir = true
var change_dir = true
var can_change = false
var is_changing = false

func _ready() -> void:
	movement_data = DEFAULT_PLAYER_METRICS

func _physics_process(delta: float) -> void:
	match state:
		states.WALK:
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
			
			if velocity.x == (movement_data.speed * x_input):
				if store_dir:
					x_dir = x_input
					store_dir = false
				
				if Input.is_action_just_pressed("action") and is_on_floor_only() and x_dir == x_input:
					run_count += 1
					print(run_count)
				
				elif x_dir != x_input :
					run_count = 0
					store_dir = true
				
			if run_count >= 3 and x_input != 0:
				x_dir = x_input
				run_count = 0
				movement_data = RUN_PLAYER_METRICS
				store_dir = true
				state = states.RUN
				
		states.RUN:
			var x_input = Input.get_axis("move_left", "move_rigth")
			apply_gravity(delta)
			
			if is_on_floor():
				if x_input != x_dir and change_dir:
					is_changing = true
					change_dir = false
					run_change_dir_timer.start()
				
				if  x_input == 0  and can_change:
					can_change = false
					change_dir = true
					is_changing = false
					state = states.STOP
				
				if x_input != 0 and x_dir != x_input and can_change:
					can_change = false
					x_dir = x_input
					is_changing = false
					change_dir = true
				
			if (is_on_floor() or coyote_jump_timer.time_left > 0.0) and not is_changing:
				if Input.is_action_just_pressed("jump"):
					velocity.y = -movement_data.jump_velocity
					coyote_jump_timer.stop()
			
			if not is_on_floor():
				animation_player_lower.play("jump")
				animation_player_upper.play("jump")
			else:
				accelerate_horizontaly(x_dir, delta)
				anchor.scale.x = sign(x_dir)
				animation_player_upper.play("run")
				animation_player_lower.play("run")
			
			move_and_slide()
			

func accelerate_horizontaly(horizontal_direction: float, delta: float) -> void:
	var current_state_speed = movement_data.speed
	var acceleration_amount: float = movement_data.acceleration
	if not is_on_floor(): acceleration_amount = movement_data.air_acceleration
	velocity.x = move_toward(velocity.x, current_state_speed * horizontal_direction, acceleration_amount * delta * abs(horizontal_direction))

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

func _on_run_change_dir_timer_timeout() -> void:
	can_change = true
	print("passed")
	run_change_dir_timer.stop()
