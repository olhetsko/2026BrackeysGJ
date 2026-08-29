extends Node2D

# The desk bell. Ringing swaps to the struck frame for a moment, so it visibly
# thumps down and springs back, then locks out until the customer has had time
# to arrive.

const COOLDOWN := 1.5
## How long the struck frame stays up. Short enough to read as an impact.
const PRESS_TIME := 0.12

## Both frames share a canvas, but the bell is drawn much smaller in the struck
## one - swapping them raw shrinks it by nearly 40%, which reads as a jump
## rather than a tap.
@export var rest_texture: Texture2D
@export var pressed_texture: Texture2D
## Sprite scale to use while the struck frame is up. Set larger than the rest
## scale to claw back most of that size difference, leaving a small dip.
@export var pressed_sprite_scale: Vector2 = Vector2(0.0913, 0.0913)
## Nudge for the struck frame. The bell is not drawn in the same spot on both
## canvases, so without this it jumps sideways and downward when swapped. The
## values line the two frames up by their bases, since that is what rests on
## the desk. Tools/inspect_art.gd prints the numbers these come from.
@export var pressed_sprite_offset: Vector2 = Vector2(0.59, -1.36)

@onready var sprite: Sprite2D = $Sprite2D
@onready var _button: Button = $Button

var _cooldown_timer: Timer
var _press_tween: Tween
var _rest_sprite_scale: Vector2
var _rest_sprite_position: Vector2


func _ready() -> void:
	_rest_sprite_scale = sprite.scale
	_rest_sprite_position = sprite.position
	if rest_texture != null:
		sprite.texture = rest_texture

	# A real one-shot Timer node instead of awaiting inside _process(), which
	# used to start a fresh timer every frame the bell was on cooldown.
	_cooldown_timer = Timer.new()
	_cooldown_timer.one_shot = true
	_cooldown_timer.wait_time = COOLDOWN
	_cooldown_timer.timeout.connect(_on_cooldown_finished)
	add_child(_cooldown_timer)


func _on_button_button_down() -> void:
	# Disabling the button means spam clicks never reach this handler at all,
	# but guard anyway in case the signal is fired from elsewhere.
	if not _cooldown_timer.is_stopped():
		return

	strike()
	Audio.play("bell", 0.03)
	Global.next_customer_requested.emit()
	_button.disabled = true
	_cooldown_timer.start()


# Show the struck frame briefly. A tween rather than an await so a second ring
# cannot leave the bell stuck on the wrong frame.
func strike() -> void:
	if pressed_texture == null or rest_texture == null:
		return

	if _press_tween and _press_tween.is_valid():
		_press_tween.kill()

	sprite.texture = pressed_texture
	sprite.scale = pressed_sprite_scale
	sprite.position = _rest_sprite_position + pressed_sprite_offset
	_press_tween = create_tween()
	_press_tween.tween_interval(PRESS_TIME)
	_press_tween.tween_callback(func() -> void:
		sprite.texture = rest_texture
		sprite.scale = _rest_sprite_scale
		sprite.position = _rest_sprite_position
	)


func _on_cooldown_finished() -> void:
	_button.disabled = false
