extends Node2D

# -------------------------------------------------------------------------
# DOCUMENT POSITIONS / ANIMATION
# -------------------------------------------------------------------------

# Fallbacks only. The resting place is taken from wherever the Document node is
# placed in the editor, and the hidden place is wherever the applicant is, so
# the sheet slides out of them wherever the window happens to be.
const HIDDEN_POS := Vector2(0.0, -22.0)
const SHOWN_POS := Vector2(0.0, 34.0)
const SLIDE_TIME := 0.45

## How often a sheet is sabotaged. Half makes checking worth doing and both
## stamps worth pressing; the roll is per document, so runs of either happen.
const FLAW_CHANCE := 0.5

# -------------------------------------------------------------------------
# SCORING
# -------------------------------------------------------------------------

# What each call is worth at the end of the day. Letting someone through is
# the heavier decision in both directions - it pays the most when the sheet
# really was clean, and costs the most when it was not.
const SCORE_APPROVED_RIGHT := 4
const SCORE_APPROVED_WRONG := -4
const SCORE_REFUSED_RIGHT := 2
const SCORE_REFUSED_WRONG := -2


## Points for one logged decision. Only handed-back documents are logged, so
## an applicant sent away un-served scores nothing either way.
static func score_for(entry: Dictionary) -> int:
	var approved: bool = entry.get("status", "") == "approved"
	var document_valid: bool = bool(entry.get("is_correct", true))
	var judged_right: bool = approved == document_valid

	if approved:
		return SCORE_APPROVED_RIGHT if judged_right else SCORE_APPROVED_WRONG
	return SCORE_REFUSED_RIGHT if judged_right else SCORE_REFUSED_WRONG


## The whole day's points.
static func score_for_day(entries: Array) -> int:
	var total := 0
	for entry in entries:
		total += score_for(entry)
	return total

# -------------------------------------------------------------------------
# DAILY TRACKING DATA
# -------------------------------------------------------------------------

# Numbers the documents within a day. Reset in _ready, which runs once per
# Game.tscn load - that is once per day, since the end-of-day screen reloads
# the scene. The entries themselves live on Global.daily_documents.
static var current_day_id: int = 1

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

# Each name here must match a Node2D under People/Races in people.tscn - that
# is the sprite group the applicant walks in wearing. Adding a race means
# adding its group there and a row in every table below.
const RACES: Array[String] = [
	"Zombie",
	"Frankenstein",
	"Mummy",
	"Dragon",
	"Ghost",
	"Potato",
	"Clown",
	"Goblin",
	"Eyeball",
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
	"Mummy": {"min": 100, "max": 4000},
	"Dragon": {"min": 100, "max": 5000},
	"Ghost": {"min": 50, "max": 10000},
	"Potato": {"min": 1, "max": 3},
	"Clown": {"min": 18, "max": 90},
	"Goblin": {"min": 15, "max": 200},
	"Eyeball": {"min": 5, "max": 60},
}

const RESTRICTED_SECTORS_PER_RACE := {
	"Zombie": ["J"],
	"Frankenstein": [],
	"Mummy": [],
	"Dragon": ["A", "B", "C"],
	"Ghost": ["E"],
	"Potato": [],
	"Clown": ["E"],
	"Goblin": ["J"],
	"Eyeball": ["H"],
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
	"Mummy": 20,
	"Dragon": 20,
	"Ghost": 20,
	"Potato": 2,
	"Clown": 5,
	"Goblin": 5,
	"Eyeball": 5,
}

const RESTRICTED_SPECIALTIES_PER_RACE := {
	"Zombie": ["Translation", "Broadcasting", "Speech"],
	"Frankenstein": [],
	"Mummy": [],
	"Dragon": [],
	"Ghost": ["Firefighting"],
	"Potato": ["Firefighting"],
	"Clown": ["Surgeon", "Investigator"],
	"Goblin": ["Finance", "Records"],
	"Eyeball": ["Piloting", "Assembly"],
}

const BODY_TEMP_RANGES_CELSIUS := {
	"Zombie": {"min": 0.0, "max": 10.0},
	"Frankenstein": {"min": 30.0, "max": 35.0},
	"Mummy": {"min": 5.0, "max": 15.0},
	"Dragon": {"min": 80.0, "max": 200.0},
	"Ghost": {"min": -20.0, "max": 10.0},
	"Potato": {"min": 4.0, "max": 12.0},
	"Clown": {"min": 36.0, "max": 38.0},
	"Goblin": {"min": 33.0, "max": 37.0},
	"Eyeball": {"min": 20.0, "max": 30.0},
}

