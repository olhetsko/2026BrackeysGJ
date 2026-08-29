extends Node2D

# The applicant. Fades into the window behind the counter when the bell is
# rung, and fades back out once their card is handed over - they arrive out of
# the dark rather than walking in from offscreen.
#
# Each race in document.gd's RACES has a matching Node2D under Races in
# people.tscn. Swap the sprites inside a group for new art and nothing here
# needs to change. Adding a race means adding a group with the exact same name.

const DocumentScript = preload("res://Scripts/document.gd")

## Where they materialise: centred in the window, sitting on the sill rather
## than sunk behind it. Derived from the Background sprite's frame, so move
## this if you move the backdrop.
const WINDOW_POS := Vector2(0.0, -27.0)

const ENTER_DELAY := 0.35
const FADE_IN := 0.9
const FADE_OUT := 0.6

@onready var races: Node2D = $Races

var tween: Tween
var arriving := false


func _ready() -> void:
	position = WINDOW_POS
	modulate.a = 0.0
	# The document finds the customer through this group to decide whether a
	# drop landed on them, so neither has to know the other's scene path.
	add_to_group("customer")
	show_race("")
	Global.next_customer_requested.connect(_on_next_customer_requested)
	Global.document_processed.connect(_on_document_processed)


func _on_next_customer_requested() -> void:
	if arriving == true:
		return
	arriving = true

	if tween and tween.is_valid():
		tween.kill()

	position = WINDOW_POS
	modulate.a = 0.0

	# Settled before they appear, so the creature in the window is the one the
	# card then describes. document.gd reads it back off Global.
	Global.current_race = DocumentScript.RACES.pick_random()
	show_race(Global.current_race)

	tween = create_tween()
	tween.tween_interval(ENTER_DELAY)
	tween.tween_property(self, "modulate:a", 1.0, FADE_IN) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(on_arrived)


func on_arrived() -> void:
	arriving = false
	# Being fully there is what hands the paperwork over.
	Global.customer_arrived.emit()


# Their business is done, so they melt back into the dark. Without this they
# would simply blink out when the next bell reset the alpha.
func _on_document_processed() -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, FADE_OUT) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


# Shows one race's sprite group and hides the rest. An empty or unknown name
# hides everyone, which is how the window starts out.
func show_race(race: String) -> void:
	for group in races.get_children():
		var visual := group as CanvasItem
		if visual != null:
			visual.visible = visual.name == race
