extends Node
# One persistent mixer, real curated samples, bounded voice count and no sound backlog.
signal settings_changed
const SETTINGS := "user://deadlight_audio.cfg"
const MUSIC_PATH := "res://assets/audio/music/coastal_patrol.ogg"
const CLIP_PATHS := {
    "shot": ["res://assets/audio/sfx/shot_a.wav", "res://assets/audio/sfx/shot_b.wav", "res://assets/audio/sfx/shot_c.wav"],
    "machine_shot": ["res://assets/audio/sfx/shot_c.wav", "res://assets/audio/sfx/shot_b.wav", "res://assets/audio/sfx/shot_a.wav"],
    "plasma": ["res://assets/audio/sfx/plasma.wav"],
    "impact": ["res://assets/audio/sfx/impact.wav"],
    "explosion": ["res://assets/audio/sfx/explosion.wav"],
    "splatter": ["res://assets/audio/sfx/splatter.wav"],
    "reload": ["res://assets/audio/sfx/reload.wav"],
    "jump": ["res://assets/audio/sfx/jump.wav"],
    "step": ["res://assets/audio/sfx/step.wav"],
    "hurt": ["res://assets/audio/sfx/hurt.wav"],
    "pickup": ["res://assets/audio/sfx/pickup.wav"],
    "ui": ["res://assets/audio/sfx/ui.wav"],
    "mission": ["res://assets/audio/sfx/mission.wav"],
    "victory": ["res://assets/audio/sfx/victory.wav"],
    "defeat": ["res://assets/audio/sfx/defeat.wav"],
}
const GAINS := {"machine_shot": -10.0, "shot": -7.0, "plasma": -11.0, "impact": -13.0, "explosion": -8.0, "splatter": -16.0, "reload": -12.0, "jump": -17.0, "step": -22.0, "hurt": -13.0, "pickup": -13.0, "ui": -16.0, "mission": -10.0, "victory": -8.0, "defeat": -12.0}
const INTERVALS := {"machine_shot": 0.065, "shot": 0.065, "plasma": 0.12, "impact": 0.065, "explosion": 0.09, "splatter": 0.09, "step": 0.18, "pickup": 0.08, "ui": 0.1}
var clips: Dictionary = {}
var music_volume := 0.22
var effects_volume := 0.7
var muted := false
var unlocked := false
var focused := true
var game_active := false
var game_paused := false
var orientation_blocked := false
var music_player: AudioStreamPlayer
var voices: Array[AudioStreamPlayer] = []
var priorities: Array[int] = []
var started: Array[int] = []
var last_played: Dictionary = {}
var variants: Dictionary = {}
var event_counts: Dictionary = {}
var listener_position := Vector3.ZERO
var save_delay := -1.0
var peak_voices := 0
var shutting_down := false
var music_bus := -1
var effects_bus := -1
var ui_bus := -1
var master_bus := -1

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    if Engine.is_editor_hint():
        return
    for cue in CLIP_PATHS:
        clips[cue] = []
        for path in CLIP_PATHS[cue]:
            clips[cue].append(load(path))
    _load_settings()
    master_bus = _bus("DeadlightMaster", "Master")
    music_bus = _bus("DeadlightMusic", "DeadlightMaster")
    effects_bus = _bus("DeadlightEffects", "DeadlightMaster")
    ui_bus = _bus("DeadlightUI", "DeadlightMaster")
    var limiter := AudioEffectLimiter.new()
    limiter.ceiling_db = -1.0
    limiter.threshold_db = -3.0
    AudioServer.add_bus_effect(master_bus, limiter)
    AudioServer.set_bus_volume_db(master_bus, -2.5)
    AudioServer.set_bus_volume_db(music_bus, -70)
    _apply_levels()
    music_player = AudioStreamPlayer.new()
    music_player.bus = "DeadlightMusic"
    music_player.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
    var soundtrack := load(MUSIC_PATH).duplicate() as AudioStreamOggVorbis
    soundtrack.loop = true
    music_player.stream = soundtrack
    add_child(music_player)
    for index in range(12):
        var voice := AudioStreamPlayer.new()
        voice.playback_type = AudioServer.PLAYBACK_TYPE_STREAM
        voice.bus = "DeadlightEffects"
        add_child(voice)
        voices.append(voice)
        priorities.append(0)
        started.append(0)
    unlocked = not OS.has_feature("web")
    print("DEADLIGHT_AUDIO_READY music=22pct voices=12")

func _bus(name: String, send: String) -> int:
    var index := AudioServer.get_bus_index(name)
    if index == -1:
        AudioServer.add_bus()
        index = AudioServer.bus_count - 1
        AudioServer.set_bus_name(index, name)
        AudioServer.set_bus_send(index, send)
    return index

func _input(event: InputEvent) -> void:
    if (event is InputEventScreenTouch and event.pressed) or (event is InputEventMouseButton and event.pressed) or (event is InputEventKey and event.pressed):
        activate()

func activate() -> void:
    if shutting_down:
        return
    if not unlocked:
        unlocked = true
        print("DEADLIGHT_AUDIO_UNLOCKED")
    _ensure_music()

func _ensure_music() -> void:
    if shutting_down:
        return
    if unlocked and game_active and focused and not orientation_blocked and not music_player.has_stream_playback():
        music_player.play()
        print("DEADLIGHT_MUSIC_STARTED")

