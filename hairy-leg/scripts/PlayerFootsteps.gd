extends AudioStreamPlayer3D

@export var player: CharacterBody3D
@onready var raycast: RayCast3D = $RayCast3D

@export var walk_forward_step_interval: float = 0.6
@export var walk_backward_step_interval: float = 0.75
@export var run_step_interval: float = 0.35
@export var turn_left_step_interval: float = 0.9
@export var turn_right_step_interval: float = 0.9
@export var turn_180_step_interval: float = 1.0
@export var idle_step_interval: float = 999.0

var step_timer: float = 0.0
var last_anim: String = ""
var forced_stopped: bool = false


func _ready() -> void:
	if raycast:
		raycast.force_raycast_update()


func _physics_process(delta: float) -> void:
	if player == null or forced_stopped:
		return

	if not player.is_on_floor():
		step_timer = 0.0
		return

	var anim_name := get_player_anim()

	var speed := player.velocity.length()

	# parado total
	if anim_name == "" and speed < 0.1:
		if is_playing():
			stop()
		step_timer = 0.0
		return

	# reset quando muda animação
	if anim_name != last_anim:
		last_anim = anim_name
		step_timer = get_interval_for_anim(anim_name)

	step_timer -= delta

	if step_timer <= 0.0:
		var interval := get_interval_for_anim(anim_name)

		if interval < 999.0:
			play_step()

		step_timer = interval


func get_player_anim() -> String:
	if player and player.has_method("get_current_anim"):
		return player.get_current_anim()
	return ""


func get_interval_for_anim(anim_name: String) -> float:
	match anim_name:
		"Figner|Run":
			return run_step_interval
		"Figner|Forward Move":
			return walk_forward_step_interval
		"Figner|Backward Move":
			return walk_backward_step_interval
		"Figner|Turn Left":
			return turn_left_step_interval
		"Figner|Turn Right":
			return turn_right_step_interval
		"Figner|Turn 180":
			return turn_180_step_interval
		_:
			return idle_step_interval


func play_step() -> void:
	var floor_type := get_floor_type()

	var sound: AudioStream

	if floor_type == "grass":
		sound = preload("res://audio/sounds/footstep_grass.mp3")
	else:
		sound = preload("res://audio/sounds/footstep_concrete.mp3")

	stream = sound
	pitch_scale = randf_range(0.9, 1.1)
	play()


func get_floor_type() -> String:
	if raycast == null:
		return "default"

	raycast.force_raycast_update()

	if raycast.is_colliding():
		var collider = raycast.get_collider()

		if collider and collider.has_meta("floor_type"):
			return str(collider.get_meta("floor_type"))

		if collider and collider.is_in_group("grass"):
			return "grass"
		elif collider and collider.is_in_group("concrete"):
			return "concrete"

	return "default"


func force_stop_steps() -> void:
	stop()
	forced_stopped = true
	step_timer = 0.0
	last_anim = ""


func restore_steps() -> void:
	forced_stopped = false
	step_timer = 0.0
	last_anim = ""
