extends Node2D

# The paper the customer hands over. Rolls a random person and writes each
# field straight into its Label. Slides in when they reach the counter and
# slides back out when the bell calls the next one.
#
# Save/Stamping: pressing the stamp (over the paper) calls apply_stamp(ink),
# which sets is_stamped = true and shows the colored stamp in the slot at the
# bottom of the paper. Stamping never removes the document.
#
# Delivery: dropping the document on the customer (People node) hands it over.
# Stamped -> normal delivery. Unstamped -> still delivered, but is_stamped is
# false so other code can branch on that.

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
@onready var accept_slot: ColorRect = $Stamps/AcceptSlot
@onready var decline_slot: ColorRect = $Stamps/DeclineSlot
@onready var accept_label: Label = $Stamps/AcceptLabel
@onready var decline_label: Label = $Stamps/DeclineLabel

var tween: Tween
var dragging := false
var drag_offset := Vector2.ZERO

# Stamped state. False from the moment a new person is rolled, true the moment
# a stamp lands. The delivery path on mouse-up branches on this.
var is_stamped := false

# Where the document was when the player grabbed it, so dropping it without
# aiming at the customer just leaves it where they let go, not at the counter.
var _drag_start_pos := Vector2.ZERO


func _ready() -> void:
	position = HIDDEN_POS
	visible = false
	mark.visible = false
	# Both slots start uncolored. The matching stamp fills one of them; the
	# other stays paper-coloured.
	accept_slot.color = slot_unfilled_color()
	decline_slot.color = slot_unfilled_color()
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
	is_stamped = false
	mark.visible = false
	# Reset both slots to the paper colour so a previous green/red stamp
	# doesn't bleed into the next customer's paperwork.
	accept_slot.color = slot_unfilled_color()
	decline_slot.color = slot_unfilled_color()
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


# Called by stamp.gd when the player presses the stamp over the paper. The
# color and which slot to fill come from the stamp, so the document never
# invents its own palette or routing. Stamping only mutates state and
# visuals; it never removes the document.
#
# Contract: this function is the *only* thing Space does. It must NEVER call
# leave(), hand_to_customer(), Global.next_customer_requested.emit(), or move
# the document off the desk. is_stamped is just a piece of state; it is not
# an instruction to deliver.
func apply_stamp(color: Color, accept: bool) -> void:
	if is_stamped:
		return
	is_stamped = true
	# Fill the matching slot in the stamp's colour. The Mark ColorRect is
	# reparented visually by resizing it to the slot and snapping its top-left
	# to the slot's top-left, so it reads as "this stamp landed here".
	var slot: ColorRect = accept_slot if accept else decline_slot
	mark.color = Color(color.r, color.g, color.b, 0.85)
	mark.size = slot.size
	mark.position = slot.position
	mark.visible = true


# Paper-coloured backdrop for an unfilled stamp slot. Lives in one place so
# the onready reset and the per-person reset can't drift apart.
func slot_unfilled_color() -> Color:
	return Color(0.92, 0.92, 0.86, 1)


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


# The People node's rect in world space. Found by group so the document
# doesn't care where the customer sits in the scene.
func customer_rect() -> Rect2:
	var customer := get_tree().get_first_node_in_group("customer")
	if customer == null or not (customer is Node2D):
		return Rect2()
	var n := customer as Node2D
	var size := n.get("body_size") if "body_size" in n else Vector2(40, 60)
	return Rect2(n.global_position - size * 0.5, size)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		var at := event_world_pos(event)
		if event.pressed and sheet_rect().has_point(at):
			dragging = true
			# Remember where the paper sat so a drop on the customer hands over
			# the document, while a drop anywhere else leaves it where it lies.
			_drag_start_pos = global_position
			# Grab it where it was clicked so it does not jump to the cursor.
			drag_offset = global_position - at
			# Let go of any slide in progress, otherwise the tween keeps
			# writing position and fights the mouse.
			if tween and tween.is_valid():
				tween.kill()
			get_viewport().set_input_as_handled()
		elif not event.pressed and dragging:
			dragging = false
			var drop_at := event_world_pos(event)
			# Dropped on the customer: hand the document over. Stamped or not,
			# the document leaves the desk; the is_stamped flag stays so the
			# caller can branch on the result.
			if customer_rect().has_point(drop_at):
				hand_to_customer()
			get_viewport().set_input_as_handled()

	elif event is InputEventMouseMotion and dragging:
		global_position = event_world_pos(event) + drag_offset


# Called when the player drops the document on the customer. The document
# leaves the desk and the queue advances: People starts walking the next
# customer in. Whatever consumes the delivery (e.g. People) can read
# is_stamped to decide what to do with the paperwork.
func hand_to_customer() -> void:
	# Delivery is instant: the document vanishes the moment the player lets
	# go over the customer. No slide-back, no animation - just hide it in
	# place. We kill any in-flight tween so it can't keep writing position
	# while we're trying to vanish, then park it at the hidden slot so the
	# next roll_person doesn't have to chase it.
	dragging = false
	if tween and tween.is_valid():
		tween.kill()
	position = HIDDEN_POS
	visible = false
	# Hand the queue over. The bell normally fires this when a new customer is
	# requested, but delivery is the other path that consumes a slot, so it
	# has to emit it too or the current customer just sits there forever.
	Global.next_customer_requested.emit()
