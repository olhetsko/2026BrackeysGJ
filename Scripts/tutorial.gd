extends Control

# Coach overlay.
#
# Day 1 teaches the controls by doing: each step names one action and waits for
# the player to actually perform it, watching the same signals the game already
# emits. Every later day that brings a rule into force opens with a one-page
# briefing on that rule, read straight from document.gd's RULE_STAGES so the
# briefing can never describe something the game is not enforcing yet.
#
# It never blocks input, and a pulsing box marks whatever you need to look at.
# Steps with no natural trigger show a button instead. Skip dismisses it.

const HIGHLIGHT_COLOR := Color(1.0, 0.82, 0.3)
const HIGHLIGHT_WIDTH := 3.0
const PULSE_SPEED := 3.5
## Breathing room between what is highlighted and the box around it.
const HIGHLIGHT_PADDING := 10.0

const DocumentScript = preload("res://Scripts/document.gd")

# target  - node in Game.tscn to ring with the highlight box, "" for none
# signal  - Global signal that means "they did it"; advances the step
# button  - label for a manual advance button; can sit alongside a signal as a
#           way out when the action is not available yet
const FIRST_DAY_STEPS: Array[Dictionary] = [
	{
		"text": "You work the night window. Applicants come to you for a permit, and you decide who gets one.\n\nRing the [b]bell[/b] to call the first one.",
		"target": "Bell",
		"signal": "customer_arrived",
	},
	{
		"text": "They appear in the [b]window[/b].\n\nWhat they are matters - every species has its own limits, and their face is your first clue.",
		"target": "People",
		"button": "NEXT",
	},
	{
		"text": "Their [b]ID card[/b] slides onto your desk.\n\nIt lists everything the paperwork claims about them.",
		"target": "Document",
		"button": "NEXT",
	},
	{
		"text": "The [b]rulebook[/b] holds the rules in force today.\n\nDrag it to move it, and use [b]<[/b] and [b]>[/b] to turn the pages.",
		"target": "RuleBook",
		"signal": "rulebook_page_turned",
		# Early days have only one page, so there may be nothing to turn.
		"button": "NEXT",
	},
	{
		"text": "Your job is to compare the two.\n\nIf every field on the card obeys the book, approve them. If even one breaks a rule, turn them away.",
		"target": "Document",
		"button": "NEXT",
	},
	{
		"text": "Two stamps sit on the desk. [b]Green approves[/b], [b]red denies[/b].\n\n[b]Left-click and hold[/b] one to pick it up, and drag it over the card.",
		"target": "Stamp",
		"button": "NEXT",
	},
	{
		"text": "While you are holding a stamp over the card, press [b]RIGHT-CLICK[/b] to stamp it.\n\nTry it now - either colour will do.",
		"target": "Stamp",
		"signal": "document_stamped",
	},
	{
		"text": "Stamped. Now give it back: [b]drag the card onto the applicant[/b].",
		"target": "People",
		"signal": "document_processed",
	},
	{
		"text": "That is the whole job.\n\nServe everyone who comes, then press [b]Next Day[/b]. Anything you got wrong is explained at the end of the day - and tomorrow brings a new rule.",
		"target": "",
		"button": "START",
	},
]

@onready var panel: ColorRect = $Panel
@onready var step_text: RichTextLabel = $Panel/StepText
@onready var step_index: Label = $Panel/StepIndex
@onready var action_button: Button = $Panel/ActionButton
@onready var skip_button: Button = $Panel/SkipButton

## Day 1 runs the controls tutorial; later days run a one-page briefing on
## whatever rule just came into force.
var steps: Array[Dictionary] = []
var current_step: int = 0
var _watching: String = ""


func _ready() -> void:
	steps = steps_for_today()
	if steps.is_empty():
		queue_free()
		return

	action_button.pressed.connect(_on_action_pressed)
	skip_button.pressed.connect(finish)
	show_step(0)


# Day 1: how to play, unless it has already been seen. Any later day that turns
# a new rule on: what that rule is. Days that add nothing: nothing.
func steps_for_today() -> Array[Dictionary]:
	if Global.current_day <= 1:
		return [] if Global.tutorial_done else FIRST_DAY_STEPS.duplicate()

	var stage := new_stage_today()
	if stage.is_empty():
		return []

	var briefing: Array[Dictionary] = []

	# One slide per idea. When the card gains a field, show that first against
	# the card itself, then the rule against the book - the two things the
	# player has to connect.
	var new_fields := str(stage.get("card", ""))
	if not new_fields.is_empty():
		briefing.append({
			"text": "[b]DAY %d[/b]\n\nThe ID card now also shows [b]%s[/b]." % [
				Global.current_day, new_fields,
			],
			"target": "Document",
			"button": "NEXT",
		})

	briefing.append({
		"text": "[b]NEW RULE: %s[/b]\n\n%s\n\nIt is in the rulebook from today." % [
			str(stage["book"]), str(stage.get("lesson", "")),
		],
		# The rulebook is where they will go to look it up.
		"target": "RuleBook",
		"button": "GOT IT",
	})

	return briefing


