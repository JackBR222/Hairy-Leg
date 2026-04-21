extends StaticBody3D
class_name Door

@export var dialog_timeline: String = "testDoor"
@export var door_id: String = "A"

var current_player: Player = null
var is_open: bool = false


# READY
func _ready():
	Dialogic.signal_event.connect(_on_dialogic_signal)


# INTERAÇÃO
func interact(player: Node) -> void:
	if not player is Player:
		return

	if is_open:
		return

	current_player = player

	_update_dialogic_context()
	start_dialog()


# START DIALOG
func start_dialog() -> void:
	if current_player:
		current_player.freeze_input()

	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	Dialogic.timeline_ended.connect(_on_timeline_ended)

	Dialogic.start(dialog_timeline)


# FINAL DO DIALOGO
func _on_timeline_ended() -> void:
	if Dialogic.timeline_ended.is_connected(_on_timeline_ended):
		Dialogic.timeline_ended.disconnect(_on_timeline_ended)

	if current_player:
		current_player.unfreeze_input()

	current_player = null

	Dialogic.VAR.set("current_door_id", "NONE")


# SIGNAL DO DIALOGIC
func _on_dialogic_signal(argument: String) -> void:

	# 🧭 UNLOCK DA PORTA
	if argument == "unlock_door" and Dialogic.VAR.get("current_door_id") == door_id:
		unlock_door()

	# CHECKPOINT SET (ex: "checkpoint_1", "checkpoint_2")
	if argument.begins_with("checkpoint_"):
		var value = int(argument.replace("checkpoint_", ""))
		Checkpoint.definir_checkpoint(value)

	# CHECKPOINT PRA TESTE (-1)
	if argument == "checkpoint_test":
		Checkpoint.definir_checkpoint(-1)


# ABRIR PORTA
func unlock_door() -> void:
	if is_open:
		return

	is_open = true
	print("Porta destrancada: ", door_id)


# CONTEXTO DO DIALOGIC
func _update_dialogic_context() -> void:
	Dialogic.VAR.set("current_door_id", door_id)
