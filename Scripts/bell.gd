extends Node2D
var WaitThing = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if WaitThing == false:
		await get_tree().create_timer(1.5).timeout
		WaitThing = true


func _on_button_button_down() -> void:
	print("Press")
	if WaitThing == true:
		Global.Next = true
		WaitThing = false
	
