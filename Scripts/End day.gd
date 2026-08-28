extends Control

@onready var day_label: Label = $DayLabel
@onready var results_table: GridContainer = $ResultsTable
@onready var next_day_button: Button = $NextDayButton

func _ready() -> void:
	day_label.text = "DAY " + str(Global.current_day)
	next_day_button.pressed.connect(_on_next_day_pressed)
	populate_summary_table()

func populate_summary_table() -> void:
	# Build Column Headers
	create_table_cell("Customer ID", true)
	create_table_cell("Accepted", true)
	create_table_cell("Declined", true)

	# Build Rows for Each Customer
	for data in Global.daily_results:
		create_table_cell(data["id"], false)
		
		if data["action"] == "accepted":
			create_table_cell("Correct" if data["is_correct"] else "Wrong", false)
			create_table_cell("-", false)
		else:
			create_table_cell("-", false)
			create_table_cell("Correct" if data["is_correct"] else "Wrong", false)

func create_table_cell(text_content: String, is_header: bool) -> void:
	var label: Label = Label.new()
	label.text = text_content
	if is_header:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	results_table.add_child(label)

func _on_next_day_pressed() -> void:
	Global.advance_day()
	get_tree().change_scene_to_file("res://Game/Game.tscn")
