extends Node2D
var show = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(41, -140)
		
		
func _process(delta: float) -> void:
	if Global.Pulldown == true and show == false:
		show == true
		var tween = create_tween()
		tween.tween_property($".", "position",Vector2(position.x,-35), 1)
	if Global.Pulldown == false and show == true:
		show == false
		var tween = create_tween()
		tween.tween_property($".", "position",Vector2(position.x,-140), 1)