# -------------------------------------------------------------------------
# DAY-BY-DAY RULE ROLLOUT
# -------------------------------------------------------------------------

# Day 1 runs the first stage only; each following day adds the next one, and
# past the end everything is in play. This single list decides which fields
# the card shows, which checks run, which mistakes can be injected, and which
# rulebook pages exist - so the card can never carry a field the player has no
# rule for, and the rulebook can never be missing a rule that is being tested.
#
# check  - the validate_document() code this stage turns on
# fields - FIELD_NODES keys the card starts showing
# book   - rulebook pages whose header starts with this become available
const RULE_STAGES: Array[Dictionary] = [
	{
		"check": "AGE",
		"fields": ["name", "race", "age"],
		"book": "AGE LIMITS",
		"card": "NAME, RACE and AGE",
		"lesson": "Check the [b]AGE[/b] against the applicant's race. Every race has its own range.",
	},
	{
		"check": "WORKSPACE / SPECIALTY",
		"fields": ["workspace", "specialty"],
		"book": "WORKSPACES",
		"card": "WORKSPACE and SPECIALTY",
		"lesson": "Cards now carry a [b]WORKSPACE[/b] and a [b]SPECIALTY[/b]. The specialty must be a job that workspace actually offers.",
	},
	{
		"check": "SECTOR",
		"fields": ["sector"],
		"book": "RESTRICTED SECTORS",
		"card": "SECTOR",
		"lesson": "Cards now carry a [b]SECTOR[/b]. Some races are barred from certain sectors outright.",
	},
	{
		"check": "NAME / SECTOR",
		"fields": [],
		"book": "NAME -> SECTOR",
		"card": "",
		"lesson": "A surname's first letter decides which sectors it opens - A-G, H-N and O-Z each allow different ones. The sector on the card must be one of them.",
	},
	{
		"check": "CLEARANCE",
		"fields": ["clearance"],
		"book": "CLEARANCE",
		"card": "CLEARANCE",
		"lesson": "Cards now carry a [b]CLEARANCE[/b] level. It has to meet or beat what their workspace demands.",
	},
	{
		"check": "PERMIT DURATION",
		"fields": ["permit"],
		"book": "PERMIT DURATION",
		"card": "PERMIT DATE and EXPIRY",
		"lesson": "Cards now carry [b]PERMIT[/b] dates. A permit may not run longer than that race's limit, and may not expire before it was issued.",
	},
	{
		"check": "BODY TEMPERATURE",
		"fields": ["temp"],
		"book": "BODY TEMP",
		"card": "TEMP",
		"lesson": "Cards now carry a [b]TEMP[/b]. Each race runs at its own temperature - a warm ghost is a forgery.",
	},
	{
		"check": "SPECIALTY",
		"fields": [],
		"book": "SPECIALTY BANS",
		"card": "",
		"lesson": "Some races are banned from particular jobs even where the workspace offers them. Check the specialty against the race.",
	},
]

# Which nodes under Fields make up each row of the card.
const FIELD_NODES := {
	"name": ["NameCaption", "NameValue"],
	"age": ["AgeCaption", "AgeValue"],
	"race": ["RaceCaption", "RaceValue"],
	"workspace": ["WorkspaceCaption", "WorkspaceValue"],
	"specialty": ["SpecialtyCaption", "SpecialtyValue"],
	"sector": ["SectorCaption", "SectorValue"],
	"clearance": ["ClearanceCaption", "ClearanceValue"],
	"permit": [
		"PermitIssueCaption", "PermitIssueValue",
		"PermitExpieryCaption", "PermitExpiryValue",
	],
	"temp": ["BodyTempCaption", "BodyTempValue"],
}


## How many stages are live on a given day.
static func stages_unlocked(day: int) -> int:
	return clampi(day, 1, RULE_STAGES.size())


static func active_checks(day: int) -> Array[String]:
	var out: Array[String] = []
	for i in stages_unlocked(day):
		out.append(str(RULE_STAGES[i]["check"]))
	return out


