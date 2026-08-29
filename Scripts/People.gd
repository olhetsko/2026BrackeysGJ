extends Node2D

# The applicant. Walks in from the left when the bell is rung, and wears the
# sprite group for their species.
#
# Each race in document.gd's RACES has a matching Node2D under Races in
# people.tscn. They are placeholder rectangles for now - swap the sprites
# inside a group for real art and nothing here needs to change. Adding a race
# means adding a group with the exact same name.

const DocumentScript = preload("res://Scripts/document.gd")

const START_POS := Vector2(-174, -22)
const COUNTER_X := 0.0
const ENTER_DELAY := 0.4
const WALK_TIME := 1.0

@onready var races: Node2D = $Races

var tween: Tween
var arriving := false


func _ready() -> void:
	position = START_POS
	# The document finds the customer through this group to decide whether a
	# drop landed on them, so neither has to know the other's scene path.
	add_to_group("customer")
	show_race("")
	Global.next_customer_requested.connect(_on_next_customer_requested)


func _on_next_customer_requested() -> void:
	if arriving == true:
		return
	arriving = true

	if tween and tween.is_valid():
		tween.kill()
	position = START_POS

	# Settled before the walk, so the creature who arrives is the one the card
	# then describes. document.gd reads it back off Global.
	Global.current_race = DocumentScript.RACES.pick_random()
	show_race(Global.current_race)

	tween = create_tween()
	tween.tween_interval(ENTER_DELAY)
	tween.tween_property(self, "position:x", COUNTER_X, WALK_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.finished.connect(on_arrived)


func on_arrived() -> void:
	arriving = false
	# Reaching the counter is what hands the paperwork over.
	Global.customer_arrived.emit()


# Shows one race's sprite group and hides the rest. An empty or unknown name
# hides everyone, which is how the counter starts out.
func show_race(race: String) -> void:
	for group in races.get_children():
		var visual := group as CanvasItem
		if visual != null:
			visual.visible = visual.name == race
