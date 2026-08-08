extends Node2D


@export var creep_speed := 6.0
@export var surge_distance := 110.0
@export var approach_speed := 55.0
@export var direction := Vector2.RIGHT
@export var kills_player := true

@onready var _sprite: Sprite2D = $Sprite2D
@onready var _base_scale: Vector2 = _sprite.scale
@onready var _origin: Vector2 = position

var _granted := 0.0
var _travelled := 0.0

var _candles_total := 0
var _candles_out := 0
var _caught := false


func _ready() -> void:
	direction = direction.normalized()
	Global.Candle_extinguished.connect(_on_candle_extinguished)

	await get_tree().process_frame
	_candles_total = get_tree().get_nodes_in_group("candles").size()


func _physics_process(delta: float) -> void:
	if _caught or not Global.Moving:
		return

	_granted += creep_speed * delta
	_travelled = move_toward(_travelled, _granted, approach_speed * delta)
	position = _origin + direction * _travelled


func _on_candle_extinguished() -> void:
	_candles_out += 1
	_granted += surge_distance

	var darkness := 1.0
	if _candles_total > 0:
		darkness = float(_candles_out) / float(_candles_total)

	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "modulate:a", lerpf(0.7, 1.0, darkness), 0.6)
	tween.tween_property(_sprite, "scale", _base_scale * lerpf(1.0, 1.25, darkness), 0.6)


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _caught or not kills_player or body.name != "Player":
		return

	_caught = true
	Global.Moving = false
	Global.Is_attacking = false
	Global.Open_door = false

	var tween := create_tween()
	tween.tween_property(body, "modulate:a", 0.0, 0.8)
	await tween.finished
	get_tree().reload_current_scene()
