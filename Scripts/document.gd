extends Node2D

# -------------------------------------------------------------------------
# DOCUMENT POSITIONS / ANIMATION
# -------------------------------------------------------------------------

const HIDDEN_POS := Vector2(-107.0, -22.0)
const SHOWN_POS := Vector2(-30.0, 34.0)
const SLIDE_TIME := 0.45

# -------------------------------------------------------------------------
# DAILY TRACKING DATA
# -------------------------------------------------------------------------

static var daily_documents: Array[Dictionary] = []
static var current_day_id: int = 1

# Call this method whenever a new day begins
static func start_new_day() -> void:
	daily_documents.clear()
	current_day_id = 1
	print("[DOCUMENT MANAGER] New day started. Array and ID reset to 1.")

static func print_daily_summary() -> void:
	print("================ DAILY LOG SUMMARY ================")
	for entry in daily_documents:
		print(entry)
	print("==================================================")

# -------------------------------------------------------------------------
# BASIC DATA
# -------------------------------------------------------------------------

const FIRST_NAMES: Array[String] = [
	"Adrian", "Bianca", "Cyrus", "Dahlia", "Emil",
	"Farrah", "Gideon", "Hazel", "Ivan", "Juno",
	"Kaspar", "Lyra", "Milo", "Nadia", "Osric",
	"Petra", "Quentin", "Rosalind", "Silas", "Thea",
]

const LAST_NAMES: Array[String] = [
	"Abernathy", "Blackwood", "Castellan", "Drummond", "Ellsworth",
	"Fairbairn", "Gallagher", "Hollister", "Ivanova", "Jessup",
	"Kowalski", "Lindqvist", "Marchetti", "Novikov", "Okonkwo",
	"Pemberton", "Quintero", "Rasmussen", "Sandoval", "Thornbury",
]

const RACES: Array[String] = [
	"Werewolf",
	"Frankenstein",
	"Mummy",
	"Zombie",
	"Ghost",
	"Witch",
	"Sea Monster",
	"Troll",
	"Dragon",
]

const SECTORS: Array[String] = [
	"A", "B", "C", "D", "E", "F", "G", "H", "I", "J",
]

const WORKSPACES := {
	"Medical": ["Doctor", "Nurse", "Surgeon", "Pharmacist", "Therapist"],
	"Science": ["Biology", "Chemistry", "Physics", "Research", "Genetics"],
	"Engineering": ["Mechanical", "Electrical", "Structural", "Robotics", "Systems"],
	"Security": ["Guard", "Investigator", "Surveillance", "Security Systems", "Defense"],
	"Technology": ["Programming", "AI", "Cybersecurity", "Data Analysis", "Hardware"],
	"Administration": ["Management", "Finance", "Human Resources", "Planning", "Records"],
	"Maintenance": ["Repairs", "Plumbing", "Electrical", "Machinery", "Cleaning"],
	"Production": ["Manufacturing", "Assembly", "Quality Control", "Processing", "Packaging"],
	"Agriculture": ["Farming", "Botany", "Livestock", "Food Production", "Irrigation"],
	"Transportation": ["Piloting", "Driving", "Navigation", "Logistics", "Vehicle Maintenance"],
	"Communications": ["Radio", "Telecommunications", "Broadcasting", "Translation", "Networking"],
	"Research": ["Experiments", "Testing", "Documentation", "Analysis", "Development"],
	"Emergency Services": ["Firefighting", "Rescue", "First Aid", "Disaster Response", "Evacuation"],
	"Education": ["Teaching", "Training", "Research", "Administration", "Counseling"],
	"Operations": ["Coordination", "Scheduling", "Supervision", "Logistics", "Management"],
}

# -------------------------------------------------------------------------
# VALIDATION DATASET
# -------------------------------------------------------------------------

const RACE_AGE_LIMITS := {
	"Zombie": {"min": 1, "max": 10},
	"Frankenstein": {"min": 1, "max": 50},
	"Werewolf": {"min": 18, "max": 120},
	"Witch": {"min": 18, "max": 300},
	"Troll": {"min": 20, "max": 250},
	"Sea Monster": {"min": 20, "max": 200},
	"Mummy": {"min": 100, "max": 4000},
	"Ghost": {"min": 50, "max": 10000},
	"Dragon": {"min": 100, "max": 5000},
}

const RESTRICTED_SECTORS_PER_RACE := {
	"Troll": ["A", "B", "C"],
	"Dragon": ["A", "B", "C"],
	"Ghost": ["E"],
	"Sea Monster": ["E"],
	"Zombie": ["J"],
	"Werewolf": [],
	"Frankenstein": [],
	"Witch": [],
	"Mummy": [],
}

