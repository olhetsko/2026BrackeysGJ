extends Node2D


# Global.Pulldown's setter emits pulldown_changed; the panel and the dim
# overlay animate off that signal, so this only has to flip the flag.
func _on_button_button_down() -> void:
	Global.Pulldown = not Global.Pulldown
