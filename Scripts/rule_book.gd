extends Node2D

# ============================================================
# RULEBOOK (notepad format)
#
# A small notepad on the desk. One page is visible at a time;
# PREV / NEXT flip through entries. Header shows the section
# name, body shows the rules, footer shows "Page X / Y".
#
# Pixel font (PixelOperator8) renders sharp at size 8. Larger
# sizes (10, 12) look crisp too. Avoid sizes 3-7 — those
# fractional upscale and turn the text "flowy".
#
# All rule mechanics live here (single source of truth).
# ============================================================

# Each entry is one notepad page. Header on top, body underneath.
# Kept short so it reads like a real lined notepad.
@export var pages_data: Array[Dictionary] = [
	{
		"header": "WORKSPACES 1/3",
		"body":
			"Medical:\n" +
			"  Doctor, \n" +
			"  Nurse,\n" +
			"  Surgeon, \n" +
			"  Pharmacist,\n" +
			"  Therapist\n\n" +
			"Science:\n" +
			"  Biology, \n" +
			"  Chemistry,\n" +
			"  Physics,\n" +
			"  Research,\n" +
			"  Genetics"
	},
	{
		"header": "WORKSPACES 2/3",
		"body":
			"Engineering:\n" +
			"  Mechanical,\n" +
			"  Electrical,\n" +
			"  Structural,\n" +
			"  Robotics\n\n" +
			"Security:\n" +
			"  Guard, \n" +
			"  Investigator,\n" +
			"  Surveillance,\n" +
			"  Defense"
			
	},
	{
		"header": "WORKSPACES 3/5",
		"body":
			"Technology:\n" +
			"  Programming, \n" +
			"  AI,\n" +
			"  Cybersecurity,\n" +
			"  Hardware\n\n" +
			"Administration:\n" +
			"  Management,\n" +
			"  Finance,\n" +
			"  HR, \n" +
			"  Planning, \n" +
			"  Records"
	},
	
	{
		"header": "WORKSPACES 4/5",
		"body":
			"Maintenance:\n" +
			"  Repairs, \n" +
			"  Plumbing,\n" +
			"  Electrical,\n" +
			"  Machinery\n\n" +
			"Production:\n" +
			"  Manufacturing,\n" +
			"  Assembly, \n" +
			"  Quality\n\n" +
			"Agriculture:\n" +
			"  Farming, \n" +
			"  Botany,\n" +
			"  Livestock, \n" +
			"  Irrigation"
	},
	{
		"header": "WORKSPACES 4/5",
		"body":
			"Transportation:\n" +
			"  Piloting, \n" +
			"  Driving,\n" +
			"  Navigation, \n" +
			"  Logistics\n\n" +
			"Communications:\n" +
			"  Radio, \n" +
			"  Telecom,\n" +
			"  Broadcasting\n\n" +
			"Emergency:\n" +
			"  Firefighting, \n" +
			"  Rescue,\n" +
			"  First Aid, \n" +
			"  Evacuation"
	},
	{
		"header": "AGE LIMITS",
		"body":
			"Potato      1 - 3\n" +
			"Zombie      1 - 10\n" +
			"Eyeball     5 - 60\n" +
			"Goblin     15 - 200\n" +
			"Clown      18 - 90\n" +
			"Fra-stein   1 - 50\n" +
			"Mummy     100 - 4000\n" +
			"Dragon    100 - 5000\n" +
			"Ghost      50 - 10000"
	},
	{
		"header": "PERMIT DURATION",
		"body":
			"Max years a permit\n" +
			"may stay valid:\n\n" +
			"Zombie, Frankenstein,\n" +
			"Potato\n" +
			"  -> 2 yrs\n\n" +
			"Clown, Goblin,\n" +
			"Eyeball\n" +
			"  -> 5 yrs\n\n" +
			"Mummy, Ghost,\n" +
			"Dragon\n" +
			"  -> 20 yrs"
	},
	{
		"header": "RESTRICTED SECTORS",
		"body":
			"By race:\n\n" +
			"Dragon   : A, B, C\n" +
			"Ghost    : E\n" +
			"Clown    : E\n" +
			"Zombie   : J\n" +
			"Goblin   : J\n" +
			"Eyeball  : H\n\n" +
			"Others: no limit"
	},
	{
		"header": "NAME -> SECTOR",
		"body":
			"Last name initial\n" +
			"decides sector access:\n\n" +
			"A - G  -> A, B, C\n" +
			"H - N  -> D, E, F\n" +
			"O - Z  -> G, H, I, J"
	},
	{
		"header": "CLEARANCE 1 - 2",
		"body":
			"Level 1:\n" +
			"  Maintenance\n" +
			"  Agriculture\n" +
			"  Operations\n\n" +
			"Level 2:\n" +
			"  Production\n" +
			"  Transportation\n" +
			"  Communications\n" +
			"  Education\n\n"
	},
	{
		"header": "CLEARANCE 3 - 4",
		"body":
			"Level 3:\n" +
			"  Medical\n" +
			"  Science\n" +
			"  Engineering\n" +
			"  Administration\n" +
			"  Technology\n\n" +
			"Level 4:\n" +
			"  Security\n" +
			"  Research\n" +
			"  Emergency Ser-s"
	},
	{
		"header": "BODY TEMP",
		"body":
			"Ghost    -20 -> 10\n" +
			"Zombie     0 -> 10\n" +
			"Potato     4 -> 12\n" +
			"Mummy      5 -> 15\n" +
			"Eyeball   20 -> 30\n" +
			"Fra-stein 30 -> 35\n" +
			"Goblin    33 -> 37\n" +
			"Clown     36 -> 38\n" +
			"Dragon    80 -> 200\n\n" +
			"(values in °C)"
	},
	{
		"header": "SPECIALTY BANS",
		"body":
			"Ghost, Potato\n" +
			"  no Firefighting\n\n" +
			"Zombie no:\n" +
			"  Translation\n" +
			"  Broadcasting\n\n" +
			"Clown no:\n" +
			"  Surgeon\n" +
			"  Investigator\n\n" +
			"Goblin no:\n" +
			"  Finance, Records\n\n" +
			"Eyeball no:\n" +
			"  Piloting, Assembly"
	}
]


