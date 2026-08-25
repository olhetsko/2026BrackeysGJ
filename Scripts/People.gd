extends Node2D

const START_POS := Vector2(-174, -22)
const COUNTER_X := -107.0
const ENTER_DELAY := 0.4
const WALK_TIME := 1.0

var tween: Tween
var arriving := false


func _ready() -> void:
	position = START_POS
	Global.next_customer_requested.connect(_on_next_customer_requested)


func _on_next_customer_requested() -> void:
	if arriving == true:
		return
	arriving = true

	if tween and tween.is_valid():
		tween.kill()
	position = START_POS
	randomize_color()

	tween = create_tween()
	tween.tween_interval(ENTER_DELAY)
	tween.tween_property(self, "position:x", COUNTER_X, WALK_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(on_arrived)


func on_arrived() -> void:
	arriving = false
	# Reaching the counter is what hands the paperwork over.
	Global.customer_arrived.emit()


func randomize_color() -> void:
	var tint := Color(
		randi_range(20, 150) / 255.0,
		randi_range(20, 150) / 255.0,
		randi_range(20, 150) / 255.0
	)
	$Body.modulate = tint
	$Head.modulate = tint
