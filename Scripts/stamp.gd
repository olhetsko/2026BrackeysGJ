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

## Drop the block this close to its case and it clicks back into it, so putting
## a stamp away does not need pixel-perfect aiming. Measured in local units.
const SNAP_DISTANCE := 30.0

## Pad, block and the mark this stamp leaves all come from this one colour, so
## a stamp can never ink a different colour than it looks.
@export var ink := Color(0.19607843, 0.61960787, 0.28235295):
	set(value):
		ink = value
		apply_style()

## Which slot on the document this stamp fills when it lands. The green stamp
## is the accept stamp and fills the left "accept" slot; the red one fills
## the right "decline" slot. Set per instance in the scene.
@export var accept := true

@onready var case: ColorRect = $Case
@onready var pad: ColorRect = $Pad
@onready var block: Node2D = $Block
@onready var body: ColorRect = $Block/Body
@onready var handle: ColorRect = $Block/Handle

var dragging := false
var drag_offset := Vector2.ZERO
## Where the block sits in its case, taken from the scene so moving the case in
## the editor moves the resting place with it.
var home := Vector2.ZERO


func _ready() -> void:
	home = block.position
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
			snap_home_if_near()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and dragging:
		block.global_position = event_world_pos(event) + drag_offset
		refresh_hover()

	elif event is InputEventKey and event.keycode == KEY_SPACE:
		# Space is ONLY a stamp trigger. It must never deliver the document,
		# summon a new customer, advance the queue, or move the paper off the
		# desk. The bell's Button is kept focus-free so Space can't fire it
		# via ui_accept either; this handler then marks the event handled so
		# no other listener can chain off it.
		# echo guards against a held key stamping every frame.
		if event.pressed and not event.echo and over_document():
			stamp()
		# Always consume Space from this point on, even if no stamp landed:
		# pressing Space with the stamp somewhere else should do nothing at
		# all, certainly not ring the bell or advance the customer.
		get_viewport().set_input_as_handled()


# Let go near the case and the block drops back into it.
func snap_home_if_near() -> void:
	if block.position.distance_to(home) <= SNAP_DISTANCE:
		block.position = home
	refresh_hover()


func stamp() -> void:
	var doc := document()
	if doc == null:
		return
	# Hand the color and the slot routing to the document. The document owns
	# where the stamp appears; the stamp only contributes its ink color and
	# which side (accept / decline) it represents.
	doc.apply_stamp(ink, accept)
