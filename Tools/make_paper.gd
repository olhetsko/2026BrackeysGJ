extends SceneTree
##
## Paper generator. Writes the blank stock the ID card and the rulebook are
## printed on, so they read as worn paper instead of a flat rectangle.
##
##   godot --headless --path . --script res://Tools/make_paper.gd
##   godot --headless --path . --import
##
## Still white - just not evenly white. Grain, blotching, dirty edges and a
## chewed border, all in the same muted palette as the rest of the game.
## Edit the numbers in the sheet definitions and run it again.
##

const OUT_DIR := "res://Assets/paper"

# base    - the paper colour before anything is done to it
# grain   - per-pixel brightness wobble, the fibre
# blotch  - large soft patches, the aging
# edge    - how far in from the border the dirt reaches, in pixels
# bite    - how deep the ragged border chews, in pixels
const SHEETS := [
	{
		"name": "paper_card",
		"size": Vector2i(82, 135),
		"base": Color(0.937, 0.925, 0.882),
		"grain": 0.030,
		"blotch": 0.045,
		"edge": 7.0,
		"bite": 2,
	},
	{
		"name": "paper_note",
		"size": Vector2i(84, 98),
		# A shade warmer and older than the card - it lives on the desk.
		"base": Color(0.925, 0.902, 0.835),
		"grain": 0.034,
		"blotch": 0.055,
		"edge": 6.0,
		"bite": 2,
	},
]

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))
	for sheet in SHEETS:
		write(sheet)
	quit(0)


func write(sheet: Dictionary) -> void:
	# Seeded per sheet, so re-running gives the same paper back.
	rng.seed = 8830124
	var size: Vector2i = sheet["size"]
	var image := Image.create(size.x, size.y, false, Image.FORMAT_RGBA8)

	var blotches := value_noise(size, 6)
	var base: Color = sheet["base"]
	var grain: float = sheet["grain"]
	var blotch: float = sheet["blotch"]
	var edge: float = sheet["edge"]
	var bite: int = sheet["bite"]

	# How deep the ragged border eats into each row and column. Kept per-edge
	# so opposite sides tear differently.
	var left := ragged(size.y, bite)
	var right := ragged(size.y, bite)
	var top := ragged(size.x, bite)
	var bottom := ragged(size.x, bite)

	for y in size.y:
		for x in size.x:
			if x < left[y] or x >= size.x - right[y] \
					or y < top[x] or y >= size.y - bottom[x]:
				image.set_pixel(x, y, Color(0, 0, 0, 0))
				continue

			var shade := 1.0
			shade += rng.randf_range(-grain, grain)
			shade += (blotches[y * size.x + x] - 0.5) * 2.0 * blotch
			# Dirt gathers at the edges, heaviest right at the torn line.
			shade -= edge_dirt(x, y, size, left[y], right[y], top[x], bottom[x], edge)

			image.set_pixel(x, y, Color(
				clampf(base.r * shade, 0.0, 1.0),
				clampf(base.g * shade, 0.0, 1.0),
				clampf(base.b * shade, 0.0, 1.0),
				1.0
			))

	var path := "%s/%s.png" % [OUT_DIR, sheet["name"]]
	if image.save_png(path) != OK:
		printerr("could not write %s" % path)
		return
	print("%s  %dx%d" % [path, size.x, size.y])


## Darkening near the torn border, fading to nothing further in.
func edge_dirt(
	x: int, y: int, size: Vector2i,
	left: int, right: int, top: int, bottom: int, reach: float
) -> float:
	var distance := float(mini(
		mini(x - left, size.x - right - 1 - x),
		mini(y - top, size.y - bottom - 1 - y)
	))
	if distance >= reach:
		return 0.0
	var closeness := 1.0 - distance / reach
	return closeness * closeness * 0.16


## A run of small inward bites, correlated with its neighbours so the edge
## tears in strips rather than flickering pixel to pixel.
func ragged(length: int, depth: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(length)
	var current := 0
	for i in length:
		if rng.randf() < 0.30:
			current = rng.randi_range(0, depth)
		out[i] = current
	return out


## Smooth low-frequency noise: a coarse grid of random values, blended between.
## Gives soft patches rather than static.
func value_noise(size: Vector2i, cells: int) -> PackedFloat32Array:
	var grid := PackedFloat32Array()
	var gw := cells + 1
	grid.resize(gw * gw)
	for i in grid.size():
		grid[i] = rng.randf()

	var out := PackedFloat32Array()
	out.resize(size.x * size.y)
	for y in size.y:
		for x in size.x:
			var fx := float(x) / size.x * cells
			var fy := float(y) / size.y * cells
			var x0 := int(fx)
			var y0 := int(fy)
			var tx := smoothstep(0.0, 1.0, fx - x0)
			var ty := smoothstep(0.0, 1.0, fy - y0)

			var a: float = grid[y0 * gw + x0]
			var b: float = grid[y0 * gw + x0 + 1]
			var c: float = grid[(y0 + 1) * gw + x0]
			var d: float = grid[(y0 + 1) * gw + x0 + 1]

			out[y * size.x + x] = lerpf(lerpf(a, b, tx), lerpf(c, d, tx), ty)
	return out
