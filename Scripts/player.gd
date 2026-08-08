extends CharacterBody2D


const SPEED = 100.0
const JUMP_VELOCITY = -250.0

# Animations that play through to the end. While one of these is running,
# any other animation request is ignored unless it asks with force = true.
const HOLDS_UNTIL_FINISHED := ["Attack1", "Attack2"]

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var _holding := false

func _ready() -> void:
	Global.Moving = true

func _physics_process(delta: float) -> void:
	if not Global.Moving:
		return

	if not is_on_floor():
		velocity += get_gravity() * delta

	var direction := Input.get_axis("Left", "Right")

	# Deliberate actions force their way past an animation that is holding.
	if Input.is_action_just_pressed("Hit"):
		_play("Attack1", true)

	if Input.is_action_just_pressed("Jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
		_play("Jump", true)

	if direction != 0:
		velocity.x = direction * SPEED
		sprite.flip_h = direction < 0
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)

	# Ambient state. Never forces, so it waits for an attack to finish.
	if not is_on_floor():
		_play("Jump")
	elif direction != 0:
		_play("Run")
	else:
		_play("Idle")

	move_and_slide()

func _play(anim: String, force := false) -> void:
	if _holding and not force:
		return
	if sprite.animation == anim and sprite.is_playing():
		return

	_holding = anim in HOLDS_UNTIL_FINISHED
	Global.Is_attacking = _holding
	sprite.play(anim)


func _on_animated_sprite_2d_animation_finished() -> void:
	if sprite.animation in HOLDS_UNTIL_FINISHED:
		_holding = false
		Global.Is_attacking = false
