extends Sprite2D

func _process(delta: float) -> void:
	if Global.Open_door == true:
		$AnimatedSprite2D.play("Opening")
		await get_tree().create_timer(0.4).timeout
		$AnimatedSprite2D.play("Open")
	if Global.Open_door == false:
		await get_tree().create_timer(0.001).timeout
		$AnimatedSprite2D.play("Closed")


func _on_area_2d_body_entered(body):
	if body.name == "Player":
		if Global.Open_door == true:
			await get_tree().create_timer(0.4).timeout
			var tween = create_tween()
			tween.tween_property(body, "position", Vector2($".".position.x, $".".position.y + 4), 0.1)
			tween.tween_property(body, "modulate:a", 0.0, 1.5)
			Global.Moving = false
			await get_tree().create_timer(2.0).timeout
			Global.Level = Global.Level + 1
			get_tree().change_scene_to_file("res://Levels/level" + str(Global.Level) + ".tscn")
