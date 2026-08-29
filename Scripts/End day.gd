extends Control

# End-of-day summary.
#
# Top: one grid row per document handed back, marked Correct or Wrong.
# Bottom: a flippable review of the calls you got wrong - one page per
# document, listing the value that broke a rule on the left and the rule it
# broke on the right. No mistakes means a perfect day.

const DocumentScript = preload("res://Scripts/document.gd")

const CELL_FONT := preload("res://Assets/fonts/PixelOperator8.ttf")
const HEADER_FONT := preload("res://Assets/fonts/PixelOperator8-Bold.ttf")
const CELL_FONT_SIZE := 8

const INK := Color(0.92, 0.92, 0.92, 1)
const HEADER_INK := Color(1, 1, 1, 1)
const FIELD_INK := Color(0.95, 0.55, 0.5, 1)
const RULE_INK := Color(0.75, 0.75, 0.75, 1)

# Column widths inside the review grid, in its own (pre-scale) pixels.
const FIELD_COLUMN := 96.0
const RULE_COLUMN := 181.0

@onready var day_label: Label = $Label
@onready var score_label: Label = $Score
@onready var results_table: GridContainer = $GridContainer
@onready var continue_button: Button = $Button

@onready var review_title: Label = $Review/Title
@onready var review_index: Label = $Review/Index
@onready var review_doc: Label = $Review/DocLabel
@onready var fault_grid: GridContainer = $Review/FaultGrid
@onready var prev_button: Button = $Review/Prev
@onready var next_button: Button = $Review/Next

## Documents whose stamp was the wrong call, in id order.
var mistakes: Array[Dictionary] = []
var current_page: int = 0

## What today earned. Held rather than committed, so re-reading this screen
## cannot add it to the running total twice - that happens on Next Day.
var day_score: int = 0


func _ready() -> void:
	day_label.text = "DAY " + str(Global.current_day)
	show_score()

	if not continue_button.pressed.is_connected(_on_continue_pressed):
		continue_button.pressed.connect(_on_continue_pressed)
	prev_button.pressed.connect(func() -> void: flip(-1))
	next_button.pressed.connect(func() -> void: flip(1))

	for label in [review_title, review_index, review_doc]:
		label.add_theme_font_override("font", HEADER_FONT)

	populate_results()
	collect_mistakes()
	show_page(0)


# --- the results grid -----------------------------------------------------

func populate_results() -> void:
	# The stamped documents are logged to Global.daily_documents by
	# document.gd - that is the only list anything writes to.
	add_cell(results_table, "ID & Name", true)
	add_cell(results_table, "Accepted", true)
	add_cell(results_table, "Declined", true)

	for entry in sorted_entries():
		# id is an int, so it has to be formatted - "str" + int is an error in
		# GDScript, not a silent coercion.
		add_cell(results_table, "[%s] %s" % [
			entry.get("id", 0), entry.get("name", "Unknown"),
		], false)

		var verdict: String = "Correct" if judged_right(entry) else "Wrong"
		if was_approved(entry):
			add_cell(results_table, verdict, false)
			add_cell(results_table, "-", false)
		else:
			add_cell(results_table, "-", false)
			add_cell(results_table, verdict, false)


func sorted_entries() -> Array[Dictionary]:
	var entries := Global.daily_documents.duplicate()
	entries.sort_custom(func(a, b): return int(a.get("id", 0)) < int(b.get("id", 0)))
	return entries


func was_approved(entry: Dictionary) -> bool:
	return entry.get("status", "") == "approved"


# is_correct records whether the paperwork was clean. The player is right when
# they approved a clean sheet or turned away a flawed one.
func judged_right(entry: Dictionary) -> bool:
	return was_approved(entry) == bool(entry.get("is_correct", true))


# --- the mistake review ---------------------------------------------------

func collect_mistakes() -> void:
	mistakes.clear()
	for entry in sorted_entries():
		if not judged_right(entry):
			mistakes.append(entry)


func flip(step: int) -> void:
	if mistakes.size() < 2:
		return
	show_page(wrapi(current_page + step, 0, mistakes.size()))


func show_page(index: int) -> void:
	for child in fault_grid.get_children():
		child.queue_free()

	if mistakes.is_empty():
		review_title.text = "PERFECT DAY"
		review_index.text = ""
		review_doc.text = "Every call was right."
		prev_button.visible = false
		next_button.visible = false
		return

	current_page = clampi(index, 0, mistakes.size() - 1)
	var entry := mistakes[current_page]

	review_title.text = "MISTAKES"
	review_index.text = "%d / %d" % [current_page + 1, mistakes.size()]
	review_doc.text = "[%s] %s" % [entry.get("id", 0), entry.get("name", "Unknown")]

	# Flipping only makes sense with more than one mistake to flip between.
	var many := mistakes.size() > 1
	prev_button.visible = many
	next_button.visible = many

	var rows := DocumentScript.explain_faults(entry)
	if rows.is_empty():
		# The other kind of mistake: the sheet was clean and you turned it away,
		# so there is no offending value to point at.
		add_fault_row("APPROVED  no", "Nothing was wrong with it")
		return

	for row in rows:
		add_fault_row(str(row["field"]), str(row["rule"]))


func add_fault_row(field: String, rule: String) -> void:
	var field_label := make_label(field, HEADER_FONT, FIELD_INK)
	field_label.custom_minimum_size = Vector2(FIELD_COLUMN, 0)
	fault_grid.add_child(field_label)

	var rule_label := make_label(rule, CELL_FONT, RULE_INK)
	rule_label.custom_minimum_size = Vector2(RULE_COLUMN, 0)
	# Long rule text wraps inside its column instead of pushing the panel wide.
	rule_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	fault_grid.add_child(rule_label)


# --- shared label building ------------------------------------------------

func make_label(text: String, font: Font, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", CELL_FONT_SIZE)
	label.add_theme_color_override("font_color", color)
	return label


func add_cell(grid: GridContainer, text: String, is_header: bool) -> void:
	var label := make_label(
		text,
		HEADER_FONT if is_header else CELL_FONT,
		HEADER_INK if is_header else INK
	)
	if is_header:
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	grid.add_child(label)


# --- score -----------------------------------------------------------------

# Approving is the heavier call in both directions: +4 when the sheet really
# was clean, -4 when it was not. Refusing is the safer one: +2 and -2. The
# table itself lives in document.gd with the rest of the rules.
func show_score() -> void:
	day_score = DocumentScript.score_for_day(Global.daily_documents)
	score_label.text = "SCORE  %+d\nTOTAL  %d" % [
		day_score, Global.total_score + day_score,
	]


func _on_continue_pressed() -> void:
	Audio.play("nextday")
	# Committed here, not in _ready, so the day can only ever be banked once.
	Global.total_score += day_score
	Global.advance_day()
	get_tree().change_scene_to_file("res://Game/Game.tscn")