static func active_fields(day: int) -> Array[String]:
	var out: Array[String] = []
	for i in stages_unlocked(day):
		for field in RULE_STAGES[i]["fields"]:
			out.append(str(field))
	return out


static func active_book_tags(day: int) -> Array[String]:
	var out: Array[String] = []
	for i in stages_unlocked(day):
		out.append(str(RULE_STAGES[i]["book"]))
	return out


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
# No OnlineValue label in the scene any more - the ONLINE row was replaced by
# CLEARANCE / PERMIT / TEMP. document_online is still rolled below, so add the
# @onready back here if you put the field on the card again.

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

var document_name: String = ""
var document_age: int = 0
var document_race: String = ""
var document_workspace: String = ""
var document_specialty: String = ""
var document_sector: String = ""

var security_clearance: int = 0
var permit_issue_year: int = 0
var permit_expiry_year: int = 0
var body_temperature: float = 0.0

# -------------------------------------------------------------------------
# READY
# -------------------------------------------------------------------------

## Where the card comes to rest, taken from where the node was placed in the
## editor rather than a constant, so moving it in the scene actually moves it.
var shown_position := SHOWN_POS


func _ready() -> void:
	shown_position = position
	position = hidden_position()
	visible = false
	clear_mark()

	# A fresh Game.tscn means a fresh day, so numbering restarts at 1.
	current_day_id = 1

	add_to_group("document")

	Global.customer_arrived.connect(on_customer_arrived)
	Global.next_customer_requested.connect(on_next_customer_requested)

# -------------------------------------------------------------------------
# CUSTOMER / DOCUMENT FLOW
# -------------------------------------------------------------------------

# Only People emits customer_arrived, and only once they reach the counter, so
# the sheet is rolled exactly once per customer and slides in as they arrive.
func on_customer_arrived() -> void:
	roll_person()
	# Start on the applicant so the sheet reads as coming out of them, then
	# travel down to the counter.
	position = hidden_position()
	slide_to(shown_position)
	# The paper changes hands in both directions, so it is heard both times.
	Audio.play("paperpass", 0.04)


# Ringing for the next applicant sends the current one away, and their card
# goes with them. Leaving it on the counter stranded a sheet belonging to
# nobody, which the next arrival would then overwrite mid-inspection.
#
# Nothing is logged: they were never served, so they do not count toward the
# quota and cannot be scored either way.
func on_next_customer_requested() -> void:
	if not visible:
		return
	abandon()


func abandon() -> void:
	dragging = false
	is_stamped = false
	stamp_decision = "unprocessed"

	if tween and tween.is_valid():
		tween.kill()

	position = hidden_position()
	visible = false
	clear_mark()


# Where the card sits when it is not on the counter: on the applicant, so it
# emerges from and returns to whoever is at the window.
func hidden_position() -> Vector2:
	var customer := get_tree().get_first_node_in_group("customer") as Node2D
	if customer == null:
		return HIDDEN_POS
	var parent := get_parent() as Node2D
	if parent == null:
		return customer.global_position
	return parent.to_local(customer.global_position)

# -------------------------------------------------------------------------
# GENERATE DOCUMENT
# -------------------------------------------------------------------------

func roll_person() -> void:
	roll_clean_person()

	if randf() < FLAW_CHANCE:
		make_one_field_wrong()

	# Ask the rule checks rather than trusting the roll, so the answer key
	# always matches what is actually printed on the card.
	var faults := validate_document()
	has_discrepancy = not faults.is_empty()
	print("[DOCUMENT #%d] %s" % [
		document_id,
		"OK" if faults.is_empty() else "faults: " + ", ".join(faults),
	])


# Builds a sheet that passes every rule. Sabotage is applied afterwards, on
# top - keeping the two apart is what makes FLAW_CHANCE mean what it says.
func roll_clean_person() -> void:
	visible = true
	is_stamped = false
	stamp_decision = "unprocessed"
	has_discrepancy = false

	document_id = current_day_id
	current_day_id += 1

	clear_mark()
	apply_day_fields()

	# Whoever walked in decides the species; the card just describes them. Falls
	# back to a roll so the document can still be generated on its own.
	#
	# Race is settled first either way: it constrains which surnames and
	# specialties can still make a legal document, and an untouched sheet must
	# always be legal, or FLAW_CHANCE would not mean what it says.
	document_race = Global.current_race
	if not document_race in RACES:
		document_race = RACES.pick_random()

	var surnames := surnames_for_race(document_race)
	document_name = "%s %s" % [
		FIRST_NAMES.pick_random(),
		surnames.pick_random(),
	]

	var age_data: Dictionary = RACE_AGE_LIMITS[document_race]
	document_age = randi_range(int(age_data["min"]), int(age_data["max"]))

	document_workspace = str(WORKSPACES.keys().pick_random())
	document_specialty = pick_specialty(document_workspace, document_race)

	document_sector = get_valid_sector_for_document()

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

