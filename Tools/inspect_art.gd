extends SceneTree
##
## Measures the opaque content of each candidate frame so rest/pressed pairs
## can be told apart by shape instead of by eye.
##
##   godot --headless --path . --script res://Tools/inspect_art.gd
##
## A raised stamp (knob up on a stalk) is tall and narrow. A pressed one is
## squat. Same for a bell: struck reads shorter than at rest.
##

const FILES := [
	"res://Assets/pixil-frame-0 (2).png",
	"res://Assets/pixil-frame-0 (4).png",
	"res://Assets/pixil-frame-0 (8).png",
	"res://Assets/pixil-frame-0 (9).png",
	"res://Assets/pixil-frame-0 (10).png",
	"res://Assets/pixil-frame-0 (11).png",
	"res://Assets/pixilart-drawing (16).png",
	"res://Assets/pixilart-drawing (17).png",
	"res://Assets/pixilart-drawing (18).png",
	"res://Assets/pixilart-drawing (19).png",
]


func _initialize() -> void:
	print("%-32s %-11s %-34s %-8s %s" % [
		"file", "canvas", "content box (fraction of canvas)", "aspect", "bottom-centre offset from middle",
	])

	for path in FILES:
		var texture: Texture2D = load(path)
		if texture == null:
			print("%-32s could not load" % path.get_file())
			continue

		var image := texture.get_image()
		var box := opaque_box(image)
		if box.size.x <= 0.0:
			print("%-32s empty" % path.get_file())
			continue

		# Normalised so the different canvas sizes can be compared directly.
		var w := box.size.x / image.get_width()
		var h := box.size.y / image.get_height()
		var left := box.position.x / image.get_width()
		var top := box.position.y / image.get_height()

		# Where the content actually sits relative to the sprite's origin, in
		# texture pixels. Two frames whose bottom-centres differ will visibly
		# jump when swapped, so this is the number to correct for.
		var centre_x := (box.position.x + box.size.x * 0.5) - image.get_width() * 0.5
		var bottom_y := (box.position.y + box.size.y) - image.get_height() * 0.5

		print("%-32s %4dx%-6d x=%.3f y=%.3f w=%.3f h=%.3f  %.3f    x %+.1f  bottom %+.1f" % [
			path.get_file(), image.get_width(), image.get_height(),
			left, top, w, h, h / w, centre_x, bottom_y,
		])

	quit(0)


## The tightest rectangle containing every pixel that is not fully transparent.
## Falls back to non-white when the art has no alpha at all.
func opaque_box(image: Image) -> Rect2:
	var min_x := image.get_width()
	var min_y := image.get_height()
	var max_x := -1
	var max_y := -1
	var has_alpha := image.detect_alpha() != Image.ALPHA_NONE

	for y in image.get_height():
		for x in image.get_width():
			var pixel := image.get_pixel(x, y)
			var solid := pixel.a > 0.35 if has_alpha else (pixel.r + pixel.g + pixel.b) < 2.85
			if not solid:
				continue
			min_x = mini(min_x, x)
			min_y = mini(min_y, y)
			max_x = maxi(max_x, x)
			max_y = maxi(max_y, y)

	if max_x < 0:
		return Rect2()
	return Rect2(min_x, min_y, max_x - min_x + 1, max_y - min_y + 1)
