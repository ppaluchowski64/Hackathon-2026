extends CanvasLayer
class_name Lobby

signal start_requested

@onready var start_button: Button = $MarginContainer/VBoxContainer/Button

func _ready() -> void:
	start_button.pressed.connect(_on_start_button_pressed)

func refresh(is_host: bool, everyone_loaded: bool) -> void:
	if not is_host:
		start_button.text = "Waiting for host..."
		start_button.disabled = true
	elif not everyone_loaded:
		start_button.text = "Waiting for players..."
		start_button.disabled = true
	else:
		start_button.text = "Start the Game"
		start_button.disabled = false

func _on_start_button_pressed() -> void:
	start_button.disabled = true
	start_requested.emit()
