extends SceneTree
func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    root.size = Vector2i(1280, 720)
    var mixer = root.get_node("GameAudio")
    var original := [mixer.music_volume, mixer.effects_volume, mixer.muted]
    mixer.focused = true
    mixer.activate()
    mixer.set_muted(false)
    mixer.set_levels(0.22, 0.7)
    var scene := load("res://scenes/main.tscn") as PackedScene
    var district = scene.instantiate()
    root.add_child(district)
    current_scene = district
    district.spawner.active = false
    await process_frame
    assert(mixer.music_player.playing and mixer.music_player.stream.loop, "Quiet looping music did not start")
    assert(mixer.music_player.stream.get_length() > 30, "Music loop is too short")
    for cue in mixer.clips:
        for clip in mixer.clips[cue]:
            assert(clip != null and clip.get_length() > 0.03, "Empty audio resource: " + cue)
    assert(mixer.CLIP_PATHS.shot != mixer.CLIP_PATHS.machine_shot, "Weapons share generic shot clips")
    # Verify the production weapon and creature code actually reaches the new cues.
    var weapon = district.player.weapon
    weapon.set_physics_process(false)
    for index in [0, 1]:
        weapon.select_weapon(index)
        var definition = weapon.WEAPONS[index]
        mixer.last_played.erase(definition.sound)
        var shots_before: int = mixer.event_counts.get(definition.sound, 0)
        weapon.cooldown = 0
        weapon.active = true
        weapon.direction = Vector3.RIGHT
        weapon._physics_process(0)
        assert(mixer.event_counts.get(definition.sound, 0) == shots_before + 1)
        mixer.last_played.erase(definition.reload_sound)
        weapon.reload()
        assert(mixer.event_counts.get(definition.reload_sound, 0) > 0)
        weapon.reload_time = 0
        weapon.active = false
    for voice in mixer.voices:
        voice.stop()
    var alien = district.spawner.spawn()
    assert(alien != null)
    alien.set_physics_process(false)
    alien.position = district.player.position + Vector3(0, 0, 1.4)
    alien.voice_timer = 0
    alien._physics_process(0)
    assert(mixer.event_counts.get("alien_idle", 0) > 0)
    assert(mixer.event_counts.get("alien_attack", 0) > 0)
    alien.receive_damage(1)
    assert(mixer.event_counts.get("alien_hurt", 0) > 0)
    alien.receive_damage(999)
    assert(mixer.event_counts.get("alien_death", 0) > 0)
    var creature_voices := 0
    for index in range(mixer.voices.size()):
        if mixer.voices[index].playing and mixer.voice_cues[index].begins_with("alien_"):
            creature_voices += 1
    assert(creature_voices <= 3, "Creature voices exceeded the mobile mix budget")
    for cue in ["alien_idle", "alien_attack", "alien_hurt", "alien_death"]:
        mixer.last_played.erase(cue)
        assert(not mixer.play(cue, Vector3(100, 0, 0)), "Distant alien vocal played")
    for voice in mixer.voices:
        voice.stop()
    assert(mixer.voices.size() == 12 and mixer.get_child_count() == 13, "Mixer allocated unexpected players")
    assert(mixer.play("not_a_cue") == false, "Unknown sound accepted")
    mixer.last_played.erase("shot")
    var before: int = mixer.event_counts.get("shot", 0)
    for index in range(100):
        mixer.play("shot")
    assert(mixer.event_counts.shot == before + 1, "Repeated sound spam was not throttled")
    assert(not mixer.play("plasma", Vector3(200, 0, 0)), "Distant combat played at full range")
    mixer.set_game_state(true, true)
    assert(not mixer.play("shot"), "Weapon audio played while paused")
    mixer.last_played.erase("ui")
    assert(mixer.play("ui"), "Pause UI audio did not play")
    mixer.set_muted(true)
    assert(AudioServer.is_bus_mute(mixer.master_bus) and not mixer.play("ui"), "Mute did not stop sound")
    mixer.set_muted(false)
    mixer.set_levels(0.13, 0.52)
    mixer.save_settings()
    var preferences := ConfigFile.new()
    assert(preferences.load(mixer.SETTINGS) == OK, "Audio preferences did not save")
    assert(is_equal_approx(float(preferences.get_value("audio", "music")), 0.13), "Music level not persisted")
    mixer._notification(NOTIFICATION_APPLICATION_FOCUS_OUT)
    mixer._process(0.1)
    assert(AudioServer.is_bus_mute(mixer.master_bus) and mixer.music_player.stream_paused, "Background audio did not suspend")
    mixer._notification(NOTIFICATION_APPLICATION_FOCUS_IN)
    mixer._process(0.1)
    assert(not AudioServer.is_bus_mute(mixer.master_bus), "Audio remained muted on focus return")
    var identity := mixer.get_instance_id()
    var bus_count := AudioServer.bus_count
    district._restart()
    await process_frame
    await process_frame
    district = current_scene
    district.spawner.active = false
    assert(mixer.get_instance_id() == identity and AudioServer.bus_count == bus_count and mixer.get_child_count() == 13, "Restart duplicated the mixer/music")
    mixer.set_game_state(false, false)
    mixer._process(2.0)
    assert(not mixer.music_player.playing, "Music did not fade/stop after a run")
    assert(mixer.peak_voices <= 12, "Polyphony exceeded mobile budget")
    mixer.set_levels(original[0], original[1])
    mixer.set_muted(original[2])
    mixer.save_settings()
    print("DEADLIGHT_AUDIO_OK assets loop throttle pause mute focus settings restart polyphony")
    district.queue_free()
    await process_frame
    root.get_node("GameAudio").shutdown()
    await create_timer(0.4).timeout
    quit(0)
