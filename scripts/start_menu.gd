extends Control

const Audio = preload("res://scripts/audio_api.gd")
const ART = preload("res://assets/menu/start-screen.png")
const REFERENCE := Vector2(1280, 720)
const PLAY_RECT := Rect2(437, 470, 404, 112)
const SETTINGS_RECT := Rect2(877, 608, 175, 90)
const FONT = preload("res://assets/fonts/LilitaOne-Regular.ttf")
var art: TextureRect
var play_button: Button
var arsenal_button: Button
var upgrades_button: Button
var achievements_button: Button
var progression: Control
var save: Node
var settings_button: Button
var settings: Control
var panel: PanelContainer
var music_slider: HSlider
var effects_slider: HSlider
var mute_button: CheckButton
var back_button: Button
var music_value: Label
var effects_value: Label
var loading: Label
var starting := false
var drag_index := -1
var drag_slider: HSlider
@onready var audio: Node = get_node("/root/GameAudio")

func _ready() -> void:
    # Gameplay uses a smaller logical HUD canvas. Restore the menu canvas when
    # returning from results, so shop/settings minimum sizes still fit on mobile.
    get_viewport().content_scale_size = Vector2i(1280, 720)
    set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    audio.set_game_state(true, false)
    art = TextureRect.new()
    art.texture = ART
    art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    art.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(art)
    play_button = _hotspot("Jogar")
    play_button.pressed.connect(_play)
    settings_button = _hotspot("Configurações")
    settings_button.pressed.connect(_open_settings)
    save = preload("res://scripts/save_manager.gd").new()
    add_child(save)
    arsenal_button = _hotspot("Arsenal")
    upgrades_button = _hotspot("Upgrades")
    achievements_button = _hotspot("Conquistas")
    for entry in [[arsenal_button, "arsenal"], [upgrades_button, "upgrades"], [achievements_button, "achievements"]]:
        entry[0].pressed.connect(func(): _open_progression(entry[1]))
    _build_settings()
    progression = preload("res://scripts/progression_panel.gd").new()
    progression.progress = save
    add_child(progression)
    loading = Label.new()
    loading.text = "CARREGANDO…"
    loading.add_theme_font_override("font", FONT)
    loading.add_theme_font_size_override("font_size", 38)
    loading.add_theme_color_override("font_color", Color(1, 0.8, 0.2))
    loading.add_theme_color_override("font_outline_color", Color(0.01, 0.03, 0.06))
    loading.add_theme_constant_override("outline_size", 12)
    loading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    loading.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(loading)
    loading.hide()
    resized.connect(_layout)
    _layout()
    print("DEADLIGHT_MENU_READY version=", ProjectSettings.get_setting("application/config/version"))

func _hotspot(label: String) -> Button:
    var button := Button.new()
    button.text = label
    button.tooltip_text = label
    # The original artwork already contains the typography and button surfaces.
    for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
        button.add_theme_color_override(state, Color.TRANSPARENT)
    button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
    for state in ["hover", "pressed", "focus"]:
        var highlight := StyleBoxFlat.new()
        highlight.bg_color = Color(0.1, 0.8, 1, 0.12 if state != "pressed" else 0.24)
        highlight.border_color = Color(0.2, 0.9, 1, 0.85)
        highlight.set_border_width_all(2)
        highlight.set_corner_radius_all(24)
        button.add_theme_stylebox_override(state, highlight)
    add_child(button)
    return button

func _build_settings() -> void:
    settings = Control.new()
    settings.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    add_child(settings)
    var shade := ColorRect.new()
    shade.color = Color(0, 0.015, 0.035, 0.88)
    shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    settings.add_child(shade)
    panel = PanelContainer.new()
    var style := StyleBoxFlat.new()
    style.bg_color = Color(0.025, 0.06, 0.11)
    style.border_color = Color(0.1, 0.85, 1)
    style.set_border_width_all(3)
    style.set_corner_radius_all(20)
    for side in [SIDE_LEFT, SIDE_RIGHT, SIDE_TOP, SIDE_BOTTOM]:
        style.set_content_margin(side, 24)
    panel.add_theme_stylebox_override("panel", style)
    settings.add_child(panel)
    var box := VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    panel.add_child(box)
    var title := _label("CONFIGURAÇÕES", 34)
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(title)
    music_value = _label("", 24)
    box.add_child(music_value)
    music_slider = _slider()
    box.add_child(music_slider)
    effects_value = _label("", 24)
    box.add_child(effects_value)
    effects_slider = _slider()
    box.add_child(effects_slider)
    mute_button = CheckButton.new()
    mute_button.text = "SILENCIAR TUDO"
    mute_button.custom_minimum_size.y = 42
    mute_button.add_theme_font_override("font", FONT)
    mute_button.add_theme_font_size_override("font_size", 22)
    box.add_child(mute_button)
    back_button = Button.new()
    back_button.text = "VOLTAR"
    back_button.custom_minimum_size.y = 58
    back_button.add_theme_font_override("font", FONT)
    back_button.add_theme_font_size_override("font_size", 28)
    box.add_child(back_button)
    music_slider.value_changed.connect(func(value: float):
        audio.set_levels(value / 100.0, effects_slider.value / 100.0)
        _volume_labels())
    effects_slider.value_changed.connect(func(value: float):
        audio.set_levels(music_slider.value / 100.0, value / 100.0)
        _volume_labels())
    mute_button.toggled.connect(func(value: bool): audio.set_muted(value))
    back_button.pressed.connect(_close_settings)
    settings.hide()

