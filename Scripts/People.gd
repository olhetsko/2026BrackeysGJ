extends Node2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	position = Vector2(-174, -22)
		
		
func _process(delta: float) -> void:
	if Global.Next == true:
		print("recieve")
		Global.Next = false
		position.x = -174
		RandomColor()
		await get_tree().create_timer(0.4).timeout
		var tween = create_tween()
		tween.tween_property($".", "position", Vector2(-107, $".".position.y), 1)
		Global.Next = false


func RandomColor():
	var r = randi_range(20,150)
	var g = randi_range(20,150)
	var b = randi_range(20,150)
	$Body.modulate.r = r
	$Body.modulate.g = g
	$Body.modulate.b = b
	$Head.modulate.r = r
	$Head.modulate.g = g
	$Head.modulate.b = b
