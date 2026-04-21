extends CanvasLayer

@onready var botao_continuar = $Continuar

func _ready() -> void:
	# Só mostra se tiver checkpoint válido
	botao_continuar.visible = Checkpoint.tem_checkpoint()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test/CheckpointTest.scn")

func _on_reset_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
	
func _on_continue_pressed() -> void:
	Checkpoint.carregar_checkpoint()


func _on_quit_pressed() -> void:
	get_tree().quit()