const WORKPLACE_CLEARANCE_LEVELS := {
	"Maintenance": 1,
	"Agriculture": 1,
	"Operations": 1,
	"Production": 2,
	"Transportation": 2,
	"Communications": 2,
	"Education": 2,
	"Medical": 3,
	"Science": 3,
	"Engineering": 3,
	"Administration": 3,
	"Technology": 3,
	"Security": 4,
	"Research": 4,
	"Emergency Services": 4,
}

const NAME_SECTOR_RULES := {
	"A-G": ["A", "B", "C"],
	"H-N": ["D", "E", "F"],
	"O-Z": ["G", "H", "I", "J"],
}

const MAX_PERMIT_DURATION_YEARS := {
	"Zombie": 2,
	"Frankenstein": 2,
	"Werewolf": 5,
	"Witch": 5,
	"Troll": 5,
	"Sea Monster": 20,
	"Mummy": 20,
	"Ghost": 20,
	"Dragon": 20,
}

const RESTRICTED_SPECIALTIES_PER_RACE := {
	"Ghost": ["Firefighting"],
	"Sea Monster": ["Firefighting"],
	"Zombie": ["Translation", "Broadcasting", "Speech"],
	"Troll": ["Robotics", "Programming", "Hardware"],
	"Werewolf": [],
	"Frankenstein": [],
	"Witch": [],
	"Mummy": [],
	"Dragon": [],
}

const BODY_TEMP_RANGES_CELSIUS := {
	"Ghost": {"min": -20.0, "max": 10.0},
	"Zombie": {"min": 0.0, "max": 10.0},
	"Mummy": {"min": 5.0, "max": 15.0},
	"Werewolf": {"min": 36.0, "max": 39.0},
	"Witch": {"min": 36.0, "max": 37.5},
	"Frankenstein": {"min": 30.0, "max": 35.0},
	"Troll": {"min": 35.0, "max": 38.0},
	"Sea Monster": {"min": 10.0, "max": 22.0},
	"Dragon": {"min": 80.0, "max": 200.0},
}

# -------------------------------------------------------------------------
# UI REFERENCES
# -------------------------------------------------------------------------

@onready var sheet: Sprite2D = $Sprite2D

@onready var name_label: Label = $"Fields/NameValue"
@onready var age_label: Label = $"Fields/AgeValue"
@onready var race_label: Label = $"Fields/RaceValue"
@onready var workspace_label: Label = $"Fields/WorkspaceValue"
@onready var specialty_label: Label = $"Fields/SpecialtyValue"
@onready var sector_label: Label = $"Fields/SectorValue"
@onready var online_label: Label = $"Fields/OnlineValue"

@onready var clearance_label: Label = $"Fields/ClearanceValue"
@onready var permit_issue_label: Label = $"Fields/PermitIssueValue"
@onready var permit_expiry_label: Label = $"Fields/PermitExpiryValue"
@onready var body_temp_label: Label = $"Fields/BodyTempValue"

@onready var mark: CanvasItem = $Mark


# -------------------------------------------------------------------------
# STATE
# -------------------------------------------------------------------------

var tween: Tween
var dragging := false
var drag_offset := Vector2.ZERO

var is_stamped := false
var stamp_decision: String = "unprocessed"
var document_id: int = 0
var has_discrepancy: bool = false

var _drag_start_pos := Vector2.ZERO

var document_name: String = ""
var document_age: int = 0
var document_race: String = ""
var document_workspace: String = ""
var document_specialty: String = ""
var document_sector: String = ""
var document_online: bool = false

var security_clearance: int = 0
var permit_issue_year: int = 0
var permit_expiry_year: int = 0
var body_temperature: float = 0.0

# -------------------------------------------------------------------------
# READY
# -------------------------------------------------------------------------

func _ready() -> void:
	position = HIDDEN_POS
	visible = false
	_reset_stamp_visibilities()

	add_to_group("document")

	Global.customer_arrived.connect(on_customer_arrived)
	Global.next_customer_requested.connect(on_next_customer_requested)

# -------------------------------------------------------------------------
# CUSTOMER / DOCUMENT FLOW
# -------------------------------------------------------------------------

func on_customer_arrived() -> void:
	roll_person()
	slide_to(SHOWN_POS)

func on_next_customer_requested() -> void:
	leave()

func leave() -> void:
	dragging = false
	slide_to(HIDDEN_POS)

	tween.finished.connect(func() -> void:
		visible = false
	)

