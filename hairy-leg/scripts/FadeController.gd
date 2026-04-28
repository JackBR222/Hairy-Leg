extends CanvasItem

@export var default_fade_time: float = 1.0

signal fade_finished

var _tween: Tween
var _busy := false
var _queue: Array = []

func _ready():
	process_mode = Node.PROCESS_MODE_ALWAYS
	modulate.a = 0.0
	add_to_group("fade")

# =========================
# API PÚBLICA
# =========================

func fade_in(time: float = -1.0, priority: bool = false) -> void:
	_request_fade(1.0, time, priority)

func fade_out(time: float = -1.0, priority: bool = false) -> void:
	_request_fade(0.0, time, priority)


# =========================
# CORE
# =========================

func _request_fade(target_alpha: float, time: float, priority: bool) -> void:
	if time <= 0:
		time = default_fade_time

	var request = {
		"alpha": target_alpha,
		"time": time
	}

	if priority:
		_queue.clear()
		_start_fade(request)
	else:
		_queue.append(request)
		_process_queue()


func _process_queue() -> void:
	if _busy or _queue.is_empty():
		return

	var request = _queue.pop_front()
	_start_fade(request)


func _start_fade(request) -> void:
	_busy = true

	if _tween:
		_tween.kill()

	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", request["alpha"], request["time"])

	await _tween.finished

	_busy = false
	emit_signal("fade_finished")
	_process_queue()


# =========================
# UTILIDADES
# =========================

func is_busy() -> bool:
	return _busy


func wait_finished() -> void:
	while _busy:
		await get_tree().process_frame
