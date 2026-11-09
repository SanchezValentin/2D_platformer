extends CharacterBody2D

enum states { WALK,RUN,STOP,WALLRIDE }

#Animation Node
@onready var animation_player_lower: AnimationPlayer = $AnimationPlayerLower
@onready var animation_player_upper: AnimationPlayer = $AnimationPlayerUpper
@onready var animation_camera: AnimationPlayer = $PlayerCamera/AnimationCamera

#Timer Node
@onready var coyote_jump_timer: Timer = $CoyoteJumpTimer
@onready var coyote_wall_jump_timer: Timer = $CoyoteWallJumpTimer
@onready var run_change_dir_timer: Timer = $RunChangeDirTimer
@onready var accel_signal_timer: SignalTimer = $Accel_SignalTimer
@onready var action_buffer: Timer = $ActionBuffer

#Misc
@onready var player_camera: Camera2D = $PlayerCamera
@onready var ray_cast_upper: RayCast2D = $Anchor/RayCastUpper
@onready var ray_cast_lower: RayCast2D = $Anchor/RayCastLower
@onready var anchor: Node2D = $Anchor

#Player Metrics
const DEFAULT_PLAYER_METRICS = preload("uid://dh0p37pdne8c5")
const RUN_PLAYER_METRICS = preload("uid://7pgjeelcqljd")
const WALLRIDE_PLAYER_METRICS = preload("uid://cyqrsovdvsigr")

#Public Variable
@export var state: = states.WALK
@export var accel_window: float = 1.0
@export var movement_data : PlayerMetricsData

# var to check accel condition
var run_count = 0
var store_time = true
var is_accelerating = false

# var to store x_input and y_input at given time
var x_dir = 1.0
var saved_x_dir = 1.0
var y_dir = 1.0
var saved_y_dir = 1.0

# var to define different condition of state machine
var store_dir = true
var change_dir = false
var can_change = false
var changing_state = false

var just_hit_wall = false
var chose_dir = false
var change_y_dir = false
var go_up = false
var go_down = false
var go_ground = false
var exit_wallride = false


#var to buffer
var store_action = false

func _ready() -> void:
	movement_data = DEFAULT_PLAYER_METRICS
	
	animation_player_lower.current_animation_changed.connect(func(animation_name: String):
		animation_player_upper.play(animation_name)
		)
	
	accel_signal_timer.wait_time = accel_window