# Which sectors a surname opens up. Shared by generation, sabotage and the
# rule check so all three can never disagree about the same name.
static func allowed_sectors_for_name(full_name: String) -> Array:
	var parts := full_name.split(" ")
	if parts.is_empty():
		return []

	var initial := String(parts[parts.size() - 1]).substr(0, 1).to_upper()

	if initial >= "A" and initial <= "G":
		return NAME_SECTOR_RULES["A-G"]
	if initial >= "H" and initial <= "N":
		return NAME_SECTOR_RULES["H-N"]
	if initial >= "O" and initial <= "Z":
		return NAME_SECTOR_RULES["O-Z"]
	return []


# Surnames that still leave this race somewhere legal to stand. A Troll called
# Abernathy is unplayable: A-G opens only sectors A, B and C, and Trolls are
# barred from all three, so no legal card could ever be issued to them.
static func surnames_for_race(race: String) -> Array[String]:
	var restricted: Array = RESTRICTED_SECTORS_PER_RACE.get(race, [])
	var usable: Array[String] = []

	for surname in LAST_NAMES:
		for sector in allowed_sectors_for_name("_ " + surname):
			if not sector in restricted:
				usable.append(surname)
				break

	return usable if not usable.is_empty() else LAST_NAMES


# A job this workspace offers that this race is not banned from, so a clean
# sheet never trips the specialty ban by accident.
static func pick_specialty(workspace: String, race: String) -> String:
	var banned: Array = RESTRICTED_SPECIALTIES_PER_RACE.get(race, [])
	var offered: Array = WORKSPACES[workspace]
	var usable: Array = []

	for specialty in offered:
		if not specialty in banned:
			usable.append(specialty)

	if usable.is_empty():
		return str(offered.pick_random())
	return str(usable.pick_random())


func get_valid_sector_for_document() -> String:
	var allowed_by_name := allowed_sectors_for_name(document_name)
	if allowed_by_name.is_empty():
		return "A"

	var restricted: Array = RESTRICTED_SECTORS_PER_RACE[document_race]
	var valid_sectors: Array = []

	for sector in allowed_by_name:
		if sector not in restricted:
			valid_sectors.append(sector)

	if valid_sectors.is_empty():
		return str(allowed_by_name[0])

	return str(valid_sectors.pick_random())

# Break exactly one of the rules that are actually in play today, so the
# player always has the rule and the field needed to catch it.
func make_one_field_wrong() -> void:
	var candidates := active_checks(Global.current_day)
	candidates.shuffle()

	for code in candidates:
		if break_rule(code):
			return


# Returns false when this rule cannot be broken for this document - a race with
# no banned specialties, say - so the caller can try another.
func break_rule(code: String) -> bool:
	match code:
		"AGE":
			make_age_wrong()
			return true
		"SECTOR":
			return make_sector_restricted_wrong()
		"CLEARANCE":
			make_clearance_wrong()
			return true
		"NAME / SECTOR":
			# Moves them to a sector their surname does not open.
			make_sector_wrong()
			return true
		"PERMIT DURATION":
			make_permit_wrong()
			return true
		"WORKSPACE / SPECIALTY":
			make_specialty_wrong()
			return true
		"BODY TEMPERATURE":
			make_temperature_wrong()
			return true
		"SPECIALTY":
			return make_banned_specialty_wrong()
	return false

func make_age_wrong() -> void:
	var limits: Dictionary = RACE_AGE_LIMITS[document_race]
	var minimum: int = int(limits["min"])
	var maximum: int = int(limits["max"])

	if randi() % 2 == 0:
		document_age = minimum - 1
	else:
		document_age = maximum + 1

	age_label.text = str(document_age)

