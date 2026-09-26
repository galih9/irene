class_name IrenePopupModal
extends Control

signal dialogue_finished()
signal dialogue_advanced(step_index: int)

@onready var dimmer: ColorRect = $Dimmer
@onready var panel_container: PanelContainer = $CenterContainer/PanelContainer
@onready var portrait_rect: TextureRect = $CenterContainer/PanelContainer/Margin/HBox/PortraitContainer/Portrait
@onready var portrait_glow: TextureRect = $CenterContainer/PanelContainer/Margin/HBox/PortraitContainer/PortraitGlow
@onready var name_label: Label = $CenterContainer/PanelContainer/Margin/HBox/VBox/Header/NameTag/Margin/NameLabel
@onready var dialogue_label: Label = $CenterContainer/PanelContainer/Margin/HBox/VBox/DialogueScroll/DialogueLabel
@onready var continue_btn: Button = $CenterContainer/PanelContainer/Margin/HBox/VBox/ButtonContainer/ContinueBtn

const EMOTION_TEXTURES: Dictionary = {
	"greeting": preload("res://assets/characters/irene/greeting.png"),
	"explain": preload("res://assets/characters/irene/explain.png"),
	"happy": preload("res://assets/characters/irene/happy.png"),
	"thinking": preload("res://assets/characters/irene/thinking.png"),
	"shocked": preload("res://assets/characters/irene/shocked.png"),
	"admire": preload("res://assets/characters/irene/admire.png")
}

const IVAN_EMOTION_TEXTURES: Dictionary = {
	"greeting": preload("res://assets/characters/ivan/greeting.png"),
	"explain": preload("res://assets/characters/ivan/explain.png"),
	"excited": preload("res://assets/characters/ivan/excited.png"),
	"confused": preload("res://assets/characters/ivan/confused.png"),
	"shocked": preload("res://assets/characters/ivan/shocked.png"),
	"happy": preload("res://assets/characters/ivan/excited.png")
}

const IVY_EMOTION_TEXTURES: Dictionary = {
	"greeting": preload("res://assets/characters/ivy/greeting.png"),
	"explain": preload("res://assets/characters/ivy/explain.png"),
	"admire": preload("res://assets/characters/ivy/admire.png"),
	"congratulate": preload("res://assets/characters/ivy/congratulate.png"),
	"happy": preload("res://assets/characters/ivy/congratulate.png"),
	"excited": preload("res://assets/characters/ivy/congratulate.png"),
	"shocked": preload("res://assets/characters/ivy/shocked.png"),
	"thinking": preload("res://assets/characters/ivy/explain.png")
}

var _dialogue_queue: Array[Dictionary] = []
var _current_dialogue: Dictionary = {}
var _on_complete_callback: Callable = Callable()

var _is_typing: bool = false
var _type_tween: Tween = null
var _pulse_tween: Tween = null
var _idle_portrait_tween: Tween = null
var _full_text: String = ""
var _char_speed: float = 0.024

func _ready() -> void:
	visible = false
	modulate.a = 0.0
	continue_btn.pressed.connect(_on_continue_pressed)

	GameEvents.irene_dialogue_requested.connect(func(text: String, emotion: String, cb: Callable):
		show_dialogue(text, emotion, cb, "irene")
	)
	GameEvents.character_dialogue_requested.connect(func(char_name: String, text: String, emotion: String, cb: Callable):
		show_dialogue(text, emotion, cb, char_name)
	)

func show_dialogue(text: String, emotion: String = "explain", callback: Callable = Callable(), character: String = "irene") -> void:
	_dialogue_queue.clear()
	_dialogue_queue.append({
		"character": character,
		"text": text,
		"emotion": emotion
	})
	_on_complete_callback = callback
	_open_and_show_next()

func show_dialogue_sequence(dialogues: Array[Dictionary], callback: Callable = Callable()) -> void:
	_dialogue_queue = dialogues.duplicate()
	_on_complete_callback = callback
	_open_and_show_next()

func _open_and_show_next() -> void:
	if _dialogue_queue.is_empty():
		close_modal()
		return

	if not visible:
		visible = true
		modulate.a = 0.0
		panel_container.scale = Vector2(0.9, 0.9)
		panel_container.pivot_offset = panel_container.size * 0.5

		var in_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		in_tween.tween_property(self, "modulate:a", 1.0, 0.2)
		in_tween.tween_property(panel_container, "scale", Vector2.ONE, 0.22)
		SoundManager.play_open()

	_start_next_line()

