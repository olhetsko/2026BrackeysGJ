extends Node2D

# The paper the customer hands over. Rolls a random person and writes each
# field straight into its Label. Slides in when they reach the counter and
# slides back out when the bell calls the next one.

const HIDDEN_POS := Vector2(-107.0, -22.0)
const SHOWN_POS := Vector2(-30.0, 34.0)
const SLIDE_TIME := 0.45

const AGE_MIN := 20
const AGE_MAX := 200

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

# TODO: drop your own races in here. Any number of entries works.
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

# Ten sectors, A through J.
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

@onready var sheet: Sprite2D = $Sprite2D
@onready var name_label: Label = $"Fields/NameValue"
@onready var age_label: Label = $"Fields/AgeValue"
@onready var race_label: Label = $"Fields/RaceValue"
@onready var workspace_label: Label = $"Fields/WorkspaceValue"
@onready var specialty_label: Label = $"Fields/SpecialtyValue"
@onready var sector_label: Label = $"Fields/SectorValue"
@onready var online_label: Label = $"Fields/OnlineValue"
@onready var mark: ColorRect = $Mark

var tween: Tween
var dragging := false
var drag_offset := Vector2.ZERO


func _ready() -> void:
	position = HIDDEN_POS
	visible = false
	mark.visible = false
	# The stamps find the document through this group, so neither has to know
	# where the other sits in the scene.
	add_to_group("document")
	Global.customer_arrived.connect(on_customer_arrived)
	Global.next_customer_requested.connect(on_next_customer_requested)


func on_customer_arrived() -> void:
	roll_person()
	slide_to(SHOWN_POS)

func on_next_customer_requested() -> void:
	leave()


# Send the sheet away and hide it once it is off the counter, so nothing shows
# while we wait. If a customer arrives mid-slide, slide_to kills this tween and
# finished never fires, so roll_person's visible = true is not undone after.
func leave() -> void:
	dragging = false
	slide_to(HIDDEN_POS)
	tween.finished.connect(func() -> void: visible = false)


func roll_person() -> void:
	visible = true
	# A fresh person means a fresh, unstamped sheet.
	mark.visible = false
	name_label.text = "%s %s" % [FIRST_NAMES.pick_random(), LAST_NAMES.pick_random()]
	age_label.text = str(randi_range(AGE_MIN, AGE_MAX))
	race_label.text = RACES.pick_random()

	var workspace := str(WORKSPACES.keys().pick_random())
	workspace_label.text = workspace
	specialty_label.text = str(WORKSPACES[workspace].pick_random())

	sector_label.text = SECTORS.pick_random()
	online_label.text = "Y" if randi() % 2 == 0 else "N"


func slide_to(target: Vector2) -> void:
	if tween and tween.is_valid():
		tween.kill()
	tween = create_tween()
	tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "position", target, SLIDE_TIME)


# Stamp the sheet at a global point, in the stamp's own colour. The mark is a
# child of this scene, so it travels with the paper when it slides or is
# dragged, and it is cleared again by the next customer.
func place_mark(at_global: Vector2, color: Color) -> void:
	mark.color = Color(color.r, color.g, color.b, 0.85)
	mark.position = to_local(at_global) - mark.size * 0.5
	mark.visible = true


# --- dragging -------------------------------------------------------------

# The paper's rect in global space. Uses global_scale so it stays correct
# whatever scale the Document is instanced at.
func sheet_rect() -> Rect2:
	var size := sheet.texture.get_size() * sheet.scale * global_scale
	return Rect2(to_global(sheet.position) - size * 0.5, size)


# Where this mouse event landed, in world space. Taken from the event itself
# rather than the live cursor, so it stays correct if events are queued.
func event_world_pos(event: InputEventMouse) -> Vector2:
	return get_viewport().get_canvas_transform().affine_inverse() * event.position


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var at := event_world_pos(event)
		if event.pressed and sheet_rect().has_point(at):
			dragging = true
			# Grab it where it was clicked so it does not jump to the cursor.
			drag_offset = global_position - at
			# Let go of any slide in progress, otherwise the tween keeps
			# writing position and fights the mouse.
			if tween and tween.is_valid():
				tween.kill()
			get_viewport().set_input_as_handled()
		elif not event.pressed and dragging:
			dragging = false
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and dragging:
		global_position = event_world_pos(event) + drag_offset

	elif event is InputEventKey and event.keycode == KEY_SPACE:
		# Space always sends the sheet away, stamped or not, over it or not.
		# The stamps sit later in the tree so they get this event first and any
		# mark is already on the paper by the time it leaves.
		if event.pressed and not event.echo:
			leave()
			get_viewport().set_input_as_handled()
