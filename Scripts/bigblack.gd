extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	modulate.a = 0
		
		
func _process(delta: float) -> void:
	if Global.Pulldown == true:
		var tween = create_tween()
		tween.tween_property($".", "modulate:a", 131, 0.5)
	if Global.Pulldown == true:
		var tween = create_tween()
		tween.tween_property($".", "modulate:a", 244, 0.5)
