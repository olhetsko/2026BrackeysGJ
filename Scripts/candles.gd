extends Sprite2D

# Guards against the same candle being counted twice if the player walks back
# into the area mid-swing.
var _lit := true


func _ready() -> void:
	add_to_group("candles")
	$AnimatedSprite2D.play("Lit")


func _on_area_2d_body_entered(body):
	if _lit and Global.Is_attacking == true:
		_extinguish()


func _extinguish() -> void:
	_lit = false
	Global.Open_door = true
	Global.Candle_extinguished.emit()
	$AnimatedSprite2D.play("Hit")
