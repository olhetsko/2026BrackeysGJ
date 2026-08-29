extends Node2D

# One script for both stamps. The colour and the verdict are exported, so the
# green and red scenes are the same thing with different values set on them.
#
# Left mouse picks the stamp up and carries it; right mouse while it is over
# the document stamps the sheet.

@export var scale_multiplier: Vector2 = Vector2(1.2, 1.2)
@export var stamp_color: Color = Color.GREEN
## true stamps an approval, false a refusal.
@export var accepts: bool = true

var is_dragging: bool = false
var is_over_document: bool = false
var is_mouse_inside: bool = false
var original_scale: Vector2


func _ready() -> void:
	original_scale = scale


func get_document() -> Node2D:
	return get_tree().get_first_node_in_group("document") as Node2D


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and is_mouse_inside:
				is_dragging = true
				global_position = get_global_mouse_position()
				get_viewport().set_input_as_handled()
			elif not event.pressed and is_dragging:
				is_dragging = false
				get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging and is_over_document:
				stamp_document()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position()


func stamp_document() -> void:
	var doc := get_document()
	if doc and doc.has_method("apply_stamp"):
		doc.apply_stamp(stamp_color, accepts)


# --- Area2D signals, wired in the scene ------------------------------------

func _on_area_2d_mouse_entered() -> void:
	is_mouse_inside = true


func _on_area_2d_mouse_exited() -> void:
	is_mouse_inside = false


func _on_area_2d_area_entered(area: Area2D) -> void:
	if _is_document(area):
		is_over_document = true
		scale = original_scale * scale_multiplier


func _on_area_2d_area_exited(area: Area2D) -> void:
	if _is_document(area):
		is_over_document = false
		scale = original_scale


func _is_document(area: Area2D) -> bool:
	if area.is_in_group("document"):
		return true
	var parent := area.get_parent()
	return parent != null and parent.is_in_group("document")
