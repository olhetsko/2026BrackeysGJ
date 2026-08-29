extends SceneTree
##
## Sound generator. Writes every .wav in Assets/audio/ from scratch.
##
##   godot --headless --path . --script res://Tools/make_audio.gd
##   godot --headless --path . --import     (to (re)import them afterwards)
##
## Nothing in the game runs this - it is a build tool. Edit the numbers in the
## build_* functions and run it again to retune a sound; the RNG is seeded so
## the same settings always give the same file.
##

const RATE := 22050
const OUT_DIR := "res://Assets/audio"

var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR))

	write("bell", build_bell())
	write("stamp", build_stamp())
	write("paper", build_paper())
	write("leave", build_leave())
	write("endday", build_endday())
	write("click", build_click())
	write("ambient", build_ambient())

	quit(0)


# ---------------------------------------------------------------------------
# SOUNDS
# ---------------------------------------------------------------------------

## Desk bell. Bells are inharmonic - the partials are not whole multiples of
## the root, which is what stops it sounding like a plain beep.
func build_bell() -> PackedFloat32Array:
	var out := silence(1.5)
	var partials := [1.0, 2.76, 5.40, 8.93]
	var levels := [1.0, 0.55, 0.32, 0.18]
	var decays := [3.2, 4.6, 6.5, 9.0]
	var root := 660.0

	for p in partials.size():
		var freq: float = root * float(partials[p])
		var level: float = float(levels[p])
		var decay: float = float(decays[p])
		for i in out.size():
			var t := float(i) / RATE
			out[i] += level * exp(-t * decay) * sin(TAU * freq * t)

	# A hint of strike noise so it starts with a tick rather than a swell.
	for i in out.size():
		var t := float(i) / RATE
		out[i] += 0.35 * exp(-t * 90.0) * rng.randf_range(-1.0, 1.0)

	return normalise(out, 0.75)


## Rubber stamp: a low thump for the weight, a noise burst for the slap.
func build_stamp() -> PackedFloat32Array:
	var out := silence(0.28)
	var lowpass := 0.0

	for i in out.size():
		var t := float(i) / RATE
		# Pitch drops as it lands, which reads as impact rather than a note.
		var freq := 130.0 * exp(-t * 9.0) + 48.0
		var thump := 0.9 * exp(-t * 26.0) * sin(TAU * freq * t)

		var noise := rng.randf_range(-1.0, 1.0)
		lowpass += (noise - lowpass) * 0.35
		var slap := 0.5 * exp(-t * 55.0) * lowpass

		out[i] = thump + slap

	return normalise(out, 0.85)


## Paper being slid across a counter: bursts of bright noise.
func build_paper() -> PackedFloat32Array:
	var out := silence(0.5)
	var lowpass := 0.0
	var bumps := [0.02, 0.16, 0.30]
	var widths := [0.05, 0.06, 0.07]

	for i in out.size():
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		lowpass += (noise - lowpass) * 0.5
		# Noise minus its own low end leaves the rustle without the rumble.
		var bright := noise - lowpass

		var envelope := 0.0
		for b in bumps.size():
			var d: float = t - float(bumps[b])
			var w: float = float(widths[b])
			envelope += exp(-(d * d) / (w * w))

		out[i] = bright * envelope * 0.6

	return normalise(out, 0.5)


## Footsteps walking away: three soft thuds, each quieter than the last.
func build_leave() -> PackedFloat32Array:
	var out := silence(1.0)
	var steps := [0.0, 0.26, 0.52]
	var levels := [1.0, 0.72, 0.48]
	var lowpass := 0.0

	for i in out.size():
		var t := float(i) / RATE
		var noise := rng.randf_range(-1.0, 1.0)
		lowpass += (noise - lowpass) * 0.12

		for s in steps.size():
			var d: float = t - float(steps[s])
			if d < 0.0:
				continue
			var level: float = float(levels[s])
			out[i] += level * 0.8 * exp(-d * 30.0) * sin(TAU * 72.0 * d)
			out[i] += level * 0.35 * exp(-d * 42.0) * lowpass

	return normalise(out, 0.6)


## End of day: a slow minor chord that swells and fades.
func build_endday() -> PackedFloat32Array:
	var out := silence(3.0)
	var notes := [55.0, 110.0, 130.75, 164.5]
	var levels := [0.9, 0.6, 0.45, 0.35]

	for n in notes.size():
		var freq: float = float(notes[n])
		var level: float = float(levels[n])
		for i in out.size():
			var t := float(i) / RATE
			# Slow in, long out - no percussive edge.
			var envelope := (1.0 - exp(-t * 4.0)) * exp(-t * 1.1)
			# Two voices a hair apart so the chord breathes.
			out[i] += level * envelope * (
				sin(TAU * freq * t) + 0.7 * sin(TAU * freq * 1.004 * t)
			)

	return normalise(out, 0.7)


