extends CanvasItem

@export var default_fade_time: float = 1.0

var _tween: Tween

func _ready():
	# Começa invisível (tela limpa)
	modulate.a = 0.0

func fade_in(time: float = -1.0):
	if time <= 0:
		time = default_fade_time
	
	_start_fade(1.0, time) # fica preto

func fade_out(time: float = -1.0):
	if time <= 0:
		time = default_fade_time
	
	_start_fade(0.0, time) # volta a enxergar

func _start_fade(target_alpha: float, time: float):
	if _tween:
		_tween.kill()
	
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", target_alpha, time)

func wait_finished() -> void:
	if _tween:
		await _tween.finished