# Puts the applicant in a sector their race is barred from. Not every race has
# one, so this reports whether it managed.
func make_sector_restricted_wrong() -> bool:
	var restricted: Array = RESTRICTED_SECTORS_PER_RACE.get(document_race, [])
	if restricted.is_empty():
		return false

	# Prefer a barred sector their surname still allows, so this breaks the
	# race restriction on its own instead of dragging NAME / SECTOR with it.
	var allowed := allowed_sectors_for_name(document_name)
	var clean: Array = []
	for sector in restricted:
		if sector in allowed:
			clean.append(sector)

	var pool: Array = clean if not clean.is_empty() else restricted
	document_sector = str(pool.pick_random())
	sector_label.text = document_sector
	return true


# Gives the applicant a specialty their race is banned from, moving them to a
# workspace that really offers it so only the ban is broken.
func make_banned_specialty_wrong() -> bool:
	var banned: Array = RESTRICTED_SPECIALTIES_PER_RACE.get(document_race, [])
	var options: Array[Dictionary] = []

	for specialty in banned:
		for workspace in WORKSPACES:
			if specialty in WORKSPACES[workspace]:
				options.append({"workspace": workspace, "specialty": specialty})

	if options.is_empty():
		return false

	var pick: Dictionary = options.pick_random()
	document_workspace = str(pick["workspace"])
	document_specialty = str(pick["specialty"])
	workspace_label.text = document_workspace
	specialty_label.text = document_specialty

	# Keep clearance legal for the new workspace, or two rules break at once.
	var required: int = WORKPLACE_CLEARANCE_LEVELS[document_workspace]
	security_clearance = randi_range(required, 4)
	clearance_label.text = str(security_clearance)
	return true


func make_sector_wrong() -> void:
	var allowed_by_name := allowed_sectors_for_name(document_name)
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

# Only the rules in play today count. A field the card is not even showing
# must never make a document "wrong".
func validate_document() -> Array[String]:
	var discrepancies: Array[String] = []
	var live := active_checks(Global.current_day)

	for code in live:
		if not run_check(code):
			discrepancies.append(code)

	return discrepancies


func run_check(code: String) -> bool:
	match code:
		"AGE": return check_age()
		"SECTOR": return check_sector_restriction()
		"CLEARANCE": return check_clearance()
		"NAME / SECTOR": return check_name_sector()
		"PERMIT DURATION": return check_permit_duration()
		"SPECIALTY": return check_specialty()
		"WORKSPACE / SPECIALTY": return check_workspace_specialty()
		"BODY TEMPERATURE": return check_body_temperature()
	return true

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
	var allowed_sectors := allowed_sectors_for_name(document_name)
	if allowed_sectors.is_empty():
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

# The drop area, centred on the applicant. A little wider than they are so
# handing the sheet back does not need precise aim.
const CUSTOMER_SIZE := Vector2(60, 66)

func drop_rect() -> Rect2:
	var customer := get_tree().get_first_node_in_group("customer") as Node2D
	if customer == null:
		return Rect2()
	return Rect2(customer.global_position - CUSTOMER_SIZE * 0.5, CUSTOMER_SIZE)

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var at := event_world_pos(event)

		if event.pressed and sheet_rect().has_point(at):
			dragging = true
			drag_offset = global_position - at

			if tween and tween.is_valid():
				tween.kill()

			get_viewport().set_input_as_handled()

		elif not event.pressed and dragging:
			dragging = false
			var drop_at := event_world_pos(event)

			if drop_rect().has_point(drop_at):
				hand_to_customer()

			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and dragging:
		global_position = event_world_pos(event) + drag_offset

# -------------------------------------------------------------------------
# STAMPING & LOGGING DATA
# -------------------------------------------------------------------------

# Show only the rows whose rules the player has been taught. Values behind a
# hidden row are still generated and still legal - they are simply not printed
# on the card yet.
func apply_day_fields() -> void:
	var live := active_fields(Global.current_day)
	for key in FIELD_NODES:
		var on: bool = str(key) in live
		for node_name in FIELD_NODES[key]:
			var row := $Fields.get_node_or_null(NodePath(str(node_name))) as CanvasItem
			if row != null:
				row.visible = on


func clear_mark() -> void:
	mark.modulate.a = 0.0