func _label(text: String, font_size: int) -> Label:
    var label := Label.new()
    label.text = text
    label.add_theme_font_override("font", FONT)
    label.add_theme_font_size_override("font_size", font_size)
    return label

func _slider() -> HSlider:
    var slider := HSlider.new()
    slider.max_value = 100
    slider.step = 1
    slider.custom_minimum_size = Vector2(480, 48)
    return slider

func _layout() -> void:
    var area := get_viewport_rect().size
    var factor := area / REFERENCE
    var origin := Vector2.ZERO
    art.position = origin
    art.size = REFERENCE * factor
    play_button.position = origin + PLAY_RECT.position * factor
    play_button.size = PLAY_RECT.size * factor
    settings_button.position = origin + SETTINGS_RECT.position * factor
    settings_button.size = SETTINGS_RECT.size * factor
    for entry in [[arsenal_button, Rect2(228, 608, 185, 90)], [upgrades_button, Rect2(447, 608, 180, 90)], [achievements_button, Rect2(660, 608, 180, 90)]]:
        entry[0].position = entry[1].position * factor
        entry[0].size = entry[1].size * factor
    panel.size = Vector2(580, 440)
    panel.position = (area - panel.size) * 0.5
    loading.position = Vector2(0, area.y * 0.52)
    loading.size = Vector2(area.x, 64)

func _volume_labels() -> void:
    music_value.text = "MÚSICA  %d%%" % music_slider.value
    effects_value.text = "EFEITOS  %d%%" % effects_slider.value

func _open_settings() -> void:
    if starting:
        return
    audio.activate()
    music_slider.set_value_no_signal(audio.music_volume * 100)
    effects_slider.set_value_no_signal(audio.effects_volume * 100)
    mute_button.set_pressed_no_signal(audio.muted)
    _volume_labels()
    settings.show()
    _layout()
    Audio.play(self, "ui")
    print("DEADLIGHT_MENU_SETTINGS")
    _report_settings.call_deferred()

func _close_settings() -> void:
    drag_index = -1
    drag_slider = null
    audio.save_settings()
    print("DEADLIGHT_MENU_SETTINGS_SAVED music=%.2f effects=%.2f" % [audio.music_volume, audio.effects_volume])
    settings.hide()
    Audio.play(self, "ui")

func _play() -> void:
    if starting or settings.visible or progression.visible:
        return
    starting = true
    audio.activate()
    Audio.play(self, "ui")
    if OS.has_feature("web"):
        JavaScriptBridge.eval("window.deadlightRequestLandscape && window.deadlightRequestLandscape()")
    play_button.disabled = true
    settings_button.disabled = true
    loading.show()
    print("DEADLIGHT_MENU_PLAY")
    await get_tree().process_frame
    await get_tree().process_frame
    get_tree().change_scene_to_file("res://scenes/main.tscn")

func _input(event: InputEvent) -> void:
    if starting or progression.visible:
        return
    if event is InputEventKey and event.pressed and not event.echo:
        if event.keycode == KEY_ESCAPE and settings.visible:
            _close_settings()
            get_viewport().set_input_as_handled()
        elif event.keycode in [KEY_ENTER, KEY_SPACE] and not settings.visible and get_viewport().gui_get_focus_owner() in [null, play_button]:
            _play()
            get_viewport().set_input_as_handled()
    if event is InputEventScreenTouch:
        if not event.pressed:
            if event.index == drag_index:
                drag_index = -1
                drag_slider = null
            return
        if settings.visible:
            if back_button.get_global_rect().has_point(event.position):
                _close_settings()
            elif mute_button.get_global_rect().has_point(event.position):
                mute_button.button_pressed = not mute_button.button_pressed
            else:
                for slider in [music_slider, effects_slider]:
                    if drag_index == -1 and slider.get_global_rect().grow(8).has_point(event.position):
                        drag_index = event.index
                        drag_slider = slider
                        _touch_volume(event.position)
        elif play_button.get_global_rect().has_point(event.position):
            _play()
        elif settings_button.get_global_rect().has_point(event.position):
            _open_settings()
        else:
            for entry in [[arsenal_button, "arsenal"], [upgrades_button, "upgrades"], [achievements_button, "achievements"]]:
                if entry[0].get_global_rect().has_point(event.position):
                    _open_progression(entry[1])
                    break
        get_viewport().set_input_as_handled()
    elif event is InputEventScreenDrag and event.index == drag_index and drag_slider != null:
        _touch_volume(event.position)
        get_viewport().set_input_as_handled()

func _touch_volume(point: Vector2) -> void:
    var rect := drag_slider.get_global_rect()
    drag_slider.value = clampf((point.x - rect.position.x) / rect.size.x, 0, 1) * 100


func _report_settings() -> void:
    var area := get_viewport_rect().size
    var values := {}
    for pair in [["music", music_slider], ["effects", effects_slider]]:
        var rect: Rect2 = pair[1].get_global_rect()
        values[pair[0]] = [rect.position.x / area.x, rect.position.y / area.y, rect.size.x / area.x, rect.size.y / area.y]
    var center := back_button.get_global_rect().get_center() / area
    values["back"] = [center.x, center.y]
    print("DEADLIGHT_MENU_AUDIO_CONTROLS ", JSON.stringify(values))

func _open_progression(section: String) -> void:
    if starting or settings.visible:
        return
    audio.activate()
    Audio.play(self, "ui")
    progression.open(section)
