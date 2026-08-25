extends Node2D

# A flippable note tablet. Click the grey corner tabs to turn a page - the flip
# is instant, no animation. Page 0 is the front cover and the last page is the
# back; between them is the workspace/specialty table, all on one sheet.
#
# The table is read straight out of document.gd, so editing WORKSPACES there
# updates the tablet with no changes here.

const DocumentScript = preload("res://Scripts/document.gd")

# Workspaces listed on one sheet. The default puts the whole table on a single
# page; lower it to split across several if the list ever outgrows the paper.
const PER_PAGE := 999

const KIND_COVER := "cover"
const KIND_PAPER := "paper"
const KIND_BACK := "back"

const INK := "2a2119"
const HEADING_INK := "6b4a2f"

## Faint blue ruling, drawn to line up with the text rather than guessed at.
const RULE_COLOR := Color(0.68, 0.74, 0.80, 0.75)
const RULES_BOTTOM := 160.0

@onready var paper: ColorRect = $Paper
@onready var margin_line: ColorRect = $MarginLine
@onready var rules: Node2D = $Rules
@onready var cover_title: Label = $CoverTitle
@onready var cover_subtitle: Label = $CoverSubtitle
@onready var back_text: Label = $BackText
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
	build_rules()
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

	# The cardboard backing sits behind everything and Paper is drawn over it,
	# so turning Paper off is what reveals a cover.
	paper.visible = is_paper
	margin_line.visible = is_paper
	rules.visible = is_paper
	page_heading.visible = is_paper
	heading_rule.visible = is_paper
	content.visible = is_paper
	# Only worth showing which sheet you are on when there is more than one.
	heading_index.visible = is_paper and page["sheets"] > 1
	page_number.visible = is_paper

	cover_title.visible = kind == KIND_COVER
	cover_subtitle.visible = kind == KIND_COVER
	back_text.visible = kind == KIND_BACK

	if is_paper:
		page_heading.text = page["heading"]
		heading_index.text = page["index"]
		content.text = page["body"]
		page_number.text = "%d / %d" % [current + 1, pages.size()]


func build_pages() -> Array[Dictionary]:
	var built: Array[Dictionary] = []
	built.append({"kind": KIND_COVER})

	var names: Array = DocumentScript.WORKSPACES.keys()
	var sheets := maxi(1, int(ceil(names.size() / float(PER_PAGE))))
	for i in sheets:
		var chunk := names.slice(i * PER_PAGE, mini((i + 1) * PER_PAGE, names.size()))
		built.append({
			"kind": KIND_PAPER,
			"heading": "WORKSPACES",
			"sheets": sheets,
			"index": "%d / %d" % [i + 1, sheets],
			"body": table_bbcode(chunk),
		})

	built.append({"kind": KIND_BACK})
	return built


# One row per workspace: the name, then its specialties on the same line so the
# whole table fits a single sheet.
func table_bbcode(workspace_names: Array) -> String:
	var lines: Array[String] = []
	for workspace in workspace_names:
		var specialties: Array = DocumentScript.WORKSPACES[workspace]
		lines.append("[b][color=#%s]%s[/color][/b]  [color=#%s]%s[/color]" % [
			HEADING_INK, str(workspace).to_upper(),
			INK, " · ".join(specialties),
		])
	return "\n".join(lines)


func build_rules() -> void:
	var font := content.get_theme_font("normal_font")
	if font == null:
		return
	var font_size := content.get_theme_font_size("normal_font_size")
	var line_height := font.get_height(font_size)
	if line_height <= 0.0:
		return

	var top: float = content.position.y
	var i := 1
	while top + i * line_height < RULES_BOTTOM:
		var rule := ColorRect.new()
		rule.color = RULE_COLOR
		rule.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rule.position = Vector2(content.position.x, top + i * line_height - 1.0)
		rule.size = Vector2(content.size.x, 1.0)
		rules.add_child(rule)
		i += 1
