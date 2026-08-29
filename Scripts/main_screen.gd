extends Control

# Title screen. main_screen.tscn wires play.pressed straight to
# _on_play_pressed, so nothing is connected here.

func _ready() -> void:
	# The drone starts here and is never stopped, so it carries through the
	# menu, the day and the summary without restarting at each scene change.
	Audio.start_music()


func _on_play_pressed() -> void:
	Audio.play("click")
	get_tree().change_scene_to_file("res://Game/Game.tscn")