## UI click. Short and dry.
func build_click() -> PackedFloat32Array:
	var out := silence(0.1)

	for i in out.size():
		var t := float(i) / RATE
		var tone := 0.7 * exp(-t * 70.0) * sin(TAU * 300.0 * t)
		var tick := 0.4 * exp(-t * 220.0) * rng.randf_range(-1.0, 1.0)
		out[i] = tone + tick

	return normalise(out, 0.55)


## Background drone. Dark and flat on purpose - no melody to get sick of.
##
## Every frequency is a whole number of cycles across the loop length, so the
## waveform meets itself at the seam and the loop is inaudible.
func build_ambient() -> PackedFloat32Array:
	var length := 32.0
	var out := silence(length)

	# Cycles-per-loop / length, so each lands exactly on the boundary.
	var drones := [1760.0, 1764.0, 2640.0, 3520.0]
	var levels := [1.0, 0.85, 0.42, 0.18]

	for d in drones.size():
		var freq: float = float(drones[d]) / length
		var level: float = float(levels[d])
		for i in out.size():
			var t := float(i) / RATE
			out[i] += level * sin(TAU * freq * t)

	# Two slow swells, also whole cycles, so the level drifts without pulsing.
	for i in out.size():
		var t := float(i) / RATE
		var swell := 0.68 \
			+ 0.22 * sin(TAU * (2.0 / length) * t) \
			+ 0.10 * sin(TAU * (3.0 / length) * t)
		out[i] *= swell

	# A breath of filtered noise so it is not purely synthetic.
	var lowpass := 0.0
	for i in out.size():
		var noise := rng.randf_range(-1.0, 1.0)
		lowpass += (noise - lowpass) * 0.02
		out[i] += lowpass * 0.5

	# Sparse notes, each fully decayed before the loop point.
	var hits := [4.0, 12.0, 20.0, 28.0]
	var pitches := [130.75, 164.5, 110.0, 196.0]
	for h in hits.size():
		var start: float = float(hits[h])
		var freq: float = float(pitches[h])
		for i in out.size():
			var t := float(i) / RATE - start
			if t < 0.0:
				continue
			out[i] += 0.22 * exp(-t * 1.4) * sin(TAU * freq * t)

	return normalise(out, 0.42)


# ---------------------------------------------------------------------------
# HELPERS
# ---------------------------------------------------------------------------

func silence(seconds: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	out.resize(int(seconds * RATE))
	out.fill(0.0)
	# Reseeded per sound so editing one does not shuffle the others.
	rng.seed = 20260829
	return out


## Scale to a target peak. Keeps every sound at a predictable level instead of
## whatever the maths happened to add up to.
func normalise(samples: PackedFloat32Array, peak: float) -> PackedFloat32Array:
	var loudest := 0.0
	for value in samples:
		loudest = maxf(loudest, absf(value))
	if loudest < 0.000001:
		return samples

	var gain := peak / loudest
	for i in samples.size():
		samples[i] *= gain
	return samples


func write(name: String, samples: PackedFloat32Array) -> void:
	var pcm := PackedByteArray()
	pcm.resize(samples.size() * 2)
	for i in samples.size():
		pcm.encode_s16(i * 2, int(round(clampf(samples[i], -1.0, 1.0) * 32767.0)))

	var path := "%s/%s.wav" % [OUT_DIR, name]
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		printerr("could not write %s" % path)
		return

	file.store_buffer("RIFF".to_ascii_buffer())
	file.store_32(36 + pcm.size())
	file.store_buffer("WAVE".to_ascii_buffer())
	file.store_buffer("fmt ".to_ascii_buffer())
	file.store_32(16)
	file.store_16(1)          # PCM
	file.store_16(1)          # mono
	file.store_32(RATE)
	file.store_32(RATE * 2)   # bytes per second
	file.store_16(2)          # bytes per frame
	file.store_16(16)         # bits per sample
	file.store_buffer("data".to_ascii_buffer())
	file.store_32(pcm.size())
	file.store_buffer(pcm)
	file.close()

	print("%s  %.2fs  %d bytes" % [path, float(samples.size()) / RATE, pcm.size()])