func _process(delta: float) -> void:
    if shutting_down:
        return
    _ensure_music()
    music_player.stream_paused = not focused or orientation_blocked
    var target := linear_to_db(maxf(0.0003, music_volume))
    if game_paused:
        target -= 9.0
    if not game_active:
        target = -70
    AudioServer.set_bus_volume_db(music_bus, move_toward(AudioServer.get_bus_volume_db(music_bus), target, delta * 38))
    if not game_active and AudioServer.get_bus_volume_db(music_bus) <= -65:
        music_player.stop()
    if save_delay >= 0:
        save_delay -= delta
        if save_delay < 0:
            save_settings()

func set_game_state(active: bool, paused: bool, blocked: bool = false) -> void:
    game_active = active
    game_paused = paused
    orientation_blocked = blocked
    if paused or not active:
        for voice in voices:
            if voice.bus == "DeadlightEffects":
                voice.stop()
    _ensure_music()

func play(cue: String, position: Vector3 = Vector3.INF) -> bool:
    if shutting_down or not unlocked or muted or not focused or not clips.has(cue):
        return false
    var is_ui := cue in ["ui", "pickup", "mission", "victory", "defeat"]
    if game_paused and not is_ui:
        return false
    var now := Time.get_ticks_msec()
    if now - int(last_played.get(cue, -10000)) < int(float(INTERVALS.get(cue, 0.04)) * 1000):
        return false
    var distance_gain := 0.0
    if position != Vector3.INF:
        var distance := position.distance_to(listener_position)
        if distance > 36:
            return false
        distance_gain = -minf(18, distance * 0.5)
    var priority := 3 if is_ui else (2 if cue in ["explosion", "hurt"] else 1)
    var slot := -1
    for index in range(voices.size()):
        if not voices[index].playing:
            slot = index
            break
    if slot == -1:
        var oldest := now + 1
        for index in range(voices.size()):
            if priorities[index] < priority and started[index] < oldest:
                oldest = started[index]
                slot = index
    if slot == -1:
        return false
    last_played[cue] = now
    var choice := int(variants.get(cue, 0))
    variants[cue] = choice + 1
    var voice := voices[slot]
    voice.stop()
    voice.stream = clips[cue][choice % clips[cue].size()]
    voice.bus = "DeadlightUI" if is_ui else "DeadlightEffects"
    voice.volume_db = float(GAINS[cue]) + distance_gain
    voice.pitch_scale = (0.93 if cue == "machine_shot" else 1.0) + sin(float(choice) * 2.3) * (0.025 if cue != "step" else 0.045)
    priorities[slot] = priority
    started[slot] = now
    voice.play()
    event_counts[cue] = int(event_counts.get(cue, 0)) + 1
    var active_voices := 0
    for item in voices:
        if item.playing:
            active_voices += 1
    peak_voices = maxi(peak_voices, active_voices)
    return true

func set_levels(music: float, effects: float) -> void:
    music_volume = clampf(music, 0, 1)
    effects_volume = clampf(effects, 0, 1)
    _apply_levels()
    save_delay = 0.3
    settings_changed.emit()

func set_muted(value: bool) -> void:
    muted = value
    _apply_levels()
    save_delay = 0.3
    settings_changed.emit()
    print("DEADLIGHT_AUDIO_MUTED %s" % muted)

func _apply_levels() -> void:
    if master_bus == -1:
        return
    AudioServer.set_bus_mute(master_bus, muted or not focused)
    AudioServer.set_bus_mute(effects_bus, effects_volume <= 0)
    AudioServer.set_bus_mute(ui_bus, effects_volume <= 0)
    AudioServer.set_bus_mute(music_bus, music_volume <= 0)
    AudioServer.set_bus_volume_db(effects_bus, linear_to_db(maxf(0.0001, effects_volume)))
    AudioServer.set_bus_volume_db(ui_bus, linear_to_db(maxf(0.0001, effects_volume)))

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        focused = false
        _apply_levels()
        for voice in voices:
            voice.stop()
    elif what == NOTIFICATION_APPLICATION_FOCUS_IN:
        focused = true
        _apply_levels()

func _load_settings() -> void:
    var config := ConfigFile.new()
    if config.load(SETTINGS) == OK:
        music_volume = clampf(float(config.get_value("audio", "music", 0.22)), 0, 1)
        effects_volume = clampf(float(config.get_value("audio", "effects", 0.7)), 0, 1)
        muted = bool(config.get_value("audio", "muted", false))

func save_settings() -> void:
    var config := ConfigFile.new()
    config.set_value("audio", "music", music_volume)
    config.set_value("audio", "effects", effects_volume)
    config.set_value("audio", "muted", muted)
    if config.save(SETTINGS) != OK:
        push_warning("Audio preferences could not be saved")

func _exit_tree() -> void:
    if is_instance_valid(music_player):
        music_player.stop()
        music_player.stream = null
    for voice in voices:
        if is_instance_valid(voice):
            voice.stop()
            voice.stream = null
    clips.clear()

func shutdown() -> void:
    # Free players while the audio server is still running, then let its thread drain.
    shutting_down = true
    if is_instance_valid(music_player):
        music_player.stop()
        music_player.stream = null
        music_player.queue_free()
    for voice in voices:
        voice.stop()
        voice.stream = null
        voice.queue_free()
    voices.clear()
    clips.clear()
