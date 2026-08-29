extends Node2D

# One script for both stamps. The colour and the verdict are exported, so the
# green and red scenes are the same thing with different values set on them.
#
# Left mouse picks the stamp up and carries it; right mouse while it is over
# the document stamps the sheet.

@export var stamp_color: Color = Color.GREEN
## true stamps an approval, false a refusal.
@export var accepts: bool = true

## Two frames of the same stamp: handle up at rest, driven down when it hits
## the paper. Both frames of a pair draw at the same size, so swapping them
## reads as the handle being pushed in rather than the whole stamp resizing.
@export var rest_texture: Texture2D
@export var pressed_texture: Texture2D

## How long the pressed frame stays up after a stamp lands.
const PRESS_TIME := 0.16

@onready var sprite: Sprite2D = $Sprite2D

var is_dragging: bool = false
var is_over_document: bool = false
var is_mouse_inside: bool = false
## Where on the stamp it was grabbed. Kept so it hangs off the cursor from the
## point you picked it up rather than snapping its middle under the pointer.
var drag_offset: Vector2 = Vector2.ZERO
var _press_tween: Tween


func _ready() -> void:
	if rest_texture != null:
		sprite.texture = rest_texture


func get_document() -> Node2D:
	return get_tree().get_first_node_in_group("document") as Node2D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_mouse_inside:
				is_dragging = true
				drag_offset = global_position - get_global_mouse_position()
				get_viewport().set_input_as_handled()
			elif not event.pressed and is_dragging:
				is_dragging = false
				get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging and is_over_document:
				stamp_document()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() + drag_offset


func stamp_document() -> void:
	var doc := get_document()
	if doc and doc.has_method("apply_stamp"):
		press()
		doc.apply_stamp(stamp_color, accepts)


# Drive the handle down for a moment. A tween rather than an await, so stamping
# again mid-animation cannot leave it stuck on the pressed frame.
func press() -> void:
	if rest_texture == null or pressed_texture == null:
		return

	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()

	sprite.texture = pressed_texture
	_press_tween = create_tween()
	_press_tween.tween_interval(PRESS_TIME)
	_press_tween.tween_callback(func() -> void: sprite.texture = rest_texture)


# --- Area2D signals, wired in the scene ------------------------------------

func _on_area_2d_mouse_entered() -> void:
	is_mouse_inside = true


func _on_area_2d_mouse_exited() -> void:
	is_mouse_inside = false


# Only tracked, not shown. The stamp used to swell as it crossed the paper,
# which made it hard to place - the press animation carries the feedback now.
func _on_area_2d_area_entered(area: Area2D) -> void:
	if _is_document(area):
		is_over_document = true


func _on_area_2d_area_exited(area: Area2D) -> void:
	if _is_document(area):
		is_over_document = false


func _is_document(area: Area2D) -> bool:
	if area.is_in_group("document"):
		return true
	var parent := area.get_parent()
	return parent != null and parent.is_in_group("document")