func _physics_process(delta: float) -> void:
	var x_input = Input.get_axis("move_left", "move_rigth")
	
	match state:
		states.WALK:
			apply_gravity(delta)
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
				animation_player_lower.play("stand")
			else:
				accelerate_horizontaly(x_input, delta)
				anchor.scale.x = sign(x_input)
				animation_player_lower.play("run")
			
			if not is_on_floor():
				animation_player_lower.play("jump")
			
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
					
				if Input.is_action_just_pressed("action") and is_on_floor_only() and x_dir == x_input:
					if store_time:
						store_time = false
						accel_signal_timer.start()
					
					if not accel_signal_timer.is_stopped():
						run_count += 1
						if run_count <= 2:
							animation_camera.play("accelerate")
						store_time = true
					
				if x_dir != x_input :
					run_count = 0
					store_dir = true
				
				if run_count >= 3:
					accel_signal_timer.stop()
					animation_camera.play("RunStateTransition")
					store_dir = true
					store_time = true
					x_dir = x_input
					run_count = 0
					movement_data = RUN_PLAYER_METRICS
					state = states.RUN
	
		states.RUN:
			apply_gravity(delta)
			if  is_on_floor():
				
				if can_change :
					can_change = false
					# if change of direction and no x_input => go on stop state
					if  x_input == 0:
						animation_camera.play("SlowDown")
						state = states.STOP
					if x_input != 0:
						saved_x_dir = x_input
						changing_state = true
						accel_signal_timer.start()
						apply_friction(delta)
				
				# if x_input = direction and not changing direction than move forward
				if x_input == x_dir and not change_dir:
					accelerate_horizontaly(x_dir, delta)
					anchor.scale.x = sign(x_dir)
				
				# if player want to change direction => check if input is on purpose
				if x_input != x_dir and not change_dir and not changing_state:
					if state == states.RUN:
						change_dir = true
						run_change_dir_timer.start()
				
				if changing_state:
					buffer_action()
					if store_action == true and accel_signal_timer.time_left > 0.0:
						accel_signal_timer.stop()
						changing_state = false
						store_action = false
						action_buffer.stop()
						x_dir = saved_x_dir
			
			# if grounded and not changing direction than jump
			if (is_on_floor() or coyote_jump_timer.time_left > 0.0) and not change_dir:
				if Input.is_action_just_pressed("jump"):
					velocity.y = -movement_data.jump_velocity
					coyote_jump_timer.stop()
			 
			if not is_on_floor():
				animation_player_lower.play("jump")
			else:
				animation_player_lower.play("run")
			
			if should_wall_climb():
				just_hit_wall = true
				can_change = false
				run_change_dir_timer.stop()
				accel_signal_timer.stop()
				movement_data = WALLRIDE_PLAYER_METRICS
				state = states.WALLRIDE
			
			move_and_slide()
	
		states.STOP:
			apply_gravity(delta)
			var is_jumping = false
			var was_on_floor = is_on_floor()
			
			apply_friction(delta)
			animation_player_lower.play("stand")
			if is_on_floor() or coyote_jump_timer.time_left > 0.0:
				if Input.is_action_just_pressed("jump"):
					is_jumping = true
					velocity.x = 0
					velocity.y = -(movement_data.jump_velocity * 2)
					coyote_jump_timer.stop()
					movement_data = DEFAULT_PLAYER_METRICS
					state = states.WALK
			
			move_and_slide()
			
			var just_left_ledge = was_on_floor  and not is_on_floor() and velocity.y >= 0
			if just_left_ledge:
				coyote_jump_timer.start()
			
			if velocity.x == 0 and not is_jumping:
				movement_data = DEFAULT_PLAYER_METRICS
				state = states.WALK
	
		states.WALLRIDE:
			# When player exit wallride apply gravity, if hit ground check for action , if success go run
			if exit_wallride:
				apply_gravity(delta)
				if is_on_floor():
					if accel_signal_timer.is_stopped():
						accel_signal_timer.start()
					buffer_action()
					if store_action == true and accel_signal_timer.time_left > 0.0:
						accel_signal_timer.stop()
						store_action = false
						action_buffer.stop()
						x_dir = roundi(x_input)
						anchor.scale.x = sign(x_dir)
						animation_camera.play("SlowDown")
						movement_data = RUN_PLAYER_METRICS
						state = states.RUN
			
			var y_input = Input.get_axis("move_up","move_down")
			
			# Check if just collided with a wall / Set velocity at 0 and launch timer 
			# On devras faire un visuel different pour ce check puisque le joueur doit appuyer sur haut ou bas et non action
			if just_hit_wall == true:
				velocity.y = 0.0
				just_hit_wall = false
				accel_signal_timer.start()
			
			if not accel_signal_timer.is_stopped():
				# If Player pick up then go up and if pick down then go down
				if not change_y_dir:
					if y_input == -1:
						y_dir = y_input
						chose_dir = true
						accel_signal_timer.stop()
					
					if y_input == 1:
						y_dir = y_input
						chose_dir = true
						accel_signal_timer.stop()
				
				#Check for changing direction with action
				if change_y_dir:
					buffer_action()
					if store_action == true and accel_signal_timer.time_left > 0.0:
						accel_signal_timer.stop()
						change_y_dir = false
						chose_dir = true
						store_action = false
						action_buffer.stop()
						y_dir = saved_y_dir
			
			#If player want to change direction initiate change check
			if y_dir != y_input and y_input != 0:
				saved_y_dir = y_input
				chose_dir = false
				change_y_dir = true
				accel_signal_timer.start()
			
			# When a direction is picked go in this direction indefenitely
			if chose_dir:
				accelerate_verticaly(y_dir, delta)
			
			#prevoir le cas si on jump depuis le wall ride
			#if is_on_wall_only():
				#if Input.is_action_just_pressed("jump") :
					#velocity.y = -movement_data.wall_jump_Y
					#velocity.x = movement_data.wall_jump_X * get_wall_normal().x
					#animation_camera.play("SlowDown")
					#chose_dir = false
					#movement_data = DEFAULT_PLAYER_METRICS
					#state = states.WALK
			
			#prevoir le cas si on arrive au bout du mur
			#distinction possible si on est en contact avec le sol (= en bas du mur) ou si on n'est pas en contact (= en haut du mur)
			
			if y_input != 0:
				animation_player_lower.play("wallride")
			
			# If player arrive at upper edge
			if ray_cast_lower.is_colliding() and not ray_cast_upper.is_colliding():
				chose_dir = false
				go_up = true
			
			if go_up:
				go_up = false
				velocity.y = -movement_data.wall_jump_Y
				exit_wallride = true
				animation_player_lower.play("stand")
			
			#If player arrive at lower edge
			if  ray_cast_upper.is_colliding() and not ray_cast_lower.is_colliding():
				chose_dir = false
				go_down = true
			
			if go_down:
				go_down = false
				velocity.y = movement_data.wall_jump_Y
				exit_wallride = true
				animation_player_lower.play("stand")
			
			move_and_slide()
			
			#if not should_wall_climb():
				#animation_camera.play("SlowDown")
				#chose_dir = false
				#movement_data = DEFAULT_PLAYER_METRICS
				#state = states.WALK
			
			
			
	
