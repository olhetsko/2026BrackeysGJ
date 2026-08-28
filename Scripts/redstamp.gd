extends Node2D

@export var scale_multiplier: Vector2 = Vector2(1.2, 1.2)
@export var stamp_color: Color = Color.RED

var is_dragging: bool = false
var original_scale: Vector2
var is_over_document: bool = false
var is_mouse_inside: bool = false

func _ready() -> void:
	original_scale = scale

func get_document() -> Node2D:
	return get_tree().get_first_node_in_group("document") as Node2D

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Pickup stamp if mouse is inside the Area2D shape
				if is_mouse_inside:
					is_dragging = true
					global_position = get_global_mouse_position()
					get_viewport().set_input_as_handled()
			else:
				if is_dragging:
					is_dragging = false
					get_viewport().set_input_as_handled()

		elif event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
			if is_dragging and is_over_document:
				_apply_stamp_to_document()
				get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position()

func _apply_stamp_to_document() -> void:
	var doc = get_document()
	if doc and doc.has_method("apply_stamp"):
		if "document_decision" in Global:
			Global.document_decision = "permitted"
		doc.apply_stamp(stamp_color, false)

# Area2D Mouse Signals (Connect these in the Inspector)
func _on_area_2d_mouse_entered() -> void:
	is_mouse_inside = true

func _on_area_2d_mouse_exited() -> void:
	is_mouse_inside = false

# Area2D Document Signals
func _on_area_2d_area_entered(area: Area2D) -> void:
	if area.is_in_group("document") or area.get_parent().is_in_group("document"):
		is_over_document = true
		scale = original_scale * scale_multiplier

func _on_area_2d_area_exited(area: Area2D) -> void:
	if area.is_in_group("document") or area.get_parent().is_in_group("document"):
		is_over_document = false
		scale = original_scale
