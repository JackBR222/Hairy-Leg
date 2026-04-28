extends StaticBody3D
class_name Door


# TIMELINES
@export var dialog_timeline: Resource
@export var dialog_timeline_alt: Resource


# MODELS
@export var model_main: Node3D
@export var model_alt: Node3D


# DATA
@export var door_id: String = "A"

var current_timeline: Resource = null
var pending_timeline: Resource = null

var pending_model_alt: bool = false

var current_player: PlayerController = null
var is_open: bool = false


# INICIALIZAÇÃO
func _ready():
	current_timeline = dialog_timeline
	Dialogic.signal_event.connect(_on_dialogic_signal)
	_apply_model(false)


# INTERAÇÃO
func interact(player: Node) -> void:
	if not player is PlayerController:
		return

	if is_open:
		return

	current_player = player
	_update_dialogic_context()
	start_dialog()


func start_dialog() -> void:
	if current_player:
		current_player.freeze_input()

	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	Dialogic.timeline_ended.connect(_on_timeline_ended)
	Dialogic.start(current_timeline)


# FIM DO DIÁLOGO
func _on_timeline_ended() -> void:
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	if current_player:
		current_player.unfreeze_input()

	current_player = null
	Dialogic.VAR.set("current_door_id", "NONE")

	if pending_timeline != null:
		current_timeline = pending_timeline
		pending_timeline = null

	_apply_model(pending_model_alt)


# SINAIS DO DIALOGIC
func _on_dialogic_signal(argument: String) -> void:

	if argument == "unlock_door" and Dialogic.VAR.get("current_door_id") == door_id:
		unlock_door()

	if argument == "change_timeline_main":
		change_timeline(dialog_timeline)

	if argument == "change_timeline_alt":
		change_timeline(dialog_timeline_alt)

	if argument == "change_model_main":
		change_model(false)

	if argument == "change_model_alt":
		change_model(true)

	if argument.begins_with("checkpoint_"):
		var value = int(argument.replace("checkpoint_", ""))
		Checkpoint.definir_checkpoint(value)

	if argument == "checkpoint_test":
		Checkpoint.definir_checkpoint(-1)


# CONTROLE DE TIMELINE
func change_timeline(new_timeline: Resource) -> void:
	pending_timeline = new_timeline


# CONTROLE DE MODELO
func change_model(use_alt: bool) -> void:
	pending_model_alt = use_alt


func _apply_model(use_alt: bool) -> void:
	if model_main:
		model_main.visible = not use_alt

	if model_alt:
		model_alt.visible = use_alt


# CONTROLE DA PORTA
func unlock_door() -> void:
	if is_open:
		return

	is_open = true
	print("Porta destrancada: ", door_id)


# CONTEXTO DO DIALOGIC
func _update_dialogic_context() -> void:
	Dialogic.VAR.set("current_door_id", door_id)