func accelerate_horizontaly(horizontal_direction: float, delta: float) -> void:
	var current_state_speed = movement_data.speed
	var acceleration_amount: float = movement_data.acceleration
	if not is_on_floor(): acceleration_amount = movement_data.air_acceleration
	velocity.x = move_toward(velocity.x, current_state_speed * horizontal_direction, acceleration_amount * delta * abs(horizontal_direction))

func accelerate_verticaly(vertical_direction: float, delta: float) -> void:
	var current_state_speed = movement_data.speed
	var acceleration_amount: float = movement_data.acceleration
	if not is_on_floor(): acceleration_amount = movement_data.air_acceleration
	velocity.y = move_toward(velocity.y, current_state_speed * vertical_direction, acceleration_amount * delta * abs(vertical_direction))

func apply_friction(delta) -> void :
	var friction_amount: float = movement_data.friction
	if not is_on_floor(): friction_amount = movement_data.air_friction
	velocity.x = move_toward(velocity.x, 0.0, friction_amount * delta)

func apply_vertical_friction(delta) -> void :
	var friction_amount: float = movement_data.friction
	if not is_on_floor(): friction_amount = movement_data.air_friction
	velocity.y = move_toward(velocity.y, 0.0, friction_amount * delta)

func apply_gravity(delta) -> void:
	if not is_on_floor():
		if velocity.y <= 0:
			velocity.y += movement_data.up_gravity * delta
		else:
			velocity.y += movement_data.down_gravity * delta 

func buffer_action() -> void:
	if Input.is_action_just_pressed("action") and store_action == false :
		store_action = true
		action_buffer.start()

func should_wall_climb() -> bool :
	return (
		ray_cast_upper.is_colliding()
		and ray_cast_lower.is_colliding()
		and not is_on_floor()
	)

func _on_run_change_dir_timer_timeout() -> void:
	# if input is maintained than bool becomes true and change direction allowed
	if state == states.RUN :
		change_dir = false
		can_change = true

func _on_accel_signal_timer_timeout() -> void:
	if state == states.WALK:
		store_time = true
		is_accelerating = false
		run_count = 0
	
	if state == states.RUN and changing_state:
		var x_input = Input.get_axis("move_left", "move_rigth")
		changing_state = false
		animation_camera.play("SlowDown")
		x_dir = x_input
		movement_data = DEFAULT_PLAYER_METRICS
		state = states.WALK
	
	if state == states.WALLRIDE:
		chose_dir = false
		animation_camera.play("SlowDown")
		movement_data = DEFAULT_PLAYER_METRICS
		state = states.WALK

func _on_action_buffer_timeout() -> void:
	store_action = false