# -------------------------------------------------------------------------
# GENERATE DOCUMENT
# -------------------------------------------------------------------------

func roll_person() -> void:
	visible = true
	is_stamped = false
	stamp_decision = "unprocessed"
	has_discrepancy = false
	
	document_id = current_day_id
	current_day_id += 1

	_reset_stamp_visibilities()

	document_name = "%s %s" % [
		FIRST_NAMES.pick_random(),
		LAST_NAMES.pick_random()
	]

	document_race = RACES.pick_random()

	var age_data: Dictionary = RACE_AGE_LIMITS[document_race]
	document_age = randi_range(int(age_data["min"]), int(age_data["max"]))

	document_workspace = str(WORKSPACES.keys().pick_random())
	var valid_specialties: Array = WORKSPACES[document_workspace]
	document_specialty = str(valid_specialties.pick_random())

	document_sector = get_valid_sector_for_document()
	document_online = randi() % 2 == 0

	var required_clearance: int = WORKPLACE_CLEARANCE_LEVELS[document_workspace]
	security_clearance = randi_range(required_clearance, 4)

	permit_issue_year = randi_range(2020, 2026)
	var max_duration: int = MAX_PERMIT_DURATION_YEARS[document_race]
	var valid_duration := randi_range(0, max_duration)
	permit_expiry_year = permit_issue_year + valid_duration

	var temp_data: Dictionary = BODY_TEMP_RANGES_CELSIUS[document_race]
	body_temperature = randf_range(float(temp_data["min"]), float(temp_data["max"]))

	name_label.text = document_name
	age_label.text = str(document_age)
	race_label.text = document_race
	workspace_label.text = document_workspace
	specialty_label.text = document_specialty
	sector_label.text = document_sector

	clearance_label.text = str(security_clearance)
	permit_issue_label.text = str(permit_issue_year)
	permit_expiry_label.text = str(permit_expiry_year)
	body_temp_label.text = "%.1f °C" % body_temperature

	var failure_roll := randi_range(1, 5)
	print("[DOCUMENT #%d] Failure roll = %d" % [document_id, failure_roll])

	if failure_roll == 1:
		has_discrepancy = true
		make_one_field_wrong()

func get_valid_sector_for_document() -> String:
	var last_name := document_name.get_slice(" ", 1)
	var initial := last_name.substr(0, 1).to_upper()

	var allowed_by_name: Array = []

	if initial >= "A" and initial <= "G":
		allowed_by_name = NAME_SECTOR_RULES["A-G"]
	elif initial >= "H" and initial <= "N":
		allowed_by_name = NAME_SECTOR_RULES["H-N"]
	elif initial >= "O" and initial <= "Z":
		allowed_by_name = NAME_SECTOR_RULES["O-Z"]
	else:
		return "A"

	var restricted: Array = RESTRICTED_SECTORS_PER_RACE[document_race]
	var valid_sectors: Array = []

	for sector in allowed_by_name:
		if sector not in restricted:
			valid_sectors.append(sector)

	if valid_sectors.is_empty():
		return str(allowed_by_name[0])

	return str(valid_sectors.pick_random())

func make_one_field_wrong() -> void:
	var possible_failures := [
		"AGE",
		"SECTOR",
		"CLEARANCE",
		"NAME_SECTOR",
		"PERMIT",
		"SPECIALTY",
		"TEMPERATURE"
	]

	var failure_type: String = possible_failures.pick_random()
	print("[DOCUMENT #%d] Creating discrepancy: %s" % [document_id, failure_type])

	match failure_type:
		"AGE":
			make_age_wrong()
		"SECTOR":
			make_sector_wrong()
		"CLEARANCE":
			make_clearance_wrong()
		"NAME_SECTOR":
			make_name_sector_wrong()
		"PERMIT":
			make_permit_wrong()
		"SPECIALTY":
			make_specialty_wrong()
		"TEMPERATURE":
			make_temperature_wrong()

func make_age_wrong() -> void:
	var limits: Dictionary = RACE_AGE_LIMITS[document_race]
	var minimum: int = int(limits["min"])
	var maximum: int = int(limits["max"])

	if randi() % 2 == 0:
		document_age = minimum - 1
	else:
		document_age = maximum + 1

	age_label.text = str(document_age)

