extends Control

@onready var day_label: Label = $Label
@onready var results_table: GridContainer = $GridContainer
@onready var continue_button: Button = $Button

func _ready() -> void:
	day_label.text = "DAY " + str(Global.current_day)
	
	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
		
	populate_results()

func populate_results() -> void:
	# Sort entries by ID ascending
	Global.daily_results.sort_custom(func(a, b): return int(a["id"]) < int(b["id"]))
	
	# Headers
	add_cell("ID & Name", true)
	add_cell("Accepted", true)
	add_cell("Declined", true)
	
	# Rows
	for entry in GameManager.daily_results:
		add_cell("[" + entry["id"] + "] " + entry["name"], false)
		
		var status_text: String = "Correct" if entry["is_correct"] else "Wrong"
		
		if entry["action"] == "accepted":
			add_cell(status_text, false)
			add_cell("-", false)
		else:
			add_cell("-", false)
			add_cell(status_text, false)

func add_cell(text: String, is_header: bool) -> void:
	var label: Label = Label.new()
	label.text = text
	if is_header:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_table.add_child(label)

func _on_continue_pressed() -> void:
	Global.advance_day()
	get_tree().change_scene_to_file("res://Game/Game.tscn")
