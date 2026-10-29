extends CharacterBody2D

enum states { WALK,RUN,STOP,WALLRIDE }

@onready var anchor: Node2D = $Anchor
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_camera: AnimationPlayer = $PlayerCamera/AnimationCamera
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var coyote_wall_jump_timer: Timer = $CoyoteWallJumpTimer
@onready var run_change_dir_timer: Timer = $RunChangeDirTimer
@onready var accel_timer: Timer = $AccelTimer
@onready var player_camera: Camera2D = $PlayerCamera

const DEFAULT_PLAYER_METRICS = preload("uid://dh0p37pdne8c5")
const RUN_PLAYER_METRICS = preload("uid://7pgjeelcqljd")

@export var state: = states.WALK
@export var movement_data : PlayerMetricsData

var run_count = 0
var x_dir = 1.0
var store_dir = true
var change_dir = false
var can_change = false
var store_time = true
var slow = false


func _ready() -> void:
	movement_data = DEFAULT_PLAYER_METRICS

func _physics_process(delta: float) -> void:
	var x_input = Input.get_axis("move_left", "move_rigth")
	apply_gravity(delta)
	match state:
		states.WALK:
			var was_on_floor = is_on_floor()
			var was_on_wall = is_on_wall_only()
			
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
			
			if x_input != 0 :
				if velocity.x == movement_data.speed * roundi(x_input):
					if store_dir:
						x_dir = x_input
						store_dir = false
					
					if store_time:
						store_time = false
						accel_timer.start()
				
				if Input.is_action_just_pressed("action") and is_on_floor_only() and x_dir == x_input:
					if accel_timer.time_left > 0.0 and accel_timer.time_left < 1.0:
						accel_timer.stop()
						run_count += 1
						if run_count <= 2:
							animation_camera.play("accelerate")
						print(run_count)
						store_time = true
						
				elif x_dir != x_input :
					run_count = 0
					store_dir = true
				
			if run_count >= 3 and x_input != 0:
				animation_camera.play("RunStateTransition")
				x_dir = x_input
				run_count = 0
				movement_data = RUN_PLAYER_METRICS
				store_dir = true
				state = states.RUN
	
		states.RUN:
			# if player ask to change direction launch timer
			if change_dir and accel_timer.is_stopped(): 
				accel_timer.start()
			
			if is_on_floor():
				
				# if x_input = direction and not changing direction than move forward
				if x_input == x_dir and change_dir == false:
					accelerate_horizontaly(x_dir, delta)
					anchor.scale.x = sign(x_dir)
				
				# if player want to change direction => check if input is on purpose
				if x_input != x_dir and not change_dir:
					change_dir = true
					run_change_dir_timer.start()
				
				# if change of direction and no x_input => go on stop state
				if  x_input == 0 and can_change:
					can_change = false
					change_dir = false
					animation_camera.play("SlowDown")
					state = states.STOP
				
				# if change of direction and button pushed whilde change direction timer on than direction = x_input
				if x_input != 0 and x_dir != x_input and can_change:
					change_dir = false
					can_change = false
					apply_friction(delta)
					accel_timer.start()
					if Input.is_action_just_pressed("action") and velocity.x == 0.0 or accel_timer.time_left > 0.0:
						store_time = false
						x_dir = x_input
					
				#else : 
					#state = states.WALK
					#animation_camera.play("SlowDown")
				
			# if grounded and not changing direction than jump
			if (is_on_floor() or coyote_jump_timer.time_left > 0.0) and not change_dir:
				if Input.is_action_just_pressed("jump"):
					velocity.y = -movement_data.jump_velocity
					coyote_jump_timer.stop()
			 
			if not is_on_floor():
				animation_player_lower.play("jump")
				animation_player_upper.play("jump")
			else:
				animation_player_upper.play("run")
				animation_player_lower.play("run")
			
			move_and_slide()
	
		states.STOP:
			
				apply_friction(delta)
				animation_player_upper.play("stand")
				animation_player_lower.play("stand")
	
		states.WALLRIDE:
			pass
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
	# if input is maintained than bool becomes true and change direction allowed
	can_change = true
	run_change_dir_timer.stop()

func _on_accel_timer_timeout() -> void:
	# When timer reach 0, if in Run state than velocity = 0
	store_time = true
	if state == states.RUN : 
		pass
		#velocity.x = 0