func make_sector_wrong() -> void:
	var last_name := document_name.get_slice(" ", 1)
	var initial := last_name.substr(0, 1).to_upper()
	var allowed_by_name: Array = []

	if initial >= "A" and initial <= "G":
		allowed_by_name = NAME_SECTOR_RULES["A-G"]
	elif initial >= "H" and initial <= "N":
		allowed_by_name = NAME_SECTOR_RULES["H-N"]
	elif initial >= "O" and initial <= "Z":
		allowed_by_name = NAME_SECTOR_RULES["O-Z"]

	var restricted: Array = RESTRICTED_SECTORS_PER_RACE[document_race]
	var wrong_sectors: Array = []

	for sector in SECTORS:
		if sector not in allowed_by_name and sector not in restricted:
			wrong_sectors.append(sector)

	if not wrong_sectors.is_empty():
		document_sector = str(wrong_sectors.pick_random())
	else:
		var race_restricted: Array = restricted
		if not race_restricted.is_empty():
			document_sector = str(race_restricted.pick_random())

	sector_label.text = document_sector

func make_clearance_wrong() -> void:
	var required: int = WORKPLACE_CLEARANCE_LEVELS[document_workspace]

	if required > 1:
		security_clearance = required - 1
	else:
		security_clearance = 0

	clearance_label.text = str(security_clearance)

func make_name_sector_wrong() -> void:
	var current_last_name := document_name.get_slice(" ", 1)
	var new_last_name := current_last_name

	while new_last_name == current_last_name:
		new_last_name = str(LAST_NAMES.pick_random())

	var first_name := document_name.get_slice(" ", 0)
	document_name = "%s %s" % [first_name, new_last_name]
	name_label.text = document_name

func make_permit_wrong() -> void:
	var max_duration: int = MAX_PERMIT_DURATION_YEARS[document_race]
	var wrong_duration := max_duration + randi_range(1, 5)

	permit_expiry_year = permit_issue_year + wrong_duration
	permit_expiry_label.text = str(permit_expiry_year)

func make_specialty_wrong() -> void:
	var other_workspaces: Array[String] = []

	for workspace in WORKSPACES.keys():
		if str(workspace) != document_workspace:
			other_workspaces.append(str(workspace))

	var wrong_workspace: String = other_workspaces.pick_random()
	var specialties: Array = WORKSPACES[wrong_workspace]
	document_specialty = str(specialties.pick_random())

	while document_specialty in WORKSPACES[document_workspace]:
		wrong_workspace = other_workspaces.pick_random()
		specialties = WORKSPACES[wrong_workspace]
		document_specialty = str(specialties.pick_random())

	specialty_label.text = document_specialty

func make_temperature_wrong() -> void:
	var limits: Dictionary = BODY_TEMP_RANGES_CELSIUS[document_race]
	var minimum: float = float(limits["min"])
	var maximum: float = float(limits["max"])

	if randi() % 2 == 0:
		body_temperature = minimum - randf_range(1.0, 10.0)
	else:
		body_temperature = maximum + randf_range(1.0, 10.0)

	body_temp_label.text = "%.1f °C" % body_temperature

# -------------------------------------------------------------------------
# VALIDATION
# -------------------------------------------------------------------------

func validate_document() -> Array[String]:
	var discrepancies: Array[String] = []

	if not check_age():
		discrepancies.append("AGE")
	if not check_sector_restriction():
		discrepancies.append("SECTOR")
	if not check_clearance():
		discrepancies.append("CLEARANCE")
	if not check_name_sector():
		discrepancies.append("NAME / SECTOR")
	if not check_permit_duration():
		discrepancies.append("PERMIT DURATION")
	if not check_specialty():
		discrepancies.append("SPECIALTY")
	if not check_workspace_specialty():
		discrepancies.append("WORKSPACE / SPECIALTY")
	if not check_body_temperature():
		discrepancies.append("BODY TEMPERATURE")

	return discrepancies

func check_age() -> bool:
	if not RACE_AGE_LIMITS.has(document_race):
		return false
	var limits: Dictionary = RACE_AGE_LIMITS[document_race]
	return document_age >= int(limits["min"]) and document_age <= int(limits["max"])

func check_sector_restriction() -> bool:
	if not RESTRICTED_SECTORS_PER_RACE.has(document_race):
		return false
	var restricted: Array = RESTRICTED_SECTORS_PER_RACE[document_race]
	return document_sector not in restricted

func check_clearance() -> bool:
	if not WORKPLACE_CLEARANCE_LEVELS.has(document_workspace):
		return false
	var required: int = int(WORKPLACE_CLEARANCE_LEVELS[document_workspace])
	return security_clearance >= required

