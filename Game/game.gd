extends Node2D

# Runs the day: tracks how many customers are still owed, and swaps the bell
# for the Next Day button once the quota is served.

const MIN_CUSTOMERS := 6
const MAX_CUSTOMERS := 10
const END_DAY_SCENE := "res://Game/EndDay.tscn"

@onready var bell_node: Node2D = $Bell
@onready var next_day_node: Node2D = $Next

var max_customers_today: int = 0


func _ready() -> void:
	# Covers launching straight into the game without passing the menu.
	Audio.start_music()
	max_customers_today = randi_range(MIN_CUSTOMERS, MAX_CUSTOMERS)

	next_day_node.visible = false
	bell_node.visible = true

	Global.next_day_requested.connect(_on_next_day_requested)
	Global.document_processed.connect(_on_document_processed)


func _on_document_processed() -> void:
	var served := Global.daily_documents.size()
	print("[GAME] Customers served today: %d / %d" % [served, max_customers_today])

	# Quota met: hide the bell so no more customers can be called, and offer
	# the Next Day button instead. Hiding the bell is the quota gate - an
	# invisible Button takes no clicks.
	if served >= max_customers_today:
		bell_node.visible = false
		next_day_node.visible = true


func _on_next_day_requested() -> void:
	var error_code := get_tree().change_scene_to_file(END_DAY_SCENE)
	if error_code != OK:
		push_error("Failed to load %s (code %d)" % [END_DAY_SCENE, error_code])
