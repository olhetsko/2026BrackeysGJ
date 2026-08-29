extends Control

# Title screen.
#
# The PLAY plate is painted into the title art, so it cannot be animated on its
# own. Instead a black patch covers the painted plate - the sign behind it is
# flat black there - and a cut-out copy of the plate sits on top at exactly the
# same size and place. That copy is what shrinks and pops on a press; the patch
# means nothing of the painted one shows through while it is small.

## Held off just long enough for the plate to pop before the scene swaps.
const START_DELAY := 0.2

@onready var plate: Sprite2D = $PlayPlate

var _plate_scale: Vector2
var _plate_position: Vector2
var _press_tween: Tween
var _starting := false


func _ready() -> void:
	_plate_scale = plate.scale
	_plate_position = plate.position

	# The drone starts here and is never stopped, so it carries through the
	# menu, the day and the summary without restarting at each scene change.
	Audio.start_music()


func _on_play_button_down() -> void:
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	Pop.hold(plate, _plate_scale, _plate_position)


# Fires whether the click finished on the button or slid off it, so the plate
# always comes back up rather than sticking small.
func _on_play_button_up() -> void:
	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	Pop.spring(_press_tween, plate, _plate_scale, _plate_position)


func _on_play_pressed() -> void:
	if _starting:
		return
	_starting = true
	Audio.play("start")

	# Not awaited: the plate is mid-spring and changing scene here would cut it
	# off on the first frame of the press.
	get_tree().create_timer(START_DELAY).timeout.connect(func() -> void:
		get_tree().change_scene_to_file("res://Game/Game.tscn")
	)