func check_name_sector() -> bool:
	var parts := document_name.split(" ")
	if parts.size() < 2:
		return false

	var last_name: String = parts[parts.size() - 1]
	var initial := last_name.substr(0, 1).to_upper()
	var allowed_sectors: Array = []

	if initial >= "A" and initial <= "G":
		allowed_sectors = NAME_SECTOR_RULES["A-G"]
	elif initial >= "H" and initial <= "N":
		allowed_sectors = NAME_SECTOR_RULES["H-N"]
	elif initial >= "O" and initial <= "Z":
		allowed_sectors = NAME_SECTOR_RULES["O-Z"]
	else:
		return false

	return document_sector in allowed_sectors

func check_permit_duration() -> bool:
	if not MAX_PERMIT_DURATION_YEARS.has(document_race):
		return false
	var max_duration: int = int(MAX_PERMIT_DURATION_YEARS[document_race])
	var duration := permit_expiry_year - permit_issue_year
	return duration >= 0 and duration <= max_duration

func check_specialty() -> bool:
	if not RESTRICTED_SPECIALTIES_PER_RACE.has(document_race):
		return false
	var restricted: Array = RESTRICTED_SPECIALTIES_PER_RACE[document_race]
	return document_specialty not in restricted

func check_workspace_specialty() -> bool:
	if not WORKSPACES.has(document_workspace):
		return false
	return document_specialty in WORKSPACES[document_workspace]

func check_body_temperature() -> bool:
	if not BODY_TEMP_RANGES_CELSIUS.has(document_race):
		return false
	var limits: Dictionary = BODY_TEMP_RANGES_CELSIUS[document_race]
	var minimum: float = float(limits["min"])
	var maximum: float = float(limits["max"])
	return body_temperature >= minimum and body_temperature <= maximum

# -------------------------------------------------------------------------
# ANIMATION & DRAGGING
# -------------------------------------------------------------------------

func slide_to(target: Vector2) -> void:
	if tween and tween.is_valid():
		tween.kill()

	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target, SLIDE_TIME)

func sheet_rect() -> Rect2:
	var size := sheet.texture.get_size() * sheet.scale * global_scale
	return Rect2(
		to_global(sheet.position) - size * 0.5,
		size
	)

func event_world_pos(event: InputEventMouse) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * event.position

func customer_rect() -> Rect2:
	var customer := get_tree().get_first_node_in_group("customer")
	if customer == null or not (customer is Node2D):
		return Rect2()

	var n := customer as Node2D
	var size := n.get("body_size") if "body_size" in n else Vector2(40, 60)
	return Rect2(
		n.global_position - size * 0.5,
		size
	)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var at := event_world_pos(event)

		if event.pressed and sheet_rect().has_point(at):
			dragging = true
			_drag_start_pos = global_position
			drag_offset = global_position - at

			if tween and tween.is_valid():
				tween.kill()

			get_viewport().set_input_as_handled()

		elif not event.pressed and dragging:
			dragging = false
			var drop_at := event_world_pos(event)

			if customer_rect().has_point(drop_at):
				hand_to_customer()

			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and dragging:
		global_position = event_world_pos(event) + drag_offset

# -------------------------------------------------------------------------
# STAMPING & LOGGING DATA
# -------------------------------------------------------------------------

func _reset_stamp_visibilities() -> void:
	mark.modulate.a = 0.0

func apply_stamp(color: Color, accepted: bool) -> void:
	if is_stamped:
		return

	is_stamped = true

	# Restore color assignment
	mark.modulate = color
	mark.modulate.a = 1.0

	if accepted:
		stamp_decision = "approved"
	else:
		stamp_decision = "disapproved"

	print(
		"[DOCUMENT] Stamped. accepted=",
		accepted,
		" color=",
		color
	)
func hand_to_customer() -> void:
	dragging = false

	# Save document entry into master tracking array
	save_document_to_history()

	if tween and tween.is_valid():
		tween.kill()

	position = HIDDEN_POS
	visible = false

	Global.next_customer_requested.emit()

func save_document_to_history() -> void:
	var entry: Dictionary = {
		"id": document_id,
		"name": document_name,
		"age": document_age,
		"race": document_race,
		"workspace": document_workspace,
		"specialty": document_specialty,
		"sector": document_sector,
		"clearance": security_clearance,
		"date_expiry": str(permit_expiry_year),
		"temp": body_temperature,
		"is_correct": not has_discrepancy,
		"status": stamp_decision
	}

	daily_documents.append(entry)
	
	print("--- NEW ENTRY LOGGED ---")
	print(entry)
	print("------------------------")
