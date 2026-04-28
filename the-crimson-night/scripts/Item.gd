extends RigidBody3D
class_name Item

@export var item_type: String = "generic"
@export var start_invisible: bool = false

@export var hold_offset: Vector3 = Vector3(0.35, -0.35, -0.9)
@export var hold_rotation: Vector3 = Vector3(-15, 45, 0)

# VISUAL
@export var glow_speed: float = 3.0
@export var glow_strength: float = 0.25

# PULSE
@export var pulse_visible_time: float = 0.5
@export var pulse_hidden_time: float = 2.0

var is_being_held: bool = false
var original_position: Vector3
var original_rotation: Vector3

var is_targeted: bool = false
var glow_time: float = 0.0

var holder: PlayerController = null

var pulse_timer: float = 0.0
var pulse_visible: bool = false

var item_visible: bool = true

@onready var icon: Sprite3D = $InteractionIcon
@onready var mesh: MeshInstance3D = $MeshInstance3D
@onready var glow_sprite: AnimatedSprite3D = $GlowPulse


# REGISTRO GLOBAL (pra Dialogic encontrar o item)
static var item_registry: Dictionary = {}


func _enter_tree() -> void:
	item_registry[item_type] = self


func _exit_tree() -> void:
	if item_registry.has(item_type):
		item_registry.erase(item_type)


func _ready() -> void:
	original_position = global_position
	original_rotation = global_rotation
	freeze = true

	icon.visible = false
	glow_sprite.visible = false
	glow_sprite.play()

	if start_invisible:
		set_item_visible(false)

	Dialogic.signal_event.connect(_on_dialogic_signal)


func _process(delta: float) -> void:
	_update_glow(delta)
	_update_pulse(delta)


# FEEDBACK VISUAL
func _update_glow(delta: float) -> void:
	if is_being_held or not item_visible:
		return

	glow_time += delta * glow_speed
	var pulse = (sin(glow_time) + 1.0) * 0.5 * glow_strength

	if mesh and mesh.material_override:
		mesh.material_override.emission_energy = 0.2 + pulse


# PULSE VISUAL
func _update_pulse(delta: float) -> void:
	if is_being_held or not item_visible:
		glow_sprite.visible = false
		return

	pulse_timer += delta

	if pulse_visible:
		if pulse_timer >= pulse_visible_time:
			pulse_visible = false
			pulse_timer = 0.0
			glow_sprite.visible = false
	else:
		if pulse_timer >= pulse_hidden_time:
			pulse_visible = true
			pulse_timer = 0.0
			glow_sprite.visible = true


func set_targeted(state: bool) -> void:
	is_targeted = state
	icon.visible = state and not is_being_held and item_visible


# VISIBILIDADE
func set_item_visible(value: bool) -> void:
	item_visible = value

	if mesh:
		mesh.visible = value

	if glow_sprite:
		glow_sprite.visible = value and not is_being_held

	if icon:
		icon.visible = value and is_targeted and not is_being_held


# INTERAÇÃO PRINCIPAL
func interact(player: Node) -> void:
	if not item_visible:
		return

	if not player is PlayerController:
		return

	set_targeted(false)

	if player.held_item == null:
		_pick_up(player)
		_update_dialogic(player)
	elif player.held_item != self:
		_swap_with_player(player)
		_update_dialogic(player)


# DIALOGIC SISTEMA DE SINAL
func _on_dialogic_signal(argument: String) -> void:
	# formato esperado:
	# "reveal:key_item"
	# "hide:key_item"

	var parts = argument.split(":")
	if parts.size() < 2:
		return

	var action = parts[0]
	var target_type = parts[1]

	if not item_registry.has(target_type):
		return

	var item = item_registry[target_type]

	match action:
		"reveal":
			item.set_item_visible(true)

		"hide":
			item.set_item_visible(false)

		"consume":
			item.consume()


# PEGAR ITEM
func _pick_up(player: PlayerController) -> void:
	is_being_held = true
	freeze = true

	holder = player
	player.held_item = self

	reparent(player.hold_position)

	global_position = player.hold_position.global_position + player.hold_position.global_transform.basis * hold_offset
	global_rotation = player.hold_position.global_rotation + hold_rotation * PI / 180.0

	icon.visible = false
	glow_sprite.visible = false


# SOLTAR ITEM
func put_down(target_position: Vector3, target_rotation: Vector3 = Vector3.ZERO) -> void:
	is_being_held = false
	holder = null

	reparent(get_tree().current_scene)

	global_position = target_position

	if target_rotation == Vector3.ZERO:
		global_rotation = original_rotation
	else:
		global_rotation = target_rotation

	freeze = true


# TROCA
func _swap_with_player(player: PlayerController) -> void:
	var current_item = player.held_item
	if current_item == self:
		return

	var swap_pos = global_position
	var swap_rot = global_rotation

	current_item.put_down(swap_pos, swap_rot)

	player.held_item = null
	_pick_up(player)


# CONSUMIR
func consume() -> void:
	if not is_being_held:
		return

	if holder and holder.held_item == self:
		holder.held_item = null
		_update_dialogic(holder)

	queue_free()


# DIALOGIC VAR
func _update_dialogic(player: PlayerController) -> void:
	if player.held_item == null:
		Dialogic.VAR.set("player_item_type", "none")
	else:
		Dialogic.VAR.set("player_item_type", player.held_item.item_type)
