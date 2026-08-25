extends Node2D

const CLOSED_POS := Vector2(41, -140)
const OPEN_Y := -35.0
const SLIDE_TIME := 0.5

var _tween: Tween


func _ready() -> void:
	position = CLOSED_POS
	Global.pulldown_changed.connect(_on_pulldown_changed)


func _on_pulldown_changed(is_down: bool) -> void:
	var target_y := OPEN_Y if is_down else CLOSED_POS.y
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(self, "position:y", target_y, SLIDE_TIME)
