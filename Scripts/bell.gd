extends Node2D

const COOLDOWN := 1.5

@onready var _button: Button = $Button

var _cooldown_timer: Timer

func _ready() -> void:
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
	Audio.play("bell", 0.03)
	Global.next_customer_requested.emit()
	_button.disabled = true
	_cooldown_timer.start()


func _on_cooldown_finished() -> void:
	_button.disabled = false