func _start_next_line() -> void:
	if _dialogue_queue.is_empty():
		close_modal()
		if _on_complete_callback.is_valid():
			_on_complete_callback.call()
			_on_complete_callback = Callable()
		dialogue_finished.emit()
		return

	_current_dialogue = _dialogue_queue.pop_front()
	var text: String = _current_dialogue.get("text", "")
	var emotion: String = _current_dialogue.get("emotion", "explain")
	var character: String = _current_dialogue.get("character", "irene")

	if name_label:
		match character.to_lower():
			"ivan":
				name_label.text = "Ivan"
			"ivy":
				name_label.text = "Ivy"
			_:
				name_label.text = "Irene"

	_set_emotion(emotion, character)
	_start_typewriter(text)

func _set_emotion(emotion: String, character: String = "irene") -> void:
	var tex_dict := EMOTION_TEXTURES
	match character.to_lower():
		"ivan":
			tex_dict = IVAN_EMOTION_TEXTURES
		"ivy":
			tex_dict = IVY_EMOTION_TEXTURES
		_:
			tex_dict = EMOTION_TEXTURES
	var default_tex: Texture2D = tex_dict.get("explain", tex_dict.get("greeting"))
	var tex: Texture2D = tex_dict.get(emotion, default_tex)
	portrait_rect.texture = tex
	if portrait_glow:
		portrait_glow.texture = tex

	# Gentle breathing/wobble on emotion change
	if _idle_portrait_tween and _idle_portrait_tween.is_valid():
		_idle_portrait_tween.kill()

	portrait_rect.pivot_offset = portrait_rect.size * 0.5
	_idle_portrait_tween = create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	portrait_rect.scale = Vector2(0.92, 0.92)
	_idle_portrait_tween.tween_property(portrait_rect, "scale", Vector2.ONE, 0.25)

func _start_typewriter(text: String) -> void:
	_full_text = text
	dialogue_label.text = text
	dialogue_label.visible_characters = 0
	continue_btn.visible = false
	continue_btn.modulate.a = 0.0
	_is_typing = true

	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()

	var total_chars := text.length()
	var duration := maxf(0.3, float(total_chars) * _char_speed)

	_type_tween = create_tween()
	var on_step := func(chars_shown: int) -> void:
		dialogue_label.visible_characters = chars_shown
		if chars_shown > 0 and chars_shown % 2 == 0 and chars_shown < total_chars:
			var c := text[chars_shown - 1]
			if c != " " and c != "\n" and c != "\t":
				SoundManager.play_dialogue_blip()

	_type_tween.tween_method(on_step, 0, total_chars, duration)
	_type_tween.finished.connect(_finish_typing)

func skip_typing() -> void:
	if not _is_typing:
		return

	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()

	dialogue_label.visible_characters = -1
	_finish_typing()

func _finish_typing() -> void:
	_is_typing = false
	dialogue_label.visible_characters = -1
	_show_continue_button()

func _show_continue_button() -> void:
	continue_btn.visible = true
	var btn_tween := create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	continue_btn.scale = Vector2(0.85, 0.85)
	continue_btn.pivot_offset = continue_btn.custom_minimum_size * 0.5
	btn_tween.tween_property(continue_btn, "modulate:a", 1.0, 0.15)
	btn_tween.parallel().tween_property(continue_btn, "scale", Vector2.ONE, 0.18)

	# Gentle pulsing on Continue button
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	_pulse_tween = create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tween.tween_property(continue_btn, "scale", Vector2(1.04, 1.04), 0.7)
	_pulse_tween.tween_property(continue_btn, "scale", Vector2(1.0, 1.0), 0.7)
	_pulse_tween.set_loops()

func _on_continue_pressed() -> void:
	SoundManager.play_click()
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()

	if not _dialogue_queue.is_empty():
		_start_next_line()
	else:
		close_modal()
		if _on_complete_callback.is_valid():
			_on_complete_callback.call()
			_on_complete_callback = Callable()
		dialogue_finished.emit()

func close_modal() -> void:
	if not visible:
		return
	if _type_tween and _type_tween.is_valid():
		_type_tween.kill()
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if _idle_portrait_tween and _idle_portrait_tween.is_valid():
		_idle_portrait_tween.kill()

	var out_tween := create_tween().set_parallel(true).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	out_tween.tween_property(self, "modulate:a", 0.0, 0.15)
	out_tween.tween_property(panel_container, "scale", Vector2(0.92, 0.92), 0.15)
	out_tween.finished.connect(func():
		visible = false
	)
	SoundManager.play_close()

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _is_typing:
			skip_typing()
			accept_event()
		elif continue_btn.visible:
			_on_continue_pressed()
			accept_event()
	elif event is InputEventScreenTouch and event.pressed:
		if _is_typing:
			skip_typing()
			accept_event()
		elif continue_btn.visible:
			_on_continue_pressed()
			accept_event()
