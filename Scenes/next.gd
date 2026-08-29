# NextButton.gd
extends Node2D

@onready var button: Button = $Button

func _ready() -> void:
	button.pressed.connect(_on_button_pressed)

func _on_button_pressed() -> void:
	print("[NEXT BUTTON] Pressed! Emitting signal...")
	Global.next_day_requested.emit()
