extends Node


## Each cue maps to a list of takes. More than one means a random pick, which
## is what keeps the rulebook from clicking identically on every page turn.
const SOUNDS := {
	"bell": [preload("res://Assets/audio/bell.mp3")],
	"flip": [
		preload("res://Assets/audio/flip1.mp3"),
		preload("res://Assets/audio/flip2.mp3"),
		preload("res://Assets/audio/flip3.mp3"),
		preload("res://Assets/audio/flip4.mp3"),
	],
	"stamp": [preload("res://Assets/audio/Stamp.mp3")],
	"paperpass": [preload("res://Assets/audio/paperpass.mp3")],
	"start": [preload("res://Assets/audio/Start.mp3")],
	"nextday": [preload("res://Assets/audio/nextday.mp3")],
	"woodnextday": [preload("res://Assets/audio/wood next day.mp3")],
}

## Per-cue volume in decibels. This is the dial for balancing.
const LEVELS := {
	"bell": -3.0,
	"flip": -8.0,
	"stamp": -2.0,
	"paperpass": 2.0,
	"start": -6.0,
	"nextday": -4.0,
	"woodnextday": -4.0,
}

## The background track. Well under everything else so it sits behind the room
## rather than in front of it.
const MUSIC_VOLUME_DB := -15.0
const MUSIC_FADE := 1.5

## Music.mp3 is imported with loop=true, so it runs unbroken.
var music_stream: AudioStreamMP3 = preload("res://Assets/audio/Music.mp3")

## Sounds can overlap - a stamp while paper is sliding, a flip over the music -
## so there is a small pool of players rather than one.
const VOICES := 6

var _music: AudioStreamPlayer
var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0


func _ready() -> void:
	_music = AudioStreamPlayer.new()
	_music.name = "Music"
	_music.stream = music_stream
	_music.volume_db = MUSIC_VOLUME_DB
	_music.bus = "Master"
	add_child(_music)

	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.name = "Voice%d" % i
		voice.bus = "Master"
		add_child(voice)
		_voices.append(voice)


## Fire a one-shot by name. Unknown names are ignored rather than crashing a
## build over a typo in a sound cue.
func play(sound: String, pitch_jitter := 0.0) -> void:
	if not SOUNDS.has(sound):
		push_warning("Audio: no sound called '%s'" % sound)
		return

	var takes: Array = SOUNDS[sound]
	if takes.is_empty():
		return

	var voice := _take_voice()
	voice.stream = takes[randi() % takes.size()]
	voice.volume_db = float(LEVELS.get(sound, 0.0))
	# A little pitch variation stops repeated cues sounding like a machine.
	voice.pitch_scale = 1.0 + randf_range(-pitch_jitter, pitch_jitter)
	voice.play()


func start_music() -> void:
	if _music.playing:
		return
	_music.volume_db = MUSIC_VOLUME_DB
	_music.play()


func stop_music(fade := true) -> void:
	if not _music.playing:
		return
	if not fade:
		_music.stop()
		return
	var tween := create_tween()
	tween.tween_property(_music, "volume_db", -60.0, MUSIC_FADE)
	tween.tween_callback(_music.stop)


# Round-robin, so a new sound never cuts off the one before it while any
# voice is still free.
func _take_voice() -> AudioStreamPlayer:
	for i in _voices.size():
		var index := (_next_voice + i) % _voices.size()
		if not _voices[index].playing:
			_next_voice = (index + 1) % _voices.size()
			return _voices[index]

	# Everything busy: reuse the oldest slot.
	var fallback := _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	return fallback
