extends Node2D

# A flippable reference book. Click the grey corner tabs to turn a page - the
# flip is instant, no animation. Page 0 is the front cover and the last page is
# the back cover; everything between is paper.
#
# The workspace/specialty table is read straight out of document.gd, so editing
# WORKSPACES there updates the book with no changes here.

const DocumentScript = preload("res://Scripts/document.gd")

# How many workspaces are listed on one page. Lower this if entries start
# running off the bottom of the paper.
const PER_PAGE := 3

const KIND_COVER := "cover"
const KIND_PAPER := "paper"
const KIND_BACK := "back"

const INK := "2a2119"
const HEADING_INK := "4a3524"

@onready var cover_frame: ColorRect = $CoverFrame
@onready var cover_title: Label = $CoverTitle
@onready var cover_subtitle: Label = $CoverSubtitle
@onready var back_text: Label = $BackText
@onready var paper: ColorRect = $Paper
@onready var page_heading: Label = $PageHeading
@onready var heading_index: Label = $HeadingIndex
@onready var heading_rule: ColorRect = $HeadingRule
@onready var content: RichTextLabel = $Content
@onready var page_number: Label = $PageNumber
@onready var prev_corner: ColorRect = $PrevCorner
@onready var next_corner: ColorRect = $NextCorner

var pages: Array[Dictionary] = []
var current := 0


func _ready() -> void:
	pages = build_pages()
	prev_corner.gui_input.connect(corner_input.bind(-1))
	next_corner.gui_input.connect(corner_input.bind(1))
	show_page(0)


# --- paging ---------------------------------------------------------------

func corner_input(event: InputEvent, step: int) -> void:
	if event is InputEventMouseButton \
			and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT:
		flip(step)


# Wraps at both ends, so the corner tab is never a dead click.
func flip(step: int) -> void:
	show_page(wrapi(current + step, 0, pages.size()))


func show_page(index: int) -> void:
	current = clampi(index, 0, pages.size() - 1)
	var page := pages[current]
	var kind: String = page["kind"]
	var is_paper := kind == KIND_PAPER

	# The cover boards sit behind everything and Paper is drawn over them, so
	# turning Paper off is what reveals a cover.
	paper.visible = is_paper
	page_heading.visible = is_paper
	heading_index.visible = is_paper
	heading_rule.visible = is_paper
	content.visible = is_paper
	page_number.visible = is_paper

	cover_frame.visible = not is_paper
	cover_title.visible = kind == KIND_COVER
	cover_subtitle.visible = kind == KIND_COVER
	back_text.visible = kind == KIND_BACK

	if is_paper:
		page_heading.text = page["heading"]
		heading_index.text = page["index"]
		content.text = page["body"]
		page_number.text = "%d / %d" % [current + 1, pages.size()]


# --- page contents --------------------------------------------------------

func build_pages() -> Array[Dictionary]:
	var built: Array[Dictionary] = []
	built.append({"kind": KIND_COVER})

	var names: Array = DocumentScript.WORKSPACES.keys()
	var sheets := int(ceil(names.size() / float(PER_PAGE)))
	for i in sheets:
		var chunk := names.slice(i * PER_PAGE, mini((i + 1) * PER_PAGE, names.size()))
		built.append({
			"kind": KIND_PAPER,
			"heading": "WORKSPACES",
			"index": "%d / %d" % [i + 1, sheets],
			"body": table_bbcode(chunk),
		})

	built.append({"kind": KIND_BACK})
	return built


# One workspace per block: the name, then its five specialties on a wrapped
# line beneath it.
func table_bbcode(workspace_names: Array) -> String:
	var lines: Array[String] = []
	for workspace in workspace_names:
		var specialties: Array = DocumentScript.WORKSPACES[workspace]
		lines.append("[b][color=#%s]%s[/color][/b]" % [
			HEADING_INK, str(workspace).to_upper(),
		])
		lines.append("[color=#%s]%s[/color]" % [INK, " · ".join(specialties)])
		lines.append("")
	return "\n".join(lines)