func apply_stamp(color: Color, accepted: bool) -> void:
	# One stamp per sheet - the first verdict sticks.
	if is_stamped:
		return

	is_stamped = true
	mark.modulate = color
	mark.modulate.a = 1.0
	stamp_decision = "approved" if accepted else "disapproved"
	Audio.play("stamp", 0.05)
	Global.document_stamped.emit()


func hand_to_customer() -> void:
	dragging = false
	save_document_to_history()

	if tween and tween.is_valid():
		tween.kill()

	position = hidden_position()
	visible = false

	Audio.play("paperpass", 0.04)
	Global.document_processed.emit()


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
		"date_issue": permit_issue_year,
		"date_expiry": permit_expiry_year,
		"temp": body_temperature,
		"is_correct": not has_discrepancy,
		"status": stamp_decision,
		# Which rules this sheet broke, so the end-of-day screen can explain
		# a mistake without re-deriving it from the values.
		"faults": validate_document(),
	}

	Global.daily_documents.append(entry)

# -------------------------------------------------------------------------
# FAULT EXPLANATIONS
# -------------------------------------------------------------------------

# Turns a saved entry's fault codes into rows for the end-of-day review:
# the document value that broke a rule, and the rule it broke, both filled in
# with this document's own numbers. Static so the summary screen can call it
# without a Document node in the tree.
static func explain_faults(entry: Dictionary) -> Array[Dictionary]:
	var rows: Array[Dictionary] = []
	var race := str(entry.get("race", ""))
	var workspace := str(entry.get("workspace", ""))

	for code in entry.get("faults", []):
		match str(code):
			"AGE":
				var limits: Dictionary = RACE_AGE_LIMITS.get(race, {})
				rows.append({
					"field": "AGE  %s" % entry.get("age", "?"),
					"rule": "%s: %s-%s yrs" % [
						race, limits.get("min", "?"), limits.get("max", "?"),
					],
				})
			"SECTOR":
				var barred: Array = RESTRICTED_SECTORS_PER_RACE.get(race, [])
				rows.append({
					"field": "SECTOR  %s" % entry.get("sector", "?"),
					"rule": "%s barred from %s" % [race, ", ".join(barred)],
				})
			"NAME / SECTOR":
				var surname := str(entry.get("name", "")).get_slice(" ", 1)
				var allowed := allowed_sectors_for_name(str(entry.get("name", "")))
				rows.append({
					"field": "SECTOR  %s" % entry.get("sector", "?"),
					"rule": "%s allows %s" % [surname, ", ".join(allowed)],
				})
			"CLEARANCE":
				rows.append({
					"field": "CLEARANCE  %s" % entry.get("clearance", "?"),
					"rule": "%s needs lvl %s" % [
						workspace, WORKPLACE_CLEARANCE_LEVELS.get(workspace, "?"),
					],
				})
			"PERMIT DURATION":
				rows.append({
					"field": "PERMIT  %s-%s" % [
						entry.get("date_issue", "?"), entry.get("date_expiry", "?"),
					],
					"rule": "%s: max %s yrs" % [
						race, MAX_PERMIT_DURATION_YEARS.get(race, "?"),
					],
				})
			"SPECIALTY":
				var banned: Array = RESTRICTED_SPECIALTIES_PER_RACE.get(race, [])
				rows.append({
					"field": "SPECIALTY  %s" % entry.get("specialty", "?"),
					"rule": "%s cannot: %s" % [race, ", ".join(banned)],
				})
			"WORKSPACE / SPECIALTY":
				rows.append({
					"field": "SPECIALTY  %s" % entry.get("specialty", "?"),
					"rule": "%s has no such role" % workspace,
				})
			"BODY TEMPERATURE":
				var range_data: Dictionary = BODY_TEMP_RANGES_CELSIUS.get(race, {})
				rows.append({
					"field": "TEMP  %.1f" % float(entry.get("temp", 0.0)),
					"rule": "%s: %s-%s C" % [
						race,
						_trim_zero(range_data.get("min", "?")),
						_trim_zero(range_data.get("max", "?")),
					],
				})
			_:
				rows.append({"field": str(code), "rule": "Broke a rule"})

	return rows


# Whole-number temperatures read better without the trailing ".0", but the
# fractional limits (Witch tops out at 37.5) have to survive.
static func _trim_zero(value: Variant) -> String:
	return str(value).trim_suffix(".0")