# ============================================================
# NODES
# ============================================================

@onready var area_2d: Area2D = $Area2D
@onready var page_label: RichTextLabel = $PageLabel
@onready var header_label: RichTextLabel = $HeaderLabel
@onready var page_indicator: RichTextLabel = $PageIndicator
@onready var prev_button: Button = $prev_button
@onready var next_button: Button = $next_button


# ============================================================
# STATE
# ============================================================

const DocumentScript = preload("res://Scripts/document.gd")

var is_dragging := false
var drag_offset := Vector2.ZERO
var current_page := 0

## The pages actually in the book today. The rules arrive a day at a time, so
## the book only ever shows what the player has been given.
var visible_pages: Array[Dictionary] = []


# Keeps the book in step with document.gd's RULE_STAGES: a page appears on the
# day its rule starts being checked, so the book can never be missing a rule
# the game is testing, or list one that is not in play yet.
func rebuild_pages() -> void:
	var tags := DocumentScript.active_book_tags(Global.current_day)
	visible_pages.clear()

	for page in pages_data:
		var header := str(page.get("header", ""))
		for tag in tags:
			if header.begins_with(tag):
				visible_pages.append(page)
				break

	current_page = clampi(current_page, 0, maxi(0, visible_pages.size() - 1))


# ============================================================
# READY
# ============================================================

func _ready() -> void:

	# Pixel font: turn OFF subpixel positioning so glyphs land on
	# whole pixels. Without this, the font gets antialiased and
	# looks "flowy" at non-native sizes.
	for lbl in [page_label, header_label, page_indicator]:
		if lbl == null:
			continue
		lbl.bbcode_enabled = true
		lbl.scroll_active = false
		lbl.fit_content = true
		lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		lbl.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# 0 = SUBPIXEL_POSITIONING_DISABLED — keeps pixel fonts
		# crisp; without this Godot antialiases glyphs.
		lbl.add_theme_constant_override(
			"font_subpixel_positioning",
			TextServer.SUBPIXEL_POSITIONING_DISABLED
		)

	rebuild_pages()

	# Rulebook.tscn already wires input_event and both button presses to these
	# methods, so connecting them here too just raised "already connected"
	# three times on every scene load.

	update_page_display()


# ============================================================
# DRAG NOTEPAD
# ============================================================

func _on_area_2d_input_event(
	_viewport: Node,
	event: InputEvent,
	_shape_idx: int
) -> void:

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:

		if event.pressed:
			is_dragging = true
			drag_offset = global_position - get_global_mouse_position()
		else:
			is_dragging = false


func _input(event: InputEvent) -> void:

	if event is InputEventMouseButton \
		and event.button_index == MOUSE_BUTTON_LEFT \
		and not event.pressed:
		is_dragging = false

	elif event is InputEventMouseMotion and is_dragging:
		global_position = get_global_mouse_position() + drag_offset


# ============================================================
# PAGE DISPLAY
# ============================================================

func update_page_display() -> void:

	if visible_pages.is_empty():
		if header_label:
			header_label.text = "RULEBOOK"
		if page_label:
			page_label.text = "No rules loaded."
		if page_indicator:
			page_indicator.text = "0 / 0"
		return

	var total := visible_pages.size()
	current_page = clamp(current_page, 0, total - 1)

	var entry: Dictionary = visible_pages[current_page]
	var header_text: String = str(entry.get("header", ""))
	var body_text: String = str(entry.get("body", ""))

	if header_label:
		header_label.text = header_text

	if page_label:
		page_label.text = body_text

	if page_indicator:
		page_indicator.text = "Page %d / %d" % [current_page + 1, total]



# ============================================================
# PREV / NEXT
# ============================================================

func _on_prev_button_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_page_display()
		# One of four takes, picked at random, so paging through the book does
		# not click identically every time.
		Audio.play("flip")
		Global.rulebook_page_turned.emit()


func _on_next_button_pressed() -> void:
	if current_page < visible_pages.size() - 1:
		current_page += 1
		update_page_display()
		Audio.play("flip")
		Global.rulebook_page_turned.emit()
