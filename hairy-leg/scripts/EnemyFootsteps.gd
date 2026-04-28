extends AudioStreamPlayer3D

@export var enemy: CharacterBody3D
@onready var raycast: RayCast3D = $RayCast3D

var anim: AnimationPlayer
var last_anim_position: float = 0.0
var forced_stopped: bool = false


func _ready() -> void:
	if raycast:
		raycast.force_raycast_update()

	if enemy:
		anim = enemy.get_node("AnimationPlayer")


func _physics_process(_delta: float) -> void:
	if enemy == null or forced_stopped or anim == null:
		return

	if not enemy.is_on_floor():
		return

	var speed := enemy.velocity.length()

	# parado
	if speed < 0.1:
		if is_playing():
			stop()
		return

	# detecta loop da animação (voltou pro início)
	var current_pos = anim.current_animation_position

	if current_pos < last_anim_position:
		# aqui é o "último frame" → loopou
		if _is_movement_state():
			play_step()

	last_anim_position = current_pos


# DEFINE SE DEVE TOCAR PASSO
func _is_movement_state() -> bool:
	var state := get_enemy_state()

	return state in ["run", "chase", "walk", "patrol", "investigate", "return"]


# ESTADO DO INIMIGO
func get_enemy_state() -> String:
	if enemy == null:
		return "idle"

	var s = enemy.get("state")

	if s != null:
		match int(s):
			0: return "idle"
			1: return "patrol"
			2: return "investigate"
			3: return "chase"
			4: return "attack"
			5: return "return"

	var speed := enemy.velocity.length()

	if speed > 2.5:
		return "run"
	elif speed > 0.2:
		return "walk"

	return "idle"


# SOM DOS PASSOS
func play_step() -> void:
	var floor_type := get_floor_type()

	var sound: AudioStream

	if floor_type == "grass":
		sound = preload("res://audio/sounds/footstep_grass.mp3")
	else:
		sound = preload("res://audio/sounds/footstep_concrete.mp3")

	stream = sound
	pitch_scale = randf_range(0.85, 1.05)
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


# CONTROLE EXTERNO
func force_stop_steps() -> void:
	stop()
	forced_stopped = true
	last_anim_position = 0.0


func restore_steps() -> void:
	forced_stopped = false
	last_anim_position = 0.0
