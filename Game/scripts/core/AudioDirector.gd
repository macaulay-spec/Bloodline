extends Node
## Audio and haptics.
##
## All sound effects are synthesised at runtime, so the game ships without
## any licensed audio assets. The director also drives the haptic feedback
## on Android.

## The players used for the different sound groups.
var _sfx_players: Array[AudioStreamPlayer] = []

var _music_player: AudioStreamPlayer = null

var _next_player := 0

## The generated one-shot sounds, keyed by name.
var _sounds: Dictionary = {}

## The generated loop, keyed by name.
var _loops: Dictionary = {}

var _haptics_enabled: bool = true

var _last_sound_frame: Dictionary = {}


func _ready() -> void:
	for i in range(6):
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)
	_build_sounds()


func _build_sounds() -> void:
	_sounds["hit_light"] = _noise_burst(0.09, 900.0, 0.5, 0.25)
	_sounds["hit_heavy"] = _noise_burst(0.18, 420.0, 0.7, 0.32)
	_sounds["hit_ability"] = _tone_sweep(0.35, 880.0, 180.0, 0.3, 0.3)
	_sounds["swing_light"] = _noise_burst(0.08, 1600.0, 0.18, 0.2)
	_sounds["swing_heavy"] = _noise_burst(0.14, 900.0, 0.25, 0.24)
	_sounds["swing_ability"] = _tone_sweep(0.3, 220.0, 660.0, 0.22, 0.26)
	_sounds["dodge"] = _noise_burst(0.14, 2400.0, 0.14, 0.16)
	_sounds["guard_break"] = _tone_sweep(0.4, 300.0, 90.0, 0.4, 0.32)
	_sounds["ko"] = _tone_sweep(0.7, 180.0, 50.0, 0.45, 0.4)
	_sounds["ui_move"] = _tone(0.05, 660.0, 0.14)
	_sounds["ui_select"] = _tone(0.09, 880.0, 0.2)
	_sounds["ui_back"] = _tone(0.09, 330.0, 0.18)
	_sounds["bell"] = _tone(0.7, 520.0, 0.3)
	_loops["menu"] = _menu_loop()


## Plays a one-shot sound by name.
func play_sound(sound_id: String, volume_scale: float = 1.0) -> void:
	if not _sounds.has(sound_id):
		return
	# Rate-limit identical sounds so a flurry of hits does not stack up.
	var frame := Engine.get_process_frames()
	if _last_sound_frame.get(sound_id, -99) == frame:
		return
	_last_sound_frame[sound_id] = frame

	var stream: AudioStream = _sounds[sound_id]
	var player := _sfx_players[_next_player]
	_next_player = (_next_player + 1) % _sfx_players.size()
	player.stream = stream
	player.volume_db = linear_to_db(
		clampf(float(SaveSystem.settings.get("sfx_volume", 0.9)) * volume_scale, 0.001, 1.0)
	)
	player.play()


## Starts a looping track.
func play_music(track_id: String) -> void:
	if not _loops.has(track_id):
		return
	_music_player.stream = _loops[track_id]
	_music_player.volume_db = linear_to_db(
		clampf(float(SaveSystem.settings.get("music_volume", 0.7)), 0.001, 1.0)
	)
	if not _music_player.playing:
		_music_player.play()


func stop_music() -> void:
	_music_player.stop()


## Applies the volume settings from the save file.
func apply_settings() -> void:
	var sfx := linear_to_db(clampf(float(SaveSystem.settings.get("sfx_volume", 0.9)), 0.001, 1.0))
	for player in _sfx_players:
		player.volume_db = sfx
	_music_player.volume_db = linear_to_db(
		clampf(float(SaveSystem.settings.get("music_volume", 0.7)), 0.001, 1.0)
	)
	_haptics_enabled = bool(SaveSystem.settings.get("haptics", true))


## Fires a short haptic pulse. Silently does nothing where the platform
## has no vibration support.
func haptic(strength: float = 0.4, duration_ms: int = 60) -> void:
	if not _haptics_enabled:
		return
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(duration_ms, strength)


# --- Sound synthesis -------------------------------------------------------


func _tone(duration: float, frequency: float, amplitude: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	for i in range(count):
		var t := float(i) / sample_rate
		var envelope: float = 1.0 - float(i) / float(count)
		var sample: float = sin(TAU * frequency * t) * amplitude * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _tone_sweep(
	duration: float, start_hz: float, end_hz: float, amplitude: float, decay: float
) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var frequency: float = lerpf(start_hz, end_hz, t)
		phase += TAU * frequency / sample_rate
		var envelope: float = pow(1.0 - t, decay)
		var sample: float = sin(phase) * amplitude * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _noise_burst(
	duration: float, cutoff_hz: float, amplitude: float, decay: float
) -> AudioStreamWAV:
	var sample_rate := 22050
	var count := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(cutoff_hz)
	var previous := 0.0
	for i in range(count):
		var t := float(i) / float(count)
		var white := rng.randf_range(-1.0, 1.0)
		# A one-pole low pass turns the white noise into something duller
		# and more like an impact.
		var alpha: float = clampf(cutoff_hz / sample_rate, 0.0, 1.0)
		previous = previous + alpha * (white - previous)
		var envelope: float = pow(1.0 - t, decay)
		var sample: float = previous * amplitude * envelope
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream


func _menu_loop() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 4.0
	var count := int(duration * sample_rate)
	var data := PackedByteArray()
	data.resize(count * 2)
	# A slow two-note drone, so the menu is not silent.
	for i in range(count):
		var t := float(i) / sample_rate
		var chord: float = 55.0 if fmod(t, 4.0) < 2.0 else 61.74
		var sample: float = (
			sin(TAU * chord * t) * 0.5
			+ sin(TAU * chord * 2.0 * t) * 0.18
			+ sin(TAU * chord * 3.0 * t) * 0.08
		)
		var value := int(clampf(sample, -1.0, 1.0) * 32767.0)
		data.encode_s16(i * 2, value)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = count
	return stream
