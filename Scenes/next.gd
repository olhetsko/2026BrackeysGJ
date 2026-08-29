extends Node2D

# The Next Day button. next.tscn wires Button.pressed straight to this.

func _on_button_pressed() -> void:
	Audio.play("click")
	Global.next_day_requested.emit()
