class_name Pop
extends RefCounted

# Shared press feel for clickable art: it shrinks while the button is held, then
# springs back a touch past its resting size before settling. Kept in one place
# so the desk bell and the PLAY plate pop the same way.

## How small the art gets while held.
const SHRINK := 0.88
## How long the spring back runs. TRANS_BACK overshoots inside this window,
## which is what reads as a "pop" instead of a slide.
const SPRING_TIME := 0.26

## For art that stands on a surface: the base stays planted while it shrinks.
const ANCHOR_BOTTOM := 1.0
## For art that floats: it shrinks evenly about its middle.
const ANCHOR_CENTRE := 0.5


## Shrink `sprite` right now, keeping the point `anchor` of the way down it
## (0 = top edge, 1 = bottom edge) pinned. Without this the bell would appear
## to hop off the desk as it shrank.
static func hold(
	sprite: Sprite2D,
	base_scale: Vector2,
	base_position: Vector2,
	anchor: float = ANCHOR_CENTRE
) -> void:
	sprite.scale = base_scale * SHRINK
	sprite.position = base_position + Vector2(0.0, _pin_offset(sprite, base_scale, anchor))


## Queue the spring back onto an existing tween, so it can follow whatever else
## that tween is already doing - the bell holds its struck frame up first.
static func spring(
	tween: Tween,
	sprite: Sprite2D,
	base_scale: Vector2,
	base_position: Vector2
) -> void:
	tween.tween_property(sprite, "scale", base_scale, SPRING_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(sprite, "position", base_position, SPRING_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


# How far to slide the sprite so the anchored edge does not move when it shrinks.
static func _pin_offset(sprite: Sprite2D, base_scale: Vector2, anchor: float) -> float:
	if sprite.texture == null:
		return 0.0
	var drawn_height: float = sprite.texture.get_height() * base_scale.y
	return (anchor - 0.5) * drawn_height * (1.0 - SHRINK)