# The stage that starts being checked today, or {} on a day that adds nothing.
# Day 2 turns on stage 1, day 3 stage 2, and so on; past the end the rules stop
# arriving. Read from document.gd so the briefing can never describe a rule the
# game is not actually enforcing yet.
func new_stage_today() -> Dictionary:
	var index := Global.current_day - 1
	if index < 1 or index >= DocumentScript.RULE_STAGES.size():
		return {}
	return DocumentScript.RULE_STAGES[index]


func _process(_delta: float) -> void:
	# The highlight tracks a moving target (the card slides, the rulebook can
	# be dragged), so it is redrawn every frame rather than placed once.
	queue_redraw()


func _draw() -> void:
	var box := target_rect()
	if box.size == Vector2.ZERO:
		return
	var pulse: float = 0.55 + 0.45 * sin(Time.get_ticks_msec() / 1000.0 * PULSE_SPEED)
	draw_rect(box, Color(HIGHLIGHT_COLOR, pulse), false, HIGHLIGHT_WIDTH)


# The box to ring, in screen space. Empty when the step has no target or the
# target is not on screen yet.
func target_rect() -> Rect2:
	if current_step >= steps.size():
		return Rect2()

	var path := str(steps[current_step].get("target", ""))
	if path.is_empty():
		return Rect2()

	var scene := get_tree().current_scene
	if scene == null:
		return Rect2()

	var node := scene.get_node_or_null(path)
	if node == null or (node is CanvasItem and not node.is_visible_in_tree()):
		return Rect2()

	var box := screen_bounds(node)
	if box.size == Vector2.ZERO:
		return Rect2()
	return box.grow(HIGHLIGHT_PADDING)


# What a node actually covers on screen: the union of every visible piece it
# draws. Measured rather than guessed from the node's origin, which is what
# used to leave the boxes sitting off to one side of their target.
func screen_bounds(root: Node) -> Rect2:
	var bounds := Rect2()
	var found := false

	for item in visible_items(root):
		var local := local_rect(item)
		if local.size.x <= 0.0 or local.size.y <= 0.0:
			continue
		var piece := transformed_rect(item.get_global_transform_with_canvas(), local)
		if found:
			bounds = bounds.merge(piece)
		else:
			bounds = piece
			found = true

	return bounds if found else Rect2()


func visible_items(node: Node) -> Array[CanvasItem]:
	var found: Array[CanvasItem] = []
	if node is CanvasItem:
		if not (node as CanvasItem).visible:
			return found
		found.append(node)
	for child in node.get_children():
		found.append_array(visible_items(child))
	return found


# The area a single item draws, in its own space. Anything without a natural
# rect (Area2D, plain Node2D) contributes nothing.
func local_rect(item: CanvasItem) -> Rect2:
	if item is Sprite2D:
		return (item as Sprite2D).get_rect()
	if item is Control:
		return Rect2(Vector2.ZERO, (item as Control).size)
	return Rect2()


func transformed_rect(xform: Transform2D, rect: Rect2) -> Rect2:
	var a := xform * rect.position
	var out := Rect2(a, Vector2.ZERO)
	out = out.expand(xform * Vector2(rect.end.x, rect.position.y))
	out = out.expand(xform * rect.end)
	out = out.expand(xform * Vector2(rect.position.x, rect.end.y))
	return out


# --- steps ----------------------------------------------------------------

func show_step(index: int) -> void:
	stop_watching()

	if index >= steps.size():
		finish()
		return

	current_step = index
	var step := steps[index]

	step_text.text = str(step.get("text", ""))
	# A one-page briefing has no sequence worth counting.
	step_index.visible = steps.size() > 1
	step_index.text = "%d / %d" % [index + 1, steps.size()]

	var button_label := str(step.get("button", ""))
	action_button.visible = not button_label.is_empty()
	action_button.text = button_label

	var watch := str(step.get("signal", ""))
	if not watch.is_empty():
		Global.connect(watch, _on_step_completed)
		_watching = watch


func stop_watching() -> void:
	if _watching != "" and Global.is_connected(_watching, _on_step_completed):
		Global.disconnect(_watching, _on_step_completed)
	_watching = ""


func _on_step_completed() -> void:
	# Stop listening straight away: a step can have both a signal and a button,
	# and either one firing must advance exactly once.
	var next := current_step + 1
	stop_watching()
	# Deferred so the action that triggered this finishes before the panel
	# changes under the player.
	show_step.call_deferred(next)


func _on_action_pressed() -> void:
	var next := current_step + 1
	stop_watching()
	show_step(next)


func finish() -> void:
	stop_watching()
	Global.tutorial_done = true
	queue_free()
