extends Node2D

const DIM_ALPHA := 0.6
const FADE_TIME := 0.35

var _tween: Tween


func _ready() -> void:
	modulate.a = 0.0
	Global.pulldown_changed.connect(_on_pulldown_changed)


func _on_pulldown_changed(is_down: bool) -> void:
	var target_a := DIM_ALPHA if is_down else 0.0
	if _tween and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "modulate:a", target_a, FADE_TIME)
