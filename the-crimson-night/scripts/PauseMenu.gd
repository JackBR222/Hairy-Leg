extends CanvasLayer

@onready var player = get_tree().current_scene.get_node("Player/Player")

@export var background: TextureRect
@export var panel: Control
@export var options_panel: Control

@export var resume_button: TextureButton
@export var options_button: TextureButton
@export var main_menu_button: TextureButton
@export var options_back_button: BaseButton

@export var bg_pause: Texture2D
@export var bg_options: Texture2D

@export var fade_speed: float = 0.15

@onready var fade = get_tree().get_first_node_in_group("fade")
@onready var music_preview_player: AudioStreamPlayer = $MusicPreviewPlayer
@onready var sfx_preview_player: AudioStreamPlayer = $SFXPreviewPlayer

@onready var music_slider: HSlider = $OptionsPanel/Center/MusicSlider
@onready var sfx_slider: HSlider = $OptionsPanel/Center/SFXSlider

var paused := false
var original_textures := {}
var hover_tweens := {}

# trava de input
var input_locked := false

var can_play_preview := true

# INIT
func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	options_panel.visible = false

	_register_button(resume_button)
	_register_button(options_button)
	_register_button(main_menu_button)
	_register_button(options_back_button)
	
	music_slider.value_changed.connect(_on_music_slider_changed)
	sfx_slider.value_changed.connect(_on_sfx_slider_changed)


# INPUT
func _input(event: InputEvent) -> void:
	# bloqueia input durante fade
	if input_locked:
		return

	if event.is_action_pressed("pause_game"):
		# Só controla o pause geral
		if not options_panel.visible:
			toggle_pause()

	elif event.is_action_pressed("ui_cancel"):
		# Só controla voltar dentro de menus
		if options_panel.visible:
			close_options()
		elif paused:
			toggle_pause()


# PAUSE (SEM FADE)
func toggle_pause() -> void:
	paused = !paused
	get_tree().paused = paused
	visible = paused

	if paused:
		background.texture = bg_pause
		resume_button.grab_focus()


# OPTIONS (COM FADE)
func open_options() -> void:
	if fade:
		input_locked = true
		fade.fade_in(fade_speed)
		await fade.wait_finished()

	panel.visible = false
	options_panel.visible = true
	background.texture = bg_options

	await get_tree().process_frame
	options_back_button.grab_focus()

	if fade:
		fade.fade_out(fade_speed)
		await fade.wait_finished()
		input_locked = false


func close_options() -> void:
	if fade:
		input_locked = true
		fade.fade_in(fade_speed)
		await fade.wait_finished()

	options_panel.visible = false
	panel.visible = true
	background.texture = bg_pause

	await get_tree().process_frame
	resume_button.grab_focus()

	if fade:
		fade.fade_out(fade_speed)
		await fade.wait_finished()
		input_locked = false


var can_play_music_preview := true

func _on_music_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("Music"),
		linear_to_db(value)
	)

	_play_music_preview()
	

var can_play_sfx_preview := true

func _on_sfx_slider_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(
		AudioServer.get_bus_index("SFX"),
		linear_to_db(value)
	)

	_play_sfx_preview()
	

func _play_music_preview() -> void:
	if not can_play_music_preview:
		return

	can_play_music_preview = false
	music_preview_player.play()

	await get_tree().create_timer(0.5).timeout
	can_play_music_preview = true


func _play_sfx_preview() -> void:
	if not can_play_sfx_preview:
		return

	can_play_sfx_preview = false
	sfx_preview_player.play()

	await get_tree().create_timer(0.5).timeout
	can_play_sfx_preview = true


# AÇÕES
func _on_resume_pressed() -> void:
	toggle_pause()


func _on_options_pressed() -> void:
	open_options()


func _on_options_back_pressed() -> void:
	close_options()


func _on_main_menu_pressed() -> void:
	get_tree().paused = false

	if fade:
		input_locked = true
		fade.fade_in(fade_speed)
		await fade.wait_finished()

	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")


# BOTÕES (FEEDBACK VISUAL)
func _register_button(btn: TextureButton) -> void:
	if btn == null:
		return

	original_textures[btn] = {
		"normal": btn.texture_normal,
		"hover": btn.texture_hover,
		"pressed": btn.texture_pressed
	}

	btn.focus_entered.connect(_on_focus.bind(btn))
	btn.focus_exited.connect(_on_unfocus.bind(btn))

	btn.button_down.connect(_on_press.bind(btn))
	btn.button_up.connect(_on_release.bind(btn))

	btn.mouse_entered.connect(func(): btn.grab_focus())
	btn.mouse_exited.connect(func(): _on_unfocus(btn))


# HOVER
func _on_focus(btn: TextureButton) -> void:
	btn.texture_normal = original_textures[btn]["hover"]
	_start_pulse(btn)


func _on_unfocus(btn: TextureButton) -> void:
	btn.texture_normal = original_textures[btn]["normal"]
	_stop_pulse(btn)


func _on_press(btn: TextureButton) -> void:
	btn.texture_normal = original_textures[btn]["pressed"]


func _on_release(btn: TextureButton) -> void:
	if btn.has_focus():
		btn.texture_normal = original_textures[btn]["hover"]
	else:
		btn.texture_normal = original_textures[btn]["normal"]


# PULSE
func _start_pulse(btn: TextureButton) -> void:
	_stop_pulse(btn)

	var t := create_tween().set_loops()
	hover_tweens[btn] = t

	t.tween_property(btn, "modulate", Color(1.6, 1.6, 1.6, 1), 0.5)
	t.tween_property(btn, "modulate", Color(0.7, 0.7, 0.7, 1), 0.5)


func _stop_pulse(btn: TextureButton) -> void:
	if hover_tweens.has(btn):
		hover_tweens[btn].kill()
		hover_tweens.erase(btn)

	btn.modulate = Color(1, 1, 1, 1)
