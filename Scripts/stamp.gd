@tool
extends Node2D

# A rubber stamp sitting in its ink case. The case and pad stay on the table;
# the coloured block is what you pick up and drag.
#
# Hold it over the document and it grows a little to show it is armed, then
# press Space to leave a mark on the paper in this stamp's colour.
#
# Colour is exported, so one scene covers both stamps - set it per instance.

const HOVER_GROW := 1.25

## Pad, block and the mark this stamp leaves all come from this one colour, so
## a stamp can never ink a different colour than it looks.
@export var ink := Color(0.19607843, 0.61960787, 0.28235295):
	set(value):
		ink = value
		apply_style()

@onready var case: ColorRect = $Case
@onready var pad: ColorRect = $Pad
@onready var block: Node2D = $Block
@onready var body: ColorRect = $Block/Body
@onready var handle: ColorRect = $Block/Handle

var dragging := false
var drag_offset := Vector2.ZERO


func _ready() -> void:
	apply_style()


func apply_style() -> void:
	# The setter fires before the scene is built, and again in the editor.
	if not is_node_ready():
		return
	body.color = ink
	# The pad reads as ink soaked into felt: same hue, darker and duller.
	pad.color = ink.darkened(0.45)
	case.color = ink.darkened(0.75)
	handle.color = ink.darkened(0.3)


# --- document awareness ---------------------------------------------------

# Found by group so the stamp does not care where the document sits in the
# scene, or whether it has been dragged somewhere else.
func document() -> Node2D:
	return get_tree().get_first_node_in_group("document") as Node2D


# True when the block is sitting over the paper and a press would land on it.
func over_document() -> bool:
	var doc := document()
	if doc == null or not doc.visible:
		return false
	return doc.sheet_rect().has_point(block_rect().get_center())


# The draggable part, in global space. Includes the hover growth.
func block_rect() -> Rect2:
	return Rect2(block.to_global(body.position), body.size * block.global_scale)


func refresh_hover() -> void:
	# Straight assignment rather than a tween: the growth is a state readout,
	# and an animation here would lag behind the mouse.
	block.scale = Vector2.ONE * (HOVER_GROW if over_document() else 1.0)


# --- input ----------------------------------------------------------------

func event_world_pos(event: InputEventMouse) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * event.position


func _unhandled_input(event: InputEvent) -> void:
	if Engine.is_editor_hint() or not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var at := event_world_pos(event)
		if event.pressed and block_rect().has_point(at):
			dragging = true
			drag_offset = block.global_position - at
			get_viewport().set_input_as_handled()
		elif not event.pressed and dragging:
			dragging = false
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and dragging:
		block.global_position = event_world_pos(event) + drag_offset
		refresh_hover()

	elif event is InputEventKey and event.keycode == KEY_SPACE:
		# echo guards against a held key stamping every frame.
		if event.pressed and not event.echo and over_document():
			stamp()
			get_viewport().set_input_as_handled()


func stamp() -> void:
	var doc := document()
	if doc == null:
		return
	doc.place_mark(block_rect().get_center(), ink)
